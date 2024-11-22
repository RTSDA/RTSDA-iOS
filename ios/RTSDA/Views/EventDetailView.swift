import SwiftUI
import EventKit

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss
    @State private var showError = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(event.title)
                        .font(.title)
                        .bold()
                    
                    Text(event.description)
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        if let locationUrl = event.locationUrl, let url = URL(string: locationUrl) {
                            Button(action: {
                                UIApplication.shared.open(url)
                            }) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                    Text(event.location)
                                        .foregroundColor(.blue)
                                }
                            }
                        } else {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                Text(event.location)
                            }
                        }
                        
                        HStack {
                            Image(systemName: "calendar")
                            VStack(alignment: .leading) {
                                Text(dateFormatter.string(from: event.startDate))
                                if let endDate = event.endDate, endDate != event.startDate {
                                    Text(dateFormatter.string(from: endDate))
                                }
                            }
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    Button(action: {
                        Task {
                            do {
                                try await event.addToCalendar()
                                showSuccess = true
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to Calendar")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Event added to your calendar")
            }
        }
    }
}
