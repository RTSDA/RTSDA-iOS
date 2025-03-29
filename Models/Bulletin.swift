import Foundation

struct BulletinSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct Bulletin: Identifiable, Codable {
    let id: String
    let title: String
    let date: Date
    let sections: [BulletinSection]
    let pdfUrl: String?
    let isActive: Bool
    let created: Date
    let updated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case date
        case sections
        case pdfUrl = "pdf_url"
        case isActive = "is_active"
        case created
        case updated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        pdfUrl = try container.decodeIfPresent(String.self, forKey: .pdfUrl)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
        
        // Decode sections
        let sectionsData = try container.decode([[String: String]].self, forKey: .sections)
        sections = sectionsData.map { section in
            BulletinSection(
                title: section["title"] ?? "",
                content: section["content"] ?? ""
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(pdfUrl, forKey: .pdfUrl)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(created, forKey: .created)
        try container.encode(updated, forKey: .updated)
        
        // Encode sections
        let sectionsData = sections.map { section in
            ["title": section.title, "content": section.content]
        }
        try container.encode(sectionsData, forKey: .sections)
    }
} 