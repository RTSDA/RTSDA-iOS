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
        viewModel.filteredRequests.filter { request in
            let matchesSearch = searchText.isEmpty || 
                request.name.localizedCaseInsensitiveContains(searchText) ||
                request.email.localizedCaseInsensitiveContains(searchText) ||
                request.request.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedType == nil || request.requestType == selectedType
            let matchesApproved = !showApprovedOnly || request.status == .approved
            let matchesPrivate = !showPrivateOnly || request.isPrivate
            
            return matchesSearch && matchesType && matchesApproved && matchesPrivate
        }
    }
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView()
            } else if !viewModel.prayerRequests.isEmpty {
                FiltersSection
                RequestsList
            } else {
                ContentUnavailableView(
                    "No Prayer Requests",
                    systemImage: "hands.sparkles",
                    description: Text("Prayer requests will appear here")
                )
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
        .onAppear {
            print("AdminPrayerRequestsView appeared")
        }
    }
    
    private var FiltersSection: some View {
        Section {
            Toggle("Show Approved Only", isOn: $showApprovedOnly)
            Toggle("Show Private Only", isOn: $showPrivateOnly)
            if let type = selectedType {
                HStack {
                    Text("Type: \(type.rawValue)")
                    Spacer()
                    Button("Clear") {
                        selectedType = nil
                    }
                }
            }
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
                            selectedType = (selectedType == type) ? nil : type
                            showFilters = false
                        } label: {
                            HStack {
                                Text(type.rawValue)
                                Spacer()
                                if selectedType == type {
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
                if request.isPrivate {
                    Label("Private", systemImage: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
