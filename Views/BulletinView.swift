import SwiftUI
import Foundation
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var error: Error?
    @State private var downloadTask: Task<Void, Never>?
    
    func makeUIView(context: Context) -> PDFView {
        print("PDFViewer: Creating PDFView")
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        print("PDFViewer: updateUIView called")
        print("PDFViewer: URL = \(url)")
        
        // Cancel any existing task
        downloadTask?.cancel()
        
        // Create new task
        downloadTask = Task {
            print("PDFViewer: Starting download task")
            isLoading = true
            error = nil
            
            do {
                print("PDFViewer: Downloading PDF data...")
                var request = URLRequest(url: url)
                request.timeoutInterval = 30 // 30 second timeout
                request.setValue("application/pdf", forHTTPHeaderField: "Accept")
                request.setValue("application/pdf", forHTTPHeaderField: "Content-Type")
                
                // Add authentication headers
                if let token = UserDefaults.standard.string(forKey: "authToken") {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                print("PDFViewer: Making request with headers: \(request.allHTTPHeaderFields ?? [:])")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                // Check if task was cancelled
                if Task.isCancelled {
                    print("PDFViewer: Task was cancelled, stopping download")
                    return
                }
                
                print("PDFViewer: Downloaded \(data.count) bytes")
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("PDFViewer: Invalid response type")
                    throw URLError(.badServerResponse)
                }
                
                print("PDFViewer: HTTP Status Code: \(httpResponse.statusCode)")
                print("PDFViewer: Response headers: \(httpResponse.allHeaderFields)")
                
                guard httpResponse.statusCode == 200 else {
                    print("PDFViewer: Bad HTTP status code: \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("PDFViewer: Error response: \(errorString)")
                    }
                    throw URLError(.badServerResponse)
                }
                
                // Check if task was cancelled again before processing data
                if Task.isCancelled {
                    print("PDFViewer: Task was cancelled before processing data")
                    return
                }
                
                // Create PDF document from data
                print("PDFViewer: Creating PDF document from data...")
                if let document = PDFDocument(data: data) {
                    print("PDFViewer: PDF document created successfully")
                    print("PDFViewer: Number of pages: \(document.pageCount)")
                    
                    // Final cancellation check before updating UI
                    if Task.isCancelled {
                        print("PDFViewer: Task was cancelled before updating UI")
                        return
                    }
                    
                    await MainActor.run {
                        uiView.document = document
                        isLoading = false
                        print("PDFViewer: PDF document set to view")
                    }
                } else {
                    print("PDFViewer: Failed to create PDF document from data")
                    print("PDFViewer: Data size: \(data.count) bytes")
                    print("PDFViewer: First few bytes: \(data.prefix(16).map { String(format: "%02x", $0) }.joined())")
                    throw URLError(.cannotDecodeContentData)
                }
            } catch {
                // Only show error if it's not a cancellation
                if !Task.isCancelled {
                    print("PDFViewer: Error loading PDF: \(error)")
                    print("PDFViewer: Error description: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        print("PDFViewer: Decoding error details: \(decodingError)")
                    }
                    if let urlError = error as? URLError {
                        print("PDFViewer: URL Error: \(urlError)")
                        print("PDFViewer: URL Error Code: \(urlError.code)")
                        print("PDFViewer: URL Error Description: \(urlError.localizedDescription)")
                    }
                    await MainActor.run {
                        self.error = error
                        isLoading = false
                    }
                } else {
                    print("PDFViewer: Task was cancelled, ignoring error")
                    await MainActor.run {
                        isLoading = false
                    }
                }
            }
        }
        
        // Wait for the task to complete
        Task {
            await downloadTask?.value
        }
    }
    
    static func dismantleUIView(_ uiView: PDFView, coordinator: ()) {
        print("PDFViewer: Dismantling view")
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
                
                // PDF Download Button
                if !bulletin.pdfUrl.isEmpty {
                    if let url = URL(string: bulletin.pdfUrl) {
                        Button(action: {
                            UIApplication.shared.open(url)
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
        
        // Match hymn numbers with surrounding text
        let hymnPattern = #"(?:Hymn(?:al)?\s+(?:#\s*)?|#\s*)(\d+)(?:\s+["""]([^"""]*)[""])?.*"#
        let hymnRegex = try! NSRegularExpression(pattern: hymnPattern, options: [.caseInsensitive])
        let hymnMatches = hymnRegex.matches(in: cleanedLine, range: NSRange(location: 0, length: nsLine.length))
        
        // Match Bible verses (simplified pattern)
        let versePattern = #"(?:^|\s|[,;])\s*(?:(?:1|2|3|I|II|III|First|Second|Third)\s+)?(?:Genesis|Exodus|Leviticus|Numbers|Deuteronomy|Joshua|Judges|Ruth|(?:1st|2nd|1|2)\s*Samuel|(?:1st|2nd|1|2)\s*Kings|(?:1st|2nd|1|2)\s*Chronicles|Ezra|Nehemiah|Esther|Job|Psalms?|Proverbs|Ecclesiastes|Song\s+of\s+Solomon|Isaiah|Jeremiah|Lamentations|Ezekiel|Daniel|Hosea|Joel|Amos|Obadiah|Jonah|Micah|Nahum|Habakkuk|Zephaniah|Haggai|Zechariah|Malachi|Matthew|Mark|Luke|John|Acts|Romans|(?:1st|2nd|1|2)\s*Corinthians|Galatians|Ephesians|Philippians|Colossians|(?:1st|2nd|1|2)\s*Thessalonians|(?:1st|2nd|1|2)\s*Timothy|Titus|Philemon|Hebrews|James|(?:1st|2nd|1|2)\s*Peter|(?:1st|2nd|3rd|1|2|3)\s*John|Jude|Revelation)s?\s+\d+(?::\d+(?:-\d+)?)?(?:\s*,\s*\d+(?::\d+(?:-\d+)?)?)*"#
        let verseRegex = try! NSRegularExpression(pattern: versePattern, options: [.caseInsensitive])
        let verseMatches = verseRegex.matches(in: cleanedLine, range: NSRange(location: 0, length: nsLine.length))
        
        if !hymnMatches.isEmpty {
            var lastIndex = 0
            
            for match in hymnMatches {
                // Add text before hymn
                if match.range.location > lastIndex {
                    let text = nsLine.substring(with: NSRange(location: lastIndex, length: match.range.location - lastIndex))
                    if !text.isEmpty {
                        segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
                    }
                }
                
                // Add entire hymn line
                let hymnNumber = Int(nsLine.substring(with: match.range(at: 1)))!
                let fullHymnText = nsLine.substring(with: match.range)
                segments.append((id: UUID(), text: fullHymnText, type: .hymn(number: hymnNumber), reference: nil))
                
                lastIndex = match.range.location + match.range.length
            }
            
            // Add remaining text
            if lastIndex < nsLine.length {
                let text = nsLine.substring(from: lastIndex)
                if !text.isEmpty {
                    segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
                }
            }
        } else if !verseMatches.isEmpty {
            var lastIndex = 0
            
            for match in verseMatches {
                // Add text before verse
                if match.range.location > lastIndex {
                    let text = nsLine.substring(with: NSRange(location: lastIndex, length: match.range.location - lastIndex))
                    if !text.isEmpty {
                        segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
                    }
                }
                
                // Add verse with full range, keeping KJV in display text
                let verseText = nsLine.substring(with: match.range)
                    .trimmingCharacters(in: .whitespaces)
                
                segments.append((id: UUID(), text: verseText, type: .bibleVerse, reference: verseText))
                
                lastIndex = match.range.location + match.range.length
            }
            
            // Add remaining text
            if lastIndex < nsLine.length {
                let text = nsLine.substring(from: lastIndex)
                if !text.isEmpty {
                    segments.append((id: UUID(), text: text.trimmingCharacters(in: .whitespaces), type: .text, reference: nil))
                }
            }
        } else {
            // Regular text
            segments.append((id: UUID(), text: cleanedLine, type: .text, reference: nil))
        }
        
        return segments
    }
    
    private func formatBibleVerse(_ verse: String) -> String {
        // Strip out translation references (e.g., "KJV")
        let cleanVerse = verse.replacingOccurrences(of: #"(?:\s+(?:KJV|NIV|ESV|NKJV|NLT|RSV|ASV|CEV|GNT|MSG|NET|NRSV|WEB|YLT|DBY|WNT|BBE|DARBY|WBS|KJ21|AKJV|ASV1901|CEB|CJB|CSB|ERV|EHV|EXB|GNV|GW|ICB|ISV|JUB|LEB|MEV|MOUNCE|NOG|OJB|RGT|TLV|VOICE|WYC|WYNN|YLT1898))"#, with: "", options: [.regularExpression, .caseInsensitive])
        
        // Convert "Romans 4:11" to "rom.4.11"
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
        
        return "\(bookCode).\(reference)"
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            ForEach(sectionOrder, id: \.0) { (title, keyPath) in
                let content = bulletin[keyPath: keyPath]
                if !content.isEmpty {
                    VStack(alignment: .center, spacing: 16) {
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 4)
                        
                        VStack(alignment: .center, spacing: 12) {
                            ForEach(Array(zip(content.components(separatedBy: .newlines).indices, content.components(separatedBy: .newlines))), id: \.0) { index, line in
                                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                                if !trimmedLine.isEmpty {
                                    HStack(alignment: .center, spacing: 4) {
                                        ForEach(processLine(trimmedLine), id: \.id) { segment in
                                            switch segment.type {
                                            case .text:
                                                Text(segment.text)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(.primary)
                                            case .hymn(let number):
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
                                            case .bibleVerse:
                                                if let reference = segment.reference {
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
                                            case .sectionHeader:
                                                Text(segment.text)
                                                    .font(.headline)
                                                    .multilineTextAlignment(.center)
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    
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
