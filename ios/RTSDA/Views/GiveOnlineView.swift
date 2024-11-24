import SwiftUI
import WebKit

class GiveOnlineWebViewStateModel: ObservableObject {
    @Published var isLoading: Bool = true
    @Published var error: Error? = nil
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    weak var webView: WKWebView?
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
}

struct GiveOnlineView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var webViewState = GiveOnlineWebViewStateModel()
    let url = URL(string: "https://adventistgiving.org/donate/AN4MJG")!
    
    var body: some View {
        NavigationStack {
            WebView(url: url, webViewState: webViewState)
                .overlay {
                    if webViewState.isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
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
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            if webViewState.canGoBack {
                                Button(action: {
                                    webViewState.goBack()
                                }) {
                                    Image(systemName: "chevron.backward")
                                }
                            }
                            
                            if webViewState.canGoForward {
                                Button(action: {
                                    webViewState.goForward()
                                }) {
                                    Image(systemName: "chevron.forward")
                                }
                            }
                        }
                    }
                }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var webViewState: GiveOnlineWebViewStateModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(webViewState: webViewState)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.alwaysBounceVertical = false
        
        webViewState.webView = webView
        webView.load(URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad))
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        DispatchQueue.main.async {
            webViewState.canGoBack = webView.canGoBack
            webViewState.canGoForward = webView.canGoForward
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @ObservedObject private var webViewState: GiveOnlineWebViewStateModel
        
        init(webViewState: GiveOnlineWebViewStateModel) {
            self.webViewState = webViewState
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.webViewState.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.webViewState.isLoading = false
                self.webViewState.canGoBack = webView.canGoBack
                self.webViewState.canGoForward = webView.canGoForward
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.webViewState.isLoading = false
                self.webViewState.error = error
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.webViewState.isLoading = false
                self.webViewState.error = error
            }
        }
    }
}
