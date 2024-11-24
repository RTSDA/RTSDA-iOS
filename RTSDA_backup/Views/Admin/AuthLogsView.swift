import SwiftUI

struct AuthLogsView: View {
    @StateObject private var logsViewModel = AuthLogsViewModel()
    
    var body: some View {
        NavigationStack {
            List(logsViewModel.logs) { log in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: log.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(log.success ? .green : .red)
                        Text(log.timestamp.formatted())
                    }
                    
                    if let userId = log.userId {
                        Text("User: \(userId)")
                            .font(.caption)
                    }
                    
                    Text("Device: \(log.deviceInfo)")
                        .font(.caption)
                    
                    if let error = log.error {
                        Text("Error: \(error)")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Auth Logs")
            .refreshable {
                await logsViewModel.fetchLogs()
            }
        }
    }
}

class AuthLogsViewModel: ObservableObject {
    @Published var logs: [AuthLog] = []
    
    func fetchLogs() async {
        // Implement log fetching from Firestore
    }
}

struct AuthLog: Identifiable {
    let id: String
    let timestamp: Date
    let success: Bool
    let userId: String?
    let deviceInfo: String
    let error: String?
} 