import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Header with dismiss button
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .padding()
                    
                    Spacer()
                }
                
                // Image if available
                if let imageURL = event.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                            .frame(height: 200)
                    }
                }
                
                VStack(alignment: .center, spacing: 16) {
                    // Title and tags
                    Text(event.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        Text(event.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                        
                        if event.reoccuring != .none {
                            Text(event.reoccuring.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Date and location
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "calendar")
                            Text(event.formattedDateTime)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        if event.hasLocation {
                            Button {
                                Task {
                                    await event.openInMaps()
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                    Text(event.displayLocation)
                                        .multilineTextAlignment(.center)
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Description
                    if !event.plainDescription.isEmpty {
                        let lines = event.plainDescription.components(separatedBy: .newlines)
                        VStack(alignment: .center, spacing: 4) {
                            ForEach(lines, id: \.self) { line in
                                if line.starts(with: "📞") {
                                    Button {
                                        Task {
                                             event.callPhone()
                                        }
                                    } label: {
                                        Text(line)
                                            .font(.body)
                                            .multilineTextAlignment(.center)
                                            .foregroundStyle(.blue)
                                    }
                                } else {
                                    Text(line)
                                        .font(.body)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                    }
                    
                    // Add to Calendar button
                    Button {
                        Task {
                            await event.addToCalendar { success, error in
                                if success {
                                    alertTitle = "Success"
                                    alertMessage = "Event has been added to your calendar"
                                } else {
                                    alertTitle = "Error"
                                    alertMessage = error?.localizedDescription ?? "Failed to add event to calendar"
                                }
                                showingAlert = true
                            }
                        }
                    } label: {
                        Label("Add to Calendar", systemImage: "calendar.badge.plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemBackground))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
} 
