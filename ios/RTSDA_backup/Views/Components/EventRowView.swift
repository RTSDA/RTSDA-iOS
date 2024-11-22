import SwiftUI
import EventKit

struct EventRowView: View {
    let event: CalendarEvent
    @State private var eventStore = EKEventStore()
    @State private var showingAddToCalendar = false
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.sizeCategory) private var sizeCategory
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Main event content
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    .lineLimit(2)
                
                if !event.description.isEmpty {
                    Text(event.description)
                        .font(.system(.body, design: .default))
                        .foregroundColor(.secondary)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                        .lineLimit(sizeCategory.isAccessibilityCategory ? 1 : 2)
                }
                
                if !event.location.isEmpty {
                    Label {
                        Text(event.location)
                            .font(.system(.subheadline, design: .default))
                            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: "location")
                            .foregroundColor(.secondary)
                            .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    }
                    .foregroundColor(.secondary)
                }
                
                HStack(spacing: 12) {
                    Label {
                        Text(dateFormatter.string(from: event.startDateTime))
                            .font(.system(.subheadline, design: .default))
                            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                            .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    }
                    
                    if event.recurrenceType != .none {
                        Label {
                            Text(event.recurrenceType.displayString)
                                .font(.system(.subheadline, design: .default))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                        } icon: {
                            Image(systemName: "repeat")
                                .foregroundColor(.blue)
                                .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Add to Calendar button
            Button {
                showingAddToCalendar = true
            } label: {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: sizeCategory.isAccessibilityCategory ? 24 : 20))
                    .foregroundColor(.blue)
                    .frame(width: sizeCategory.isAccessibilityCategory ? 56 : 44, 
                           height: sizeCategory.isAccessibilityCategory ? 56 : 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Add to Calendar")
        }
        .padding(.vertical, sizeCategory.isAccessibilityCategory ? 12 : 8)
        .padding(.horizontal, 4)
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
        .alert("Success", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Event successfully added to your calendar!")
        }
    }
    
    private func addEventToCalendar() {
        Task {
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
                ekEvent.notes = event.description
                ekEvent.location = event.location
                ekEvent.startDate = event.startDateTime
                ekEvent.endDate = event.endDateTime
                ekEvent.calendar = eventStore.defaultCalendarForNewEvents
                
                try eventStore.save(ekEvent, span: .thisEvent)
                
                // Show success alert
                await MainActor.run {
                    showSuccess = true
                }
                
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}