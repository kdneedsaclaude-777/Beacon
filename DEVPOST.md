# Beacon — Devpost Submission

**Elevator pitch:** Community safety, in real time.

---

## About the project

### Inspiration

Beacon started with a simple observation: the people who most need to know what's happening in their neighbourhood — seniors — are the ones least served by existing neighbourhood apps. Those apps are cluttered, fear-mongering, and their comment sections turn every incident into an argument (and too often, into racial profiling). We wanted to build the opposite: a community safety map that is **senior-first, calm, and bias-aware by design**. Awareness, not alarm. A light that helps you see, not a siren.

### What it does

Beacon is an iOS app where neighbours share and view local incidents — thefts, break-ins, scams, suspicious activity — on one shared map.

- **Three ways to see your area**: map pins with clustering and a heat-map overlay, a large-type list, and a card grid — so the map works even for people who find maps hard to read.
- **A one-question-per-screen report wizard** with 14 incident types, block-level location privacy, duplicate detection ("add your sighting instead"), and a practice mode that posts nothing — so new users can learn with zero fear of posting something wrong.
- **Community signals without comments**: "I saw this too" sighting counts, "I didn't see this" doubts (enough doubts hide a report), flagging, and 30-day auto-expiry so old incidents don't permanently stigmatize a street.
- **A personal safety toolkit**: one-tap SOS, a Walk Timer that texts a trusted contact if you don't check in, daily check-in reminders, Scam Shield for phone/door-to-door scams, and a big-print safety guide.
- **Inclusivity enforced in code, not just guidelines**: reports describe actions, never appearance; exact addresses are auto-detected and blocked; a family filter blurs harsh words (locked on for minors); under-13 profiles are view-only; and there's deliberately no comments section.
- **A one-tap emergency call banner** that can never be disabled and dials the right number for your region (911, 999, 112, …).

### How we built it

Beacon is **100% native SwiftUI** targeting iOS, with **no third-party dependencies** — every feature is built on Apple frameworks:

- **MapKit** for the map, pin clustering, geocoded search, and the heat-map overlay.
- **CoreLocation** wrapped in a small `@Observable` service — when-in-use permission only, with a graceful fallback so the entire app works with location denied.
- **Local-first persistence** (JSON on device) via an observable `IncidentStore`, with **CloudKit** layered on top for optional community sync — location-scoped so users only pull reports within 50 km, with no server to run and no accounts to manage.
- **WidgetKit** for a glanceable home-screen widget ("Your area: 2 reports this week ↓").
- **Swift Testing** for the safety-critical logic: moderation and blocked words, address-leak detection, voting rules, duplicate detection, expiry, and emergency-number region mapping.
- A custom theme engine with three palettes (Daylight, Night Watch, and a warm low-glare Night Mode), all meeting WCAG AA contrast, plus the "Beacon Boot-Up" loading animation — a bouncing gem that fires a beam of light, Minecraft-beacon style, where the beam doubles as the progress bar.

### Challenges we ran into

The hardest problems weren't technical — they were social. Letting people report "suspicious activity" without enabling profiling meant structuring the form around *behaviour*, auto-blocking exact addresses, and skipping comments entirely. Supporting the largest accessibility text sizes forced every layout to reflow, and anonymous reporting needed real defences: rate limits, duplicate merging, doubt votes, and 30-day expiry.

### Accomplishments that we're proud of

A fully native, zero-dependency iOS app with map, list, and grid views, a 14-category report wizard, CloudKit community sync, a safety toolkit (SOS, Walk Timer, Scam Shield), and full VoiceOver and Dynamic Type support — with bias-prevention and privacy guardrails enforced in code, not just guidelines.

### What we learned

Senior-first design makes the app better for everyone — big targets and plain language are clarity, not compromise. The most important features are sometimes the ones you *don't* build (comments, leaderboards, appearance fields). And Apple's native stack goes remarkably far: sync, widgets, and maps with zero servers.

### What's next for Beacon

Apple Watch SOS and Walk Timer, Siri voice reporting, Live Activities, French localization, and verified advisories from local community organizations.

---

## Built with

`swift` · `swiftui` · `mapkit` · `corelocation` · `cloudkit` · `widgetkit` · `xcode` · `ios` · `swift-testing` · `apple-maps` · `push-notifications`
