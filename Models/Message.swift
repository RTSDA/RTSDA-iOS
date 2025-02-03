import Foundation

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
    let date: String // ISO8601 formatted date string
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: duration) ?? ""
    }
    
    var formattedDate: String {
        // Parse the date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        
        guard let date = dateFormatter.date(from: date) else { return date }
        
        // Format for display
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM d, yyyy"
        displayFormatter.timeZone = TimeZone(identifier: "America/New_York")
        return displayFormatter.string(from: date)
    }
}

// MARK: - Codable
extension Message: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case speaker
        case videoUrl
        case thumbnailUrl
        case duration
        case isLiveStream
        case isPublished
        case isDeleted
        case liveBroadcastStatus
        case date
    }
}
