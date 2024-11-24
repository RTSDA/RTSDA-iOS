import SwiftUI

struct AdminEventRow: View {
    let event: Event
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onPublish: () -> Void
    let onUnpublish: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(event.title)
                    .font(.headline)
                Spacer()
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if event.isPublished {
                        Button(action: onUnpublish) {
                            Label("Unpublish", systemImage: "eye.slash")
                        }
                    } else {
                        Button(action: onPublish) {
                            Label("Publish", systemImage: "eye")
                        }
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                }
            }
            
            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack(spacing: 16) {
                Label(event.startDate.formatted(date: .abbreviated, time: .shortened),
                      systemImage: "calendar")
                    .font(.caption)
                
                if !event.location.isEmpty {
                    Label(event.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                }
                
                Spacer()
                
                if event.isPublished {
                    Label("Published", systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
