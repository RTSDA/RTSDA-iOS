import Foundation
import EventKit
import UIKit

struct Event: Identifiable, Codable {
    let id: String
    let title: String
    let description: String  // Original HTML description
    let startDate: Date
    let endDate: Date
    let location: String?
    let locationURL: String?
    let image: String?
    let thumbnail: String?
    let category: EventCategory
    let isFeatured: Bool
    let reoccuring: ReoccurringType
    let isPublished: Bool
    let created: Date
    let updated: Date
    
    enum EventCategory: String, Codable {
        case service = "Service"
        case social = "Social"
        case ministry = "Ministry"
        case other = "Other"
    }
    
    enum ReoccurringType: String, Codable {
        case none = ""  // For non-recurring events
        case daily = "DAILY"
        case weekly = "WEEKLY"
        case biweekly = "BIWEEKLY"
        case firstTuesday = "FIRST_TUESDAY"
        
        var calendarRecurrenceRule: EKRecurrenceRule? {
            switch self {
            case .none:
                return nil  // No recurrence for one-time events
            case .daily:
                return EKRecurrenceRule(
                    recurrenceWith: .daily,
                    interval: 1,
                    end: nil
                )
            case .weekly:
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
                let tuesday = EKWeekday.tuesday
                return EKRecurrenceRule(
                    recurrenceWith: .monthly,
                    interval: 1,
                    daysOfTheWeek: [EKRecurrenceDayOfWeek(tuesday)],
                    daysOfTheMonth: nil,
                    monthsOfTheYear: nil,
                    weeksOfTheYear: nil,
                    daysOfTheYear: nil,
                    setPositions: [1],
                    end: nil
                )
            }
        }
    }
    
    var formattedDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.timeZone = .gmt  // Use GMT to match database times exactly
        
        let startDateString = dateFormatter.string(from: startDate)
        let endTimeFormatter = DateFormatter()
        endTimeFormatter.timeStyle = .short
        endTimeFormatter.timeZone = .gmt  // Use GMT to match database times exactly
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
        return hasLocation
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
    
    var imageURL: URL? {
        guard let image = image else { return nil }
        return URL(string: "https://pocketbase.rockvilletollandsda.church/api/files/events/\(id)/\(image)")
    }
    
    var thumbnailURL: URL? {
        guard let thumbnail = thumbnail else { return nil }
        return URL(string: "https://pocketbase.rockvilletollandsda.church/api/files/events/\(id)/\(thumbnail)")
    }
    
    func callPhone() {
        if let phoneNumber = extractPhoneNumber() {
            let cleanNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
            if let url = URL(string: "tel://\(cleanNumber)") {
                UIApplication.shared.open(url)
            }
        }
    }
    
    func extractPhoneNumber() -> String? {
        let phonePattern = #"Phone:.*?(\+\d{1})?[\s-]?\(?(\d{3})\)?[-.\s]?(\d{3})[-.\s]?(\d{4})"#
        if let match = description.range(of: phonePattern, options: .regularExpression) {
            let phoneText = String(description[match])
            let numberPattern = #"(\+\d{1})?[\s-]?\(?(\d{3})\)?[-.\s]?(\d{3})[-.\s]?(\d{4})"#
            if let numberMatch = phoneText.range(of: numberPattern, options: .regularExpression) {
                return String(phoneText[numberMatch])
            }
        }
        return nil
    }
    
    var plainDescription: String {
        // First remove all table structures and divs
        var cleanedText = description.replacingOccurrences(of: "<table[^>]*>.*?</table>", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "<div[^>]*>", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "</div>", with: "\n", options: .regularExpression)
        
        // Replace other HTML tags
        cleanedText = cleanedText.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "<p>", with: "", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "</p>", with: "\n", options: .regularExpression)
        cleanedText = cleanedText.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        
        // Decode common HTML entities
        let htmlEntities = [
            "&nbsp;": " ",
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&#x27;": "'",
            "&#x2F;": "/",
            "&#39;": "'",
            "&#47;": "/",
            "&rsquo;": "'",
            "&mdash;": "—"
        ]
        
        for (entity, replacement) in htmlEntities {
            cleanedText = cleanedText.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Format phone numbers with better pattern matching
        let phonePattern = #"(?m)^Phone:.*?(\+\d{1})?[\s-]?\(?(\d{3})\)?[-.\s]?(\d{3})[-.\s]?(\d{4})"#
        cleanedText = cleanedText.replacingOccurrences(
            of: phonePattern,
            with: "📞 Phone: ($2) $3-$4",
            options: .regularExpression
        )
        
        // Clean up whitespace while preserving intentional line breaks
        let lines = cleanedText.components(separatedBy: .newlines)
        let nonEmptyLines = lines.map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return nonEmptyLines.joined(separator: "\n")
    }
    
    func openInMaps() async {
        let permissionsManager = await PermissionsManager.shared
        
        // We don't strictly need location permission to open maps,
        // but we'll request it for better functionality
        await permissionsManager.requestLocationAccess()
        
        if let locationURL = locationURL, let url = URL(string: locationURL) {
            await UIApplication.shared.open(url, options: [:])
        } else if let location = location, !location.isEmpty {
            let searchQuery = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location
            if let mapsUrl = URL(string: "http://maps.apple.com/?q=\(searchQuery)") {
                await UIApplication.shared.open(mapsUrl, options: [:])
            }
        }
    }
    
    func addToCalendar(completion: @escaping (Bool, Error?) -> Void) async {
        let permissionsManager = await PermissionsManager.shared
        let eventStore = EKEventStore()
        
        do {
            let accessGranted = await permissionsManager.requestCalendarAccess()
            
            if !accessGranted {
                await MainActor.run {
                    completion(false, NSError(domain: "com.rtsda.calendar", code: 1, 
                        userInfo: [NSLocalizedDescriptionKey: "Calendar access is not available. You can enable it in Settings."]))
                }
                return
            }
            
            let event = EKEvent(eventStore: eventStore)
            
            // Set basic event details
            event.title = self.title
            event.notes = self.plainDescription
            event.startDate = self.startDate
            event.endDate = self.endDate
            event.location = self.location ?? self.locationURL
            
            // Set recurrence rule if applicable
            if let rule = self.reoccuring.calendarRecurrenceRule {
                event.recurrenceRules = [rule]
            }
            
            // Get the default calendar
            guard let calendar = eventStore.defaultCalendarForNewEvents else {
                await MainActor.run {
                    completion(false, NSError(domain: "com.rtsda.calendar", code: 2,
                        userInfo: [NSLocalizedDescriptionKey: "Could not access default calendar."]))
                }
                return
            }
            
            event.calendar = calendar
            
            try eventStore.save(event, span: .thisEvent)
            await MainActor.run {
                completion(true, nil)
            }
        } catch {
            await MainActor.run {
                completion(false, error)
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startDate = "start_time"
        case endDate = "end_time"
        case location
        case locationURL = "location_url"
        case image
        case thumbnail
        case category
        case isFeatured = "is_featured"
        case reoccuring
        case isPublished = "is_published"
        case created
        case updated
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        
        // Try multiple date formats
        let startDateString = try container.decode(String.self, forKey: .startDate)
        let endDateString = try container.decode(String.self, forKey: .endDate)
        let createdString = try container.decode(String.self, forKey: .created)
        let updatedString = try container.decode(String.self, forKey: .updated)
        
        // Create formatters for different possible formats
        let formatters = [
            { () -> DateFormatter in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZ" // PocketBase format
                return formatter
            }(),
            { () -> ISO8601DateFormatter in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter
            }(),
            { () -> ISO8601DateFormatter in
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                return formatter
            }()
        ]
        
        // Function to try parsing date with multiple formatters
        func parseDate(_ dateString: String, field: String) throws -> Date {
            // Print the date string we're trying to parse
            print("🗓️ Trying to parse date: \(dateString) for field: \(field)")
            
            for formatter in formatters {
                if let date = (formatter as? ISO8601DateFormatter)?.date(from: dateString) ?? 
                             (formatter as? DateFormatter)?.date(from: dateString) {
                    print("✅ Successfully parsed date using \(type(of: formatter))")
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(
                forKey: CodingKeys(stringValue: field)!,
                in: container,
                debugDescription: "Date string '\(dateString)' does not match any expected format"
            )
        }
        
        // Parse all dates
        startDate = try parseDate(startDateString, field: "start_time")
        endDate = try parseDate(endDateString, field: "end_time")
        created = try parseDate(createdString, field: "created")
        updated = try parseDate(updatedString, field: "updated")
        
        // Decode remaining fields
        location = try container.decodeIfPresent(String.self, forKey: .location)
        locationURL = try container.decodeIfPresent(String.self, forKey: .locationURL)
        image = try container.decodeIfPresent(String.self, forKey: .image)
        thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
        category = try container.decode(EventCategory.self, forKey: .category)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        reoccuring = try container.decode(ReoccurringType.self, forKey: .reoccuring)
        isPublished = try container.decodeIfPresent(Bool.self, forKey: .isPublished) ?? true // Default to true if not present
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         startDate: Date,
         endDate: Date,
         location: String? = nil,
         locationURL: String? = nil,
         image: String? = nil,
         thumbnail: String? = nil,
         category: EventCategory,
         isFeatured: Bool = false,
         reoccuring: ReoccurringType,
         isPublished: Bool = true,
         created: Date = Date(),
         updated: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.locationURL = locationURL
        self.image = image
        self.thumbnail = thumbnail
        self.category = category
        self.isFeatured = isFeatured
        self.reoccuring = reoccuring
        self.isPublished = isPublished
        self.created = created
        self.updated = updated
    }
}

struct EventResponse: Codable {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let totalItems: Int
    let items: [Event]
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "perPage"
        case totalPages = "totalPages"
        case totalItems = "totalItems"
        case items
    }
}
