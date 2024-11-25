import Foundation

actor CacheService {
    static let shared = CacheService()
    
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Cache configuration
    private let maxMemoryCacheSize = 50 // Maximum number of items in memory
    internal let cacheExpirationInterval: TimeInterval = 3600 * 4 // 4 hours
    
    private init() {
        // Set up memory cache limits
        memoryCache.countLimit = maxMemoryCacheSize
        
        // Set up disk cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDirectory.appendingPathComponent("YouTubeCache")
        
        try? fileManager.createDirectory(at: cacheDirectory, 
                                       withIntermediateDirectories: true)
        
        // Clean up expired disk cache on init
        Task {
            await cleanExpiredDiskCache()
        }
    }
    
    // MARK: - Cache Operations
    
    func cache<T: Codable>(_ object: T, forKey key: String) async throws {
        let entry = CacheEntry(object: object, timestamp: Date())
        
        // Save to memory cache
        memoryCache.setObject(entry, forKey: key as NSString)
        
        // Save to disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key)
        let data = try JSONEncoder().encode(entry)
        try data.write(to: fileURL)
    }
    
    func object<T: Codable>(forKey key: String) async throws -> T? {
        // Check memory cache first
        if let entry = memoryCache.object(forKey: key as NSString) {
            if !entry.isExpired {
                return entry.object as? T
            }
            memoryCache.removeObject(forKey: key as NSString)
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        let data = try Data(contentsOf: fileURL)
        let entry = try JSONDecoder().decode(CacheEntry.self, from: data)
        
        if entry.isExpired {
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
        
        // Update memory cache with disk cache hit
        memoryCache.setObject(entry, forKey: key as NSString)
        return entry.object as? T
    }
    
    func removeObject(forKey key: String) async throws {
        // Remove from memory cache
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    func clearAll() async throws {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory,
                                                         includingPropertiesForKeys: nil)
        for url in contents {
            try fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - Cache Maintenance
    
    private func cleanExpiredDiskCache() async {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory,
                                                             includingPropertiesForKeys: nil)
            for url in contents {
                guard let data = try? Data(contentsOf: url),
                      let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) else {
                    try? fileManager.removeItem(at: url)
                    continue
                }
                
                if entry.isExpired {
                    try? fileManager.removeItem(at: url)
                }
            }
        } catch {
            print("Error cleaning disk cache: \(error)")
        }
    }
}

// MARK: - Cache Entry

private class CacheEntry: Codable {
    let object: Codable
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > CacheService.shared.cacheExpirationInterval
    }
    
    init(object: Codable, timestamp: Date) {
        self.object = object
        self.timestamp = timestamp
    }
    
    private enum CodingKeys: String, CodingKey {
        case object, timestamp
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Decode the object based on its type
        if let data = try? container.decode(YouTubeService.YouTubeVideo.self, forKey: .object) {
            object = data
        } else {
            throw DecodingError.dataCorruptedError(forKey: .object,
                                                  in: container,
                                                  debugDescription: "Unknown object type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(object, forKey: .object)
    }
}
