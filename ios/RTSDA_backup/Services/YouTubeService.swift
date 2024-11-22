import Foundation

@globalActor
actor YouTubeService {
    static let shared = YouTubeService()
    
    private let apiKey = YTConfig.YouTube.apiKey
    private let channelId = YTConfig.YouTube.channelId
    private let session = URLSession.shared
    
    // Cache
    private var cachedSermon: Video?
    private var cachedLivestream: Video?
    private var lastFetchTime: Date?
    private let cacheDuration: TimeInterval = 3600 // 1 hour
    
    struct Video: Identifiable {
        let id: String
        let title: String
        let description: String
        let thumbnailURL: String
        let isLiveStream: Bool
    }
    
    func fetchLatestSermon() async throws -> Video? {
        // Return cached result if within cache duration
        if let lastFetch = lastFetchTime,
           let cached = cachedSermon,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            print("Returning cached sermon")
            return cached
        }
        
        let searchURL = "https://www.googleapis.com/youtube/v3/search?key=\(apiKey)&channelId=\(channelId)&part=snippet&type=video&order=date&maxResults=10"
        
        guard let url = URL(string: searchURL) else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        print("Fetching from URL: \(searchURL)")
        
        do {
            let (data, httpResponse) = try await session.data(from: url)
            
            if let response = httpResponse as? HTTPURLResponse {
                print("Response status code: \(response.statusCode)")
                
                if response.statusCode == 403 {
                    print("Quota exceeded, returning cached data if available")
                    return cachedSermon
                }
            }
            
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(SearchResponse.self, from: data)
            
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
        } catch {
            print("API Error: \(error)")
            return cachedSermon
        }
        
        return cachedSermon
    }
    
    func fetchUpcomingLivestream() async throws -> Video? {
        if let lastFetch = lastFetchTime,
           let cached = cachedLivestream,
           Date().timeIntervalSince(lastFetch) < cacheDuration {
            print("Returning cached livestream")
            return cached
        }
        
        let searchURL = "https://www.googleapis.com/youtube/v3/search?key=\(apiKey)&channelId=\(channelId)&part=snippet&eventType=upcoming&type=video&order=date&maxResults=1"
        
        guard let url = URL(string: searchURL) else {
            return cachedLivestream
        }
        
        do {
            let (data, httpResponse) = try await session.data(from: url)
            
            if let response = httpResponse as? HTTPURLResponse {
                if response.statusCode == 403 {
                    return cachedLivestream
                }
            }
            
            let decoder = JSONDecoder()
            let livestreamResponse = try decoder.decode(SearchResponse.self, from: data)
            
            if let livestream = livestreamResponse.items.first {
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
        } catch {
            return cachedLivestream
        }
        
        return cachedLivestream
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
