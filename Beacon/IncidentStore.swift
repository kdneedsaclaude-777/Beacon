//
//  IncidentStore.swift
//  Beacon (Finder)
//
//  Owns all incident data. Persists to a JSON file on-device (Phase 1 —
//  CloudKit community sync is planned for Phase 2).
//

import Foundation
import CoreLocation
import Observation
import WidgetKit

@Observable
final class IncidentStore {
    private(set) var incidents: [Incident] = []
    /// Incidents this user has tapped "I saw this too" on (one confirmation each).
    private(set) var confirmedSightingIDs: Set<UUID> = []
    /// Incidents this user thumbs-downed ("I didn't see this").
    private(set) var notSeenVotedIDs: Set<UUID> = []
    /// Community thumbs-down tallies per incident.
    private(set) var notSeenCounts: [UUID: Int] = [:]
    /// Incidents this user posted (they may delete their own).
    private(set) var myReportIDs: Set<UUID> = []
    /// Our reports still waiting to reach CloudKit.
    private(set) var pendingCloudIDs: Set<UUID> = []
    private var hasSeededSampleData = false

    nonisolated private struct StoreFile: Codable {
        var incidents: [Incident]
        var confirmedSightingIDs: Set<UUID>
        var myReportIDs: Set<UUID>
        var hasSeededSampleData: Bool
        // Optional so files saved by older versions still load.
        var notSeenVotedIDs: Set<UUID>?
        var notSeenCounts: [UUID: Int]?
        var pendingCloudIDs: Set<UUID>?
    }

    private let fileURL: URL

    private static var defaultFileURL: URL {
        let directory = URL.applicationSupportDirectory.appending(path: "Beacon", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "incidents.json")
    }

    /// Pass a custom URL in tests to keep them away from real user data.
    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL
        load()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let file = try? JSONDecoder().decode(StoreFile.self, from: data) else { return }
        incidents = file.incidents
        confirmedSightingIDs = file.confirmedSightingIDs
        myReportIDs = file.myReportIDs
        hasSeededSampleData = file.hasSeededSampleData
        notSeenVotedIDs = file.notSeenVotedIDs ?? []
        notSeenCounts = file.notSeenCounts ?? [:]
        pendingCloudIDs = file.pendingCloudIDs ?? []
    }

    private func save() {
        let file = StoreFile(
            incidents: incidents,
            confirmedSightingIDs: confirmedSightingIDs,
            myReportIDs: myReportIDs,
            hasSeededSampleData: hasSeededSampleData,
            notSeenVotedIDs: notSeenVotedIDs,
            notSeenCounts: notSeenCounts,
            pendingCloudIDs: pendingCloudIDs
        )
        if let data = try? JSONEncoder().encode(file) {
            try? data.write(to: fileURL, options: .atomic)
        }
        updateWidgetSummary()
    }

    /// Publishes a small summary for the home-screen widget. Harmless
    /// no-op until the App Group + widget extension are set up in Xcode.
    private func updateWidgetSummary() {
        guard let shared = UserDefaults(suiteName: "group.beacon.shared") else { return }
        let week = visibleIncidents().count { $0.date > Date(timeIntervalSinceNow: -7 * 24 * 3600) }
        let previousWeek = visibleIncidents().count {
            $0.date <= Date(timeIntervalSinceNow: -7 * 24 * 3600)
                && $0.date > Date(timeIntervalSinceNow: -14 * 24 * 3600)
        }
        shared.set(week, forKey: "widget.weekCount")
        shared.set(week < previousWeek ? "down" : week > previousWeek ? "up" : "same", forKey: "widget.trend")
        shared.set(Date(), forKey: "widget.updated")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Mutations

    func add(_ incident: Incident) {
        incidents.append(incident)
        myReportIDs.insert(incident.id)
        if !incident.isSample {
            pendingCloudIDs.insert(incident.id)
        }
        save()
    }

    // MARK: - Cloud bookkeeping

    func markUploaded(_ id: UUID) {
        pendingCloudIDs.remove(id)
        save()
    }

    func markPendingUpload(_ id: UUID) {
        pendingCloudIDs.insert(id)
        save()
    }

    /// Merge reports pulled from CloudKit. Community counters take the
    /// highest value seen; two or more community flags hide a report.
    func mergeCloud(_ remote: [CloudSync.CloudIncident]) {
        for item in remote {
            if let index = incidents.firstIndex(where: { $0.id == item.incident.id }) {
                incidents[index].sightingCount = max(incidents[index].sightingCount, item.incident.sightingCount)
                if item.flagCount >= 2 {
                    incidents[index].isFlagged = true
                }
            } else {
                var incoming = item.incident
                incoming.isSample = false
                incoming.isFlagged = item.flagCount >= 2
                incidents.append(incoming)
            }
            notSeenCounts[item.incident.id] = max(notSeenCounts[item.incident.id] ?? 0, item.notSeenCount)
        }
        save()
    }

    func confirmSighting(_ id: UUID) {
        guard !confirmedSightingIDs.contains(id),
              let index = incidents.firstIndex(where: { $0.id == id }) else { return }
        incidents[index].sightingCount += 1
        confirmedSightingIDs.insert(id)
        save()
    }

    func hasConfirmedSighting(_ id: UUID) -> Bool {
        confirmedSightingIDs.contains(id)
    }

    /// Thumbs-down: "I was around and didn't see this." Enough of these
    /// relative to sightings hides the report (community correction).
    func markNotSeen(_ id: UUID) {
        guard !notSeenVotedIDs.contains(id), !confirmedSightingIDs.contains(id) else { return }
        notSeenVotedIDs.insert(id)
        notSeenCounts[id, default: 0] += 1
        save()
    }

    func hasMarkedNotSeen(_ id: UUID) -> Bool {
        notSeenVotedIDs.contains(id)
    }

    func notSeenCount(for id: UUID) -> Int {
        notSeenCounts[id] ?? 0
    }

    /// Hidden once doubts clearly outweigh sightings.
    func isCommunityHidden(_ incident: Incident) -> Bool {
        let doubts = notSeenCount(for: incident.id)
        return doubts >= 5 && doubts >= incident.sightingCount * 2
    }

    func isMine(_ id: UUID) -> Bool {
        myReportIDs.contains(id)
    }

    /// Flagged posts are hidden pending review (Phase 2 adds real moderation).
    func flag(_ id: UUID) {
        guard let index = incidents.firstIndex(where: { $0.id == id }) else { return }
        incidents[index].isFlagged = true
        save()
    }

    func delete(_ id: UUID) {
        incidents.removeAll { $0.id == id }
        myReportIDs.remove(id)
        confirmedSightingIDs.remove(id)
        save()
    }

    func clearSampleData() {
        incidents.removeAll { $0.isSample }
        save()
    }

    // MARK: - Queries

    func visibleIncidents(showOlder: Bool = false) -> [Incident] {
        incidents.filter { !$0.isFlagged && !isCommunityHidden($0) && (showOlder || !$0.isExpired) }
    }

    func incidents(within radiusMetres: Double, of location: CLLocation, showOlder: Bool = false) -> [Incident] {
        visibleIncidents(showOlder: showOlder)
            .filter { $0.location.distance(from: location) <= radiusMetres }
            .sorted { $0.location.distance(from: location) < $1.location.distance(from: location) }
    }

    /// A likely duplicate: same category, within ~500 m and 12 hours.
    func possibleDuplicate(category: IncidentCategory, coordinate: CLLocationCoordinate2D, date: Date) -> Incident? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return visibleIncidents().first { incident in
            incident.category == category
                && incident.location.distance(from: location) < 500
                && abs(incident.date.timeIntervalSince(date)) < 12 * 3600
        }
    }

    // MARK: - Sample data

    /// If the example reports were seeded around the fallback location
    /// (e.g. before location permission was granted), shift them to the
    /// user's real neighbourhood once we know where that is.
    func relocateSamplesIfFar(from centre: CLLocationCoordinate2D) {
        let samples = incidents.filter { $0.isSample }
        guard !samples.isEmpty else { return }
        let centroidLat = samples.map(\.latitude).reduce(0, +) / Double(samples.count)
        let centroidLon = samples.map(\.longitude).reduce(0, +) / Double(samples.count)
        let centroid = CLLocation(latitude: centroidLat, longitude: centroidLon)
        let target = CLLocation(latitude: centre.latitude, longitude: centre.longitude)
        guard centroid.distance(from: target) > 50_000 else { return }

        for index in incidents.indices where incidents[index].isSample {
            incidents[index].latitude += centre.latitude - centroidLat
            incidents[index].longitude += centre.longitude - centroidLon
        }
        save()
    }

    /// Seeds nearby example reports on first launch so the map isn't empty.
    /// Clearly marked as samples and removable in Settings.
    func seedSampleDataIfNeeded(around centre: CLLocationCoordinate2D) {
        guard !hasSeededSampleData else { return }
        hasSeededSampleData = true

        nonisolated struct Seed {
            let dLat: Double, dLon: Double
            let category: IncidentCategory
            let hoursAgo: Double
            let people: Int?
            let sightings: Int
            let details: String?
            let vehicle: String?
        }

        let seeds: [Seed] = [
            Seed(dLat: 0.0031, dLon: -0.0044, category: .carTheft, hoursAgo: 14, people: 2, sightings: 3,
                 details: "Two people checking car door handles along the street.", vehicle: nil),
            Seed(dLat: -0.0052, dLon: 0.0027, category: .packageTheft, hoursAgo: 30, people: 1, sightings: 2,
                 details: "Package taken from a front porch in the afternoon.", vehicle: nil),
            Seed(dLat: 0.0068, dLon: 0.0061, category: .suspicious, hoursAgo: 5, people: 1, sightings: 1,
                 details: "Someone looking into backyard windows, left when noticed.", vehicle: nil),
            Seed(dLat: -0.0025, dLon: -0.0073, category: .scam, hoursAgo: 50, people: nil, sightings: 4,
                 details: "Phone caller claiming to be the tax agency, demanding gift cards. Do not pay — hang up.", vehicle: nil),
            Seed(dLat: 0.0088, dLon: -0.0019, category: .vandalism, hoursAgo: 76, people: nil, sightings: 1,
                 details: "Spray paint on the community centre wall.", vehicle: nil),
            Seed(dLat: -0.0079, dLon: -0.0038, category: .carTheft, hoursAgo: 100, people: 1, sightings: 2,
                 details: "Car window smashed overnight, bag taken.", vehicle: "Grey sedan"),
            Seed(dLat: 0.0014, dLon: 0.0093, category: .breakIn, hoursAgo: 130, people: nil, sightings: 1,
                 details: "Garage side door forced open while owners were away.", vehicle: nil),
            Seed(dLat: -0.0090, dLon: 0.0075, category: .bikeTheft, hoursAgo: 170, people: 1, sightings: 1,
                 details: "Bike taken from a driveway.", vehicle: nil),
            Seed(dLat: 0.0047, dLon: 0.0022, category: .suspicious, hoursAgo: 210, people: 3, sightings: 2,
                 details: "Group trying gates in the alley late at night.", vehicle: nil),
            Seed(dLat: -0.0011, dLon: -0.0058, category: .scam, hoursAgo: 260, people: 1, sightings: 3,
                 details: "Door-to-door 'furnace inspector' with no ID asking to come inside.", vehicle: nil),
            Seed(dLat: 0.0060, dLon: -0.0080, category: .robbery, hoursAgo: 320, people: 2, sightings: 1,
                 details: "Phone grabbed near the bus stop in the evening.", vehicle: nil),
            Seed(dLat: -0.0040, dLon: 0.0050, category: .hazard, hoursAgo: 400, people: nil, sightings: 1,
                 details: "Street light out on the corner for over a week — very dark at night.", vehicle: nil),
        ]

        for seed in seeds {
            let incident = Incident(
                category: seed.category,
                date: Date(timeIntervalSinceNow: -seed.hoursAgo * 3600),
                reportedAt: Date(timeIntervalSinceNow: -seed.hoursAgo * 3600 + 1800),
                latitude: centre.latitude + seed.dLat,
                longitude: centre.longitude + seed.dLon,
                locationName: "Example report — nearby area",
                peopleInvolved: seed.people,
                sightingCount: seed.sightings,
                details: seed.details,
                vehicleDescription: seed.vehicle,
                isSample: true
            )
            incidents.append(incident)
        }
        save()
    }
}
