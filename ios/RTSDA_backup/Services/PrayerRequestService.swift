import Foundation
import FirebaseFirestore

class PrayerRequestService {
    static let shared = PrayerRequestService()
    private let db = Firestore.firestore()
    
    func submitRequest(_ request: PrayerRequest) async throws -> Bool {
        let data: [String: Any] = [
            "name": request.name,
            "email": request.email,
            "requestType": request.requestType.rawValue,
            "details": request.details,
            "isConfidential": request.isConfidential,
            "timestamp": Timestamp(date: Date())
        ]
        
        do {
            _ = try await db.collection("prayerRequests").addDocument(data: data)
            return true
        } catch {
            print("Error submitting prayer request: \(error)")
            throw error
        }
    }
} 