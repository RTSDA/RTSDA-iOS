import SwiftUI
import EventKit

struct EventDetailView: View {
    let event: CalendarEvent
    @Environment(\.dismiss) var dismiss
    @State private var showingAddToCalendar = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = true
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            List {
                Section {
                    Text(event.title)
                        .font(.title2)
                        .padding(.vertical, 4)
                    
                    Text(event.description)
                        .foregroundColor(.secondary)
                }
                
                Section("Time & Location") {
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text("Starts: \(dateFormatter.string(from: event.startDateTime))")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        
                        Label {
                            Text("Ends: \(dateFormatter.string(from: event.endDateTime))")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    }
                    
                    if !event.location.isEmpty {
                        Label {
                            Text(event.location)
                        } icon: {
                            Image(systemName: "location")
                        }
                    }
                }
                
                if event.recurrenceType != .none {
                    Section("Recurrence") {
                        Label {
                            Text(event.recurrenceType.displayString)
                        } icon: {
                            Image(systemName: "repeat")
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        showingAddToCalendar = true
                    }) {
                        Label("Add to Calendar", systemImage: "calendar.badge.plus")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .opacity(isLoading ? 0 : 1)
            .alert("Add to Calendar", isPresented: $showingAddToCalendar) {
                Button("Add", role: .none) {
                    addEventToCalendar()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Would you like to add this event to your calendar?")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            
            if isLoading {
                ProgressView()
            }
        }
        .onAppear {
            // Short delay to ensure data is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLoading = false
            }
        }
    }
    
    private func addEventToCalendar() {
        Task {
            let eventStore = EKEventStore()
            
            do {
                if #available(iOS 17.0, *) {
                    let granted = try await eventStore.requestWriteOnlyAccessToEvents()
                    guard granted else {
                        errorMessage = "Calendar access denied"
                        showError = true
                        return
                    }
                } else {
                    let granted = await withCheckedContinuation { continuation in
                        eventStore.requestAccess(to: .event) { granted, _ in
                            continuation.resume(returning: granted)
                        }
                    }
                    guard granted else {
                        errorMessage = "Calendar access denied"
                        showError = true
                        return
                    }
                }
                
                let ekEvent = EKEvent(eventStore: eventStore)
                ekEvent.title = event.title
                ekEvent.startDate = event.startDateTime
                ekEvent.endDate = event.endDateTime
                ekEvent.notes = event.description
                ekEvent.location = event.location
                ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                
                try eventStore.save(ekEvent, span: .thisEvent)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
