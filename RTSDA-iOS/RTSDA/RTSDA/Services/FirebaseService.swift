import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    
    private init() {
        // Configure Firebase if it hasn't been configured yet
        if FirebaseApp.app() == nil {
            let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist")
            if let filePath = filePath,
               let options = FirebaseOptions(contentsOfFile: filePath) {
                FirebaseApp.configure(options: options)
            } else {
                // Use the same config as the web app for development
                let options = FirebaseOptions(
                    googleAppID: "1:YOUR_APP_ID:ios:YOUR_IOS_APP_ID",
                    gcmSenderID: "YOUR_SENDER_ID"
                )
                options.projectID = "rtsda-website"  // Same as web project
                options.storageBucket = "rtsda-website.appspot.com"
                FirebaseApp.configure(options: options)
            }
        }
    }
    
    // MARK: - Prayer Requests
    
    /// Subscribes to prayer request updates
    /// - Parameter completion: Called when prayer requests are updated
    func subscribeToPrayerRequests(completion: @escaping ([PrayerRequest]) -> Void) -> ListenerRegistration {
        let db = Firestore.firestore()
        return db.collection("prayerRequests")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching prayer requests: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let requests = documents.compactMap { document -> PrayerRequest? in
                    let data = document.data()
                    return PrayerRequest(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String,
                        phone: data["phone"] as? String,
                        requestType: data["requestType"] as? String ?? "",
                        request: data["message"] as? String ?? "",
                        isPrivate: data["private"] as? Bool ?? false,
                        isAnonymous: data["isAnonymous"] as? Bool ?? false,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        status: data["status"] as? String ?? "pending"
                    )
                }
                completion(requests)
            }
    }
    
    /// Updates the status of a prayer request
    /// - Parameters:
    ///   - requestId: The ID of the request to update
    ///   - newStatus: The new status ("pending", "praying", "answered")
    func updatePrayerRequestStatus(requestId: String, newStatus: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("prayerRequests")
            .document(requestId)
            .updateData(["status": newStatus])
    }
    
    /// Deletes a prayer request
    /// - Parameter requestId: The ID of the request to delete
    func deletePrayerRequest(requestId: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("prayerRequests")
            .document(requestId)
            .delete()
    }
}
