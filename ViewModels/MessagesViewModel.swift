import Foundation

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var filteredMessages: [Message] = []
    @Published var livestream: Message?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var availableYears: [String] = []
    @Published var availableMonths: [String] = []
    @Published var currentMediaType: JellyfinService.MediaType = .sermons
    
    private let jellyfinService = JellyfinService.shared
    private let owncastService = OwnCastService.shared
    private var currentTask: Task<Void, Never>?
    private var autoRefreshTask: Task<Void, Never>?
    
    init() {
        Task {
            await loadContent()
            startAutoRefresh()
        }
    }
    
    deinit {
        autoRefreshTask?.cancel()
    }
    
    private func startAutoRefresh() {
        // Cancel any existing auto-refresh task
        autoRefreshTask?.cancel()
        
        // Create new auto-refresh task
        autoRefreshTask = Task {
            while !Task.isCancelled {
                // Wait for 5 seconds
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
                
                // Check only livestream status
                let streamStatus = try? await owncastService.getStreamStatus()
                print("📺 Stream status: \(String(describing: streamStatus))")
                if let status = streamStatus, status.online {
                    print("📺 Stream is online! Creating livestream message")
                    self.livestream = owncastService.createLivestreamMessage(from: status)
                    print("📺 Livestream message created: \(String(describing: self.livestream))")
                } else {
                    print("📺 Stream is offline or status check failed")
                    self.livestream = nil
                }
            }
        }
    }
    
    func loadContent(mediaType: JellyfinService.MediaType = .sermons) async {
        currentMediaType = mediaType
        guard !isLoading else { return }
        isLoading = true
        error = nil
        
        // Cancel any existing task
        currentTask?.cancel()
        
        // Create a new task for content loading
        currentTask = Task {
            do {
                // Check OwnCast stream status
                if !Task.isCancelled {
                    let streamStatus = try? await owncastService.getStreamStatus()
                    print("📺 Initial stream status: \(String(describing: streamStatus))")
                    if let status = streamStatus, status.online {
                        print("📺 Stream is online on initial load! Creating livestream message")
                        self.livestream = owncastService.createLivestreamMessage(from: status)
                        print("📺 Initial livestream message created: \(String(describing: self.livestream))")
                    } else {
                        print("📺 Stream is offline on initial load")
                        self.livestream = nil
                    }
                }
                
                // Set media type and fetch content
                if !Task.isCancelled {
                    jellyfinService.setType(mediaType)
                    let sermons = try await jellyfinService.fetchSermons(type: mediaType == .sermons ? .sermon : .liveArchive)
                    
                    // Create simple date formatter
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    formatter.timeZone = TimeZone(identifier: "America/New_York")
                    
                    // Convert sermons to messages
                    self.messages = sermons.map { sermon in
                        Message(
                            id: sermon.id,
                            title: sermon.title,
                            description: sermon.description,
                            speaker: sermon.speaker,
                            videoUrl: sermon.videoUrl ?? "",
                            thumbnailUrl: sermon.thumbnail ?? "",
                            duration: 0,
                            isLiveStream: sermon.type == .liveArchive,
                            isPublished: true,
                            isDeleted: false,
                            liveBroadcastStatus: sermon.type == .liveArchive ? "live" : "none",
                            date: formatter.string(from: sermon.date)
                        )
                    }
                    .sorted { $0.date > $1.date }
                    
                    // Update available years and months
                    updateAvailableFilters()
                    
                    // Initialize filtered messages with all messages
                    self.filteredMessages = self.messages
                    
                    // Only show error if both content and livestream failed
                    if self.messages.isEmpty && self.livestream == nil {
                        self.error = JellyfinService.JellyfinError.noVideosFound
                    }
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    print("Error loading content: \(error.localizedDescription)")
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
        
        // Wait for the task to complete
        await currentTask?.value
    }
    
    func refreshContent() async {
        // Check stream status first
        let streamStatus = try? await owncastService.getStreamStatus()
        if let status = streamStatus, status.online {
            self.livestream = owncastService.createLivestreamMessage(from: status)
        } else {
            self.livestream = nil
        }
        
        // Then load the rest of the content
        await loadContent(mediaType: currentMediaType)
    }
    
    private func updateAvailableFilters() {
        // Get messages for current media type
        let currentMessages = messages.filter { message in
            message.isLiveStream == (currentMediaType == .livestreams)
        }
        
        // Create date formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Get unique years first
        var years = Set<String>()
        var monthsByYear: [String: Set<String>] = [:]
        
        for message in currentMessages {
            if let date = formatter.date(from: message.date) {
                let calendar = Calendar.current
                let year = String(calendar.component(.year, from: date))
                let month = String(format: "%02d", calendar.component(.month, from: date))
                
                years.insert(year)
                
                // Group months by year
                if monthsByYear[year] == nil {
                    monthsByYear[year] = Set<String>()
                }
                monthsByYear[year]?.insert(month)
            }
        }
        
        // Sort years descending (newest first)
        availableYears = Array(years).sorted(by: >)
        
        // Get months only for selected year (first year by default)
        if let selectedYear = availableYears.first,
           let monthsForYear = monthsByYear[selectedYear] {
            availableMonths = Array(monthsForYear).sorted()
        } else {
            availableMonths = []
        }
    }
    
    // Add a method to update months when year changes
    func updateMonthsForYear(_ year: String) {
        // Get messages for current media type and year
        let currentMessages = messages.filter { message in
            message.isLiveStream == (currentMediaType == .livestreams) &&
            message.date.hasPrefix(year)
        }
        
        // Create date formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Get months for the selected year
        var months = Set<String>()
        
        for message in currentMessages {
            if let date = formatter.date(from: message.date) {
                let calendar = Calendar.current
                let month = String(format: "%02d", calendar.component(.month, from: date))
                months.insert(month)
            }
        }
        
        // Sort months ascending (Jan to Dec)
        availableMonths = Array(months).sorted()
    }
    
    func filterContent(year: String? = nil, month: String? = nil) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // Filter by type first
        let typeFiltered = messages.filter { message in
            message.isLiveStream == (currentMediaType == .livestreams)
        }
        
        // Then filter by date components
        let dateFiltered = typeFiltered.filter { message in
            guard let date = formatter.date(from: message.date) else { return false }
            let calendar = Calendar.current
            
            if let year = year {
                let messageYear = String(calendar.component(.year, from: date))
                if messageYear != year { return false }
            }
            
            if let month = month {
                let messageMonth = String(format: "%02d", calendar.component(.month, from: date))
                if messageMonth != month { return false }
            }
            
            return true
        }
        
        // Sort by date, newest first
        filteredMessages = dateFiltered.sorted { $0.date > $1.date }
    }
}
