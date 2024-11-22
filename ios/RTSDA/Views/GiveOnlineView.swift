import SwiftUI
import WebKit

class GiveOnlineWebViewStateModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var error: Error? = nil
}

struct GiveOnlineView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var webViewState = GiveOnlineWebViewStateModel()
    
    var body: some View {
        NavigationStack {
            GiveOnlineWebView(url: URL(string: "https://adventistgiving.org/donate/AN4MJG")!, webViewState: webViewState)
                .overlay {
                    if webViewState.isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).opacity(0.8))
                    }
                }
                .navigationTitle("Give Online")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .imageScale(.medium)
                        }
                    }
                }
        }
    }
}

struct GiveOnlineWebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var webViewState: GiveOnlineWebViewStateModel
    
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
        @ObservedObject private var webViewState: GiveOnlineWebViewStateModel
        
        init(webViewState: GiveOnlineWebViewStateModel) {
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
