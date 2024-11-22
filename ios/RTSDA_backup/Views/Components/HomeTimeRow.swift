import SwiftUI

struct HomeTimeRow: View {
    let service: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(service)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}