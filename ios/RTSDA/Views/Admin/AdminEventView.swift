import SwiftUI

struct AdminEventView: View {
    @StateObject private var viewModel = AdminEventViewModel()
    @State private var showingEventForm = false
    @State private var selectedEvent: Event?
    @State private var showingDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.uiState.events.isEmpty && !viewModel.uiState.isLoading {
                    emptyStateView
                } else {
                    eventsList
                }
                
                if viewModel.uiState.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemBackground).opacity(0.8))
                }
            }
            .listStyle(.inset)
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedEvent = nil
                        showingEventForm = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showingEventForm, onDismiss: {
                selectedEvent = nil
            }) {
                NavigationStack {
                    EventFormView(
                        event: selectedEvent,
                        validationState: viewModel.validationState
                    ) { event in
                        Task {
                            do {
                                try await viewModel.saveEvent(event)
                                showingEventForm = false
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                }
            }
            .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    deleteSelectedEvent()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this event?")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .refreshable {
                viewModel.setupEventsListener()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Events")
                .font(.headline)
            Text("Add your first event using the + button")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var eventsList: some View {
        List {
            if let error = viewModel.uiState.error {
                Text(error)
                    .foregroundColor(.red)
                    .listRowSeparator(.hidden)
            }
            
            ForEach(viewModel.uiState.events) { event in
                AdminEventRow(
                    event: event,
                    onDelete: {
                        selectedEvent = event
                        showingDeleteConfirmation = true
                    },
                    onEdit: {
                        selectedEvent = event
                        showingEventForm = true
                    },
                    onPublish: {
                        Task {
                            try? await viewModel.publishEvent(event)
                        }
                    },
                    onUnpublish: {
                        Task {
                            try? await viewModel.unpublishEvent(event)
                        }
                    }
                )
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.setupEventsListener()
        }
    }
    
    private func deleteSelectedEvent() {
        guard let event = selectedEvent else { return }
        Task {
            do {
                try await viewModel.deleteEvent(event)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
