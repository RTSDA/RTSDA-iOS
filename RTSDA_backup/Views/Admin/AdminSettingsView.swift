import SwiftUI

struct AdminSettingsView: View {
    @ObservedObject private var authService = AdminAuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        List {
            Button(role: .destructive) {
                signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .navigationTitle("Settings")
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signOut() {
        do {
            try authService.signOut()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
} 