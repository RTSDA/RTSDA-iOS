import SwiftUI

class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @AppStorage("useSystemFontSize") var useSystemFontSize = true
    @AppStorage("useSystemContrast") var useSystemContrast = true
    @AppStorage("useSystemMotionEffects") var useSystemMotionEffects = true
    
    private init() {}
}
