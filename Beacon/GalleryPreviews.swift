//
//  GalleryPreviews.swift
//  Beacon
//
//  Temporary previews used to render gallery screenshots. Safe to delete.
//

import SwiftUI

@MainActor
private struct PreviewHost<Content: View>: View {
    @ViewBuilder var content: Content

    @State private var store: IncidentStore = {
        let store = IncidentStore()
        store.seedSampleDataIfNeeded(around: LocationService.fallbackCoordinate)
        return store
    }()
    @State private var settings: AppSettings = {
        let settings = AppSettings()
        settings.isSignedIn = true
        settings.profileName = "Waltzing Teapot"
        settings.avatar = "🦊"
        settings.ageGroup = .adult
        settings.hasOnboarded = true
        return settings
    }()
    @State private var location = LocationService()
    @State private var cloud = CloudSync()

    var body: some View {
        content
            .environment(store)
            .environment(settings)
            .environment(location)
            .environment(cloud)
    }
}

@MainActor
private struct DetailPreviewHost: View {
    @State private var store: IncidentStore = {
        let store = IncidentStore()
        store.seedSampleDataIfNeeded(around: LocationService.fallbackCoordinate)
        return store
    }()
    @State private var settings: AppSettings = {
        let settings = AppSettings()
        settings.isSignedIn = true
        settings.profileName = "Waltzing Teapot"
        settings.avatar = "🦊"
        settings.ageGroup = .adult
        settings.hasOnboarded = true
        return settings
    }()
    @State private var location = LocationService()
    @State private var cloud = CloudSync()

    var body: some View {
        if let incident = store.incidents.first {
            IncidentDetailView(incident: incident)
                .environment(store)
                .environment(settings)
                .environment(location)
                .environment(cloud)
        }
    }
}

#Preview("Map") {
    let _ = UserDefaults.standard.set(ViewMode.map.rawValue, forKey: "viewMode")
    PreviewHost { MapScreen() }
}

#Preview("Report") {
    PreviewHost { NavigationStack { ReportFlowView() } }
}

#Preview("InMyArea") {
    PreviewHost { InMyAreaView() }
}

#Preview("Safety") {
    PreviewHost { SafetyView() }
}

#Preview("SeniorSafety") {
    PreviewHost { NavigationStack { SeniorSafetyView() } }
}

#Preview("Settings") {
    PreviewHost { SettingsView() }
}

#Preview("Detail") {
    DetailPreviewHost()
}

#Preview("Onboarding") {
    PreviewHost { OnboardingView() }
}

#Preview("MapList") {
    let _ = UserDefaults.standard.set(ViewMode.list.rawValue, forKey: "viewMode")
    PreviewHost { MapScreen() }
}

#Preview("MapGrid") {
    let _ = UserDefaults.standard.set(ViewMode.grid.rawValue, forKey: "viewMode")
    PreviewHost { MapScreen() }
}
