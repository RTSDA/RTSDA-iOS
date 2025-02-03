import Foundation

class PocketBaseService {
    static let shared = PocketBaseService()
    private let baseURL = "https://pocketbase.rockvilletollandsda.church"
    
    private init() {}
    
    struct EventResponse: Codable {
        let page: Int
        let perPage: Int
        let totalItems: Int
        let totalPages: Int
        let items: [Event]
        
        enum CodingKeys: String, CodingKey {
            case page
            case perPage
            case totalItems
            case totalPages
            case items
        }
    }
    
    @MainActor
    func fetchConfig() async throws -> Config {
        let recordId = "nn753t8o2t1iupd"
        let urlString = "\(baseURL)/api/collections/config/records/\(recordId)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error fetching config: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(Config.self, from: data)
        } catch {
            print("Failed to decode config: \(error)")
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
    
    @MainActor
    func fetchEvents() async throws -> [Event] {
        guard let url = URL(string: "\(baseURL)/api/collections/events/records?sort=start_time") else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("Error fetching events: \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let eventResponse = try decoder.decode(EventResponse.self, from: data)
            return eventResponse.items
        } catch {
            print("Failed to decode events: \(error)")
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
} 