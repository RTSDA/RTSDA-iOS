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
        facebook: "https://www.facebook.com/rockvilletollandsdachurch/",  // RTSDA Facebook page
        tiktok: "https://www.tiktok.com/@rockvilletollandsda",  // RTSDA TikTok profile
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
        if urlScheme == Self.schemes.sabbathSchool {
            if let altUrl = URL(string: Self.schemes.sabbathSchoolAlt) {
                print("✅ Opening Sabbath School web app: \(altUrl)")
                UIApplication.shared.open(altUrl)
                return
            }
        }
        // Special handling for EGW Writings app
        else if urlScheme == Self.schemes.egwWritings {
            if let webUrl = URL(string: Self.schemes.egwWritingsWeb) {
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
