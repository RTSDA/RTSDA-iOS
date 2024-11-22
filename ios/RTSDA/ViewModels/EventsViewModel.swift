import Foundation
import FirebaseFirestore
import Combine

enum EventsError: LocalizedError {
    case fetchFailed(String)
    case addFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Failed to fetch events: \(message)"
        case .addFailed(let message):
            return "Failed to add event: \(message)"
        case .updateFailed(let message):
            return "Failed to update event: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete event: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var error: EventsError?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        setupEventsListener()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    private func setupEventsListener() {
        isLoading = true
        error = nil
        
        listenerRegistration = db.collection("events")
            .whereField("isPublished", isEqualTo: true)
            .order(by: "startDate")
            .order(by: FieldPath.documentID())
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = .fetchFailed(error.localizedDescription)
                    self.isLoading = false
                    return
                }
                
                do {
                    self.events = try querySnapshot?.documents
                        .compactMap { document -> Event? in
                            do {
                                if let event = try Event.fromDocument(document) {
                                    // Double check isPublished in case of race conditions
                                    return event.isPublished ? event : nil
                                }
                                return nil
                            } catch {
                                print("Error parsing event document: \(error)")
                                return nil
                            }
                        }
                        .sorted { $0.startDate < $1.startDate }
                        ?? []
                    self.isLoading = false
                } catch {
                    self.error = .fetchFailed("Failed to parse events: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
    }
    
    func refresh() {
        listenerRegistration?.remove()
        setupEventsListener()
    }
    
    func addEvent(_ event: Event) async {
        isLoading = true
        error = nil
        
        do {
            _ = try await db.collection("events")
                .addDocument(data: event.toDocument())
            
            isLoading = false
        } catch {
            self.error = .addFailed(error.localizedDescription)
            isLoading = false
        }
    }
    
    func updateEvent(_ event: Event) async {
        isLoading = true
        error = nil
        
        do {
            try await db.collection("events")
                .document(event.id)
                .setData(event.toDocument(), merge: true)
            
            isLoading = false
        } catch {
            self.error = .updateFailed(error.localizedDescription)
            isLoading = false
        }
    }
    
    func deleteEvent(_ event: Event) async {
        isLoading = true
        error = nil
        
        do {
            try await db.collection("events")
                .document(event.id)
                .delete()
            
            isLoading = false
        } catch {
            self.error = .deleteFailed(error.localizedDescription)
            isLoading = false
        }
    }
}