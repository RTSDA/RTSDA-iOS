import SwiftUI

struct AdminEventRow: View {
    let event: Event
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onPublish: () -> Void
    let onUnpublish: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                Text(event.formattedStartDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if !event.location.isEmpty {
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if event.isPublished {
                    Text("Published")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                } else {
                    Text("Draft")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
                
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
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                        .padding(8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
