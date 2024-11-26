import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var eventsViewModel = EventsViewModel(isAdminView: true)
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                if let admin = authService.currentAdmin {
                    if admin.role == .superAdmin || admin.role == .eventManager {
                        EventManagementView(viewModel: eventsViewModel)
                            .tabItem {
                                Label("Events", systemImage: "calendar")
                            }
                            .tag(0)
                    }
                    
                    if admin.role == .superAdmin || admin.role == .prayerRequestManager {
                        PrayerRequestsView()
                            .tabItem {
                                Label("Prayer Requests", systemImage: "hands.sparkles")
                            }
                            .tag(1)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(selectedTab == 0 ? "Events" : "Prayer Requests")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Welcome, \(authService.currentAdmin?.name ?? "Admin")")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout", action: logout)
                }
            }
        }
    }
    
    private func logout() {
        Task {
            do {
                try authService.signOut()
            } catch {
                print("Error logging out: \(error)")
            }
        }
    }
}

struct EventManagementView: View {
    @ObservedObject var viewModel: EventsViewModel
    @State private var showingAddEvent = false
    @State private var eventToEdit: Event?
    
    var body: some View {
        List {
            if viewModel.events.isEmpty {
                Text("No events yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.events) { event in
                    Button(action: {
                        eventToEdit = event
                    }) {
                        EventRowView(event: event)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteEvent(event)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddEvent = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            NavigationStack {
                AddEventView(viewModel: viewModel)
            }
        }
        .sheet(item: $eventToEdit) { event in
            NavigationStack {
                AddEventView(viewModel: viewModel, eventToEdit: event)
            }
        }
        .refreshable {
            await viewModel.loadEvents()
        }
    }
}

struct PrayerRequestsView: View {
    @StateObject private var viewModel = AdminPrayerRequestViewModel()
    
    var body: some View {
        List {
            if viewModel.prayerRequests.isEmpty {
                Text("No prayer requests yet")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.prayerRequests, id: \.id) { request in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(request.isAnonymous ? "Anonymous" : request.name)
                                .font(.headline)
                            Spacer()
                            Text(request.requestType)
                                .font(.caption)
                                .padding(4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        Text(request.request)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(request.status)
                                .font(.caption)
                                .padding(4)
                                .background(
                                    Group {
                                        switch request.status {
                                        case "pending": Color.green.opacity(0.2)
                                        case "praying": Color.orange.opacity(0.2)
                                        case "answered": Color.blue.opacity(0.2)
                                        default: Color.gray.opacity(0.2)
                                        }
                                    }
                                )
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text(request.timestamp.formatted())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task {
                                if let id = request.id {
                                    try? await viewModel.deletePrayerRequest(requestId: id)
                                }
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            Task {
                                if let id = request.id {
                                    let newStatus = request.status == "pending" ? "praying" :
                                                  request.status == "praying" ? "answered" : "pending"
                                    try? await viewModel.updatePrayerRequestStatus(
                                        requestId: id,
                                        newStatus: newStatus
                                    )
                                }
                            }
                        } label: {
                            Label("Update Status", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .navigationTitle("Prayer Requests")
        .refreshable {
            await viewModel.loadPrayerRequests()
        }
        .task {
            await viewModel.loadPrayerRequests()
        }
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(event.title)
                .font(.headline)
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(event.formattedDateTime)
                .font(.caption)
        }
    }
}
