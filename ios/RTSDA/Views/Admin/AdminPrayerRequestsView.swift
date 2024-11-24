import SwiftUI
import FirebaseFirestore

struct AdminPrayerRequestsView: View {
    @StateObject private var viewModel = AdminPrayerRequestsViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedType: PrayerRequest.RequestType?
    @State private var showApprovedOnly = false
    @State private var showPrivateOnly = false
    @State private var showingDeleteAlert = false
    @State private var prayerRequestToDelete: PrayerRequest?
    
    var filteredRequests: [PrayerRequest] {
        // Start with the base filtered requests from the view model
        let requests = viewModel.filteredRequests
        
        print("[AdminPrayerRequestsView] -------- Filtering Requests --------")
        print("[AdminPrayerRequestsView] Base requests from view model: \(requests.count)")
        print("[AdminPrayerRequestsView] Active filters:")
        print(" - Search text: '\(searchText)'")
        print(" - Type filter: \(selectedType?.rawValue ?? "All")")
        print(" - Show approved only: \(showApprovedOnly)")
        print(" - Show private only: \(showPrivateOnly)")
        
        let filtered = requests.filter { request in
            let matchesSearch = searchText.isEmpty || 
                request.name.localizedCaseInsensitiveContains(searchText) ||
                request.email.localizedCaseInsensitiveContains(searchText) ||
                request.request.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedType == nil || request.requestType == selectedType
            let matchesApproved = !showApprovedOnly || request.status == .approved
            let matchesPrivate = !showPrivateOnly || request.isPrivate
            
            let shouldInclude = matchesSearch && matchesType && matchesApproved && matchesPrivate
            
            if !shouldInclude {
                print("[AdminPrayerRequestsView] Filtered out request \(request.id):")
                if !matchesSearch { print(" - Failed search criteria") }
                if !matchesType { print(" - Wrong type (\(request.requestType.rawValue))") }
                if !matchesApproved { print(" - Not approved") }
                if !matchesPrivate { print(" - Not private") }
            }
            
            return shouldInclude
        }
        
        print("[AdminPrayerRequestsView] Filtered count: \(filtered.count)")
        print("[AdminPrayerRequestsView] ----------------------------------")
        
        return filtered
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.prayerRequests.isEmpty {
                Text("No prayer requests in the database")
                    .foregroundColor(.secondary)
            } else if filteredRequests.isEmpty {
                Text("No prayer requests match the current filters")
                    .foregroundColor(.secondary)
            } else {
                RequestsList
            }
        }
        .searchable(text: $searchText, prompt: "Search requests")
        .navigationTitle("Prayer Requests")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters.toggle()
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet
        }
        .alert("Delete Request", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let request = prayerRequestToDelete {
                    viewModel.deleteRequest(request)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this prayer request?")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.showError = false
                viewModel.errorMessage = ""
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            print("AdminPrayerRequestsView appeared")
        }
    }
    
    private var RequestsList: some View {
        ForEach(filteredRequests) { request in
            RequestRow(request: request) { updatedRequest in
                viewModel.updateRequest(updatedRequest)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    prayerRequestToDelete = request
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    private var FilterSheet: some View {
        NavigationView {
            List {
                Section("Request Type") {
                    ForEach(PrayerRequest.RequestType.allCases, id: \.self) { type in
                        Button {
                            print("[AdminPrayerRequestsView] Filter type selected: \(type.rawValue)")
                            withAnimation {
                                if type == .all {
                                    // When selecting "All", clear the selectedType
                                    selectedType = nil
                                } else {
                                    selectedType = type
                                }
                                viewModel.setRequestType(type)
                            }
                            showFilters = false
                        } label: {
                            HStack {
                                Text(type.rawValue)
                                Spacer()
                                if selectedType == type || (type == .all && selectedType == nil) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Section("Status") {
                    Toggle("Show Approved Only", isOn: $showApprovedOnly)
                    Toggle("Show Private Only", isOn: $showPrivateOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showFilters = false
                    }
                }
            }
        }
    }
}

struct RequestRow: View {
    let request: PrayerRequest
    let onUpdate: (PrayerRequest) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(request.name)
                    .font(.headline)
                Spacer()
                HStack(spacing: 8) {
                    Text(request.requestType.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    
                    if request.isPrivate {
                        Label("Private", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(request.request)
                .font(.body)
                .lineLimit(3)
            
            VStack(alignment: .leading, spacing: 4) {
                if !request.email.isEmpty {
                    Label(request.email, systemImage: "envelope")
                        .font(.caption)
                }
                if !request.phone.isEmpty {
                    Link(destination: URL(string: "tel:\(request.phone)")!) {
                        Label(request.phone, systemImage: "phone")
                            .font(.caption)
                    }
                }
            }
            
            HStack {
                Picker("Status", selection: Binding(
                    get: { request.status },
                    set: { newStatus in
                        var updatedRequest = request
                        updatedRequest.status = newStatus
                        onUpdate(updatedRequest)
                    }
                )) {
                    Text("New").tag(PrayerRequest.RequestStatus.new)
                    Text("Approved").tag(PrayerRequest.RequestStatus.approved)
                    Text("Rejected").tag(PrayerRequest.RequestStatus.rejected)
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                Text(request.timestamp.dateValue().formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AdminPrayerRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        AdminPrayerRequestsView()
    }
}
