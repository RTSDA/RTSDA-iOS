@preconcurrency import SwiftUI
@preconcurrency import WebKit

struct BulletinView: View {
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WebViewWithRefresh(url: URL(string: "https://rtsda.updates.church")!, isLoading: $isLoading)
            .navigationTitle("Bulletin")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(uiColor: .systemBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
    }
}

struct WebViewWithRefresh: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Add swipe gesture recognizer
        let swipeGesture = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe(_:)))
        swipeGesture.direction = .right
        webView.addGestureRecognizer(swipeGesture)
        
        // Configure refresh control with custom appearance
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, 
                               action: #selector(Coordinator.handleRefresh),
                               for: .valueChanged)
        // Set the refresh control's background color
        refreshControl.backgroundColor = .clear
        webView.scrollView.refreshControl = refreshControl
        
        // Set background colors
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebViewWithRefresh
        
        init(_ parent: WebViewWithRefresh) {
            self.parent = parent
        }
        
        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            print("🔄 Swipe detected")
            if gesture.state == .ended {
                if let webView = gesture.view as? WKWebView {
                    print("📱 Attempting to trigger back action")
                    
                    // JavaScript to click the Chakra UI back button
                    let script = """
                        function findBackButton() {
                            // Common back button selectors
                            var selectors = [
                                'button[aria-label="Go back"]',
                                'button.chakra-button[aria-label*="back"]',
                                'button.chakra-button svg[aria-label*="back"]',
                                'button.chakra-button span svg[aria-hidden="true"]',
                                'button svg[data-icon="arrow-left"]',
                                'button.chakra-button svg',
                                'button.chakra-button'
                            ];
                            
                            for (var i = 0; i < selectors.length; i++) {
                                var buttons = document.querySelectorAll(selectors[i]);
                                for (var j = 0; j < buttons.length; j++) {
                                    var button = buttons[j];
                                    // Check if it looks like a back button
                                    if (button.textContent.toLowerCase().includes('back') ||
                                        button.getAttribute('aria-label')?.toLowerCase().includes('back') ||
                                        button.innerHTML.toLowerCase().includes('back')) {
                                        console.log('Found back button:', button.outerHTML);
                                        return button;
                                    }
                                }
                            }
                            console.log('No back button found');
                            return null;
                        }
                        
                        var backButton = findBackButton();
                        if (backButton) {
                            backButton.click();
                            true;
                        } else {
                            false;
                        }
                    """
                    
                    webView.evaluateJavaScript(script) { result, error in
                        if let error = error {
                            print("❌ JavaScript error: \(error.localizedDescription)")
                        } else if let success = result as? Bool {
                            print(success ? "✅ Back button clicked" : "❌ No back button found")
                        }
                    }
                }
            }
        }
        
        @objc func handleRefresh(sender: UIRefreshControl) {
            parent.isLoading = true
            if let webView = sender.superview?.superview as? WKWebView {
                // Clear all website data
                WKWebsiteDataStore.default().removeData(
                    ofTypes: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache],
                    modifiedSince: Date(timeIntervalSince1970: 0)
                ) {
                    DispatchQueue.main.async {
                        // Create a fresh request
                        if let url = webView.url {
                            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                            webView.load(request)
                        }
                    }
                }
            }
        }
        
        // Navigation delegate methods
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            webView.scrollView.refreshControl?.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            webView.scrollView.refreshControl?.endRefreshing()
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            webView.scrollView.refreshControl?.endRefreshing()
        }
        
        // Handle back navigation
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .backForward {
                decisionHandler(.cancel)
                parent.isLoading = false
                return
            }
            decisionHandler(.allow)
        }
    }
}

#Preview {
    NavigationStack {
        BulletinView()
    }
}
