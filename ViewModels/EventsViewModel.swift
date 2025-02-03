import SwiftUI

@MainActor
class EventsViewModel: ObservableObject {
    @Published private(set) var events: [Event] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let pocketBaseService = PocketBaseService.shared
    
    func loadEvents() async {
        isLoading = true
        error = nil
        
        do {
            let now = Date()
            let calendar = Calendar.current
            let todayStart = calendar.startOfDay(for: now)
            
            // Keep events that either:
            // 1. Start in the future (after today), or
            // 2. Are today and haven't ended yet
            events = try await pocketBaseService.fetchEvents()
                .filter { event in
                    let eventStart = calendar.startOfDay(for: event.startDate)
                    if eventStart > todayStart {
                        return true  // Future event
                    } else if eventStart == todayStart {
                        return event.endDate > now  // Today's event that hasn't ended
                    }
                    return false
                }
                .sorted { $0.startDate < $1.startDate }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
