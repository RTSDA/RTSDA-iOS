import SwiftUI

struct BulletinRow: View {
    let bulletin: Bulletin
    @Environment(\.sizeCategory) private var sizeCategory
    
    var body: some View {
        Button(action: openBulletin) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bulletin.title)
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    
                    Text(bulletin.timestamp.formatted(date: .long, time: .omitted))
                        .font(.subheadline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .imageScale(sizeCategory.isAccessibilityCategory ? .large : .medium)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .accessibilityLabel("\(bulletin.title) from \(bulletin.timestamp.formatted(date: .long, time: .omitted))")
        .accessibilityHint("Tap to view bulletin")
    }
    
    private func openBulletin() {
        if let url = URL(string: bulletin.url) {
            UIApplication.shared.open(url)
        }
    }
}