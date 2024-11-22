import SwiftUI
import FirebaseFirestore

struct EventFormView: View {
    let event: CalendarEvent?
    let onSave: (CalendarEvent) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(3600) // 1 hour default duration
    @State private var recurrenceType = RecurrenceType.none
    
    private let recurrenceTypes = RecurrenceType.allCases
    private let calendar: Calendar = {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current
        return calendar
    }()
    
    private var dateRange: ClosedRange<Date> {
        let start = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let end = calendar.date(byAdding: .year, value: 2, to: Date()) ?? Date()
        return start...end
    }
    
    private var endDateRange: ClosedRange<Date> {
        let start = startDate
        let end = calendar.date(byAdding: .year, value: 2, to: startDate) ?? startDate.addingTimeInterval(3600 * 24 * 365 * 2)
        return start...end
    }
    
    init(event: CalendarEvent? = nil, onSave: @escaping (CalendarEvent) -> Void) {
        self.event = event
        self.onSave = onSave
        
        if let event = event {
            _title = State(initialValue: event.title)
            _description = State(initialValue: event.description)
            _location = State(initialValue: event.location)
            _startDate = State(initialValue: event.startDateTime)
            _endDate = State(initialValue: event.endDateTime)
            _recurrenceType = State(initialValue: event.recurrenceType)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("Date & Time")) {
                    DatePicker("Start", 
                              selection: $startDate,
                              in: dateRange,
                              displayedComponents: [.date, .hourAndMinute])
                        .modifier(DateChangeModifier(
                            date: startDate,
                            onChange: { newValue in
                                if endDate < newValue {
                                    endDate = newValue.addingTimeInterval(3600)
                                }
                                // Ensure end date is within the allowed range from start date
                                if let maxEndDate = calendar.date(byAdding: .year, value: 2, to: newValue),
                                   endDate > maxEndDate {
                                    endDate = maxEndDate
                                }
                            }
                        ))
                    
                    DatePicker("End",
                              selection: $endDate,
                              in: endDateRange,
                              displayedComponents: [.date, .hourAndMinute])
                        .modifier(DateChangeModifier(
                            date: endDate,
                            onChange: { newValue in
                                if newValue < startDate {
                                    startDate = newValue.addingTimeInterval(-3600)
                                }
                            }
                        ))
                }
                
                Section(header: Text("Recurrence")) {
                    Picker("Recurrence", selection: $recurrenceType) {
                        ForEach(recurrenceTypes, id: \.self) { type in
                            Text(type.rawValue.lowercased().capitalized)
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
                        let newEvent = CalendarEvent(
                            id: event?.id ?? "",
                            title: title,
                            description: description,
                            location: location,
                            startDate: startDate.timeIntervalSince1970,
                            endDate: endDate.timeIntervalSince1970,
                            recurrenceType: recurrenceType
                        )
                        onSave(newEvent)
                        dismiss()
                    }
                    .disabled(title.isEmpty || endDate <= startDate)
                }
            }
        }
    }
}

struct DateChangeModifier: ViewModifier {
    let date: Date
    let onChange: (Date) -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: date) { oldValue, newValue in
                onChange(newValue)
            }
        } else {
            content.onChange(of: date) { newValue in
                onChange(newValue)
            }
        }
    }
}