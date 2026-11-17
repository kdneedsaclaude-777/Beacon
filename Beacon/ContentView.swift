//
//  ContentView.swift
//  Beacon (Finder)
//
//  Root view: Beacon Boot-Up loading screen → onboarding → main tabs.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var store = IncidentStore()
    @State private var settings = AppSettings()
    @State private var location = LocationService()
    @State private var cloud = CloudSync()
    @State private var showLoading = true
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    var body: some View {
        Group {
            ZStack {
                if settings.hasOnboarded {
                    MainTabView()
                } else {
                    OnboardingView()
                }

                if settings.hasOnboarded && !settings.hasSeenTutorial && !showLoading {
                    TutorialView {
                        settings.hasSeenTutorial = true
                    }
                    .transition(.opacity)
                }

                if showLoading {
                    BeaconLoadingView(palette: palette)
                        .transition(.opacity)
                }
            }
        }
        .environment(store)
        .environment(settings)
        .environment(location)
        .environment(cloud)
        .tint(palette.accent)
        .preferredColorScheme(settings.preferredScheme)
        .dynamicTypeSize(settings.dynamicTypeOverride ?? dynamicTypeSize)
        .task {
            if settings.hasOnboarded {
                location.requestPermission()
            }
            // Give the beacon a moment to bounce, and location a moment to
            // arrive so sample reports land in the user's real neighbourhood.
            try? await Task.sleep(for: .seconds(1.6))
            store.seedSampleDataIfNeeded(around: location.bestCoordinate)
            withAnimation(.easeOut(duration: 0.5)) {
                showLoading = false
            }
            await cloud.sync(store: store, near: location.currentLocation)
        }
        .onChange(of: location.currentLocation) { _, newLocation in
            // Example reports follow the user's real area once located, in
            // case they were first seeded around the fallback coordinate.
            if let newLocation {
                store.relocateSamplesIfFar(from: newLocation.coordinate)
            }
        }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
}

struct MainTabView: View {
    var body: some View {
        TabView {
            MapScreen()
                .tabItem { Label("Map", systemImage: "map.fill") }

            NavigationStack {
                ReportFlowView()
            }
            .tabItem { Label("Report", systemImage: "plus.circle.fill") }

            InMyAreaView()
                .tabItem { Label("In My Area", systemImage: "location.circle.fill") }

            SafetyView()
                .tabItem { Label("Safety", systemImage: "shield.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview {
    ContentView()
}
