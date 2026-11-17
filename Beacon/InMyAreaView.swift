//
//  InMyAreaView.swift
//  Beacon (Finder)
//
//  Radius-based local feed with a weekly summary, trend, and simple
//  plain-language statistics charts.
//

import SwiftUI
import Charts
import CoreLocation

struct InMyAreaView: View {
    @Environment(IncidentStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(LocationService.self) private var location
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedIncident: Incident?

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    private let radiusOptions: [Double] = [0.5, 1, 2, 5]

    private var centre: CLLocation {
        location.currentLocation ?? CLLocation(
            latitude: LocationService.fallbackCoordinate.latitude,
            longitude: LocationService.fallbackCoordinate.longitude
        )
    }

    private var nearby: [Incident] {
        store.incidents(within: settings.radiusKm * 1000, of: centre)
    }

    private var thisWeek: [Incident] {
        nearby.filter { $0.date > Date(timeIntervalSinceNow: -7 * 24 * 3600) }
    }

    private var lastWeek: [Incident] {
        nearby.filter {
            $0.date <= Date(timeIntervalSinceNow: -7 * 24 * 3600)
                && $0.date > Date(timeIntervalSinceNow: -14 * 24 * 3600)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    EmergencyBanner()

                    radiusPicker
                    summaryCard

                    if location.authorization == .denied {
                        SectionCard(palette: palette) {
                            Label("Location is off. Turn it on to see reports near you.", systemImage: "location.slash")
                                .font(.callout)
                                .foregroundStyle(palette.textPrimary)
#if canImport(UIKit)
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                Link(destination: settingsURL) {
                                    Label("Turn on location", systemImage: "gear")
                                }
                                .buttonStyle(BigButtonStyle(color: palette.accent))
                            }
#endif
                        }
                    }

                    if !settings.simpleMode && !nearby.isEmpty {
                        statsSection
                    }

                    Text("Nearest first")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    if nearby.isEmpty {
                        VStack(spacing: 10) {
                            Text("💠")
                                .font(.system(size: 40))
                            Text("No reports in your area")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(palette.textPrimary)
                            Text("That's good news. Try a bigger radius to see more.")
                                .font(.body)
                                .foregroundStyle(palette.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        ForEach(nearby) { incident in
                            Button {
                                selectedIncident = incident
                            } label: {
                                IncidentRow(incident: incident, palette: palette, userLocation: location.currentLocation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(palette.background)
            .navigationTitle("In My Area")
            .sheet(item: $selectedIncident) { incident in
                IncidentDetailView(incident: incident)
            }
        }
    }

    private var radiusPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Show reports within")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            HStack(spacing: 8) {
                ForEach(radiusOptions, id: \.self) { option in
                    Button {
                        settings.radiusKm = option
                    } label: {
                        Text(option < 1 ? "\(Int(option * 1000)) m" : "\(Int(option)) km")
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(
                                settings.radiusKm == option ? palette.accent : palette.surface,
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                            .foregroundStyle(settings.radiusKm == option ? .white : palette.textPrimary)
                    }
                    .accessibilityAddTraits(settings.radiusKm == option ? .isSelected : [])
                }
            }
        }
    }

    private var summaryCard: some View {
        SectionCard(palette: palette) {
            Text("\(thisWeek.count) report\(thisWeek.count == 1 ? "" : "s") near you in the last 7 days")
                .font(.title3.weight(.bold))
                .foregroundStyle(palette.textPrimary)
            HStack(spacing: 6) {
                Image(systemName: trendSymbol)
                    .foregroundStyle(palette.accent)
                Text(trendText)
                    .font(.callout)
                    .foregroundStyle(palette.textSecondary)
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var trendSymbol: String {
        if thisWeek.count < lastWeek.count { return "arrow.down.circle.fill" }
        if thisWeek.count > lastWeek.count { return "arrow.up.circle.fill" }
        return "equal.circle.fill"
    }

    private var trendText: String {
        if thisWeek.count < lastWeek.count { return "Fewer than last week — heading the right way." }
        if thisWeek.count > lastWeek.count { return "More than last week — stay aware, stay calm." }
        return "About the same as last week."
    }

    // MARK: - Charts

    private var last30Days: [Incident] {
        nearby.filter { $0.date > Date(timeIntervalSinceNow: -30 * 24 * 3600) }
    }

    private var categoryCounts: [(category: IncidentCategory, count: Int)] {
        IncidentCategory.allCases.compactMap { category in
            let count = last30Days.count { $0.category == category }
            return count > 0 ? (category, count) : nil
        }
    }

    private var statsSection: some View {
        SectionCard(palette: palette) {
            Text("Last 30 days, by type")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Chart(categoryCounts, id: \.category) { entry in
                BarMark(
                    x: .value("Reports", entry.count),
                    y: .value("Type", entry.category.label)
                )
                .foregroundStyle(entry.category.color)
                .annotation(position: .trailing) {
                    Text("\(entry.count)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(categoryCounts.count) * 44 + 20)
            .accessibilityLabel(chartAccessibilitySummary)

            Text(plainLanguageCaption)
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
        }
    }

    private var chartAccessibilitySummary: String {
        categoryCounts.map { "\($0.category.label): \($0.count)" }.joined(separator: ", ")
    }

    private var plainLanguageCaption: String {
        guard let top = categoryCounts.max(by: { $0.count < $1.count }) else {
            return "No reports in the last 30 days."
        }
        return "The most common report near you is “\(top.category.label.lowercased())”."
    }
}
