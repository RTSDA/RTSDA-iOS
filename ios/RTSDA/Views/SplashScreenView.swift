import SwiftUI

struct SplashScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = SplashScreenViewModel()
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(colorScheme == .dark ? "splash-dark" : "splash-light")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                if let verse = viewModel.verseOfTheDay {
                    VStack(spacing: 16) {
                        if !viewModel.theme.isEmpty {
                            Text(viewModel.theme)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(verse.text)
                            .font(.title3)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text("— \(verse.reference)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            viewModel.retryFetch()
                        }) {
                            Label("Retry", systemImage: "arrow.clockwise")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding()
                } else {
                    // Empty view to maintain spacing
                    Color.clear
                        .frame(height: 100)
                }
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