import Foundation
import UIKit

class AppAvailabilityService {
    static let shared = AppAvailabilityService()
    
    private var availabilityCache: [String: Bool] = [:]
    
    // Common URL schemes
    struct Schemes {
        static let bible = "youversion://"
        static let egw = "egw-ios://"
        static let hymnal = "adventisthymnarium://"
        static let sabbathSchool = "com.googleusercontent.apps.443920152945-d0kf5h2dubt0jbcntq8l0qeg6lbpgn60://"
        static let sabbathSchoolAlt = "https://sabbath-school.adventech.io"
        static let egwWritingsWeb = "https://m.egwwritings.org/en/folders/2"
        static let facebook = "https://www.facebook.com/rockvilletollandsdachurch/"
        static let tiktok = "https://www.tiktok.com/@rockvilletollandsda"
        static let spotify = "spotify://show/2ARQaUBaGnVTiF9syrKDvO"
        static let podcasts = "podcasts://podcasts.apple.com/us/podcast/rockville-tolland-sda-church/id1630777684"
    }
    
    // App Store fallback URLs
    struct AppStoreURLs {
        static let sabbathSchool = "https://apps.apple.com/us/app/sabbath-school/id895272167"
        static let egwWritings = "https://apps.apple.com/us/app/egw-writings-2/id994076136"
        static let egwWritingsWeb = "https://m.egwwritings.org/en/folders/2"
        static let hymnal = "https://apps.apple.com/us/app/hymnal-adventist/id6446034427"
        static let bible = "https://apps.apple.com/us/app/bible/id282935706"
        static let facebook = "https://apps.apple.com/us/app/facebook/id284882215"
        static let tiktok = "https://apps.apple.com/us/app/tiktok/id835599320"
        static let spotify = "https://apps.apple.com/us/app/spotify-music-and-podcasts/id324684580"
        static let podcasts = "https://apps.apple.com/us/app/apple-podcasts/id525463029"
    }
    
    private init() {
        // Check for common apps at launch
        checkAvailability(urlScheme: Schemes.sabbathSchool)
        checkAvailability(urlScheme: Schemes.egw)
        checkAvailability(urlScheme: Schemes.bible)
        checkAvailability(urlScheme: Schemes.facebook)
        checkAvailability(urlScheme: Schemes.tiktok)
        checkAvailability(urlScheme: Schemes.spotify)
        checkAvailability(urlScheme: Schemes.podcasts)
    }
    
    func isAppInstalled(urlScheme: String) -> Bool {
        if let cached = availabilityCache[urlScheme] {
            return cached
        }
        return checkAvailability(urlScheme: urlScheme)
    }
    
    @discardableResult
    private func checkAvailability(urlScheme: String) -> Bool {
        guard let url = URL(string: urlScheme) else {
            print("⚠️ Failed to create URL for scheme: \(urlScheme)")
            return false
        }
        let isAvailable = UIApplication.shared.canOpenURL(url)
        print("📱 App availability for \(urlScheme): \(isAvailable)")
        availabilityCache[urlScheme] = isAvailable
        return isAvailable
    }
    
    func openApp(urlScheme: String, fallbackURL: String) {
        // First try the URL scheme
        if let appUrl = URL(string: urlScheme) {
            print("🔗 Attempting to open URL: \(appUrl)")
            
            // Check if we can open the URL
            if UIApplication.shared.canOpenURL(appUrl) {
                print("✅ Opening app URL: \(appUrl)")
                UIApplication.shared.open(appUrl) { success in
                    if !success {
                        print("❌ Failed to open app URL: \(appUrl)")
                        self.handleFallback(urlScheme: urlScheme, fallbackURL: fallbackURL)
                    }
                }
            } else {
                print("❌ Cannot open app URL: \(appUrl)")
                handleFallback(urlScheme: urlScheme, fallbackURL: fallbackURL)
            }
        } else {
            print("⚠️ Failed to create URL: \(urlScheme)")
            handleFallback(urlScheme: urlScheme, fallbackURL: fallbackURL)
        }
    }
    
    private func handleFallback(urlScheme: String, fallbackURL: String) {
        // Special handling for Sabbath School app
        if urlScheme == Schemes.sabbathSchool {
            if let altUrl = URL(string: Schemes.sabbathSchoolAlt) {
                print("✅ Opening Sabbath School web app: \(altUrl)")
                UIApplication.shared.open(altUrl)
                return
            }
        }
        // Special handling for EGW Writings app
        else if urlScheme == Schemes.egw {
            if let webUrl = URL(string: Schemes.egwWritingsWeb) {
                print("✅ Opening EGW mobile web URL: \(webUrl)")
                UIApplication.shared.open(webUrl)
                return
            }
        }
        
        // Try the fallback URL
        if let fallback = URL(string: fallbackURL) {
            print("⬇️ Falling back to: \(fallback)")
            UIApplication.shared.open(fallback) { success in
                if !success {
                    print("❌ Failed to open fallback URL: \(fallback)")
                }
            }
        } else {
            print("❌ Failed to create fallback URL: \(fallbackURL)")
        }
    }
}
