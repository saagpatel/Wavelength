# Wavelength

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](#)

> Every radio signal in the room, rendered in real time

Wavelength is a real-time electromagnetic spectrum visualizer for iOS. It renders a live GPU-accelerated spectrogram of the radio environment around you — Bluetooth, Wi-Fi, cellular, FM broadcast, GPS, and satellites — layered on a log-scale frequency axis from 70 MHz to 6 GHz.

## Features

- **GPU-rendered spectrogram** — Metal compute shader draws a 1024×512 RGBA16F circular-buffer texture at 30 fps using viridis or magma colormaps
- **Three signal tiers** — Live (hardware-sensed), Nearby (database + GPS confirmed), and Probable (location-inferred) rendered with distinct visual weight
- **Multi-source sensing** — CoreBluetooth, NEHotspot Wi-Fi scan, CoreTelephony cellular band detection, and CoreLocation geofencing
- **FCC band overlay** — spectrum allocation bands drawn as labeled regions directly on the spectrogram (~8 MB bundled SQLite)
- **CelesTrak satellite propagation** — TLE-based SGP4 satellite position integration; active overhead satellites plotted on the frequency axis
- **Tap-to-inspect** — bottom sheet with signal label, dBm reading, provenance, and category
- **Privacy mode** — anonymizes Bluetooth device identifiers before any logging

## Quick Start

### Prerequisites
- Xcode 16+
- iOS 17.0+ device (hardware sensor access required)

### Installation
```bash
git clone https://github.com/saagpatel/Wavelength
open Wavelength.xcodeproj
```

### Usage
Deploy to a physical device. Grant Bluetooth, Wi-Fi (Location), and Location permissions on first launch. The spectrogram starts rendering immediately; tap any signal band to inspect it.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6.0, strict concurrency |
| UI | SwiftUI |
| GPU | Metal 3 (compute + render pipeline) |
| Sensing | CoreBluetooth, NEHotspot, CoreTelephony, CoreLocation |
| Reference data | FCC SQLite DB, OpenCellID, CelesTrak TLE + SGP4 |

## Architecture

Four sensor adapters (`BluetoothAdapter`, `WiFiAdapter`, `CellularAdapter`, `LocationAdapter`) run as independent actors, each publishing detected signals to a central `SignalAggregator`. The aggregator merges signals into frequency buckets and writes to a `MTLBuffer` that the Metal compute shader reads each frame. The shader maps power levels to colormap indices and writes to the circular-buffer texture, which the render pipeline samples as a scrolling waterfall. FCC allocation lookups are batched SQL queries triggered only on visible frequency range changes.

## License

MIT