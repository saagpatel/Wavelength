# Wavelength App Store Connect Metadata Draft

Confirm all values in App Store Connect before submission.

## Identity

| Field | Draft value |
|---|---|
| Name | Wavelength: RF Spectrum |
| Subtitle | A field guide to radio bands |
| Bundle ID | `com.waveylength.app` |
| SKU | `WAVELENGTH-001` |
| Primary category | Education |
| Secondary category | Utilities |
| Price | Decide before release |

## Keywords

`spectrum,radio,signals,Bluetooth,FM,FCC,frequency,science,education,visualizer,spectrogram,bands`

## Description

Wavelength draws a scrolling, spectrogram-style display of the radio spectrum: Bluetooth Low Energy activity your iPhone can observe, plus reference entries for FM stations and FCC frequency allocations, all on one frequency axis.

With permission, your iPhone picks up the Bluetooth Low Energy broadcasts around you. Allow location and Wavelength lists FM station references for your area, adds an ADS-B entry when you are within 2 km of a bundled airport, and marks probable 5G C-Band coverage when an online city lookup matches a selected US city.

Features:

- Scrolling display with Viridis and Magma color maps
- Optional nearby Bluetooth Low Energy observation
- Bundled FM station and FCC allocation references
- GPS and Iridium satellite references
- ADS-B and 5G entries based on where you are
- Tap near a signal's frequency for its category and a short note on what that band is used for
- No accounts, advertising, analytics, or tracking

With location allowed and an internet connection, Wavelength sends your coordinates to Apple to identify your city for 5G entries; Bluetooth observations stay in memory on your device. Satellite reference entries use public orbital data downloaded from CelesTrak; that request does not include your location.

Wavelength is a learning tool, not a spectrum analyzer. Reference and inferred entries do not confirm reception or physical presence, and Wavelength does not measure RF energy. Do not rely on it for safety, navigation, aviation, or security decisions.

## Promotional text

`A scrolling, spectrogram-style map of the radio spectrum: nearby Bluetooth activity, FM station references, and FCC band allocations, with notes on what each is for.`

## URLs

- Support: https://github.com/saagpatel/Wavelength/issues
- Privacy: https://github.com/saagpatel/Wavelength/blob/main/PRIVACY.md

## App Review notes

No account, credential, or in-app purchase is required. Bluetooth and location are optional.

1. On first launch, swipe left from the welcome page to "Permissions". Tap "Location" or "Bluetooth" to request the corresponding system permission, or leave both untouched. Swipe left to "Ready to explore" and tap "Get Started".
2. If you granted location, close and reopen the app after onboarding so it reads the updated authorization status and starts location updates. The first permission request can leave the app's stored status unchanged until relaunch.
3. The main screen shows the frequency axis and bundled FCC allocation overlays even without sensor data. Tap the gear icon at the top right to open "Settings". Under "Colormap", switch between "Viridis" and "Magma". "Frequency Range" changes the displayed range. "Hide Bluetooth device names" is on by default. "Show probable signals" controls inferred entries. Tap "Done" to return.
4. On a physical iPhone with Bluetooth allowed and enabled, nearby BLE advertisements can appear. With a location fix, FM references depend on coverage in the bundled database. "ADS-B" is inferred only within 2 km of a bundled airport. "5G C-Band" requires an online city lookup matching the app's US city list. Either inferred entry may be absent at your location.
5. If signals are present, tap the visualization at a signal's frequency height to open details with "Frequency", "Category", and "Provenance". Selection uses the nearest active signal within 200 MHz. Annotation text can be shifted to avoid overlap, so tapping its text may select a different signal or nothing. Details give a category explanation, not a provider attribution.

The "Live", "Nearby", and "Probable" labels are app categories. "Nearby" entries are references, not confirmation of reception or physical presence. FM and satellite signal strengths are reference values, not measurements. Satellite entries can come from an unfiltered cache and do not establish current visibility.

Release builds contain no example signals. A simulator review should use the frequency axis, allocation overlays, and Settings path above; do not expect live BLE observations. Location-dependent entries require a supplied simulator location or a physical device location fix. DEBUG builds inject example Bluetooth, Wi-Fi, and cellular entries labeled "Live" on both simulator and device; those examples are absent from the submitted Release build. Wavelength does not scan Wi-Fi or cellular signals.

Bluetooth observations remain in memory on-device. When location is allowed and the app is online, coordinates are sent to Apple's reverse-geocoding service to identify the city for probable 5G coverage. CelesTrak satellite-data requests do not include location. See `PRIVACY.md` for the same data boundaries.

## Screenshot plan

Run `scripts/capture-screenshots.sh` to capture the real app UI in deterministic **Debug-only** fixture states. For screenshot production, this numbered plan supersedes the older Release-only screenshot bullet in the Release-owner checklist below; physical Release acceptance remains separate. Each launch uses `-AppStoreScreenshot <n>`, skips onboarding and permissions, uses a fresh in-memory settings/cache database, and leaves sensing, contextual updates, and network monitoring stopped. The existing DEBUG mock provider supplies example signals with a fixed date (2024-01-01 UTC); Bluetooth names are hidden. The normal Metal amplitude builder and shader render a fixed, fully populated spectrogram history without scrolling.

The required device is **iPhone 18 Pro Max**, 6.9-inch, **1320x2868** portrait. `TARGETED_DEVICE_FAMILY` is `1`, so an iPad capture is not required. If family `2` is added later, add a 13-inch iPad capture at **2064x2752** to this plan and the script.

| n | Scene | Current UI and capture conditions | Device / pixel size | Capture status | Caption |
|---|---|---|---|---|---|
| 1 | Frequency view | Main screen with the full 70–6000 MHz frequency axis, bundled FCC allocation overlays, Viridis spectrogram, and existing DEBUG example signal annotations. | iPhone 18 Pro Max / 1320x2868 | Simulator-capturable | Explore frequency allocations |
| 2 | Display controls | The real Settings sheet, showing Colormap (Viridis selected, Magma available), Frequency Range (Full), and Hide Bluetooth device names enabled. Cache counts are zero and settings are reset on each launch. | iPhone 18 Pro Max / 1320x2868 | Simulator-capturable | Choose your color map and frequency range |
| 3 | Bluetooth details | The real signal detail sheet for the existing mock Bluetooth Headphones signal at 2441 MHz, with generic BLE 2.4 GHz sublabel and the same Live category the app uses for DEBUG fixtures. Selected directly to avoid frequency/annotation tap ambiguity. | iPhone 18 Pro Max / 1320x2868 | Simulator-capturable using existing mock data | Inspect Bluetooth activity |

All three scenes use existing synthetic signal data and unchanged production UI; none requires an OPERATOR capture on device. They are illustration fixtures, not proof of Bluetooth observation, Wi-Fi/cellular scanning, nearby reception, or satellite visibility. The Live label and hardware provenance text in scene 3 are the current UI for that DEBUG fixture, not evidence that hardware was used. Do not add provider attributions, invented camera imagery, or captions claiming confirmed nearby signals. Reference entries and inferred strengths are not measurements.

Outputs are ignored PNGs at `screenshots/appstore/iphone-18-pro-max/01.png` through `03.png`. The script builds once without signing, reads the built bundle ID, uses a 9:41 status bar and dark appearance, and verifies every PNG with `sips`. Default settling time is 4 seconds per scene; override with `SHOT_WAIT` or `SHOT_WAIT_1`, `SHOT_WAIT_2`, and `SHOT_WAIT_3` if needed. `DERIVED` overrides `.build/shots`. The script clears its status-bar overrides on exit and shuts down only simulators it booted. Review generated images before upload; parsing and shell checks do not verify simulator rendering.

## Release-owner checklist

- [ ] Confirm `com.waveylength.app` in Apple Developer and App Store Connect.
- [ ] Resolve provisioning, run a signed archive, and Validate App.
- [ ] Test Bluetooth allow/deny, location allow/deny, offline behavior, cache clearing, and rendering on physical devices.
- [ ] Follow the review path above on a physical Release build, including relaunch after granting location and frequency-based detail selection. Do not require local FM, airport, 5G, or satellite entries to appear.
- [ ] Confirm privacy nutrition labels against `PRIVACY.md`, Apple reverse geocoding, CelesTrak requests, and resolved dependency behavior.
- [ ] Capture the screenshot scenes above at 1320x2868 from a Release build. Use real BLE observations with names hidden for the optional Bluetooth scene; exclude DEBUG examples and unsupported confirmation or visibility captions.
- [ ] Decide price, territories, categories, age-rating answers, copyright, and support ownership.
- [ ] Complete TestFlight review before submission.
