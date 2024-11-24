import SwiftUI
import FirebaseAuth

struct EventFormView: View {
    let event: Event?
    @StateObject private var formState = EventFormState()
    let onSave: (Event) -> Void
    
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var location: String = ""
    @State private var locationUrl: String = ""
    @State private var recurrenceType: RecurrenceType = .none
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(event: Event?, validationState: EventValidationState, onSave: @escaping (Event) -> Void) {
        print("[EventFormView] ===== FORM INITIALIZATION START =====")
        print("[EventFormView] Received event: \(event?.id ?? "nil") with title: \(event?.title ?? "nil")")
        self.event = event
        self.onSave = onSave
        
        // Initialize state with event data if editing, otherwise use defaults
        if let existingEvent = event {
            print("[EventFormView] Initializing with existing event:")
            print("  - ID: \(existingEvent.id)")
            print("  - Title: \(existingEvent.title)")
            print("  - Description: \(existingEvent.description)")
            
            _title = State(initialValue: existingEvent.title)
            _description = State(initialValue: existingEvent.description)
            _startDate = State(initialValue: existingEvent.startDate)
            _endDate = State(initialValue: existingEvent.endDate ?? existingEvent.startDate.addingTimeInterval(3600))
            _location = State(initialValue: existingEvent.location)
            _locationUrl = State(initialValue: existingEvent.locationUrl ?? "")
            _recurrenceType = State(initialValue: existingEvent.recurrenceType)
            
            print("[EventFormView] Form state initialized with existing event data")
        } else {
            print("[EventFormView] Initializing new event with default values")
            let now = Date()
            _title = State(initialValue: "")
            _description = State(initialValue: "")
            _startDate = State(initialValue: now)
            _endDate = State(initialValue: now.addingTimeInterval(3600))
            _location = State(initialValue: "")
            _locationUrl = State(initialValue: "")
            _recurrenceType = State(initialValue: .none)
            
            print("[EventFormView] Form state initialized with default values")
        }
        
        print("[EventFormView] ===== FORM INITIALIZATION COMPLETE =====")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Event Details")) {
                TextField("Title", text: $title)
                    .textInputAutocapitalization(.words)
                    .onChange(of: title) { _ in updateValidation() }
                if !formState.validationState.hasTitle {
                    Text("Title is required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                
                DatePicker("Start Date", selection: $startDate)
                    .onChange(of: startDate) { _ in updateValidation() }
                if !formState.validationState.hasStartDate {
                    Text("Start date is required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                DatePicker("End Date", selection: $endDate)
                    .onChange(of: endDate) { _ in updateValidation() }
                if !formState.validationState.hasEndDate {
                    Text("End date is required")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                if !formState.validationState.isEndDateAfterStart {
                    Text("End date must be after start date")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("Location")) {
                TextField("Location", text: $location)
                    .textInputAutocapitalization(.words)
                    .onChange(of: location) { _ in updateValidation() }
                if !formState.validationState.hasLocation {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    print("[EventFormView] Save button tapped for event: \(event?.id ?? "new")")
                    let event = Event(
                        id: self.event?.id ?? "",
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                        startDate: startDate,
                        endDate: endDate,
                        location: location.trimmingCharacters(in: .whitespacesAndNewlines),
                        locationUrl: locationUrl.isEmpty ? nil : locationUrl.trimmingCharacters(in: .whitespacesAndNewlines),
                        recurrenceType: recurrenceType,
                        parentEventId: self.event?.parentEventId,
                        createdAt: self.event?.createdAt ?? Date(),
                        updatedAt: Date(),
                        createdBy: self.event?.createdBy,
                        updatedBy: Auth.auth().currentUser?.uid ?? "",
                        isPublished: self.event?.isPublished ?? false,
                        isDeleted: self.event?.isDeleted ?? false
                    )
                    
                    print("[EventFormView] Created event object, calling onSave")
                    onSave(event)
                }
                .disabled(!formState.validationState.isValid)
            }
        }
        .onAppear {
            updateValidation()
        }
    }
    
    private func updateValidation() {
        formState.validationState = EventValidationState(
            hasStartDate: true,
            hasEndDate: true,
            hasTitle: !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasLocation: !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            isEndDateAfterStart: endDate > startDate
        )
    }
}

@MainActor
class EventFormState: ObservableObject {
    @Published var validationState = EventValidationState()
}

#Preview {
    EventFormView(event: nil, validationState: EventValidationState(), onSave: { _ in })
}
