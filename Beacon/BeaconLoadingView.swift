//
//  BeaconLoadingView.swift
//  Beacon (Finder)
//
//  "The Beacon Boot-Up": a bouncing beacon gem that fires a light beam
//  upward on each bounce, Minecraft-style. Falls back to a gentle pulse
//  when Reduce Motion is on.
//

import SwiftUI

struct BeaconLoadingView: View {
    let palette: ThemePalette

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bouncing = false
    @State private var pulsing = false

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack(alignment: .bottom) {
                    // The light beam, shooting up from the gem.
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [palette.beam.opacity(0.85), palette.beam.opacity(0)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 26, height: bouncing ? 190 : 90)
                        .offset(y: -70)
                        .opacity(pulsing ? 0.95 : 0.55)

                    VStack(spacing: 0) {
                        Text("💠")
                            .font(.system(size: 72))
                            .scaleEffect(x: bouncing ? 0.94 : 1.08, y: bouncing ? 1.10 : 0.90)
                            .offset(y: bouncing ? -30 : 0)
                            .shadow(color: palette.beam.opacity(pulsing ? 0.8 : 0.3), radius: 24)

                        // Pedestal tiles, widest at the bottom.
                        VStack(spacing: 3) {
                            pedestalTile(width: 56)
                            pedestalTile(width: 84)
                            pedestalTile(width: 116)
                        }
                    }
                }
                .frame(height: 300, alignment: .bottom)
                .accessibilityHidden(true)

                Text("Beacon")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.textPrimary)

                Text("See your neighbourhood clearly")
                    .font(.title3)
                    .foregroundStyle(palette.textSecondary)

                if reduceMotion {
                    ProgressView()
                        .tint(palette.accent)
                        .padding(.top, 8)
                }

                Spacer()
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading Beacon")
        .onAppear {
            if reduceMotion {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            } else {
                withAnimation(.spring(duration: 0.55, bounce: 0.45).repeatForever(autoreverses: true)) {
                    bouncing = true
                }
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
        }
    }

    private func pedestalTile(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(palette.surface)
            .stroke(palette.textSecondary.opacity(0.35), lineWidth: 1)
            .frame(width: width, height: 16)
    }
}

#Preview {
    BeaconLoadingView(palette: .daylight)
}
