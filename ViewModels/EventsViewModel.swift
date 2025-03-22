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
            // Get current time
            let now = Date()
            print("🕒 Current time: \(now)")
            
            // Show all events that haven't ended yet
            let allEvents = try await pocketBaseService.fetchEvents()
            print("📋 Total events from PocketBase: \(allEvents.count)")
            
            for event in allEvents {
                print("🗓️ Event: \(event.title)")
                print("   Start: \(event.startDate)")
                print("   End: \(event.endDate)")
                print("   Category: \(event.category.rawValue)")
                print("   Recurring: \(event.reoccuring.rawValue)")
                print("   Published: \(event.isPublished)")
            }
            
            events = allEvents
                .filter { event in
                    // Subtract 5 hours from the current time to match the UTC offset
                    // Because PocketBase stores "5 AM Eastern" as "5 AM UTC"
                    // So when it's actually "10 AM UTC", PocketBase shows "5 AM UTC"
                    let utcOffset = -5 * 60 * 60 // -5 hours in seconds
                    let adjustedNow = now.addingTimeInterval(TimeInterval(utcOffset))
                    let willShow = event.endDate > adjustedNow
                    print("   Compare - Event: \(event.title)")
                    print("   End time: \(event.endDate)")
                    print("   Current time (adjusted to UTC): \(adjustedNow)")
                    print("   Will show: \(willShow)")
                    return willShow
                }
                .sorted { $0.startDate < $1.startDate }
            
            print("✅ Filtered events count: \(events.count)")
        } catch {
            print("❌ Error loading events: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
}
