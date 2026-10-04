# Wavelength — App Store Connect Metadata Draft

Confirm all values in App Store Connect before submission.

## Identity

| Field | Draft value |
|---|---|
| Name | Wavelength: RF Spectrum |
| Subtitle | Explore the signal landscape |
| Bundle ID | `com.waveylength.app` |
| SKU | `WAVELENGTH-001` |
| Primary category | Education |
| Secondary category | Utilities |
| Price | Decide before release |

## Keywords

`spectrum,radio,signals,Bluetooth,satellite,FCC,frequency,science,education,visualizer`

## Description

Wavelength is an educational window into the signal landscape around you.

Explore a GPU-rendered frequency visualization that separates three kinds of information: Bluetooth activity your iPhone can observe, public reference signals that are relevant near your location, and contextual signals that are only probable. Tap any annotation to see its source and learn what that part of the spectrum is used for.

Features:

- Optional nearby Bluetooth Low Energy observation
- Bundled FM station and FCC allocation references
- Calculated GPS and Iridium satellite visibility using public orbital data
- Airport-based contextual signals
- Viridis and Magma visual themes
- Clear observed, nearby, and probable provenance labels
- No accounts, advertising, analytics, or tracking

Wavelength is a visualization and educational reference, not a calibrated spectrum analyzer or software-defined radio. It does not measure raw RF energy across the displayed range and must not be used for safety, navigation, aviation, or security decisions.

## Promotional text

`Explore Bluetooth observations, public frequency references, and calculated satellite visibility in one provenance-aware visualization.`

## URLs

- Support: https://github.com/saagpatel/Wavelength/issues
- Privacy: https://github.com/saagpatel/Wavelength/blob/main/PRIVACY.md

## App Review notes

Bluetooth and location are optional and requested from explicit buttons during onboarding. Bluetooth observations and location stay on-device. Wavelength downloads public satellite orbital elements from CelesTrak; that request does not include location.

The simulator includes debug-only example signals so reviewers can inspect the visualization without physical sensor data. A production build never labels those examples as observations because they are not included outside DEBUG builds.

No account, credential, entitlement-only Wi-Fi helper, cellular scanner, or in-app purchase is required.

## Release-owner checklist

- [ ] Confirm `com.waveylength.app` in Apple Developer and App Store Connect.
- [ ] Resolve provisioning, run a signed archive, and Validate App.
- [ ] Test Bluetooth allow/deny, location allow/deny, offline behavior, cache clearing, and rendering on physical devices.
- [ ] Confirm privacy nutrition labels against `PRIVACY.md` and actual behavior.
- [ ] Capture current required iPhone screenshots from a Release build using privacy-safe test data.
- [ ] Decide price, territories, categories, age-rating answers, copyright, and support ownership.
- [ ] Complete TestFlight review before submission.
