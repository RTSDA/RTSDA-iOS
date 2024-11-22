import SwiftUI

struct MessagesView: View {
    @State private var latestSermon: YouTubeService.Video?
    @State private var upcomingLivestream: YouTubeService.Video?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedVideo: YouTubeService.Video?
    @State private var showingVideo = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        if let livestream = upcomingLivestream {
                            Button {
                                selectedVideo = livestream
                                showingVideo = true
                            } label: {
                                VideoCardView(video: livestream)
                                    .padding(.horizontal)
                            }
                        }
                        
                        if let sermon = latestSermon {
                            Button {
                                selectedVideo = sermon
                                showingVideo = true
                            } label: {
                                VideoCardView(video: sermon)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .refreshable {
                await loadContent()
            }
            .task {
                await loadContent()
            }
            .sheet(isPresented: $showingVideo) {
                if let video = selectedVideo {
                    YouTubeView(videoId: video.id)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
    
    private func loadContent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let sermonTask = YouTubeService.shared.fetchLatestSermon()
            async let livestreamTask = YouTubeService.shared.fetchUpcomingLivestream()
            
            let (sermon, livestream) = await (try sermonTask, try livestreamTask)
            latestSermon = sermon
            upcomingLivestream = livestream
        } catch {
            errorMessage = "Unable to load content: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct VideoCardView: View {
    let video: YouTubeService.Video
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(8)
            
            Text(video.title)
                .font(.headline)
                .lineLimit(2)
            
            if video.isLiveStream {
                Text("Upcoming Livestream")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            Text(video.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
