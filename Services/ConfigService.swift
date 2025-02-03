import Foundation

@MainActor
class ConfigService: ObservableObject {
    static let shared = ConfigService()
    private let pocketBaseService = PocketBaseService.shared
    
    @Published private(set) var config: Config?
    @Published private(set) var error: Error?
    @Published private(set) var isLoading = false
    
    private init() {}
    
    var bibleApiKey: String? {
        config?.apiKeys.bibleApiKey
    }
    
    var jellyfinApiKey: String? {
        config?.apiKeys.jellyfinApiKey
    }
    
    var churchName: String {
        config?.churchName ?? "Rockville-Tolland SDA Church"
    }
    
    var aboutText: String {
        config?.aboutText ?? ""
    }
    
    var contactEmail: String {
        config?.contactEmail ?? "av@rockvilletollandsda.org"
    }
    
    var contactPhone: String {
        config?.contactPhone ?? "8608750450"
    }
    
    var churchAddress: String {
        config?.churchAddress ?? "9 Hartford Tpke Tolland CT 06084"
    }
    
    var googleMapsUrl: String {
        config?.googleMapsUrl ?? "https://maps.app.goo.gl/Ld4YZFPQGxGRBFJt8"
    }
    
    func loadConfig() async {
        isLoading = true
        error = nil
        
        do {
            config = try await pocketBaseService.fetchConfig()
        } catch {
            self.error = error
            print("Failed to load app configuration: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshConfig() async {
        await loadConfig()
    }
} 