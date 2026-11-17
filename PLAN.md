# Beacon — Community Safety Map
### App Plan & Design Document
**Created by:** KDragon
**Platform:** iOS (SwiftUI, MapKit)
**Date:** September 6, 2026

---

## 1. What Beacon Is

Beacon is a community safety app where neighbours can report and view local incidents — suspicious activity, thefts, break-ins, robberies, and car theft — on a shared map. The goal is awareness, not alarm: help people (especially seniors) know what's happening nearby, in an app that's simple enough for anyone to use.

**Why "Beacon"?** It's short, easy to say and spell, positive in tone (a light that helps you see, not a siren), and translates well across languages.

### Guiding principles
1. **Awareness, not vigilantism.** Beacon informs; it never encourages confrontation. Every screen that shows an active incident also shows "If this is an emergency, call 911."
2. **Accessible to everyone.** Designed senior-first: big text, big buttons, plain language, works with VoiceOver.
3. **Inclusive and bias-aware.** Reports describe *behaviour and events*, not people's race, ethnicity, or appearance stereotypes. The report form is structured to prevent profiling (see Section 6).
4. **Privacy-respecting.** Reporters are anonymous to other users; exact home addresses are never shown.

---

## 2. Core Features

### 2.1 The Map (Home screen)
- Full-screen map (Apple MapKit) with colour-coded, icon-coded pins for each incident.
- Pins **cluster** when zoomed out (e.g., a badge showing "7") so the map never becomes cluttered.
- Tapping a pin opens a large, readable incident card.
- **Three view modes**, switchable with one big segmented control at the top:
  - **🗺 Map View** — the default. Pins, clustering, legend.
  - **📋 List View** — the same incidents as a scrollable list, sorted by nearest first, in large type. Essential for VoiceOver users and anyone who finds maps hard to read.
  - **🔲 Grid View** — incident cards in a 2-column grid of big tiles (icon, category, distance, time, sighting count). A visual middle ground: easier to scan than a list, simpler than a map. In Simple Mode and at large accessibility text sizes, the grid automatically becomes a single column.
- The app remembers which view you used last and reopens to it.
- Legend button explaining every pin colour/icon in plain words.

### 2.1.1 Location Sensing
- **"Follow Me" mode** — the map gently keeps you centred as you move (walking home, checking a route), with a clear on/off button and a visible indicator when active. Respects Reduce Motion.
- **Auto-centre on launch** — the map opens on your current neighbourhood, not a default city view.
- **Geofenced home zone** — optionally mark your home area (approximate, block-level). Beacon can notify you if a new report appears inside it, even when the app is closed (uses efficient region monitoring, not constant GPS).
- **Distance labels everywhere** — every incident shows "350 m away" / "1.2 km away" in list, grid, and cards.
- **Privacy-first sensing** — "when in use" permission by default; the home-zone alert feature clearly explains the "always" permission before asking, and everything works without it. Your location is never stored on a server or shown to other users.

### 2.2 Reporting an Incident
A short, step-by-step form (one question per screen, big Next button — much easier for seniors than one long form):
1. **What happened?** — pick a category (big tappable cards with icons):
   - 👀 Suspicious activity
   - 🎒 Theft (personal property / package)
   - 🏠 Break-in / burglary
   - 💰 Robbery
   - 🚗 Car theft or car break-in
   - 🧱 Vandalism
   - ❓ Other
2. **Where?** — drop a pin on the map, or "Use my current location" button.
3. **When?** — date and time pickers, defaulting to "just now."
4. **How many people were involved/seen?** — simple stepper (1, 2, 3, 4, 5+, "Not sure").
5. **What did you see?** — optional short description with on-screen guidance: *"Describe actions and events (e.g. 'checking car door handles'). Please don't describe race or ethnicity."*
6. **Optional extras:** vehicle description (colour/type/plate), photo of *property or scene only* (the form reminds users not to upload identifiable photos of people).
7. **Review & submit** — a summary in large type, with an edit button per field.

### 2.3 Sighting Confirmations ("I saw this too")
- Every incident card has a **"👁 I saw this too"** button. This increments a **sighting count** shown on the pin and card ("3 people reported this").
- Multiple sightings of the same thing merge into one pin instead of ten duplicates, and higher counts make a pin slightly larger — more signal, less noise.

### 2.4 Search Bar
- Prominent search bar at the top of the map.
- Searches by: **place** (street, neighbourhood, landmark — via MapKit geocoding), **category** ("car theft"), and **keywords** in report descriptions.
- Recent searches saved locally; large clear "✕" button to reset.

### 2.5 "In My Area"
- A dedicated **In My Area** tab: everything within a chosen radius of you (0.5 km / 1 km / 2 km / 5 km — simple segmented picker).
- Shows a friendly summary at the top: *"4 reports near you in the last 7 days"* with a small trend note ("fewer than last week ↓").
- Optional **nearby alerts**: a push notification when a new report appears within your radius (off by default, easy toggle).

### 2.6 Incident Detail Card
Every incident shows, in large clear type:
- Category icon + name
- **Date and time** of the incident ("Tuesday, Sept 2 at 7:45 PM" — spelled out, not "09/02 19:45")
- Approximate location (street/block level — never an exact unit number)
- **Number of people involved** and **sighting count**
- Description (if provided)
- "I saw this too" and "Report a problem with this post" buttons
- The 911 emergency reminder banner

---

## 3. App Structure (Screens & Navigation)

Bottom tab bar with **4 large, labelled tabs** (icons + text, never icons alone):

| Tab | Purpose |
|---|---|
| 🗺 **Map** | Home. Map/list of incidents, search bar, legend. |
| 📍 **In My Area** | Radius-based local feed, weekly summary, trend. |
| ➕ **Report** | The step-by-step report flow (center, extra large). |
| ⚙️ **Settings** | Text size, theme, alerts, language, privacy, help. |

Plus a **one-time onboarding** (3 friendly screens: what Beacon is, how to report, the community guidelines) and a persistent, dismissible **"Emergency? Call 911"** banner style used across the app.

---

## 4. Colour Themes

All combinations meet **WCAG AA contrast (4.5:1 minimum)**, and colour is **never the only signal** — every category also has a unique icon and text label (important for colour-blind users).

### 4.1 Light theme (default) — "Daylight"
| Role | Colour | Hex |
|---|---|---|
| Background | Soft warm white | `#FAFAF7` |
| Card / surface | White | `#FFFFFF` |
| Primary text | Near-black | `#1A1A1A` |
| Primary accent (buttons, links) | Deep teal | `#00695C` |
| Secondary accent | Slate blue | `#37507A` |

### 4.2 Dark theme — "Night Watch"
| Role | Colour | Hex |
|---|---|---|
| Background | Deep navy-charcoal | `#12161C` |
| Card / surface | Dark slate | `#1E242D` |
| Primary text | Off-white | `#F2F2F0` |
| Primary accent | Bright teal | `#4DB6AC` |
| Secondary accent | Light steel blue | `#8FA8D0` |

### 4.3 Night Mode 🌙
Distinct from the regular dark theme — a dedicated mode for checking the app late at night:
- **Auto-schedule:** follows the system light/dark setting by default, with optional sunset-to-sunrise scheduling or a manual toggle in Settings.
- **Dimmed map style:** MapKit's dark map with muted colours, so the map itself doesn't glare.
- **Warm, low-glare palette:** Night Mode shifts accents from teal toward warm amber (`#D4A24E`) and lowers overall brightness of surfaces (`#0C0F13` background) — easier on older eyes and doesn't wreck night vision or wake up a partner.
- **Larger default text in Night Mode** (+1 Dynamic Type step), since low light makes reading harder, especially for seniors.
- Category pins keep their icons and gain a subtle outer glow so they stay distinguishable on the dark map without relying on colour.

### 4.4 High-Contrast mode
Pure white/black backgrounds, `#005044` accent, thicker borders, bolder text weights. Follows the system "Increase Contrast" setting automatically, and can also be forced on in Settings.

### 4.5 Category colours (same in all themes, paired with icons)
| Category | Colour | Hex | Icon |
|---|---|---|---|
| Suspicious activity | Amber | `#B26A00` | eye |
| Theft | Orange-red | `#C62828` | bag |
| Break-in / burglary | Crimson | `#8E1B1B` | house |
| Robbery | Deep red | `#7B1240` | exclamation shield |
| Car theft / break-in | Indigo | `#3949AB` | car |
| Vandalism | Plum | `#6A1B9A` | paintbrush |
| Other | Grey-blue | `#546E7A` | question mark |

Deliberately **no bright alarm-red UI everywhere** — a safety app should feel calm and trustworthy, not frightening. Reds are reserved only for the most serious categories and the emergency banner.

---

## 5. Accessibility (Senior-First Design)

This is a core requirement, not an afterthought:

- **Dynamic Type everywhere** — every screen tested up to the largest accessibility text sizes; layouts reflow instead of truncating. In-app **text size slider** in Settings for people who don't know about the iOS setting.
- **Large touch targets** — minimum 44×44 pt, primary buttons 56 pt tall.
- **VoiceOver** — every pin, button, and card fully labelled ("Car break-in, Maple Street area, Tuesday evening, 2 sightings"). The List View makes the map fully screen-reader navigable.
- **Plain language** — "Break-in" not "B&E," spelled-out dates, no jargon, short sentences. Reading level target: grade 6.
- **Icons always have text labels.** Colour never carries meaning alone.
- **Reduced motion** respected — no animated map flyovers if the system setting is on.
- **Simple Mode toggle** (Settings): hides advanced options, enlarges everything further, shows only Map + Report.
- **Haptic + visual confirmation** after submitting a report ("✓ Thank you. Your report is on the map.") so users are never unsure whether it worked.
- **Multilingual support** — launch in English and French (Canada), architecture ready for more via standard iOS localization.
- **Voice input friendly** — description field works with dictation; the whole report flow is possible without typing.

---

## 6. Inclusivity & Community Safety Guardrails

To keep Beacon helpful and prevent it becoming a profiling or harassment tool:

- **Behaviour-based reporting.** The form asks *what happened*, and description guidance explicitly says not to describe race/ethnicity. "A person looked out of place" is not a reportable event; "someone trying car door handles" is.
- **No photos of people.** Photo uploads are for property/scenes; guidelines state identifiable people will be removed.
- **Flagging & moderation.** Every post has "Report a problem" (inaccurate, discriminatory, spam, wrong location). Flagged posts are hidden pending review.
- **Auto-expiry.** Pins fade after 30 days and disappear from the default view (visible only via an explicit "show older" filter), so old incidents don't permanently stigmatize a street or neighbourhood.
- **Approximate locations for homes.** Residential reports snap to the block level, never an exact address.
- **Anonymous by default.** Other users never see who posted a report.
- **Community guidelines** shown at onboarding and linked from every report form: be factual, don't accuse named individuals, call 911 for emergencies — Beacon is not a replacement for police.
- **No comments section at launch.** Comment threads on crime posts are where neighbourhood apps turn toxic. Sighting confirmations give community signal without arguments.

### 6.1 Personal Safety Features
Beyond reporting, Beacon actively helps keep users safe:
- **🆘 SOS button** — always reachable from the tab bar via a long-press on the app icon or a persistent button on the map. One tap calls 911; a second option texts your emergency contact your live location. Big, obvious, works with shaky hands.
- **🚶 Walk Timer ("I'm heading home")** — set a walking time (e.g. 15 minutes). If you don't tap "I'm home safe" when it ends, Beacon texts your chosen contact your last location. Great for seniors walking home from the bus stop at night.
- **👨‍👩‍👧 Trusted Contacts** — add up to 3 family members/friends. They can receive your Walk Timer alerts and SOS messages. (They do *not* see your location at any other time.)
- **📞 Daily Check-In (optional, senior-focused)** — an opt-in daily "I'm OK" tap. If missed, a gentle reminder goes out, then a notification to a trusted contact. Simple, private, and entirely optional.
- **☎️ Scam Shield** — a special report category and alert type for **phone/door-to-door scams**, which target seniors far more than street crime does. Scam reports show the scam script ("caller claims to be CRA...") so neighbours recognize it.

### 6.2 Trust & Data Safety
- **False-report protection** — rate limiting (max reports per day per device), duplicate detection, and repeat-flagged reporters lose posting ability. New reports from first-time reporters in Phase 2 get a "new reporter" internal weighting until confirmed by sightings.
- **No selling or sharing of data. Ever.** No ads, no trackers, no analytics SDKs beyond Apple's opt-in TestFlight/App Store metrics. This is a promise printed inside the app.
- **Encrypted in transit and at rest** — CloudKit encrypts data by default; nothing sensitive is stored in plain text on-device.
- **Kid-safe rating** — no gory detail; photo uploads are auto-scanned (on-device) to block explicit content before posting.
- **Right to delete** — reporters can delete their own reports at any time; deletion propagates to all users.
- **Well-lit disclaimer culture** — every alert notification ends with "Stay aware, stay calm." Language across the app is checked so it informs without frightening — fear-mongering safety apps make seniors *less* likely to go outside, which is the opposite of the goal.

---

## 7. Extra Features (things you didn't mention, worth including)

1. **Weekly Area Summary** — a friendly Monday notification/card: "Your area last week: 2 reports, both car break-ins. Tip: lock doors and remove valuables."
2. **Safety Tips library** — short, large-print tips (home security, phone scams targeting seniors, package theft prevention). Genuinely valuable to the senior audience beyond the map.
3. **Trend indicators** — simple up/down arrows per category in "In My Area," so people get context, not just raw pins.
4. **Emergency contacts card** — one tap to call 911, plus editable local non-emergency police line and a personal emergency contact.
5. **Time filter** — Today / This week / This month chips on the map.
6. **Share a report** — share sheet to send an incident card to a family group chat ("FYI mom, lock the car").
7. **Offline viewing** — recently loaded reports cached locally so the map still shows data with a weak connection.
8. **Duplicate detection** — when a new report is close in place/time/category to an existing one, the app suggests "Is this the same incident? Add your sighting instead."
9. **Verified organization badge (future)** — allow a community association or local police unit to post verified advisories, visually distinct from resident reports.

### 7.1 Twelve More Features (round two)
1. **🔥 Heat Map overlay** — toggle a soft heat-shading layer on the map showing where reports concentrate over the last 30 days. Great big-picture view without reading a single pin.
2. **📊 Community Stats dashboard** — simple charts (Swift Charts): reports per week, by category, by time of day ("most car break-ins happen 11 PM–3 AM"). Plain-language captions under every chart.
3. **📌 Watched Places** — bookmark locations you care about (your mom's street, your kid's school, the community centre) and get alerts for those areas too, not just where you are.
4. **📱 Home Screen Widget** — a glanceable widget: "Your area: 2 reports this week ↓". Small, medium, and large sizes; large type throughout.
5. **⌚️ Apple Watch companion** — see nearby alerts, trigger SOS, and start the Walk Timer from the wrist. Ideal for seniors who walk without their phone in hand.
6. **🗣 Siri Shortcuts & voice reporting** — "Hey Siri, report to Beacon" starts a fully voice-driven report flow. Also: "Hey Siri, is my area safe this week?"
7. **🔔 Live Activities** — an active Walk Timer or nearby developing incident shows on the Lock Screen / Dynamic Island until resolved.
8. **🐕 Lost & Found board** — a separate, friendly tab section for lost pets, stolen bikes, and found items. Half of what people actually post on neighbourhood apps — giving it a home keeps the incident map clean, and it's the feel-good side of community.
9. **🏅 Community Helper badges** — gentle recognition (not gamification): "First report," "10 confirmed sightings," "Scam spotter." No leaderboards, no competition — just thanks.
10. **📄 Monthly PDF report** — one tap exports a clean, printable month summary for community association meetings or the fridge door. Printable = senior-friendly.
11. **📅 Community Events** — verified organizations can post safety meetings, neighbourhood watch signups, and police town halls; they appear as calendar cards, not map pins.
12. **🧭 Guided Tour & Practice Mode** — an interactive walkthrough where new users file a *practice report* on a fake incident that isn't published. Seniors learn by doing, with zero fear of "posting something wrong."

---

## 8. Launch & Loading Experience — "The Beacon Boot-Up" 💠

A signature moment when the app opens or loads data, inspired by a Minecraft beacon:

- **The animation:** a beacon emoji (💠, with 🔆 as the light source) sits on a small pedestal of three stacked rounded tiles. It **bounces with squash-and-stretch** (compresses slightly on landing, stretches on the way up — classic cartoon physics via SwiftUI spring animations), and on every bounce a **vertical beam of light shoots upward** from the gem, fading at the top, with a soft teal glow pulse radiating outward — just like a Minecraft beacon firing its beam.
- **Loading feedback:** the beam doubles as the progress indicator — it grows taller as loading progresses, and when loading completes the beam flashes once and the map fades in underneath it.
- **Sound & haptics:** a soft "hum" tick on each bounce (respects the silent switch) and a light haptic on completion.
- **Fast by design:** the animation never *adds* wait time — if loading finishes in under half a second, it plays one quick bounce and gets out of the way.
- **Accessibility:** with **Reduce Motion** on, the bounce is replaced by a gentle opacity pulse of the beacon and a plain progress bar; VoiceOver announces "Loading Beacon" and "Ready." The glow colours meet contrast requirements in all three themes (in Night Mode the beam is warm amber instead of teal).
- Also used as a small inline loader (a mini bouncing beacon) when the map fetches new reports, so the whole app has one consistent, friendly loading identity.

---

## 9. Technical Plan

### Architecture
- **SwiftUI** + **MVVM**, iOS 17+
- **MapKit** (`Map`, `Annotation`, clustering) + **CoreLocation** (when-in-use permission only)
- **SwiftData** for local storage in Phase 1; **CloudKit public database** in Phase 2 for real community sharing (free, no server to run, Apple-managed auth)
- **Push notifications** via CloudKit subscriptions for "In My Area" alerts
- **Testing:** Swift Testing for models/view-models, XCUIAutomation for the report flow and accessibility audits (`performAccessibilityAudit()`)

### Data model (core entity)
```swift
Incident
├── id: UUID
├── category: IncidentCategory      // enum: suspicious, theft, breakIn, robbery, carTheft, vandalism, other
├── date: Date                      // when it happened (date + time)
├── reportedAt: Date                // when it was posted
├── coordinate: latitude/longitude  // snapped to block level for homes
├── locationName: String            // "Maple St & 3rd Ave area"
├── peopleInvolved: Int?            // nil = "not sure"
├── sightingCount: Int              // starts at 1, +1 per "I saw this too"
├── details: String?                // optional description
├── vehicleDescription: String?
├── photoData: Data?                // property/scene only
├── isFlagged: Bool
└── expiresAt: Date                 // reportedAt + 30 days
```

### Build phases
| Phase | Scope |
|---|---|
| **1 — Local MVP** | Map/list/grid views + pins, full report flow, incident cards, search, In My Area, sightings, location sensing (follow-me, auto-centre, distances), the Beacon Boot-Up loading animation, all data on-device with SwiftData. Full accessibility + all three themes (Daylight, Night Watch, Night Mode) from day one. |
| **2 — Community sync** | CloudKit shared database, nearby push alerts, geofenced home zone, flagging/moderation, auto-expiry, false-report protection. |
| **3 — Safety toolkit** | SOS button, Walk Timer, Trusted Contacts, Daily Check-In, Scam Shield, heat map, watched places, widget. |
| **4 — Polish & extras** | Weekly summaries, safety tips, trends, stats dashboard, Lost & Found, French localization, share sheet, Simple Mode, Siri Shortcuts, Watch app, Live Activities, badges, PDF export, community events, practice mode. |

---

## 10. Privacy & Legal Notes
- Location permission: *when in use* only, with a plain-language explanation string.
- Clear privacy policy: reports are public and anonymous; no account required in Phase 1.
- In-app disclaimer at onboarding: *"Beacon reports are submitted by community members and are not verified by police. In an emergency, always call 911."*
- App Store category: Lifestyle/Utilities; will need moderation mechanism (flagging, above) to satisfy App Review's user-generated-content rules (guideline 1.2).

---

*Beacon — see your neighbourhood clearly. Built by KDragon.*
