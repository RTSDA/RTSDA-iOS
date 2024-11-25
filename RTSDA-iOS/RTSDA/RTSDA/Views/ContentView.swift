import SwiftUI
import YouTubePlayerKit
import SafariServices

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            NavigationStack {
                BulletinView()
            }
            .tabItem {
                Label("Bulletin", systemImage: "newspaper")
            }
            
            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "video.and.waveform.fill")
                }
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
        }
        .accentColor(Color(hex: "fb8b23"))
    }
}

// MARK: - Constants
enum ChurchContact {
    static let email = "info@rockvilletollandsda.org"
    static var emailUrl: String {
        "mailto:\(email)"
    }
    static let phone = "860-875-0450"
    static var phoneUrl: String {
        "tel://\(phone.replacingOccurrences(of: "-", with: ""))"
    }
}

struct HomeView: View {
    @State private var scrollTarget: ScrollTarget?
    @State private var showingSafariView = false
    @State private var safariURL: URL?
    
    enum ScrollTarget {
        case serviceTimes
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Image Section
                        ZStack(alignment: .bottom) {
                            Image("church_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                            
                            // Gradient overlay
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 150)
                        }
                        
                        // Quick Links Section
                        VStack(spacing: 24) {
                            Text("Quick Links")
                                .font(.custom("Montserrat-Bold", size: 24))
                                .padding(.top)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                QuickLinkButton(
                                    title: "Service Times",
                                    icon: "clock.fill",
                                    color: Color(hex: "fb8b23")
                                ) {
                                    withAnimation {
                                        scrollTarget = .serviceTimes
                                    }
                                }
                                
                                QuickLinkButton(
                                    title: "Directions",
                                    icon: "location.fill",
                                    color: Color(hex: "fb8b23")
                                ) {
                                    if let url = URL(string: "https://maps.apple.com/?address=9+Hartford+Turnpike,+Tolland,+CT+06084") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                
                                QuickLinkButton(
                                    title: "Contact Us",
                                    icon: "envelope.fill",
                                    color: Color(hex: "fb8b23")
                                ) {
                                    if let url = URL(string: ChurchContact.emailUrl) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                
                                QuickLinkButton(
                                    title: "Give Online",
                                    icon: "heart.fill",
                                    color: Color(hex: "fb8b23")
                                ) {
                                    if let url = URL(string: "https://adventistgiving.org/donate/AN4MJG") {
                                        safariURL = url
                                        showingSafariView = true
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About Us")
                                .font(.custom("Montserrat-Bold", size: 24))
                            
                            Text("We are a vibrant, welcoming Seventh-day Adventist church community located in Tolland, Connecticut. Our mission is to share God's love through worship, fellowship, and service.")
                                .font(.custom("Montserrat-Regular", size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Service Times
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Service Times")
                                    .font(.custom("Montserrat-SemiBold", size: 20))
                                    .padding(.top, 8)
                                    .id(ScrollTarget.serviceTimes)
                                
                                ServiceTimeRow(day: "Saturday", time: "9:15 AM", name: "Sabbath School")
                                ServiceTimeRow(day: "Saturday", time: "11:00 AM", name: "Worship Service")
                                
                                Text("Join us for worship!")
                                    .font(.custom("Montserrat-Regular", size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                    }
                }
                .onChange(of: scrollTarget) { oldValue, newValue in
                    if let target = newValue {
                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
                        }
                        // Reset after scrolling
                        scrollTarget = nil
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Image("church_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingSafariView) {
            if let url = safariURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

struct QuickLinkButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.custom("Montserrat-SemiBold", size: 14))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct ServiceTimeRow: View {
    let day: String
    let time: String
    let name: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(day)
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(.secondary)
                Text(time)
                    .font(.custom("Montserrat-SemiBold", size: 16))
            }
            
            Spacer()
            
            Text(name)
                .font(.custom("Montserrat-Regular", size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct EventsView: View {
    @StateObject private var viewModel = EventsViewModel()
    
    var body: some View {
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
        .padding(.horizontal)
        .padding(.vertical, 6)
        .onTapGesture {
            // Handle tap gesture
        }
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
}

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var selectedMessage: Message?
    
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
                        Text("Error loading messages")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Try Again") {
                            viewModel.refreshContent()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.messages.isEmpty && viewModel.livestream == nil {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Messages Available")
                            .font(.headline)
                        Text("Check back later for new messages")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let livestream = viewModel.livestream {
                                LivestreamCard(message: livestream, selectedMessage: $selectedMessage)
                                    .padding(.horizontal)
                            }
                            
                            ForEach(viewModel.messages) { message in
                                MessageCard(message: message, selectedMessage: $selectedMessage)
                                    .padding(.horizontal)
                            }
                            
                            // Media Links Row
                            HStack(spacing: 16) {
                                // YouTube Channel Link Button
                                Link(destination: URL(string: YouTubeService.channelUrl)!) {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "play.rectangle.fill")
                                                .foregroundColor(.red)
                                            Text("YouTube")
                                                .foregroundColor(.primary)
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Spotify Channel Link Button
                                Button {
                                    AppAvailabilityService.shared.openApp(
                                        urlScheme: AppAvailabilityService.schemes.spotify,
                                        fallbackURL: "https://open.spotify.com/show/2ARQaUBaGnVTiF9syrKDvO"
                                    )
                                } label: {
                                    VStack(spacing: 8) {
                                        HStack {
                                            Image(systemName: "headphones")
                                                .foregroundColor(.green)
                                            Text("Spotify")
                                                .foregroundColor(.primary)
                                        }
                                        .padding()
                                        .background(Color(.systemBackground))
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                // Apple Podcasts Link Button
                                Button {
                                    AppAvailabilityService.shared.openApp(
                                        urlScheme: AppAvailabilityService.schemes.podcasts,
                                        fallbackURL: "https://podcasts.apple.com/us/podcast/rockville-tolland-sda-church/id1630777684"
                                    )
                                } label: {
                                    Label("Apple Podcasts", systemImage: "mic.circle.fill")
                                        .labelStyle(.iconOnly)
                                        .foregroundColor(Color(red: 0.6, green: 0.25, blue: 0.98))  // Apple Podcasts purple
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        viewModel.refreshContent()
                    }
                }
            }
            .navigationTitle("Messages")
        }
    }
    
    private func extractVideoId(from url: String) -> String? {
        guard let url = URL(string: url) else { return nil }
        
        if url.host == "youtu.be" {
            return url.lastPathComponent
        }
        
        if url.host?.contains("youtube.com") == true,
           let videoId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first(where: { $0.name == "v" })?
            .value {
            return videoId
        }
        
        return nil
    }
}

struct MessageCard: View {
    let message: Message
    @Binding var selectedMessage: Message?
    
    var body: some View {
        VStack(spacing: 0) {
            // Video Player Section
            if selectedMessage?.id == message.id,
               let videoId = extractVideoId(from: message.videoUrl) {
                YouTubePlayerSwiftUIView(player: YouTubePlayer(
                    source: .video(id: videoId),
                    configuration: .init(
                        autoPlay: true
                    )
                ))
                .frame(height: 250)
                .cornerRadius(12)
            } else {
                // Thumbnail Section
                if let thumbnailUrl = message.thumbnailUrl,
                   let url = URL(string: thumbnailUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .frame(height: 200)
                    .clipped()
                }
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if message.isLiveStream {
                        Text(message.liveBroadcastStatus.uppercased())
                            .font(.custom("Montserrat-Bold", size: 12))
                            .foregroundColor(message.liveBroadcastStatus == "live" ? .red : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(message.liveBroadcastStatus == "live" ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    if !message.isLiveStream {
                        Text(message.formattedDuration)
                            .font(.custom("Montserrat-Regular", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(message.title)
                    .font(.custom("Montserrat-SemiBold", size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
        .padding(.horizontal)
        .padding(.vertical, 6)
        .onTapGesture {
            if selectedMessage?.id == message.id {
                selectedMessage = nil
            } else {
                selectedMessage = message
            }
        }
    }
    
    private func extractVideoId(from url: String) -> String? {
        guard let url = URL(string: url) else { return nil }
        
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            return queryItems.first(where: { $0.name == "v" })?.value
        }
        
        // If no query items, try to get it from the path
        let pathComponents = url.pathComponents
        if pathComponents.count > 1 {
            return pathComponents.last
        }
        
        return nil
    }
}

struct LivestreamCard: View {
    let message: Message
    @Binding var selectedMessage: Message?
    
    var body: some View {
        MessageCard(message: message, selectedMessage: $selectedMessage)
    }
}

struct MoreView: View {
    @State private var showingSafariView = false
    @State private var safariURL: URL?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Resources") {
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.schemes.bible,
                            fallbackURL: AppAvailabilityService.appStoreURLs.bible
                        )
                    } label: {
                        Label("Bible", systemImage: "book.fill")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.schemes.sabbathSchool,
                            fallbackURL: AppAvailabilityService.appStoreURLs.sabbathSchool
                        )
                    } label: {
                        Label("Sabbath School", systemImage: "book.fill")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.schemes.egwWritings,
                            fallbackURL: AppAvailabilityService.appStoreURLs.egwWritings
                        )
                    } label: {
                        Label("EGW Writings", systemImage: "book.closed.fill")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.schemes.hymnal,
                            fallbackURL: AppAvailabilityService.appStoreURLs.hymnal
                        )
                    } label: {
                        Label("SDA Hymnal", systemImage: "music.note")
                            .overlay(alignment: .trailing) {
                                Text("Coming Soon")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                    }
                    .disabled(true)
                }
                
                Section("Connect") {
                    NavigationLink {
                        PrayerRequestView()
                    } label: {
                        Label("Prayer Request", systemImage: "hands.sparkles.fill")
                    }
                    
                    Link(destination: URL(string: ChurchContact.emailUrl)!) {
                        Label("Email Us", systemImage: "envelope.fill")
                    }
                    
                    Link(destination: URL(string: ChurchContact.phoneUrl)!) {
                        Label("Call Us", systemImage: "phone.fill")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.schemes.facebook,
                            fallbackURL: "https://www.facebook.com/rockvilletollandsda"
                        )
                    } label: {
                        Label("Facebook", systemImage: "link")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.schemes.tiktok,
                            fallbackURL: "https://www.tiktok.com/@rockvilletollandsda"
                        )
                    } label: {
                        Label("TikTok", systemImage: "play.square")
                    }
                    
                    Link(destination: URL(string: "https://maps.apple.com/?address=9+Hartford+Turnpike,+Tolland,+CT+06084")!) {
                        Label("Directions", systemImage: "map.fill")
                    }
                }
                
                Section("About") {
                    NavigationLink {
                        BeliefsView()
                    } label: {
                        Label("Our Beliefs", systemImage: "heart.text.square.fill")
                    }
                }
                
                Section("App Info") {
                    HStack {
                        Label("Version", systemImage: "info.circle.fill")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("More")
        }
        .sheet(isPresented: $showingSafariView) {
            if let url = safariURL {
                SafariView(url: url)
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let controller = SFSafariViewController(url: url, configuration: config)
        controller.preferredControlTintColor = UIColor(named: "AccentColor")
        controller.dismissButtonStyle = .done
        return controller
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

struct YouTubePlayerSwiftUIView: UIViewControllerRepresentable {
    let player: YouTubePlayer
    
    func makeUIViewController(context: Context) -> YouTubePlayerViewController {
        YouTubePlayerViewController(player: player)
    }
    
    func updateUIViewController(_ uiViewController: YouTubePlayerViewController, context: Context) {
        // Update the view controller if needed
    }
}

extension UIApplication {
    var scrollView: UIScrollView? {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.rootViewController?.view.subviews.first { $0 is UIScrollView } as? UIScrollView
        }
        return nil
    }
}

#Preview {
    ContentView()
}
