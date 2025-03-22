import SwiftUI
import SafariServices
import AVKit

struct ContentView: View {
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
            
            NavigationStack {
                MessagesView()
            }
                .tabItem {
                    Label("Messages", systemImage: "video.fill")
                }
                .tag(3)
            
            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis")
                }
                .tag(4)
        }
        .navigationBarHidden(true)
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
    @State private var showSheet = false
    @State private var sheetContent: AnyView?
    @State private var showSuccessAlert = false
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
                        VStack(spacing: 0) {
                            Image("church_hero")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width)
                                .frame(height: horizontalSizeClass == .compact ? 350 : geometry.size.height * 0.45)
                                .offset(y: horizontalSizeClass == .compact ? 30 : 0)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .edgesIgnoringSafeArea(.top)
                        
                        // Content Section
                        if horizontalSizeClass == .compact {
                            VStack(spacing: 16) {
                                quickLinksSection
                                aboutUsSection
                            }
                            .padding()
                        } else {
                            HStack(alignment: .top, spacing: 32) {
                                VStack(alignment: .leading, spacing: 24) {
                                    quickLinksSection
                                        .frame(maxWidth: geometry.size.width * 0.35)
                                    
                                    Image("church_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: geometry.size.width * 0.25)
                                        .padding(.top, 24)
                                }
                                
                                aboutUsSection
                                    .padding(.top, 8)
                            }
                            .padding(32)
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
        .sheet(isPresented: $showSheet) {
            if let content = sheetContent {
                content
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thank you for your message! We'll get back to you soon.")
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
            QuickLinkButton(title: "Contact Us", icon: "envelope.fill") {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootViewController = window.rootViewController {
                    let contactFormView = ContactFormView(isModal: true)
                    let hostingController = UIHostingController(rootView: NavigationStack { contactFormView })
                    rootViewController.present(hostingController, animated: true)
                }
            }
            
            QuickLinkButton(title: "Directions", icon: "location.fill") {
                if let url = URL(string: "https://maps.apple.com/?address=9+Hartford+Turnpike,+Tolland,+CT+06084") {
                    UIApplication.shared.open(url)
                }
            }
            
            QuickLinkButton(title: "Call Us", icon: "phone.fill") {
                if let url = URL(string: ChurchContact.phoneUrl) {
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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: horizontalSizeClass == .compact ? 24 : 32))
                .foregroundColor(color)
            Text(title)
                .font(.custom("Montserrat-Medium", size: horizontalSizeClass == .compact ? 14 : 16))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(horizontalSizeClass == .compact ? 16 : 24)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .onTapGesture(perform: action)
    }
}

struct ServiceTimeRow: View {
    let day: String
    let time: String
    let name: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(day)
                    .font(.custom("Montserrat-Regular", size: horizontalSizeClass == .compact ? 14 : 16))
                    .foregroundColor(.secondary)
                Text(time)
                    .font(.custom("Montserrat-SemiBold", size: horizontalSizeClass == .compact ? 16 : 18))
            }
            
            Spacer()
            
            Text(name)
                .font(.custom("Montserrat-Regular", size: horizontalSizeClass == .compact ? 16 : 18))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, horizontalSizeClass == .compact ? 4 : 8)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Montserrat-Medium", size: 14))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

struct FilterSection: View {
    let title: String
    let items: [String]
    let selectedItem: String?
    let onSelect: (String?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.custom("Montserrat-SemiBold", size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if selectedItem != nil {
                    Button("Clear") {
                        onSelect(nil)
                    }
                    .font(.custom("Montserrat-Regular", size: 12))
                    .foregroundColor(.accentColor)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedItem == nil,
                        action: { onSelect(nil) }
                    )
                    
                    ForEach(items, id: \.self) { item in
                        FilterChip(
                            title: item,
                            isSelected: selectedItem == item,
                            action: { onSelect(item) }
                        )
                    }
                }
                .padding(.bottom, 4) // Extra padding for shadow
            }
        }
    }
}

struct FilterPicker: View {
    @Binding var selectedYear: String?
    @Binding var selectedMonth: String?
    @Binding var selectedMediaType: JellyfinService.MediaType
    let availableYears: [String]
    let availableMonths: [String]
    
    var body: some View {
        VStack(spacing: 16) {
            // Media Type Toggle
            Picker("Media Type", selection: $selectedMediaType) {
                Text("Sermons").tag(JellyfinService.MediaType.sermons)
                Text("Live Archives").tag(JellyfinService.MediaType.livestreams)
            }
            .pickerStyle(.segmented)
            
            // Filters
            VStack(spacing: 16) {
                FilterSection(
                    title: "YEAR",
                    items: availableYears,
                    selectedItem: selectedYear,
                    onSelect: { year in
                        selectedYear = year
                        selectedMonth = nil
                    }
                )
                
                if selectedYear != nil {
                    FilterSection(
                        title: "MONTH",
                        items: availableMonths,
                        selectedItem: selectedMonth,
                        onSelect: { month in
                            selectedMonth = month
                        }
                    )
                }
            }
            
            // Active Filters Summary
            if selectedYear != nil || selectedMonth != nil {
                HStack {
                    Text("Showing:")
                        .font(.custom("Montserrat-Regular", size: 12))
                        .foregroundColor(.secondary)
                    
                    if let month = selectedMonth {
                        Text(month)
                            .font(.custom("Montserrat-Medium", size: 12))
                    }
                    
                    if let year = selectedYear {
                        Text(year)
                            .font(.custom("Montserrat-Medium", size: 12))
                    }
                    
                    Spacer()
                    
                    Button("Clear All") {
                        selectedYear = nil
                        selectedMonth = nil
                    }
                    .font(.custom("Montserrat-Medium", size: 12))
                    .foregroundColor(.accentColor)
                }
                .padding(.top, -8)
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

struct MoreView: View {
    @State private var showingSafariView = false
    @State private var safariURL: URL?
    @State private var showSheet = false
    @State private var sheetContent: AnyView?
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Resources") {
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.Schemes.bible,
                            fallbackURL: AppAvailabilityService.AppStoreURLs.bible
                        )
                    } label: {
                        Label("Bible", systemImage: "book.fill")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.Schemes.sabbathSchool,
                            fallbackURL: AppAvailabilityService.AppStoreURLs.sabbathSchool
                        )
                    } label: {
                        Label("Sabbath School", systemImage: "book.fill")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.Schemes.egw,
                            fallbackURL: AppAvailabilityService.AppStoreURLs.egwWritings
                        )
                    } label: {
                        Label("EGW Writings", systemImage: "book.closed.fill")
                    }
                    
                    Button {
                        AppAvailabilityService.shared.openApp(
                            urlScheme: AppAvailabilityService.Schemes.hymnal,
                            fallbackURL: AppAvailabilityService.AppStoreURLs.hymnal
                        )
                    } label: {
                        Label("SDA Hymnal", systemImage: "music.note")
                    }
                }
                
                Section("Connect") {
                    NavigationLink {
                        ContactFormView()
                    } label: {
                        Label("Contact Us", systemImage: "envelope.fill")
                    }
                    
                    Link(destination: URL(string: ChurchContact.phoneUrl)!) {
                        Label("Call Us", systemImage: "phone.fill")
                    }
                    
                    Link(destination: URL(string: ChurchContact.facebook)!) {
                        Label("Facebook", systemImage: "link")
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
            .sheet(isPresented: $showingSafariView) {
                if let url = safariURL {
                    SafariView(url: url)
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showSheet) {
                if let content = sheetContent {
                    content
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Thank you for your message! We'll get back to you soon.")
            }
        }
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

extension UIScrollView {
    func scrollToBottom() {
        let bottomPoint = CGPoint(x: 0, y: contentSize.height - bounds.size.height)
        setContentOffset(bottomPoint, animated: true)
    }
}

#Preview {
    ContentView()
}
