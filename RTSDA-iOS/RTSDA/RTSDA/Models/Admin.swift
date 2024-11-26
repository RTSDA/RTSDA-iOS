import Foundation
import FirebaseFirestore

struct Admin: Codable {
    let id: String
    let email: String
    let role: AdminRole
    let name: String
    
    enum AdminRole: String, Codable {
        case superAdmin
        case eventManager
        case prayerRequestManager
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case role
        case name
    }
    
    static func fromDocument(_ document: DocumentSnapshot) -> Admin? {
        guard let data = document.data(),
              let email = data["email"] as? String,
              let roleString = data["role"] as? String,
              let role = AdminRole(rawValue: roleString),
              let name = data["name"] as? String else {
            return nil
        }
        
        return Admin(id: document.documentID,
                    email: email,
                    role: role,
                    name: name)
    }
}
