import Foundation
import UIKit

class AppAvailabilityService {
    static let shared = AppAvailabilityService()
    
    private var availabilityCache: [String: Bool] = [:]
    
    // Common URL schemes
    static let schemes = (
        sabbathSchool: "com.googleusercontent.apps.443920152945-d0kf5h2dubt0jbcntq8l0qeg6lbpgn60://",  // URL scheme from Sabbath School Info.plist
        sabbathSchoolAlt: "https://sabbath-school.adventech.io",  // Official web app URL
        egwWritings: "egw-ios://",  // URL scheme from Info.plist (works in Safari)
        egwWritingsWeb: "https://m.egwwritings.org/en/folders/2",  // Mobile web version as fallback
        hymnal: "sdahymnal://",
        bible: "youversion://",
        facebook: "fb://profile/100064558722961",  // RTSDA Facebook profile ID
        tiktok: "tiktok://user/@rockvilletollandsda",  // RTSDA TikTok profile
        spotify: "spotify://show/2ARQaUBaGnVTiF9syrKDvO",  // RTSDA Spotify show
        podcasts: "podcasts://podcasts.apple.com/us/podcast/rockville-tolland-sda-church/id1630777684"  // RTSDA Apple Podcasts
    )
    
    // App Store fallback URLs
    static let appStoreURLs = (
        sabbathSchool: "https://apps.apple.com/us/app/sabbath-school/id895272167",
        egwWritings: "https://apps.apple.com/us/app/egw-writings-2/id994076136",  // Updated to correct App Store ID
        egwWritingsWeb: "https://m.egwwritings.org/en/folders/2",  // Mobile web version as primary fallback
        hymnal: "https://apps.apple.com/us/app/sda-hymnal/id1052432680",
        bible: "https://apps.apple.com/us/app/bible/id282935706",  // YouVersion Bible App
        facebook: "https://apps.apple.com/us/app/facebook/id284882215",
        tiktok: "https://apps.apple.com/us/app/tiktok/id835599320",
        spotify: "https://apps.apple.com/us/app/spotify-music-and-podcasts/id324684580",
        podcasts: "https://apps.apple.com/us/app/apple-podcasts/id525463029"
    )
    
    private init() {
        // Check for common apps at launch
        checkAvailability(urlScheme: Self.schemes.sabbathSchool)
        checkAvailability(urlScheme: Self.schemes.egwWritings)
        checkAvailability(urlScheme: Self.schemes.hymnal)
        checkAvailability(urlScheme: Self.schemes.bible)
        checkAvailability(urlScheme: Self.schemes.facebook)
        checkAvailability(urlScheme: Self.schemes.tiktok)
        checkAvailability(urlScheme: Self.schemes.spotify)
        checkAvailability(urlScheme: Self.schemes.podcasts)
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
        guard let appUrl = URL(string: urlScheme) else {
            print("⚠️ Failed to create URL: \(urlScheme)")
            if let fallback = URL(string: fallbackURL) {
                print("❌ Falling back to: \(fallback)")
                UIApplication.shared.open(fallback)
            }
            return
        }
        
        print("🔗 Attempting to open URL: \(appUrl)")
        if UIApplication.shared.canOpenURL(appUrl) {
            print("✅ Opening app URL: \(appUrl)")
            UIApplication.shared.open(appUrl)
        } else {
            if let webUrl = URL(string: Self.schemes.egwWritingsWeb) {
                print("✅ Opening mobile web URL: \(webUrl)")
                UIApplication.shared.open(webUrl)
            } else if let fallback = URL(string: fallbackURL) {
                print("❌ Falling back to: \(fallback)")
                UIApplication.shared.open(fallback)
            }
        }
    }
}
