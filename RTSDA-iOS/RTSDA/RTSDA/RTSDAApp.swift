//
//  RTSDAApp.swift
//  RTSDA
//
//  Created by Benjamin Slingo on 11/24/24.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Initialize Remote Config
        Task {
            do {
                try await RemoteConfigManager.shared.fetchAndActivate()
            } catch {
                print("❌ Failed to fetch remote config: \(error)")
            }
        }
        
        return true
    }
}

@main
struct RTSDAApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
