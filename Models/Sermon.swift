import Foundation

struct Sermon: Identifiable {
    let id: String
    let title: String
    let description: String
    let date: Date
    let speaker: String
    let type: SermonType
    let videoUrl: String?
    let thumbnail: String?
    
    init(id: String, title: String, description: String, date: Date, speaker: String, type: SermonType, videoUrl: String?, thumbnail: String?) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.speaker = speaker
        self.type = type
        self.videoUrl = videoUrl
        self.thumbnail = thumbnail
    }
}

enum SermonType: String {
    case sermon = "Sermons"
    case liveArchive = "LiveStreams"
} 
