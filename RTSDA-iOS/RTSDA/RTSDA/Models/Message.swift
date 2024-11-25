import Foundation
import FirebaseFirestore

struct Message: Identifiable {
    let id: String
    let title: String
    let description: String
    let speaker: String
    let videoUrl: String
    let thumbnailUrl: String?
    let duration: TimeInterval
    let isLiveStream: Bool
    let isPublished: Bool
    let isDeleted: Bool
    let liveBroadcastStatus: String // "none", "upcoming", "live", or "completed"
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: duration) ?? ""
    }
}

extension Message {
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let speaker = data["speaker"] as? String,
              let videoUrl = data["videoUrl"] as? String,
              let duration = data["duration"] as? TimeInterval,
              let isLiveStream = data["isLiveStream"] as? Bool,
              let isPublished = data["isPublished"] as? Bool else {
            return nil
        }
        
        self.id = document.documentID
        self.title = title
        self.description = description
        self.speaker = speaker
        self.videoUrl = videoUrl
        self.thumbnailUrl = data["thumbnailUrl"] as? String
        self.duration = duration
        self.isLiveStream = isLiveStream
        self.isPublished = isPublished
        self.isDeleted = data["isDeleted"] as? Bool ?? false
        self.liveBroadcastStatus = data["liveBroadcastStatus"] as? String ?? "none"
    }
}
