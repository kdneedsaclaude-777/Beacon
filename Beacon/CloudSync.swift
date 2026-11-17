//
//  CloudSync.swift
//  Beacon
//
//  Phase 2: community sharing through CloudKit's public database.
//  Fails safe — when the iCloud capability or account is missing, Beacon
//  simply stays local-only and says so in Settings.
//

import Foundation
import CloudKit
import CoreLocation
import Observation

@Observable
final class CloudSync {
    enum Status: Equatable {
        case unknown
        case active
        case unavailable(String)

        var label: String {
            switch self {
            case .unknown: "Checking…"
            case .active: "On — reports are shared with your community"
            case .unavailable(let reason): "Off — \(reason)"
            }
        }
    }

    private(set) var status: Status = .unknown
    private(set) var isSyncing = false
    private(set) var lastSync: Date?

    private static let recordType = "Incident"

    /// Cheap, crash-safe gate: nil when the app has no iCloud entitlement
    /// or the user isn't signed into iCloud. We never touch CKContainer
    /// unless this passes.
    private var cloudCapable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private var database: CKDatabase {
        CKContainer.default().publicCloudDatabase
    }

    // MARK: - Availability

    @discardableResult
    func refreshAvailability() async -> Bool {
        guard cloudCapable else {
            status = .unavailable("sign in to iCloud, and the app needs the iCloud capability")
            return false
        }
        do {
            let account = try await CKContainer.default().accountStatus()
            if account == .available {
                status = .active
                return true
            }
            status = .unavailable("iCloud account not available on this device")
            return false
        } catch {
            status = .unavailable(error.localizedDescription)
            return false
        }
    }

    // MARK: - Sync

    /// Push everything of ours that hasn't made it up yet, then pull the
    /// community's recent reports. When the user's location is known,
    /// only reports within `syncRadiusMetres` are pulled — so a Toronto
    /// community never downloads another city's reports.
    static let syncRadiusMetres: Double = 50_000

    func sync(store: IncidentStore, near userLocation: CLLocation? = nil) async {
        guard !isSyncing, await refreshAvailability() else { return }
        isSyncing = true
        defer { isSyncing = false }

        for id in store.pendingCloudIDs {
            if let incident = store.incidents.first(where: { $0.id == id }) {
                await upload(incident, store: store)
            } else {
                store.markUploaded(id)
            }
        }
        await pull(into: store, near: userLocation)
        lastSync = Date()
    }

    /// Upload one of our reports. Sample and practice data never leaves
    /// the device.
    func upload(_ incident: Incident, store: IncidentStore) async {
        guard !incident.isSample, cloudCapable else { return }
        do {
            let record = makeRecord(from: incident)
            _ = try await database.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
            store.markUploaded(incident.id)
        } catch {
            store.markPendingUpload(incident.id)
        }
    }

    func deleteRemote(_ id: UUID) async {
        guard cloudCapable else { return }
        try? await database.deleteRecord(withID: CKRecord.ID(recordName: id.uuidString))
    }

    enum Counter: String {
        case sightingCount
        case notSeenCount
        case flagCount
    }

    /// Increment a community counter on the server copy, if there is one.
    func bump(_ counter: Counter, incidentID: UUID) async {
        guard cloudCapable else { return }
        let recordID = CKRecord.ID(recordName: incidentID.uuidString)
        guard let record = try? await database.record(for: recordID) else { return }
        let current = record[counter.rawValue] as? Int ?? 0
        record[counter.rawValue] = current + 1
        _ = try? await database.modifyRecords(saving: [record], deleting: [], savePolicy: .changedKeys)
    }

    // MARK: - Pull

    private func pull(into store: IncidentStore, near userLocation: CLLocation?) async {
        let since = Date(timeIntervalSinceNow: -30 * 24 * 3600)
        // With a known location, query by distance (CloudKit-native geo
        // query) and trim to 30 days client-side. Without one, fall back
        // to a recency query.
        let predicate: NSPredicate
        if let userLocation {
            predicate = NSPredicate(
                format: "distanceToLocation:fromLocation:(location, %@) < %f",
                userLocation, Self.syncRadiusMetres
            )
        } else {
            predicate = NSPredicate(format: "reportedAt > %@", since as NSDate)
        }
        let query = CKQuery(recordType: Self.recordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "reportedAt", ascending: false)]

        var fetched: [CloudIncident] = []
        do {
            var (matches, cursor) = try await database.records(matching: query, resultsLimit: 100)
            var pages = 0
            while true {
                fetched.append(contentsOf: matches.compactMap { _, result in
                    (try? result.get()).flatMap(Self.parse)
                })
                pages += 1
                guard let next = cursor, pages < 5 else { break }
                (matches, cursor) = try await database.records(continuingMatchFrom: next)
            }
        } catch {
            // Query errors (e.g. schema not created yet) leave local data untouched.
            return
        }
        let cutoff = Date(timeIntervalSinceNow: -30 * 24 * 3600)
        store.mergeCloud(fetched.filter { $0.incident.reportedAt > cutoff })
    }

    // MARK: - Record mapping

    nonisolated struct CloudIncident {
        var incident: Incident
        var notSeenCount: Int
        var flagCount: Int
    }

    private func makeRecord(from incident: Incident) -> CKRecord {
        let record = CKRecord(
            recordType: Self.recordType,
            recordID: CKRecord.ID(recordName: incident.id.uuidString)
        )
        record["category"] = incident.category.rawValue
        record["date"] = incident.date
        record["reportedAt"] = incident.reportedAt
        record["latitude"] = incident.latitude
        record["longitude"] = incident.longitude
        // CLLocation field enables CloudKit's native "within X metres" queries.
        record["location"] = CLLocation(latitude: incident.latitude, longitude: incident.longitude)
        record["locationName"] = incident.locationName
        if let people = incident.peopleInvolved {
            record["peopleInvolved"] = people
        }
        record["sightingCount"] = incident.sightingCount
        if let details = incident.details {
            record["details"] = details
        }
        if let vehicle = incident.vehicleDescription {
            record["vehicle"] = vehicle
        }
        record["flagCount"] = incident.isFlagged ? 1 : 0
        if let photoData = incident.photoData {
            let url = URL.temporaryDirectory.appending(path: "\(incident.id.uuidString).jpg")
            if (try? photoData.write(to: url)) != nil {
                record["photo"] = CKAsset(fileURL: url)
            }
        }
        return record
    }

    nonisolated private static func parse(_ record: CKRecord) -> CloudIncident? {
        guard
            let id = UUID(uuidString: record.recordID.recordName),
            let categoryRaw = record["category"] as? String,
            let category = IncidentCategory(rawValue: categoryRaw),
            let date = record["date"] as? Date,
            let reportedAt = record["reportedAt"] as? Date,
            let latitude = record["latitude"] as? Double,
            let longitude = record["longitude"] as? Double
        else { return nil }

        var photoData: Data?
        if let asset = record["photo"] as? CKAsset, let url = asset.fileURL {
            photoData = try? Data(contentsOf: url)
        }

        let incident = Incident(
            id: id,
            category: category,
            date: date,
            reportedAt: reportedAt,
            latitude: latitude,
            longitude: longitude,
            locationName: record["locationName"] as? String ?? "Nearby area",
            peopleInvolved: record["peopleInvolved"] as? Int,
            sightingCount: record["sightingCount"] as? Int ?? 1,
            details: record["details"] as? String,
            vehicleDescription: record["vehicle"] as? String,
            photoData: photoData
        )
        return CloudIncident(
            incident: incident,
            notSeenCount: record["notSeenCount"] as? Int ?? 0,
            flagCount: record["flagCount"] as? Int ?? 0
        )
    }
}
