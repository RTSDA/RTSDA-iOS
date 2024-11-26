import Foundation
import FirebaseFirestore
import Combine

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    private let eventsCollectionName = "events"
    private let isAdminView: Bool
    
    init(isAdminView: Bool = false) {
        self.isAdminView = isAdminView
        print("📱 EventsViewModel initialized")
        Task {
            await loadEvents()
        }
    }
    
    func loadEvents() async {
        print("📅 Starting to load events...")
        isLoading = true
        error = nil
        
        do {
            let eventsRef: Query
            
            if isAdminView {
                // Admin view: Get all events, just order by date
                eventsRef = db.collection(eventsCollectionName)
                    .order(by: "startDate", descending: false)
            } else {
                // Regular user view: Only get published events
                eventsRef = db.collection(eventsCollectionName)
                    .whereField("isPublished", isEqualTo: true)
                    .whereField("startDate", isGreaterThanOrEqualTo: Timestamp(date: Date()))
                    .order(by: "startDate", descending: false)
            }
            
            let querySnapshot = try await eventsRef.getDocuments()
            
            print("\n📅 Raw Firestore Data:")
            print("Found \(querySnapshot.documents.count) documents")
            
            // Print complete raw data for each document
            for document in querySnapshot.documents {
                print("\n📄 Document ID: \(document.documentID)")
                let data = document.data()
                for (key, value) in data {
                    if let timestamp = value as? Timestamp {
                        print("  \(key): \(timestamp.dateValue())")
                    } else {
                        print("  \(key): \(value)")
                    }
                }
            }
            
            // Parse events, filtering out deleted ones in memory
            self.events = querySnapshot.documents.compactMap { document in
                let data = document.data()
                
                // Skip deleted events (unless in admin view)
                if !isAdminView {
                    guard (data["isDeleted"] as? Bool) != true else {
                        return nil
                    }
                }
                
                return Event(
                    id: document.documentID,
                    title: data["title"] as? String ?? "",
                    description: data["description"] as? String ?? "",
                    startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                    endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date(),
                    location: data["location"] as? String,
                    locationURL: data["locationUrl"] as? String,
                    recurrenceType: RecurrenceType(rawValue: data["recurrenceType"] as? String ?? "") ?? .none,
                    isPublished: data["isPublished"] as? Bool ?? true
                )
            }
            
            print("\n📅 Parsed \(self.events.count) events")
            print("Event Titles:")
            for event in self.events {
                print("- \(event.title)")
            }
            
        } catch {
            print("❌ Error loading events: \(error.localizedDescription)")
            self.error = error
        }
        
        isLoading = false
    }
    
    func addEvent(_ event: Event) async throws {
        let data: [String: Any] = [
            "title": event.title,
            "description": event.description,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "location": event.location as Any,
            "locationUrl": event.locationURL as Any,
            "recurrenceType": event.recurrenceType.rawValue,
            "isPublished": event.isPublished,
            "isDeleted": false,
            "createdAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection(eventsCollectionName).document(event.id).setData(data)
        await loadEvents()
    }
    
    func updateEvent(_ event: Event) async throws {
        let data: [String: Any] = [
            "title": event.title,
            "description": event.description,
            "startDate": Timestamp(date: event.startDate),
            "endDate": Timestamp(date: event.endDate),
            "location": event.location as Any,
            "locationUrl": event.locationURL as Any,
            "recurrenceType": event.recurrenceType.rawValue,
            "isPublished": event.isPublished,
            "updatedAt": Timestamp(date: Date())
        ]
        
        try await db.collection(eventsCollectionName).document(event.id).updateData(data)
        await loadEvents()
    }
    
    func deleteEvent(_ event: Event) async {
        do {
            try await db.collection(eventsCollectionName).document(event.id).delete()
            await loadEvents()
        } catch {
            print("Error deleting event: \(error)")
        }
    }
    
    func getEventPage(for title: String) -> EventPage {
        switch title.lowercased() {
        case "prayer meeting":
            return .prayerMeeting
        case "sabbath school":
            return .sabbathSchool
        case "divine service":
            return .divineService
        case "bible study":
            return .bibleStudy
        case "pathfinders":
            return .pathfinders
        case "adventurers":
            return .adventurers
        case "youth meeting":
            return .youthMeeting
        default:
            return .other
        }
    }
}

enum EventPage {
    case prayerMeeting
    case sabbathSchool
    case divineService
    case bibleStudy
    case pathfinders
    case adventurers
    case youthMeeting
    case other
    
    var title: String {
        switch self {
        case .prayerMeeting: return "Prayer Meeting"
        case .sabbathSchool: return "Sabbath School"
        case .divineService: return "Divine Service"
        case .bibleStudy: return "Bible Study"
        case .pathfinders: return "Pathfinders"
        case .adventurers: return "Adventurers"
        case .youthMeeting: return "Youth Meeting"
        case .other: return "Event"
        }
    }
    
    var icon: String {
        switch self {
        case .prayerMeeting: return "hands.sparkles.fill"
        case .sabbathSchool: return "book.fill"
        case .divineService: return "cross.fill"
        case .bibleStudy: return "text.book.closed.fill"
        case .pathfinders: return "figure.hiking"
        case .adventurers: return "star.fill"
        case .youthMeeting: return "person.2.fill"
        case .other: return "calendar"
        }
    }
}
