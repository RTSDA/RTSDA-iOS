import Foundation
import FirebaseRemoteConfig

struct BibleAPIConfig {
    static let baseURL = "https://api.scripture.api.bible/v1"
    static let bibleId = "de4e12af7f28f599-02" // English Standard Version (ESV)
    
    // Remote Config keys
    private static let remoteConfigBibleApiKey = "bible_api_key"
    
    static func getAPIKey() async throws -> String {
        let remoteConfig = RemoteConfig.remoteConfig()
        
        do {
            // Fetch and activate remote config
            let status = try await remoteConfig.fetchAndActivate()
            print("[Bible API] Remote Config fetch status: \(status)")
            
            // Get the API key from remote config
            let apiKey = remoteConfig.configValue(forKey: remoteConfigBibleApiKey).stringValue ?? ""
            
            guard !apiKey.isEmpty else {
                print("[Bible API] Error: API key not found in Remote Config")
                throw NSError(
                    domain: "BibleAPIConfig",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Bible API key not found in Remote Config"]
                )
            }
            
            if let prefix = apiKey.prefix(6).first {
                print("[Bible API] Successfully fetched API key (prefix: \(prefix)...)")
            }
            return apiKey
        } catch {
            print("[Bible API] Error fetching API key: \(error.localizedDescription)")
            throw NSError(
                domain: "BibleAPIConfig",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to fetch Bible API key: \(error.localizedDescription)"]
            )
        }
    }
}
