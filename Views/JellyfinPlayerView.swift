import SwiftUI
import AVKit

class PlayerViewController: AVPlayerViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        allowsPictureInPicturePlayback = true
    }
}

struct JellyfinPlayerView: View {
    let videoUrl: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        if let url = URL(string: videoUrl) {
            VideoViewControllerRepresentable(url: url, dismiss: dismiss)
                .ignoresSafeArea()
                .onAppear {
                    try? AVAudioSession.sharedInstance().setCategory(.playback)
                    try? AVAudioSession.sharedInstance().setActive(true)
                }
        }
    }
}

struct VideoViewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL
    let dismiss: DismissAction
    
    func makeUIViewController(context: Context) -> PlayerViewController {
        let controller = PlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.player?.play()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PlayerViewController, context: Context) {}
} 