import SwiftUI

struct AccessibilityModifier: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    @Environment(\.legibilityWeight) var legibilityWeight
    @Environment(\.colorSchemeContrast) var contrast
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    func body(content: Content) -> some View {
        content
            // Support Dynamic Type
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            // Support Bold Text
            .fontWeight(legibilityWeight == .bold ? .bold : .regular)
            // Support Increased Contrast
            .accessibilityShowsLargeContentViewer()
            // Support Reduce Motion
            .accessibilityReduceMotion()
            // Support VoiceOver
            .accessibilityElement(children: .contain)
            .accessibilityLabel(accessibilityLabel)
    }
    
    private var accessibilityLabel: Text {
        Text("RTSDA Church App")
    }
}

extension View {
    func withAccessibilitySettings() -> some View {
        modifier(AccessibilityModifier())
    }
}
