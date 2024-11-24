import SwiftUI
import WebKit

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
            action: #selector(Coordinator.handleRefresh),
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
        }
        
        @objc func handleRefresh(sender: UIRefreshControl) {
            guard let webView = sender.superview?.superview as? WKWebView else {
                sender.endRefreshing()
                return
            }
            
            webView.reload()
            sender.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateTextSize(for: webView)
        }
        
        func updateTextSize(for webView: WKWebView) {
            // Calculate the text size multiplier based on the current dynamic type size
            let textSizeMultiplier = calculateTextSizeMultiplier()
            
            // Inject CSS to scale text
            let js = """
                var style = document.createElement('style');
                style.innerHTML = `
                    :root {
                        --dynamic-text-multiplier: \(textSizeMultiplier);
                    }
                    body {
                        font-size: calc(1rem * var(--dynamic-text-multiplier)) !important;
                    }
                    p, div, span, a, li, td, th, label, input, textarea, button {
                        font-size: inherit !important;
                    }
                    h1 { font-size: calc(2em * var(--dynamic-text-multiplier)) !important; }
                    h2 { font-size: calc(1.5em * var(--dynamic-text-multiplier)) !important; }
                    h3 { font-size: calc(1.17em * var(--dynamic-text-multiplier)) !important; }
                    h4 { font-size: calc(1em * var(--dynamic-text-multiplier)) !important; }
                    h5 { font-size: calc(0.83em * var(--dynamic-text-multiplier)) !important; }
                    h6 { font-size: calc(0.67em * var(--dynamic-text-multiplier)) !important; }
                `;
                document.head.appendChild(style);
            """
            
            webView.evaluateJavaScript(js, completionHandler: nil)
        }
        
        private func calculateTextSizeMultiplier() -> Float {
            // Map SwiftUI's dynamic type sizes to web-friendly multipliers
            switch parent.dynamicTypeSize {
            case .xSmall:
                return 0.8
            case .small:
                return 0.9
            case .medium:
                return 1.0
            case .large:
                return 1.2
            case .xLarge:
                return 1.4
            case .xxLarge:
                return 1.6
            case .xxxLarge:
                return 1.8
            case .accessibility1:
                return 2.0
            case .accessibility2:
                return 2.4
            case .accessibility3:
                return 2.8
            case .accessibility4:
                return 3.2
            case .accessibility5:
                return 3.6
            @unknown default:
                return 1.0
            }
        }
    }
}
