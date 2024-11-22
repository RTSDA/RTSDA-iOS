import SwiftUI
import FirebaseFirestore

struct AdminEventView: View {
    @StateObject private var viewModel = AdminEventViewModel()
    @ObservedObject private var authService = AdminAuthService.shared
    @State private var showingAddEvent = false
    @State private var showingDeleteConfirmation = false
    @State private var eventToDelete: CalendarEvent?
    @State private var showError = false
    
    var body: some View {
        if authService.isAdmin {
            NavigationView {
                ZStack {
                    if viewModel.events.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "calendar")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No events")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        List {
                            if viewModel.isOffline {
                                Section {
                                    HStack {
                                        Image(systemName: "wifi.slash")
                                            .foregroundColor(.orange)
                                        Text("Offline Mode")
                                            .foregroundColor(.orange)
                                        Spacer()
                                        ProgressView()
                                            .tint(.orange)
                                    }
                                    .listRowBackground(Color.orange.opacity(0.1))
                                }
                            }
                            
                            ForEach(viewModel.events) { event in
                                AdminEventRow(event: event, viewModel: viewModel)
                                    .onTapGesture {
                                        viewModel.eventToEdit = event
                                        showingAddEvent = true
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            eventToDelete = event
                                            showingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .refreshable {
                            await viewModel.fetchEvents()
                        }
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
                .navigationTitle("Events")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.eventToEdit = nil
                            showingAddEvent = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .disabled(viewModel.isOffline)
                    }
                }
                .sheet(isPresented: $showingAddEvent) {
                    NavigationView {
                        EventFormView(
                            event: viewModel.eventToEdit
                        ) { event in
                            Task {
                                await viewModel.saveEvent(event)
                                showingAddEvent = false
                            }
                        }
                    }
                }
                .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
                    Button("Delete", role: .destructive) {
                        if let event = eventToDelete {
                            Task {
                                await viewModel.deleteEvent(event)
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Are you sure you want to delete this event?")
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
                }
                .onReceive(viewModel.$error) { error in
                    showError = error != nil
                }
            }
            .task {
                await viewModel.fetchEvents()
            }
        } else {
            Text("Access Denied")
                .font(.title)
                .foregroundColor(.red)
        }
    }
}
