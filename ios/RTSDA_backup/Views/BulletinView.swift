import SwiftUI
import FirebaseFirestore

struct BulletinView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @StateObject private var viewModel = BulletinViewModel()
    @State private var searchText = ""
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading bulletins...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.bulletins.isEmpty {
                Text("No bulletins available")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(viewModel.bulletins) { bulletin in
                    BulletinRow(bulletin: bulletin) // Use the BulletinRow view
                }
            }
        }
        .navigationTitle("Bulletins")
        .searchable(text: $searchText, prompt: "Search bulletins")
        .refreshable {
            await viewModel.fetchBulletins() // Refresh bulletins when pulled down
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
        .task {
            await viewModel.fetchBulletins() // Fetch bulletins on load
        }
    }
} 