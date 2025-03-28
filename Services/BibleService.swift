import Foundation

@MainActor
class BibleService {
    static let shared = BibleService()
    private let configService = ConfigService.shared
    private let baseURL = "https://api.scripture.api.bible/v1"
    
    private init() {}
    
    // API Response structures
    struct BibleAPIResponse: Codable {
        let data: VerseData
    }
    
    struct VerseData: Codable {
        let id: String
        let orgId: String
        let bibleId: String
        let bookId: String
        let chapterId: String
        let reference: String
        let content: String
        
        // The API returns HTML content, so we'll clean it up
        var cleanContent: String {
            return content
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "NUN\\s+\\d+\\s+", with: "", options: .regularExpression) // Remove Hebrew letter prefixes
                .replacingOccurrences(of: "^[A-Z]+\\s+\\d+\\s+", with: "", options: .regularExpression) // Remove any other letter prefixes
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func getRandomVerse() async throws -> (verse: String, reference: String) {
        // List of popular and uplifting Bible verses
        let references = [
            "JER.29.11", "PRO.3.5", "PHP.4.13", "JOS.1.9", "PSA.23.1",
            "ISA.40.31", "MAT.11.28", "ROM.8.28", "PSA.27.1", "PSA.46.10",
            "JHN.3.16", "ROM.15.13", "2CO.5.7", "DEU.31.6", "ROM.8.31",
            "1JN.4.19", "PHP.4.6", "MAT.6.33", "HEB.11.1", "PSA.37.4"
        ]
        
        // Randomly select a reference
        let randomReference = references.randomElement() ?? "JHN.3.16"
        
        guard let apiKey = configService.bibleApiKey else {
            throw NSError(domain: "BibleService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bible API key not found"])
        }
        
        // Construct the API URL
        let urlString = "\(baseURL)/bibles/de4e12af7f28f599-01/verses/\(randomReference)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.addValue(apiKey, forHTTPHeaderField: "api-key")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check for successful response
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "BibleService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch verse"])
        }
        
        let decoder = JSONDecoder()
        let apiResponse = try decoder.decode(BibleAPIResponse.self, from: data)
        
        return (verse: apiResponse.data.cleanContent, reference: apiResponse.data.reference)
    }
}
