import Foundation
import EventKit
import CoreLocation
import Photos
import Contacts
import AVFoundation

@MainActor
class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()
    
    @Published var calendarAccess: Bool = false
    @Published var locationAccess: Bool = false
    @Published var cameraAccess: Bool = false
    @Published var photosAccess: Bool = false
    @Published var contactsAccess: Bool = false
    @Published var microphoneAccess: Bool = false
    
    private let locationManager = CLLocationManager()
    
    private init() {
        checkPermissions()
    }
    
    func checkPermissions() {
        checkCalendarAccess()
        checkLocationAccess()
        checkCameraAccess()
        checkPhotosAccess()
        checkContactsAccess()
        checkMicrophoneAccess()
    }
    
    // MARK: - Calendar
    func checkCalendarAccess() {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            calendarAccess = status == .fullAccess || status == .writeOnly
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            calendarAccess = status == .authorized
        }
    }
    
    func requestCalendarAccess() async -> Bool {
        let store = EKEventStore()
        do {
            if #available(iOS 17.0, *) {
                // First try to get write-only access as it's less invasive
                let writeGranted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                    store.requestWriteOnlyAccessToEvents { granted, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
                
                if writeGranted {
                    await MainActor.run {
                        calendarAccess = true
                    }
                    return true
                }
                
                // If write-only access fails or is denied, try for full access
                let fullGranted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
                    store.requestFullAccessToEvents { granted, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
                
                await MainActor.run {
                    calendarAccess = fullGranted
                }
                return fullGranted
            } else {
                // Pre-iOS 17 fallback
                #if compiler(>=5.9)
                let granted = try await store.requestAccess(to: .event)
                #else
                let granted = try await withCheckedThrowingContinuation { continuation in
                    store.requestAccess(to: .event) { granted, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
                #endif
                
                await MainActor.run {
                    calendarAccess = granted
                }
                return granted
            }
        } catch {
            print("❌ Calendar access error: \(error)")
            return false
        }
    }
    
    // MARK: - Location
    func checkLocationAccess() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationAccess = true
        default:
            locationAccess = false
        }
    }
    
    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    // MARK: - Camera
    func checkCameraAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraAccess = status == .authorized
    }
    
    func requestCameraAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            cameraAccess = granted
        }
        return granted
    }
    
    // MARK: - Photos
    func checkPhotosAccess() {
        let status = PHPhotoLibrary.authorizationStatus()
        photosAccess = status == .authorized || status == .limited
    }
    
    func requestPhotosAccess() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            photosAccess = status == .authorized || status == .limited
        }
        return photosAccess
    }
    
    // MARK: - Contacts
    func checkContactsAccess() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        contactsAccess = status == .authorized
    }
    
    func requestContactsAccess() async -> Bool {
        let store = CNContactStore()
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                contactsAccess = granted
            }
            return granted
        } catch {
            print("❌ Contacts access error: \(error)")
            return false
        }
    }
    
    // MARK: - Microphone
    func checkMicrophoneAccess() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        microphoneAccess = status == .authorized
    }
    
    func requestMicrophoneAccess() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            microphoneAccess = granted
        }
        return granted
    }
    
    // MARK: - Helper Methods
    func handleLimitedAccess(for feature: AppFeature) -> FeatureAvailability {
        switch feature {
        case .calendar:
            if #available(iOS 17.0, *) {
                let status = EKEventStore.authorizationStatus(for: .event)
                switch status {
                case .fullAccess:
                    return .full
                case .writeOnly:
                    return .limited
                default:
                    return .unavailable
                }
            } else {
                let status = EKEventStore.authorizationStatus(for: .event)
                if status == .authorized {
                    return .full
                }
                return .unavailable
            }
        case .location:
            return locationAccess ? .full : .limited
        case .camera:
            return cameraAccess ? .full : .limited
        case .photos:
            // Photos is special - it can work with limited access
            let status = PHPhotoLibrary.authorizationStatus()
            switch status {
            case .authorized:
                return .full
            case .limited:
                return .limited
            default:
                return .unavailable
            }
        case .contacts:
            return contactsAccess ? .full : .limited
        case .microphone:
            return microphoneAccess ? .full : .limited
        }
    }
}

enum AppFeature {
    case calendar
    case location
    case camera
    case photos
    case contacts
    case microphone
    
    var displayName: String {
        switch self {
        case .calendar: return "Calendar"
        case .location: return "Location"
        case .camera: return "Camera"
        case .photos: return "Photos"
        case .contacts: return "Contacts"
        case .microphone: return "Microphone"
        }
    }
}

enum FeatureAvailability {
    case full
    case limited
    case unavailable
    
    var description: String {
        switch self {
        case .full:
            return "Full Access"
        case .limited:
            return "Limited Access"
        case .unavailable:
            return "Not Available"
        }
    }
}
