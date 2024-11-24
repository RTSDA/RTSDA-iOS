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
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    Text("Access our church's digital resources and study materials.")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Study Materials").font(.headline)) {
                ResourceButton(
                    title: "SDA Hymnal",
                    icon: "music.note.list",
                    detail: "Access the digital hymnal"
                ) {
                    NavigationLink(destination: HymnalBrowserView()) {
                        EmptyView()
                    }
                }
                
                ResourceButton(
                    title: "Sabbath School",
                    icon: "book.fill",
                    detail: "Weekly lesson study guides"
                ) {
                    Button(action: openSabbathSchool) {
                        EmptyView()
                    }
                }
                
                ResourceButton(
                    title: "EGW Writings",
                    icon: "books.vertical.fill",
                    detail: "Access EGW Writings"
                ) {
                    Button(action: openEGWWritings) {
                        EmptyView()
                    }
                }
                
                ResourceButton(
                    title: "Bible",
                    icon: "book.closed.fill",
                    detail: "Access the Bible"
                ) {
                    Button(action: openBible) {
                        EmptyView()
                    }
                }
            }
        }
        .navigationTitle("Resources")
    }
    
    private func openEGWWritings() {
        let egwScheme = "egw-writings://"
        
        if let url = URL(string: egwScheme),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // If app is not installed, open App Store
            if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id994076136") {
                UIApplication.shared.open(appStoreURL)
            }
        }
    }
    
    private func openBible() {
        let bibleScheme = "youversion://"
        
        if let url = URL(string: bibleScheme),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // If app is not installed, open App Store
            if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id282935706") {
                UIApplication.shared.open(appStoreURL)
            }
        }
    }
    
    private func openSabbathSchool() {
        let schemes = [
            "com.googleusercontent.apps.96814818762-k7l0r7no343dms51ss59q6c5dslujcu7://",
            "fb1440555266255436://",
            "com.googleusercontent.apps.443920152945-d0kf5h2dubt0jbcntq8l0qeg6lbpgn60://"
        ]
        
        print("Trying to open Sabbath School app...")
        
        for scheme in schemes {
            if let url = URL(string: scheme) {
                print("Trying scheme: \(scheme)")
                if UIApplication.shared.canOpenURL(url) {
                    print("Found working scheme: \(scheme)")
                    UIApplication.shared.open(url)
                    return
                }
            }
        }
        
        print("No schemes worked, opening App Store...")
        if let appStoreURL = URL(string: "itms-apps://itunes.apple.com/app/id895272167") {
            UIApplication.shared.open(appStoreURL)
        }
    }
}

struct ResourceButton: View {
    let title: String
    let icon: String
    let detail: String
    let destination: () -> AnyView
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        NavigationLink(destination: destination()) {
            HStack {
                Image(systemName: icon)
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    Text(detail)
                        .font(.subheadline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .accessibilityLabel("\(title): \(detail)")
        .accessibilityHint("Tap to view \(title.lowercased())")
    }
}

#Preview {
    ResourcesView()
}
