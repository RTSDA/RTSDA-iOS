import SwiftUI

struct AdminEventView: View {
    @StateObject private var viewModel = AdminEventViewModel()
    @State private var showingEventForm = false
    @State private var selectedEvent: Event?
    @State private var showingDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        mainContent
            .sheet(isPresented: $showingEventForm) {
                eventFormSheet
            }
            .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
                deleteAlert
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
    }
    
    private var mainContent: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    eventsList
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
        }
    }
    
    private var eventFormSheet: some View {
        NavigationStack {
            EventFormView(
                event: selectedEvent,
                validationState: viewModel.validationState,
                onSave: { event in
                    Task {
                        do {
                            try await viewModel.saveEvent(event)
                            showingEventForm = false
                            selectedEvent = nil
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            )
            .navigationTitle(selectedEvent == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingEventForm = false
                        selectedEvent = nil
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    private var eventsList: some View {
        List {
            if viewModel.events.isEmpty {
                Text("No events in the database")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.events) { event in
                    AdminEventRow(
                        event: event,
                        onDelete: {
                            selectedEvent = event
                            showingDeleteConfirmation = true
                        },
                        onEdit: {
                            selectedEvent = event
                            DispatchQueue.main.async {
                                showingEventForm = true
                            }
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
        }
        .listStyle(.inset)
        .refreshable {
            viewModel.setupEventsListener()
        }
    }
    
    private var addButton: some View {
        Button {
            selectedEvent = nil
            showingEventForm = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
        }
    }
    
    private var deleteAlert: some View {
        Group {
            Button("Delete", role: .destructive) {
                if let event = selectedEvent {
                    Task {
                        do {
                            try await viewModel.deleteEvent(event)
                            selectedEvent = nil
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                selectedEvent = nil
            }
        }
    }
}
