import SwiftUI
import FirebaseAuth

struct AdminDashboardView: View {
    @ObservedObject private var authService = AdminAuthService.shared
    
    var body: some View {
        Group {
            if authService.isAdmin {
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
                    
                    NavigationLink {
                        AdminSettingsView()
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
                .navigationTitle("Admin Dashboard")
            } else {
                AdminLoginView()
            }
        }
    }
} 