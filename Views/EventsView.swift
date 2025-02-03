import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    @State private var selectedEvent: Event?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Text("Unable to load events")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadEvents()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.events.isEmpty {
                    Text("No upcoming events")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(viewModel.events) { event in
                                EventCard(event: event) {
                                    selectedEvent = event
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await viewModel.loadEvents()
                    }
                }
            }
            .navigationTitle("Events")
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            .task {
                await viewModel.loadEvents()
            }
        }
    }
}

#Preview {
    EventsView()
}
