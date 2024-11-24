import Foundation
import FirebaseFirestore

struct PrayerRequest: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let requestType: RequestType
    let details: String
    let isConfidential: Bool
    let timestamp: Date
    var prayedFor: Bool
    var prayedForDate: Date?
    
    enum RequestType: String, Codable, CaseIterable {
        case personal = "Personal"
        case family = "Family"
        case friend = "Friend"
        case church = "Church"
        case other = "Other"
    }
} 