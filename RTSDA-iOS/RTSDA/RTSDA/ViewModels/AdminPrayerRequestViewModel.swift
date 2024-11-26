import SwiftUI
import FirebaseFirestore

@MainActor
class AdminPrayerRequestViewModel: ObservableObject {
    @Published private(set) var prayerRequests: [PrayerRequest] = []
    private var listener: ListenerRegistration?
    private let firebaseService = FirebaseService.shared
    
    init() {
        setupListener()
    }
    
    private func setupListener() {
        listener = firebaseService.subscribeToPrayerRequests { [weak self] requests in
            self?.prayerRequests = requests.sorted { $0.timestamp > $1.timestamp }
        }
    }
    
    func loadPrayerRequests() async {
        // The listener will handle updates, but we can add manual refresh logic here if needed
    }
    
    func deletePrayerRequest(requestId: String) async throws {
        try await firebaseService.deletePrayerRequest(requestId: requestId)
    }
    
    func updatePrayerRequestStatus(requestId: String, newStatus: String) async throws {
        try await firebaseService.updatePrayerRequestStatus(requestId: requestId, newStatus: newStatus)
    }
    
    deinit {
        listener?.remove()
    }
}
