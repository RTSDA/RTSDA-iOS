import SwiftUI
import WebKit

struct LiveStreamView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView("Loading live stream...")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            }
            
            DynamicWebView(url: URL(string: "https://www.youtube.com/@RockvilleTollandSDAChurch/live")!)
                .opacity(isLoading ? 0 : 1)
                .accessibilityLabel("Live stream video player")
                .accessibilityHint("Shows the live stream from our church's YouTube channel")
        }
        .navigationTitle("Live Stream")
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("OK", role: .cancel) {
                error = nil
            }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred while loading the live stream")
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
    }
}

#Preview {
    LiveStreamView()
}