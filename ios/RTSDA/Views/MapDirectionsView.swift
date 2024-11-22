import SwiftUI
import MapKit

struct MapDirectionsView: View {
    let route: MKRoute
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text(formatDistance(route.distance))
                                .font(.headline)
                            Text(formatTime(route.expectedTravelTime))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Step by Step Directions") {
                    ForEach(route.steps, id: \.instructions) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: getDirectionIcon(for: step))
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            Text(step.instructions)
                                .font(.body)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .full
        return formatter.string(fromDistance: distance)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: time) ?? ""
    }
    
    private func getDirectionIcon(for step: MKRoute.Step) -> String {
        if step.instructions.contains("Turn right") {
            return "arrow.turn.up.right"
        } else if step.instructions.contains("Turn left") {
            return "arrow.turn.up.left"
        } else if step.instructions.contains("Continue") || step.instructions.contains("Head") {
            return "arrow.up"
        } else if step.instructions.contains("Arrive") {
            return "mappin.circle.fill"
        } else {
            return "arrow.up"
        }
    }
}

#Preview {
    // Create a mock route for preview
    let route = MKRoute()
    return MapDirectionsView(route: route)
}
