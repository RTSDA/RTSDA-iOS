import Foundation
import FirebaseRemoteConfig

@globalActor
actor ConfigService {
    static let shared = ConfigService()
    
    private let remoteConfig = RemoteConfig.remoteConfig()
    private var cachedValues: [String: String] = [:]
    
    private init() {}
    
    func fetchConfig() async throws {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            print("Config fetch status: \(status)")
            // Debug: Print YouTube API key (first 8 chars only for security)
            let key = await getString(forKey: Keys.youtubeApiKey)
            if !key.isEmpty {
                let prefix = String(key.prefix(8))
                print("Successfully fetched YouTube API key (prefix: \(prefix)...)")
            } else {
                print("Warning: YouTube API key is empty")
            }
        } catch {
            print("Error fetching remote config: \(error)")
            throw error
        }
    }
    
    func getString(forKey key: String) async -> String {
        if let cached = cachedValues[key] {
            return cached
        }
        let value = remoteConfig.configValue(forKey: key).stringValue ?? ""
        cachedValues[key] = value
        return value
    }
    
    func clearCache() {
        cachedValues.removeAll()
    }
}

// Configuration keys
extension ConfigService {
    enum Keys {
        static let youtubeApiKey = "youtube_api_key"
    }
}
