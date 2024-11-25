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
    
    func loadEvents() async {
        print("📅 Starting to load events...")
        isLoading = true
        error = nil
        
        do {
            // Use the existing composite index (isPublished, startDate, __name__)
            let eventsRef = db.collection(eventsCollectionName)
                .whereField("isPublished", isEqualTo: true)
                .whereField("startDate", isGreaterThanOrEqualTo: Timestamp(date: Date()))
                .order(by: "startDate")
            
            print("📅 Querying Firestore collection: \(eventsCollectionName)")
            
            let querySnapshot = try await eventsRef.getDocuments()
            
            print("📅 Got response from Firestore")
            print("📅 Found \(querySnapshot.documents.count) documents")
            
            // Filter deleted events in memory since we don't have an index for it
            self.events = querySnapshot.documents.compactMap { document in
                guard let isDeleted = document.data()["isDeleted"] as? Bool,
                      !isDeleted else {
                    return nil
                }
                return Event(document: document)
            }
            
            print("📅 Parsed \(self.events.count) events after filtering deleted events")
        } catch {
            print("❌ Error loading events: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    init() {
        print("📱 EventsViewModel initialized")
        Task {
            await loadEvents()
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
