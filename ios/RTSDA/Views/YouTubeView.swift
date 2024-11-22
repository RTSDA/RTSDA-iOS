import SwiftUI
import AVKit
import MediaPlayer

// Cache class for video information
final class VideoCache: NSObject, Codable {
    let videoURL: String
    let timestamp: Date
    
    // Cache validity duration (24 hours)
    static let validityDuration: TimeInterval = 24 * 60 * 60
    
    init(videoURL: String, timestamp: Date = Date()) {
        self.videoURL = videoURL
        self.timestamp = timestamp
        super.init()
    }
    
    var isValid: Bool {
        return Date().timeIntervalSince(timestamp) < Self.validityDuration
    }
}

class VideoCacheManager {
    static let shared = VideoCacheManager()
    
    private let memoryCache = NSCache<NSString, VideoCache>()
    private let fileManager = FileManager.default
    
    private var cacheDirectory: URL? {
        return fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("VideoCache")
    }
    
    private init() {
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        guard let cacheDirectory = cacheDirectory else { return }
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    func getCachedVideo(id: String) -> URL? {
        // Check memory cache first
        if let cached = memoryCache.object(forKey: id as NSString), cached.isValid {
            return URL(string: cached.videoURL)
        }
        
        // Check disk cache
        guard let cached = loadFromDisk(id: id), cached.isValid else {
            return nil
        }
        
        // Update memory cache
        memoryCache.setObject(cached, forKey: id as NSString)
        return URL(string: cached.videoURL)
    }
    
    func cacheVideo(id: String, url: URL) {
        let cache = VideoCache(videoURL: url.absoluteString, timestamp: Date())
        
        // Save to memory
        memoryCache.setObject(cache, forKey: id as NSString)
        
        // Save to disk
        saveToDisk(cache: cache, id: id)
    }
    
    private func loadFromDisk(id: String) -> VideoCache? {
        guard let cacheDirectory = cacheDirectory else { return nil }
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")
        
        guard let data = try? Data(contentsOf: fileURL),
              let cache = try? JSONDecoder().decode(VideoCache.self, from: data) else {
            return nil
        }
        
        return cache
    }
    
    private func saveToDisk(cache: VideoCache, id: String) {
        guard let cacheDirectory = cacheDirectory else { return }
        let fileURL = cacheDirectory.appendingPathComponent("\(id).cache")
        
        if let data = try? JSONEncoder().encode(cache) {
            try? data.write(to: fileURL)
        }
    }
    
    func clearExpiredCache() {
        guard let cacheDirectory = cacheDirectory else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                if let cache = loadFromDisk(id: file.deletingPathExtension().lastPathComponent),
                   !cache.isValid {
                    try? fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Error clearing cache: \(error)")
        }
    }
}

class VideoPlayerState: ObservableObject {
    static let shared = VideoPlayerState()
    @Published var player: AVPlayer?
    @Published var currentVideoId: String?
    @Published var isPlaying: Bool = false
    @Published var error: Error?
    @Published var isLoading: Bool = false
    var pipController: AVPictureInPictureController?
    private var playerItemObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var audioSession: AVAudioSession?
    private var nowPlayingInfo: [String: Any] = [:]
    
    init() {
        setupAudioSession()
        setupNotifications()
        setupRemoteCommandCenter()
    }
    
    private func setupAudioSession() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            // Configure for video playback with mixing
            try audioSession?.setCategory(.playback, 
                                      mode: .moviePlayback,
                                      policy: .longFormVideo,
                                      options: [.allowAirPlay, .allowBluetooth])
            
            // Set preferred sample rate and IO buffer duration for video
            try audioSession?.setPreferredSampleRate(44100.0)
            try audioSession?.setPreferredIOBufferDuration(0.005)
            
            // Activate the audio session
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    private func setupNotifications() {
        // Audio session interruption handling
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: audioSession)
        
        // Route change handling
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAudioRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: audioSession)
        
        // Media server reset handling
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleMediaServerReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: audioSession)
        
        // App lifecycle handling
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            self?.isPlaying = true
            return .success
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            self?.isPlaying = false
            return .success
        }
        
        // Seek command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.player?.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 1))
            return .success
        }
    }
    
    @objc private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            player?.pause()
            isPlaying = false
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                player?.play()
                isPlaying = true
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
            // Automatically pause when headphones are unplugged
            player?.pause()
            isPlaying = false
        case .newDeviceAvailable, .categoryChange:
            // Handle new audio route
            do {
                try audioSession?.setActive(true)
            } catch {
                print("Failed to reactivate audio session: \(error)")
            }
        default:
            break
        }
    }
    
    @objc private func handleMediaServerReset(_ notification: Notification) {
        setupAudioSession()
        if isPlaying {
            player?.play()
        }
    }
    
    @objc private func handleAppDidEnterBackground(_ notification: Notification) {
        updateNowPlayingInfo()
    }
    
    @objc private func handleAppWillEnterForeground(_ notification: Notification) {
        do {
            try audioSession?.setActive(true)
        } catch {
            print("Failed to reactivate audio session: \(error)")
        }
    }
    
    internal func updateNowPlayingInfo() {
        guard let player = player else { return }
        
        // Update now playing info
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.duration.seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func setPlayer(with url: URL) {
        cleanup()
        
        let player = AVPlayer(url: url)
        self.player = player
        
        // Configure player for background playback
        player.allowsExternalPlayback = true
        player.preventsDisplaySleepDuringVideoPlayback = true
        
        // Set up AirPlay if available
        if let playerLayer = player.currentItem?.asset as? AVURLAsset {
            playerLayer.resourceLoader.preloadsEligibleContentKeys = true
        }
        
        // Observe player item status
        playerItemObserver = player.currentItem?.observe(\.status) { [weak self] item, _ in
            if item.status == .failed {
                self?.error = item.error
            }
        }
        
        // Add time observer for updating now playing info
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        
        // Start playback
        player.play()
        isPlaying = true
        
        // Update now playing info
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentVideoId
        updateNowPlayingInfo()
    }
    
    private func cleanup() {
        playerItemObserver?.invalidate()
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        player?.pause()
        isPlaying = false
    }
    
    deinit {
        cleanup()
        NotificationCenter.default.removeObserver(self)
        do {
            try audioSession?.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
    }
}

struct VideoLoadingView: View {
    var body: some View {
        ProgressView()
    }
}

struct YouTubeView: View {
    let videoId: String
    @StateObject private var playerState = VideoPlayerState.shared
    @State private var isLoading = true
    @State private var playerLayer: AVPlayerLayer?
    
    var body: some View {
        ZStack {
            if isLoading {
                VideoLoadingView()
            }
            
            VideoPlayer(player: playerState.player)
                .onAppear {
                    loadVideo()
                }
                .onDisappear {
                    playerState.player?.pause()
                }
                .overlay(
                    Group {
                        if let error = playerState.error {
                            Text("Error: \(error.localizedDescription)")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                )
                .allowsHitTesting(true)
                .aspectRatio(16/9, contentMode: .fit)
                .background(PlayerLayerView(player: playerState.player, onLayerCreated: { layer in
                    playerLayer = layer
                    setupPiP()
                }))
        }
    }
    
    private func setupPiP() {
        guard let playerLayer = playerLayer,
              AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }
        
        let pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
        playerState.pipController = pipController
    }
    
    private func loadVideo() {
        isLoading = true
        Task {
            do {
                let videoURL = try await YouTubeService.shared.extractVideoURL(from: videoId)
                await MainActor.run {
                    playerState.setPlayer(with: videoURL)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    playerState.error = error
                    isLoading = false
                }
            }
        }
    }
}

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer?
    let onLayerCreated: (AVPlayerLayer) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let layer = AVPlayerLayer()
        layer.player = player
        layer.videoGravity = .resizeAspect
        view.layer.addSublayer(layer)
        onLayerCreated(layer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            layer.player = player
        }
    }
}