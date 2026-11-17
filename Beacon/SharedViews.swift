//
//  SharedViews.swift
//  Beacon (Finder)
//
//  Small reusable pieces: the 911 banner, category pin, big buttons.
//

import SwiftUI

/// Shown on every screen that displays incidents. Beacon informs — it is
/// never a replacement for emergency services.
struct EmergencyBanner: View {
    var body: some View {
        Link(destination: EmergencyNumber.telURL) {
            HStack(spacing: 10) {
                Image(systemName: "phone.fill")
                Text("Emergency? Call \(EmergencyNumber.current)")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote)
            }
            .font(.callout)
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: "8E1B1B"), in: RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel("Emergency? Tap to call \(EmergencyNumber.spokenDigits)")
    }
}

/// The coloured map pin / badge for a category. Icon plus colour, never
/// colour alone.
struct CategoryBadge: View {
    let category: IncidentCategory
    var size: CGFloat = 40
    var glow: Bool = false

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(category.color, in: Circle())
            .overlay(Circle().stroke(.white, lineWidth: 2))
            .shadow(color: glow ? category.color.opacity(0.9) : .black.opacity(0.3), radius: glow ? 8 : 3)
            .accessibilityHidden(true)
    }
}

/// Beacon's primary action button: 56pt tall, full width, obvious.
struct BigButtonStyle: ButtonStyle {
    var color: Color
    var textColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3.weight(.semibold))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(color, in: RoundedRectangle(cornerRadius: 16))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SectionCard<Content: View>: View {
    let palette: ThemePalette
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}
