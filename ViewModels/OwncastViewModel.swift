import Foundation

@MainActor
class OwncastViewModel: ObservableObject {
    @Published var streamUrl: URL?
    @Published var isLoading = false
    private let owncastService = OwnCastService.shared
    private let baseUrl = "https://stream.rockvilletollandsda.church"
    
    func checkStreamStatus() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let status = try await owncastService.getStreamStatus()
            if status.online {
                streamUrl = URL(string: "\(baseUrl)/hls/stream.m3u8")
            } else {
                streamUrl = nil
            }
        } catch {
            print("Failed to check stream status:", error)
            streamUrl = nil
        }
    }
} 