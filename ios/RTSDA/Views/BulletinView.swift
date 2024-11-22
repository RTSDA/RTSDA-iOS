import SwiftUI
import WebKit

class WebViewStateModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var error: Error? = nil
}

struct BulletinView: View {
    @StateObject private var webViewState = WebViewStateModel()
    
    var body: some View {
        BulletinWebView(url: URL(string: "https://rtsda.updates.church")!, webViewState: webViewState)
            .overlay {
                if webViewState.isLoading {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .navigationTitle("Updates")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct BulletinWebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var webViewState: WebViewStateModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(webViewState: webViewState)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        // Enable zoom
        webView.configuration.preferences.javaScriptEnabled = true
        webView.scrollView.setZoomScale(1.0, animated: false)
        webView.scrollView.minimumZoomScale = 0.5
        webView.scrollView.maximumZoomScale = 3.0
        
        // Load URL
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        webView.load(request)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @ObservedObject private var webViewState: WebViewStateModel
        
        init(webViewState: WebViewStateModel) {
            self.webViewState = webViewState
        }
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            if let webView = refreshControl.superview?.superview as? WKWebView {
                webView.reload()
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            webViewState.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webViewState.isLoading = false
            webView.scrollView.refreshControl?.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            webViewState.isLoading = false
            webViewState.error = error
            webView.scrollView.refreshControl?.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            webViewState.isLoading = false
            webViewState.error = error
            webView.scrollView.refreshControl?.endRefreshing()
        }
    }
}
