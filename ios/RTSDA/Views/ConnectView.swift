import SwiftUI
import MessageUI

struct ConnectView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var showingMailComposer = false
    @State private var showingError = false
    @State private var mailData = ComposeMailData(
        toRecipients: ["info@rockvilletollandsda.org"],
        subject: "Contact from RTSDA App",
        messageBody: "",
        attachments: []
    )
    
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
                    icon: "link.circle.fill",
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
        .sheet(isPresented: $showingMailComposer) {
            MailView(mailData: $mailData)
        }
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
        } else if let mailtoURL = URL(string: "mailto:\(churchEmail)") {
            UIApplication.shared.open(mailtoURL)
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

struct ComposeMailData {
    let toRecipients: [String]
    let subject: String
    let messageBody: String
    let attachments: [AttachmentData]
}

struct AttachmentData {
    let data: Data
    let mimeType: String
    let fileName: String
}

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentation
    @Binding var mailData: ComposeMailData
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentation: PresentationMode
        
        init(presentation: Binding<PresentationMode>) {
            _presentation = presentation
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                 didFinishWith result: MFMailComposeResult,
                                 error: Error?) {
            if let error = error {
                print("Mail compose error: \(error.localizedDescription)")
            }
            $presentation.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(presentation: presentation)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = context.coordinator
        mailComposer.setToRecipients(mailData.toRecipients)
        mailComposer.setSubject(mailData.subject)
        mailComposer.setMessageBody(mailData.messageBody, isHTML: false)
        
        for attachment in mailData.attachments {
            mailComposer.addAttachmentData(
                attachment.data,
                mimeType: attachment.mimeType,
                fileName: attachment.fileName
            )
        }
        
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
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
    ConnectView()
}