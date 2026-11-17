//
//  LocationService.swift
//  Beacon (Finder)
//
//  Privacy-first location sensing: when-in-use only, never stored or shared.
//

import Foundation
import CoreLocation
import Observation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var currentLocation: CLLocation?
    var authorization: CLAuthorizationStatus = .notDetermined

    /// Fallback centre (used for sample data and the map before permission is granted).
    static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090)

    var bestCoordinate: CLLocationCoordinate2D {
        currentLocation?.coordinate ?? Self.fallbackCoordinate
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // metres moved before a new fix is delivered
        manager.activityType = .otherNavigation
        manager.pausesLocationUpdatesAutomatically = false
    }

    var isAuthorized: Bool {
#if os(macOS)
        authorization == .authorized || authorization == .authorizedAlways
#else
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
#endif
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Re-ask for location: shows the system prompt if it was never
    /// answered, otherwise kicks the updates back into gear. (iOS only
    /// shows the permission popup once — after a denial, the user must
    /// flip it in Settings, which the in-app banner links to.)
    func retry() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            manager.stopUpdatingLocation()
            manager.startUpdatingLocation()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = latest
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorization = status
#if os(macOS)
            let isAuthorized = status == .authorized || status == .authorizedAlways
#else
            let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
#endif
            if isAuthorized {
                self.manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location is optional everywhere in the app; failures are non-fatal.
    }
}
