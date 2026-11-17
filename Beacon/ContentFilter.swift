//
//  ContentFilter.swift
//  Beacon (Finder)
//
//  Family filter: blurs harsh or scary words in report text so a child
//  glancing at the screen doesn't read them. Adults can tap a blurred
//  word to reveal it; for minor profiles words stay blurred.
//

import SwiftUI

nonisolated enum ContentFilter {
    /// Words blurred when the family filter is on. Matched whole-word,
    /// ignoring case and punctuation.
    static let sensitiveWords: Set<String> = [
        "kill", "killed", "killing", "murder", "murdered",
        "stab", "stabbed", "stabbing", "knife", "knives",
        "gun", "guns", "shot", "shoot", "shooting", "firearm",
        "blood", "bloody", "bleeding",
        "weapon", "weapons",
        "assault", "assaulted", "attack", "attacked", "attacking",
        "drug", "drugs", "needle", "needles", "overdose",
        "dead", "died", "death", "corpse",
        "rape", "raped",
        "damn", "hell", "crap",
        "threat", "threatened", "threatening",
    ]

    static func isSensitive(_ word: String) -> Bool {
        let cleaned = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
        return sensitiveWords.contains(cleaned)
    }

    static func containsSensitiveWords(_ text: String) -> Bool {
        text.split(whereSeparator: \.isWhitespace).contains { isSensitive(String($0)) }
    }
}

/// Moderation: inappropriate language is blocked at posting time (three
/// strikes removes posting access), and exact street addresses are
/// rejected for privacy.
nonisolated enum Moderation {
    /// Language that gets a report rejected and earns a strike.
    static let blockedWords: Set<String> = [
        "fuck", "fucking", "fucked", "shit", "bitch", "asshole", "bastard",
        "dick", "cunt", "pussy", "whore", "slut", "nigger", "nigga",
        "faggot", "fag", "retard", "retarded",
    ]

    static func containsBlockedWords(_ text: String) -> Bool {
        text.split(whereSeparator: \.isWhitespace).contains { word in
            blockedWords.contains(word.lowercased().trimmingCharacters(in: .punctuationCharacters))
        }
    }

    /// Detects things like "123 Maple Street" or "apt 4" so exact home
    /// addresses never end up in a public description.
    static func looksLikeExactAddress(_ text: String) -> Bool {
        let streetPattern = /\b\d{1,5}\s+[A-Za-z]+\.?,?\s*(street|st|avenue|ave|road|rd|drive|dr|boulevard|blvd|lane|ln|court|ct|crescent|cres|place|pl|way|terrace|circle|cir)\b/
            .ignoresCase()
        let unitPattern = /\b(apt|apartment|unit|suite)\s*#?\s*\d+\b/
            .ignoresCase()
        return text.contains(streetPattern) || text.contains(unitPattern)
    }
}

/// Renders text word-by-word, blurring flagged words when the family
/// filter is on. Tapping a blurred word reveals it (adults only).
struct FilteredText: View {
    let text: String
    let filterOn: Bool
    let canReveal: Bool
    var textColor: Color = .primary

    @State private var revealed: Set<Int> = []

    private var words: [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    var body: some View {
        if !filterOn || !ContentFilter.containsSensitiveWords(text) {
            Text(text)
                .font(.body)
                .foregroundStyle(textColor)
        } else {
            WordFlowLayout(spacing: 5) {
                ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                    wordView(word, index: index)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func wordView(_ word: String, index: Int) -> some View {
        if ContentFilter.isSensitive(word) && !revealed.contains(index) {
            Text(word)
                .font(.body)
                .foregroundStyle(textColor)
                .blur(radius: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(textColor.opacity(0.25), lineWidth: 1)
                )
                .onTapGesture {
                    if canReveal {
                        withAnimation { _ = revealed.insert(index) }
                    }
                }
                .accessibilityLabel(canReveal ? "Hidden word. Tap to show." : "Hidden word.")
        } else {
            Text(word)
                .font(.body)
                .foregroundStyle(textColor)
        }
    }
}

/// Minimal wrapping layout so blurred words flow like normal text.
struct WordFlowLayout: Layout {
    var spacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
