//
//  TutorialView.swift
//  Beacon (Finder)
//
//  Interactive guided tour: each step asks the user to actually tap the
//  thing being taught. Skippable at any time, replayable from Settings.
//

import SwiftUI

struct TutorialView: View {
    let onFinish: () -> Void

    @Environment(AppSettings.self) private var settings
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 0
    @State private var demoSightings = 3
    @State private var pulse = false
    @State private var stepDoneHaptic = false

    private var palette: ThemePalette { settings.palette(for: colorScheme) }
    private let totalSteps = 6

    var body: some View {
        ZStack {
            palette.background.opacity(0.97).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("Quick tour")
                        .font(.headline)
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                    Button("Skip") {
                        onFinish()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(palette.surface, in: Capsule())
                    .accessibilityLabel("Skip the tour")
                }
                .padding(.horizontal)
                .padding(.top, 8)

                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Capsule()
                            .fill(index <= step ? palette.accent : palette.surface)
                            .frame(height: 6)
                    }
                }
                .padding(.horizontal)
                .accessibilityElement()
                .accessibilityLabel("Tour step \(step + 1) of \(totalSteps)")

                Spacer()

                stepView
                    .padding(.horizontal, 24)
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))

                Spacer()

                if step == totalSteps - 1 {
                    Button("Start using Beacon") {
                        advance()
                    }
                    .buttonStyle(BigButtonStyle(color: palette.accent))
                    .padding()
                } else {
                    Label("Tap the highlighted item to continue", systemImage: "hand.tap")
                        .font(.callout)
                        .foregroundStyle(palette.textSecondary)
                        .padding()
                }
            }
        }
        .sensoryFeedback(.success, trigger: stepDoneHaptic)
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
        }
    }

    private func advance() {
        stepDoneHaptic.toggle()
        if step == totalSteps - 1 {
            onFinish()
        } else {
            withAnimation { step += 1 }
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case 0: pinStep
        case 1: sightingStep
        case 2: searchStep
        case 3: reportStep
        case 4: emergencyStep
        default: doneStep
        }
    }

    private func stepText(_ title: String, _ body: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.title.weight(.bold))
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(body)
                .font(.title3)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var pinStep: some View {
        VStack(spacing: 26) {
            stepText("Reports live on the map", "Every pin is a neighbour's report. The colour and picture show what happened. Try it — tap the pin!")
            Button {
                advance()
            } label: {
                CategoryBadge(category: .carTheft, size: 64)
                    .scaleEffect(pulse ? 1.12 : 1.0)
                    .overlay(
                        Circle()
                            .stroke(palette.accent.opacity(0.6), lineWidth: 3)
                            .scaleEffect(pulse ? 1.5 : 1.1)
                            .opacity(pulse ? 0 : 1)
                    )
            }
            .accessibilityLabel("Example map pin, car theft. Tap to continue.")
        }
    }

    private var sightingStep: some View {
        VStack(spacing: 26) {
            stepText("Saw it too? Say so", "If you saw the same thing, don't post a duplicate — tap “I saw this too.” Give it a try.")
            Button {
                demoSightings += 1
                advance()
            } label: {
                Label("I saw this too", systemImage: "eye")
            }
            .buttonStyle(BigButtonStyle(color: palette.accent))
            Text("\(demoSightings) people reported this")
                .font(.headline)
                .foregroundStyle(palette.textSecondary)
                .contentTransition(.numericText())
        }
    }

    private var searchStep: some View {
        VStack(spacing: 26) {
            stepText("Search anything", "Streets, neighbourhoods, or words like “car” or “scam.” Tap the search bar to continue.")
            Button {
                advance()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                    Text("Search street, category, or keyword")
                        .foregroundStyle(palette.textSecondary)
                    Spacer()
                }
                .padding(16)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(palette.accent, lineWidth: pulse ? 3 : 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Example search bar. Tap to continue.")
        }
    }

    private var reportStep: some View {
        VStack(spacing: 26) {
            stepText("Reporting is easy", "The Report tab asks six simple questions, one at a time. You can even practice first from Settings — nothing gets posted in practice. Tap the plus!")
            Button {
                advance()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(palette.accent)
                    .scaleEffect(pulse ? 1.12 : 1.0)
            }
            .accessibilityLabel("Example report button. Tap to continue.")
        }
    }

    private var emergencyStep: some View {
        VStack(spacing: 26) {
            stepText("The red banner is real", "One tap on the red banner calls \(EmergencyNumber.current) immediately — no menus in between. This one below is just for the tour, so it's safe to tap.")
            Button {
                advance()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                    Text("Emergency? Call \(EmergencyNumber.current)")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .font(.callout)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(hex: "8E1B1B"), in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel("Practice emergency banner. Safe to tap — it only continues the tour.")
        }
    }

    private var doneStep: some View {
        VStack(spacing: 26) {
            Text("💠")
                .font(.system(size: 64))
            stepText("You're all set!", "Check “In My Area” for what's near you, and the Safety tab for the SOS button, Walk Timer, and scam alerts. Welcome to the neighbourhood.")
        }
    }
}
