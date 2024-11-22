import SwiftUI

struct SplashView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Image(colorScheme == .dark ? "splash-dark" : "splash-light")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    SplashView()
}
