//
//  MapScreen.swift
//  Beacon (Finder)
//
//  Home screen: incidents shown as a map, list, or grid, with search,
//  time/category filters, a legend, and Follow Me location sensing.
//

import SwiftUI
import MapKit

nonisolated enum ViewMode: String, CaseIterable, Identifiable {
    case map, list, grid
    var id: String { rawValue }

    var label: String {
        switch self {
        case .map: "Map"
        case .list: "List"
        case .grid: "Grid"
        }
    }

    var symbol: String {
        switch self {
        case .map: "map"
        case .list: "list.bullet"
        case .grid: "square.grid.2x2"
        }
    }
}

struct MapScreen: View {
    @Environment(IncidentStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(LocationService.self) private var location
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("viewMode") private var viewModeRaw = ViewMode.map.rawValue
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchText = ""
    @State private var timeFilter: TimeFilter = .month
    @State private var categoryFilter: IncidentCategory?
    @State private var showOlder = false
    @State private var heatMapOn = false
    @State private var showLegend = false
    @State private var selectedIncident: Incident?
    @State private var showEmergencyBanner = true
    @State private var isSearchingPlace = false
    @State private var visibleRegion: MKCoordinateRegion?

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    private var viewMode: ViewMode {
        get { ViewMode(rawValue: viewModeRaw) ?? .map }
    }

    private var filteredIncidents: [Incident] {
        var results = store.visibleIncidents(showOlder: showOlder)
            .filter { timeFilter.contains($0.date) }
        if let categoryFilter {
            results = results.filter { $0.category == categoryFilter }
        }
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            results = results.filter { incident in
                incident.category.label.lowercased().contains(query)
                    || (incident.details ?? "").lowercased().contains(query)
                    || incident.locationName.lowercased().contains(query)
                    || (incident.vehicleDescription ?? "").lowercased().contains(query)
            }
        }
        if let current = location.currentLocation {
            results.sort {
                $0.location.distance(from: current) < $1.location.distance(from: current)
            }
        } else {
            results.sort { $0.date > $1.date }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                header

                switch viewMode {
                case .map: mapView
                case .list: listView
                case .grid: gridView
                }
            }
            .background(palette.background)
            .navigationTitle("Beacon")
            .toolbarTitleDisplayMode(.inline)
            .sheet(item: $selectedIncident) { incident in
                IncidentDetailView(incident: incident)
            }
            .sheet(isPresented: $showLegend) {
                legendView
            }
            // The 911 banner can be tucked away for the moment, but it always
            // returns when the user comes back to this screen. There is
            // deliberately no way to disable it permanently.
            .onAppear {
                showEmergencyBanner = true
            }
        }
    }

    // MARK: - Header (banner, search, filters)

    private var header: some View {
        VStack(spacing: 10) {
            if showEmergencyBanner {
                HStack(spacing: 8) {
                    EmergencyBanner()
                    Button {
                        withAnimation { showEmergencyBanner = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(palette.textSecondary)
                    }
                    .accessibilityLabel("Hide emergency banner")
                }
            }

            if location.currentLocation == nil {
                locationNudge
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(palette.textSecondary)
                TextField("Search street, category, or keyword", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit { findPlaceOnMap() }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(palette.textSecondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))

            if !searchText.isEmpty && viewMode == .map {
                Button {
                    findPlaceOnMap()
                } label: {
                    Label("Find “\(searchText)” on the map", systemImage: "mappin.and.ellipse")
                        .font(.callout.weight(.medium))
                }
                .disabled(isSearchingPlace)
            }

            Picker("View", selection: Binding(
                get: { viewMode },
                set: { viewModeRaw = $0.rawValue }
            )) {
                ForEach(ViewMode.allCases) { mode in
                    Label(mode.label, systemImage: mode.symbol).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            filterChips
        }
        .padding(.horizontal)
    }

    /// Shown until a real location fix arrives: re-asks when the system
    /// prompt was never answered, or links to Settings after a denial.
    private var locationNudge: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.slash")
                .foregroundStyle(palette.secondaryAccent)
            Text(location.authorization == .denied
                 ? "Location is off — Beacon can't show what's near you."
                 : "Finding your location…")
                .font(.callout)
                .foregroundStyle(palette.textPrimary)
            Spacer()
            if location.authorization == .denied {
#if canImport(UIKit)
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    Link("Turn on", destination: settingsURL)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
#endif
            } else {
                Button("Retry") {
                    location.retry()
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(palette.accent)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(TimeFilter.allCases) { filter in
                        Button(filter.label) { timeFilter = filter }
                    }
                } label: {
                    chipLabel("🕐 \(timeFilter.label)", active: timeFilter != .all)
                }

                Menu {
                    Button("All categories") { categoryFilter = nil }
                    ForEach(IncidentCategory.allCases) { category in
                        Button {
                            categoryFilter = category
                        } label: {
                            Label(category.label, systemImage: category.symbol)
                        }
                    }
                } label: {
                    chipLabel(categoryFilter?.label ?? "All categories", active: categoryFilter != nil)
                }

                if !settings.simpleMode {
                    Button {
                        showOlder.toggle()
                    } label: {
                        chipLabel("Show older", active: showOlder)
                    }
                }

                if viewMode == .map {
                    Button {
                        heatMapOn.toggle()
                    } label: {
                        chipLabel("🔥 Heat map", active: heatMapOn)
                    }
                    .accessibilityHint("Shades the areas where reports cluster instead of showing individual pins.")
                }

                Button {
                    showLegend = true
                } label: {
                    chipLabel("Legend", active: false)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func chipLabel(_ text: String, active: Bool) -> some View {
        Text(text)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(active ? palette.accent : palette.surface, in: Capsule())
            .foregroundStyle(active ? .white : palette.textPrimary)
    }

    // MARK: - Map view

    private var mapView: some View {
        Map(position: $position) {
            UserAnnotation()
            if heatMapOn {
                // Overlapping translucent circles read as a heat map:
                // more reports nearby, deeper the shading.
                ForEach(filteredIncidents) { incident in
                    MapCircle(center: incident.coordinate, radius: 250)
                        .foregroundStyle(Color(hex: "B34700").opacity(0.16))
                        .mapOverlayLevel(level: .aboveRoads)
                }
            } else {
                ForEach(filteredIncidents) { incident in
                    Annotation(incident.category.label, coordinate: incident.coordinate) {
                        incidentPin(incident)
                    }
                }
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .onMapCameraChange { context in
            visibleRegion = context.region
        }
        .overlay(alignment: .bottomTrailing) {
            followMeButton
                .padding()
        }
        .overlay(alignment: .bottomLeading) {
            zoomButtons
                .padding()
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    /// Big, senior-friendly zoom buttons (pinch also works: on the
    /// simulator, hold Option and drag to pinch).
    private var zoomButtons: some View {
        VStack(spacing: 10) {
            Button {
                zoom(by: 0.5)
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                    .frame(width: 46, height: 46)
                    .background(palette.surface, in: Circle())
                    .foregroundStyle(palette.textPrimary)
            }
            .accessibilityLabel("Zoom in")
            Button {
                zoom(by: 2)
            } label: {
                Image(systemName: "minus")
                    .font(.title3.weight(.bold))
                    .frame(width: 46, height: 46)
                    .background(palette.surface, in: Circle())
                    .foregroundStyle(palette.textPrimary)
            }
            .accessibilityLabel("Zoom out")
        }
        .shadow(color: .black.opacity(0.2), radius: 4)
    }

    private func zoom(by factor: Double) {
        guard var region = visibleRegion else { return }
        region.span.latitudeDelta = min(120, max(0.0015, region.span.latitudeDelta * factor))
        region.span.longitudeDelta = min(120, max(0.0015, region.span.longitudeDelta * factor))
        withAnimation(.easeInOut(duration: 0.3)) {
            position = .region(region)
        }
    }

    private func incidentPin(_ incident: Incident) -> some View {
        Button {
            selectedIncident = incident
        } label: {
            ZStack(alignment: .topTrailing) {
                CategoryBadge(
                    category: incident.category,
                    size: incident.sightingCount > 2 ? 46 : 40,
                    glow: settings.theme == .night
                )
                if incident.sightingCount > 1 {
                    Text("\(incident.sightingCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Color(hex: "1A1A1A"), in: Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel(pinAccessibilityLabel(incident))
    }

    private func pinAccessibilityLabel(_ incident: Incident) -> String {
        var label = "\(incident.category.label), \(incident.shortWhenLabel), \(incident.sightingLabel)."
        if let distance = incident.distanceLabel(from: location.currentLocation) {
            label += " \(distance)."
        }
        return label
    }

    private var followMeButton: some View {
        Button {
            withAnimation { position = .userLocation(fallback: .automatic) }
        } label: {
            Label("Follow me", systemImage: position.followsUserLocation ? "location.fill" : "location")
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(palette.surface, in: Capsule())
                .foregroundStyle(position.followsUserLocation ? palette.accent : palette.textPrimary)
        }
        .accessibilityLabel(position.followsUserLocation ? "Following your location" : "Centre map on my location")
    }

    // MARK: - List view

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if filteredIncidents.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredIncidents) { incident in
                        Button {
                            selectedIncident = incident
                        } label: {
                            IncidentRow(incident: incident, palette: palette, userLocation: location.currentLocation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Grid view

    private var gridColumns: [GridItem] {
        settings.simpleMode
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 10) {
                if filteredIncidents.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredIncidents) { incident in
                        Button {
                            selectedIncident = incident
                        } label: {
                            IncidentTile(incident: incident, palette: palette, userLocation: location.currentLocation)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("💠")
                .font(.system(size: 44))
            Text("No reports match")
                .font(.title3.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
            Text("Try a wider time range or clear the search. Quiet is good news!")
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Legend

    private var legendView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(IncidentCategory.allCases) { category in
                        HStack(alignment: .top, spacing: 14) {
                            CategoryBadge(category: category, size: 44)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.label)
                                    .font(.headline)
                                    .foregroundStyle(palette.textPrimary)
                                Text(category.plainDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(palette.textSecondary)
                                Text(category.examples)
                                    .font(.footnote.italic())
                                    .foregroundStyle(palette.textSecondary.opacity(0.85))
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding()
            }
            .background(palette.background)
            .navigationTitle("Map legend")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showLegend = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Place search

    private func findPlaceOnMap() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }
        isSearchingPlace = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = MKCoordinateRegion(
            center: location.bestCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
        Task {
            defer { isSearchingPlace = false }
            guard let response = try? await MKLocalSearch(request: request).start(),
                  let item = response.mapItems.first else { return }
            withAnimation {
                position = .region(MKCoordinateRegion(
                    center: item.placemark.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                ))
                viewModeRaw = ViewMode.map.rawValue
            }
        }
    }
}

// MARK: - Row & tile

struct IncidentRow: View {
    let incident: Incident
    let palette: ThemePalette
    let userLocation: CLLocation?

    var body: some View {
        HStack(spacing: 14) {
            CategoryBadge(category: incident.category, size: 46)
            VStack(alignment: .leading, spacing: 4) {
                Text(incident.category.label)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                Text(incident.shortWhenLabel)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                HStack(spacing: 10) {
                    if let distance = incident.distanceLabel(from: userLocation) {
                        Label(distance, systemImage: "location")
                    }
                    Label("\(incident.sightingCount)", systemImage: "eye")
                }
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(palette.textSecondary)
        }
        .padding(14)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

struct IncidentTile: View {
    let incident: Incident
    let palette: ThemePalette
    let userLocation: CLLocation?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                CategoryBadge(category: incident.category, size: 40)
                Spacer()
                Label("\(incident.sightingCount)", systemImage: "eye")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }
            Text(incident.category.label)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.leading)
            Text(incident.shortWhenLabel)
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            if let distance = incident.distanceLabel(from: userLocation) {
                Text(distance)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}
