import SwiftUI
import EventKit
import FirebaseFirestore

struct EventsView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @StateObject private var viewModel = EventsViewModel()
    @State private var showingError = false
    @State private var selectedEvent: CalendarEvent?
    @Environment(\.scenePhase) var scenePhase
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ZStack {
                List {
                    if viewModel.isLoading {
                        ProgressView("Loading events...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if viewModel.events.isEmpty {
                        Text("No upcoming events")
                            .font(.body)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.events) { event in
                            EventRowView(event: event)
                                .onTapGesture {
                                    selectedEvent = event
                                }
                        }
                    }
                }
                .refreshable {
                    await viewModel.fetchEvents()
                }
                .alert("Error", isPresented: $showingError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.error?.localizedDescription ?? "An error occurred")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                }
                .navigationTitle("Events")
                .sheet(item: $selectedEvent) { event in
                    EventView(event: event)
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await viewModel.fetchEvents()
                }
            }
        }
        .onReceive(viewModel.$error) { error in
            showingError = error != nil
        }
    }
}

struct EventRowView: View {
    let event: CalendarEvent
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        NavigationLink(destination: EventView(event: event)) {
            HStack {
                Image(systemName: "calendar")
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    
                    Text(dateFormatter.string(from: event.startDate))
                        .font(.subheadline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .foregroundColor(.secondary)
                    
                    if !event.location.isEmpty {
                        Text(event.location)
                            .font(.subheadline)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .accessibilityLabel("\(event.title) on \(dateFormatter.string(from: event.startDate))\(event.location.isEmpty ? "" : " at \(event.location)")")
        .accessibilityHint("Tap to view event details")
    }
}