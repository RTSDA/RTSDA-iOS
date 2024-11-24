import Foundation

// Cache class for API responses
final class YouTubeAPICache: Codable {
    let data: Data
    let timestamp: Date
    
    // Cache API responses for 1 hour
    static let validityDuration: TimeInterval = 60 * 60
    
    init(data: Data, timestamp: Date = Date()) {
        self.data = data
        self.timestamp = timestamp
    }
    
    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < Self.validityDuration
    }
}

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
    
    private var quotaUsageDate: Date?
    private var dailyQuotaUsage: Int = 0
    private let maxDailyQuota = 10000
    private let quotaCostPerVideoLookup = 1  // Adjust this based on actual API cost
    
    private let cache = NSCache<NSString, YouTubeAPICache>()
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL? = {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("YouTubeAPICache")
    }()
    
    private func checkQuota() async throws {
        // Reset quota if it's a new day
        if let lastDate = quotaUsageDate, !Calendar.current.isDate(lastDate, inSameDayAs: Date()) {
            quotaUsageDate = Date()
            dailyQuotaUsage = 0
        }
        
        // Initialize date if first time
        if quotaUsageDate == nil {
            quotaUsageDate = Date()
        }
        
        // Check if we have enough quota
        if dailyQuotaUsage + quotaCostPerVideoLookup > maxDailyQuota {
            throw NSError(
                domain: "YouTubeService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Daily YouTube API quota exceeded. Please try again tomorrow."]
            )
        }
    }
    
    private func incrementQuota() {
        dailyQuotaUsage += quotaCostPerVideoLookup
    }
    
    private init() {
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        guard let cacheDirectory = cacheDirectory else { return }
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func getCachedResponse(for url: URL) -> Data? {
        let key = url.absoluteString as NSString
        
        // Check memory cache first
        if let cached = cache.object(forKey: key), cached.isValid {
            print("📦 Using cached response for: \(url.absoluteString)")
            return cached.data
        }
        
        // Check disk cache
        guard let cacheDirectory = cacheDirectory else { return nil }
        let fileURL = cacheDirectory.appendingPathComponent(key.hash.description + ".cache")
        
        guard let data = try? Data(contentsOf: fileURL),
              let cached = try? JSONDecoder().decode(YouTubeAPICache.self, from: data),
              cached.isValid else {
            return nil
        }
        
        // Update memory cache
        cache.setObject(cached, forKey: key)
        print("📦 Using disk-cached response for: \(url.absoluteString)")
        return cached.data
    }
    
    private func cacheResponse(_ data: Data, for url: URL) {
        let key = url.absoluteString as NSString
        let cache = YouTubeAPICache(data: data)
        
        // Save to memory cache
        self.cache.setObject(cache, forKey: key)
        
        // Save to disk cache
        guard let cacheDirectory = cacheDirectory else { return }
        let fileURL = cacheDirectory.appendingPathComponent(key.hash.description + ".cache")
        
        if let encodedData = try? JSONEncoder().encode(cache) {
            try? encodedData.write(to: fileURL)
        }
        print("💾 Cached response for: \(url.absoluteString)")
    }
    
    private func clearExpiredCache() {
        guard let cacheDirectory = cacheDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                guard let data = try? Data(contentsOf: file),
                      let cached = try? JSONDecoder().decode(YouTubeAPICache.self, from: data),
                      !cached.isValid else { continue }
                
                try? fileManager.removeItem(at: file)
                print("🗑️ Removed expired cache file: \(file.lastPathComponent)")
            }
        } catch {
            print("❌ Error clearing cache: \(error)")
        }
    }
    
    private func fetchWithRetry<T: Decodable>(request: URLRequest, retries: Int = 2) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                if attempt > 0 {
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
                
                if let cachedResponse = getCachedResponse(for: request.url!) {
                    let response = try JSONDecoder().decode(T.self, from: cachedResponse)
                    return response
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
                
                cacheResponse(data, for: request.url!)
                
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
    
    struct Video: Identifiable {
        let id: String
        let title: String
        let description: String
        let thumbnailURL: String
        let isLiveStream: Bool
        let duration: String?
    }
    
    private func isShortVideo(duration: String?) -> Bool {
        guard let duration = duration else { 
            print("No duration provided, treating as not a short")
            return false 
        }
        
        // Convert ISO 8601 duration to seconds
        let pattern = #"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(duration.startIndex..<duration.endIndex, in: duration)
        
        guard let match = regex.firstMatch(in: duration, range: range) else { 
            print("Could not parse duration: \(duration)")
            return false 
        }
        
        let hours = match.range(at: 1).location != NSNotFound ? Int(duration[Range(match.range(at: 1), in: duration)!]) ?? 0 : 0
        let minutes = match.range(at: 2).location != NSNotFound ? Int(duration[Range(match.range(at: 2), in: duration)!]) ?? 0 : 0
        let seconds = match.range(at: 3).location != NSNotFound ? Int(duration[Range(match.range(at: 3), in: duration)!]) ?? 0 : 0
        
        let totalSeconds = hours * 3600 + minutes * 60 + seconds
        let isShort = totalSeconds < 61
        print("Video duration: \(hours)h \(minutes)m \(seconds)s (total: \(totalSeconds)s)")
        if isShort {
            print("Video is a Short (duration: \(duration))")
        }
        return isShort
    }
    
    private func isWorshipService(title: String) -> Bool {
        let keywords = ["Worship Service", "Sabbath Service", "Divine Service"]
        let matches = keywords.filter { title.localizedCaseInsensitiveContains($0) }
        if !matches.isEmpty {
            print("Found service keywords in title: \(matches.joined(separator: ", "))")
            return true
        }
        return false
    }
    
    func fetchLatestSermon() async throws -> Video? {
        print("Fetching latest sermon...")
        // Get API key from Remote Config
        let apiKey = await configService.getString(forKey: ConfigService.Keys.youtubeApiKey)
        print("Using channel ID: \(channelId)")
        
        // Clear expired cache entries
        clearExpiredCache()
        
        // First, search for videos
        let searchUrlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=\(channelId)&maxResults=25&order=date&type=video&key=\(apiKey)"
        guard let searchUrl = URL(string: searchUrlString) else { 
            print("Failed to create search URL")
            return nil 
        }
        
        print("Search URL: \(searchUrlString)")
        
        let searchRequest = URLRequest(url: searchUrl)
        do {
            let searchResponse: SearchResponse = try await fetchWithRetry(request: searchRequest)
            print("Found \(searchResponse.items.count) videos in search")
            
            if searchResponse.items.isEmpty {
                print("No videos found in search response")
                return nil
            }
            
            // Get video details to check duration
            let videoIds = searchResponse.items.map { $0.id.videoId }.joined(separator: ",")
            let detailsUrlString = "https://www.googleapis.com/youtube/v3/videos?part=contentDetails,snippet,status&id=\(videoIds)&key=\(apiKey)"
            guard let detailsUrl = URL(string: detailsUrlString) else { 
                print("Failed to create details URL")
                return nil 
            }
            
            print("Details URL: \(detailsUrlString)")
            
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
            
            // Find the first video that's not a Short, not a livestream, and not a worship service
            guard let video = detailsResponse.items.first(where: { video in
                print("\nChecking video: \(video.snippet.title)")
                
                let notShort = !isShortVideo(duration: video.contentDetails.duration)
                if !notShort {
                    print("Filtered out: Is a short video")
                    return false
                }
                
                let notLivestream = video.snippet.liveBroadcastContent == "none"
                if !notLivestream {
                    print("Filtered out: Is a livestream (\(video.snippet.liveBroadcastContent))")
                    return false
                }
                
                let notWorshipService = !isWorshipService(title: video.snippet.title)
                if !notWorshipService {
                    print("Filtered out: Is a worship service")
                    return false
                }
                
                print("Video passed all filters")
                return true
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
        } catch {
            print("Error fetching latest sermon: \(error)")
            throw error
        }
    }
    
    func fetchUpcomingLivestream() async throws -> Video? {
        print("\nFetching upcoming livestream...")
        let apiKey = await configService.getString(forKey: ConfigService.Keys.youtubeApiKey)
        print("Using channel ID: \(channelId)")
        
        // Clear expired cache entries
        clearExpiredCache()
        
        let searchUrlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=\(channelId)&eventType=upcoming&type=video&order=date&maxResults=1&key=\(apiKey)"
        guard let searchUrl = URL(string: searchUrlString) else { 
            print("Failed to create search URL")
            return nil 
        }
        
        print("Search URL: \(searchUrlString)")
        
        let request = URLRequest(url: searchUrl)
        do {
            let response: SearchResponse = try await fetchWithRetry(request: request)
            print("Found \(response.items.count) upcoming livestreams")
            
            guard let item = response.items.first else {
                print("No upcoming livestreams found")
                return nil
            }
            
            print("Found upcoming livestream: \(item.snippet.title)")
            
            return Video(
                id: item.id.videoId,
                title: item.snippet.title,
                description: item.snippet.description,
                thumbnailURL: item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.default.url,
                isLiveStream: true,
                duration: nil
            )
        } catch {
            print("Error fetching upcoming livestream: \(error)")
            throw error
        }
    }
    
    func extractVideoURL(from videoId: String) async throws -> URL {
        // Check cache first
        if let cachedURL = VideoCacheManager.shared.getCachedVideo(id: videoId) {
            print("Using cached video URL for \(videoId)")
            return cachedURL
        }
        
        // Check quota before making API call
        try await checkQuota()
        
        print("Cache miss for \(videoId), fetching from API")
        
        // Use embedded player URL which works with AVPlayer
        let embedURL = "https://www.youtube.com/embed/\(videoId)?playsinline=1&autoplay=1"
        guard let videoURL = URL(string: embedURL) else {
            throw NSError(domain: "YouTubeService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid video URL"])
        }
        
        // Cache the video URL
        VideoCacheManager.shared.cacheVideo(id: videoId, url: videoURL)
        print("Cached video URL for \(videoId)")
        
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
