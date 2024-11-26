import SwiftUI
import YouTubePlayerKit
import SafariServices

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            if horizontalSizeClass == .compact {
                NavigationView {
                    mainContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else {
                NavigationView {
                    mainContent
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
    }
    
    private var mainContent: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            NavigationStack {
                BulletinView()
            }
            .tabItem {
                Label("Bulletin", systemImage: "newspaper")
            }
            .tag(1)
            
            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            .tag(2)
            
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "video.and.waveform.fill")
                }
                .tag(3)
            
            if authService.isAuthenticated {
                AdminDashboardView()
                    .environmentObject(authService)
                    .tabItem {
                        Label("Admin", systemImage: "lock.shield")
                    }
                    .tag(4)
            }
            
            MoreView()
                .environmentObject(authService)
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(5)
        }
        .navigationBarHidden(true)
        .onAppear {
            authService.checkAuthState()
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                selectedTab = 4
            }
        }
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
    static let facebook = "https://www.facebook.com/rockvilletollandsdachurch/"
}

struct HomeView: View {
    @State private var scrollTarget: ScrollTarget?
    @State private var showingSafariView = false
    @State private var safariURL: URL?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    enum ScrollTarget {
        case serviceTimes
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Image Section
                        Image("church_hero")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: horizontalSizeClass == .compact ? 300 : geometry.size.height * 0.3)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Content Section
                        if horizontalSizeClass == .compact {
                            VStack(spacing: 16) {
                                quickLinksSection
                                aboutUsSection
                            }
                            .padding()
                        } else {
                            HStack(alignment: .top, spacing: 16) {
                                quickLinksSection
                                    .frame(maxWidth: geometry.size.width * 0.4)
                                aboutUsSection
                            }
                            .padding()
                        }
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .onChange(of: scrollTarget) { _, target in
                    if let target {
                        withAnimation {
                            proxy.scrollTo(target, anchor: .top)
                        }
                        scrollTarget = nil
                    }
                }
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image("church_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showingSafariView) {
            if let url = safariURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .compact ? 16 : 8) {
            Text("Quick Links")
                .font(.custom("Montserrat-Bold", size: horizontalSizeClass == .compact ? 24 : 20))
            
            quickLinksGrid
        }
    }
    
    private var quickLinksGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: horizontalSizeClass == .compact ? 16 : 8),
                GridItem(.flexible(), spacing: horizontalSizeClass == .compact ? 16 : 8)
            ],
            spacing: horizontalSizeClass == .compact ? 16 : 8
        ) {
            QuickLinkButton(title: "Prayer Request", icon: "hands.sparkles.fill") {
                let prayerRequestView = PrayerRequestView()
                let hostingController = UIHostingController(rootView: prayerRequestView)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    rootViewController.present(hostingController, animated: true)
                }
            }
            
            QuickLinkButton(title: "Directions", icon: "location.fill") {
                if let url = URL(string: "https://maps.apple.com/?address=9+Hartford+Turnpike,+Tolland,+CT+06084") {
                    UIApplication.shared.open(url)
                }
            }
            
            QuickLinkButton(title: "Contact Us", icon: "envelope.fill") {
                if let url = URL(string: ChurchContact.emailUrl) {
                    UIApplication.shared.open(url)
                }
            }
            
            QuickLinkButton(title: "Give Online", icon: "heart.fill") {
                if let url = URL(string: "https://adventistgiving.org/donate/AN4MJG") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    private var aboutUsSection: some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .compact ? 16 : 8) {
            Text("About Us")
                .font(.custom("Montserrat-Bold", size: horizontalSizeClass == .compact ? 24 : 20))
            
            aboutUsContent
        }
    }
    
    private var aboutUsContent: some View {
        VStack(alignment: .leading, spacing: horizontalSizeClass == .compact ? 16 : 8) {
            Text("We are a vibrant, welcoming Seventh-day Adventist church community located in Tolland, Connecticut. Our mission is to share God's love through worship, fellowship, and service.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Service Times")
                    .font(.custom("Montserrat-Bold", size: 20))
                    .id(ScrollTarget.serviceTimes)
                
                VStack(spacing: 12) {
                    ServiceTimeRow(day: "Saturday", time: "9:15 AM", name: "Sabbath School")
                    ServiceTimeRow(day: "Saturday", time: "11:00 AM", name: "Worship Service")
                    ServiceTimeRow(day: "Wednesday", time: "6:30 PM", name: "Prayer Meeting")
                }
            }
        }
    }
}

struct QuickLinkButton: View {
    let title: String
    let icon: String
    var color: Color = Color(hex: "fb8b23")
    var action: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(title)
                .font(.custom("Montserrat-Medium", size: 14))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture(perform: action)
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
                            VStack(spacing: 12) {
                                Text("Listen & Watch")
                                    .font(.custom("Montserrat-SemiBold", size: 16))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                HStack(spacing: 8) {
                                    // YouTube Channel Link Button
                                    Link(destination: URL(string: YouTubeService.channelUrl)!) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "play.rectangle.fill")
                                                .foregroundColor(.red)
                                            Text("YouTube")
                                                .font(.custom("Montserrat-Medium", size: 14))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Spotify Channel Link Button
                                    Button {
                                        AppAvailabilityService.shared.openApp(
                                            urlScheme: AppAvailabilityService.schemes.spotify,
                                            fallbackURL: "https://open.spotify.com/show/2ARQaUBaGnVTiF9syrKDvO"
                                        )
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "headphones")
                                                .foregroundColor(.green)
                                            Text("Spotify")
                                                .font(.custom("Montserrat-Medium", size: 14))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    // Apple Podcasts Link Button
                                    Button {
                                        AppAvailabilityService.shared.openApp(
                                            urlScheme: AppAvailabilityService.schemes.podcasts,
                                            fallbackURL: "https://podcasts.apple.com/us/podcast/rockville-tolland-sda-church/id1234567890"
                                        )
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "waveform")
                                                .foregroundColor(.purple)
                                            Text("Podcasts")
                                                .font(.custom("Montserrat-Medium", size: 14))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.8)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
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
    @EnvironmentObject private var authService: AuthenticationService
    @State private var showingSafariView = false
    @State private var safariURL: URL?
    @State private var showingAdminLogin = false
    
    var body: some View {
        NavigationStack {
            List {
                if !authService.isAuthenticated {
                    Section("Admin") {
                        Button(action: {
                            showingAdminLogin = true
                        }) {
                            Label("Admin Login", systemImage: "lock.shield")
                        }
                    }
                }
                
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
                        HStack {
                            Label("SDA Hymnal", systemImage: "music.note")
                            Spacer()
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
                    
                    Link(destination: URL(string: "https://www.facebook.com/rockvilletollandsdachurch/")!) {
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
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("More")
        }
        .sheet(isPresented: $showingAdminLogin) {
            AdminLoginView()
        }
        .sheet(isPresented: $showingSafariView) {
            if let url = safariURL {
                SafariView(url: url)
                    .ignoresSafeArea()
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

enum NavigationDestination {
    case prayerRequest
}

#Preview {
    ContentView()
}
