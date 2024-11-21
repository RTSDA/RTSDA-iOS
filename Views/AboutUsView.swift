import SwiftUI

struct AboutUsView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Church Logo
                Image("church_logo")
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
                    
                    ServiceTimesView()
                }
                
                // Location
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.title2)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    Text("8 King Street\nTolland, CT 06084")
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
                    .accessibilityLabel("Get directions to 8 King Street, Tolland, CT 06084")
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
                            Text("(860) 875-2197")
                                .font(.body)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        }
                    }
                    .accessibilityLabel("Call us at (860) 875-2197")
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
                        
                        Button(action: openFacebook) {
                            Image(systemName: "facebook")
                                .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                                .font(.title)
                        }
                        .accessibilityLabel("Visit our Facebook page")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("About Us")
    }
    
    private func openMaps() {
        if let url = URL(string: "maps://?address=8 King Street, Tolland, CT 06084") {
            UIApplication.shared.open(url)
        }
    }
    
    private func makePhoneCall() {
        if let url = URL(string: "tel:8608752197") {
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

struct ServiceTimesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sabbath School: 9:30 AM")
            Text("Divine Service: 11:00 AM")
            Text("Prayer Meeting: Wednesday 6:30 PM")
        }
        .font(.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

#Preview {
    AboutUsView()
}
