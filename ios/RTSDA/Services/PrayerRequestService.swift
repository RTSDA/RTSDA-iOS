import Foundation
import FirebaseFirestore

class PrayerRequestService {
    static let shared = PrayerRequestService()
    private let db = Firestore.firestore()
    
    // Submit a new prayer request
    func submitRequest(_ request: PrayerRequest) async throws -> Bool {
        let data: [String: Any] = [
            "name": request.name,
            "email": request.email,
            "phone": request.phone,
            "request": request.request,
            "timestamp": Timestamp(date: Date()),
            "status": PrayerRequest.RequestStatus.new.rawValue,
            "isPrivate": request.isPrivate,
            "requestType": request.requestType.rawValue
        ]
        
        do {
            _ = try await db.collection("prayerRequests").addDocument(data: data)
            return true
        } catch {
            print("Error submitting prayer request: \(error)")
            throw error
        }
    }
    
    // Get all prayer requests (for admin)
    func getPrayerRequests() async throws -> [PrayerRequest] {
        do {
            let snapshot = try await db.collection("prayerRequests")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            return snapshot.documents.compactMap { document in
                do {
                    let data = document.data()
                    let timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date())
                    
                    return PrayerRequest(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String ?? "",
                        phone: data["phone"] as? String ?? "",
                        request: data["request"] as? String ?? "",
                        timestamp: timestamp,
                        status: PrayerRequest.RequestStatus(rawValue: data["status"] as? String ?? "") ?? .new,
                        isPrivate: data["isPrivate"] as? Bool ?? false,
                        requestType: PrayerRequest.RequestType(rawValue: data["requestType"] as? String ?? "") ?? .personal
                    )
                } catch {
                    print("Error decoding prayer request: \(error)")
                    return nil
                }
            }
        } catch {
            print("Error getting prayer requests: \(error)")
            throw error
        }
    }
    
    // Update prayer request status (for admin)
    func updateStatus(requestId: String, status: PrayerRequest.RequestStatus) async throws {
        do {
            try await db.collection("prayerRequests").document(requestId)
                .updateData(["status": status.rawValue])
        } catch {
            print("Error updating prayer request status: \(error)")
            throw error
        }
    }
    
    // Delete prayer request (for admin)
    func deleteRequest(requestId: String) async throws {
        do {
            try await db.collection("prayerRequests").document(requestId).delete()
        } catch {
            print("Error deleting prayer request: \(error)")
            throw error
        }
    }
    
    // Create a new prayer request
    func createPrayerRequest(name: String, email: String, phone: String, request: String, isPrivate: Bool, requestType: PrayerRequest.RequestType = .personal) async throws {
        let timestamp = Timestamp(date: Date())
        let prayerRequest = PrayerRequest(
            id: "",
            name: name,
            email: email,
            phone: phone,
            request: request,
            timestamp: timestamp,
            status: .new,
            isPrivate: isPrivate,
            requestType: requestType
        )
    }
}