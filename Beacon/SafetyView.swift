//
//  SafetyView.swift
//  Beacon (Finder)
//
//  Personal safety toolkit: SOS, Walk Timer, trusted contact,
//  daily check-in, Scam Shield, and senior-focused safety tips.
//

import SwiftUI
import UserNotifications
import CoreLocation

struct SafetyView: View {
    @Environment(IncidentStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(LocationService.self) private var location
    @Environment(\.colorScheme) private var colorScheme

    @State private var walkMinutes = 15
    @State private var homeSafeHaptic = false

    private var palette: ThemePalette { settings.palette(for: colorScheme) }

    private var hasContact: Bool {
        !settings.trustedContactPhone.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    sosCard
                    if showsSeniorGuide {
                        seniorGuideCard
                    }
                    walkTimerCard
                    trustedContactCard
                    dailyCheckInCard
                    scamShieldCard
                    safetyTipsCard
                }
                .padding()
            }
            .background(palette.background)
            .navigationTitle("Safety")
        }
    }

    // MARK: - SOS

    private var sosCard: some View {
        SectionCard(palette: palette) {
            Label("Emergency SOS", systemImage: "sos")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            // One tap, no menus — dials immediately.
            Link(destination: EmergencyNumber.telURL) {
                Label("Call \(EmergencyNumber.current) now", systemImage: "phone.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color(hex: "8E1B1B"), in: RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityLabel("Call \(EmergencyNumber.spokenDigits) now. Calls immediately with one tap.")
            if hasContact, let smsURL {
                Link(destination: smsURL) {
                    Label("Text \(contactDisplayName) my location", systemImage: "message.fill")
                }
                .buttonStyle(BigButtonStyle(color: palette.secondaryAccent))
            }
            Text("Calling \(EmergencyNumber.current) is always the right choice in an emergency.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
        }
    }

    /// The dedicated safety guide shows for the 30–49 band and up ("40+").
    private var showsSeniorGuide: Bool {
        guard let group = settings.ageGroup else { return false }
        return group == .adult || group == .midAdult || group == .senior
    }

    private var seniorGuideCard: some View {
        SectionCard(palette: palette) {
            Label("Your safety guide (40+)", systemImage: "book.fill")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Text("A dedicated big-print guide: phone and money scams, door safety, going out, online safety, and what to do if something happens.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            NavigationLink {
                SeniorSafetyView()
            } label: {
                Label("Open the guide", systemImage: "arrow.right.circle.fill")
            }
            .buttonStyle(BigButtonStyle(color: palette.accent))
        }
    }

    private var contactDisplayName: String {
        settings.trustedContactName.isEmpty ? "my contact" : settings.trustedContactName
    }

    private var smsURL: URL? {
        let coordinate = location.bestCoordinate
        let body = "I need help. My location: http://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude) (sent from Beacon)"
        let encoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "sms:\(settings.trustedContactPhone)&body=\(encoded)")
    }

    // MARK: - Walk Timer

    private var walkTimerCard: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            walkTimerContent(now: context.date)
        }
    }

    private func walkTimerContent(now: Date) -> some View {
        SectionCard(palette: palette) {
            Label("Walk Timer — “I'm heading home”", systemImage: "figure.walk")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            if let end = settings.walkTimerEnd, end > now {
                Text(timerLabel(until: end, now: now))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText())
                Text("When time runs out, Beacon reminds you to check in. If you're not safe, use SOS above.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                Button {
                    endWalkTimer()
                    homeSafeHaptic.toggle()
                } label: {
                    Label("I'm home safe", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(BigButtonStyle(color: palette.accent))
                .sensoryFeedback(.success, trigger: homeSafeHaptic)
            } else {
                Text("Walking somewhere? Set a timer. If you don't check in when it ends, Beacon reminds you — and one tap texts \(contactDisplayName).")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                HStack(spacing: 8) {
                    ForEach([10, 15, 30, 45], id: \.self) { minutes in
                        Button {
                            walkMinutes = minutes
                        } label: {
                            Text("\(minutes) min")
                                .font(.callout.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(
                                    walkMinutes == minutes ? palette.accent : palette.background,
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .foregroundStyle(walkMinutes == minutes ? .white : palette.textPrimary)
                        }
                        .accessibilityAddTraits(walkMinutes == minutes ? .isSelected : [])
                    }
                }
                Button {
                    startWalkTimer()
                } label: {
                    Label("Start Walk Timer", systemImage: "timer")
                }
                .buttonStyle(BigButtonStyle(color: palette.secondaryAccent))
            }
        }
    }

    private func timerLabel(until end: Date, now: Date) -> String {
        let remaining = max(0, Int(end.timeIntervalSince(now)))
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func startWalkTimer() {
        let end = Date(timeIntervalSinceNow: Double(walkMinutes) * 60)
        settings.walkTimerEnd = end
        Task {
            let centre = UNUserNotificationCenter.current()
            let granted = (try? await centre.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Walk Timer finished"
            content.body = "Are you home safe? Open Beacon to check in, or text \(contactDisplayName) from the Safety tab."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Double(walkMinutes) * 60, repeats: false)
            try? await centre.add(UNNotificationRequest(identifier: "walkTimer", content: content, trigger: trigger))
        }
    }

    private func endWalkTimer() {
        settings.walkTimerEnd = nil
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["walkTimer"])
    }

    // MARK: - Trusted contact

    private var trustedContactCard: some View {
        SectionCard(palette: palette) {
            Label("Trusted contact", systemImage: "person.2.fill")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Used by SOS and the Walk Timer. They never see your location at any other time.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
            TextField("Name (e.g. Sarah)", text: Bindable(settings).trustedContactName)
                .padding(12)
                .background(palette.background, in: RoundedRectangle(cornerRadius: 12))
            TextField("Phone number", text: Bindable(settings).trustedContactPhone)
                .padding(12)
                .background(palette.background, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Daily check-in

    /// All 48 half-hour times in a day, as minutes from midnight.
    private var halfHourOptions: [Int] {
        Array(stride(from: 0, to: 24 * 60, by: 30))
    }

    private func timeLabel(forMinutes minutes: Int) -> String {
        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let date = Calendar.current.date(from: components) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    private var dailyCheckInCard: some View {
        SectionCard(palette: palette) {
            Toggle(isOn: Bindable(settings).dailyCheckInEnabled) {
                Label("Daily check-in reminder", systemImage: "sun.max")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
            }
            .onChange(of: settings.dailyCheckInEnabled) { _, enabled in
                if enabled {
                    scheduleDailyCheckIn()
                } else {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyCheckIn"])
                }
            }

            if settings.dailyCheckInEnabled {
                HStack {
                    Text("Remind me at")
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                    Spacer()
                    Picker("Reminder time", selection: Bindable(settings).dailyCheckInMinutes) {
                        ForEach(halfHourOptions, id: \.self) { minutes in
                            Text(timeLabel(forMinutes: minutes)).tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(palette.accent)
                }
                .onChange(of: settings.dailyCheckInMinutes) { _, _ in
                    scheduleDailyCheckIn()
                }
                Text("On the half hour — pick whatever fits your routine.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }

            Text("A gentle daily reminder at \(timeLabel(forMinutes: settings.dailyCheckInMinutes)) to send your “I'm OK” to \(contactDisplayName). Completely optional.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
        }
    }

    private func scheduleDailyCheckIn() {
        Task {
            let centre = UNUserNotificationCenter.current()
            let granted = (try? await centre.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            centre.removePendingNotificationRequests(withIdentifiers: ["dailyCheckIn"])
            let content = UNMutableNotificationContent()
            content.title = "Daily check-in"
            content.body = "Hello! Tap to let \(contactDisplayName) know you're OK."
            content.sound = .default
            var components = DateComponents()
            components.hour = settings.dailyCheckInMinutes / 60
            components.minute = settings.dailyCheckInMinutes % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            try? await centre.add(UNNotificationRequest(identifier: "dailyCheckIn", content: content, trigger: trigger))
        }
    }

    // MARK: - Scam Shield

    private var recentScams: [Incident] {
        store.visibleIncidents().filter { $0.category == .scam }
            .sorted { $0.date > $1.date }
    }

    private var scamShieldCard: some View {
        SectionCard(palette: palette) {
            Label("Scam Shield", systemImage: "phone.badge.checkmark")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Text("Phone and door-to-door scams target seniors more than any street crime. If a caller demands money, gift cards, or personal details — hang up. Real agencies never do that.")
                .font(.body)
                .foregroundStyle(palette.textSecondary)
            if !recentScams.isEmpty {
                Text("\(recentScams.count) scam report\(recentScams.count == 1 ? "" : "s") in your community")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
            }
            NavigationLink {
                ReportFlowView(initialCategory: .scam)
            } label: {
                Label("Report a scam", systemImage: "megaphone")
            }
            .buttonStyle(BigButtonStyle(color: IncidentCategory.scam.color))
        }
    }

    // MARK: - Safety tips

    /// Tips for everyone, plus extras matched to the signed-in age group.
    private var tipsForUser: [SafetyTip] {
        SafetyTip.all.filter { tip in
            guard let audience = tip.audience else { return true }
            guard let group = settings.ageGroup else { return false }
            return audience.contains(group)
        }
    }

    private var safetyTipsCard: some View {
        SectionCard(palette: palette) {
            Label("Safety tips", systemImage: "lightbulb")
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            if settings.ageGroup != nil {
                Text("Picked for your age group, plus the basics everyone should know.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
            }
            ForEach(tipsForUser) { tip in
                DisclosureGroup {
                    Text(tip.body)
                        .font(.body)
                        .foregroundStyle(palette.textSecondary)
                        .padding(.top, 4)
                } label: {
                    Text(tip.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(palette.textPrimary)
                }
                .tint(palette.accent)
            }
        }
    }
}

nonisolated struct SafetyTip: Identifiable {
    let id: Int
    let title: String
    let body: String
    /// nil = shown to everyone; otherwise only these age groups see it.
    var audience: Set<AgeGroup>? = nil

    static let all: [SafetyTip] = [
        // Everyone
        SafetyTip(id: 1, title: "🚗 Protect your car", body: "Lock doors every time, take valuables inside, and park in lit areas. Most car break-ins take under 10 seconds and target unlocked cars."),
        SafetyTip(id: 2, title: "📦 Stop package theft", body: "Ask for deliveries to a side door, share deliveries with a trusted neighbour, or pick up from a parcel locker when you'll be out."),
        SafetyTip(id: 3, title: "📞 Spot phone scams", body: "Government agencies, banks, and police never ask for gift cards, wire transfers, or your PIN over the phone. When in doubt, hang up and call the official number yourself."),
        SafetyTip(id: 4, title: "🏠 Home security basics", body: "Lock doors and ground-floor windows even when home, use a timer lamp when away, and don't announce trips publicly before you leave."),
        SafetyTip(id: 5, title: "🚪 Door-to-door visitors", body: "You never have to open the door. Speak through it, ask for ID through a window, and call the company to verify. A real inspector won't mind waiting."),
        SafetyTip(id: 6, title: "🌙 Walking at night", body: "Keep to lit streets, keep one ear free of headphones, and use Beacon's Walk Timer so someone knows when to expect you."),
        SafetyTip(id: 7, title: "💬 Text & email scams", body: "\"Your package has a fee,\" \"your account is locked\" — scam texts create panic on purpose. Never tap links in unexpected messages; go to the real website or app yourself."),
        SafetyTip(id: 8, title: "🔑 Never share codes", body: "One-time codes texted to your phone are keys to your accounts. No real company, bank, or family member needs you to read one out. Anyone asking is a scammer."),
        SafetyTip(id: 9, title: "🏧 ATM and cash safety", body: "Use machines inside stores or banks, cover the keypad, and pocket cash before walking away. If someone hovers, cancel and leave — any awkwardness beats losing your card."),
        SafetyTip(id: 10, title: "🚌 Transit smarts", body: "Wait in lit areas near others, keep bags zipped and in front of you, and sit near the driver on quiet routes."),

        // Kids and teens
        SafetyTip(id: 11, title: "🧒 If you feel lost or scared", body: "Stop and stay where you are. Look for a parent with kids, a store worker in uniform, or a police officer, and tell them your grown-up's phone number. It's always okay to yell for help.",
                  audience: [.under13, .teen]),
        SafetyTip(id: 12, title: "🎮 Online friends you've never met", body: "People online aren't always who they say. Never share your school, address, or photos with someone you haven't met in real life, and tell a grown-up if anyone asks to keep secrets.",
                  audience: [.under13, .teen]),
        SafetyTip(id: 13, title: "🎒 Walking to school", body: "Use the same route your family agreed on, walk with a friend when you can, and never get in a car with someone unless your grown-up said today, this person, this car.",
                  audience: [.under13, .teen]),

        // Older adults
        SafetyTip(id: 14, title: "💊 Health product scams", body: "Miracle cures, discount medications, and \"free\" medical devices sold by phone are almost always scams. Buy medication only from your own pharmacy, and check with your doctor first.",
                  audience: [.midAdult, .senior]),
        SafetyTip(id: 15, title: "👪 The 'grandchild emergency' scam", body: "A caller cries \"Grandma, I'm in trouble, don't tell Mom, send money.\" Hang up and call your grandchild or their parents directly on the number you already have. Real emergencies survive a two-minute check.",
                  audience: [.midAdult, .senior]),
        SafetyTip(id: 16, title: "🛡️ Romance scams", body: "Online romances that quickly turn to requests for money, gift cards, or crypto are scams — no matter how real the feelings seem. Never send money to someone you haven't met in person.",
                  audience: [.youngAdult, .adult, .midAdult, .senior]),
    ]
}
