import Foundation
import FirebaseFirestore
import EventKit

// MARK: - Recurrence Type
enum RecurrenceType: String, Codable, CaseIterable {
    case none = "NONE"
    case daily = "DAILY"
    case weekly = "WEEKLY"
    case biweekly = "BIWEEKLY"
    case monthly = "MONTHLY"
    case firstTuesday = "FIRST_TUESDAY"
    
    var displayString: String {
        switch self {
        case .none:
            return "One-time"
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Bi-weekly"
        case .monthly:
            return "Monthly"
        case .firstTuesday:
            return "First Tuesday"
        }
    }
}

// MARK: - Event
struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date?
    let location: String
    let locationUrl: String?
    let recurrenceType: RecurrenceType
    let parentEventId: String?
    let createdAt: Date?
    let updatedAt: Date?
    let createdBy: String?
    let updatedBy: String?
    let isPublished: Bool
    let isDeleted: Bool
    
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        startDate: Date,
        endDate: Date? = nil,
        location: String,
        locationUrl: String? = nil,
        recurrenceType: RecurrenceType = .none,
        parentEventId: String? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        createdBy: String? = nil,
        updatedBy: String? = nil,
        isPublished: Bool = false,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.locationUrl = locationUrl
        self.recurrenceType = recurrenceType
        self.parentEventId = parentEventId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
        self.updatedBy = updatedBy
        self.isPublished = isPublished
        self.isDeleted = isDeleted
    }
    
    func nextOccurrence() -> Event? {
        guard recurrenceType != .none else { return nil }
        
        let calendar = Calendar.current
        var nextStart = startDate
        let now = Date()
        
        // Keep incrementing until we find a future date
        while nextStart <= now {
            switch recurrenceType {
            case .none:
                return nil
            case .daily:
                nextStart = calendar.date(byAdding: .day, value: 1, to: nextStart) ?? nextStart
            case .weekly:
                nextStart = calendar.date(byAdding: .weekOfYear, value: 1, to: nextStart) ?? nextStart
            case .biweekly:
                nextStart = calendar.date(byAdding: .weekOfYear, value: 2, to: nextStart) ?? nextStart
            case .monthly:
                nextStart = calendar.date(byAdding: .month, value: 1, to: nextStart) ?? nextStart
            case .firstTuesday:
                nextStart = calendar.date(byAdding: .day, value: 1, to: nextStart) ?? nextStart
                while nextStart.weekday != 3 {
                    nextStart = calendar.date(byAdding: .day, value: 1, to: nextStart) ?? nextStart
                }
            }
        }
        
        // Calculate the next end date by adding the same duration as the original event
        var nextEnd: Date? = nil
        if let endDate = endDate {
            let duration = endDate.timeIntervalSince(startDate)
            nextEnd = nextStart.addingTimeInterval(duration)
        }
        
        return Event(
            id: id,
            title: title,
            description: description,
            startDate: nextStart,
            endDate: nextEnd,
            location: location,
            locationUrl: locationUrl,
            recurrenceType: recurrenceType,
            parentEventId: parentEventId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: createdBy,
            updatedBy: updatedBy,
            isPublished: isPublished,
            isDeleted: isDeleted
        )
    }
    
    func addToCalendar() async throws -> Bool {
        let eventStore = EKEventStore()
        
        // Check current authorization status
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            // Request access
            let granted = if #available(iOS 17.0, *) {
                try await eventStore.requestFullAccessToEvents()
            } else {
                try await eventStore.requestAccess(to: .event)
            }
            
            if !granted {
                throw EventError.calendarAccessDenied
            }
            
        case .denied, .restricted:
            throw EventError.calendarAccessDenied
            
        case .authorized, .fullAccess:
            break
            
        @unknown default:
            break
        }
        
        // Create and save the event
        do {
            let ekEvent = EKEvent(eventStore: eventStore)
            ekEvent.title = title
            ekEvent.notes = description
            ekEvent.startDate = startDate
            ekEvent.endDate = endDate ?? startDate.addingTimeInterval(3600)
            ekEvent.location = location
            
            // Set recurrence rule if needed
            if recurrenceType != .none {
                let recurrenceRule: EKRecurrenceRule?
                
                switch recurrenceType {
                case .none:
                    recurrenceRule = nil
                case .daily:
                    recurrenceRule = EKRecurrenceRule(
                        recurrenceWith: .daily,
                        interval: 1,
                        end: nil)
                case .weekly:
                    recurrenceRule = EKRecurrenceRule(
                        recurrenceWith: .weekly,
                        interval: 1,
                        end: nil)
                case .biweekly:
                    recurrenceRule = EKRecurrenceRule(
                        recurrenceWith: .weekly,
                        interval: 2,
                        end: nil)
                case .monthly:
                    recurrenceRule = EKRecurrenceRule(
                        recurrenceWith: .monthly,
                        interval: 1,
                        end: nil)
                case .firstTuesday:
                    recurrenceRule = EKRecurrenceRule(
                        recurrenceWith: .monthly,
                        interval: 1,
                        daysOfTheWeek: [EKRecurrenceDayOfWeek(.tuesday)],
                        daysOfTheMonth: nil,
                        monthsOfTheYear: nil,
                        weeksOfTheYear: nil,
                        daysOfTheYear: nil,
                        setPositions: [1],
                        end: nil)
                }
                
                if let rule = recurrenceRule {
                    ekEvent.addRecurrenceRule(rule)
                }
            }
            
            ekEvent.calendar = eventStore.defaultCalendarForNewEvents
            try eventStore.save(ekEvent, span: .thisEvent)
            return true
        } catch {
            throw EventError.calendarError(error.localizedDescription)
        }
    }
}

extension Date {
    var weekday: Int {
        return Calendar.current.component(.weekday, from: self)
    }
}

// MARK: - Firestore Conversion
extension Event {
    static func fromDocument(_ document: DocumentSnapshot) throws -> Event? {
        guard let data = document.data() else { return nil }
        
        let startDate: Date
        if let timestamp = data["startDate"] as? Timestamp {
            startDate = timestamp.dateValue()
        } else if let seconds = data["startDate"] as? Double {
            startDate = Date(timeIntervalSince1970: seconds)
        } else if let seconds = data["startDate"] as? Int64 {
            startDate = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            throw EventError.invalidStartDate
        }
        
        var endDate: Date?
        if let timestamp = data["endDate"] as? Timestamp {
            endDate = timestamp.dateValue()
        } else if let seconds = data["endDate"] as? Double {
            endDate = Date(timeIntervalSince1970: seconds)
        } else if let seconds = data["endDate"] as? Int64 {
            endDate = Date(timeIntervalSince1970: TimeInterval(seconds))
        }
        
        let createdAt: Date?
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let seconds = data["createdAt"] as? Double {
            createdAt = Date(timeIntervalSince1970: seconds)
        } else if let seconds = data["createdAt"] as? Int64 {
            createdAt = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            createdAt = nil
        }
        
        let updatedAt: Date?
        if let timestamp = data["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else if let seconds = data["updatedAt"] as? Double {
            updatedAt = Date(timeIntervalSince1970: seconds)
        } else if let seconds = data["updatedAt"] as? Int64 {
            updatedAt = Date(timeIntervalSince1970: TimeInterval(seconds))
        } else {
            updatedAt = nil
        }
        
        return Event(
            id: document.documentID,
            title: data["title"] as? String ?? "",
            description: data["description"] as? String ?? "",
            startDate: startDate,
            endDate: endDate,
            location: data["location"] as? String ?? "",
            locationUrl: data["locationUrl"] as? String,
            recurrenceType: RecurrenceType(rawValue: data["recurrenceType"] as? String ?? "") ?? .none,
            parentEventId: data["parentEventId"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: data["createdBy"] as? String,
            updatedBy: data["updatedBy"] as? String,
            isPublished: data["isPublished"] as? Bool ?? false,
            isDeleted: data["isDeleted"] as? Bool ?? false
        )
    }
    
    func toDocument() -> [String: Any] {
        var doc: [String: Any] = [
            "title": title,
            "description": description,
            "startDate": Timestamp(date: startDate),
            "location": location,
            "recurrenceType": recurrenceType.rawValue,
            "isPublished": isPublished,
            "isDeleted": isDeleted
        ]
        
        if let endDate = endDate {
            doc["endDate"] = Timestamp(date: endDate)
        }
        if let locationUrl = locationUrl {
            doc["locationUrl"] = locationUrl
        }
        if let parentEventId = parentEventId {
            doc["parentEventId"] = parentEventId
        }
        if let createdAt = createdAt {
            doc["createdAt"] = Timestamp(date: createdAt)
        }
        if let updatedAt = updatedAt {
            doc["updatedAt"] = Timestamp(date: updatedAt)
        }
        if let createdBy = createdBy {
            doc["createdBy"] = createdBy
        }
        if let updatedBy = updatedBy {
            doc["updatedBy"] = updatedBy
        }
        
        return doc
    }
}

// MARK: - Event Error
enum EventError: LocalizedError {
    case invalidStartDate
    case calendarAccessDenied
    case calendarError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidStartDate:
            return "Invalid start date format"
        case .calendarAccessDenied:
            return "Calendar access is required to add events. Please enable it in Settings."
        case .calendarError(let message):
            return "Calendar error: \(message)"
        }
    }
}
