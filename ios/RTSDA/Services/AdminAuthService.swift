import Foundation
import FirebaseAuth
import FirebaseFirestore

class AdminAuthService: ObservableObject {
    static let shared = AdminAuthService()
    @Published var isAdmin = false
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    
    private init() {
        // Set persistence to .none to prevent automatic sign in
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            Task {
                await self?.checkAdminStatus(userId: user?.uid)
            }
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("Attempting to sign in with email: \(email)")
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        print("Sign in successful for user: \(result.user.uid)")
        await checkAdminStatus(userId: result.user.uid)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        isAdmin = false
    }
    
    @MainActor
    private func checkAdminStatus(userId: String?) async {
        guard let userId = userId else {
            print("No user ID provided")
            isAdmin = false
            return
        }
        
        do {
            print("Checking admin status for user: \(userId)")
            let docSnapshot = try await db.collection("admins").document(userId).getDocument()
            isAdmin = docSnapshot.exists
            print("Admin status: \(isAdmin)")
        } catch {
            print("Error checking admin status: \(error)")
            isAdmin = false
        }
    }
} 

