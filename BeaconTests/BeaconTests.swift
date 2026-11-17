//
//  BeaconTests.swift
//  BeaconTests
//
//  Tests for Beacon's safety-critical logic: moderation, the family
//  filter, address privacy detection, and incident store rules.
//

import Testing
import Foundation
import CoreLocation
@testable import Beacon

// MARK: - Moderation

@Suite("Moderation")
struct ModerationTests {
    @Test func blockedWordsAreCaught() {
        #expect(Moderation.containsBlockedWords("what the fuck happened here"))
        #expect(Moderation.containsBlockedWords("SHIT!"))
        #expect(Moderation.containsBlockedWords("that bitch."))
    }

    @Test func cleanTextPasses() {
        #expect(!Moderation.containsBlockedWords("Two people checking car door handles."))
        #expect(!Moderation.containsBlockedWords(""))
        // Blocked words inside other words don't count (whole-word match).
        #expect(!Moderation.containsBlockedWords("The class assembles at noon."))
    }

    @Test func exactAddressesAreDetected() {
        #expect(Moderation.looksLikeExactAddress("Stolen from 123 Maple Street yesterday"))
        #expect(Moderation.looksLikeExactAddress("break-in at 7 Birchwood Ave"))
        #expect(Moderation.looksLikeExactAddress("saw him near apt 4"))
        #expect(Moderation.looksLikeExactAddress("Unit #12 got hit"))
    }

    @Test func vagueLocationsAreAllowed() {
        #expect(!Moderation.looksLikeExactAddress("Near the Maple Street area"))
        #expect(!Moderation.looksLikeExactAddress("Someone checking car handles at night"))
        #expect(!Moderation.looksLikeExactAddress("2 people by the park"))
    }
}

// MARK: - Family filter

@Suite("Family filter")
struct ContentFilterTests {
    @Test func sensitiveWordsAreFlagged() {
        #expect(ContentFilter.isSensitive("knife"))
        #expect(ContentFilter.isSensitive("Knife,"))
        #expect(ContentFilter.isSensitive("GUN!"))
        #expect(!ContentFilter.isSensitive("garden"))
    }

    @Test func sentenceScanning() {
        #expect(ContentFilter.containsSensitiveWords("He had a knife in his bag"))
        #expect(!ContentFilter.containsSensitiveWords("Package taken from a porch"))
    }
}

// MARK: - Incident store

@MainActor
@Suite("Incident store")
struct IncidentStoreTests {
    private func makeStore() -> IncidentStore {
        IncidentStore(fileURL: URL.temporaryDirectory.appending(path: "beacon-test-\(UUID().uuidString).json"))
    }

    private func makeIncident(
        category: IncidentCategory = .carTheft,
        latitude: Double = 43.6532,
        longitude: Double = -79.3832,
        date: Date = Date(),
        reportedAt: Date = Date(),
        isSample: Bool = false
    ) -> Incident {
        Incident(
            category: category,
            date: date,
            reportedAt: reportedAt,
            latitude: latitude,
            longitude: longitude,
            locationName: "Test area",
            peopleInvolved: 1,
            isSample: isSample
        )
    }

    @Test func addingPersistsAndMarksAsMine() {
        let url = URL.temporaryDirectory.appending(path: "beacon-test-\(UUID().uuidString).json")
        let store = IncidentStore(fileURL: url)
        let incident = makeIncident()
        store.add(incident)
        #expect(store.isMine(incident.id))

        let reloaded = IncidentStore(fileURL: url)
        #expect(reloaded.incidents.count == 1)
        #expect(reloaded.incidents.first?.id == incident.id)
    }

    @Test func sightingCanOnlyBeConfirmedOnce() {
        let store = makeStore()
        let incident = makeIncident()
        store.add(incident)

        store.confirmSighting(incident.id)
        store.confirmSighting(incident.id)

        #expect(store.incidents.first?.sightingCount == 2)
        #expect(store.hasConfirmedSighting(incident.id))
    }

    @Test func cannotVoteBothWays() {
        let store = makeStore()
        let incident = makeIncident()
        store.add(incident)

        store.confirmSighting(incident.id)
        store.markNotSeen(incident.id)

        #expect(store.notSeenCount(for: incident.id) == 0)
        #expect(!store.hasMarkedNotSeen(incident.id))
    }

    @Test func thumbsDownRegistersOnce() {
        let store = makeStore()
        let incident = makeIncident()
        store.add(incident)

        store.markNotSeen(incident.id)
        store.markNotSeen(incident.id)

        #expect(store.notSeenCount(for: incident.id) == 1)
        #expect(store.hasMarkedNotSeen(incident.id))
    }

    @Test func duplicateDetectionFindsNearbySameCategory() {
        let store = makeStore()
        let incident = makeIncident()
        store.add(incident)

        // Same category, ~100 m away, same time: duplicate.
        let nearby = store.possibleDuplicate(
            category: .carTheft,
            coordinate: CLLocationCoordinate2D(latitude: 43.6541, longitude: -79.3832),
            date: Date()
        )
        #expect(nearby?.id == incident.id)

        // Different category: not a duplicate.
        #expect(store.possibleDuplicate(
            category: .scam,
            coordinate: CLLocationCoordinate2D(latitude: 43.6541, longitude: -79.3832),
            date: Date()
        ) == nil)

        // Same category but ~5 km away: not a duplicate.
        #expect(store.possibleDuplicate(
            category: .carTheft,
            coordinate: CLLocationCoordinate2D(latitude: 43.6982, longitude: -79.3832),
            date: Date()
        ) == nil)

        // Same category and place, but a day apart: not a duplicate.
        #expect(store.possibleDuplicate(
            category: .carTheft,
            coordinate: CLLocationCoordinate2D(latitude: 43.6541, longitude: -79.3832),
            date: Date(timeIntervalSinceNow: -24 * 3600)
        ) == nil)
    }

    @Test func expiredReportsHideFromDefaultView() {
        let store = makeStore()
        let old = makeIncident(reportedAt: Date(timeIntervalSinceNow: -31 * 24 * 3600))
        let fresh = makeIncident()
        store.add(old)
        store.add(fresh)

        #expect(store.visibleIncidents().map(\.id) == [fresh.id])
        #expect(store.visibleIncidents(showOlder: true).count == 2)
    }

    @Test func flaggedReportsAreHidden() {
        let store = makeStore()
        let incident = makeIncident()
        store.add(incident)
        store.flag(incident.id)
        #expect(store.visibleIncidents().isEmpty)
    }

    @Test func samplesRelocateWhenFarAway() {
        let store = makeStore()
        // Seed around Apple Park (California).
        store.seedSampleDataIfNeeded(around: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090))
        let toronto = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)

        store.relocateSamplesIfFar(from: toronto)

        let torontoLocation = CLLocation(latitude: toronto.latitude, longitude: toronto.longitude)
        for sample in store.incidents.filter({ $0.isSample }) {
            #expect(sample.location.distance(from: torontoLocation) < 5000)
        }
    }

    @Test func samplesStayPutWhenNearby() {
        let store = makeStore()
        let home = CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832)
        store.seedSampleDataIfNeeded(around: home)
        let before = store.incidents.map(\.latitude)

        // 1 km away: no relocation.
        store.relocateSamplesIfFar(from: CLLocationCoordinate2D(latitude: 43.6620, longitude: -79.3832))
        #expect(store.incidents.map(\.latitude) == before)
    }

    @Test func userReportsNeverRelocate() {
        let store = makeStore()
        store.seedSampleDataIfNeeded(around: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090))
        let mine = makeIncident(latitude: 37.33, longitude: -122.01)
        store.add(mine)

        store.relocateSamplesIfFar(from: CLLocationCoordinate2D(latitude: 43.6532, longitude: -79.3832))

        let kept = store.incidents.first { $0.id == mine.id }
        #expect(kept?.latitude == 37.33)
        #expect(kept?.longitude == -122.01)
    }
}

// MARK: - Model rules

@Suite("Model rules")
struct ModelTests {
    @Test func peopleLabels() {
        var incident = Incident(
            category: .theft, date: Date(), latitude: 0, longitude: 0,
            locationName: "x", peopleInvolved: nil
        )
        #expect(incident.peopleLabel == "Not sure")
        incident.peopleInvolved = 5
        #expect(incident.peopleLabel == "5 or more")
        incident.peopleInvolved = 2
        #expect(incident.peopleLabel == "2")
    }

    @Test func timeFilters() {
        #expect(TimeFilter.today.contains(Date()))
        #expect(TimeFilter.week.contains(Date(timeIntervalSinceNow: -3 * 24 * 3600)))
        #expect(!TimeFilter.week.contains(Date(timeIntervalSinceNow: -10 * 24 * 3600)))
        #expect(!TimeFilter.month.contains(Date(timeIntervalSinceNow: -40 * 24 * 3600)))
        #expect(TimeFilter.all.contains(Date(timeIntervalSinceNow: -400 * 24 * 3600)))
    }

    @Test func ageGroupRules() {
        #expect(!AgeGroup.under13.canPost)
        #expect(AgeGroup.under13.isMinor)
        #expect(AgeGroup.teen.canPost)
        #expect(AgeGroup.teen.isMinor)
        #expect(AgeGroup.senior.canPost)
        #expect(!AgeGroup.senior.isMinor)
    }

    @Test func nicknamesAreWellFormed() {
        for _ in 0..<20 {
            let name = NicknameGenerator.random()
            let parts = name.split(separator: " ").map(String.init)
            #expect(parts.count == 2)
            #expect(NicknameGenerator.adjectives.contains(parts[0]))
            #expect(NicknameGenerator.nouns.contains(parts[1]))
        }
    }

    @Test func emergencyNumbersMatchRegions() {
        #expect(EmergencyNumber.number(forRegion: "CA") == "911")
        #expect(EmergencyNumber.number(forRegion: "US") == "911")
        #expect(EmergencyNumber.number(forRegion: "GB") == "999")
        #expect(EmergencyNumber.number(forRegion: "AU") == "000")
        #expect(EmergencyNumber.number(forRegion: "NZ") == "111")
        #expect(EmergencyNumber.number(forRegion: "FR") == "112")
        #expect(EmergencyNumber.number(forRegion: nil) == "112")
    }

    @Test func everyCategoryHasCompleteMetadata() {
        for category in IncidentCategory.allCases {
            #expect(!category.label.isEmpty)
            #expect(!category.symbol.isEmpty)
            #expect(!category.plainDescription.isEmpty)
            #expect(!category.examples.isEmpty)
            #expect(category.colorHex.count == 6)
        }
    }
}
