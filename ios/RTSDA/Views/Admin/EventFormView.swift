import SwiftUI

struct EventFormView: View {
    let event: Event?
    let validationState: EventValidationState
    let onSave: (Event) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location: String
    @State private var locationUrl: String
    @State private var recurrenceType: RecurrenceType
    
    init(event: Event?, validationState: EventValidationState, onSave: @escaping (Event) -> Void) {
        self.event = event
        self.validationState = validationState
        self.onSave = onSave
        
        _title = State(initialValue: event?.title ?? "")
        _description = State(initialValue: event?.description ?? "")
        _startDate = State(initialValue: event?.startDate ?? Date())
        _endDate = State(initialValue: event?.endDate ?? Date().addingTimeInterval(3600))
        _location = State(initialValue: event?.location ?? "")
        _locationUrl = State(initialValue: event?.locationUrl ?? "")
        _recurrenceType = State(initialValue: event?.recurrenceType ?? .none)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Event Details")) {
                TextField("Title", text: $title)
                    .textInputAutocapitalization(.words)
                if !validationState.hasTitle {
                    Text("Title is required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                
                DatePicker("Start Date", selection: $startDate)
                if !validationState.hasStartDate {
                    Text("Start date is required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                DatePicker("End Date", selection: $endDate)
                if !validationState.hasEndDate {
                    Text("End date is required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if !validationState.isEndDateAfterStart {
                    Text("End date must be after start date")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Location")) {
                TextField("Location", text: $location)
                    .textInputAutocapitalization(.words)
                if !validationState.hasLocation {
                    Text("Location is required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                TextField("Location URL", text: $locationUrl)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
            }
            
            Section(header: Text("Recurrence")) {
                Picker("Recurrence", selection: $recurrenceType) {
                    ForEach(RecurrenceType.allCases, id: \.self) { type in
                        Text(type.displayString)
                            .tag(type)
                    }
                }
            }
        }
        .navigationTitle(event == nil ? "Add Event" : "Edit Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    let newEvent = Event(
                        id: event?.id ?? "",
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                        startDate: startDate,
                        endDate: endDate,
                        location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                        locationUrl: locationUrl.isEmpty ? nil : locationUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                        recurrenceType: recurrenceType,
                        parentEventId: event?.parentEventId,
                        createdAt: event?.createdAt ?? Date(),
                        updatedAt: Date(),
                        createdBy: event?.createdBy,
                        updatedBy: nil,
                        isPublished: event?.isPublished ?? false,
                        isDeleted: event?.isDeleted ?? false
                    )
                    onSave(newEvent)
                }
            }
        }
    }
}
