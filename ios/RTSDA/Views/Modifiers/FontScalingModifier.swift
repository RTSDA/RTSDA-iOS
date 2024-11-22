import SwiftUI

struct FontScalingModifier: ViewModifier {
    @ObservedObject private var settings = AppSettings.shared
    
    func body(content: Content) -> some View {
        content
            .environment(\.sizeCategory, settings.useSystemFontSize ? ContentSizeCategory.medium : ContentSizeCategory.medium)
    }
}
