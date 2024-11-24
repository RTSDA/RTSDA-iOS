import Foundation
import FirebaseFirestore
import Network

@MainActor
class AdminEventViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var eventToEdit: CalendarEvent?
    @Published var error: Error?
    @Published var isLoading = false
    @Published var loadingStates: [String: Bool] = [:]
    @Published var isOffline = false
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var cache: [String: CalendarEvent] = [:]
    private let networkMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        setupNetworkMonitoring()
        setupEventsListener()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOffline = path.status != .satisfied
                if path.status == .satisfied {
                    // Reconnected - refresh data
                    await self?.fetchEvents()
                }
            }
        }
        networkMonitor.start(queue: queue)
    }
    
    private func setupEventsListener() {
        // Initial fetch to populate cache
        Task {
            await fetchEvents()
        }
        
        // Setup persistent listener with retry logic
        setupListener()
    }
    
    private func setupListener() {
        listenerRegistration?.remove() // Remove existing listener if any
        
        listenerRegistration = db.collection("events")
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    if (error as NSError).domain == FirestoreErrorDomain {
                        // Handle Firestore-specific errors
                        switch (error as NSError).code {
                        case FirestoreErrorCode.unavailable.rawValue:
                            // Network error - will retry automatically
                            self.isOffline = true
                            return
                        default:
                            self.error = error
                        }
                    } else {
                        self.error = error
                    }
                    print("Error listening for events: \(error)")
                    return
                }
                
                self.isOffline = false
                
                guard let snapshot = snapshot else {
                    print("No snapshot available")
                    return
                }
                
                // Process changes incrementally
                for change in snapshot.documentChanges {
                    let docId = change.document.documentID
                    
                    switch change.type {
                    case .added, .modified:
                        if let event = CalendarEvent(document: change.document) {
                            self.cache[docId] = event
                        }
                    case .removed:
                        self.cache.removeValue(forKey: docId)
                    }
                }
                
                // Update events array from cache
                self.events = Array(self.cache.values)
                    .sorted { $0.startDate < $1.startDate }
            }
    }
    
    func fetchEvents() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("events")
                .order(by: "startDate", descending: false)
                .getDocuments()
            
            // Update cache and events array
            cache = Dictionary(uniqueKeysWithValues: snapshot.documents.compactMap { doc -> (String, CalendarEvent)? in
                guard let event = CalendarEvent(document: doc) else { return nil }
                return (doc.documentID, event)
            })
            
            events = Array(cache.values)
                .sorted { $0.startDate < $1.startDate }
        } catch {
            if (error as NSError).domain == FirestoreErrorDomain {
                switch (error as NSError).code {
                case FirestoreErrorCode.unavailable.rawValue:
                    self.isOffline = true
                    // Use cached data if available
                    if !self.cache.isEmpty {
                        self.events = Array(self.cache.values)
                            .sorted { $0.startDate < $1.startDate }
                    }
                default:
                    self.error = error
                }
            } else {
                self.error = error
            }
            print("Error fetching events: \(error)")
        }
    }
    
    func getEvent(_ id: String) async -> CalendarEvent? {
        // Return cached event if available
        if let cachedEvent = cache[id] {
            return cachedEvent
        }
        
        // Set loading state for this event
        loadingStates[id] = true
        defer { loadingStates[id] = false }
        
        do {
            let doc = try await db.collection("events").document(id).getDocument()
            if let event = CalendarEvent(document: doc) {
                cache[id] = event
                return event
            }
        } catch {
            print("Error fetching single event: \(error)")
            // Return cached version if available during network error
            if (error as NSError).domain == FirestoreErrorDomain,
               (error as NSError).code == FirestoreErrorCode.unavailable.rawValue {
                return cache[id]
            }
        }
        return nil
    }
    
    func saveEvent(_ event: CalendarEvent) async {
        do {
            if event.id.isEmpty {
                try await addEvent(event)
            } else {
                try await updateEvent(event)
            }
            eventToEdit = nil
        } catch {
            if (error as NSError).domain == FirestoreErrorDomain,
               (error as NSError).code == FirestoreErrorCode.unavailable.rawValue {
                self.error = NSError(
                    domain: "AdminEventViewModel",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to save event. Please check your internet connection and try again."]
                )
            } else {
                self.error = error
            }
            print("Error saving event: \(error)")
        }
    }
    
    func deleteEvent(_ event: CalendarEvent) async {
        do {
            try await db.collection("events").document(event.id).delete()
            // Remove from cache immediately
            cache.removeValue(forKey: event.id)
            events = Array(cache.values)
                .sorted { $0.startDate < $1.startDate }
        } catch {
            if (error as NSError).domain == FirestoreErrorDomain,
               (error as NSError).code == FirestoreErrorCode.unavailable.rawValue {
                self.error = NSError(
                    domain: "AdminEventViewModel",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to delete event. Please check your internet connection and try again."]
                )
            } else {
                self.error = error
            }
            print("Error deleting event: \(error)")
        }
    }
    
    private func addEvent(_ event: CalendarEvent) async throws {
        let ref = db.collection("events").document()
        let eventWithId = CalendarEvent(
            id: ref.documentID,
            title: event.title,
            description: event.description,
            location: event.location,
            startDate: event.startDate,
            endDate: event.endDate,
            recurrenceType: event.recurrenceType
        )
        try await ref.setData(eventWithId.toFirestore)
        // Add to cache immediately
        cache[ref.documentID] = eventWithId
        events = Array(cache.values)
            .sorted { $0.startDate < $1.startDate }
    }
    
    private func updateEvent(_ event: CalendarEvent) async throws {
        try await db.collection("events").document(event.id).setData(event.toFirestore)
        // Update cache immediately
        cache[event.id] = event
        events = Array(cache.values)
            .sorted { $0.startDate < $1.startDate }
    }
    
    deinit {
        listenerRegistration?.remove()
        networkMonitor.cancel()
    }
}