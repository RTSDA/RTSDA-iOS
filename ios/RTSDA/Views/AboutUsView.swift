import SwiftUI

struct AboutUsView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Church Logo
                Image("sdalogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 200)
                    .accessibilityLabel("Rockville-Tolland SDA Church Logo")
                
                // Welcome Message
                VStack(alignment: .leading, spacing: 16) {
                    Text("Welcome to Our Church")
                        .font(.title)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    Text("We are a warm and welcoming Seventh-day Adventist congregation located in Tolland, Connecticut. Our mission is to share God's love and the hope of His soon return with our community.")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                }
                
                // Service Times
                VStack(alignment: .leading, spacing: 12) {
                    Text("Service Times")
                        .font(.title2)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    RTSDAServiceTimesView()
                }
                
                // Location
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.title2)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    Text("9 Hartford Tpke\nTolland, CT 06084")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    
                    Button(action: openMaps) {
                        Text("Get Directions")
                            .font(.headline)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .accessibilityLabel("Get directions to 9 Hartford Tpke, Tolland, CT 06084")
                    .accessibilityHint("Opens Maps app with directions to our church")
                }
                
                // Contact Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact Us")
                        .font(.title2)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    Button(action: makePhoneCall) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                            Text("(860) 875-0450")
                                .font(.body)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        }
                    }
                    .accessibilityLabel("Call us at (860) 875-0450")
                    .accessibilityHint("Opens Phone app to call our church")
                    
                    Button(action: sendEmail) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                            Text("info@rockvilletollandsda.org")
                                .font(.body)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        }
                    }
                    .accessibilityLabel("Email us at info@rockvilletollandsda.org")
                    .accessibilityHint("Opens Mail app to send us an email")
                }
                
                // Social Media
                VStack(alignment: .leading, spacing: 12) {
                    Text("Follow Us")
                        .font(.title2)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 20) {
                        Button(action: openYouTube) {
                            Image(systemName: "play.rectangle.fill")
                                .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                                .font(.title)
                        }
                        .accessibilityLabel("Visit our YouTube channel")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("About Us")
    }
    
    private func openMaps() {
        if let url = URL(string: "maps://?address=9 Hartford Tpke, Tolland, CT 06084") {
            UIApplication.shared.open(url)
        }
    }
    
    private func makePhoneCall() {
        if let url = URL(string: "tel:8608750450") {
            UIApplication.shared.open(url)
        }
    }
    
    private func sendEmail() {
        if let url = URL(string: "mailto:info@rockvilletollandsda.org") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openYouTube() {
        if let url = URL(string: "https://www.youtube.com/@RockvilleTollandSDAChurch") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openFacebook() {
        if let url = URL(string: "https://www.facebook.com/RockvilleTollandSDA") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    AboutUsView()
}
