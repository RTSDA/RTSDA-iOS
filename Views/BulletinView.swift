import SwiftUI
import Foundation
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var error: Error?
    @Binding var hasInteracted: Bool
    @State private var downloadTask: Task<Void, Never>?
    @State private var documentTask: Task<Void, Never>?
    @State private var pageCount: Int = 0
    @State private var currentPage: Int = 1
    @State private var pdfData: Data?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .twoUpContinuous
        pdfView.displayDirection = .horizontal
        pdfView.backgroundColor = .systemBackground
        pdfView.usePageViewController(true)
        pdfView.delegate = context.coordinator
        return pdfView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Only start a new download if we don't have the data yet
        if pdfData == nil {
            Task { @MainActor in
                await startDownload(for: uiView)
            }
        } else if uiView.document == nil && documentTask == nil {
            Task { @MainActor in
                await createDocument(for: uiView)
            }
        }
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        var parent: PDFViewer
        
        init(_ parent: PDFViewer) {
            self.parent = parent
        }
        
        func pdfViewPageChanged(_ notification: Notification) {
            if !parent.hasInteracted {
                parent.hasInteracted = true
            }
        }
    }
    
    private func createDocument(for pdfView: PDFView) async {
        documentTask?.cancel()
        
        documentTask = Task {
            do {
                guard let data = pdfData else { return }
                let document = try await createPDFDocument(from: data)
                
                if !Task.isCancelled {
                    await MainActor.run {
                        pdfView.document = document
                        pageCount = document.pageCount
                        isLoading = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.error = error
                        isLoading = false
                    }
                }
            }
            await MainActor.run {
                documentTask = nil
            }
        }
    }
    
    private func startDownload(for pdfView: PDFView) async {
        // Cancel any existing task
        downloadTask?.cancel()
        
        // Create new task
        downloadTask = Task {
            await MainActor.run {
                isLoading = true
                error = nil
            }
            
            do {
                // Download PDF data
                let (data, _) = try await downloadPDFData()
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                // Store the data
                await MainActor.run {
                    self.pdfData = data
                }
                
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        self.error = error
                        isLoading = false
                    }
                }
            }
        }
    }
    
    private func createPDFDocument(from data: Data) async throws -> PDFDocument {
        return try await Task.detached {
            guard let document = PDFDocument(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            return document
        }.value
    }
    
    private func downloadPDFData() async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.setValue("application/pdf", forHTTPHeaderField: "Accept")
        request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return try await URLSession.shared.data(for: request)
    }
    
    static func dismantleUIView(_ uiView: PDFView, coordinator: ()) {
        uiView.document = nil
    }
}

struct BulletinListView: View {
    @StateObject private var viewModel = BulletinViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.bulletins.isEmpty {
                        ProgressView()
                } else if let error = viewModel.error {
                    VStack {
                        Text("Error loading bulletins")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await viewModel.loadBulletins()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else if viewModel.bulletins.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Bulletins Available")
                            .font(.headline)
                        Text("Check back later for bulletins.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("Refresh") {
                            Task {
                                await viewModel.loadBulletins()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.bulletins) { bulletin in
                            NavigationLink(destination: BulletinDetailView(bulletin: bulletin)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(bulletin.date.formatted(date: .long, time: .omitted))
                                        .font(.headline)
                                    Text(bulletin.title)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.loadBulletins()
                    }
                }
            }
            .navigationTitle("Church Bulletins")
            .task {
                if viewModel.bulletins.isEmpty {
                    await viewModel.loadBulletins()
                }
            }
        }
    }
}

struct BulletinDetailView: View {
    let bulletin: Bulletin
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showPDFViewer = false
    @State private var showScrollIndicator = true
    @State private var hasInteracted = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(bulletin.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(bulletin.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal)
                
                // PDF Button
                if bulletin.pdf != nil {
                    Button(action: {
                        showPDFViewer = true
                        showScrollIndicator = true
                        hasInteracted = false
                    }) {
                        HStack {
                            Image(systemName: "doc.fill")
                                .font(.title3)
                            Text("View PDF")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                
                // Content
                BulletinContentView(bulletin: bulletin)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showPDFViewer) {
            if let url = URL(string: bulletin.pdfUrl) {
                NavigationStack {
                    ZStack {
                        PDFViewer(url: url, isLoading: $isLoading, error: $error, hasInteracted: $hasInteracted)
                            .ignoresSafeArea()
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(1.5)
                                .tint(.white)
                        }
                        
                        if let error = error {
                            VStack(spacing: 16) {
                                Text("Error loading PDF")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text(error.localizedDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Button("Try Again") {
                                    self.error = nil
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                        }
                        
                        if showScrollIndicator && !hasInteracted {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    VStack(spacing: 8) {
                                        Image(systemName: "arrow.left.and.right")
                                            .font(.title)
                                            .foregroundColor(.white)
                                        Text("Swipe to navigate")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Button("Got it") {
                                            withAnimation {
                                                showScrollIndicator = false
                                                hasInteracted = true
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.top, 4)
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
                                    .padding()
                                }
                            }
                        }
                    }
                    .navigationTitle("PDF Viewer")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showPDFViewer = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// Update the main BulletinView to use BulletinListView
struct BulletinView: View {
    var body: some View {
        BulletinListView()
    }
}

struct BulletinContentView: View {
    let bulletin: Bulletin
    
    // Tuple to represent processed content segments
    typealias ContentSegment = (id: UUID, text: String, type: ContentType, reference: String?)
    
    enum ContentType {
        case text
        case hymn(number: Int)
        case responsiveReading(number: Int)
        case bibleVerse
        case sectionHeader
    }
    
    private let sectionOrder = [
        ("Sabbath School", \Bulletin.sabbathSchool),
        ("Divine Worship", \Bulletin.divineWorship),
        ("Scripture Reading", \Bulletin.scriptureReading),
        ("Sunset", \Bulletin.sunset)
    ]
    
    private func cleanHTML(_ text: String) -> String {
        // Remove HTML tags
        var cleaned = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Replace common HTML entities
        let entities = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#39;": "'",
            "&nbsp;": " ",
            "&ndash;": "–",
            "&mdash;": "—",
            "&bull;": "•",
            "&aelig;": "æ",
            "\\u003c": "<",
            "\\u003e": ">",
            "\\r\\n": " "
        ]
        
        for (entity, replacement) in entities {
            cleaned = cleaned.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Clean up whitespace and normalize spaces
        cleaned = cleaned.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: #"(\d+)\s*:\s*(\d+)"#, with: "$1:$2", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned
    }
    
    private func processLine(_ line: String) -> [ContentSegment] {
        // Clean HTML first
        let cleanedLine = cleanHTML(line)
        var segments: [ContentSegment] = []
        let nsLine = cleanedLine as NSString
        
        // Check for section headers
        if let headerSegment = processHeader(cleanedLine, nsLine) {
            segments.append(headerSegment)
            return segments
        }
        
        // Process hymn numbers
        if let hymnSegments = processHymns(cleanedLine, nsLine) {
            segments.append(contentsOf: hymnSegments)
            return segments
        }
        
        // Process responsive readings
        if let readingSegments = processResponsiveReadings(cleanedLine, nsLine) {
            segments.append(contentsOf: readingSegments)
            return segments
        }
        
        // Process Bible verses
        if let verseSegments = processBibleVerses(cleanedLine, nsLine) {
            segments.append(contentsOf: verseSegments)
            return segments
        }
        
        // If no special processing was done, add as regular text
        segments.append((id: UUID(), text: cleanedLine, type: .text, reference: nil))
        return segments
    }
    
    private func processHeader(_ line: String, _ nsLine: NSString) -> ContentSegment? {
        let headerPatterns = [
            // Sabbath School headers
            #"^(Sabbath School):?"#,
            #"^(Song Service):?"#,
            #"^(Leadership):?"#,
            #"^(Lesson Study):?"#,
            #"^(Mission Story):?"#,
            #"^(Welcome):?"#,
            #"^(Opening Song):?"#,
            #"^(Opening Prayer):?"#,
            #"^(Mission Spotlight):?"#,
            #"^(Bible Study):?"#,
            #"^(Closing Song):?"#,
            #"^(Closing Prayer):?"#,
            // Divine Worship headers
            #"^(Announcements):?"#,
            #"^(Call To Worship):?"#,
            #"^(Opening Hymn):?"#,
            #"^(Prayer & Praises):?"#,
            #"^(Prayer Song):?"#,
            #"^(Offering):?"#,
            #"^(Children's Story):?"#,
            #"^(Special Music):?"#,
            #"^(Scripture Reading):?"#,
            #"^(Sermon):?"#,
            #"^(Closing Hymn):?"#,
            #"^(Benediction):?"#
        ]
        
        for pattern in headerPatterns {
            let headerRegex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let headerMatches = headerRegex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            
            if !headerMatches.isEmpty {
                let headerText = nsLine.substring(with: headerMatches[0].range(at: 1))
                    .trimmingCharacters(in: .whitespaces)
                return (id: UUID(), text: headerText, type: .sectionHeader, reference: nil)
            }
        }
        
        return nil
    }
    
    private func processHymns(_ line: String, _ nsLine: NSString) -> [ContentSegment]? {
        let hymnPattern = #"(?:Hymn(?:al)?\s+(?:#\s*)?|#\s*)(\d+)(?:\s+["""]([^"""]*)[""])?.*"#
        let hymnRegex = try! NSRegularExpression(pattern: hymnPattern, options: [.caseInsensitive])
        let hymnMatches = hymnRegex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        
        if hymnMatches.isEmpty { return nil }
        
        var segments: [ContentSegment] = []
        var lastIndex = 0
        
        for match in hymnMatches {
            if match.range.location > lastIndex {
                let text = nsLine.substring(with: NSRange(location: lastIndex, length: match.range.location - lastIndex))
                if !text.isEmpty {
                    segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
                }
            }
            
            let hymnNumber = Int(nsLine.substring(with: match.range(at: 1)))!
            let fullHymnText = nsLine.substring(with: match.range)
            segments.append((id: UUID(), text: fullHymnText, type: .hymn(number: hymnNumber), reference: nil))
            
            lastIndex = match.range.location + match.range.length
        }
        
        if lastIndex < nsLine.length {
            let text = nsLine.substring(from: lastIndex)
            if !text.isEmpty {
                segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
            }
        }
        
        return segments
    }
    
    private func processResponsiveReadings(_ line: String, _ nsLine: NSString) -> [ContentSegment]? {
        let responsivePattern = #"(?:Responsive\s+Reading\s+(?:#\s*)?|#\s*)(\d+)(?:\s+["""]([^"""]*)[""])?.*"#
        let responsiveRegex = try! NSRegularExpression(pattern: responsivePattern, options: [.caseInsensitive])
        let responsiveMatches = responsiveRegex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        
        if responsiveMatches.isEmpty { return nil }
        
        var segments: [ContentSegment] = []
        var lastIndex = 0
        
        for match in responsiveMatches {
            if match.range.location > lastIndex {
                let text = nsLine.substring(with: NSRange(location: lastIndex, length: match.range.location - lastIndex))
                if !text.isEmpty {
                    segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
                }
            }
            
            let readingNumber = Int(nsLine.substring(with: match.range(at: 1)))!
            let fullReadingText = nsLine.substring(with: match.range)
            segments.append((id: UUID(), text: fullReadingText, type: .responsiveReading(number: readingNumber), reference: nil))
            
            lastIndex = match.range.location + match.range.length
        }
        
        if lastIndex < nsLine.length {
            let text = nsLine.substring(from: lastIndex)
            if !text.isEmpty {
                segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
            }
        }
        
        return segments
    }
    
    private func processBibleVerses(_ line: String, _ nsLine: NSString) -> [ContentSegment]? {
        let versePattern = #"(?:^|\s|[,;])\s*(?:(?:1|2|3|I|II|III|First|Second|Third)\s+)?(?:Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|(?:1st|2nd|1|2)\s*Samuel|(?:1st|2nd|1|2)\s*Kings|(?:1st|2nd|1|2)\s*Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|Ecclesiastes|Song\s+of\s+Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|(?:1st|2nd|1|2)\s*Corinthians|Galatians|Ephesians|Philippians|Colossians|(?:1st|2nd|1|2)\s*Thessalonians|(?:1st|2nd|1|2)\s*Timothy|Titus|Philemon|Hebrews|James|(?:1st|2nd|1|2)\s*Peter|(?:1st|2nd|3rd|1|2|3)\s*John|Jude|Revelation)s?\s+\d+(?:[:.]\d+(?:-\d+)?)?(?:\s*,\s*\d+(?:[:.]\d+(?:-\d+)?)?)*"#
        let verseRegex = try! NSRegularExpression(pattern: versePattern, options: [.caseInsensitive])
        let verseMatches = verseRegex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        
        if verseMatches.isEmpty { return nil }
        
        var segments: [ContentSegment] = []
        var lastIndex = 0
        
        for match in verseMatches {
            if match.range.location > lastIndex {
                let text = nsLine.substring(with: NSRange(location: lastIndex, length: match.range.location - lastIndex))
                if !text.isEmpty {
                    segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
                }
            }
            
            let verseText = nsLine.substring(with: match.range)
                .trimmingCharacters(in: .whitespaces)
            
            // Extract the complete verse reference including chapter and verse
            let referencePattern = #"(?:(?:1|2|3|I|II|III|First|Second|Third)\s+)?(?:Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|(?:1st|2nd|1|2)\s*Samuel|(?:1st|2nd|1|2)\s*Kings|(?:1st|2nd|1|2)\s*Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|Ecclesiastes|Song\s+of\s+Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|(?:1st|2nd|1|2)\s*Corinthians|Galatians|Ephesians|Philippians|Colossians|(?:1st|2nd|1|2)\s*Thessalonians|(?:1st|2nd|1|2)\s*Timothy|Titus|Philemon|Hebrews|James|(?:1st|2nd|1|2)\s*Peter|(?:1st|2nd|3rd|1|2|3)\s*John|Jude|Revelation)s?\s+\d+(?:[:.]\d+(?:-\d+)?)?(?:\s*,\s*\d+(?:[:.]\d+(?:-\d+)?)?)*"#
            let referenceRegex = try! NSRegularExpression(pattern: referencePattern, options: [.caseInsensitive])
            if let referenceMatch = referenceRegex.firstMatch(in: verseText, range: NSRange(location: 0, length: verseText.count)) {
                let reference = (verseText as NSString).substring(with: referenceMatch.range)
                segments.append((id: UUID(), text: verseText, type: .bibleVerse, reference: reference))
            }
            
            lastIndex = match.range.location + match.range.length
        }
        
        if lastIndex < nsLine.length {
            let text = nsLine.substring(from: lastIndex)
            if !text.isEmpty {
                segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
            }
        }
        
        return segments
    }
    
    private func formatBibleVerse(_ verse: String) -> String {
        // Strip out translation references (e.g., "KJV")
        let cleanVerse = verse.replacingOccurrences(of: #"(?:\s+(?:KJV|NIV|ESV|NKJV|NLT|RSV|ASV|CEV|GNT|MSG|NET|NRSV|WEB|YLT|DBY|WNT|BBE|DARBY|WBS|KJ21|AKJV|ASV1901|CEB|CJB|CSB|ERV|EHV|EXB|GNV|GW|ICB|ISV|JUB|LEB|MEV|MOUNCE|NOG|OJB|RGT|TLV|VOICE|WYC|WYNN|YLT1898))"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
        
        // Convert "Romans 4:11" to "rom.4.11" for Bible.com links
        let bookMap = [
            "Genesis": "gen", "Exodus": "exo", "Leviticus": "lev", "Numbers": "num",
            "Deuteronomy": "deu", "Joshua": "jos", "Judges": "jdg", "Ruth": "rut",
            "1 Samuel": "1sa", "2 Samuel": "2sa", "1 Kings": "1ki", "2 Kings": "2ki",
            "1 Chronicles": "1ch", "2 Chronicles": "2ch", "Ezra": "ezr", "Nehemiah": "neh",
            "Esther": "est", "Job": "job", "Psalm": "psa", "Psalms": "psa", "Proverbs": "pro",
            "Ecclesiastes": "ecc", "Song of Solomon": "sng", "Isaiah": "isa", "Jeremiah": "jer",
            "Lamentations": "lam", "Ezekiel": "ezk", "Daniel": "dan", "Hosea": "hos",
            "Joel": "jol", "Amos": "amo", "Obadiah": "oba", "Jonah": "jon",
            "Micah": "mic", "Nahum": "nam", "Habakkuk": "hab", "Zephaniah": "zep",
            "Haggai": "hag", "Zechariah": "zec", "Malachi": "mal", "Matthew": "mat",
            "Mark": "mrk", "Luke": "luk", "John": "jhn", "Acts": "act",
            "Romans": "rom", "1 Corinthians": "1co", "2 Corinthians": "2co", "Galatians": "gal",
            "Ephesians": "eph", "Philippians": "php", "Colossians": "col", "1 Thessalonians": "1th",
            "2 Thessalonians": "2th", "1 Timothy": "1ti", "2 Timothy": "2ti", "Titus": "tit",
            "Philemon": "phm", "Hebrews": "heb", "James": "jas", "1 Peter": "1pe",
            "2 Peter": "2pe", "1 John": "1jn", "2 John": "2jn", "3 John": "3jn",
            "Jude": "jud", "Revelation": "rev"
        ]
        
        let components = cleanVerse.components(separatedBy: " ")
        guard components.count >= 2 else { return cleanVerse.lowercased() }
        
        // Handle book name (including numbered books like "1 Corinthians")
        var bookName = ""
        var remainingComponents: [String] = components
        
        if let firstComponent = components.first, let _ = Int(firstComponent) {
            if components.count >= 2 {
                bookName = components[0] + " " + components[1]
                remainingComponents = Array(components.dropFirst(2))
            }
        } else {
            bookName = components[0]
            remainingComponents = Array(components.dropFirst())
        }
        
        guard let bookCode = bookMap[bookName] else { return cleanVerse.lowercased() }
        
        // Format chapter and verse
        let reference = remainingComponents.joined(separator: "")
            .replacingOccurrences(of: ":", with: ".")
            .replacingOccurrences(of: "-", with: "-")
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
        
        return "\(bookCode).\(reference)"
    }
    
    private func renderTextSegment(_ segment: ContentSegment) -> some View {
        Text(segment.text)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            .foregroundColor(.primary)
    }
    
    private func renderHymnSegment(_ segment: ContentSegment, number: Int) -> some View {
        Button(action: {
            AppAvailabilityService.shared.openHymnByNumber(number)
        }) {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .foregroundColor(.blue)
                Text(segment.text)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    private func renderResponsiveReadingSegment(_ segment: ContentSegment, number: Int) -> some View {
        Button(action: {
            AppAvailabilityService.shared.openResponsiveReadingByNumber(number)
        }) {
            HStack {
                Image(systemName: "book")
                    .foregroundColor(.blue)
                Text("Responsive Reading #\(number)")
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func renderBibleVerseSegment(_ segment: ContentSegment, reference: String) -> some View {
        Button(action: {
            let formattedVerse = formatBibleVerse(reference)
            if let url = URL(string: "https://www.bible.com/bible/1/\(formattedVerse)") {
                UIApplication.shared.open(url)
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                Text(segment.text)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }
    
    private func renderSectionHeaderSegment(_ segment: ContentSegment) -> some View {
        Text(segment.text)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 16)
            .padding(.bottom, 4)
            .padding(.horizontal, 8)
    }
    
    private func renderLine(_ line: String) -> some View {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        guard !trimmedLine.isEmpty else { return AnyView(EmptyView()) }
        
        return AnyView(
            HStack(alignment: .center, spacing: 4) {
                ForEach(processLine(trimmedLine), id: \.id) { segment in
                    switch segment.type {
                    case .text:
                        renderTextSegment(segment)
                    case .hymn(let number):
                        renderHymnSegment(segment, number: number)
                    case .responsiveReading(let number):
                        renderResponsiveReadingSegment(segment, number: number)
                    case .bibleVerse:
                        if let reference = segment.reference {
                            renderBibleVerseSegment(segment, reference: reference)
                        }
                    case .sectionHeader:
                        renderSectionHeaderSegment(segment)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        )
    }
    
    private func renderSection(_ title: String, content: String) -> some View {
        VStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
            
            VStack(alignment: .center, spacing: 12) {
                ForEach(Array(zip(content.components(separatedBy: .newlines).indices, 
                                content.components(separatedBy: .newlines))), id: \.0) { _, line in
                    renderLine(line)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            ForEach(sectionOrder, id: \.0) { (title, keyPath) in
                let content = bulletin[keyPath: keyPath]
                if !content.isEmpty {
                    renderSection(title, content: content)
                    
                    if title != sectionOrder.last?.0 {
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    BulletinView()
}
