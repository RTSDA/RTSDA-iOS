import SwiftUI

struct AddEventView: View {
    @ObservedObject var viewModel: EventsViewModel
    @Environment(\.dismiss) private var dismiss
    
    let eventToEdit: Event?
    
    @State private var title = ""
    @State private var description = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour later by default
    @State private var location = ""
    @State private var locationURL = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var recurrenceType: RecurrenceType = .none
    @State private var isPublished = true
    
    init(viewModel: EventsViewModel, eventToEdit: Event? = nil) {
        self.viewModel = viewModel
        self.eventToEdit = eventToEdit
        
        // Initialize state properties if editing
        if let event = eventToEdit {
            _title = State(initialValue: event.title)
            _description = State(initialValue: event.description)
            _startDate = State(initialValue: event.startDate)
            _endDate = State(initialValue: event.endDate)
            _location = State(initialValue: event.location ?? "")
            _locationURL = State(initialValue: event.locationURL ?? "")
            _recurrenceType = State(initialValue: event.recurrenceType)
            _isPublished = State(initialValue: event.isPublished)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Event Details")) {
                TextField("Title", text: $title)
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...6)
                
                DatePicker("Start", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section(header: Text("Location")) {
                TextField("Location Address", text: $location)
                TextField("Location URL", text: $locationURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            Section(header: Text("Settings")) {
                Picker("Recurrence", selection: $recurrenceType) {
                    Text("None").tag(RecurrenceType.none)
                    Text("Recurring").tag(RecurrenceType.recurring)
                    Text("Bi-Weekly").tag(RecurrenceType.biweekly)
                    Text("First Tuesday").tag(RecurrenceType.firstTuesday)
                }
                
                Toggle("Published", isOn: $isPublished)
            }
            
            Section {
                Button(action: saveEvent) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(eventToEdit != nil ? "Update Event" : "Save Event")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(title.isEmpty || description.isEmpty || isLoading || endDate <= startDate)
            }
        }
        .navigationTitle(eventToEdit != nil ? "Edit Event" : "Add Event")
        .navigationBarItems(trailing: Button("Cancel") {
            dismiss()
        })
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveEvent() {
        isLoading = true
        
        let event = Event(
            id: eventToEdit?.id ?? UUID().uuidString,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            location: location.isEmpty ? nil : location,
            locationURL: locationURL.isEmpty ? nil : locationURL,
            recurrenceType: recurrenceType,
            isPublished: isPublished
        )
        
        Task {
            do {
                if eventToEdit != nil {
                    try await viewModel.updateEvent(event)
                } else {
                    try await viewModel.addEvent(event)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
