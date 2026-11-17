//
//  AccountView.swift
//  Beacon (Finder)
//
//  Local "sign up / sign in" for posting reports. Everything stays on
//  this device: a nickname and an age group — never a birthday.
//

import SwiftUI

/// Silly-but-wholesome nickname generator. Seniors love these, and random
/// names keep reports anonymous by default.
nonisolated enum NicknameGenerator {
    static let adjectives = [
        "Cheerful", "Dancing", "Sparkly", "Wobbly", "Snazzy", "Bouncy",
        "Giggling", "Cozy", "Dapper", "Zippy", "Jolly", "Twinkly",
        "Merry", "Plucky", "Spiffy", "Sunny", "Waltzing", "Chuckling",
    ]
    static let nouns = [
        "Pickle", "Waffle", "Muffin", "Penguin", "Teapot", "Gnome",
        "Biscuit", "Marshmallow", "Cabbage", "Slipper", "Kazoo", "Pumpkin",
        "Noodle", "Butterscotch", "Gumboot", "Doughnut", "Radish", "Accordion",
    ]

    static func random() -> String {
        "\(adjectives.randomElement() ?? "Cheerful") \(nouns.randomElement() ?? "Pickle")"
    }
}

struct AccountView: View {
    /// True when shown inside the report flow (tighter copy).
    var embedded = false

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorScheme) private var colorScheme

    @State private var name = ""
    @State private var selectedAge: AgeGroup?
    @State private var selectedAvatar = "🦊"
    @State private var showSeniorNote = false

    /// Friendly, anonymous avatars — no photos, no faces.
    static let avatarOptions = [
        "🦊", "🐼", "🦉", "🐨", "🐯", "🦁",
        "🐸", "🐢", "🦋", "🐬", "🦜", "🌻",
        "⭐️", "🌈", "🍁", "💠",
    ]

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    private var hasExistingProfile: Bool {
        !settings.profileName.isEmpty && settings.ageGroup != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if settings.isSignedIn {
                signedInCard
            } else if hasExistingProfile {
                welcomeBackCard
            } else {
                signUpForm
            }
        }
    }

    // MARK: - Signed in

    private var signedInCard: some View {
        SectionCard(palette: palette) {
            HStack(spacing: 12) {
                Text(settings.avatar)
                    .font(.system(size: 44))
                    .frame(width: 60, height: 60)
                    .background(palette.background, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text("Signed in as \(settings.profileName)")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("Age group: \(settings.ageGroup?.label ?? "—")")
                        .font(.footnote)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            Text("Change avatar")
                .font(.footnote.weight(.medium))
                .foregroundStyle(palette.textSecondary)
            avatarGrid(selection: Bindable(settings).avatar)
            Button("Sign out") {
                settings.isSignedIn = false
            }
            .font(.body.weight(.medium))
            .foregroundStyle(palette.secondaryAccent)
        }
    }

    // MARK: - Welcome back

    private var welcomeBackCard: some View {
        SectionCard(palette: palette) {
            Text("Welcome back!")
                .font(.title3.weight(.bold))
                .foregroundStyle(palette.textPrimary)
            Button {
                settings.isSignedIn = true
            } label: {
                Label("Sign in as \(settings.profileName)", systemImage: "person.crop.circle.badge.checkmark")
            }
            .buttonStyle(BigButtonStyle(color: palette.accent))
            Button("Not you? Create a new profile") {
                settings.profileName = ""
                settings.ageGroup = nil
            }
            .font(.callout)
            .foregroundStyle(palette.textSecondary)
        }
    }

    // MARK: - Sign up

    private var signUpForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(embedded ? "Sign up to post reports" : "Create your profile")
                .font(.title2.weight(.bold))
                .foregroundStyle(palette.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text("Just a nickname and an age group — no email, no password, no birthday. It stays on this device and shapes Beacon to fit you.")
                .font(.body)
                .foregroundStyle(palette.textSecondary)

            HStack(spacing: 10) {
                TextField("Nickname", text: $name)
                    .padding(14)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                Button {
                    withAnimation { name = NicknameGenerator.random() }
                } label: {
                    Text("🎲")
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityLabel("Roll a new silly nickname")
            }
            .onAppear {
                if name.isEmpty {
                    name = NicknameGenerator.random()
                }
            }
            Text("We picked you a silly one — tap the dice for another, or type your own.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)

            Text("Pick your avatar")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            avatarGrid(selection: $selectedAvatar)

            Text("Your age group")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(AgeGroup.allCases) { group in
                    Button {
                        selectedAge = group
                    } label: {
                        VStack(spacing: 6) {
                            Text(group.emoji)
                                .font(.title)
                            Text(group.label)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(selectedAge == group ? .white : palette.textPrimary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 72)
                        .background(
                            selectedAge == group ? palette.accent : palette.surface,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Age group \(group.label)")
                    .accessibilityAddTraits(selectedAge == group ? .isSelected : [])
                }
            }

            if selectedAge == .under13 {
                SectionCard(palette: palette) {
                    Label("Under-13 profiles can explore the map with family, but can't post reports.", systemImage: "figure.2.and.child.holdinghands")
                        .font(.callout)
                        .foregroundStyle(palette.textPrimary)
                }
            }

            Button("Create profile & sign in") {
                signUp()
            }
            .buttonStyle(BigButtonStyle(color: canSubmit ? palette.accent : palette.textSecondary))
            .disabled(!canSubmit)

            if showSeniorNote {
                Label("We turned on larger text for comfort — change it any time in Settings.", systemImage: "textformat.size")
                    .font(.callout)
                    .foregroundStyle(palette.accent)
            }
        }
    }

    private func avatarGrid(selection: Binding<String>) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
            ForEach(Self.avatarOptions, id: \.self) { option in
                Button {
                    selection.wrappedValue = option
                } label: {
                    Text(option)
                        .font(.system(size: 30))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            selection.wrappedValue == option ? palette.accent.opacity(0.3) : palette.surface,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selection.wrappedValue == option ? palette.accent : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Avatar \(option)")
                .accessibilityAddTraits(selection.wrappedValue == option ? .isSelected : [])
            }
        }
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedAge != nil
    }

    private func signUp() {
        guard let selectedAge else { return }
        settings.profileName = name.trimmingCharacters(in: .whitespaces)
        settings.ageGroup = selectedAge
        settings.avatar = selectedAvatar
        settings.isSignedIn = true
        if selectedAge == .senior && settings.textSize == .system {
            settings.textSize = .large
            showSeniorNote = true
        }
    }
}
