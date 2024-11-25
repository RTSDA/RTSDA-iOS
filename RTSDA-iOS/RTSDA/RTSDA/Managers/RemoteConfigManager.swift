import Foundation
import FirebaseRemoteConfig

class RemoteConfigManager {
    static let shared = RemoteConfigManager()
    
    private let remoteConfig: RemoteConfig
    
    // Remote config keys
    enum ConfigKey: String {
        case youtubeApiKey = "youtube_api_key"
        
        // Add more keys as needed
    }
    
    private init() {
        remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0 // Allow frequent fetches for development
        #else
        settings.minimumFetchInterval = 3600 // Production fetch interval: 1 hour
        #endif
        remoteConfig.configSettings = settings
        
        // Set default values
        let defaults: [String: NSObject] = [
            ConfigKey.youtubeApiKey.rawValue: "" as NSObject
        ]
        remoteConfig.setDefaults(defaults)
    }
    
    func fetchAndActivate() async throws {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            print("✅ Remote config fetch and activate status: \(status)")
        } catch {
            print("❌ Remote config fetch failed: \(error)")
            throw error
        }
    }
    
    func getString(for key: ConfigKey) -> String {
        remoteConfig[key.rawValue].stringValue
    }
    
    func getYouTubeApiKey() -> String {
        return getString(for: .youtubeApiKey)
    }
}
