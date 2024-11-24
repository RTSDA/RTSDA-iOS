import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class AdminPrayerRequestsViewModel: ObservableObject {
    @Published var prayerRequests: [PrayerRequest] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedRequestType: PrayerRequest.RequestType = .all
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        setupPrayerRequestsListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    func setupPrayerRequestsListener() {
        isLoading = true
        print("[AdminPrayerRequestsViewModel] Setting up prayer requests listener")
        
        listener?.remove()  // Remove any existing listener
        
        listener = db.collection("prayerRequests")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("[AdminPrayerRequestsViewModel] Error fetching prayer requests: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("[AdminPrayerRequestsViewModel] No documents found")
                    self.prayerRequests = []
                    self.isLoading = false
                    return
                }
                
                print("[AdminPrayerRequestsViewModel] Received \(documents.count) prayer requests")
                self.prayerRequests = documents.compactMap { document -> PrayerRequest? in
                    let data = document.data()
                    print("[AdminPrayerRequestsViewModel] Processing document: \(document.documentID)")
                    
                    guard let name = data["name"] as? String,
                          let email = data["email"] as? String,
                          let phone = data["phone"] as? String,
                          let request = data["request"] as? String,
                          let statusString = data["status"] as? String,
                          let status = PrayerRequest.RequestStatus(rawValue: statusString.lowercased()),
                          let timestamp = data["timestamp"] as? Timestamp else {
                        print("[AdminPrayerRequestsViewModel] Missing required fields for document: \(document.documentID)")
                        return nil
                    }
                    
                    // Handle isPrivate as either boolean or integer
                    let isPrivate: Bool
                    if let boolValue = data["isPrivate"] as? Bool {
                        isPrivate = boolValue
                    } else if let intValue = data["isPrivate"] as? Int {
                        isPrivate = intValue != 0
                    } else {
                        isPrivate = false
                    }
                    
                    // Default to PERSONAL if requestType is missing
                    let requestType: PrayerRequest.RequestType
                    if let requestTypeString = data["requestType"] as? String,
                       let parsedType = PrayerRequest.RequestType(rawValue: requestTypeString) {
                        requestType = parsedType
                    } else {
                        requestType = .personal
                    }
                    
                    return PrayerRequest(
                        id: document.documentID,
                        name: name,
                        email: email,
                        phone: phone,
                        request: request,
                        timestamp: timestamp,
                        status: status,
                        isPrivate: isPrivate,
                        requestType: requestType
                    )
                }
                
                print("[AdminPrayerRequestsViewModel] Successfully decoded \(self.prayerRequests.count) prayer requests")
                self.isLoading = false
            }
    }
    
    var filteredRequests: [PrayerRequest] {
        print("[AdminPrayerRequestsViewModel] Filtering requests - Type: \(selectedRequestType.rawValue)")
        print("[AdminPrayerRequestsViewModel] Total requests: \(prayerRequests.count)")
        
        if selectedRequestType == .all {
            print("[AdminPrayerRequestsViewModel] Returning all requests")
            return prayerRequests
        }
        
        let filtered = prayerRequests.filter { $0.requestType == selectedRequestType }
        print("[AdminPrayerRequestsViewModel] Filtered count: \(filtered.count)")
        return filtered
    }
    
    func setRequestType(_ type: PrayerRequest.RequestType) {
        print("[AdminPrayerRequestsViewModel] Setting request type: \(type.rawValue)")
        selectedRequestType = type
    }
    
    func updateRequest(_ request: PrayerRequest) {
        Task {
            do {
                try await db.collection("prayerRequests").document(request.id).setData(from: request)
                print("[AdminPrayerRequestsViewModel] Successfully updated request: \(request.id)")
            } catch {
                print("[AdminPrayerRequestsViewModel] Error updating request: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func deleteRequest(_ request: PrayerRequest) {
        Task {
            do {
                try await db.collection("prayerRequests").document(request.id).delete()
                print("[AdminPrayerRequestsViewModel] Successfully deleted request: \(request.id)")
            } catch {
                print("[AdminPrayerRequestsViewModel] Error deleting request: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}