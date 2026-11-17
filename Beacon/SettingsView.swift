//
//  SettingsView.swift
//  Beacon (Finder)
//
//  Themes, text size, Simple Mode, practice reporting, data controls,
//  community guidelines, and about.
//

import SwiftUI

struct SettingsView: View {
    @Environment(IncidentStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(CloudSync.self) private var cloud
    @Environment(LocationService.self) private var location
    @Environment(\.colorScheme) private var colorScheme

    @State private var showClearSamplesConfirm = false

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    profileCard
                    communityCard
                    familyCard
                    appearanceCard
                    accessibilityCard
                    practiceCard
                    dataCard
                    guidelinesCard
                    aboutCard
                }
                .padding()
            }
            .background(palette.background)
            .navigationTitle("Settings")
        }
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Your profile", systemImage: "person.crop.circle")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            AccountView()
        }
    }

    private var communityCard: some View {
        SectionCard(palette: palette) {
            Label("Community sync", systemImage: "icloud")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Text(cloud.status.label)
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            if let lastSync = cloud.lastSync {
                Text("Last synced \(lastSync.formatted(date: .omitted, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }
            Button {
                Task { await cloud.sync(store: store, near: location.currentLocation) }
            } label: {
                Label(cloud.isSyncing ? "Syncing…" : "Sync now", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(BigButtonStyle(color: palette.secondaryAccent))
            .disabled(cloud.isSyncing)
        }
        .task {
            await cloud.refreshAvailability()
        }
    }

    private var familyCard: some View {
        SectionCard(palette: palette) {
            Label("Family filter", systemImage: "eye.slash")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            if settings.isMinor {
                Text("On for your age group — harsh words in reports stay blurred.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            } else {
                Toggle(isOn: Bindable(settings).familyFilter) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Blur harsh words in reports")
                            .font(.body.weight(.medium))
                            .foregroundStyle(palette.textPrimary)
                        Text("Helpful when little eyes glance at your screen. Tap a blurred word to show it.")
                            .font(.footnote)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
            }
        }
    }

    private var appearanceCard: some View {
        SectionCard(palette: palette) {
            Label("Appearance", systemImage: "paintpalette")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            ForEach(AppTheme.allCases) { theme in
                Button {
                    settings.theme = theme
                } label: {
                    HStack {
                        Text(theme.label)
                            .font(.body.weight(.medium))
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Image(systemName: settings.theme == theme ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(settings.theme == theme ? palette.accent : palette.textSecondary)
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(settings.theme == theme ? .isSelected : [])
            }
            if settings.theme == .night {
                Text("Night Mode uses warm, low-glare colours and slightly larger text — easier on the eyes after dark.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }
        }
    }

    private var accessibilityCard: some View {
        SectionCard(palette: palette) {
            Label("Reading & comfort", systemImage: "textformat.size")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Picker("Text size", selection: Bindable(settings).textSize) {
                ForEach(TextSizeChoice.allCases) { choice in
                    Text(choice.label).tag(choice)
                }
            }
            .pickerStyle(.segmented)

            Toggle(isOn: Bindable(settings).highContrast) {
                Text("Higher contrast")
                    .font(.body.weight(.medium))
                    .foregroundStyle(palette.textPrimary)
            }

            Toggle(isOn: Bindable(settings).simpleMode) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Simple Mode")
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                    Text("Fewer options, bigger layout, single-column view.")
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
    }

    private var practiceCard: some View {
        SectionCard(palette: palette) {
            Label("Learn Beacon", systemImage: "graduationcap")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Try the report flow with training wheels on — nothing gets posted.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            NavigationLink {
                ReportFlowView(isPractice: true)
            } label: {
                Label("Practice a report", systemImage: "figure.walk.motion")
            }
            .buttonStyle(BigButtonStyle(color: palette.secondaryAccent))
            Button {
                settings.hasSeenTutorial = false
            } label: {
                Label("Replay the quick tour", systemImage: "arrow.counterclockwise")
                    .font(.body.weight(.medium))
            }
            .foregroundStyle(palette.accent)
        }
    }

    private var dataCard: some View {
        SectionCard(palette: palette) {
            Label("Your data", systemImage: "lock.shield")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Everything is stored on this device. No accounts, no ads, no trackers, and your data is never sold or shared. Ever.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            Button("Remove example reports", role: .destructive) {
                showClearSamplesConfirm = true
            }
            .font(.body.weight(.medium))
            .confirmationDialog("Remove all example reports from the map?", isPresented: $showClearSamplesConfirm, titleVisibility: .visible) {
                Button("Remove examples", role: .destructive) {
                    store.clearSampleData()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var guidelinesCard: some View {
        SectionCard(palette: palette) {
            Label("Community guidelines", systemImage: "hand.raised")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            VStack(alignment: .leading, spacing: 8) {
                guideline("Report what happened — actions and events, not how people look.")
                guideline("Never describe race or ethnicity. It doesn't keep anyone safer.")
                guideline("Don't accuse named people. Beacon is not a courtroom.")
                guideline("In an emergency, always call \(EmergencyNumber.current) first. Beacon is not the police.")
                guideline("Be the neighbour you'd want to have.")
            }
        }
    }

    private func guideline(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(palette.accent)
                .padding(.top, 2)
            Text(text)
                .font(.callout)
                .foregroundStyle(palette.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private var aboutCard: some View {
        SectionCard(palette: palette) {
            HStack(spacing: 12) {
                Text("💠")
                    .font(.system(size: 40))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Beacon")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(palette.textPrimary)
                    Text("See your neighbourhood clearly")
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            Divider()
            Text("Created by KDragon")
                .font(.callout.weight(.medium))
                .foregroundStyle(palette.textPrimary)
            Text("Version 1.0 · Reports are community-submitted and not verified by police.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
        }
    }
}
