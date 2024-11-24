import SwiftUI
import WebKit
import AVFoundation

struct YouTubeView: UIViewRepresentable {
    let videoId: String
    
    func makeUIView(context: Context) -> WKWebView {
        // Configure audio session
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = .nonPersistent()
        
        // Enable background playback
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = true
        
        // Remove any RL prefix if present
        let cleanId = videoId.hasPrefix("RL") ? String(videoId.dropFirst(2)) : videoId
        print("Loading clean video ID: \(cleanId)")
        
        // Use embedded player URL with autoplay and background playback
        if let url = URL(string: "https://www.youtube.com/embed/\(cleanId)?playsinline=1&autoplay=1&modestbranding=1&enablejsapi=1&rel=0") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
} 