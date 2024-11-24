import SwiftUI
import FirebaseCore
import FirebaseFirestore

// AppDelegate for Firebase configuration
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        
        let db = Firestore.firestore()
        db.settings = settings
        
        return true
    }
}

@main
struct RTSDAApp: App {
    init() {
        FirebaseApp.configure()
        let settings = Firestore.firestore().settings
        settings.cacheSettings = MemoryCacheSettings()
        Firestore.firestore().settings = settings
    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var settings = AppSettings.shared
    @State private var showingSplash = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showingSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showingSplash = false
                                }
                            }
                        }
                } else {
                    ContentView()
                }
            }
            .withAccessibilitySettings()
            .environment(\.sizeCategory, settings.useSystemFontSize ? .medium : .medium)
        }
    }
}
