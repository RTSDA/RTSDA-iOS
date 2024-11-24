import Foundation
import FirebaseFirestore

@MainActor
class EventService: ObservableObject {
    private let db = Firestore.firestore()
    @Published private(set) var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var listener: ListenerRegistration?
    
    init() {
        setupListener()
        Task {
            await syncRecurringEvents()
        }
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupListener() {
        listener = db.collection("events")
            .order(by: "startDate", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.error = error
                    return
                }
                
                let events = snapshot?.documents.compactMap { document -> CalendarEvent? in
                    CalendarEvent(document: document)
                } ?? []
                
                Task { @MainActor in
                    self?.events = events.sorted { $0.startDate < $1.startDate }
                }
            }
    }
    
    func syncRecurringEvents() async {
        do {
            isLoading = true
            defer { isLoading = false }
            
            let now = Date()
            let sixMonthsFromNow = Calendar.current.date(byAdding: .month, value: 6, to: now) ?? now
            
            // Get all recurring events
            let snapshot = try await db.collection("events")
                .whereField("recurrenceType", isNotEqualTo: RecurrenceType.none.rawValue)
                .getDocuments()
            
            let recurringEvents = snapshot.documents.compactMap { CalendarEvent(document: $0) }
            
            for baseEvent in recurringEvents {
                // Delete old instances
                let oldInstancesSnapshot = try await db.collection("events")
                    .whereField("parentEventId", isEqualTo: baseEvent.id)
                    .whereField("startDate", isLessThan: now.timeIntervalSince1970)
                    .getDocuments()
                
                for document in oldInstancesSnapshot.documents {
                    try await document.reference.delete()
                }
                
                // Generate future instances
                var currentDate = max(now, baseEvent.startDateTime)
                while currentDate < sixMonthsFromNow {
                    if let nextDate = calculateNextDate(
                        from: currentDate,
                        recurrenceType: baseEvent.recurrenceType
                    ) {
                        // Check if instance already exists
                        let existingSnapshot = try await db.collection("events")
                            .whereField("parentEventId", isEqualTo: baseEvent.id)
                            .whereField("startDate", isEqualTo: nextDate.timeIntervalSince1970)
                            .getDocuments()
                        
                        if existingSnapshot.documents.isEmpty {
                            // Create new instance
                            var instanceData = baseEvent.toFirestore
                            instanceData["parentEventId"] = baseEvent.id
                            instanceData["startDate"] = nextDate.timeIntervalSince1970
                            instanceData["endDate"] = nextDate.timeIntervalSince1970 + (baseEvent.endDateTime.timeIntervalSince(baseEvent.startDateTime))
                            instanceData["recurrenceType"] = RecurrenceType.none.rawValue
                            
                            let docRef = db.collection("events").document()
                            try await docRef.setData(instanceData)
                        }
                        
                        currentDate = nextDate
                    } else {
                        break
                    }
                }
            }
        } catch {
            self.error = error
        }
    }
    
    // MARK: - CRUD Operations
    
    func addEvent(_ event: CalendarEvent) async throws {
        let docRef = db.collection("events").document()
        var eventData = event.toFirestore
        
        // For new events, ensure we're using the current timestamp
        if event.id.isEmpty {
            let now = Date()
            if event.startDateTime < now {
                eventData["startDate"] = now.timeIntervalSince1970
                eventData["endDate"] = now.addingTimeInterval(3600).timeIntervalSince1970 // 1 hour default
            }
        }
        
        try await docRef.setData(eventData)
        
        // If it's a recurring event, generate future instances
        if event.recurrenceType != .none {
            await syncRecurringEvents()
        }
    }
    
    func updateEvent(_ event: CalendarEvent) async throws {
        let docRef = db.collection("events").document(event.id)
        try await docRef.setData(event.toFirestore)
        
        // If it's a recurring event, update future instances
        if event.recurrenceType != .none {
            await syncRecurringEvents()
        }
    }
    
    func deleteEvent(_ event: CalendarEvent) async throws {
        // Delete the event
        try await db.collection("events").document(event.id).delete()
        
        // If this is a recurring event, delete all child instances
        let childInstancesSnapshot = try await db.collection("events")
            .whereField("parentEventId", isEqualTo: event.id)
            .getDocuments()
        
        for document in childInstancesSnapshot.documents {
            try await document.reference.delete()
        }
    }
    
    private func calculateNextDate(
        from date: Date,
        recurrenceType: RecurrenceType
    ) -> Date? {
        let calendar = Calendar.current
        var nextDate = date
        
        switch recurrenceType {
        case .none:
            return nil
            
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate) ?? nextDate
            
        case .biweekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: nextDate) ?? nextDate
            
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate) ?? nextDate
            
        case .firstTuesday:
            var components = calendar.dateComponents([.year, .month], from: nextDate)
            components.weekdayOrdinal = 1
            components.weekday = 3 // Tuesday
            components.hour = calendar.component(.hour, from: nextDate)
            components.minute = calendar.component(.minute, from: nextDate)
            
            if let firstTuesday = calendar.date(from: components),
               firstTuesday > nextDate {
                nextDate = firstTuesday
            } else {
                components.month = (components.month ?? 1) + 1
                nextDate = calendar.date(from: components) ?? nextDate
            }
        }
        
        return nextDate
    }
}
