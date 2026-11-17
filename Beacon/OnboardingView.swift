//
//  OnboardingView.swift
//  Beacon (Finder)
//
//  Three friendly pages: what Beacon is, how reporting works (and the
//  inclusivity guidelines), and the safety tools + 911 disclaimer.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LocationService.self) private var location
    @Environment(\.colorScheme) private var colorScheme

    @State private var page = 0

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                pageView(
                    emoji: "💠",
                    title: "Welcome to Beacon",
                    body: "See what's happening in your neighbourhood — thefts, break-ins, scams, and suspicious activity — on one simple map, shared by your community."
                )
                .tag(0)

                pageView(
                    emoji: "🤝",
                    title: "Report kindly",
                    body: "Reports describe actions — like “checking car door handles” — never how people look. No descriptions of race or ethnicity, no accusations, no photos of people. Awareness, not blame."
                )
                .tag(1)

                pageView(
                    emoji: "🛡️",
                    title: "Your safety toolkit",
                    body: "SOS, a Walk Timer that checks you got home, scam alerts, and senior-friendly safety tips.\n\nOne big rule: in a real emergency, always call \(EmergencyNumber.current) first. Beacon informs — it never replaces the police."
                )
                .tag(2)
            }
#if os(iOS)
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
#endif

            Button(page < 2 ? "Next" : "Get started") {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    location.requestPermission()
                    settings.hasOnboarded = true
                }
            }
            .buttonStyle(BigButtonStyle(color: palette.accent))
            .padding()
        }
        .background(palette.background)
    }

    private func pageView(emoji: String, title: String, body bodyText: String) -> some View {
        VStack(spacing: 22) {
            Spacer()
            Text(emoji)
                .font(.system(size: 76))
                .accessibilityHidden(true)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.center)
            Text(bodyText)
                .font(.title3)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Spacer()
            Spacer()
        }
    }
}
