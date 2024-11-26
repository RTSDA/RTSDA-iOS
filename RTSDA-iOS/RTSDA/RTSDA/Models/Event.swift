import Foundation
import FirebaseFirestore
import MapKit
import EventKit

enum RecurrenceType: String, Codable {
    case none = "none"
    case recurring = "recurring"
    case biweekly = "BIWEEKLY"
    case firstTuesday = "FIRST_TUESDAY"
    
    var displayName: String {
        switch self {
        case .none: return ""
        case .recurring: return "Recurring Event"
        case .biweekly: return "Bi-Weekly"
        case .firstTuesday: return "First Tuesday"
        }
    }
    
    var calendarRecurrenceRule: EKRecurrenceRule? {
        let calendar = Calendar.current
        switch self {
        case .none:
            return nil
        case .recurring:
            return EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 1,
                end: nil
            )
        case .biweekly:
            return EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: 2,
                end: nil
            )
        case .firstTuesday:
            // Create a rule for the first Tuesday of every month
            let tuesday = EKWeekday.tuesday
            return EKRecurrenceRule(
                recurrenceWith: .monthly,
                interval: 1,
                daysOfTheWeek: [EKRecurrenceDayOfWeek(tuesday)],
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: [1], // First occurrence
                end: nil
            )
        }
    }
}

struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let locationURL: String?
    let registrationRequired: Bool
    let registrationURL: String?
    let recurrenceType: RecurrenceType
    let imageURL: String?
    let isPublished: Bool
    let isDeleted: Bool
    
    var formattedDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        let startDateString = dateFormatter.string(from: startDate)
        let endTimeFormatter = DateFormatter()
        endTimeFormatter.timeStyle = .short
        let endTimeString = endTimeFormatter.string(from: endDate)
        
        return "\(startDateString) • \(endTimeString)"
    }
    
    var hasLocation: Bool {
        return (location != nil && !location!.isEmpty)
    }
    
    var hasLocationUrl: Bool {
        return (locationURL != nil && !locationURL!.isEmpty)
    }
    
    var canOpenInMaps: Bool {
        if let locationURL = locationURL, !locationURL.isEmpty,
           let url = URL(string: locationURL) {
            return true
        }
        if let location = location, !location.isEmpty {
            return true
        }
        return false
    }
    
    var displayLocation: String {
        if let location = location {
            return location
        }
        if let locationURL = locationURL {
            // Try to extract a readable location from the URL
            if let url = URL(string: locationURL) {
                let components = url.pathComponents
                if components.count > 1 {
                    return components.last?.replacingOccurrences(of: "+", with: " ") ?? locationURL
                }
            }
            return locationURL
        }
        return "No location specified"
    }
    
    func openInMaps() {
        Task {
            let permissionsManager = PermissionsManager.shared
            
            // We don't strictly need location permission to open maps,
            // but we'll request it for better functionality
            _ = try? await permissionsManager.requestLocationAccess()
            
            if let locationURL = locationURL, let url = URL(string: locationURL) {
                _ = await UIApplication.shared.open(url)
            } else if let location = location, !location.isEmpty {
                let searchQuery = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
                if let mapsUrl = URL(string: "http://maps.apple.com/?q=\(searchQuery)") {
                    _ = await UIApplication.shared.open(mapsUrl)
                }
            }
        }
    }
    
    func addToCalendar(completion: @escaping (Bool, Error?) -> Void) {
        Task {
            let permissionsManager = PermissionsManager.shared
            let accessGranted = await permissionsManager.requestCalendarAccess()
            
            if !accessGranted {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "com.rtsda.calendar", code: 1, 
                        userInfo: [NSLocalizedDescriptionKey: "Calendar access is not available. You can enable it in Settings."]))
                }
                return
            }
            
            let eventStore = EKEventStore()
            let event = EKEvent(eventStore: eventStore)
            
            // Set basic event details
            event.title = self.title
            event.notes = self.description
            event.startDate = self.startDate
            event.endDate = self.endDate
            event.location = self.location ?? self.locationURL
            
            // Set recurrence rule if applicable
            if let rule = self.recurrenceType.calendarRecurrenceRule {
                event.recurrenceRules = [rule]
            }
            
            // Get the default calendar - this works with both full and limited access
            guard let calendar = eventStore.defaultCalendarForNewEvents else {
                DispatchQueue.main.async {
                    completion(false, NSError(domain: "com.rtsda.calendar", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Could not access default calendar."]))
                }
                return
            }
            
            event.calendar = calendar
            
            do {
                try eventStore.save(event, span: .thisEvent)
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                print("❌ Failed to save event: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, error)
                }
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startDate = "startDate"
        case endDate = "endDate"
        case location
        case locationURL = "locationUrl"
        case registrationRequired = "registration_required"
        case registrationURL = "registration_url"
        case recurrenceType = "recurrenceType"
        case imageURL = "imageUrl"
        case isPublished
        case isDeleted
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .startDate) {
            startDate = timestamp.dateValue()
        } else {
            startDate = try container.decode(Date.self, forKey: .startDate)
        }
        
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .endDate) {
            endDate = timestamp.dateValue()
        } else {
            endDate = try container.decode(Date.self, forKey: .endDate)
        }
        
        location = try container.decodeIfPresent(String.self, forKey: .location)
        locationURL = try container.decodeIfPresent(String.self, forKey: .locationURL)
        registrationRequired = try container.decode(Bool.self, forKey: .registrationRequired)
        registrationURL = try container.decodeIfPresent(String.self, forKey: .registrationURL)
        
        let recurrenceTypeString = try container.decode(String.self, forKey: .recurrenceType)
        recurrenceType = RecurrenceType(rawValue: recurrenceTypeString) ?? .none
        
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        isPublished = try container.decode(Bool.self, forKey: .isPublished)
        isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         startDate: Date,
         endDate: Date,
         location: String? = nil,
         locationURL: String? = nil,
         registrationRequired: Bool = false,
         registrationURL: String? = nil,
         recurrenceType: RecurrenceType = .none,
         imageURL: String? = nil,
         isPublished: Bool = true,
         isDeleted: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.locationURL = locationURL
        self.registrationRequired = registrationRequired
        self.registrationURL = registrationURL
        self.recurrenceType = recurrenceType
        self.imageURL = imageURL
        self.isPublished = isPublished
        self.isDeleted = isDeleted
    }
}

extension Event {
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        print("🔍 Parsing document: \(document.documentID)")
        print("🔍 Raw data: \(data)")
        
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let startTimestamp = data["startDate"] as? Timestamp,
              let endTimestamp = data["endDate"] as? Timestamp,
              let recurrenceTypeString = data["recurrenceType"] as? String else {
            print("❌ Missing required fields in document")
            return nil
        }
        
        self.id = document.documentID
        self.title = title
        self.description = description
        self.startDate = startTimestamp.dateValue()
        self.endDate = endTimestamp.dateValue()
        self.location = data["location"] as? String
        self.locationURL = data["locationUrl"] as? String
        self.registrationRequired = data["registration_required"] as? Bool ?? false
        self.registrationURL = data["registration_url"] as? String
        self.recurrenceType = RecurrenceType(rawValue: recurrenceTypeString) ?? .none
        self.imageURL = data["imageUrl"] as? String
        self.isPublished = data["isPublished"] as? Bool ?? false
        self.isDeleted = data["isDeleted"] as? Bool ?? false
    }
}
