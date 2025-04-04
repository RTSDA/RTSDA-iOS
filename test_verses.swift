import Foundation

class PocketBaseService {
    static let shared = PocketBaseService()
    let baseURL = "https://pocketbase.rockvilletollandsda.church/api/collections"
    private init() {}
}

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
    
    private func getVerses() async throws -> [Verse] {
        print("Fetching verses from PocketBase")
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
        
        let decoder = JSONDecoder()
        let versesRecord = try decoder.decode(VersesRecord.self, from: data)
        return versesRecord.verses.verses
    }
    
    func testAllVerses() async throws {
        print("\n=== Testing All Verses ===\n")
        let verses = try await getVerses()
        for verse in verses {
            print("Reference: \(verse.reference)")
            print("Text: \(verse.text)")
            print("-------------------\n")
        }
        print("=== Test Complete ===\n")
    }
}

print("Starting Bible Verses Test...")

// Create a semaphore to signal when the task is complete
let semaphore = DispatchSemaphore(value: 0)

Task {
    do {
        try await BibleService.shared.testAllVerses()
    } catch {
        print("Error testing verses: \(error)")
    }
    semaphore.signal()
}

// Wait for the task to complete
semaphore.wait() 