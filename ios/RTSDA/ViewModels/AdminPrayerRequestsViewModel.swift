import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class AdminPrayerRequestsViewModel: ObservableObject {
    @Published var prayerRequests: [PrayerRequest] = []
    @Published var filteredRequests: [PrayerRequest] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var selectedRequestType: PrayerRequest.RequestType = .all
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        setupRealtimeUpdates()
    }
    
    deinit {
        listener?.remove()
    }
    
    private func setupRealtimeUpdates() {
        isLoading = true
        print("Setting up realtime updates")
        
        listener = db.collection("prayerRequests")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] (querySnapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Firestore error: \(error.localizedDescription)")
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No documents found in snapshot")
                    self.prayerRequests = []
                    self.filterRequests()
                    self.isLoading = false
                    return
                }
                
                print("Found \(documents.count) documents")
                
                self.prayerRequests = documents.compactMap { document -> PrayerRequest? in
                    let data = document.data()
                    print("Processing document: \(document.documentID)")
                    print("Document data: \(data)")
                    
                    guard let name = data["name"] as? String,
                          let email = data["email"] as? String,
                          let phone = data["phone"] as? String,
                          let request = data["request"] as? String,
                          let statusString = data["status"] as? String,
                          let status = PrayerRequest.RequestStatus(rawValue: statusString.lowercased()),
                          let timestamp = data["timestamp"] as? Timestamp else {
                        print("Failed to parse required fields for document: \(document.documentID)")
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
                
                print("Successfully parsed \(self.prayerRequests.count) prayer requests")
                self.filterRequests()
                self.isLoading = false
            }
    }
    
    func filterRequests() {
        filteredRequests = prayerRequests.filter { request in
            switch selectedRequestType {
            case .all:
                return true
            case let type:
                return request.requestType == type
            }
        }
    }
    
    func setRequestType(_ type: PrayerRequest.RequestType) {
        selectedRequestType = type
        filterRequests()
    }
    
    func updateRequest(_ request: PrayerRequest) {
        Task {
            do {
                try await db.collection("prayerRequests")
                    .document(request.id)
                    .updateData([
                        "status": request.status.rawValue,
                        "requestType": request.requestType.rawValue,
                        "isPrivate": request.isPrivate
                    ])
                
                if let index = prayerRequests.firstIndex(where: { $0.id == request.id }) {
                    prayerRequests[index] = request
                }
                
                filterRequests()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func deleteRequest(_ request: PrayerRequest) {
        Task {
            do {
                try await db.collection("prayerRequests")
                    .document(request.id)
                    .delete()
                
                prayerRequests.removeAll { $0.id == request.id }
                
                filterRequests()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    func updateRequestStatus(_ request: PrayerRequest, newStatus: PrayerRequest.RequestStatus) async {
        do {
            let data: [String: Any] = [
                "status": newStatus.rawValue
            ]
            
            try await db.collection("prayerRequests").document(request.id).updateData(data)
            
            // Update local state
            if let index = prayerRequests.firstIndex(where: { $0.id == request.id }) {
                var updatedRequest = request
                updatedRequest.status = newStatus
                prayerRequests[index] = updatedRequest
            }
            
            filterRequests()
            
            print("Updated prayer request status: \(request.id) - Status: \(newStatus)")
        } catch {
            print("Error updating prayer request status: \(error)")
        }
    }
    
    func deletePrayerRequest(_ request: PrayerRequest) async {
        do {
            try await db.collection("prayerRequests").document(request.id).delete()
            prayerRequests.removeAll { $0.id == request.id }
            
            filterRequests()
            
            print("Deleted prayer request: \(request.id)")
        } catch {
            print("Error deleting prayer request: \(error)")
        }
    }
    
    private func createPrayerRequest(title: String, description: String) {
        let timestamp = Timestamp(date: Date())
        let prayerRequest = PrayerRequest(
            id: "",
            name: title,
            email: "",
            phone: "",
            request: description,
            timestamp: timestamp,
            status: .new,
            isPrivate: false,
            requestType: .personal
        )
    }
}