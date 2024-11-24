import SwiftUI

struct AdminEventRow: View {
    let event: CalendarEvent
    @StateObject private var viewModel: AdminEventViewModel
    
    init(event: CalendarEvent, viewModel: AdminEventViewModel) {
        self.event = event
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.title3)
                .fontWeight(.semibold)
                .lineLimit(2)
            
            if !event.description.isEmpty {
                Text(event.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .redacted(reason: viewModel.loadingStates[event.id] ?? false ? .placeholder : [])
            }
            
            if !event.location.isEmpty {
                Label {
                    Text(event.location)
                        .lineLimit(1)
                        .redacted(reason: viewModel.loadingStates[event.id] ?? false ? .placeholder : [])
                } icon: {
                    Image(systemName: "location")
                        .foregroundColor(.secondary)
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                Label {
                    Text(dateFormatter.string(from: event.startDateTime))
                        .redacted(reason: viewModel.loadingStates[event.id] ?? false ? .placeholder : [])
                } icon: {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                }
                .font(.callout)
                
                if event.recurrenceType != .none {
                    Label {
                        Text(event.recurrenceType.displayString)
                            .redacted(reason: viewModel.loadingStates[event.id] ?? false ? .placeholder : [])
                    } icon: {
                        Image(systemName: "repeat")
                            .foregroundColor(.blue)
                    }
                    .font(.callout)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .task(id: event.id) {
            if viewModel.loadingStates[event.id] ?? false {
                _ = await viewModel.getEvent(event.id)
            }
        }
    }
}