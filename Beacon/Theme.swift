//
//  Theme.swift
//  Beacon (Finder)
//
//  Colour themes (Daylight, Night Watch, Night Mode) and user settings.
//  All palettes meet WCAG AA contrast; colour is never the only signal.
//

import SwiftUI
import Observation

nonisolated enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case daylight
    case nightWatch
    case night

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Match device"
        case .daylight: "Daylight"
        case .nightWatch: "Night Watch (dark)"
        case .night: "Night Mode 🌙"
        }
    }
}

/// Age bands only — Beacon never asks for a birthday. Used to shape the
/// experience: what's shown, what's blurred, and which tips appear.
nonisolated enum AgeGroup: String, CaseIterable, Identifiable {
    case under13
    case teen
    case youngAdult
    case adult
    case midAdult
    case senior

    var id: String { rawValue }

    var label: String {
        switch self {
        case .under13: "Under 13"
        case .teen: "13–17"
        case .youngAdult: "18–29"
        case .adult: "30–49"
        case .midAdult: "50–64"
        case .senior: "65+"
        }
    }

    var emoji: String {
        switch self {
        case .under13: "🧒"
        case .teen: "🎒"
        case .youngAdult: "🚶"
        case .adult: "🏡"
        case .midAdult: "🌳"
        case .senior: "🌟"
        }
    }

    var isMinor: Bool { self == .under13 || self == .teen }

    /// Under-13s can look at the map with family but can't post reports.
    var canPost: Bool { self != .under13 }
}

nonisolated enum TextSizeChoice: String, CaseIterable, Identifiable {
    case system
    case large
    case extraLarge
    case huge

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: "Small"
        case .large: "Large"
        case .extraLarge: "Extra large"
        case .huge: "Huge"
        }
    }

    var dynamicTypeSize: DynamicTypeSize? {
        switch self {
        case .system: nil
        case .large: .xLarge
        case .extraLarge: .xxxLarge
        case .huge: .accessibility2
        }
    }
}

nonisolated struct ThemePalette {
    var background: Color
    var surface: Color
    var textPrimary: Color
    var textSecondary: Color
    var accent: Color
    var secondaryAccent: Color
    /// Colour of the beacon loading beam and glows.
    var beam: Color
    /// Explicit scheme forced by the theme; nil follows the device.
    var preferredScheme: ColorScheme?

    static let daylight = ThemePalette(
        background: Color(hex: "FAFAF7"),
        surface: .white,
        textPrimary: Color(hex: "1A1A1A"),
        textSecondary: Color(hex: "55554F"),
        accent: Color(hex: "00695C"),
        secondaryAccent: Color(hex: "37507A"),
        beam: Color(hex: "00695C"),
        preferredScheme: .light
    )

    static let nightWatch = ThemePalette(
        background: Color(hex: "12161C"),
        surface: Color(hex: "1E242D"),
        textPrimary: Color(hex: "F2F2F0"),
        textSecondary: Color(hex: "B5BAC2"),
        accent: Color(hex: "4DB6AC"),
        secondaryAccent: Color(hex: "8FA8D0"),
        beam: Color(hex: "4DB6AC"),
        preferredScheme: .dark
    )

    static let night = ThemePalette(
        background: Color(hex: "0C0F13"),
        surface: Color(hex: "171B21"),
        textPrimary: Color(hex: "F2EFE9"),
        textSecondary: Color(hex: "C7BFA9"),
        accent: Color(hex: "D4A24E"),
        secondaryAccent: Color(hex: "B08D57"),
        beam: Color(hex: "D4A24E"),
        preferredScheme: .dark
    )

    var highContrast: ThemePalette {
        var palette = self
        if preferredScheme == .dark {
            palette.background = .black
            palette.textPrimary = .white
        } else {
            palette.background = .white
            palette.textPrimary = .black
            palette.accent = Color(hex: "005044")
        }
        return palette
    }
}

@Observable
final class AppSettings {
    private static let defaults = UserDefaults.standard

    var theme: AppTheme {
        didSet { Self.defaults.set(theme.rawValue, forKey: "theme") }
    }
    var textSize: TextSizeChoice {
        didSet { Self.defaults.set(textSize.rawValue, forKey: "textSize") }
    }
    var highContrast: Bool {
        didSet { Self.defaults.set(highContrast, forKey: "highContrast") }
    }
    /// Simple Mode: fewer options, larger layouts, single-column grid.
    var simpleMode: Bool {
        didSet { Self.defaults.set(simpleMode, forKey: "simpleMode") }
    }
    var hasOnboarded: Bool {
        didSet { Self.defaults.set(hasOnboarded, forKey: "hasOnboarded") }
    }
    /// "In My Area" radius in kilometres.
    var radiusKm: Double {
        didSet { Self.defaults.set(radiusKm, forKey: "radiusKm") }
    }
    var trustedContactName: String {
        didSet { Self.defaults.set(trustedContactName, forKey: "trustedContactName") }
    }
    var trustedContactPhone: String {
        didSet { Self.defaults.set(trustedContactPhone, forKey: "trustedContactPhone") }
    }
    var dailyCheckInEnabled: Bool {
        didSet { Self.defaults.set(dailyCheckInEnabled, forKey: "dailyCheckInEnabled") }
    }
    /// Daily check-in time as minutes from midnight, half-hour steps only
    /// (e.g. 600 = 10:00 AM, 630 = 10:30 AM).
    var dailyCheckInMinutes: Int {
        didSet { Self.defaults.set(dailyCheckInMinutes, forKey: "dailyCheckInMinutes") }
    }
    /// End of an active Walk Timer, if any.
    var walkTimerEnd: Date? {
        didSet { Self.defaults.set(walkTimerEnd, forKey: "walkTimerEnd") }
    }
    /// Local profile ("sign in" lives on this device only — no server, no password).
    var profileName: String {
        didSet { Self.defaults.set(profileName, forKey: "profileName") }
    }
    var ageGroup: AgeGroup? {
        didSet { Self.defaults.set(ageGroup?.rawValue, forKey: "ageGroup") }
    }
    var isSignedIn: Bool {
        didSet { Self.defaults.set(isSignedIn, forKey: "isSignedIn") }
    }
    /// Family filter: blurs harsh words in report text. On by default,
    /// locked on for minors.
    var familyFilter: Bool {
        didSet { Self.defaults.set(familyFilter, forKey: "familyFilter") }
    }
    var hasSeenTutorial: Bool {
        didSet { Self.defaults.set(hasSeenTutorial, forKey: "hasSeenTutorial") }
    }
    /// Profile avatar (emoji) — friendly, anonymous identity.
    var avatar: String {
        didSet { Self.defaults.set(avatar, forKey: "avatar") }
    }
    /// Guideline strikes: inappropriate posts earn strikes; three removes
    /// posting access on this device.
    var strikeCount: Int {
        didSet { Self.defaults.set(strikeCount, forKey: "strikeCount") }
    }
    var isBanned: Bool {
        didSet { Self.defaults.set(isBanned, forKey: "isBanned") }
    }

    init() {
        let defaults = Self.defaults
        theme = AppTheme(rawValue: defaults.string(forKey: "theme") ?? "") ?? .system
        textSize = TextSizeChoice(rawValue: defaults.string(forKey: "textSize") ?? "") ?? .system
        highContrast = defaults.bool(forKey: "highContrast")
        simpleMode = defaults.bool(forKey: "simpleMode")
        hasOnboarded = defaults.bool(forKey: "hasOnboarded")
        radiusKm = defaults.object(forKey: "radiusKm") as? Double ?? 1.0
        trustedContactName = defaults.string(forKey: "trustedContactName") ?? ""
        trustedContactPhone = defaults.string(forKey: "trustedContactPhone") ?? ""
        dailyCheckInEnabled = defaults.bool(forKey: "dailyCheckInEnabled")
        dailyCheckInMinutes = defaults.object(forKey: "dailyCheckInMinutes") as? Int ?? 600
        walkTimerEnd = defaults.object(forKey: "walkTimerEnd") as? Date
        profileName = defaults.string(forKey: "profileName") ?? ""
        ageGroup = AgeGroup(rawValue: defaults.string(forKey: "ageGroup") ?? "")
        isSignedIn = defaults.bool(forKey: "isSignedIn")
        familyFilter = defaults.object(forKey: "familyFilter") as? Bool ?? true
        hasSeenTutorial = defaults.bool(forKey: "hasSeenTutorial")
        avatar = defaults.string(forKey: "avatar") ?? "🙂"
        strikeCount = defaults.integer(forKey: "strikeCount")
        isBanned = defaults.bool(forKey: "isBanned")
    }

    var isMinor: Bool { ageGroup?.isMinor ?? false }

    /// Minors can't turn the word filter off.
    var familyFilterActive: Bool { familyFilter || isMinor }

    /// The active palette. The device scheme decides only when theme is .system.
    func palette(for deviceScheme: ColorScheme) -> ThemePalette {
        let base: ThemePalette = switch theme {
        case .system: deviceScheme == .dark ? .nightWatch : .daylight
        case .daylight: .daylight
        case .nightWatch: .nightWatch
        case .night: .night
        }
        return highContrast ? base.highContrast : base
    }

    var preferredScheme: ColorScheme? {
        switch theme {
        case .system: nil
        case .daylight: .light
        case .nightWatch, .night: .dark
        }
    }

    /// Night Mode bumps text one step up unless the user set an explicit size.
    var dynamicTypeOverride: DynamicTypeSize? {
        if let explicit = textSize.dynamicTypeSize { return explicit }
        return theme == .night ? .xLarge : nil
    }
}
