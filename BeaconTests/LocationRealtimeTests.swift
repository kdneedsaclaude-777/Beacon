//
//  LocationRealtimeTests.swift
//  BeaconTests
//
//  Realtime location: the same pipeline the app uses when a live fix
//  arrives (new location → bestCoordinate → samples follow the user),
//  exercised from 20 different locations around the world.
//

import Testing
import Foundation
import CoreLocation
@testable import Beacon

@MainActor
@Suite("Realtime location — 20 cities")
struct LocationRealtimeTests {
    static let cities: [(name: String, latitude: Double, longitude: Double)] = [
        ("Toronto", 43.6532, -79.3832),
        ("Vancouver", 49.2827, -123.1207),
        ("New York", 40.7128, -74.0060),
        ("San Francisco", 37.7749, -122.4194),
        ("Mexico City", 19.4326, -99.1332),
        ("São Paulo", -23.5505, -46.6333),
        ("London", 51.5074, -0.1278),
        ("Paris", 48.8566, 2.3522),
        ("Berlin", 52.5200, 13.4050),
        ("Madrid", 40.4168, -3.7038),
        ("Rome", 41.9028, 12.4964),
        ("Lagos", 6.5244, 3.3792),
        ("Cairo", 30.0444, 31.2357),
        ("Nairobi", -1.2921, 36.8219),
        ("Mumbai", 19.0760, 72.8777),
        ("Singapore", 1.3521, 103.8198),
        ("Tokyo", 35.6762, 139.6503),
        ("Seoul", 37.5665, 126.9780),
        ("Sydney", -33.8688, 151.2093),
        ("Auckland", -36.8485, 174.7633),
    ]

    private func makeStore() -> IncidentStore {
        IncidentStore(fileURL: URL.temporaryDirectory.appending(path: "beacon-location-test-\(UUID().uuidString).json"))
    }

    @Test("Live fix updates bestCoordinate and relocates samples", arguments: cities)
    func liveFixIsFollowed(city: (name: String, latitude: Double, longitude: Double)) {
        let coordinate = CLLocationCoordinate2D(latitude: city.latitude, longitude: city.longitude)
        let fix = CLLocation(latitude: city.latitude, longitude: city.longitude)

        // A new fix immediately becomes the service's best coordinate.
        let service = LocationService()
        service.currentLocation = fix
        #expect(service.bestCoordinate.latitude == coordinate.latitude)
        #expect(service.bestCoordinate.longitude == coordinate.longitude)

        // Sample reports seeded at the fallback follow the user's real
        // area once a fix arrives, exactly as ContentView does on
        // `onChange(of: location.currentLocation)`.
        let store = makeStore()
        store.seedSampleDataIfNeeded(around: LocationService.fallbackCoordinate)
        store.relocateSamplesIfFar(from: coordinate)

        let samples = store.incidents.filter(\.isSample)
        #expect(!samples.isEmpty)
        for sample in samples {
            #expect(sample.location.distance(from: fix) < 5000, "\(city.name): sample should sit within 5 km of the live fix")
        }

        // A later fix in the same neighbourhood must not shuffle pins:
        // realtime following, but stable geography (~220 m north).
        let before = store.incidents.filter(\.isSample).map(\.latitude)
        store.relocateSamplesIfFar(from: CLLocationCoordinate2D(latitude: city.latitude + 0.002, longitude: city.longitude))
        #expect(store.incidents.filter(\.isSample).map(\.latitude) == before, "\(city.name): nearby follow-up fix should not relocate samples")
    }
}
