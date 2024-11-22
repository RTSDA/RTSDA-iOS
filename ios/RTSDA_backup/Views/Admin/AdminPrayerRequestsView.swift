import SwiftUI
import FirebaseFirestore

struct AdminPrayerRequestsView: View {
    @StateObject private var viewModel = AdminPrayerRequestsViewModel()
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedType: PrayerRequest.RequestType?
    @State private var showPrayedForOnly = false
    @State private var showConfidentialOnly = false
    @State private var showingDeleteAlert = false
    @State private var prayerRequestToDelete: PrayerRequest?
    
    var filteredRequests: [PrayerRequest] {
        viewModel.prayerRequests.filter { request in
            let matchesSearch = searchText.isEmpty || 
                request.name.localizedCaseInsensitiveContains(searchText) ||
                request.email.localizedCaseInsensitiveContains(searchText) ||
                request.details.localizedCaseInsensitiveContains(searchText)
            
            let matchesType = selectedType == nil || request.requestType == selectedType
            let matchesPrayedFor = !showPrayedForOnly || request.prayedFor
            let matchesConfidential = !showConfidentialOnly || request.isConfidential
            
            return matchesSearch && matchesType && matchesPrayedFor && matchesConfidential
        }
    }
    
    var body: some View {
        List {
            if !viewModel.prayerRequests.isEmpty {
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
        .alert("Delete Prayer Request?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let request = prayerRequestToDelete {
                    Task {
                        await viewModel.deletePrayerRequest(request)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .task {
            await viewModel.fetchPrayerRequests()
        }
        .refreshable {
            await viewModel.fetchPrayerRequests()
        }
    }
    
    private var FiltersSection: some View {
        Section {
            if selectedType != nil || showPrayedForOnly || showConfidentialOnly {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        if let type = selectedType {
                            FilterChip(text: type.rawValue) {
                                selectedType = nil
                            }
                        }
                        if showPrayedForOnly {
                            FilterChip(text: "Prayed For") {
                                showPrayedForOnly = false
                            }
                        }
                        if showConfidentialOnly {
                            FilterChip(text: "Confidential") {
                                showConfidentialOnly = false
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private var RequestsList: some View {
        ForEach(filteredRequests, id: \.id) { request in
            RequestRow(request: request) { updatedRequest in
                Task {
                    await viewModel.updatePrayedForStatus(request: updatedRequest)
                }
            }
            .swipeActions(edge: .trailing) {
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
                    Toggle("Show Prayed For Only", isOn: $showPrayedForOnly)
                    Toggle("Show Confidential Only", isOn: $showConfidentialOnly)
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
                if request.isConfidential {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.red)
                }
                Spacer()
                Text(request.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(request.email)
                .font(.subheadline)
                .foregroundColor(.blue)
            
            Text("Type: \(request.requestType.rawValue)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(request.details)
                .font(.body)
                .padding(.top, 4)
            
            HStack {
                Spacer()
                Button {
                    var updatedRequest = request
                    updatedRequest.prayedFor.toggle()
                    updatedRequest.prayedForDate = updatedRequest.prayedFor ? Date() : nil
                    onUpdate(updatedRequest)
                } label: {
                    Label(
                        request.prayedFor ? "Prayed For" : "Mark as Prayed For",
                        systemImage: request.prayedFor ? "checkmark.circle.fill" : "circle"
                    )
                    .foregroundColor(request.prayedFor ? .green : .blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.subheadline)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.secondary.opacity(0.2))
        .cornerRadius(16)
    }
}

