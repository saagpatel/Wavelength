# Wavelength

Educational iPhone frequency visualization built with SwiftUI, Metal, Bluetooth Low Energy, CoreLocation, bundled FCC/FM/airport references, and CelesTrak TLE data.

## Product boundaries

- Actual observations are limited to Bluetooth Low Energy advertisements; DEBUG builds also inject mock Bluetooth, Wi-Fi, and cellular signals labeled as live.
- Nearby signals come from bundled reference data, cached satellite TLEs, or on-device satellite calculations.
- Probable signals are contextual inferences, never measurements.
- Do not describe the app as a spectrum analyzer, SDR, Wi-Fi scanner, cellular scanner, or raw-RF detector.
- Bluetooth and location permissions must remain optional, user-initiated, and explained before the system prompt.
- Location and Bluetooth observations must remain on-device. Known violation: `ContextualEngine` passes location to CoreLocation reverse geocoding when online for probable urban 5G inference; fix it, or decide to change this rule together with PRIVACY.md and APPSTORE-METADATA.md.
- The only runtime reference download is public CelesTrak TLE data, without location parameters (see the known reverse-geocoding violation above).

## Engineering constraints

- Generate the Xcode project from `project.yml`; do not treat hand-edited project output as source of truth.
- Keep Swift 6 strict concurrency clean.
- Preserve provenance labels across registry, visualization, annotations, details, metadata, and screenshots.
- Keep Release builds free of debug mock signals.
- Do not add entitlement-gated network scanning or client-side API credentials.
- Keep bundle IDs, permissions, privacy policy, manifest, and App Store metadata synchronized.

## Commands

- `make test`
- `make release`
- `make archive`

See `README.md` and current source for current product truth. `PRIVACY.md` and `APPSTORE-METADATA.md` still claim location stays on-device, which does not account for the reverse-geocoding call. `IMPLEMENTATION-ROADMAP.md` and `docs/PORTFOLIO-DISPOSITION.md` are historical records.
