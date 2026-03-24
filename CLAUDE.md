# Wavelength

## Overview
Wavelength is an open-source iOS app (iPhone, iOS 17+) that renders a real-time annotated spectrogram of the electromagnetic environment. It fuses live device sensing (Bluetooth LE, Wi-Fi, cellular) with GPS-anchored contextual data (FCC allocations, OpenCellID towers, FM stations, satellite TLEs) to show users what signals surround them at any location. MIT licensed, no backend, no user accounts, no analytics.

## Tech Stack
- Swift: 6.0 (strict concurrency, actor isolation throughout)
- SwiftUI: iOS 17+ (Observable macro, no UIKit except MTKView bridge)
- Metal: 3 — GPU compute shader for spectrogram texture rendering
- GRDB.swift: ~6.x — SQLite ORM, type-safe queries, migration runner
- Alamofire: ~5.9 — HTTP client for OpenCellID, CelesTrak, FCC FM APIs
- SwiftyTLE: latest — TLE parsing + SGP4 propagator for satellite positions
- CoreBluetooth / CoreTelephony / CoreLocation / NetworkExtension: system frameworks

## Development Conventions
- Swift 6 strict concurrency — all mutable state in actors or `@Observable` classes, zero `@unchecked Sendable`
- File naming: PascalCase for types, camelCase for files that contain one type (e.g., `SignalRegistry.swift`)
- No storyboards — SwiftUI only, except `MTKView` wrapped in `UIViewRepresentable`
- Unit tests for all data transforms (frequency math, SQLite queries, TLE parsing) before committing
- Git: conventional commits — `feat:`, `fix:`, `chore:`, `perf:`
- Minimum deployment target: iOS 17.0

## Current Phase
**Phase 0: Foundation (Weeks 1–2)**
See IMPLEMENTATION-ROADMAP.md for full task list, acceptance criteria, and verification checklist.

## Key Decisions
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

## Do NOT
- Do not use `localStorage`, `UserDefaults` for signal data — all state in GRDB SQLite
- Do not add CocoaPods or Carthage — SPM only
- Do not store raw Bluetooth device names or MAC addresses — privacy mode on by default; display category only
- Do not call external APIs on every app foreground — respect cache TTLs (towers: 7 days, TLEs: 24h, FM: 30 days)
- Do not build mmWave (28 GHz) or RTL-SDR hardware support in v1 — explicitly deferred
- Do not add gamification, badges, or social features — clean, aesthetic, informational only
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md
