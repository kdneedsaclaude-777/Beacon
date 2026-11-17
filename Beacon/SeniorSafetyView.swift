//
//  SeniorSafetyView.swift
//  Beacon (Finder)
//
//  A dedicated, big-print safety guide shown to users 40 and up.
//

import SwiftUI

struct SeniorSafetyView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("A calm, practical guide. Scammers and thieves rely on rushing people — almost every tip here comes down to one thing: it's always okay to slow down.")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)

                EmergencyBanner()

                section("📞 Phone & money — the golden rules", items: [
                    "No real bank, government office, or police force ever asks for gift cards, wire transfers, or crypto. Anyone who does is a scammer — every time.",
                    "Never read out a code that was texted to you. Those codes are the keys to your accounts.",
                    "\"Don't tell anyone\" is the biggest red flag there is. Real emergencies survive a phone call to your family.",
                    "Hang up and call back on the official number from your card or statement. A two-minute check defeats almost every phone scam.",
                    "If a grandchild calls \"in trouble, needing money fast\" — hang up and call them or their parents on the number you already have.",
                ])

                section("🚪 At your door", items: [
                    "You never have to open the door. Speaking through it is not rude.",
                    "Ask for ID through the window and call the company yourself to check. A real worker expects this.",
                    "Unexpected \"inspectors,\" \"utility workers,\" or \"contractors who noticed a problem with your roof\" are classic setups. Real utilities book appointments.",
                    "If someone won't leave, say clearly \"I'm calling the police now\" — and do it.",
                ])

                section("🚶 Out and about", items: [
                    "Use ATMs inside banks or stores, cover the keypad, and put cash away before walking out.",
                    "Carry your bag closed and in front of you in crowds; keep your phone in an inner pocket, not a back pocket.",
                    "At night, stick to lit streets and let someone know when to expect you — Beacon's Walk Timer in the Safety tab does exactly this.",
                    "If someone demands your bag or wallet, hand it over. Things are replaceable; you are not.",
                ])

                section("💻 Online", items: [
                    "\"Your computer has a virus, call this number\" pop-ups are always fake. Close the browser; nothing is wrong with your computer.",
                    "Unexpected emails about packages, refunds, or locked accounts: don't tap the link. Open the real website or app yourself.",
                    "Online romances that turn into requests for money are scams, no matter how long you've been talking.",
                    "Use different passwords for email and banking. A notebook kept at home is perfectly fine.",
                ])

                section("💊 Health & home", items: [
                    "Buy medication only from your own pharmacy. \"Discount medication\" calls and miracle cures are scams.",
                    "Keep a lamp on a timer for evenings away, and lock ground-floor windows even when home.",
                    "Know your neighbours. Communities where people wave at each other genuinely have less crime — it's the cheapest security system ever invented.",
                ])

                SectionCard(palette: palette) {
                    Text("If something happened to you")
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    Text("There is no shame in being scammed or robbed — it happens to sharp, careful people every day, and reporting it protects your neighbours. Call \(EmergencyNumber.current) for emergencies, your local non-emergency line otherwise, tell your bank right away if money is involved, and post it on Beacon so others can watch out.")
                        .font(.body)
                        .foregroundStyle(palette.textSecondary)
                }
            }
            .padding()
        }
        .background(palette.background)
        .navigationTitle("Safety guide 40+")
        .toolbarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, items: [String]) -> some View {
        SectionCard(palette: palette) {
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(palette.accent)
                        .padding(.top, 3)
                    Text(item)
                        .font(.body)
                        .foregroundStyle(palette.textPrimary)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}
