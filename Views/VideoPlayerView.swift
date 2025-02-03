import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var isInPiPMode = false
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            VideoPlayerViewController(url: url, isInPiPMode: $isInPiPMode, isLoading: $isLoading)
                .ignoresSafeArea()
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(isInPiPMode)
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .onAppear {
            setupAudio()
        }
    }
    
    private func setupAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}

struct VideoPlayerViewController: UIViewControllerRepresentable {
    let url: URL
    @Binding var isInPiPMode: Bool
    @Binding var isLoading: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        controller.delegate = context.coordinator
        
        // Add observer for buffering state
        player.addObserver(context.coordinator, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        context.coordinator.setPlayerController(controller)
        
        player.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isInPiPMode: $isInPiPMode, isLoading: $isLoading)
    }
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        @Binding var isInPiPMode: Bool
        @Binding var isLoading: Bool
        internal var playerController: AVPlayerViewController?
        private var wasPlayingBeforeDismiss = false
        
        init(isInPiPMode: Binding<Bool>, isLoading: Binding<Bool>) {
            _isInPiPMode = isInPiPMode
            _isLoading = isLoading
            super.init()
        }
        
        func setPlayerController(_ controller: AVPlayerViewController) {
            playerController = controller
        }
        
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "timeControlStatus",
               let player = object as? AVPlayer {
                DispatchQueue.main.async {
                    self.isLoading = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                }
            }
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            if let player = playerController?.player {
                wasPlayingBeforeDismiss = (player.rate > 0)
            }
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            if wasPlayingBeforeDismiss, let player = playerController?.player {
                // Prevent the player from pausing during transition
                player.rate = 1.0
            }
        }
        
        func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            isInPiPMode = true
        }
        
        func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            isInPiPMode = false
        }
        
        deinit {
            if let player = playerController?.player {
                player.removeObserver(self, forKeyPath: "timeControlStatus")
            }
        }
    }
} 