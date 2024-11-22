import SwiftUI
import FirebaseFirestore

// Main container view
struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    
    var body: some View {
        EventsContainerView(viewModel: viewModel)
    }
}

// Container view handling navigation and alerts
private struct EventsContainerView: View {
    @ObservedObject var viewModel: EventsViewModel
    @State private var showingError = false
    @State private var selectedEvent: Event? = nil
    
    var body: some View {
        NavigationStack {
            EventsListView(
                events: viewModel.events,
                isLoading: viewModel.isLoading,
                selectedEvent: $selectedEvent,
                onRefresh: { viewModel.refresh() }
            )
            .navigationTitle("Events")
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            .alert(viewModel.error?.errorDescription ?? "Error", isPresented: $showingError) {
                Button("Retry", role: .none) {
                    viewModel.refresh()
                }
                Button("OK", role: .cancel) {}
            } message: {
                if case .networkError = viewModel.error {
                    Text("Please check your internet connection and try again.")
                } else {
                    Text("An unexpected error occurred. Please try again.")
                }
            }
            .onReceive(viewModel.$error) { error in
                showingError = error != nil
            }
        }
    }
}

// List view handling content display
private struct EventsListView: View {
    let events: [Event]
    let isLoading: Bool
    @Binding var selectedEvent: Event?
    let onRefresh: () -> Void
    
    var body: some View {
        ScrollView {
            if isLoading && events.isEmpty {
                LoadingView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else if events.isEmpty {
                EmptyStateView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(events) { event in
                        EventRowView(event: event)
                            .onTapGesture {
                                selectedEvent = event
                            }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .refreshable {
            onRefresh()
        }
    }
}

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading events...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Events")
                .font(.headline)
            Text("Check back later for upcoming events")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}