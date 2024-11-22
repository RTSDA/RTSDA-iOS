import Foundation
import Combine

@MainActor
class SplashScreenViewModel: ObservableObject {
    @Published var verseOfTheDay: BibleVerse?
    @Published var error: String?
    @Published var theme: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await fetchVerseOfTheDay()
        }
    }
    
    func fetchVerseOfTheDay() async {
        let dailyVerse = DailyVerses.getVerseForDate()
        theme = dailyVerse.theme
        
        do {
            // First, get the API key from Remote Config
            let apiKey = try await BibleAPIConfig.getAPIKey()
            
            guard let url = URL(string: "\(BibleAPIConfig.baseURL)/bibles/\(BibleAPIConfig.bibleId)/verses/\(dailyVerse.id)?content-type=text&include-notes=false&include-titles=false&include-chapter-numbers=false&include-verse-numbers=false&include-verse-spans=false") else {
                self.error = "Invalid URL"
                return
            }
            
            var request = URLRequest(url: url)
            request.addValue(apiKey, forHTTPHeaderField: "api-key")
            
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            
            // Print the response for debugging
            if let httpResponse = urlResponse as? HTTPURLResponse {
                print("[Bible API] Response status: \(httpResponse.statusCode)")
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("[Bible API] Response: \(responseString)")
            }
            
            let verseResponse = try JSONDecoder().decode(BibleVerseResponse.self, from: data)
            self.verseOfTheDay = verseResponse.data
            self.error = nil
        } catch {
            print("[Bible API] Error fetching verse: \(error)")
            self.error = error.localizedDescription
        }
    }
    
    func retryFetch() {
        Task {
            await fetchVerseOfTheDay()
        }
    }
}
