import SwiftUI

struct OwncastView: View {
    @StateObject private var viewModel = OwncastViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if let streamUrl = viewModel.streamUrl {
                    VideoPlayerView(url: streamUrl)
                } else {
                    ContentUnavailableView {
                        Label("Stream Offline", systemImage: "video.slash")
                    } description: {
                        Text("The live stream is currently offline")
                    }
                }
            }
            .navigationTitle("Live Stream")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.checkStreamStatus()
        }
    }
} 