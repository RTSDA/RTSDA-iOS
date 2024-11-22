import Foundation

struct BibleVerse: Codable {
    let reference: String
    let text: String
    
    enum CodingKeys: String, CodingKey {
        case reference = "reference"
        case text = "content"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reference = try container.decode(String.self, forKey: .reference)
        
        // Clean up the text content
        var content = try container.decode(String.self, forKey: .text)
        content = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        text = content
    }
}

struct BibleVerseResponse: Codable {
    let data: BibleVerse
}
