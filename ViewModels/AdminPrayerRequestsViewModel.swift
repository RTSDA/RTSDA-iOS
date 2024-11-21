import Foundation
import FirebaseFirestore

@MainActor
final class AdminPrayerRequestsViewModel: ObservableObject {
    @Published var prayerRequests: [PrayerRequest] = []
    private let db = Firestore.firestore()
    
    func fetchPrayerRequests() async {
        do {
            let snapshot = try await db.collection("prayerRequests")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            prayerRequests = snapshot.documents.compactMap { document -> PrayerRequest? in
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let email = data["email"] as? String,
                      let requestTypeString = data["requestType"] as? String,
                      let requestType = PrayerRequest.RequestType(rawValue: requestTypeString),
                      let details = data["details"] as? String,
                      let isConfidential = data["isConfidential"] as? Bool,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                
                let prayedFor = data["prayedFor"] as? Bool ?? false
                let prayedForDate = (data["prayedForDate"] as? Timestamp)?.dateValue()
                
                return PrayerRequest(
                    id: document.documentID,
                    name: name,
                    email: email,
                    requestType: requestType,
                    details: details,
                    isConfidential: isConfidential,
                    timestamp: timestamp,
                    prayedFor: prayedFor,
                    prayedForDate: prayedForDate
                )
            }
            
            print("Fetched \(prayerRequests.count) prayer requests")
        } catch {
            print("Error fetching prayer requests: \(error)")
        }
    }
    
    func updatePrayedForStatus(request: PrayerRequest) async {
        do {
            let data: [String: Any] = [
                "prayedFor": request.prayedFor,
                "prayedForDate": request.prayedFor ? Timestamp(date: Date()) as Any : NSNull()
            ]
            
            try await db.collection("prayerRequests").document(request.id).updateData(data)
            
            // Update local state
            if let index = prayerRequests.firstIndex(where: { $0.id == request.id }) {
                prayerRequests[index] = request
            }
            
            print("Updated prayer request status: \(request.id) - Prayed For: \(request.prayedFor)")
        } catch {
            print("Error updating prayer request status: \(error)")
        }
    }
    
    func deletePrayerRequest(_ request: PrayerRequest) async {
        do {
            try await db.collection("prayerRequests").document(request.id).delete()
            await fetchPrayerRequests()
        } catch {
            print("Error deleting prayer request: \(error)")
        }
    }
} 