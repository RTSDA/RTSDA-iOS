import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseRemoteConfig

// AppDelegate for Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let firestoreSettings = FirestoreSettings()
        firestoreSettings.cacheSettings = PersistentCacheSettings()
        
        let db = Firestore.firestore()
        db.settings = firestoreSettings
        
        // Configure Remote Config
        let remoteConfig = RemoteConfig.remoteConfig()
        let remoteConfigSettings = RemoteConfigSettings()
        remoteConfigSettings.minimumFetchInterval = 0 // For development, remove this line for production
        remoteConfig.configSettings = remoteConfigSettings
        
        // Set default values
        remoteConfig.setDefaults([
            "youtube_api_key": "YOUR_DEV_API_KEY" as NSObject
        ])
        
        // Check for installed apps in the background
        Task {
            await ResourceService.shared.checkInstalledApps()
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        // Handle URL scheme
        return true
    }
}

@main
struct RTSDAApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var settings = AppSettings.shared
    @State private var showingSplash = true
    @StateObject private var splashViewModel = SplashScreenViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showingSplash {
                    SplashScreenView(viewModel: splashViewModel)
                        .transition(
                            .asymmetric(
                                insertion: .opacity,
                                removal: .opacity.combined(with: .scale(scale: 0.9))
                            )
                        )
                        .onChange(of: splashViewModel.isLoaded) { isLoaded in
                            if isLoaded {
                                // Add a delay to ensure the verse is readable
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    withAnimation(.easeOut(duration: 0.8)) {
                                        showingSplash = false
                                    }
                                }
                            }
                        }
                } else {
                    ContentView()
                        .task {
                            do {
                                try await ConfigService.shared.fetchConfig()
                            } catch {
                                print("Error fetching remote config: \(error)")
                            }
                        }
                        .transition(.opacity)
                }
            }
            .environmentObject(settings)
        }
    }
}
