import Foundation

@MainActor
class JellyfinService {
    static let shared = JellyfinService()
    private let configService = ConfigService.shared
    
    private let baseUrl = "https://jellyfin.rockvilletollandsda.church"
    private var apiKey: String? {
        configService.jellyfinApiKey
    }
    private var libraryId: String?
    private var currentType: MediaType = .sermons
    
    enum MediaType: String {
        case sermons = "Sermons"
        case livestreams = "LiveStreams"
    }
    
    enum JellyfinError: Error {
        case invalidURL
        case networkError
        case decodingError
        case noVideosFound
        case libraryNotFound
    }
    
    struct JellyfinItem: Codable {
        let id: String
        let name: String
        let tags: [String]?
        let premiereDate: String?
        let productionYear: Int?
        let overview: String?
        let mediaType: String
        let type: String
        let path: String
        let dateCreated: String
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case name = "Name"
            case tags = "Tags"
            case premiereDate = "PremiereDate"
            case productionYear = "ProductionYear"
            case overview = "Overview"
            case mediaType = "MediaType"
            case type = "Type"
            case path = "Path"
            case dateCreated = "DateCreated"
        }
    }
    
    private struct LibraryResponse: Codable {
        let items: [Library]
        
        enum CodingKeys: String, CodingKey {
            case items = "Items"
        }
    }
    
    private struct Library: Codable {
        let id: String
        let name: String
        let path: String
        
        enum CodingKeys: String, CodingKey {
            case id = "Id"
            case name = "Name"
            case path = "Path"
        }
    }
    
    private struct ItemsResponse: Codable {
        let items: [JellyfinItem]
        
        enum CodingKeys: String, CodingKey {
            case items = "Items"
        }
    }
    
    private init() {}
    
    func setType(_ type: MediaType) {
        self.currentType = type
        self.libraryId = nil // Reset library ID when switching types
    }
    
    private func fetchWithAuth(_ url: URL) async throws -> (Data, URLResponse) {
        // Ensure config is loaded
        if configService.config == nil {
            await configService.loadConfig()
        }
        
        guard let apiKey = self.apiKey else {
            throw JellyfinError.networkError
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        request.addValue(apiKey, forHTTPHeaderField: "X-MediaBrowser-Token")
        request.addValue("MediaBrowser Client=\"RTSDA iOS\", Device=\"iOS\", DeviceId=\"rtsda-ios\", Version=\"1.0.0\", Token=\"\(apiKey)\"", 
                        forHTTPHeaderField: "X-Emby-Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check if task was cancelled
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw JellyfinError.networkError
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Jellyfin API error: \(responseString)")
                }
                throw JellyfinError.networkError
            }
            
            return (data, response)
        } catch is CancellationError {
            throw URLError(.cancelled)
        } catch {
            print("Network request failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func getLibraryId() async throws -> String {
        if let id = libraryId { return id }
        
        let url = URL(string: "\(baseUrl)/Library/MediaFolders")!
        
        do {
            let (data, _) = try await fetchWithAuth(url)
            
            // Check if task was cancelled
            try Task.checkCancellation()
            
            let response = try JSONDecoder().decode(LibraryResponse.self, from: data)
            
            let searchTerm = currentType == .sermons ? "Sermons" : "LiveStreams"
            
            // Try exact match on name
            if let library = response.items.first(where: { $0.name == searchTerm }) {
                libraryId = library.id
                return library.id
            }
            
            print("Library not found: \(searchTerm)")
            print("Available libraries: \(response.items.map { $0.name }.joined(separator: ", "))")
            throw JellyfinError.libraryNotFound
        } catch is CancellationError {
            throw URLError(.cancelled)
        } catch {
            print("Error fetching library ID: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // Create formatters for different possible formats
        let formatters = [
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ" // PocketBase format
                return formatter
            }(),
            { () -> ISO8601DateFormatter in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter
            }(),
            { () -> ISO8601DateFormatter in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ?? 
                         (formatter as? DateFormatter)?.date(from: dateString) {
                return date
            }
        }
        
        return nil
    }
    
    func fetchSermons(type: SermonType) async throws -> [Sermon] {
        currentType = MediaType(rawValue: type.rawValue)!
        let libraryId = try await getLibraryId()
        
        // Check if task was cancelled
        try Task.checkCancellation()
        
        let urlString = "\(baseUrl)/Items?ParentId=\(libraryId)&Fields=Path,PremiereDate,ProductionYear,Overview,DateCreated&Recursive=true&IncludeItemTypes=Movie,Video,Episode&SortBy=DateCreated&SortOrder=Descending"
        guard let url = URL(string: urlString) else {
            throw JellyfinError.invalidURL
        }
        
        let (data, _) = try await fetchWithAuth(url)
        
        // Check if task was cancelled
        try Task.checkCancellation()
        
        let response = try JSONDecoder().decode(ItemsResponse.self, from: data)
        
        return response.items.map { item in
            var title = item.name
            var speaker = "Unknown Speaker"
            
            // Remove file extension if present
            title = title.replacingOccurrences(of: #"\.(mp4|mov)$"#, with: "", options: .regularExpression)
            
            // Try to split into title and speaker
            let parts = title.components(separatedBy: " - ")
            if parts.count > 1 {
                title = parts[0].trimmingCharacters(in: .whitespaces)
                let speakerPart = parts[1].trimmingCharacters(in: .whitespaces)
                speaker = speakerPart.replacingOccurrences(
                    of: #"\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d+(?:th|st|nd|rd)?\s*\d{4}$"#,
                    with: "",
                    options: .regularExpression
                ).replacingOccurrences(of: "|", with: "").trimmingCharacters(in: .whitespaces)
            }
            
            // Parse date with UTC handling
            let rawDate = item.premiereDate ?? item.dateCreated
            let utcDate = parseDate(rawDate) ?? Date()
            
            // Extract components in UTC and create a new date at noon UTC to avoid timezone issues
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(identifier: "UTC")!
            var components = calendar.dateComponents([.year, .month, .day], from: utcDate)
            components.hour = 12 // Set to noon UTC to ensure date remains the same in all timezones
            let localDate = calendar.date(from: components) ?? Date()
            
            return Sermon(
                id: item.id,
                title: title,
                description: item.overview ?? "",
                date: localDate,
                speaker: speaker,
                type: type,
                videoUrl: getStreamUrl(itemId: item.id),
                thumbnail: getImageUrl(itemId: item.id)
            )
        }
    }
    
    private func getStreamUrl(itemId: String) -> String {
        var components = URLComponents(string: "\(baseUrl)/Videos/\(itemId)/master.m3u8")!
        guard let apiKey = self.apiKey else { return "" }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "MediaSourceId", value: itemId),
            URLQueryItem(name: "TranscodingProtocol", value: "hls"),
            URLQueryItem(name: "RequireAvc", value: "true"),
            URLQueryItem(name: "MaxStreamingBitrate", value: "20000000"),
            URLQueryItem(name: "VideoBitrate", value: "10000000"),
            URLQueryItem(name: "AudioBitrate", value: "192000"),
            URLQueryItem(name: "AudioCodec", value: "aac"),
            URLQueryItem(name: "VideoCodec", value: "h264"),
            URLQueryItem(name: "MaxAudioChannels", value: "2"),
            URLQueryItem(name: "StartTimeTicks", value: "0"),
            URLQueryItem(name: "SubtitleMethod", value: "Embed"),
            URLQueryItem(name: "TranscodeReasons", value: "VideoCodecNotSupported")
        ]
        return components.url!.absoluteString
    }
    
    private func getImageUrl(itemId: String) -> String {
        guard let apiKey = self.apiKey else { return "" }
        return "\(baseUrl)/Items/\(itemId)/Images/Primary?api_key=\(apiKey)"
    }
} 