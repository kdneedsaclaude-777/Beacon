# 💠 Beacon

**See your neighbourhood clearly.** A community safety app for iOS where neighbours share and view local incidents — thefts, break-ins, scams, suspicious activity — on one shared map. Designed senior-first: big text, big buttons, plain language, and full VoiceOver support.

Created by **KDragon**.

## Features

**The map** — incidents shown three ways (map pins, list, grid), with search (streets, categories, keywords), time/category filters, a heat map overlay, zoom buttons, Follow Me, and a plain-language legend. A one-tap emergency call banner is always present and can never be disabled — it dials the correct emergency number for the user's region (911, 999, 112, …).

**Reporting** — a one-question-per-screen wizard with 14 incident types (each with concrete examples), block-level location privacy, people count, optional photo (property only — and no photos at all on suspicious-person reports), duplicate detection ("add your sighting instead"), and a practice mode that posts nothing.

**Community signals** — "I saw this too" sighting counts, "I didn't see this" thumbs-down votes (enough doubts hide a report), flagging, and 30-day auto-expiry.

**Safety toolkit** — one-tap SOS, a Walk Timer that reminds you to check in, trusted contact texting with your live location, a daily check-in reminder (half-hour time picker), Scam Shield, 16 age-matched safety tips, and a dedicated big-print safety guide for users 40+.

**Inclusivity by design** — reports describe actions, never appearance (no race/ethnicity descriptions, enforced by form guidance); automatic exact-address detection blocks privacy leaks; a family filter blurs harsh words (locked on for minors); profanity earns strikes and three strikes removes posting access; under-13 profiles are view-only; no comments section, on purpose.

**Profiles** — local-only sign-up with a silly generated nickname ("Waltzing Teapot" 🎲), an avatar, and an age group (never a birthday). Age shapes the experience: tips, filters, and posting rights.

**Accessibility** — Dynamic Type everywhere plus an in-app text size picker, high-contrast mode, Simple Mode, Reduce Motion support, VoiceOver labels throughout, and an interactive tap-to-learn tutorial with a Skip button.

**Themes** — Daylight, Night Watch (dark), and Night Mode (warm, low-glare, larger text), plus the "Beacon Boot-Up" bouncing-gem loading animation.

## Project layout

```
Beacon.xcodeproj        Xcode project (target/scheme: Beacon)
Beacon/                 App source (SwiftUI, iOS 26+)
  Models.swift            Incident, categories, EmergencyNumber, TimeFilter
  IncidentStore.swift     Persistence (JSON), votes, merging, widget summary
  CloudSync.swift         CloudKit community sync (Phase 2)
  LocationService.swift   CoreLocation wrapper
  Theme.swift             Palettes, AppSettings, AgeGroup
  ContentFilter.swift     Family filter + moderation (blocked words, address detection)
  *View.swift / *Screen.swift   All screens
BeaconTests/            Unit tests (Swift Testing) for safety-critical logic
BeaconWidget-Install/   Ready-made home-screen widget + INSTALL.md
PLAN.md                 Full product/design plan
PRIVACY.md, TERMS.md    Policy drafts
CHANGELOG.md            Update log
```

## Building & running

Open `Beacon.xcodeproj` in Xcode, select an **iPhone simulator** destination, and Run. No dependencies, no packages.

Simulator tips:
- Set a location or the app falls back to a default area: **Features → Location → Custom Location** (e.g. 43.6532, -79.3832 for Toronto). Sample reports auto-relocate once a real fix arrives.
- Pinch-zoom on the simulator = hold **Option** and drag (or use the in-app +/− buttons).

## Tests

Run the `BeaconTests` suite in Xcode (⌘U). Covers moderation (blocked words, address detection), the family filter, voting rules, duplicate detection, expiry, sample relocation, and emergency-number region mapping.

> If tests fail with a "test host" error after the project rename: BeaconTests target → Build Settings → **Test Host** → replace `Finder.app/Finder` with `Beacon.app/Beacon`.

## Enabling community sync (CloudKit)

Reports are local-only until CloudKit is enabled (requires an Apple Developer Program membership):
1. Beacon target → Signing & Capabilities → **+ Capability → iCloud → CloudKit**
2. Sign the device/simulator into iCloud
3. Post one report (creates the CloudKit schema), then **Settings → Community sync → Sync now** on a second device

Sync is location-scoped: users only pull reports within 50 km of themselves. Without the capability, the app stays fully functional in local-only mode.

## Home-screen widget

See `BeaconWidget-Install/INSTALL.md` — two minutes in Xcode (new Widget Extension target + the `group.beacon.shared` App Group on both targets).
