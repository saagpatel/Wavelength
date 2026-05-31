# Wavelength

## Overview
iOS app (iPhone, iOS 17+) rendering a real-time annotated spectrogram of the electromagnetic environment. Fuses live device sensing (Bluetooth LE, Wi-Fi, cellular) with GPS-anchored contextual data (FCC allocations, OpenCellID towers, FM stations, satellite TLEs). MIT licensed — no backend, no user accounts, no analytics.

## Stack
- Swift 6.0 — strict concurrency, actor isolation throughout
- SwiftUI iOS 17+ — Observable macro; no UIKit except `MTKView` wrapped in `UIViewRepresentable`
- Metal 3 — GPU compute shader for spectrogram texture rendering
- GRDB.swift ~7.x — SQLite ORM, type-safe queries, migration runner
- Alamofire ~5.9 — HTTP client for OpenCellID, CelesTrak, FCC FM APIs
- SatelliteKit ~2.x (gavineadie/SatelliteKit) — TLE parsing + SGP4 propagator
- CoreBluetooth / CoreTelephony / CoreLocation / NetworkExtension

## Build / Test / Run
- Build and test: open in Xcode, build scheme `Wavelength`, run tests with `xcodebuild test`
- Deploy to a physical device — grant Bluetooth, Wi-Fi (Location), and Location permissions on first launch
- Phases 0–3 complete (56 files, 63 passing tests); next: TestFlight beta and App Store submission
- Full task list and acceptance criteria: `IMPLEMENTATION-ROADMAP.md`

## Conventions
- Swift 6 strict concurrency — all mutable state in actors or `@Observable` classes; `@unchecked Sendable` is a defect
- File naming: PascalCase for types, camelCase for files containing one type (e.g. `SignalRegistry.swift`)
- Dependency management: SPM only — CocoaPods and Carthage are not used
- Git: conventional commits — `feat:`, `fix:`, `chore:`, `perf:`
- Minimum deployment target: iOS 17.0
- Unit tests for all data transforms (frequency math, SQLite queries, TLE parsing) before committing

## Architecture Decisions
| Decision | Choice | Why |
|---|---|---|
| Frequency axis scale | Logarithmic (log10) | Linear compresses FM band to 0.3% of display |
| Frequency scope | 70 MHz – 6 GHz | Covers all daily-life signals; mmWave deferred to v2 |
| Spectrogram texture | 1024 freq bins × 512 time cols, circular buffer | Fits 2MB GPU budget, 30fps on A15 |
| Update cadence | New column every 2s, render at 30fps | Matches sensor update rate, manageable GPU writes |
| Colormap | Viridis (default), Magma (settings toggle) | Perceptually uniform, OLED-optimized, colorblind-safe |
| Signal provenance | Three tiers: Live / Nearby / Probable | Honest about what's sensed vs. inferred |
| Wi-Fi sensing | NEHotspotHelper (applied) + NEHotspotNetwork fallback | Entitlement may take weeks; fallback ships anyway |
| Data storage | GRDB.swift + SQLite, local only | Offline-first, no vendor lock-in |
| API keys | CryptoKit AES-GCM in app, never in source | OpenCellID key is the only secret |

## Gotchas
- Signal data goes in GRDB SQLite — `localStorage` and `UserDefaults` are not used for signal state
- Bluetooth display: store category only — raw device names and MAC addresses are not stored (privacy mode on by default)
- External API calls: respect cache TTLs (towers: 7 days, TLEs: 24h, FM: 30 days) — do not call on every app foreground
- mmWave (28 GHz) and RTL-SDR hardware support are explicitly deferred to v2 — do not add in v1
- No gamification, badges, or social features — informational only
- Implement only features in the current phase of `IMPLEMENTATION-ROADMAP.md`

<!-- portfolio-context:start -->
# Portfolio Context

## What This Project Is

Wavelength is an open-source iOS app (iPhone, iOS 17+) that renders a real-time annotated spectrogram of the electromagnetic environment. It fuses live device sensing (Bluetooth LE, Wi-Fi, cellular) with GPS-anchored contextual data (FCC allocations, OpenCellID towers, FM stations, satellite TLEs) to show users what signals surround them at any location. MIT licensed, no backend, no user accounts, no analytics.

## Current State

**Phases 0–3 complete.** Core Metal spectrogram pipeline, live sensing (Bluetooth, Wi-Fi, cellular), contextual overlay (FCC bands, cell towers, FM stations, satellites), settings, onboarding, and App Store metadata are all implemented (56 files, 63 tests). Remaining: TestFlight beta testing and App Store submission.

## Stack

- Swift: 6.0 (strict concurrency, actor isolation throughout)
- SwiftUI: iOS 17+ (Observable macro, no UIKit except MTKView bridge)
- Metal: 3 — GPU compute shader for spectrogram texture rendering
- GRDB.swift: ~7.x — SQLite ORM, type-safe queries, migration runner
- Alamofire: ~5.9 — HTTP client for OpenCellID, CelesTrak, FCC FM APIs
- SatelliteKit: ~2.x (gavineadie/SatelliteKit) — TLE parsing + SGP4 propagator for satellite positions
- CoreBluetooth / CoreTelephony / CoreLocation / NetworkExtension: system frameworks

## How To Run

Deploy to a physical device. Grant Bluetooth, Wi-Fi (Location), and Location permissions on first launch. The spectrogram starts rendering immediately; tap any signal band to inspect it.

## Known Risks

- Do not use `localStorage`, `UserDefaults` for signal data — all state in GRDB SQLite
- Do not add CocoaPods or Carthage — SPM only
- Do not store raw Bluetooth device names or MAC addresses — privacy mode on by default; display category only
- Do not call external APIs on every app foreground — respect cache TTLs (towers: 7 days, TLEs: 24h, FM: 30 days)
- Do not build mmWave (28 GHz) or RTL-SDR hardware support in v1 — explicitly deferred
- Do not add gamification, badges, or social features — clean, aesthetic, informational only
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md

## Next Recommended Move

Use this context plus the README and supporting docs to resume the next active task, then promote the repo beyond minimum-viable by capturing a dedicated handoff, roadmap, or discovery artifact.

<!-- portfolio-context:end -->
