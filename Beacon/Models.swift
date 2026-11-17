//
//  Models.swift
//  Beacon (Finder)
//
//  Core data types for community incident reports.
//

import SwiftUI
import CoreLocation

nonisolated enum IncidentCategory: String, Codable, CaseIterable, Identifiable {
    case suspicious
    case theft
    case packageTheft
    case bikeTheft
    case breakIn
    case robbery
    case carTheft
    case vandalism
    case trespassing
    case disturbance
    case hazard
    case scam
    case lostPet
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .suspicious: "Suspicious activity"
        case .theft: "Theft"
        case .packageTheft: "Package theft"
        case .bikeTheft: "Bike theft"
        case .breakIn: "Break-in"
        case .robbery: "Robbery"
        case .carTheft: "Car theft / break-in"
        case .vandalism: "Vandalism"
        case .trespassing: "Trespassing"
        case .disturbance: "Disturbance"
        case .hazard: "Safety hazard"
        case .scam: "Scam"
        case .lostPet: "Lost / found pet"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .suspicious: "eye"
        case .theft: "handbag"
        case .packageTheft: "shippingbox"
        case .bikeTheft: "bicycle"
        case .breakIn: "house"
        case .robbery: "exclamationmark.shield"
        case .carTheft: "car"
        case .vandalism: "paintbrush"
        case .trespassing: "figure.walk.motion"
        case .disturbance: "speaker.wave.2"
        case .hazard: "exclamationmark.triangle"
        case .scam: "phone"
        case .lostPet: "pawprint"
        case .other: "questionmark"
        }
    }

    /// Plain-language explanation shown in the map legend.
    var plainDescription: String {
        switch self {
        case .suspicious: "Someone acting oddly, like checking car doors or looking into windows."
        case .theft: "Something was stolen from a person, yard, or store."
        case .packageTheft: "A delivery or mail was taken."
        case .bikeTheft: "A bike or scooter was stolen."
        case .breakIn: "Someone broke into a home, garage, or business."
        case .robbery: "Something was taken from a person directly."
        case .carTheft: "A car was stolen or broken into."
        case .vandalism: "Property was damaged on purpose."
        case .trespassing: "Someone was somewhere they clearly don't belong."
        case .disturbance: "A fight, threats, or scary commotion in public."
        case .hazard: "Something unsafe that isn't a crime."
        case .scam: "A phone, online, or door-to-door scam attempt."
        case .lostPet: "A missing pet, or a found one looking for home."
        case .other: "Anything else worth letting neighbours know about."
        }
    }

    /// Concrete examples shown on the report cards (and as a hover tooltip
    /// on iPad/Mac).
    var examples: String {
        switch self {
        case .suspicious: "e.g. trying car door handles, peering into windows, testing gates at night"
        case .theft: "e.g. purse taken at a store, tools taken from a yard"
        case .packageTheft: "e.g. a parcel taken from a porch, mail opened or missing"
        case .bikeTheft: "e.g. a bike taken from a rack or garage, a lock cut"
        case .breakIn: "e.g. a forced door or window at a home, shed, or business"
        case .robbery: "e.g. a phone grabbed from someone's hand, a wallet demanded"
        case .carTheft: "e.g. a stolen car, a smashed window, items taken from inside"
        case .vandalism: "e.g. spray paint, broken fences, smashed mailboxes"
        case .trespassing: "e.g. a stranger in a backyard, stairwell, or locked lobby"
        case .disturbance: "e.g. shouting or fighting in the street, threats yelled at passers-by"
        case .hazard: "e.g. a street light out, a broken lock on a shared door, a dark path"
        case .scam: "e.g. fake tax-agency calls, gift card demands, fake 'inspectors'"
        case .lostPet: "e.g. a missing cat or dog, or a friendly pet wandering alone"
        case .other: "e.g. anything that doesn't fit the other types"
        }
    }

    var colorHex: String {
        switch self {
        case .suspicious: "B26A00"
        case .theft: "C62828"
        case .packageTheft: "A0522D"
        case .bikeTheft: "2E7D32"
        case .breakIn: "8E1B1B"
        case .robbery: "7B1240"
        case .carTheft: "3949AB"
        case .vandalism: "6A1B9A"
        case .trespassing: "5D4037"
        case .disturbance: "455A64"
        case .hazard: "B34700"
        case .scam: "00838F"
        case .lostPet: "AD1457"
        case .other: "546E7A"
        }
    }

    var color: Color { Color(hex: colorHex) }
}

nonisolated struct Incident: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var category: IncidentCategory
    /// When the incident happened.
    var date: Date
    /// When it was posted to Beacon.
    var reportedAt: Date = Date()
    var latitude: Double
    var longitude: Double
    var locationName: String
    /// Number of people involved; nil means "not sure". 5 means "5 or more".
    var peopleInvolved: Int?
    var sightingCount: Int = 1
    var details: String?
    var vehicleDescription: String?
    /// Optional photo of property or the scene — never of people.
    var photoData: Data? = nil
    var isFlagged: Bool = false
    var isSample: Bool = false

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var location: CLLocation { CLLocation(latitude: latitude, longitude: longitude) }

    /// Reports fade from the default view after 30 days.
    var isExpired: Bool {
        reportedAt < Date(timeIntervalSinceNow: -30 * 24 * 3600)
    }

    var peopleLabel: String {
        switch peopleInvolved {
        case nil: "Not sure"
        case let count? where count >= 5: "5 or more"
        case let count?: "\(count)"
        }
    }

    var sightingLabel: String {
        sightingCount == 1 ? "1 person reported this" : "\(sightingCount) people reported this"
    }

    var whenLabel: String {
        date.formatted(date: .complete, time: .shortened)
    }

    var shortWhenLabel: String {
        if Calendar.current.isDateInToday(date) {
            return "Today at \(date.formatted(date: .omitted, time: .shortened))"
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday at \(date.formatted(date: .omitted, time: .shortened))"
        }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().hour().minute())
    }

    /// Text used for the share sheet and VoiceOver.
    var summary: String {
        var parts = ["\(category.label) — \(locationName)", shortWhenLabel, sightingLabel]
        if let details, !details.isEmpty { parts.append(details) }
        parts.append("Shared from Beacon, a community safety app.")
        return parts.joined(separator: "\n")
    }

    func distance(from location: CLLocation?) -> CLLocationDistance? {
        guard let location else { return nil }
        return self.location.distance(from: location)
    }

    func distanceLabel(from location: CLLocation?) -> String? {
        guard let metres = distance(from: location) else { return nil }
        if metres < 1000 { return "\(Int((metres / 10).rounded() * 10)) m away" }
        return String(format: "%.1f km away", metres / 1000)
    }
}

nonisolated enum TimeFilter: String, CaseIterable, Identifiable {
    case today, week, month, all

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: "Today"
        case .week: "This week"
        case .month: "This month"
        case .all: "All"
        }
    }

    func contains(_ date: Date) -> Bool {
        switch self {
        case .today: Calendar.current.isDateInToday(date)
        case .week: date > Date(timeIntervalSinceNow: -7 * 24 * 3600)
        case .month: date > Date(timeIntervalSinceNow: -30 * 24 * 3600)
        case .all: true
        }
    }
}

/// The local emergency number, chosen from the device's region so Beacon
/// dials the right service anywhere — 911 in North America, 999 in the
/// UK, 000 in Australia, and 112 (the international GSM standard, which
/// redirects almost everywhere) as the fallback.
nonisolated enum EmergencyNumber {
    static func number(forRegion region: String?) -> String {
        switch region {
        case "US", "CA", "MX", "PH", "CR", "PA", "DO", "SV", "UY": "911"
        case "GB", "IE", "HK", "MY", "KE", "BD", "AE", "SA", "QA": "999"
        case "AU": "000"
        case "NZ": "111"
        case "JP", "CN", "TW", "KP": "110"
        case "BR": "190"
        case "ZA": "10111"
        default: "112"
        }
    }

    static var current: String {
        number(forRegion: Locale.current.region?.identifier)
    }

    static var telURL: URL {
        URL(string: "tel://\(current)") ?? URL(string: "tel://112")!
    }

    /// Digits spaced out so that victims VoiceOver reads "9 1 1", not "nine hundred eleven".
    static var spokenDigits: String {
        current.map(String.init).joined(separator: " ")
    }
}

extension Color {
    nonisolated init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
