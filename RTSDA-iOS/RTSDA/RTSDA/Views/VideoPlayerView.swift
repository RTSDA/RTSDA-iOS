import SwiftUI
import AVKit
import MediaPlayer

struct VideoPlayerView: View {
    let videoId: String
    @Binding var player: AVPlayer?
    @State private var pipController: AVPictureInPictureController?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                setupPlayer()
                setupNowPlaying()
                setupPictureInPicture()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
    
    private func setupPlayer() {
        if player == nil {
            let videoURL = URL(string: "https://www.youtube.com/watch?v=\(videoId)")!
            player = AVPlayer(url: videoURL)
            
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try? AVAudioSession.sharedInstance().setActive(true)
            
            NotificationCenter.default.addObserver(
                forName: AVAudioSession.routeChangeNotification,
                object: nil,
                queue: .main
            ) { notification in
                guard let userInfo = notification.userInfo,
                      let reasonRaw = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw)
                else { return }
                
                switch reason {
                case .oldDeviceUnavailable:
                    player?.pause()
                default:
                    break
                }
            }
        }
    }
    
    private func setupNowPlaying() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { _ in
            player?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { _ in
            player?.pause()
            return .success
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: "Video",
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]
    }
    
    private func setupPictureInPicture() {
        guard let playerLayer = player?.currentItem?.asset as? AVPlayerLayer else { return }
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
    }
}
