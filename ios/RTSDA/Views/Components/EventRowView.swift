import SwiftUI

struct EventRowView: View {
    let event: Event
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sizeCategory) private var sizeCategory
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    
                    if !event.description.isEmpty {
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if event.recurrenceType != .none {
                    Image(systemName: "repeat")
                        .imageScale(.medium)
                        .foregroundColor(.accentColor)
                }
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .imageScale(.medium)
                    Group {
                        Text(dateFormatter.string(from: event.startDate))
                        if let endDate = event.endDate, endDate != event.startDate {
                            Text(" - ")
                            Text(dateFormatter.string(from: endDate))
                        }
                    }
                    .font(.caption)
                }
                .foregroundColor(.secondary)
                
                if !event.location.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .imageScale(.medium)
                        Text(event.location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(color: Color(.systemGray4).opacity(0.5), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}