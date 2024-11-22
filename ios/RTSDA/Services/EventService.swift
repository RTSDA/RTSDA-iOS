import Foundation
import FirebaseFirestore

@MainActor
class EventService: ObservableObject {
    private let db = Firestore.firestore()
    private let eventsCollection = "events"
    @Published private(set) var events: [Event] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var listener: ListenerRegistration?
    
    init() {
        setupListener()
        Task {
            await updateRecurringEvents()
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupListener() {
        isLoading = true
        error = nil
        
        listener = db.collection(eventsCollection)
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    return
                }
                
                let events = snapshot?.documents.compactMap { document in
                    try? Event.fromDocument(document)
                } ?? []
                
                Task { @MainActor in
                    self.events = events.sorted { $0.startDate < $1.startDate }
                    self.isLoading = false
                }
            }
    }
    
    func refresh() {
        listener?.remove()
        setupListener()
    }
    
    func updateRecurringEvents() async {
        do {
            isLoading = true
            defer { isLoading = false }
            
            print("Starting recurring events update...")
            
            let now = Date()
            
            // Get all recurring events
            let snapshot = try await db.collection(eventsCollection)
                .whereField("recurrenceType", isNotEqualTo: RecurrenceType.none.rawValue)
                .getDocuments()
            
            let recurringEvents = snapshot.documents.compactMap { document -> Event? in
                try? Event.fromDocument(document)
            }
            
            print("Found recurring events: \(recurringEvents.count)")
            
            for event in recurringEvents {
                // Only update if the event date has passed
                if event.startDate < now,
                   let nextEvent = event.nextOccurrence() {
                    // Update the event with the new date
                    try await db.collection(eventsCollection).document(event.id).setData([
                        "startDate": Timestamp(date: nextEvent.startDate),
                        "endDate": nextEvent.endDate.map { Timestamp(date: $0) }
                    ].compactMapValues { $0 }, merge: true)
                    print("Updated recurring event '\(event.title)' to next occurrence: \(nextEvent.startDate)")
                } else {
                    print("Skipping event '\(event.title)' - date has not passed yet: \(event.startDate)")
                }
            }
            
            print("Finished updating recurring events")
        } catch {
            print("Error updating recurring events: \(error)")
            self.error = error
        }
    }
    
    func addEvent(_ event: Event) async throws {
        isLoading = true
        error = nil
        
        do {
            let docRef = db.collection(eventsCollection).document()
            try await docRef.setData(event.toDocument())
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
        
        // If it's a recurring event, check if we need to update its date
        if event.recurrenceType != .none {
            await updateRecurringEvents()
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        isLoading = true
        error = nil
        
        do {
            try await db.collection(eventsCollection).document(event.id).setData(event.toDocument(), merge: true)
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
        
        // If it's a recurring event, check if we need to update its date
        if event.recurrenceType != .none {
            await updateRecurringEvents()
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        isLoading = true
        error = nil
        
        do {
            try await db.collection(eventsCollection).document(event.id).delete()
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
            throw error
        }
    }
}
