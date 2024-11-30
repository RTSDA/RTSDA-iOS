import SwiftUI
import YouTubePlayerKit
import SafariServices

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            BulletinView()
                .tabItem {
                    Label("Bulletin", systemImage: "newspaper.fill")
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
                    Label("Messages", systemImage: "video.fill")
                }
                .tag(3)
            
            MoreView()
                .environmentObject(authService)
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(4)
            
            if authService.isAuthenticated {
                AdminDashboardView()
                    .environmentObject(authService)
                    .tabItem {
                        Label("Admin", systemImage: "lock.shield")
                    }
                    .tag(5)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            authService.checkAuthState()
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                selectedTab = 5
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

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    @State private var selectedMessage: Message?
    @State private var hasInitiallyLoaded = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && !hasInitiallyLoaded {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if let error = viewModel.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        Text(error.localizedDescription)
                            .font(.custom("Montserrat-Regular", size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let livestream = viewModel.livestream {
                                LivestreamCard(message: livestream, selectedMessage: $selectedMessage)
                                    .padding(.horizontal)
                            }
                            
                            VStack(spacing: 12) {
                                Text("Listen & Watch")
                                    .font(.custom("Montserrat-SemiBold", size: 16))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.messages) { message in
                                    MessageCard(message: message, selectedMessage: $selectedMessage)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                            
                            // Media Links Row
                            VStack(spacing: 12) {
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
                                            urlScheme: AppAvailabilityService.Schemes.spotify,
                                            fallbackURL: AppAvailabilityService.AppStoreURLs.spotify
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
                                            urlScheme: AppAvailabilityService.Schemes.podcasts,
                                            fallbackURL: AppAvailabilityService.AppStoreURLs.podcasts
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
                    }
                    .refreshable {
                        selectedMessage = nil
                        await viewModel.refreshContent()
                        if !hasInitiallyLoaded {
                            hasInitiallyLoaded = true
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                Task {
                    await viewModel.refreshContent()
                    hasInitiallyLoaded = true
                }
            }
        }
    }
}

struct YouTubePlayerView: View {
    let videoId: String
    
    var body: some View {
        YouTubePlayerKit.YouTubePlayerView(
            YouTubePlayer(
                source: .video(id: videoId),
                configuration: .init(
                    autoPlay: true
                )
            )
        )
    }
}

struct MessageCard: View {
    let message: Message
    @Binding var selectedMessage: Message?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let videoId = message.videoUrl.extractYouTubeVideoId() {
                if selectedMessage?.id == message.id {
                    YouTubePlayerView(videoId: videoId)
                        .frame(height: 200)
                        .cornerRadius(8)
                } else {
                    AsyncImage(url: URL(string: message.thumbnailUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(height: 200)
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedMessage = message
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.custom("Montserrat-SemiBold", size: 16))
                    .foregroundColor(.primary)
                
                Text(message.speaker)
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
                    Link(destination: URL(string: AppAvailabilityService.Schemes.bible)!) {
                        Label("Bible", systemImage: "book.fill")
                    }
                    
                    Link(destination: URL(string: AppAvailabilityService.Schemes.sabbathSchool)!) {
                        Label("Sabbath School", systemImage: "book.fill")
                    }
                    
                    Link(destination: URL(string: AppAvailabilityService.Schemes.egw)!) {
                        Label("EGW Writings", systemImage: "book.closed.fill")
                    }
                    
                    Link(destination: URL(string: AppAvailabilityService.Schemes.hymnal)!) {
                        Label("SDA Hymnal", systemImage: "music.note")
                    }
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
                            urlScheme: AppAvailabilityService.Schemes.tiktok,
                            fallbackURL: AppAvailabilityService.AppStoreURLs.tiktok
                        )
                    } label: {
                        Label("TikTok", systemImage: "play.rectangle.fill")
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

extension String {
    func extractYouTubeVideoId() -> String? {
        guard let url = URL(string: self) else { return nil }
        
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

#Preview {
    ContentView()
}
