import SwiftUI
import MessageUI

struct ConnectView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var showingMailComposer = false
    @State private var showingError = false
    
    private let churchPhone = "860-875-0450"
    private let churchEmail = "info@rockvilletollandsda.org"
    private let churchWebsite = "https://rockvilletollandsda.org"
    private let churchAddress = "9 Hartford Turnpike, Tolland, CT 06084"
    private let facebookURL = "https://www.facebook.com/rockvilletollandsdachurch/"
    private let tiktokURL = "https://tiktok.com/@rockvilletollandsda"
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Get in Touch")
                        .font(.title2)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    Text("We'd love to hear from you! Here are the ways you can connect with our church community.")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Contact Information").font(.headline)) {
                ContactButton(
                    title: "Email Us",
                    icon: "envelope.fill",
                    detail: churchEmail,
                    action: composeEmail
                )
                
                ContactButton(
                    title: "Call Us",
                    icon: "phone.fill",
                    detail: churchPhone,
                    action: makePhoneCall
                )
                
                ContactButton(
                    title: "Visit Us",
                    icon: "map.fill",
                    detail: churchAddress,
                    action: openMaps
                )
            }
            
            Section(header: Text("Social Media").font(.headline)) {
                ContactButton(
                    title: "YouTube",
                    icon: "play.rectangle.fill",
                    detail: "Watch our services and events",
                    action: openYouTube
                )
                
                ContactButton(
                    title: "Facebook",
                    icon: "facebook",
                    detail: "Follow us for updates",
                    action: openFacebook
                )
                
                ContactButton(
                    title: "TikTok",
                    icon: "music.note.list",
                    detail: "Follow us on TikTok",
                    action: openTikTok
                )
            }
            
            Section(header: Text("Church Website").font(.headline)) {
                ContactButton(
                    title: "Visit Website",
                    icon: "globe",
                    detail: churchWebsite,
                    action: openWebsite
                )
            }
        }
        .navigationTitle("Contact & Connect")
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Unable to perform this action. Please try again.")
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
    }
    
    private func composeEmail() {
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            showingError = true
        }
    }
    
    private func makePhoneCall() {
        if let url = URL(string: "tel:\(churchPhone.replacingOccurrences(of: "-", with: ""))") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openMaps() {
        let addressEncoded = churchAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let appleMapsURL = URL(string: "maps://?address=\(addressEncoded)") {
            if UIApplication.shared.canOpenURL(appleMapsURL) {
                UIApplication.shared.open(appleMapsURL)
            } else {
                // Fallback to Google Maps web URL
                if let googleMapsURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(addressEncoded)") {
                    UIApplication.shared.open(googleMapsURL)
                }
            }
        }
    }
    
    private func openYouTube() {
        if let url = URL(string: "https://www.youtube.com/@RockvilleTollandSDAChurch") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openFacebook() {
        if let url = URL(string: facebookURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTikTok() {
        if let url = URL(string: tiktokURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite() {
        if let url = URL(string: churchWebsite) {
            UIApplication.shared.open(url)
        }
    }
}

struct ContactButton: View {
    let title: String
    let icon: String
    let detail: String
    let action: () -> Void
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        Button(action: action) {
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
        .accessibilityHint("Tap to \(title.lowercased())")
    }
}

#Preview {
    ConnectView()
}