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

## Verification

Run from the repository root. Use full Xcode with active Xcode developer tools and an installed iOS simulator;
Command Line Tools alone cannot run these checks. The Make targets generate the
project with XcodeGen; Swift package resolution may download declared packages.

```bash
# Simulator unit suite; signing is disabled by the Makefile
make test

# Compile the Release configuration without signing or uploading an archive
make release
```

The Makefile's simulator destination must exist locally. Override `DESTINATION` if
needed, for example `make test DESTINATION='platform=iOS Simulator,name=iPhone 17'`
for an installed simulator with that name. For a focused pure-data check, open the
generated project in Xcode and run `FrequencyBandTests` in the Test navigator.
The broader simulator suite and Release build remain the checks before delivery.
There is no configured standalone lint or formatter command.

The focused frequency-band suite uses numeric fixtures and needs no Bluetooth,
location permission, or CelesTrak refresh. For UI changes, check the simulator
debug mock flow and signal provenance labels. Bluetooth/location behavior needs
separate device checks. CodeQL excludes the Metal shader; ordinary CI and the
Release build are the compilation checks that include it.

## Data boundaries

- Bluetooth observations and location remain on-device.
- The only runtime data download is public satellite TLE data from CelesTrak; location is not included in that request.
- FM, FCC, and airport reference data ship in the app bundle.
- Wavelength is educational and must not be used as the sole basis for radio-frequency, navigation, aviation, security, or safety decisions.

## License

MIT
