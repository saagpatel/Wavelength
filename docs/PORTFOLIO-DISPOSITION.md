# Wavelength — Portfolio Disposition

**Status:** Release Frozen (iOS App Store) — SwiftUI iOS RF spectrum
visualizer on `origin/main`, with full App Store submission
scaffolding (`APPSTORE-METADATA.md`, fastlane `deliver`,
DEVELOPMENT_TEAM, Privacy Manifest, scheme generation, copyright +
ExportOptions, privacy policy, archive prep, AI-generated final
icon, XcodeGen `project.yml`). Classified as **Utilities** (primary)
+ **Education** (secondary) at **Free**. **Eleventh and final
iOS App Store cluster member from the initial portfolio audit.**
Caps the iOS cluster — pattern is stable across 11 structurally-
distinct iOS apps.

**Memory drift note:** Prior memory described Wavelength as an
"iOS spectrogram" (audio FFT). The `APPSTORE-METADATA.md` on
canonical main describes it as an **RF spectrum** visualizer ("See
the Invisible RF World") with keywords Bluetooth / WiFi / cellular /
satellite / FCC — a wireless-signal visualizer, not an audio
spectrogram. Disposition trusts the operator-authored metadata
file over the memory record.

> Disposition uses strict `origin/main` verification.
> **Caps the iOS App Store cluster at 11 members; pattern stable.**

---

## Verification posture

This repo has **only `origin`** (`saagpatel/Wavelength`) — no
`legacy-origin` remote. Clean.

Specifically verified on `origin/main`:

- Tip: `99b04ef` chore: replace placeholder icon with AI-generated
  app icon
- Substantive App Store prep commits:
  - `99b04ef` AI-generated app icon (final)
  - `d99418c` fastlane deliver config
  - `5eaa183` gradient placeholder (intermediate)
  - `81deb89` app store archive prep
  - `3b2757e` privacy policy + metadata URLs
  - `193d6cb` copyright + ExportOptions
  - `fd3336b` App Store Connect metadata
  - `5add5ae` App Store prep — DEVELOPMENT_TEAM, Privacy Manifest,
    scheme generation
- App Store identity:
  - Name: **Wavelength**, Subtitle: **See the Invisible RF World**
  - Bundle ID: `com.wavelength.app`, SKU: `WAVELENGTH-001`
  - Categories: **Utilities** + **Education**
  - Age Rating: 4+, **Price: Free**, All territories
- Default branch: `main`

---

## Current state in one paragraph

Wavelength is a SwiftUI iOS app that visualizes wireless signals
around the user — Bluetooth (via CoreBluetooth scan), WiFi (via
NetworkExtension framework, where entitlements permit), cellular
signal strength, and educational FCC-band context. Per memory:
Phases 0–3 complete, 89 tests. The canonical commit cadence shows
full App Store prep cadence (DEVELOPMENT_TEAM + Privacy Manifest +
APPSTORE-METADATA + ExportOptions + copyright + privacy policy +
fastlane deliver + final AI icon). The "See the Invisible RF World"
subtitle positions this as an educational tool more than a
diagnostic instrument — iOS doesn't expose raw RF spectrum APIs
to apps, so this is a "what wireless signals can I observe with
the SDKs I have access to" visualizer, not a true spectrum
analyzer.

---

## Why "Release Frozen (iOS App Store, local-first)" — eleventh cluster member

The cluster signature continues to hold. Wavelength shares the
local-first sub-shape with most cluster siblings (no operator
backend; observations stay on device). Educational secondary
category may help with App Store editorial pickup (similar to
Seismoscope + Tide Engine positioning).

This is the **eleventh** iOS cluster member from the initial
portfolio audit. After this row, all iOS apps in operator memory
have been dispositioned.

---

## Cluster taxonomy update (iOS cluster capped at initial 11)

| Cluster | Count | Sub-shapes |
|---|---|---|
| Signing (Apple desktop) | 24 | … |
| **iOS App Store** | **11** | local-first (8) / cloud-backed (1, Nocturne) / local-first+API-read (2, Tide Engine + Seismoscope) / Active prep-arc (1, Terroir overlaps with local-first count above — Terroir is the 10th member counted) |
| Static-host (web) | 3 | … |
| Self-hosted service | 1 | … |
| PyPI distribution | 2 | … |
| Local-first pipeline | 1 | … |
| Operator-tool / dogfood | 1 | … |
| Chrome MV3 extension | 2 | … |
| Game (Godot) | 1 | … |

iOS cluster final composition (11 members):
1. Calibrate — local-first, Free, StoreKit IAP, leaderboard, friend groups, prediction game
2. Chromafield — local-first, Free, Metal generative art instrument
3. Ghost Routes — local-first, Free, privacy-first Google Takeout location visualizer
4. Nocturne — **cloud-backed**, Free, citizen-science light pollution heatmap
5. Tide Engine — local-first + API-read, Free (?), NOAA + WorldTides tidal sim
6. Liminal — local-first, **$4.99 paid**, SceneKit + Metal atmospheric exploration / puzzle game
7. Redact — local-first, **$3.99 paid**, forward-only writing
8. Room Tone — local-first, **$2.99 paid**, ARKit + LiDAR acoustic resonance synthesizer
9. Seismoscope — local-first + API-read, Free, accelerometer seismometer + USGS feed
10. Terroir — **Active prep arc**, divergent-branches trap, flavor profile + data pipeline
11. **Wavelength** — local-first, Free, RF spectrum visualizer

**Pricing distribution**: 8 Free + 3 Paid ($2.99 / $3.99 / $4.99).

**Sub-shape distribution**: 8 local-first + 1 cloud-backed +
2 local-first+API-read. Cluster is operationally trusted.

---

## Unblock trigger (operator)

1. **App Store Connect record** + Free tier.
2. **CoreBluetooth + NetworkExtension entitlements** — verify
   Info.plist usage descriptions are clear and operator's
   developer account has the necessary capability profiles.
3. **Privacy nutrition labels** — wireless-scan apps often look
   suspicious to reviewers. Be explicit: nothing transmitted, no
   network requests, no analytics, no PII collection. Local-only
   observation.
4. **Educational positioning** — secondary category Education may
   open App Store editorial / "Today" feature pickup for
   wireless-spectrum awareness. Worth pitching.
5. **FCC-band educational content** — verify any FCC frequency
   data shipped in the app is accurate and properly attributed.
6. **Required screenshots** + fastlane deliver dry-run.
7. **Submit for Review.**

Estimated operator time: ~3-4 hours.

---

## Portfolio operating system instructions

| Aspect | Posture |
|---|---|
| Portfolio status | `Release Frozen (iOS App Store, local-first)` |
| Distribution channel | **App Store Connect** — Utilities + Education, Free |
| Review cadence | Suspend overdue counting |
| Resurface conditions | (a) Submission to App Store Review, (b) CoreBluetooth / NetworkExtension API change, (c) FCC band data refresh, or (d) v1.1 scope |
| Co-batch with | iOS App Store cluster — **caps the cluster at 11 from the initial audit** |
| Special concern | **Wireless-scan review scrutiny.** Apps that scan wireless signals get extra reviewer attention. Privacy posture (local-only, no transmission) must be explicit. |
| Special concern | **NetworkExtension entitlement.** WiFi scan capability requires an entitlement that's harder to obtain than baseline; verify the developer account has it. |
| Special concern | **Memory drift recorded** — prior memory called this an audio spectrogram; canonical state is RF spectrum. Update memory record to reflect actual product. |

---

## Reactivation procedure

1. Verify `git branch -vv` shows `main` tracking `origin/main`.
2. Review stash `r14-wavelength-stash` (CLAUDE.md + project.yml
   mods + .claude/ + .codex/ + AGENTS.md).
3. Open Xcode → confirm DEVELOPMENT_TEAM + CoreBluetooth +
   NetworkExtension entitlements.
4. **Audit `PrivacyInfo.xcprivacy` for Required Reason API
   declarations** (similar pattern to Room Tone's UserDefaults
   fix — wireless scan APIs may need declarations).
5. **Test on physical device with active Bluetooth + WiFi**
   environments.
6. Run Swift Testing / XCTest target — 89 tests.

---

## Last known reference

| Field | Value |
|---|---|
| `origin/main` tip | `99b04ef` chore: replace placeholder icon with AI-generated app icon |
| Default branch | `main` |
| Build system | iOS / Swift / SwiftUI / **CoreBluetooth + NetworkExtension** / XcodeGen / XCTest |
| Bundle ID | `com.wavelength.app` |
| App Store category | Utilities + Education |
| Price | **Free** |
| Phases shipped | Phases 0–3 complete; 89 tests |
| Migration state | No `legacy-origin` remote |
| Memory drift correction | Prior memory described "spectrogram" (audio); canonical state is "RF spectrum visualizer" (wireless signals). Update memory record. |
| Distinguishing feature | **Eleventh and final iOS App Store cluster member from initial audit.** Caps the cluster. Pattern stable across 11 structurally-distinct iOS apps. |
