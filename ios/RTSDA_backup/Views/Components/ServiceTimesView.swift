import SwiftUI

struct ServiceTimesView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Weekly Service Times")
                    .font(.headline)
                    .padding(.horizontal)
                
                List {
                    Section(header: Text("Saturday (Sabbath)")) {
                        HomeTimeRow(service: "Sabbath School", time: "9:30 AM")
                        HomeTimeRow(service: "Divine Service", time: "11:00 AM")
                    }
                    
                    Section(header: Text("Wednesday")) {
                        HomeTimeRow(service: "Prayer Meeting", time: "7:00 PM")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body)
                }
            }
        }
    }
}