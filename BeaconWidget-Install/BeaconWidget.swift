//
//  BeaconWidget.swift
//  BeaconWidget
//
//  "Your Area" home-screen widget. See INSTALL.md in this folder for the
//  two-minute setup in Xcode. This file lives OUTSIDE the app target on
//  purpose — drop it into the widget extension target when you create it.
//

import WidgetKit
import SwiftUI

struct BeaconEntry: TimelineEntry {
    let date: Date
    let weekCount: Int
    let trend: String
}

struct BeaconProvider: TimelineProvider {
    private func currentEntry() -> BeaconEntry {
        let shared = UserDefaults(suiteName: "group.beacon.shared")
        return BeaconEntry(
            date: .now,
            weekCount: shared?.integer(forKey: "widget.weekCount") ?? 0,
            trend: shared?.string(forKey: "widget.trend") ?? "same"
        )
    }

    func placeholder(in context: Context) -> BeaconEntry {
        BeaconEntry(date: .now, weekCount: 2, trend: "down")
    }

    func getSnapshot(in context: Context, completion: @escaping (BeaconEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BeaconEntry>) -> Void) {
        completion(Timeline(entries: [currentEntry()], policy: .after(.now.addingTimeInterval(30 * 60))))
    }
}

struct BeaconWidgetView: View {
    let entry: BeaconEntry

    private var trendSymbol: String {
        switch entry.trend {
        case "down": "arrow.down.circle.fill"
        case "up": "arrow.up.circle.fill"
        default: "equal.circle.fill"
        }
    }

    private var trendText: String {
        switch entry.trend {
        case "down": "Fewer than last week"
        case "up": "More than last week"
        default: "Same as last week"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("💠")
                Text("Your Area")
                    .font(.headline)
            }
            Spacer()
            Text("\(entry.weekCount)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.3, green: 0.71, blue: 0.67))
            Text(entry.weekCount == 1 ? "report this week" : "reports this week")
                .font(.footnote)
            Label(trendText, systemImage: trendSymbol)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@main
struct BeaconWidgetBundle: WidgetBundle {
    var body: some Widget {
        BeaconAreaWidget()
    }
}

struct BeaconAreaWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "BeaconArea", provider: BeaconProvider()) { entry in
            BeaconWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Your Area")
        .description("Community reports near you this week, at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
