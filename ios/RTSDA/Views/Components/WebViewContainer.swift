import SwiftUI

struct WebViewContainer: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading \(title)...")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                }
                
                DynamicWebView(url: url)
                    .opacity(isLoading ? 0 : 1)
                    .accessibilityLabel("\(title) web view")
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK", role: .cancel) {
                    error = nil
                }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred while loading the content")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
        }
    }
}

#Preview {
    WebViewContainer(
        url: URL(string: "https://www.example.com")!,
        title: "Example"
    )
}
