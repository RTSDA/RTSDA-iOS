//
//  RTSDAApp.swift
//  RTSDA
//
//  Created by Benjamin Slingo on 11/24/24.
//

import SwiftUI

@main
struct RTSDAApp: App {
    @StateObject private var configService = ConfigService.shared
    
    init() {
        // Enable standard orientations (portrait and landscape)
        if #available(iOS 16.0, *) {
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.forEach { windowScene in
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: [.portrait, .landscapeLeft, .landscapeRight]))
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
