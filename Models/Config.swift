import Foundation

struct Config: Codable {
    let id: String
    let churchName: String
    let contactEmail: String
    let contactPhone: String
    let churchAddress: String
    let googleMapsUrl: String
    let aboutText: String
    let apiKeys: APIKeys
    
    struct APIKeys: Codable {
        let bibleApiKey: String
        let jellyfinApiKey: String
        
        enum CodingKeys: String, CodingKey {
            case bibleApiKey = "bible_api_key"
            case jellyfinApiKey = "jellyfin_api_key"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case churchName = "church_name"
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case churchAddress = "church_address"
        case googleMapsUrl = "google_maps_url"
        case aboutText = "about_text"
        case apiKeys = "api_key"
    }
}

struct ConfigResponse: Codable {
    let page: Int
    let perPage: Int
    let totalPages: Int
    let totalItems: Int
    let items: [Config]
    
    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "perPage"
        case totalPages = "totalPages"
        case totalItems = "totalItems"
        case items
    }
} 