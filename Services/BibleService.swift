import Foundation

@MainActor
class BibleService {
    static let shared = BibleService()
    private let pocketBaseService = PocketBaseService.shared
    
    private init() {}
    
    struct Verse: Identifiable, Codable {
        let id: String
        let reference: String
        let text: String
        let isActive: Bool
        
        enum CodingKeys: String, CodingKey {
            case id
            case reference
            case text
            case isActive = "is_active"
        }
    }
    
    struct VersesRecord: Codable {
        let collectionId: String
        let collectionName: String
        let created: String
        let id: String
        let updated: String
        let verses: VersesData
        
        struct VersesData: Codable {
            let id: String
            let verses: [Verse]
        }
    }
    
    private var cachedVerses: [Verse]?
    
    func getRandomVerse() async throws -> (verse: String, reference: String) {
        let verses = try await getVerses()
        print("Total verses available: \(verses.count)")
        
        guard !verses.isEmpty else {
            print("No verses available")
            throw NSError(domain: "BibleService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No verses available"])
        }
        
        let randomVerse = verses.randomElement()!
        print("Selected random verse: \(randomVerse.reference)")
        return (verse: randomVerse.text, reference: randomVerse.reference)
    }
    
    func getVerse(reference: String) async throws -> (verse: String, reference: String) {
        print("Looking up verse with reference: \(reference)")
        
        // Convert API-style reference (e.g., "JER.29.11") to display format ("Jeremiah 29:11")
        let displayReference = reference
            .replacingOccurrences(of: "\\.", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "([A-Z]+)", with: "$1 ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        
        print("Converted reference to: \(displayReference)")
        
        let verses = try await getVerses()
        print("Found \(verses.count) verses")
        
        if let verse = verses.first(where: { $0.reference.lowercased() == displayReference.lowercased() }) {
            print("Found matching verse: \(verse.reference)")
            return (verse: verse.text, reference: verse.reference)
        }
        
        print("No matching verse found for reference: \(displayReference)")
        throw NSError(domain: "BibleService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verse not found"])
    }
    
    private func getVerses() async throws -> [Verse] {
        // Return cached verses if available
        if let cached = cachedVerses {
            print("Returning cached verses")
            return cached
        }
        
        print("Fetching verses from PocketBase")
        // Fetch from PocketBase
        let endpoint = "\(PocketBaseService.shared.baseURL)/bible_verses/records/nkf01o1q3456flr"
        
        guard let url = URL(string: endpoint) else {
            print("Invalid URL: \(endpoint)")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Making request to: \(endpoint)")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid response type")
            throw URLError(.badServerResponse)
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error response from server: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        // Print raw response for debugging
        if let rawResponse = String(data: data, encoding: .utf8) {
            print("Raw response from PocketBase:")
            print(rawResponse)
        }
        
        let decoder = JSONDecoder()
        do {
            let versesRecord = try decoder.decode(VersesRecord.self, from: data)
            
            // Cache the verses
            cachedVerses = versesRecord.verses.verses
            print("Successfully fetched and cached \(versesRecord.verses.verses.count) verses")
            
            return versesRecord.verses.verses
        } catch {
            print("Failed to decode response: \(error)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key: \(key.stringValue) in \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("Type mismatch: expected \(type) in \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("Value not found: expected \(type) in \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("Unknown decoding error")
                }
            }
            throw error
        }
    }
    
    func testAllVerses() async throws {
        print("\n=== Testing All Verses ===\n")
        let verses = try await getVerses()
        for verse in verses {
            print("Reference: \(verse.reference)")
            print("Verse: \(verse.text)")
            print("-------------------\n")
        }
        print("=== Test Complete ===\n")
    }
}
