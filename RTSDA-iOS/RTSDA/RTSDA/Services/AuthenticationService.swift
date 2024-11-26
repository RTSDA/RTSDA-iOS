import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentAdmin: Admin?
    @Published var isAuthenticated = false
    @Published var error: Error?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    func signIn(email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            print("Successfully signed in with UID:", result.user.uid)
            try await fetchAdminProfile(uid: result.user.uid)
        } catch {
            self.error = error
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            self.currentAdmin = nil
            self.isAuthenticated = false
        } catch {
            self.error = error
            throw error
        }
    }
    
    private func fetchAdminProfile(uid: String) async throws {
        let docSnapshot = try await db.collection("admins").document(uid).getDocument()
        
        guard let admin = Admin.fromDocument(docSnapshot) else {
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not authorized as admin"])
            self.error = error
            throw error
        }
        
        self.currentAdmin = admin
        self.isAuthenticated = true
    }
    
    func checkAuthState() {
        auth.addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            Task {
                if let user = user {
                    do {
                        try await self.fetchAdminProfile(uid: user.uid)
                    } catch {
                        self.error = error
                        try? self.signOut()
                    }
                } else {
                    self.currentAdmin = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
}
