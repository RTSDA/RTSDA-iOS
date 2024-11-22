import Foundation
import FirebaseFirestore

@MainActor
class BulletinViewModel: ObservableObject {
    @Published var bulletins: [Bulletin] = [] // Assuming you have a Bulletin model
    private let db = Firestore.firestore()
    
    func fetchBulletins() async {
        do {
            let snapshot = try await db.collection("bulletins")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            bulletins = snapshot.documents.compactMap { document -> Bulletin? in
                let data = document.data()
                
                guard let title = data["title"] as? String,
                      let content = data["content"] as? String,
                      let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                    return nil
                }
                
                return Bulletin(
                    id: document.documentID,
                    title: title,
                    content: content,
                    timestamp: timestamp
                )
            }
        } catch {
            print("Error fetching bulletins: \(error)")
        }
    }
} 