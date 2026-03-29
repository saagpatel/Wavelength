# Wavelength

[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue?logo=apple)](https://developer.apple.com/ios/)
[![Metal](https://img.shields.io/badge/GPU-Metal-silver?logo=apple)](https://developer.apple.com/metal/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/tests-63%20passing-brightgreen)]()

A real-time electromagnetic spectrum visualizer for iOS. Wavelength renders a live GPU-accelerated spectrogram of the radio environment around you — Bluetooth, Wi-Fi, cellular, FM broadcast, GPS, and satellites — layered on a log-scale frequency axis from 70 MHz to 6 GHz.

## Screenshot

> _Screenshot placeholder — add a device screenshot here_

## Features

- **GPU-rendered spectrogram** — Metal compute shader draws a 1024x512 RGBA16F circular-buffer texture at 30 fps using viridis or magma colormaps
- **Three signal tiers** — Live (hardware-sensed), Nearby (database + GPS confirmed), and Probable (location-inferred) signals each rendered with distinct visual weight
- **Multi-source sensing** — CoreBluetooth, NEHotspot Wi-Fi scan, CoreTelephony cellular band detection, and CoreLocation geofencing
- **Contextual enrichment** — Bundled FCC spectrum allocation database (~8 MB SQLite), OpenCellID cell tower lookup, CelesTrak TLE satellite position propagation via SGP4, and FCC FM station lookup
- **FCC band overlay** — Frequency allocations drawn as labeled bands directly on the spectrogram
- **Tap-to-inspect** — Bottom sheet panel with signal label, sublabel, dBm reading, provenance, and category
- **Frequency presets** — Full (70–6000 MHz), Broadcast (70–1000 MHz), Mobile (700–6000 MHz), or custom range
- **Privacy mode** — Anonymizes Bluetooth device identifiers before any logging
- **Onboarding flow** — Three-screen permission request sequence on first launch

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6, strict concurrency |
| UI | SwiftUI + UIViewRepresentable |
| GPU rendering | Metal, MetalKit (MTKView) |
| Concurrency | Swift actors, `@Observable` |
| Database | GRDB.swift (SQLite) |
| Networking | Alamofire |
| Satellite math | SatelliteKit (SGP4 propagation) |
| Sensors | CoreBluetooth, CoreTelephony, NetworkExtension, CoreLocation |

## Prerequisites

- Xcode 16+
- iOS 17.0+ device (Metal required; simulator has no radio hardware)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the `.xcodeproj` from `project.yml`

Optional: an OpenCellID API key for live cell tower lookups (the app functions without one using cached data).

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/saagpatel/Wavelength.git
cd Wavelength

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode
open Wavelength.xcodeproj
```

Then build and run on a physical iOS 17+ device. A simulator build compiles but sensor output will be empty — radio hardware is required for live signal data.

## Project Structure

```
Wavelength/
├── Wavelength/
│   ├── App/           # @main entry point, initialization
│   ├── Core/          # SignalRegistry, Signal model, FrequencyBand, SettingsManager
│   ├── Sensing/       # BluetoothScanner, WiFiScanner, CellularMonitor, LocationMonitor
│   ├── Contextual/    # ContextualEngine, FCCDatabase, CellTowerService, SatelliteService, FMStationService
│   ├── Metal/         # SpectrogramRenderer, SpectrogramTexture, Shaders.metal
│   ├── UI/            # SpectrogramView, FrequencyAxisView, SignalDetailPanel, SettingsView, OnboardingView
│   ├── Database/      # DatabaseManager, GRDB migrations
│   ├── Models/        # Shared types and enums
│   └── Resources/     # fcc_spectrum.sqlite, itu_regions.json, airports.json
├── WavelengthTests/   # 63 unit tests
├── scripts/
│   └── build_fcc_db.py  # One-time FCC data pre-processor (not bundled in app)
└── project.yml          # XcodeGen project definition
```

## Running Tests

Open `Wavelength.xcodeproj` in Xcode and press `Cmd+U`, or run:

```bash
xcodebuild test -scheme Wavelength -destination 'platform=iOS Simulator,name=iPhone 16'
```

## License

MIT — see [LICENSE](LICENSE).
