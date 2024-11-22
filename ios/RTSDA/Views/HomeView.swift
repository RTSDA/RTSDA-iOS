import SwiftUI
import MapKit

struct HomeView: View {
    private let churchAddress = "9 Hartford Turnpike, Tolland, CT 06084"
    @State private var showingDonationView = false
    @State private var showingServiceTimes = false
    @State private var showingPrayerRequest = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Church Logo/Header
                    Image("second-coming")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .padding()
                        .accessibilityLabel("Church Logo")
                    
                    // Welcome Message
                    Text("Welcome to\nRockville-Tolland SDA Church")
                        .font(.title)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    // Quick Links
                    VStack(spacing: 15) {
                        QuickLinkButton(title: "Service Times", icon: "clock.fill") {
                            showingServiceTimes = true
                        }
                        
                        QuickLinkButton(title: "Directions", icon: "map.fill") {
                            openMaps()
                        }
                        
                        QuickLinkButton(title: "Give Online", icon: "heart.fill") {
                            showingDonationView = true
                        }
                        
                        QuickLinkButton(title: "Prayer Request", icon: "hands.sparkles.fill") {
                            showingPrayerRequest = true
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Home")
            .sheet(isPresented: $showingDonationView) {
                GiveOnlineView()
            }
            .sheet(isPresented: $showingServiceTimes) {
                ServiceTimesSheet()
            }
            .sheet(isPresented: $showingPrayerRequest) {
                PrayerRequestView()
            }
        }
    }
    
    private func openMaps() {
        let addressEncoded = churchAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Try Apple Maps first
        if let appleMapsURL = URL(string: "maps://?address=\(addressEncoded)") {
            if UIApplication.shared.canOpenURL(appleMapsURL) {
                UIApplication.shared.open(appleMapsURL)
                return
            }
        }
        
        // Fallback to Google Maps
        if let googleMapsURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(addressEncoded)") {
            UIApplication.shared.open(googleMapsURL)
        }
    }
}

struct QuickLinkButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.sizeCategory) var sizeCategory
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                Spacer()
                Image(systemName: "chevron.right")
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Tap to open \(title)")
    }
}

#Preview {
    HomeView()
}