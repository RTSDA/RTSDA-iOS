import SwiftUI
import FirebaseFirestore

struct AdminView: View {
    var body: some View {
        List {
            NavigationLink {
                AdminEventView()
            } label: {
                Label("Events", systemImage: "calendar")
            }
            
            NavigationLink {
                AdminPrayerRequestsView()
            } label: {
                Label("Prayer Requests", systemImage: "hands.sparkles.fill")
            }
        }
        .navigationTitle("Admin")
    }
} 