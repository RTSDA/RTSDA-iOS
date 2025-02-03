import SwiftUI

struct SplashScreenView: View {
    @StateObject private var configService = ConfigService.shared
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var bibleVerse = ""
    @State private var bibleReference = ""
    
    // Timing constants
    private let fadeInDuration: Double = 0.5
    private let baseDisplayDuration: Double = 1.0
    private let timePerWord: Double = 0.15
    private let minDisplayDuration: Double = 1.5
    private let maxDisplayDuration: Double = 3.0
    
    private func calculateDisplayDuration(for text: String) -> Double {
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let calculatedDuration = baseDisplayDuration + (Double(words.count) * timePerWord)
        return min(max(calculatedDuration, minDisplayDuration), maxDisplayDuration)
    }
    
    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color(hex: "3b0d11"),
                    Color(hex: "21070a")
                ]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image("sdalogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                    
                    Text("Rockville-Tolland SDA Church")
                        .font(.custom("Montserrat-SemiBold", size: 24))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Rectangle()
                        .fill(Color(hex: "fb8b23"))
                        .frame(width: 60, height: 2)
                    
                    Text(bibleVerse)
                        .font(.custom("Lora-Italic", size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineSpacing(4)
                    
                    Text(bibleReference)
                        .font(.custom("Montserrat-Regular", size: 14))
                        .foregroundColor(Color(hex: "fb8b23"))
                }
                .padding()
                .scaleEffect(size)
                .opacity(opacity)
                .task {
                    // First load config
                    await configService.loadConfig()
                    
                    do {
                        let verse = try await BibleService.shared.getRandomVerse()
                        bibleVerse = verse.verse
                        bibleReference = verse.reference
                        
                        // Calculate display duration based on verse length
                        let displayDuration = calculateDisplayDuration(for: verse.verse)
                        
                        // Start fade in animation after verse is loaded
                        withAnimation(.easeIn(duration: fadeInDuration)) {
                            self.size = 0.9
                            self.opacity = 1.0
                        }
                        
                        // Wait for fade in + calculated display duration before transitioning
                        DispatchQueue.main.asyncAfter(deadline: .now() + fadeInDuration + displayDuration) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    } catch {
                        // Fallback to a default verse if API fails
                        bibleVerse = "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life."
                        bibleReference = "John 3:16"
                        
                        // Calculate duration for fallback verse
                        let displayDuration = calculateDisplayDuration(for: bibleVerse)
                        
                        // Use same timing for fallback verse
                        withAnimation(.easeIn(duration: fadeInDuration)) {
                            self.size = 0.9
                            self.opacity = 1.0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + fadeInDuration + displayDuration) {
                            withAnimation {
                                self.isActive = true
                            }
                        }
                    }
                }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SplashScreenView()
}
