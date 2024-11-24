import SwiftUI

struct EventView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    let event: CalendarEvent
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(event.title)
                        .font(.title)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .fontWeight(.bold)
                    
                    Text(event.formattedDate)
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .foregroundColor(.secondary)
                    
                    if !event.location.isEmpty {
                        Text(event.location)
                            .font(.headline)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .foregroundColor(.secondary)
                    }
                    
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.body)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    }
                }
                .padding()
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
