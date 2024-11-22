import SwiftUI

struct ServiceTime: Identifiable {
    let id = UUID()
    let day: String
    let name: String
    let time: String
}

struct RTSDAServiceTimesView: View {
    private let serviceTimes = [
        ServiceTime(day: "Saturday", name: "Sabbath School", time: "9:15 AM"),
        ServiceTime(day: "Saturday", name: "Divine Service", time: "11:00 AM"),
        ServiceTime(day: "Wednesday", name: "Prayer Meeting", time: "7:00 PM")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(serviceTimes) { service in
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.headline)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                    
                    HStack {
                        Text(service.day)
                        Text("•")
                        Text(service.time)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility5)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(service.name) on \(service.day) at \(service.time)")
            }
        }
    }
}

#Preview {
    RTSDAServiceTimesView()
        .padding()
}
