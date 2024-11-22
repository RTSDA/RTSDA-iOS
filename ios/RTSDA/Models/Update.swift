import Foundation
import FirebaseFirestore

struct Update: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var date: Date
    var imageUrl: String?
    var priority: Int
    var isActive: Bool
    
    init(id: String = UUID().uuidString,
         title: String = "",
         content: String = "",
         date: Date = Date(),
         imageUrl: String? = nil,
         priority: Int = 0,
         isActive: Bool = true) {
        self.id = id
        self.title = title
        self.content = content
        self.date = date
        self.imageUrl = imageUrl
        self.priority = priority
        self.isActive = isActive
    }
    
    static func fromDocument(_ document: DocumentSnapshot) -> Update? {
        guard let data = document.data() else { return nil }
        
        let date: Date
        if let timestamp = data["date"] as? Timestamp {
            date = timestamp.dateValue()
        } else if let seconds = (data["date"] as? Double) {
            date = Date(timeIntervalSince1970: seconds)
        } else {
            date = Date()
        }
        
        return Update(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            content: data["content"] as? String ?? "",
            date: date,
            imageUrl: data["imageUrl"] as? String,
            priority: data["priority"] as? Int ?? 0,
            isActive: data["isActive"] as? Bool ?? true
        )
    }
    
    func toDocument() -> [String: Any] {
        var doc: [String: Any] = [
            "title": title,
            "content": content,
            "date": Timestamp(date: date),
            "priority": priority,
            "isActive": isActive
        ]
        
        if let imageUrl = imageUrl {
            doc["imageUrl"] = imageUrl
        }
        
        return doc
    }
}
