import SwiftUI

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error loading events")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Try Again") {
                            Task {
                                await viewModel.loadEvents()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Upcoming Events")
                            .font(.headline)
                        Text("Check back later for new events")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.events) { event in
                                EventCard(event: event)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .refreshable {
                        Task {
                            await viewModel.loadEvents()
                        }
                    }
                }
            }
            .navigationTitle("Events")
            .onAppear {
                Task {
                    await viewModel.loadEvents()
                }
            }
        }
    }
}

struct EventCard: View {
    let event: Event
    @State private var showingCalendarAlert = false
    @State private var calendarError: Error?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Title and Recurring Badge
            HStack {
                Text(event.title)
                    .font(.custom("Montserrat-SemiBold", size: 18))
                    .foregroundColor(.primary)
                
                if event.recurrenceType != .none {
                    Image(systemName: "repeat")
                        .foregroundColor(Color(hex: "fb8b23"))
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                // Add to Calendar Button
                Button(action: {
                    event.addToCalendar { success, error in
                        DispatchQueue.main.async {
                            if success {
                                showingCalendarAlert = true
                            } else {
                                calendarError = error
                                showingCalendarAlert = true
                            }
                        }
                    }
                }) {
                    Image(systemName: "calendar.badge.plus")
                        .foregroundColor(Color(hex: "fb8b23"))
                        .font(.system(size: 18))
                }
            }
            
            // Date and Time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "fb8b23"))
                Text(event.formattedDateTime)
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(.secondary)
            }
            
            // Location if available
            if event.hasLocation || event.hasLocationUrl {
                if event.hasLocationUrl {
                    Button(action: {
                        event.openInMaps()
                    }) {
                        LocationRow(location: event.displayLocation, isClickable: true)
                    }
                } else {
                    LocationRow(location: event.displayLocation, isClickable: false)
                }
            }
            
            // Description
            if !event.description.isEmpty {
                Text(event.description)
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // Registration Button if required
            if event.registrationRequired {
                Button(action: {
                    // Handle registration
                    if let url = event.registrationURL,
                       let registrationURL = URL(string: url) {
                        UIApplication.shared.open(registrationURL)
                    }
                }) {
                    Text("Register")
                        .font(.custom("Montserrat-SemiBold", size: 14))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "fb8b23"))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .alert(isPresented: $showingCalendarAlert) {
            if let error = calendarError {
                Alert(
                    title: Text("Error"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("OK"))
                )
            } else {
                Alert(
                    title: Text("Success"),
                    message: Text("Event has been added to your calendar."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct LocationRow: View {
    let location: String
    var isClickable: Bool = true
    
    var body: some View {
        Button(action: {
            if isClickable {
                if let url = URL(string: "https://maps.apple.com/?address=9+Hartford+Turnpike,+Tolland,+CT+06084") {
                    UIApplication.shared.open(url)
                }
            }
        }) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(isClickable ? .accentColor : .secondary)
                Text(location)
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(isClickable ? .primary : .secondary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isClickable {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isClickable ? Color(hex: "fb8b23").opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isClickable)
    }
}

#Preview {
    EventsView()
        .environmentObject(AuthenticationService())
}
