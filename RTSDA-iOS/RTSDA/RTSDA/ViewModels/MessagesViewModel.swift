import Foundation
import FirebaseFirestore
import YouTubePlayerKit

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var livestream: Message?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let youtubeService = YouTubeService.shared
    
    init() {
        Task {
            await loadContent()
        }
    }
    
    func loadContent() async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        
        do {
            // Fetch latest sermon and livestream concurrently
            async let sermonTask = youtubeService.fetchLatestSermon()
            async let livestreamTask = youtubeService.fetchUpcomingLivestream()
            
            // Wait for both tasks to complete
            let sermon = try? await sermonTask
            let upcomingStream = try? await livestreamTask
            
            // Clear previous content
            self.messages = []
            self.livestream = nil
            
            // Create message from sermon if available
            if let sermon = sermon {
                let sermonMessage = Message(
                    id: sermon.videoId,
                    title: sermon.title,
                    description: sermon.description,
                    speaker: "RTSDA Church", // Default speaker
                    videoUrl: "https://www.youtube.com/watch?v=\(sermon.videoId)",
                    thumbnailUrl: sermon.thumbnailUrl,
                    duration: sermon.duration,
                    isLiveStream: false,
                    isPublished: true,
                    isDeleted: false,
                    liveBroadcastStatus: sermon.liveBroadcastStatus
                )
                self.messages = [sermonMessage]
            }
            
            // Handle livestream if available
            if let upcomingStream = upcomingStream {
                self.livestream = Message(
                    id: upcomingStream.videoId,
                    title: upcomingStream.title,
                    description: upcomingStream.description,
                    speaker: "RTSDA Church", // Default speaker
                    videoUrl: "https://www.youtube.com/watch?v=\(upcomingStream.videoId)",
                    thumbnailUrl: upcomingStream.thumbnailUrl,
                    duration: upcomingStream.duration,
                    isLiveStream: true,
                    isPublished: true,
                    isDeleted: false,
                    liveBroadcastStatus: upcomingStream.liveBroadcastStatus
                )
            }
            
            // Only show error if both sermon and livestream failed
            if self.messages.isEmpty && self.livestream == nil {
                self.error = YouTubeService.YouTubeError.noVideosFound
            }
        } catch {
            self.error = error
            print("Error loading content: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func refreshContent() {
        Task {
            await loadContent()
        }
    }
}
