//
//  ReportFlowView.swift
//  Beacon (Finder)
//
//  Step-by-step report wizard: one question per screen, big buttons,
//  bias-aware description guidance, duplicate detection, practice mode.
//

import SwiftUI
import MapKit
import PhotosUI

struct ReportFlowView: View {
    var initialCategory: IncidentCategory?
    /// Practice mode walks through the whole flow but never saves.
    var isPractice = false

    @Environment(IncidentStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(LocationService.self) private var location
    @Environment(CloudSync.self) private var cloud
    @Environment(\.colorScheme) private var colorScheme

    private enum Step: Int, CaseIterable {
        case category, place, when, people, details, review
    }

    @State private var step: Step = .category
    @State private var category: IncidentCategory?
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var date = Date()
    /// nil = not chosen yet; -1 = "not sure"; 5 = "5 or more".
    @State private var people: Int?
    @State private var details = ""
    @State private var vehicle = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var duplicate: Incident?
    @State private var showDuplicateAlert = false
    @State private var showAddressAlert = false
    @State private var showLanguageAlert = false
    @State private var languageAlertMessage = ""
    @State private var submitted = false
    @State private var didSubmitHaptic = false

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            if settings.isBanned && !isPractice {
                bannedView
            } else if !settings.isSignedIn && !isPractice {
                ScrollView {
                    AccountView(embedded: true)
                        .padding()
                }
            } else if settings.ageGroup?.canPost == false && !isPractice {
                under13View
            } else if submitted {
                successView
            } else {
                progressHeader
                ScrollView {
                    stepContent
                        .padding()
                }
                navigationButtons
            }
        }
        .background(palette.background)
        .navigationTitle(isPractice ? "Practice report" : "New report")
        .toolbarTitleDisplayMode(.inline)
        .onAppear {
            if let initialCategory, category == nil {
                category = initialCategory
            }
        }
        .alert("Is this the same incident?", isPresented: $showDuplicateAlert, presenting: duplicate) { existing in
            Button("Yes — add my sighting") {
                store.confirmSighting(existing.id)
                submitted = true
                didSubmitHaptic.toggle()
            }
            Button("No — post my report") {
                saveReport()
            }
            Button("Cancel", role: .cancel) {}
        } message: { existing in
            Text("A similar report (\(existing.category.label), \(existing.shortWhenLabel)) is already nearby. Adding your sighting keeps the map tidy.")
        }
        .alert("Please remove the exact address", isPresented: $showAddressAlert) {
            Button("Edit my description") {
                withAnimation { step = .details }
            }
        } message: {
            Text("Your description looks like it includes a street address or unit number. For everyone's privacy, the map pin (rounded to the block) is all the location a report needs.")
        }
        .alert("Post blocked", isPresented: $showLanguageAlert) {
            Button(settings.isBanned ? "OK" : "Edit my description") {
                if !settings.isBanned {
                    withAnimation { step = .details }
                }
            }
        } message: {
            Text(languageAlertMessage)
        }
        .sensoryFeedback(.success, trigger: didSubmitHaptic)
    }

    private var bannedView: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 56))
                .foregroundStyle(palette.textSecondary)
            Text("Posting is turned off")
                .font(.title.weight(.bold))
                .foregroundStyle(palette.textPrimary)
            Text("Reports with inappropriate language broke the community guidelines three times, so posting has been removed on this device. You can still view the map and use the safety tools.")
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
    }

    private var under13View: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("🧒")
                .font(.system(size: 64))
            Text("Explorer mode")
                .font(.title.weight(.bold))
                .foregroundStyle(palette.textPrimary)
            Text("You can look at the map and learn with your family, but posting reports is for ages 13 and up. If you see something wrong, tell a grown-up!")
                .font(.title3)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
    }

    // MARK: - Progress

    private var progressHeader: some View {
        VStack(spacing: 8) {
            if isPractice {
                Text("Practice mode — nothing will be posted")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(palette.secondaryAccent.opacity(0.25))
                    .foregroundStyle(palette.textPrimary)
            }
            HStack(spacing: 6) {
                ForEach(Step.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s.rawValue <= step.rawValue ? palette.accent : palette.surface)
                        .frame(height: 6)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .accessibilityElement()
            .accessibilityLabel("Step \(step.rawValue + 1) of \(Step.allCases.count)")
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .category: categoryStep
        case .place: placeStep
        case .when: whenStep
        case .people: peopleStep
        case .details: detailsStep
        case .review: reviewStep
        }
    }

    private var categoryStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepTitle("What happened?")
            ForEach(IncidentCategory.allCases) { option in
                Button {
                    category = option
                } label: {
                    HStack(spacing: 14) {
                        CategoryBadge(category: option, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.label)
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)
                            Text(option.plainDescription)
                                .font(.footnote)
                                .foregroundStyle(palette.textSecondary)
                                .multilineTextAlignment(.leading)
                            Text(option.examples)
                                .font(.footnote.italic())
                                .foregroundStyle(palette.textSecondary.opacity(0.85))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: category == option ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(category == option ? palette.accent : palette.textSecondary)
                    }
                    .padding(12)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(category == option ? palette.accent : .clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .help(option.examples)
                .accessibilityAddTraits(category == option ? .isSelected : [])
            }
        }
    }

    private var placeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepTitle("Where did it happen?")
            Text("Tap the map to place the pin, or use your current location. Pins are rounded to the block for privacy — you never need an exact address.")
                .font(.body)
                .foregroundStyle(palette.textSecondary)

            MapReader { proxy in
                Map(position: $mapPosition) {
                    UserAnnotation()
                    if let coordinate {
                        Annotation("Report location", coordinate: coordinate) {
                            CategoryBadge(category: category ?? .other, size: 44)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .onTapGesture { point in
                    if let tapped = proxy.convert(point, from: .local) {
                        coordinate = tapped
                    }
                }
            }
            .accessibilityLabel("Map. Double tap to place the report pin. You can also use the button below to use your current location.")

            Button {
                coordinate = location.bestCoordinate
                withAnimation { mapPosition = .userLocation(fallback: .automatic) }
            } label: {
                Label("Use my current location", systemImage: "location.fill")
            }
            .buttonStyle(BigButtonStyle(color: palette.secondaryAccent))

            if coordinate != nil {
                Label("Pin placed", systemImage: "checkmark.circle.fill")
                    .font(.callout.weight(.medium))
                    .foregroundStyle(palette.accent)
            }
        }
    }

    private var whenStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepTitle("When did it happen?")
            SectionCard(palette: palette) {
                DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                    .font(.body)
                Divider()
                DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                    .font(.body)
            }
            Text("If you're not sure of the exact time, your best guess is fine.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
        }
    }

    private var peopleStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepTitle("How many people were involved?")
            ForEach([1, 2, 3, 4, 5, -1], id: \.self) { option in
                Button {
                    people = option
                } label: {
                    HStack {
                        Text(option == -1 ? "Not sure" : option == 5 ? "5 or more" : "\(option)")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(palette.textPrimary)
                        Spacer()
                        Image(systemName: people == option ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(people == option ? palette.accent : palette.textSecondary)
                    }
                    .padding(16)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(people == option ? palette.accent : .clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(people == option ? .isSelected : [])
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepTitle("What did you see? (optional)")

            SectionCard(palette: palette) {
                Label {
                    Text("Describe **actions and events**, like “checking car door handles.” Please don't describe race, ethnicity, or how someone looks — it doesn't help neighbours stay safe, and it can hurt people.")
                } icon: {
                    Image(systemName: "heart.circle")
                        .foregroundStyle(palette.accent)
                }
                .font(.callout)
                .foregroundStyle(palette.textPrimary)
            }

            TextField("What happened…", text: $details, axis: .vertical)
                .lineLimit(4...8)
                .padding(14)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))

            Label("Privacy reminder: never type an exact address or unit number. The map pin (rounded to the block) is all the location a report needs.", systemImage: "lock.shield")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)

            Text("Vehicle involved? (optional)")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            TextField("Colour, type, plate if seen", text: $vehicle)
                .padding(14)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))

            // No photos on suspicious-activity reports: those would be
            // photos of people, and Beacon doesn't do that.
            if category != .suspicious {
                photoSection
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add a photo? (optional)")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Property and scenes only — a smashed window, a damaged fence. Never photos of people.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)

            if let photoData, let image = loadedImage(from: photoData) {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel("Photo attached to this report")
                Button("Remove photo", role: .destructive) {
                    self.photoData = nil
                    photoItem = nil
                }
                .font(.body.weight(.medium))
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Choose a photo", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(BigButtonStyle(color: palette.secondaryAccent))
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let raw = try? await newItem.loadTransferable(type: Data.self) {
                    photoData = Self.compressed(raw)
                }
            }
        }
    }

    private func loadedImage(from data: Data) -> Image? {
#if canImport(UIKit)
        UIImage(data: data).map(Image.init(uiImage:))
#else
        NSImage(data: data).map(Image.init(nsImage:))
#endif
    }

    /// Downscale to keep reports small enough for CloudKit records.
    nonisolated private static func compressed(_ data: Data) -> Data {
#if canImport(UIKit)
        guard let image = UIImage(data: data) else { return data }
        let maxSide: CGFloat = 1200
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.7) ?? data
#else
        return data
#endif
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepTitle("Check your report")
            SectionCard(palette: palette) {
                reviewRow("What", category?.label ?? "—")
                Divider()
                reviewRow("Where", coordinate == nil ? "—" : "Pin placed on map")
                Divider()
                reviewRow("When", date.formatted(date: .abbreviated, time: .shortened))
                Divider()
                reviewRow("People", people == -1 ? "Not sure" : people == 5 ? "5 or more" : people.map(String.init) ?? "—")
                if !details.isEmpty {
                    Divider()
                    reviewRow("Details", details)
                }
                if !vehicle.isEmpty {
                    Divider()
                    reviewRow("Vehicle", vehicle)
                }
                if photoData != nil && category != .suspicious {
                    Divider()
                    reviewRow("Photo", "1 photo attached")
                }
            }
            Text(isPractice
                 ? "This is practice — nothing will be posted."
                 : "Your report is anonymous. Neighbours will see it on the map.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)

            Label("One last privacy check: no exact addresses in your description, right?", systemImage: "lock.shield")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
        }
    }

    private func reviewRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(palette.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }

    private func stepTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(palette.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Navigation

    private var canContinue: Bool {
        switch step {
        case .category: category != nil
        case .place: coordinate != nil
        case .when: true
        case .people: people != nil
        case .details: true
        case .review: true
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if step != .category {
                Button("Back") {
                    withAnimation { step = Step(rawValue: step.rawValue - 1) ?? .category }
                }
                .buttonStyle(BigButtonStyle(color: palette.surface, textColor: palette.textPrimary))
                .frame(maxWidth: 120)
            }
            Button(step == .review ? (isPractice ? "Finish practice" : "Post report") : "Next") {
                if step == .review {
                    submit()
                } else {
                    withAnimation { step = Step(rawValue: step.rawValue + 1) ?? .review }
                }
            }
            .buttonStyle(BigButtonStyle(color: canContinue ? palette.accent : palette.textSecondary))
            .disabled(!canContinue)
        }
        .padding()
    }

    // MARK: - Submit

    private func submit() {
        if isPractice {
            submitted = true
            didSubmitHaptic.toggle()
            return
        }
        guard let category, let coordinate else { return }

        let freeText = "\(details) \(vehicle)"
        if Moderation.looksLikeExactAddress(freeText) {
            showAddressAlert = true
            return
        }
        if Moderation.containsBlockedWords(freeText) {
            settings.strikeCount += 1
            if settings.strikeCount >= 3 {
                settings.isBanned = true
                settings.isSignedIn = false
                languageAlertMessage = "That language breaks the community guidelines. This was your third strike, so posting has been turned off and you've been signed out."
            } else {
                let remaining = 3 - settings.strikeCount
                languageAlertMessage = "That language breaks the community guidelines and can't be posted. Warning \(settings.strikeCount) of 3 — \(remaining) more and posting will be turned off."
            }
            showLanguageAlert = true
            return
        }

        if let existing = store.possibleDuplicate(category: category, coordinate: coordinate, date: date) {
            duplicate = existing
            showDuplicateAlert = true
            return
        }
        saveReport()
    }

    private func saveReport() {
        guard let category, let coordinate else { return }
        // Round to ~3 decimal places (about a city block) for privacy.
        let snapped = CLLocationCoordinate2D(
            latitude: (coordinate.latitude * 1000).rounded() / 1000,
            longitude: (coordinate.longitude * 1000).rounded() / 1000
        )
        Task {
            let name = await Self.approximateName(for: snapped)
            let incident = Incident(
                category: category,
                date: date,
                latitude: snapped.latitude,
                longitude: snapped.longitude,
                locationName: name,
                peopleInvolved: people == -1 ? nil : people,
                details: details.isEmpty ? nil : details,
                vehicleDescription: vehicle.isEmpty ? nil : vehicle,
                photoData: category == .suspicious ? nil : photoData
            )
            store.add(incident)
            submitted = true
            didSubmitHaptic.toggle()
            await cloud.upload(incident, store: store)
        }
    }

    nonisolated private static func approximateName(for coordinate: CLLocationCoordinate2D) async -> String {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return "Nearby area"
        }
        if let street = placemark.thoroughfare { return "\(street) area" }
        if let area = placemark.subLocality ?? placemark.locality { return "\(area) area" }
        return "Nearby area"
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("💠")
                .font(.system(size: 72))
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(palette.accent)
            Text(isPractice ? "Practice complete!" : "Thank you!")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(palette.textPrimary)
            Text(isPractice
                 ? "You've got it — nothing was posted. When it's real, it works exactly the same way."
                 : "Your report is on the map. Your neighbours appreciate you looking out for them.")
                .font(.title3)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Done") {
                resetFlow()
            }
            .buttonStyle(BigButtonStyle(color: palette.accent))
            .padding(.horizontal)
            Spacer()
        }
    }

    private func resetFlow() {
        submitted = false
        step = .category
        category = initialCategory
        coordinate = nil
        people = nil
        details = ""
        vehicle = ""
        photoItem = nil
        photoData = nil
        date = Date()
    }
}
