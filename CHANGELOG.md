# Beacon — Update Log

All notable changes to Beacon. Created by KDragon.

## 0.9 — September 7, 2026
- **Region-aware emergency numbers**: the app now dials and displays the correct emergency number for the user's region (911 CA/US/MX, 999 UK, 000 AU, 111 NZ, 112 international fallback, and more) across the banner, SOS, tutorial, onboarding, and guides
- **Location-scoped community sync**: reports upload with a CloudKit location field; syncing pulls only reports within 50 km of the user (last 30 days), so communities never download other cities' data
- "Location off" banner on the map: re-asks for permission when possible, deep-links to Settings after a denial; same fix-it button in In My Area
- New test for emergency-number mapping (suite now 22 tests)

## 0.8 — September 7, 2026
- **Unit test suite** (21 tests): moderation, address privacy detection, family filter, voting rules, duplicate detection, expiry, sample relocation
- **CloudKit community sync (Phase 2 scaffolding)**: upload/pull/merge of reports, shared sighting/thumbs-down/flag counters, remote delete, pending-upload retry, and a Community Sync status card in Settings — fails safe to local-only without the iCloud capability
- **Photo attachments**: optional property/scene photo on reports (compressed, synced) — deliberately unavailable on suspicious-activity reports
- **Heat map**: map chip that swaps pins for translucent density shading
- **Widget prepared**: app publishes weekly summary; ready-made widget code + install guide in `BeaconWidget-Install/`
- App renamed **Finder → Beacon** (target, scheme, folders)

## 0.7 — September 7, 2026
- **App icon**: beacon gem + light beam, in light/dark/tinted variants
- **Location fix**: sample reports automatically relocate to the user's real area once located (previously stuck at the fallback location)

## 0.6 — September 7, 2026
- **Six new report types** (14 total): package theft, bike theft, trespassing, disturbance, safety hazard, lost/found pet — each with concrete examples shown on report cards and in the legend (tooltip on iPad/Mac)
- **911 banner always returns** when revisiting the map after being dismissed; permanent disabling is deliberately impossible
- Random **silly nicknames** at sign-up with a 🎲 reroll ("Waltzing Teapot")
- **Daily check-in time picker** — half-hour steps only
- **Report moved to second tab**

## 0.5 — September 7, 2026
- **Dedicated safety guide for 40+** (phone scams, door safety, out and about, online, health & home)
- **Map zoom buttons** (+/−)
- **Avatars** (16 friendly emoji, no photos)
- **Thumbs-down voting** ("I didn't see this") with community auto-hide threshold
- **Three-strike moderation**: inappropriate language blocks the post; third strike removes posting access
- **Exact-address detection** blocks descriptions containing street addresses or unit numbers; privacy reminders throughout the report flow
- Fully interactive tutorial (tap the actual element to advance); "Small" text size label

## 0.4 — September 7, 2026
- **Interactive tutorial** with Skip button, replayable from Settings
- **Local sign-up/sign-in** (nickname + age group — never a birthday) required for posting
- **Age groups** shape the experience: under-13 view-only Explorer mode, minors' word filter locked on, seniors get larger text automatically, age-matched safety tips
- **Family filter**: blurs harsh words in reports (tap-to-reveal for adults)
- **One-tap 911** with no confirmation step

## 0.2–0.3 — September 6, 2026
- **Full MVP**: map/list/grid views, 8 report categories, step-by-step report wizard with duplicate detection, sighting confirmations, search, time/category filters, legend, In My Area with radius picker/trends/charts, Safety tab (SOS, Walk Timer, trusted contact, Scam Shield, tips), Settings (3 themes + Night Mode, text size, high contrast, Simple Mode, practice reporting), onboarding, Beacon Boot-Up loading animation, 12 sample reports, JSON persistence
- Block-level location rounding, 30-day report expiry, flagging, anonymous reports

## 0.1 — September 6, 2026
- Initial product & design plan (`PLAN.md`): concept, guiding principles, colour themes, accessibility-first requirements, inclusivity guardrails, feature roadmap
