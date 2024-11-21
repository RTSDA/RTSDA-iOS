import Foundation
import FirebaseFirestore

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

struct Event: Identifiable, Codable {
    var id: String
    var title: String
    var subtitle: String?
    var description: String
    var date: Date
    var endDate: Date?
    var location: String
    var cost: String?
    var ageGroup: String?
    var recurrenceType: RecurrenceType
    var recurrenceEndDate: Date?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String? = nil,
        description: String,
        date: Date,
        endDate: Date? = nil,
        location: String = "",
        cost: String? = nil,
        ageGroup: String? = nil,
        recurrenceType: RecurrenceType = .none,
        recurrenceEndDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.date = date
        self.endDate = endDate
        self.location = location
        self.cost = cost
        self.ageGroup = ageGroup
        self.recurrenceType = recurrenceType
        self.recurrenceEndDate = recurrenceEndDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedEndDate: String? {
        guard let endDate = endDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: endDate)
    }
}