import Foundation

class YouTubeService {
    static let shared = YouTubeService()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    private let cache = CacheService.shared
    private let remoteConfig = RemoteConfigManager.shared
    
    // MARK: - Constants
    static let channelId = "UCH3GQ7cC1gvTSEbTSg2jW3Q"
    static var channelUrl: String {
        "https://www.youtube.com/channel/\(channelId)"
    }
    
    // MARK: - Cache Keys
    private enum CacheKey {
        static let sermon = "latest_sermon"
        static let livestream = "upcoming_livestream"
        static let sermonList = "sermon_list"
        
        static func videoDetails(_ id: String) -> String {
            "video_details_\(id)"
        }
    }
    
    // MARK: - Public API
    struct YouTubeVideo: Codable {
        let title: String
        let description: String
        let videoId: String
        let thumbnailUrl: String?
        let publishedAt: Date
        let duration: TimeInterval
        let liveBroadcastStatus: String
        let isLiveContent: Bool
        
        init(title: String, description: String, videoId: String, thumbnailUrl: String?, publishedAt: Date, duration: TimeInterval, liveBroadcastStatus: String, isLiveContent: Bool = false) {
            self.title = title
            self.description = description
            self.videoId = videoId
            self.thumbnailUrl = thumbnailUrl
            self.publishedAt = publishedAt
            self.duration = duration
            self.liveBroadcastStatus = liveBroadcastStatus
            self.isLiveContent = isLiveContent
        }
    }
    
    enum YouTubeError: Error {
        case apiKeyMissing
        case noVideosFound
        case invalidResponse
        case networkError(Error)
        
        var localizedDescription: String {
            switch self {
            case .apiKeyMissing:
                return "YouTube API key is missing"
            case .noVideosFound:
                return "No videos found"
            case .invalidResponse:
                return "Invalid response from YouTube API"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            }
        }
    }

    func fetchLatestSermon() async throws -> YouTubeVideo {
        print("📺 Fetching latest sermon...")
        
        // Check cache first
        if let cached: YouTubeVideo = try await cache.object(forKey: CacheKey.sermon) {
            print("✅ Found cached sermon: \(cached.title)")
            return cached
        }
        
        print("🔄 Cache miss, fetching from API...")
        
        // Fetch from API if not in cache
        let apiKey = remoteConfig.getYouTubeApiKey()
        guard !apiKey.isEmpty else {
            print("❌ YouTube API key is missing")
            throw YouTubeError.apiKeyMissing
        }
        
        let maxResults = 50 // Maximum allowed by the API
        
        let searchURL = URL(string: "https://www.googleapis.com/youtube/v3/search")!
        var components = URLComponents(url: searchURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "channelId", value: YouTubeService.channelId),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "order", value: "date"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "videoDuration", value: "long"), // Filter for videos longer than 20 minutes
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        print("🌐 Making API request to: \(components.url!)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            
            // Log the response status
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API Response Status: \(httpResponse.statusCode)")
            }
            
            // Log the response data
            if let responseStr = String(data: data, encoding: .utf8) {
                print("📦 API Response: \(responseStr)")
            }
            
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            
            // Find the first video that's not a live/upcoming stream and not a short
            guard let videoId = searchResponse.items.first(where: { item in
                // Only want regular videos, not live or upcoming streams
                // Also exclude videos with "Worship Service" in the title
                return item.snippet.liveBroadcastContent == "none" &&
                       !item.snippet.title.contains("Worship Service")
            })?.id.videoId else {
                print("❌ No regular videos found in search response")
                throw YouTubeError.noVideosFound
            }
            
            print("🎥 Found video ID: \(videoId), fetching details...")
            
            let video = try await fetchVideoDetails(videoId)
            
            // Cache the result
            try await cache.cache(video, forKey: CacheKey.sermon)
            print("✅ Successfully cached sermon: \(video.title)")
            
            return video
        } catch {
            print("❌ Error fetching latest sermon: \(error.localizedDescription)")
            throw YouTubeError.networkError(error)
        }
    }
    
    func fetchUpcomingLivestream() async throws -> YouTubeVideo? {
        print("📺 Fetching upcoming livestream...")
        
        // Check cache first
        if let cached: YouTubeVideo = try await cache.object(forKey: CacheKey.livestream) {
            print("✅ Found cached livestream: \(cached.title)")
            return cached
        }
        
        print("🔄 Cache miss, fetching from API...")
        
        let apiKey = remoteConfig.getYouTubeApiKey()
        guard !apiKey.isEmpty else {
            print("❌ YouTube API key is missing")
            throw YouTubeError.apiKeyMissing
        }
        
        let searchURL = URL(string: "https://www.googleapis.com/youtube/v3/search")!
        var components = URLComponents(url: searchURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "channelId", value: YouTubeService.channelId),
            URLQueryItem(name: "eventType", value: "upcoming"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        print("🌐 Making API request to: \(components.url!)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            
            // Log the response status
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API Response Status: \(httpResponse.statusCode)")
            }
            
            // Log the response data
            if let responseStr = String(data: data, encoding: .utf8) {
                print("📦 API Response: \(responseStr)")
            }
            
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            
            guard let videoId = searchResponse.items.first?.id.videoId else {
                print("ℹ️ No upcoming livestreams found")
                return nil
            }
            
            print("🎥 Found livestream ID: \(videoId), fetching details...")
            
            let video = try await fetchVideoDetails(videoId, isLiveContent: true)
            
            // Cache the result
            try await cache.cache(video, forKey: CacheKey.livestream)
            print("✅ Successfully cached livestream: \(video.title)")
            
            return video
        } catch {
            print("❌ Error fetching upcoming livestream: \(error.localizedDescription)")
            throw YouTubeError.networkError(error)
        }
    }
    
    private func fetchVideoDetails(_ videoId: String, isLiveContent: Bool = false) async throws -> YouTubeVideo {
        print("🎬 Fetching details for video: \(videoId)")
        
        let apiKey = remoteConfig.getYouTubeApiKey()
        guard !apiKey.isEmpty else {
            print("❌ YouTube API key is missing")
            throw YouTubeError.apiKeyMissing
        }
        
        let videoURL = URL(string: "https://www.googleapis.com/youtube/v3/videos")!
        var components = URLComponents(url: videoURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,contentDetails,status"),
            URLQueryItem(name: "id", value: videoId),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        print("🌐 Making API request to: \(components.url!)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: components.url!)
            
            // Log the response status
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 API Response Status: \(httpResponse.statusCode)")
            }
            
            // Log the response data
            if let responseStr = String(data: data, encoding: .utf8) {
                print("📦 API Response: \(responseStr)")
            }
            
            let videoResponse = try decoder.decode(VideoResponse.self, from: data)
            
            guard let videoItem = videoResponse.items.first else {
                print("❌ No video details found for ID: \(videoId)")
                throw YouTubeError.invalidResponse
            }
            
            print("📏 Raw duration value: \(videoItem.contentDetails.duration)")
            print("🎥 Video broadcast status: \(videoItem.snippet.liveBroadcastContent)")
            
            // Get the duration, allowing P0D for upcoming livestreams
            let duration = getDurationInSeconds(from: videoItem.contentDetails.duration)
            
            // For non-live content, ensure it's not a live/upcoming stream and not too short
            if !isLiveContent {
                if videoItem.snippet.liveBroadcastContent != "none" {
                    print("❌ Video is a live/upcoming stream: \(videoItem.snippet.liveBroadcastContent)")
                    throw YouTubeError.invalidResponse
                }
                
                if duration < 60 {
                    print("❌ Video is too short (likely a Short): \(duration) seconds")
                    throw YouTubeError.invalidResponse
                }
            }
            
            let video = YouTubeVideo(
                title: videoItem.snippet.title,
                description: videoItem.snippet.description,
                videoId: videoItem.id,
                thumbnailUrl: videoItem.snippet.thumbnails.high?.url,
                publishedAt: videoItem.snippet.publishedAt,
                duration: duration,
                liveBroadcastStatus: videoItem.snippet.liveBroadcastContent,
                isLiveContent: isLiveContent
            )
            
            return video
        } catch {
            print("❌ Error fetching video details: \(error.localizedDescription)")
            throw YouTubeError.networkError(error)
        }
    }
    
    private func getDurationInSeconds(from duration: String) -> TimeInterval {
        // Handle P0D for upcoming livestreams
        if duration == "P0D" {
            return 0
        }
        
        // YouTube duration format: PT#H#M#S
        let pattern = "PT(?:(\\d+)H)?(?:(\\d+)M)?(?:(\\d+)S)?"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        
        let nsString = duration as NSString
        guard let match = regex.firstMatch(in: duration,
                                         options: [],
                                         range: NSRange(location: 0, length: nsString.length)) else {
            print("❌ Failed to parse duration: \(duration)")
            return 0
        }
        
        func getGroup(_ group: Int) -> Int {
            guard let range = Range(match.range(at: group), in: duration) else { return 0 }
            return Int(duration[range]) ?? 0
        }
        
        let hours = getGroup(1)
        let minutes = getGroup(2)
        let seconds = getGroup(3)
        
        let totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        print("⏱️ Parsed duration: \(duration) -> \(totalSeconds) seconds (H:\(hours) M:\(minutes) S:\(seconds))")
        
        return TimeInterval(totalSeconds)
    }
}

// MARK: - YouTube API Response Models
private struct SearchResponse: Codable {
    let items: [SearchItem]
    
    struct SearchItem: Codable {
        let id: VideoId
        let snippet: Snippet
        
        enum CodingKeys: String, CodingKey {
            case id
            case snippet
        }
    }
    
    struct VideoId: Codable {
        let kind: String
        let videoId: String
    }
}

private struct VideoResponse: Codable {
    let items: [VideoItem]
    
    struct VideoItem: Codable {
        let id: String
        let snippet: Snippet
        let contentDetails: ContentDetails
        let status: Status?
    }
}

private struct Snippet: Codable {
    let title: String
    let description: String
    let publishedAt: Date
    let thumbnails: Thumbnails
    let liveBroadcastContent: String
    
    struct Thumbnails: Codable {
        let `default`: Thumbnail?
        let medium: Thumbnail?
        let high: Thumbnail?
        
        struct Thumbnail: Codable {
            let url: String
            let width: Int
            let height: Int
        }
    }
}

private struct ContentDetails: Codable {
    let duration: String
}

private struct Status: Codable {
    let uploadStatus: String?
    let privacyStatus: String?
    let license: String?
    let embeddable: Bool?
    let publicStatsViewable: Bool?
    let madeForKids: Bool?
}
