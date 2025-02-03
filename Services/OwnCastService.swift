import Foundation

class OwnCastService {
    static let shared = OwnCastService()
    
    private let baseUrl = "https://stream.rockvilletollandsda.church"
    
    private init() {}
    
    struct StreamStatus: Codable {
        let online: Bool
        let streamTitle: String?
        let lastConnectTime: String?
        let lastDisconnectTime: String?
        let serverTime: String?
        let versionNumber: String?
        
        enum CodingKeys: String, CodingKey {
            case online
            case streamTitle = "name"
            case lastConnectTime
            case lastDisconnectTime
            case serverTime
            case versionNumber
        }
    }
    
    func getStreamStatus() async throws -> StreamStatus {
        guard let url = URL(string: "\(baseUrl)/api/status") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let responseString = String(data: data, encoding: .utf8) {
                print("Stream status error: \(responseString)")
            }
            throw URLError(.badServerResponse)
        }
        
        do {
            return try JSONDecoder().decode(StreamStatus.self, from: data)
        } catch {
            print("Failed to decode stream status: \(error)")
            throw error
        }
    }
    
    func createLivestreamMessage(from status: StreamStatus) -> Message {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        let formattedDate = dateFormatter.string(from: Date())
        
        return Message(
            id: UUID().uuidString,
            title: status.streamTitle ?? "Live Stream",
            description: "Watch our live stream",
            speaker: "Live Stream",
            videoUrl: "\(baseUrl)/hls/stream.m3u8",
            thumbnailUrl: "\(baseUrl)/thumbnail.jpg",
            duration: 0,
            isLiveStream: true,
            isPublished: true,
            isDeleted: false,
            liveBroadcastStatus: "live",
            date: formattedDate
        )
    }
} 