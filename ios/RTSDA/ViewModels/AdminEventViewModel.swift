import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AdminEventViewModel: ObservableObject {
    @Published private(set) var events: [Event] = []
    @Published var selectedEvent: Event?
    @Published private(set) var validationState = EventValidationState()
    @Published private(set) var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        setupEventsListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    func setupEventsListener() {
        isLoading = true
        self.error = nil
        
        listener = db.collection("events")
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error getting events: \(error)")
                    return
                }
                
                do {
                    self.events = try querySnapshot?.documents
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
                self.isLoading = false
            }
    }
    
    func validateEvent(_ event: Event) -> Bool {
        print("[AdminEventViewModel] Validating event: \(event.id)")
        validationState = EventValidationState(
            hasStartDate: true, // Date is non-optional in model
            hasEndDate: event.endDate != nil,
            hasTitle: !event.title.isEmpty,
            hasLocation: !event.location.isEmpty,
            isEndDateAfterStart: event.endDate.map { $0 > event.startDate } ?? false
        )
        print("[AdminEventViewModel] Validation state: \(validationState.isValid)")
        return validationState.isValid
    }
    
    func updateEventToEdit(_ event: Event?) {
        print("[AdminEventViewModel] Updating event to edit: \(event?.id ?? "nil")")
        selectedEvent = event
        if let event = event {
            _ = validateEvent(event)
        } else {
            validationState = EventValidationState()
        }
    }
    
    func loadEvent(eventId: String) async {
        isLoading = true
        self.error = nil
        
        do {
            let doc = try await db.collection("events").document(eventId).getDocument()
            if let event = try Event.fromDocument(doc) {
                selectedEvent = event
            }
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    func saveEvent(_ event: Event) async throws {
        print("[AdminEventViewModel] Attempting to save event: \(event.id)")
        guard validateEvent(event) else {
            print("[AdminEventViewModel] Event validation failed")
            throw ValidationError.invalidEvent
        }
        
        isLoading = true
        self.error = nil
        
        do {
            if event.id.isEmpty {
                print("[AdminEventViewModel] Creating new event")
                let docRef = db.collection("events").document()
                try await docRef.setData(event.toDocument())
                print("[AdminEventViewModel] New event created successfully")
            } else {
                print("[AdminEventViewModel] Updating existing event: \(event.id)")
                try await db.collection("events").document(event.id).setData(event.toDocument(), merge: true)
                print("[AdminEventViewModel] Event updated successfully")
            }
            isLoading = false
            selectedEvent = nil
        } catch let saveError {
            print("[AdminEventViewModel] Error saving event: \(saveError.localizedDescription)")
            self.error = saveError
            isLoading = false
            throw saveError
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        print("[AdminEventViewModel] Deleting event: \(event.id)")
        isLoading = true
        self.error = nil
        
        do {
            try await db.collection("events").document(event.id).delete()
            print("[AdminEventViewModel] Event deleted successfully")
            isLoading = false
        } catch let deleteError {
            print("[AdminEventViewModel] Error deleting event: \(deleteError.localizedDescription)")
            self.error = deleteError
            isLoading = false
            throw deleteError
        }
    }
    
    func publishEvent(_ event: Event) async throws {
        print("[AdminEventViewModel] Publishing event: \(event.id)")
        isLoading = true
        self.error = nil
        
        do {
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
            try await db.collection("events").document(event.id).setData(updatedEvent.toDocument(), merge: true)
            print("[AdminEventViewModel] Event published successfully")
            isLoading = false
        } catch let publishError {
            print("[AdminEventViewModel] Error publishing event: \(publishError.localizedDescription)")
            self.error = publishError
            isLoading = false
            throw publishError
        }
    }
    
    func unpublishEvent(_ event: Event) async throws {
        print("[AdminEventViewModel] Unpublishing event: \(event.id)")
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
        print("[AdminEventViewModel] Event unpublished successfully")
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
