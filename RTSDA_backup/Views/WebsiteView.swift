import SwiftUI

struct WebsiteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading website...")
                        .font(.body)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                }
                
                DynamicWebView(
                    url: URL(string: "https://rockvilletollandsda.org")!,
                    isLoading: $isLoading,
                    error: $error
                )
                .opacity(isLoading ? 0 : 1)
                .accessibilityLabel("Church website")
                .accessibilityHint("Browse our church's website")
            }
            .navigationTitle("Church Website")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(edges: .bottom)
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
                Text(error?.localizedDescription ?? "An error occurred while loading the website")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
        }
    }
}

#Preview {
    WebsiteView()
}