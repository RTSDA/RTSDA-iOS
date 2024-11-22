import SwiftUI
import WebKit
import Foundation
import UIKit

struct DynamicWebView: UIViewRepresentable {
    let url: URL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.backgroundColor = .systemBackground
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = true
        webView.allowsBackForwardNavigationGestures = true
        
        // Add refresh control
        webView.scrollView.refreshControl = UIRefreshControl()
        webView.scrollView.refreshControl?.addTarget(
            context.coordinator,
            action: #selector(Coordinator.handleRefresh(_:)),
            for: .valueChanged
        )
        
        let request = URLRequest(url: url)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Update text size when dynamic type changes
        context.coordinator.updateTextSize(for: uiView)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: DynamicWebView
        
        init(_ parent: DynamicWebView) {
            self.parent = parent
            super.init()
        }
        
        @objc func handleRefresh(_ sender: UIRefreshControl) {
            let request = URLRequest(url: parent.url)
            sender.endRefreshing()
            
            if let webView = sender.superview?.superview as? WKWebView {
                webView.load(request)
            }
        }
        
        func updateTextSize(for webView: WKWebView) {
            let script = """
                document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust = '\(Int(UIFontMetrics.default.scaledValue(for: 16)))%'
            """
            webView.evaluateJavaScript(script)
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateTextSize(for: webView)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}
