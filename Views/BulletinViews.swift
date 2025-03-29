import SwiftUI

struct BulletinListView: View {
    @StateObject private var viewModel = BulletinViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
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
                    VStack {
                        Text("No Bulletins")
                            .font(.headline)
                        Text("No bulletins are available at this time.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(viewModel.bulletins) { bulletin in
                        NavigationLink(destination: BulletinDetailView(bulletin: bulletin)) {
                            BulletinRowView(bulletin: bulletin)
                        }
                    }
                }
            }
            .navigationTitle("Church Bulletins")
            .task {
                await viewModel.loadBulletins()
            }
        }
    }
}

struct BulletinDetailView: View {
    let bulletin: Bulletin
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(bulletin.date.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(bulletin.title)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                // PDF Download Button
                if let pdfUrl = bulletin.pdfUrl, let url = URL(string: pdfUrl) {
                    Link(destination: url) {
                        Label("Download PDF", systemImage: "doc.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                // Sections
                ForEach(bulletin.sections, id: \.title) { section in
                    BulletinSectionView(section: section)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BulletinSectionView: View {
    let section: BulletinSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.headline)
            
            if section.title == "Scripture Reading" {
                ScriptureReadingView(content: section.content)
            } else {
                BulletinContentText(content: section.content)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct ScriptureReadingView: View {
    let content: String
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(content.components(separatedBy: .newlines), id: \.self) { line in
                if !line.isEmpty {
                    Text(line)
                        .font(.body)
                        .foregroundColor(line.contains("Acts") ? .primary : .secondary)
                }
            }
        }
    }
}

struct BulletinContentText: View {
    let content: String
    
    var formattedContent: [(label: String?, value: String)] {
        content.components(separatedBy: .newlines)
            .map { line -> (String?, String) in
                let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    return (parts[0].trimmingCharacters(in: .whitespaces),
                           parts[1].trimmingCharacters(in: .whitespaces))
                }
                return (nil, line)
            }
            .filter { !$0.1.isEmpty }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(formattedContent, id: \.1) { item in
                if let label = item.label {
                    VStack(spacing: 4) {
                        Text(label)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(item.value)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(item.value)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct BulletinRowView: View {
    let bulletin: Bulletin
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bulletin.date.formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(bulletin.title)
                .font(.headline)
                .lineLimit(2)
            
            if bulletin.pdfUrl != nil {
                Label("PDF Available", systemImage: "doc.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
} 