import SwiftUI

struct SplashScreenView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                Image("rtsda_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                
                Text("Welcome to RTSDA")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
            }
        }
    }
}