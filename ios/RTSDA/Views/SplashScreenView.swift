import SwiftUI

struct SplashScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Image(colorScheme == .dark ? "splash-dark" : "splash-light")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                Text("Welcome to RTSDA")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
            }
            .scaleEffect(isAnimating ? 1.0 : 0.95)
            .opacity(isAnimating ? 1 : 0.8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}