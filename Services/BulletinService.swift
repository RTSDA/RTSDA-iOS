import Foundation

class BulletinService {
    static let shared = BulletinService()
    private let pocketBaseService = PocketBaseService.shared
    
    private init() {}
    
    func getBulletins(activeOnly: Bool = true) async throws -> [Bulletin] {
        var urlString = "\(pocketBaseService.baseURL)/api/collections/bulletins/records?sort=-date"
        
        if activeOnly {
            urlString += "&filter=(is_active=true)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        struct BulletinResponse: Codable {
            let items: [Bulletin]
        }
        
        let bulletinResponse = try decoder.decode(BulletinResponse.self, from: data)
        return bulletinResponse.items
    }
    
    func getBulletin(id: String) async throws -> Bulletin {
        let urlString = "\(pocketBaseService.baseURL)/api/collections/bulletins/records/\(id)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(Bulletin.self, from: data)
    }
    
    func getLatestBulletin() async throws -> Bulletin? {
        let bulletins = try await getBulletins(activeOnly: true)
        return bulletins.first
    }
} 