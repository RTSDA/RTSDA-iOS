import SwiftUI
import WebKit

struct HymnalWebView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading SDA Hymnal...")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
            
            DynamicWebView(url: URL(string: "https://www.sdahymnals.com/sda-hymnal")!)
                .opacity(isLoading ? 0 : 1)
                .accessibilityLabel("SDA Hymnal browser")
                .accessibilityHint("Browse and search the Seventh-day Adventist Hymnal")
        }
        .navigationTitle("SDA Hymnal")
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK", role: .cancel) {
                error = nil
            }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred while loading the hymnal")
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
    }
}

#Preview {
    HymnalWebView()
}