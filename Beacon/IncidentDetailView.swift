//
//  IncidentDetailView.swift
//  Beacon (Finder)
//
//  Large, readable incident card with sighting confirmation, sharing,
//  flagging, and the emergency reminder.
//

import SwiftUI
import MapKit

struct IncidentDetailView: View {
    let incident: Incident

    @Environment(IncidentStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(LocationService.self) private var location
    @Environment(CloudSync.self) private var cloud
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showFlagDialog = false
    @State private var showDeleteConfirm = false
    @State private var confirmedNow = false

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    /// Live copy from the store so the sighting count updates in place.
    private var current: Incident {
        store.incidents.first { $0.id == incident.id } ?? incident
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    EmergencyBanner()

                    HStack(spacing: 14) {
                        CategoryBadge(category: current.category, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(current.category.label)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(palette.textPrimary)
                            if current.isSample {
                                Text("Example report")
                                    .font(.footnote.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(palette.secondaryAccent.opacity(0.25), in: Capsule())
                                    .foregroundStyle(palette.textPrimary)
                            }
                        }
                    }

                    SectionCard(palette: palette) {
                        detailRow(icon: "calendar", title: "When", value: current.whenLabel)
                        Divider()
                        detailRow(icon: "mappin.and.ellipse", title: "Where", value: current.locationName)
                        if let distance = current.distanceLabel(from: location.currentLocation) {
                            Divider()
                            detailRow(icon: "location", title: "Distance", value: distance)
                        }
                        Divider()
                        detailRow(icon: "person.2", title: "People involved", value: current.peopleLabel)
                        Divider()
                        detailRow(icon: "eye", title: "Sightings", value: current.sightingLabel)
                    }

                    if let details = current.details, !details.isEmpty {
                        SectionCard(palette: palette) {
                            Text("What happened")
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)
                            FilteredText(
                                text: details,
                                filterOn: settings.familyFilterActive,
                                canReveal: !settings.isMinor,
                                textColor: palette.textPrimary
                            )
                            if settings.familyFilterActive && ContentFilter.containsSensitiveWords(details) {
                                Text(settings.isMinor
                                     ? "Some words are hidden by the family filter."
                                     : "Some words are hidden by the family filter. Tap a blurred word to show it.")
                                    .font(.footnote)
                                    .foregroundStyle(palette.textSecondary)
                            }
                        }
                    }

                    if let vehicle = current.vehicleDescription, !vehicle.isEmpty {
                        SectionCard(palette: palette) {
                            Text("Vehicle")
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)
                            Text(vehicle)
                                .font(.body)
                                .foregroundStyle(palette.textPrimary)
                        }
                    }

                    if let photoData = current.photoData, let photo = photoImage(from: photoData) {
                        photo
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .accessibilityLabel("Photo attached to this report")
                    }

                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: current.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
                    ))) {
                        Annotation(current.category.label, coordinate: current.coordinate) {
                            CategoryBadge(category: current.category, size: 40)
                        }
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .allowsHitTesting(false)
                    .accessibilityLabel("Map showing the report location, \(current.locationName)")

                    Button {
                        store.confirmSighting(current.id)
                        confirmedNow = true
                        Task { await cloud.bump(.sightingCount, incidentID: current.id) }
                    } label: {
                        Label(
                            store.hasConfirmedSighting(current.id) ? "You confirmed this sighting ✓" : "I saw this too",
                            systemImage: "eye"
                        )
                    }
                    .buttonStyle(BigButtonStyle(color: store.hasConfirmedSighting(current.id) ? palette.textSecondary : palette.accent))
                    .disabled(store.hasConfirmedSighting(current.id) || store.hasMarkedNotSeen(current.id))
                    .sensoryFeedback(.success, trigger: confirmedNow)

                    Button {
                        store.markNotSeen(current.id)
                        Task { await cloud.bump(.notSeenCount, incidentID: current.id) }
                    } label: {
                        Label(
                            store.hasMarkedNotSeen(current.id) ? "Noted — you didn't see this ✓" : "I didn't see this",
                            systemImage: "hand.thumbsdown"
                        )
                    }
                    .buttonStyle(BigButtonStyle(
                        color: palette.surface,
                        textColor: store.hasMarkedNotSeen(current.id) ? palette.textSecondary : palette.textPrimary
                    ))
                    .disabled(store.hasMarkedNotSeen(current.id) || store.hasConfirmedSighting(current.id))
                    .accessibilityHint("Marks that you were nearby and did not see this happen.")

                    if store.notSeenCount(for: current.id) > 0 {
                        Label(
                            "\(store.notSeenCount(for: current.id)) \(store.notSeenCount(for: current.id) == 1 ? "person" : "people") didn't see this",
                            systemImage: "hand.thumbsdown"
                        )
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                    }

                    ShareLink(item: current.summary) {
                        Label("Share with family", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(BigButtonStyle(color: palette.secondaryAccent))

                    HStack {
                        Button("Report a problem with this post") {
                            showFlagDialog = true
                        }
                        .foregroundStyle(palette.textSecondary)
                        Spacer()
                        if store.isMine(current.id) || current.isSample {
                            Button("Delete", role: .destructive) {
                                showDeleteConfirm = true
                            }
                        }
                    }
                    .font(.callout)
                    .padding(.top, 4)

                    Text("Reports come from community members and are not verified by police. Stay aware, stay calm.")
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                }
                .padding()
            }
            .background(palette.background)
            .navigationTitle("Report")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("What's wrong with this post?", isPresented: $showFlagDialog, titleVisibility: .visible) {
                Button("It's inaccurate") { flagAndClose() }
                Button("It's discriminatory or targets a person") { flagAndClose() }
                Button("It's spam") { flagAndClose() }
                Button("Wrong location") { flagAndClose() }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete this report?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete report", role: .destructive) {
                    let id = current.id
                    let wasMine = store.isMine(id)
                    store.delete(id)
                    if wasMine {
                        Task { await cloud.deleteRemote(id) }
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func flagAndClose() {
        store.flag(current.id)
        Task { await cloud.bump(.flagCount, incidentID: current.id) }
        dismiss()
    }

    private func photoImage(from data: Data) -> Image? {
#if canImport(UIKit)
        UIImage(data: data).map(Image.init(uiImage:))
#else
        NSImage(data: data).map(Image.init(nsImage:))
#endif
    }

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 26)
                .foregroundStyle(palette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                Text(value)
                    .font(.body.weight(.medium))
                    .foregroundStyle(palette.textPrimary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
