import SwiftUI
import SafariServices
import OSLog

struct ResourcesView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @StateObject private var resourceService = ResourceService.shared
    private let logger = Logger(subsystem: "org.rtsda.app", category: "ResourcesView")
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Church Resources")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Access our church's digital resources and study materials.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            }
            
            Section(header: Text("Study Materials").textCase(.none)) {
                ForEach(resourceService.resources, id: \.key) { resource in
                    let title = titleForKey(resource.key)
                    let icon = iconForKey(resource.key)
                    let detail = detailForKey(resource.key)
                    
                    Button {
                        logger.notice("🔵 Resource button tapped: \(resource.key)")
                        resourceService.openResource(resource)
                    } label: {
                        HStack {
                            Image(systemName: icon)
                                .foregroundColor(.accentColor)
                                .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                                .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(detail)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if resourceService.installedApps.contains(resource.key) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .imageScale(.small)
                            } else {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .imageScale(.small)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Resources")
        .task {
            logger.notice("📱 ResourcesView appeared")
            await resourceService.checkInstalledApps()
        }
    }
    
    private func titleForKey(_ key: String) -> String {
        switch key {
        case "bible": return "Bible"
        case "sabbathSchool": return "Sabbath School"
        case "egw": return "EGW Writings"
        case "hymnal": return "SDA Hymnal"
        default: return ""
        }
    }
    
    private func iconForKey(_ key: String) -> String {
        switch key {
        case "bible": return "book.closed.fill"
        case "sabbathSchool": return "book.fill"
        case "egw": return "books.vertical.fill"
        case "hymnal": return "music.note.list"
        default: return ""
        }
    }
    
    private func detailForKey(_ key: String) -> String {
        switch key {
        case "bible": return "Access the Bible"
        case "sabbathSchool": return "Weekly lesson study guides"
        case "egw": return "Access EGW Writings"
        case "hymnal": return "Access the digital hymnal"
        default: return ""
        }
    }
}

#Preview {
    ResourcesView()
}
