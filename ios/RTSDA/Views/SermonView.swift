import SwiftUI
import WebKit

struct SermonView: View {
    @StateObject private var viewModel = SermonViewModel()
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var selectedVideoId: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading content...")
                            .font(.body)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.body)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    } else {
                        // Upcoming Livestream Section
                        if let livestream = viewModel.upcomingLivestream {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Upcoming Livestream")
                                    .font(.title)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                if selectedVideoId == livestream.id {
                                    YouTubeView(videoId: livestream.id)
                                        .frame(height: sizeCategory.isAccessibilityCategory ? 400 : 300)
                                        .cornerRadius(12)
                                } else {
                                    AsyncImage(url: URL(string: livestream.thumbnailURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .foregroundColor(.gray.opacity(0.3))
                                    }
                                    .frame(height: sizeCategory.isAccessibilityCategory ? 400 : 300)
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        selectedVideoId = livestream.id
                                    }
                                    .accessibilityLabel("Livestream thumbnail")
                                    .accessibilityAddTraits(.isButton)
                                }
                                
                                Text(livestream.title)
                                    .font(.headline)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                                    .padding(.horizontal)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical)
                        }
                        
                        // Latest Sermon Section
                        if let video = viewModel.latestVideo {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Latest Sermon")
                                    .font(.title)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                
                                if selectedVideoId == video.id {
                                    YouTubeView(videoId: video.id)
                                        .frame(height: sizeCategory.isAccessibilityCategory ? 400 : 300)
                                        .cornerRadius(12)
                                } else {
                                    AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .foregroundColor(.gray.opacity(0.3))
                                    }
                                    .frame(height: sizeCategory.isAccessibilityCategory ? 400 : 300)
                                    .cornerRadius(12)
                                    .onTapGesture {
                                        selectedVideoId = video.id
                                    }
                                    .accessibilityLabel("Sermon thumbnail")
                                    .accessibilityAddTraits(.isButton)
                                }
                                
                                Text(video.title)
                                    .font(.headline)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                                    .padding(.horizontal)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text(video.description)
                                    .font(.body)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                                    .padding(.horizontal)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical)
                        }
                        
                        // More Videos Button
                        Link(destination: URL(string: viewModel.channelURL)!) {
                            HStack {
                                Image(systemName: "play.tv")
                                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                                Text("Watch More on YouTube")
                                    .font(.body)
                                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .accessibilityLabel("Open YouTube channel")
                    }
                }
            }
            .refreshable {
                await viewModel.fetchContent()
            }
            .navigationTitle("Sermons")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchContent()
            }
        }
    }
    
    private let channelURL = "https://www.youtube.com/@RockvilleTollandSDAChurch"
}

@MainActor
class SermonViewModel: ObservableObject {
    @Published var latestVideo: YouTubeService.Video?
    @Published var upcomingLivestream: YouTubeService.Video?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var channelURL = "https://www.youtube.com/@RockvilleTollandSDAChurch"
    
    private let service = YouTubeService.shared
    private var task: Task<Void, Never>?
    
    deinit {
        task?.cancel()
    }
    
    func fetchContent() async {
        guard !isLoading else { return }
        
        task?.cancel()
        isLoading = true
        errorMessage = nil
        
        task = Task {
            do {
                async let sermon = service.fetchLatestSermon()
                async let livestream = service.fetchUpcomingLivestream()
                
                let (sermonResult, livestreamResult) = await (try sermon, try livestream)
                
                if !Task.isCancelled {
                    self.latestVideo = sermonResult
                    self.upcomingLivestream = livestreamResult
                    self.errorMessage = nil
                }
            } catch {
                if !Task.isCancelled {
                    print("Error fetching content: \(error.localizedDescription)")
                    errorMessage = error.localizedDescription
                    
                    // If we have cached content, keep showing it
                    if latestVideo == nil {
                        do {
                            // Try one more time with cached content
                            latestVideo = try await service.fetchLatestSermon()
                        } catch {
                            print("Failed to fetch cached content: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
}

#Preview {
    SermonView()
}