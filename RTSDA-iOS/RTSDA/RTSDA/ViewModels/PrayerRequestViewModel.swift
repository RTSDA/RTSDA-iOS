import Foundation
import FirebaseFirestore

struct PrayerRequest: Codable, Identifiable {
    var id: String?
    let name: String
    let email: String?
    let phone: String?
    let requestType: String
    let request: String
    let isPrivate: Bool
    let isAnonymous: Bool
    let timestamp: Date
    let status: String // "pending", "praying", "answered"
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case requestType
        case request = "message"
        case isPrivate = "private"
        case isAnonymous
        case timestamp
        case status
    }
}

enum RequestType: String, CaseIterable {
    case personal = "Personal"
    case family = "Family"
    case health = "Health"
    case financial = "Financial"
    case spiritual = "Spiritual"
    case other = "Other"
}

@MainActor
class PrayerRequestViewModel: ObservableObject {
    @Published var isSubmitting = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    private let db = Firestore.firestore()
    
    func submitPrayerRequest(
        name: String,
        email: String?,
        phone: String?,
        requestType: String,
        request: String,
        isPrivate: Bool,
        isAnonymous: Bool
    ) async {
        isSubmitting = true
        errorMessage = ""
        
        do {
            let data: [String: Any] = [
                "name": name,
                "email": email as Any,
                "phone": phone as Any,
                "requestType": requestType,
                "message": request,
                "private": isPrivate,
                "isAnonymous": isAnonymous,
                "timestamp": FieldValue.serverTimestamp(),
                "status": "pending"
            ]
            
            try await db.collection("prayerRequests").addDocument(data: data)
            
            isSubmitting = false
            showSuccessAlert = true
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
