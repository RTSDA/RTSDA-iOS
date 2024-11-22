import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var route: MKRoute?
    @State private var showingDirections = false
    @State private var errorMessage: String?
    @State private var showingError = false
    
    private let churchLocation = CLLocationCoordinate2D(latitude: 41.871742, longitude: -72.437397)
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map {
                    Marker("Rockville-Tolland SDA Church", coordinate: churchLocation)
                        .tint(.blue)
                    if let userLocation = locationManager.location?.coordinate {
                        Marker("You", coordinate: userLocation)
                            .tint(.red)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                
                VStack {
                    Spacer()
                    Button(action: {
                        getDirections()
                    }) {
                        Text("Get Directions")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Directions")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unable to get directions")
            }
            .sheet(isPresented: $showingDirections) {
                if let route = route {
                    MapDirectionsView(route: route)
                }
            }
            .onAppear {
                locationManager.requestAuthorization()
            }
        }
    }
    
    private func getDirections() {
        guard let location = locationManager.location else {
            errorMessage = "Unable to determine your location. Please enable location services."
            showingError = true
            return
        }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: location.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: churchLocation))
        request.transportType = .automobile
        
        Task {
            do {
                let directions = MKDirections(request: request)
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    self.route = route
                    showingDirections = true
                } else {
                    errorMessage = "No route found"
                    showingError = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
}

#Preview {
    MapView()
} 