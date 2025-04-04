import Foundation

struct BulletinSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct Bulletin: Identifiable, Codable {
    let id: String
    let collectionId: String
    let title: String
    let date: Date
    let divineWorship: String
    let sabbathSchool: String
    let scriptureReading: String
    let sunset: String
    let pdf: String?
    let isActive: Bool
    let created: Date
    let updated: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case collectionId = "collectionId"
        case title
        case date
        case divineWorship = "divine_worship"
        case sabbathSchool = "sabbath_school"
        case scriptureReading = "scripture_reading"
        case sunset
        case pdf
        case isActive = "is_active"
        case created
        case updated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        collectionId = try container.decode(String.self, forKey: .collectionId)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        divineWorship = try container.decode(String.self, forKey: .divineWorship)
        sabbathSchool = try container.decode(String.self, forKey: .sabbathSchool)
        scriptureReading = try container.decode(String.self, forKey: .scriptureReading)
        sunset = try container.decode(String.self, forKey: .sunset)
        pdf = try container.decodeIfPresent(String.self, forKey: .pdf)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        created = try container.decode(Date.self, forKey: .created)
        updated = try container.decode(Date.self, forKey: .updated)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(collectionId, forKey: .collectionId)
        try container.encode(title, forKey: .title)
        try container.encode(date, forKey: .date)
        try container.encode(divineWorship, forKey: .divineWorship)
        try container.encode(sabbathSchool, forKey: .sabbathSchool)
        try container.encode(scriptureReading, forKey: .scriptureReading)
        try container.encode(sunset, forKey: .sunset)
        try container.encodeIfPresent(pdf, forKey: .pdf)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(created, forKey: .created)
        try container.encode(updated, forKey: .updated)
    }
    
    // Computed property to get the PDF URL
    var pdfUrl: String {
        if let pdf = pdf {
            return "https://pocketbase.rockvilletollandsda.church/api/files/\(collectionId)/\(id)/\(pdf)"
        }
        return ""
    }
    
    // Computed property to get formatted content
    var content: String {
        """
        Divine Worship
        \(divineWorship)

        Sabbath School
        \(sabbathSchool)

        Scripture Reading
        \(scriptureReading)

        Sunset Information
        \(sunset)
        """
    }
}

class PocketBaseService {
    static let shared = PocketBaseService()
    let baseURL = "https://pocketbase.rockvilletollandsda.church/api/collections"
    
    private init() {}
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ"
        return formatter
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            print("Attempting to decode date string: \(dateString)")
            
            // Try ISO8601 first
            if let date = ISO8601DateFormatter().date(from: dateString) {
                print("Successfully decoded ISO8601 date")
                return date
            }
            
            // Try various date formats
            let formatters = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd HH:mm:ss.SSSZ",
                "yyyy-MM-dd HH:mm:ssZ",
                "yyyy-MM-dd"
            ]
            
            for format in formatters {
                let formatter = DateFormatter()
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    print("Successfully decoded date with format: \(format)")
                    return date
                }
            }
            
            print("Failed to decode date string with any format")
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string '\(dateString)' does not match any expected format"
            )
        }
        return decoder
    }()
    
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
    
    struct BulletinResponse: Codable {
        let page: Int
        let perPage: Int
        let totalItems: Int
        let totalPages: Int
        let items: [Bulletin]
    }
    
    @MainActor
    func fetchConfig() async throws -> Config {
        let recordId = "nn753t8o2t1iupd"
        let urlString = "\(baseURL)/config/records/\(recordId)"
        
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
        guard let url = URL(string: "\(baseURL)/events/records?sort=start_time") else {
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
    
    func fetchBulletins(activeOnly: Bool = false) async throws -> BulletinResponse {
        let endpoint = "\(baseURL)/bulletins/records"
        var components = URLComponents(string: endpoint)!
        
        var queryItems = [URLQueryItem]()
        if activeOnly {
            queryItems.append(URLQueryItem(name: "filter", value: "is_active=true"))
        }
        queryItems.append(URLQueryItem(name: "sort", value: "-date"))
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        // Debug: Print the JSON response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Received JSON response: \(jsonString)")
        }
        
        do {
            return try decoder.decode(BulletinResponse.self, from: data)
        } catch {
            print("Failed to decode bulletins: \(error)")
            throw error
        }
    }
} 