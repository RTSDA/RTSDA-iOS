import SwiftUI
import FirebaseAuth

struct AdminLoginView: View {
    @ObservedObject private var authService = AdminAuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if authService.isAdmin {
                AdminDashboardView()
            } else {
                Form {
                    Section {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disabled(isLoading)
                        
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .disabled(isLoading)
                    }
                    
                    Section {
                        Button {
                            Task {
                                await signIn()
                            }
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Sign In")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(email.isEmpty || password.isEmpty || isLoading)
                    }
                }
                .navigationTitle("Admin Login")
                .alert("Error", isPresented: $showingError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func signIn() async {
        isLoading = true
        print("Starting sign in process")
        
        do {
            try await authService.signIn(email: email, password: password)
            print("Sign in completed successfully")
        } catch {
            print("Sign in error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
} 