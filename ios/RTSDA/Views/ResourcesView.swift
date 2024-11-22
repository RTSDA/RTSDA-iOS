import SwiftUI
import SafariServices

struct ResourcesView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    
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
                ResourceButton(
                    title: "SDA Hymnal",
                    icon: "music.note.list",
                    detail: "Access the digital hymnal",
                    action: openHymnal
                )
                
                ResourceButton(
                    title: "Sabbath School",
                    icon: "book.fill",
                    detail: "Weekly lesson study guides",
                    action: openSabbathSchool
                )
                
                ResourceButton(
                    title: "EGW Writings",
                    icon: "books.vertical.fill",
                    detail: "Access EGW Writings",
                    action: openEGWWritings
                )
                
                ResourceButton(
                    title: "Bible",
                    icon: "book.closed.fill",
                    detail: "Access the Bible",
                    action: openBible
                )
            }
        }
        .navigationTitle("Resources")
    }
    
    private func openEGWWritings() {
        let egwScheme = "egw-writings://"
        let appStoreURL = "https://apps.apple.com/us/app/egw-writings-2/id994076136"
        
        if let url = URL(string: egwScheme),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // If app is not installed, open App Store
            if let url = URL(string: appStoreURL) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func openBible() {
        let bibleScheme = "youversion://"
        let appStoreURL = "https://apps.apple.com/us/app/bible/id282935706"
        
        if let url = URL(string: bibleScheme),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // If app is not installed, open App Store
            if let url = URL(string: appStoreURL) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func openHymnal() {
        let hymnalScheme = "adventisthymnal://"
        let appStoreURL = "https://apps.apple.com/us/app/adventist-hymnal/id1153114394"
        
        if let url = URL(string: hymnalScheme),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // If app is not installed, open App Store
            if let url = URL(string: appStoreURL) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    private func openSabbathSchool() {
        let schemes = [
            "com.googleusercontent.apps.96814818762-k7l0r7no343dms51ss59q6c5dslujcu7://",
            "fb1440555266255436://",
            "com.googleusercontent.apps.443920152945-d0kf5h2dubt0jbcntq8l0qeg6lbpgn60://"
        ]
        
        for scheme in schemes {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // If app is not installed, open App Store
        if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id895272167") {
            UIApplication.shared.open(appStoreURL)
        }
    }
}

struct ResourceButton: View {
    let title: String
    let icon: String
    let detail: String
    let action: () -> Void
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        Button(action: action) {
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
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .imageScale(.small)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ResourcesView()
}
