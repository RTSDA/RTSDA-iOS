import Foundation

struct Bulletin: Identifiable, Codable {
    var id: String
    var title: String
    var content: String
    var timestamp: Date
    
    init(id: String = UUID().uuidString, title: String, content: String, timestamp: Date) {
        self.id = id
        self.title = title
        self.content = content
        self.timestamp = timestamp
    }
} 