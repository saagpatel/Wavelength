# Wavelength

Wavelength is an educational iPhone spectrum visualization built with SwiftUI and Metal. It combines Bluetooth Low Energy observations with bundled FM/FCC reference data, calculated satellite visibility, and clearly labeled contextual inferences.

It is not a software-defined radio, spectrum analyzer, Wi-Fi scanner, cellular-band detector, or safety/security instrument. iPhone hardware and public APIs do not expose raw RF power across the displayed spectrum; the app distinguishes observed, nearby-reference, and probable signals so those categories are not presented as equivalent measurements.

## Features

- GPU-rendered scrolling visualization with Viridis and Magma color maps
- Optional Bluetooth Low Energy observation
- Bundled FCC allocation and FM station reference data
- CelesTrak orbital-element refresh and on-device satellite visibility calculation
- Contextual airport-based signal inference
- Tap-to-inspect provenance and educational descriptions
- No accounts, analytics, advertising, or tracking

## Build

Requirements: Xcode 16 or newer, iOS 17+, and XcodeGen.

```bash
xcodegen generate
make test
make release
```

Bluetooth and location behavior require a physical device. The simulator uses debug-only mock signals to make the rendering and inspection flow testable.

## Data boundaries

- Bluetooth observations and location remain on-device.
- The only runtime data download is public satellite TLE data from CelesTrak; location is not included in that request.
- FM, FCC, and airport reference data ship in the app bundle.
- Wavelength is educational and must not be used as the sole basis for radio-frequency, navigation, aviation, security, or safety decisions.

## License

MIT
