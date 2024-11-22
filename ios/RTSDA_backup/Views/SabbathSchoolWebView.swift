import SwiftUI
import WebKit

struct SabbathSchoolWebView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading Sabbath School...")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
            
            DynamicWebView(
                url: URL(string: "https://www.sabbathschoolpersonal.com")!,
                isLoading: $isLoading,
                error: $error
            )
            .opacity(isLoading ? 0 : 1)
            .accessibilityLabel("Sabbath School lesson study")
            .accessibilityHint("Access the weekly Sabbath School lesson study materials")
        }
        .navigationTitle("Sabbath School")
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK", role: .cancel) {
                error = nil
            }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred while loading Sabbath School")
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
    }
}

#Preview {
    SabbathSchoolWebView()
}