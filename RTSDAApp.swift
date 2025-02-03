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
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
        }
    }
}
