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
        // Create configuration with script message handler
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        // Add hymn detection script
        let hymnDetectionScript = """
        function detectAndModifyHymns() {
            // Regular expression to match patterns like:
            // - "Hymn XXX" or "Hymnal XXX" with optional quotes and title
            // - "#XXX" with optional quotes and title
            // - But NOT match when the number is followed by a colon (e.g., "10:45")
            // - And NOT match when the number is actually part of a larger number
            const hymnRegex = /(?:(hymn(?:al)?\\s+#?)|#)(\\d+)(?![\\d:\\.]|\\d*[apm])(?:\\s+["']([^"']+)["'])?/gi;
            
            // Extra check before creating links
            function isValidHymnNumber(text, matchIndex, number) {
                // Make sure this is not part of a time (e.g., "Hymn 10:45am")
                const afterMatch = text.substring(matchIndex + number.length);
                if (afterMatch.match(/^\\s*[:.]\\d|\\d*[apm]/)) {
                    return false;
                }
                return true;
            }
            
            // Function to replace text with a styled link
            function replaceWithLink(node) {
                if (node.nodeType === 3) {
                    // Text node
                    const content = node.textContent;
                    if (hymnRegex.test(content)) {
                        // Reset regex lastIndex
                        hymnRegex.lastIndex = 0;
                        
                        // Create a temporary element
                        const span = document.createElement('span');
                        let lastIndex = 0;
                        let match;
                        
                        // Find all matches and replace them with links
                        while ((match = hymnRegex.exec(content)) !== null) {
                            // Add text before the match
                            if (match.index > lastIndex) {
                                span.appendChild(document.createTextNode(content.substring(lastIndex, match.index)));
                            }
                            
                            // Get the hymn number
                            const hymnNumber = match[2];
                            
                            // Extra validation to ensure this isn't part of a time
                            const prefixLength = match[0].length - hymnNumber.length;
                            const numberStartIndex = match.index + prefixLength;
                            
                            if (!isValidHymnNumber(content, numberStartIndex, hymnNumber)) {
                                // Just add the original text if it's not a valid hymn reference
                                span.appendChild(document.createTextNode(match[0]));
                            } else {
                                // Create link element for valid hymn numbers
                                const hymnTitle = match[3] ? ': ' + match[3] : '';
                                const link = document.createElement('a');
                                link.textContent = match[0];
                                link.href = 'javascript:void(0)';
                                link.className = 'hymn-link';
                                link.setAttribute('data-hymn-number', hymnNumber);
                                link.style.color = '#0070c9';
                                link.style.textDecoration = 'underline';
                                link.style.fontWeight = 'bold';
                                link.onclick = function(e) {
                                    e.preventDefault();
                                    window.webkit.messageHandlers.hymnHandler.postMessage({ number: hymnNumber });
                                };
                                
                                span.appendChild(link);
                            }
                            
                            lastIndex = match.index + match[0].length;
                        }
                        
                        // Add any remaining text
                        if (lastIndex < content.length) {
                            span.appendChild(document.createTextNode(content.substring(lastIndex)));
                        }
                        
                        // Replace the original node with our span containing links
                        if (span.childNodes.length > 0) {
                            node.parentNode.replaceChild(span, node);
                        }
                    }
                } else if (node.nodeType === 1 && node.nodeName !== 'SCRIPT' && node.nodeName !== 'STYLE' && node.nodeName !== 'A') {
                    // Element node, not a script or style tag or already a link
                    Array.from(node.childNodes).forEach(child => replaceWithLink(child));
                }
            }
            
            // Process the document body
            replaceWithLink(document.body);
            
            console.log('Hymn detection script executed');
        }
        
        // Call the function after page has loaded and whenever content changes
        detectAndModifyHymns();
        
        // Use a MutationObserver to detect DOM changes and reapply the links
        const observer = new MutationObserver(mutations => {
            detectAndModifyHymns();
        });
        observer.observe(document.body, { childList: true, subtree: true });
        """
        
        let userScript = WKUserScript(
            source: hymnDetectionScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        
        contentController.addUserScript(userScript)
        contentController.add(context.coordinator, name: "hymnHandler")
        configuration.userContentController = contentController
        
        // Create the web view with our configuration
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
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebViewWithRefresh
        
        init(_ parent: WebViewWithRefresh) {
            self.parent = parent
        }
        
        // Handle messages from JavaScript
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "hymnHandler" {
                guard let body = message.body as? [String: Any],
                      let hymnNumberString = body["number"] as? String,
                      let hymnNumber = Int(hymnNumberString) else {
                    print("❌ Invalid hymn number received")
                    return
                }
                
                print("🎵 Opening hymn #\(hymnNumber)")
                AppAvailabilityService.shared.openHymnByNumber(hymnNumber)
            }
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
            
            // Execute the hymn detection script again after the page loads
            let rerunScript = "detectAndModifyHymns();"
            webView.evaluateJavaScript(rerunScript) { _, error in
                if let error = error {
                    print("❌ Error running hymn detection script: \(error.localizedDescription)")
                } else {
                    print("✅ Hymn detection script executed after page load")
                }
            }
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
