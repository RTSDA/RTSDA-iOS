import SwiftUI
import MapKit

struct DirectionsView: View {
    @Environment(\.dismiss) private var dismiss
    let route: MKRoute
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "clock")
                        Text("Estimated Time: \(formatTime(route.expectedTravelTime))")
                    }
                    
                    HStack {
                        Image(systemName: "car")
                        Text("Distance: \(formatDistance(route.distance))")
                    }
                }
                
                Section("Turn by Turn Directions") {
                    ForEach(route.steps, id: \.instructions) { step in
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text(step.instructions)
                        }
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
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        let miles = meters / 1609.34
        return String(format: "%.1f miles", miles)
    }
} 