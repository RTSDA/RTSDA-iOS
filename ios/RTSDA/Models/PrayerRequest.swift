import Foundation
import FirebaseFirestore

struct PrayerRequest: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let phone: String
    let request: String
    let timestamp: Timestamp
    var status: RequestStatus
    let isPrivate: Bool
    let requestType: RequestType
    
    enum RequestStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
        case new = "new"
    }
    
    enum RequestType: String, Codable, CaseIterable {
        case all = "All"
        case personal = "Personal"
        case family = "Family"
        case health = "Health"
        case financial = "Financial"
        case spiritual = "Spiritual"
        case other = "Other"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case request
        case timestamp
        case status
        case isPrivate
        case requestType
    }
    
    init(id: String = UUID().uuidString,
         name: String,
         email: String,
         phone: String = "",
         request: String,
         timestamp: Timestamp = Timestamp(date: Date()),
         status: RequestStatus = .new,
         isPrivate: Bool = false,
         requestType: RequestType = .personal) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.request = request
        self.timestamp = timestamp
        self.status = status
        self.isPrivate = isPrivate
        self.requestType = requestType
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        request = try container.decode(String.self, forKey: .request)
        
        // Optional fields with defaults
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        isPrivate = try container.decodeIfPresent(Bool.self, forKey: .isPrivate) ?? false
        
        // Handle timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp
        } else {
            // Fallback to current time if timestamp is missing or invalid
            self.timestamp = Timestamp(date: Date())
        }
        
        // Handle status with fallback
        if let statusString = try? container.decode(String.self, forKey: .status),
           let status = RequestStatus(rawValue: statusString) {
            self.status = status
        } else {
            self.status = .new
        }
        
        // Handle requestType with fallback
        if let requestTypeString = try? container.decode(String.self, forKey: .requestType),
           let requestType = RequestType(rawValue: requestTypeString) {
            self.requestType = requestType
        } else {
            self.requestType = .personal
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        try container.encode(phone, forKey: .phone)
        try container.encode(request, forKey: .request)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(status.rawValue, forKey: .status)
        try container.encode(isPrivate, forKey: .isPrivate)
        try container.encode(requestType.rawValue, forKey: .requestType)
    }
}