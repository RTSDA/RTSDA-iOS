import Foundation
import FirebaseFirestore
import Combine

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        setupEventsListener()
    }
    
    private func setupEventsListener() {
        listenerRegistration = db.collection("events")
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error
                    print("Error listening for events: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents in snapshot")
                    return
                }
                
                self.events = documents.compactMap { document in
                    CalendarEvent(document: document)
                }
            }
    }
    
    func fetchEvents() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("events")
                .order(by: "startDate", descending: false)
                .getDocuments()
            
            events = snapshot.documents.compactMap { document in
                CalendarEvent(document: document)
            }
        } catch {
            self.error = error
            print("Error fetching events: \(error)")
        }
    }
    
    func addEvent(_ event: CalendarEvent) async throws {
        let ref = event.id.isEmpty ? db.collection("events").document() : db.collection("events").document(event.id)
        let eventWithId = event.id.isEmpty ? CalendarEvent(id: ref.documentID,
                                                         title: event.title,
                                                         description: event.description,
                                                         location: event.location,
                                                         startDate: event.startDate,
                                                         endDate: event.endDate,
                                                         recurrenceType: event.recurrenceType) : event
        
        try await ref.setData(eventWithId.toFirestore)
    }
    
    func updateEvent(_ event: CalendarEvent) async throws {
        try await db.collection("events").document(event.id).setData(event.toFirestore)
    }
    
    func deleteEvent(_ event: CalendarEvent) async throws {
        try await db.collection("events").document(event.id).delete()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
}