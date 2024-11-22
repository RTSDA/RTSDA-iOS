import Foundation

@globalActor
actor YouTubeService {
    static let shared = YouTubeService()
    
    private let apiKey = YTConfig.YouTube.apiKey
    private let channelId = YTConfig.YouTube.channelId
    private let bundleId = Bundle.main.bundleIdentifier ?? "com.rtsda.appr"
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = [
            "X-Ios-Bundle-Identifier": bundleId,
            "User-Agent": "RTSDA-iOS/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")"
        ]
        return URLSession(configuration: config)
    }()
    
    // Cache
    private var cachedSermon: Video?
    private var cachedLivestream: Video?
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 7200 // 2 hours
    private var quotaExceeded = false
    private var quotaResetTime: Date?
    
    struct Video: Identifiable {
        let id: String
        let title: String
        let description: String
        let thumbnailURL: String
        let isLiveStream: Bool
    }
    
    private func fetchWithRetry<T: Decodable>(request: URLRequest, retries: Int = 2) async throws -> T {
        // Check if API key is configured
        guard YTConfig.YouTube.isApiKeyConfigured else {
            throw NSError(domain: "YouTubeAPI",
                         code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "YouTube API key not configured. Please check app settings."])
        }
        
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                if attempt > 0 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                    print("Retry attempt \(attempt)")
                }
                
                let (data, response) = try await session.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("YouTube API Response - Status code: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode == 429 { // Too Many Requests
                        if attempt < retries {
                            continue
                        }
                    }
                    
                    if httpResponse.statusCode != 200 {
                        if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let error = errorJson["error"] as? [String: Any] {
                            print("YouTube API Error Details: \(error)")
                            
                            if let message = error["message"] as? String {
                                throw NSError(domain: "YouTubeAPI", 
                                            code: httpResponse.statusCode,
                                            userInfo: [NSLocalizedDescriptionKey: message])
                            }
                        }
                    }
                }
                
                let decoder = JSONDecoder()
                return try decoder.decode(T.self, from: data)
            } catch {
                lastError = error
                if attempt == retries {
                    throw lastError!
                }
            }
        }
        
        throw lastError!
    }
    
    func fetchLatestSermon() async throws -> Video? {
        // If quota is exceeded and reset time hasn't passed, return cached data
        if quotaExceeded {
            if let resetTime = quotaResetTime, Date() < resetTime {
                print("Quota still exceeded, returning cached sermon")
                return cachedSermon
            } else {
                // Reset quota exceeded state if reset time has passed
                quotaExceeded = false
                quotaResetTime = nil
            }
        }
        
        print("Bundle ID: \(bundleId)")
        
        // Return cached result if within cache duration
        if let lastFetch = lastFetchTime,
           let cached = cachedSermon,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            print("Returning cached sermon")
            return cached
        }
        
        var urlComponents = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "channelId", value: channelId),
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "order", value: "date"),
            URLQueryItem(name: "maxResults", value: "10")
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        let searchResponse: SearchResponse = try await fetchWithRetry(request: request)
        
        let sermons = searchResponse.items.filter { item in
            let title = item.snippet.title.uppercased()
            let description = item.snippet.description.uppercased()
            
            let sermonKeywords = ["SERMON", "MESSAGE", "PASTOR", "PREACHING"]
            let excludedTerms = ["LIVE", "LIVESTREAM", "WORSHIP SERVICE"]
            
            return sermonKeywords.contains { title.contains($0) || description.contains($0) }
                && !excludedTerms.contains { title.contains($0) }
        }
        
        if let sermon = sermons.first {
            let video = Video(
                id: sermon.id.videoId,
                title: sermon.snippet.title,
                description: sermon.snippet.description,
                thumbnailURL: sermon.snippet.thumbnails.high.url,
                isLiveStream: false
            )
            
            cachedSermon = video
            lastFetchTime = Date()
            return video
        }
        
        return nil
    }
    
    func fetchUpcomingLivestream() async throws -> Video? {
        print("Bundle ID: \(bundleId)")
        
        // Return cached result if within cache duration
        if let lastFetch = lastFetchTime,
           let cached = cachedLivestream,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            print("Returning cached livestream")
            return cached
        }
        
        var urlComponents = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "channelId", value: channelId),
            URLQueryItem(name: "part", value: "snippet"),
            URLQueryItem(name: "eventType", value: "upcoming"),
            URLQueryItem(name: "type", value: "video"),
            URLQueryItem(name: "order", value: "date"),
            URLQueryItem(name: "maxResults", value: "1")
        ]
        
        guard let url = urlComponents.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        let searchResponse: SearchResponse = try await fetchWithRetry(request: request)
        
        if let livestream = searchResponse.items.first {
            let video = Video(
                id: livestream.id.videoId,
                title: livestream.snippet.title,
                description: livestream.snippet.description,
                thumbnailURL: livestream.snippet.thumbnails.high.url,
                isLiveStream: true
            )
            
            cachedLivestream = video
            lastFetchTime = Date()
            return video
        }
        
        return nil
    }
}

// Response models
private struct SearchResponse: Codable {
    let kind: String
    let etag: String
    let pageInfo: PageInfo
    let items: [SearchItem]
}

private struct PageInfo: Codable {
    let totalResults: Int
    let resultsPerPage: Int
}

private struct SearchItem: Codable {
    let id: VideoId
    let snippet: Snippet
}

private struct VideoId: Codable {
    let kind: String
    let videoId: String
}

private struct Snippet: Codable {
    let title: String
    let description: String
    let thumbnails: Thumbnails
}

private struct Thumbnails: Codable {
    let high: Thumbnail
}

private struct Thumbnail: Codable {
    let url: String
}
