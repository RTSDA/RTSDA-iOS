import SwiftUI
import WebKit
import os.log
import Network
import AVFoundation
import AVKit

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "BulletinView")
private let sharedProcessPool = WKProcessPool()

class WebViewStateModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    @Published var isLoading: Bool = false
    @Published var error: Error? = nil
    @Published var webView: WKWebView?
    @Published var hasLoadedContent: Bool = false
    @Published var lastUpdate: Date = Date()
    private var contentUpdateTimer: Timer?
    private var audioSession: AVAudioSession?
    
    override init() {
        super.init()
        setupAudioSession()
        createWebView()
        setupAutoRefresh()
        setupNotifications()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            // Configure audio session for mixed usage
            try audioSession?.setCategory(.playback, 
                                        mode: .default,
                                        policy: .longFormAudio,
                                        options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            
            // Set active with options that allow mixing with other audio
            try audioSession?.setActive(true, options: [.notifyOthersOnDeactivation])
            
            // Set preferred IO buffer duration for better performance
            try audioSession?.setPreferredIOBufferDuration(0.005)
            
            // Enable background playback when screen is locked
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupNotifications() {
        // Audio session interruption notifications
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession)
        
        // Audio route change notifications
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession)
        
        // Media server notifications
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleMediaServerReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: audioSession)
            
        // Background/Foreground notifications
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
            
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Audio session interrupted, handle pause
            webView?.evaluateJavaScript("document.querySelectorAll('video, audio').forEach(m => m.pause())")
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            // Check if we should resume playback
            if options.contains(.shouldResume) {
                do {
                    try audioSession?.setActive(true)
                    webView?.evaluateJavaScript("document.querySelectorAll('video, audio').forEach(m => m.play())")
                } catch {
                    logger.error("Failed to reactivate audio session: \(error.localizedDescription)")
                }
            }
        @unknown default:
            break
        }
    }
    
    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Old audio route is no longer available (e.g., headphones unplugged)
            webView?.evaluateJavaScript("document.querySelectorAll('video, audio').forEach(m => m.pause())")
        case .newDeviceAvailable, .categoryChange:
            // New audio route is available or category changed
            do {
                try audioSession?.setActive(true)
            } catch {
                logger.error("Failed to reactivate audio session after route change: \(error.localizedDescription)")
            }
        default:
            break
        }
    }
    
    @objc private func handleMediaServerReset(_ notification: Notification) {
        // Media server was reset, reconfigure audio session
        setupAudioSession()
    }
    
    @objc private func handleEnterBackground() {
        // Ensure audio session stays active in background
        do {
            try audioSession?.setActive(true, options: [])
        } catch {
            logger.error("Failed to keep audio session active in background: \(error.localizedDescription)")
        }
    }
    
    @objc private func handleEnterForeground() {
        // Reactivate audio session if needed
        do {
            if !(audioSession?.isOtherAudioPlaying ?? false) {
                try audioSession?.setActive(true, options: [])
            }
        } catch {
            logger.error("Failed to reactivate audio session: \(error.localizedDescription)")
        }
    }
    
    func createWebView() {
        let config = WKWebViewConfiguration()
        config.processPool = sharedProcessPool
        config.websiteDataStore = .nonPersistent()
        
        // Configure for media playback
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []  // Allow autoplay
        
        // Enable Picture in Picture support
        config.allowsPictureInPictureMediaPlayback = true
        
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences
        
        config.suppressesIncrementalRendering = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        // Add JavaScript to enable PiP for all video elements
        let script = WKUserScript(source: """
            document.addEventListener('DOMContentLoaded', function() {
                const videos = document.getElementsByTagName('video');
                for (let video of videos) {
                    if (video.webkitSupportsPresentationMode && typeof video.webkitSetPresentationMode === 'function') {
                        video.webkitSetPresentationMode('inline');
                    }
                    // Enable PiP support
                    video.setAttribute('webkit-playsinline', '');
                    video.setAttribute('playsinline', '');
                    video.setAttribute('x-webkit-airplay', '');
                    // Add PiP button
                    if (document.pictureInPictureEnabled || document.webkitSupportsPresentationMode) {
                        video.addEventListener('loadedmetadata', function() {
                            if (video.webkitSupportsPresentationMode && typeof video.webkitSetPresentationMode === 'function') {
                                video.webkitSetPresentationMode('inline');
                            }
                        });
                    }
                }
            }, false);
            """, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        webView.configuration.userContentController.addUserScript(script)
        
        self.webView = webView
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupAutoRefresh() {
        // Check for updates every 5 minutes
        contentUpdateTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.lastUpdate = Date()
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isLoading = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isLoading = false
        hasLoadedContent = true
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        self.error = error
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        isLoading = false
        self.error = error
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}

struct BulletinView: View {
    @StateObject private var webViewState = WebViewStateModel()
    private let url = URL(string: "https://rtsda.updates.church")!
    private let monitor = NWPathMonitor()
    @State private var isConnected = true
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            // Background color
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            if !isConnected {
                VStack(spacing: 16) {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Internet Connection")
                        .font(.headline)
                    Text("Please check your network settings and try again")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: checkConnectivityAndLoad) {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else if let webView = webViewState.webView {
                WebViewWrapper(webView: webView,
                             url: url,
                             isRefreshing: $isRefreshing,
                             onRefresh: refresh,
                             webViewState: webViewState)
                    .opacity(webViewState.hasLoadedContent ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: webViewState.hasLoadedContent)
                
                if webViewState.isLoading || isRefreshing {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
        .onAppear {
            setupNetworkMonitoring()
        }
        // Add automatic refresh when lastUpdate changes
        .onChange(of: webViewState.lastUpdate) { _ in
            if isConnected && !isRefreshing {
                refresh()
            }
        }
    }
    
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                let wasConnected = isConnected
                isConnected = path.status == .satisfied
                
                if !wasConnected && isConnected {
                    checkConnectivityAndLoad()
                }
                
                logger.debug("Network status changed: \(path.status == .satisfied ? "connected" : "disconnected")")
            }
        }
        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    private func checkConnectivityAndLoad() {
        guard isConnected else { return }
        refresh()
    }
    
    private func refresh() {
        webViewState.hasLoadedContent = false
        // Create a new WebView instance
        webViewState.createWebView()
        // Load content in the new WebView
        if let webView = webViewState.webView {
            loadContent(in: webView)
        }
    }
    
    private func loadContent(in webView: WKWebView) {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        request.setValue("RTSDA-iOS-App", forHTTPHeaderField: "User-Agent")
        
        webView.load(request)
    }
    
    private func handleError(_ error: Error) {
        webViewState.error = error
        webViewState.isLoading = false
        isRefreshing = false
    }
}

struct WebViewWrapper: UIViewRepresentable {
    let webView: WKWebView
    let url: URL
    @Binding var isRefreshing: Bool
    let onRefresh: () -> Void
    @ObservedObject var webViewState: WebViewStateModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
        
        loadContent()
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // If this is a different WebView instance, update the delegates and refresh control
        if webView != self.webView {
            self.webView.navigationDelegate = context.coordinator
            self.webView.uiDelegate = context.coordinator
            
            // Transfer refresh control to new WebView
            if let oldRefreshControl = webView.scrollView.refreshControl {
                let newRefreshControl = UIRefreshControl()
                newRefreshControl.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh(_:)), for: .valueChanged)
                self.webView.scrollView.refreshControl = newRefreshControl
                
                // If was refreshing, keep the new control refreshing
                if oldRefreshControl.isRefreshing {
                    newRefreshControl.beginRefreshing()
                }
            }
        }
        
        // End refreshing if needed
        if !isRefreshing, let refreshControl = webView.scrollView.refreshControl, refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }
    
    private func loadContent() {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")
        webView.load(request)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WebViewWrapper
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
            super.init()
        }
        
        @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
            parent.webViewState.hasLoadedContent = false
            parent.onRefresh()
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { [self] in
                if !parent.webViewState.hasLoadedContent {
                    parent.webViewState.isLoading = true
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { [self] in
                parent.webViewState.isLoading = false
                parent.webViewState.hasLoadedContent = true
                parent.isRefreshing = false
                if let refreshControl = webView.scrollView.refreshControl, refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [self] in
                parent.webViewState.isLoading = false
                parent.isRefreshing = false
                if let refreshControl = webView.scrollView.refreshControl, refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { [self] in
                parent.webViewState.isLoading = false
                parent.isRefreshing = false
                if let refreshControl = webView.scrollView.refreshControl, refreshControl.isRefreshing {
                    refreshControl.endRefreshing()
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
