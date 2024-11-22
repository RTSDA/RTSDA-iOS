import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AdminEventViewModel: ObservableObject {
    @Published private(set) var uiState = AdminEventUiState()
    @Published var eventToEdit: Event?
    @Published private(set) var validationState = EventValidationState()
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        setupEventsListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    func setupEventsListener() {
        uiState.isLoading = true
        uiState.error = nil
        
        listener = db.collection("events")
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting events: \(error)")
                    return
                }
                
                do {
                    self.uiState.events = try querySnapshot?.documents
                        .compactMap { document -> Event? in
                            do {
                                return try Event.fromDocument(document)
                            } catch {
                                print("Error parsing event document: \(error)")
                                return nil
                            }
                        }
                        .sorted { $0.startDate < $1.startDate }
                        ?? []
                } catch {
                    print("Failed to parse events: \(error)")
                }
                self.uiState.isLoading = false
            }
    }
    
    func validateEvent(_ event: Event) -> Bool {
        validationState = EventValidationState(
            hasStartDate: true, // Date is non-optional in model
            hasEndDate: event.endDate != nil,
            hasTitle: !event.title.isEmpty,
            hasLocation: !event.location.isEmpty,
            isEndDateAfterStart: event.endDate.map { $0 > event.startDate } ?? false
        )
        return validationState.isValid
    }
    
    func updateEventToEdit(_ event: Event?) {
        eventToEdit = event
        if let event = event {
            _ = validateEvent(event)
        } else {
            validationState = EventValidationState()
        }
    }
    
    func loadEvent(eventId: String) async {
        uiState.isLoading = true
        uiState.error = nil
        
        do {
            let doc = try await db.collection("events").document(eventId).getDocument()
            if let event = try Event.fromDocument(doc) {
                eventToEdit = event
            }
            uiState.isLoading = false
        } catch {
            uiState.error = error.localizedDescription
            uiState.isLoading = false
        }
    }
    
    func saveEvent(_ event: Event) async throws {
        guard validateEvent(event) else {
            throw ValidationError.invalidEvent
        }
        
        uiState.isLoading = true
        uiState.error = nil
        
        do {
            if event.id.isEmpty {
                // New event
                let docRef = db.collection("events").document()
                try await docRef.setData(event.toDocument())
            } else {
                // Update existing event
                try await db.collection("events").document(event.id).setData(event.toDocument(), merge: true)
            }
            uiState.isLoading = false
            eventToEdit = nil
        } catch {
            uiState.error = error.localizedDescription
            uiState.isLoading = false
            throw error
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        uiState.isLoading = true
        uiState.error = nil
        
        do {
            try await db.collection("events").document(event.id).delete()
            uiState.isLoading = false
        } catch {
            uiState.error = error.localizedDescription
            uiState.isLoading = false
            throw error
        }
    }
    
    func publishEvent(_ event: Event) async throws {
        let updatedEvent = Event(
            id: event.id,
            title: event.title,
            description: event.description,
            startDate: event.startDate,
            endDate: event.endDate,
            location: event.location,
            locationUrl: event.locationUrl,
            recurrenceType: event.recurrenceType,
            parentEventId: event.parentEventId,
            createdAt: event.createdAt,
            updatedAt: Date(),
            createdBy: event.createdBy,
            updatedBy: Auth.auth().currentUser?.uid,
            isPublished: true,
            isDeleted: event.isDeleted
        )
        try await saveEvent(updatedEvent)
    }
    
    func unpublishEvent(_ event: Event) async throws {
        let updatedEvent = Event(
            id: event.id,
            title: event.title,
            description: event.description,
            startDate: event.startDate,
            endDate: event.endDate,
            location: event.location,
            locationUrl: event.locationUrl,
            recurrenceType: event.recurrenceType,
            parentEventId: event.parentEventId,
            createdAt: event.createdAt,
            updatedAt: Date(),
            createdBy: event.createdBy,
            updatedBy: Auth.auth().currentUser?.uid,
            isPublished: false,
            isDeleted: event.isDeleted
        )
        try await saveEvent(updatedEvent)
    }
}

enum ValidationError: LocalizedError {
    case invalidEvent
    
    var errorDescription: String? {
        switch self {
        case .invalidEvent:
            return "Please fill in all required fields"
        }
    }
}
