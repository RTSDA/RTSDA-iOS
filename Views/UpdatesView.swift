import SwiftUI

struct UpdatesView: View {
    @Environment(\.sizeCategory) private var sizeCategory
    @StateObject private var viewModel = UpdatesViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading {
                ProgressView("Loading updates...")
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if viewModel.updates.isEmpty {
                Text("No updates available")
                    .font(.body)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(viewModel.updates) { update in
                    UpdateRow(update: update)
                }
            }
        }
        .navigationTitle("Updates")
        .refreshable {
            await viewModel.fetchUpdates()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
        .task {
            await viewModel.fetchUpdates()
        }
    }
}

struct UpdateRow: View {
    let update: Update
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(update.title)
                .font(.headline)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
            
            Text(update.message)
                .font(.body)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                .foregroundColor(.secondary)
            
            Text(update.date.formatted(date: .long, time: .shortened))
                .font(.caption)
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(update.title): \(update.message). Posted \(update.date.formatted(date: .long, time: .shortened))")
    }
}

#Preview {
    UpdatesView()
}