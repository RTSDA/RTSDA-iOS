import Foundation

@globalActor
actor YouTubeService {
    static let shared = YouTubeService()
    
    private let configService = ConfigService.shared
    private let channelId = YTConfig.YouTube.channelId
    private let bundleId = Bundle.main.bundleIdentifier ?? "com.rtsda.app"
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "X-Ios-Bundle-Identifier": bundleId,
            "User-Agent": "RTSDA-iOS/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
        ]
        return URLSession(configuration: config)
    }()
    
    private init() {}
    
    struct Video: Identifiable {
        let id: String
        let title: String
        let description: String
        let thumbnailURL: String
        let isLiveStream: Bool
        let duration: String?
    }
    
    private func fetchWithRetry<T: Decodable>(request: URLRequest, retries: Int = 2) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                if attempt > 0 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
                
                let (data, response) = try await session.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let error = errorJson["error"] as? [String: Any],
                           let message = error["message"] as? String {
                            print("YouTube API Error: \(message)")
                            throw NSError(domain: "YouTubeAPI", 
                                        code: httpResponse.statusCode,
                                        userInfo: [NSLocalizedDescriptionKey: message])
                        }
                    }
                }
                
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                lastError = error
                print("API Error: \(error)")
                if attempt == retries {
                    throw error
                }
            }
        }
        
        throw lastError!
    }
    
    private func isShortVideo(duration: String?) -> Bool {
        guard let duration = duration else { return false }
        
        // Convert ISO 8601 duration to seconds
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(duration.startIndex..<duration.endIndex, in: duration)
        
        guard let match = regex.firstMatch(in: duration, range: range) else { return false }
        
        let hours = match.range(at: 1).location != NSNotFound ? Int(duration[Range(match.range(at: 1), in: duration)!]) ?? 0 : 0
        let minutes = match.range(at: 2).location != NSNotFound ? Int(duration[Range(match.range(at: 2), in: duration)!]) ?? 0 : 0
        let seconds = match.range(at: 3).location != NSNotFound ? Int(duration[Range(match.range(at: 3), in: duration)!]) ?? 0 : 0
        
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        let isShort = totalSeconds < 61
        if isShort {
            print("Video is a Short (duration: \(duration))")
        }
        return isShort
    }
    
    private func isWorshipService(title: String) -> Bool {
        let isWorship = title.localizedCaseInsensitiveContains("Worship Service")
        if isWorship {
            print("Found Worship Service: \(title)")
        }
        return isWorship
    }
    
    func fetchLatestSermon() async throws -> Video? {
        print("Fetching latest sermon...")
        // Get API key from Remote Config
        let apiKey = await configService.getString(forKey: ConfigService.Keys.youtubeApiKey)
        
        // First, search for videos - removed eventType=completed to get all videos
        let searchUrlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=\(channelId)&maxResults=25&order=date&type=video&key=\(apiKey)"
        guard let searchUrl = URL(string: searchUrlString) else { return nil }
        
        let searchRequest = URLRequest(url: searchUrl)
        let searchResponse: SearchResponse = try await fetchWithRetry(request: searchRequest)
        
        print("Found \(searchResponse.items.count) videos in search")
        
        // Get video details to check duration
        let videoIds = searchResponse.items.map { $0.id.videoId }.joined(separator: ",")
        let detailsUrlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails,snippet,status&id=\(videoIds)&key=\(apiKey)"
        guard let detailsUrl = URL(string: detailsUrlString) else { return nil }
        
        let detailsRequest = URLRequest(url: detailsUrl)
        let detailsResponse: VideoListResponse = try await fetchWithRetry(request: detailsRequest)
        
        print("Got details for \(detailsResponse.items.count) videos")
        
        // Print all video titles and durations for debugging
        for video in detailsResponse.items {
            print("\nVideo: \(video.snippet.title)")
            print("Duration: \(video.contentDetails.duration)")
            print("Is Short: \(isShortVideo(duration: video.contentDetails.duration))")
            print("Is Worship: \(isWorshipService(title: video.snippet.title))")
            print("LiveBroadcastContent: \(video.snippet.liveBroadcastContent)")
        }
        
        // Find the first video that's not a Short, not a Worship Service, and not a livestream
        guard let video = detailsResponse.items.first(where: { 
            !isShortVideo(duration: $0.contentDetails.duration) && 
            !isWorshipService(title: $0.snippet.title) &&
            $0.snippet.liveBroadcastContent == "none"  // Filter out live streams
        }) else {
            print("No suitable videos found after filtering")
            return nil
        }
        
        print("Selected video: \(video.snippet.title)")
        
        return Video(
            id: video.id,
            title: video.snippet.title,
            description: video.snippet.description,
            thumbnailURL: video.snippet.thumbnails.high?.url ?? video.snippet.thumbnails.default.url,
            isLiveStream: false,
            duration: video.contentDetails.duration
        )
    }
    
    func fetchUpcomingLivestream() async throws -> Video? {
        let apiKey = await configService.getString(forKey: ConfigService.Keys.youtubeApiKey)
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=\(channelId)&eventType=upcoming&maxResults=1&order=date&type=video&key=\(apiKey)"
        guard let url = URL(string: urlString) else { return nil }
        
        let request = URLRequest(url: url)
        let response: SearchResponse = try await fetchWithRetry(request: request)
        
        guard let item = response.items.first else { return nil }
        
        return Video(
            id: item.id.videoId,
            title: item.snippet.title,
            description: item.snippet.description,
            thumbnailURL: item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.default.url,
            isLiveStream: true,
            duration: nil
        )
    }
    
    func extractVideoURL(from videoId: String) async throws -> URL {
        let apiKey = await configService.getString(forKey: ConfigService.Keys.youtubeApiKey)
        let infoURL = "https://www.googleapis.com/youtube/v3/videos?part=player&id=\(videoId)&key=\(apiKey)"
        guard let url = URL(string: infoURL) else {
            throw NSError(domain: "YouTubeService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let request = URLRequest(url: url)
        let response: VideoPlayerResponse = try await fetchWithRetry(request: request)
        
        guard let item = response.items.first else {
            throw NSError(domain: "YouTubeService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video found"])
        }
        
        // Extract video URL from player
        guard let videoURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)") else {
            throw NSError(domain: "YouTubeService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid video URL"])
        }
        
        return videoURL
    }
}

// Response models
private struct SearchResponse: Codable {
    let items: [SearchItem]
}

private struct SearchItem: Codable {
    let id: VideoId
    let snippet: Snippet
}

private struct VideoId: Codable {
    let videoId: String
}

private struct Snippet: Codable {
    let title: String
    let description: String
    let thumbnails: Thumbnails
    let liveBroadcastContent: String
}

private struct Thumbnails: Codable {
    let `default`: Thumbnail
    let high: Thumbnail?
}

private struct Thumbnail: Codable {
    let url: String
}

private struct VideoListResponse: Codable {
    let items: [VideoItem]
}

private struct VideoItem: Codable {
    let id: String
    let snippet: Snippet
    let contentDetails: ContentDetails
}

private struct ContentDetails: Codable {
    let duration: String
}

private struct VideoPlayerResponse: Codable {
    let items: [VideoPlayerItem]
}

private struct VideoPlayerItem: Codable {
    let player: PlayerDetails
}

private struct PlayerDetails: Codable {
    let embedHtml: String
}
