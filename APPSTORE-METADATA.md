# Wavelength App Store Connect Metadata Draft

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

`spectrum,radio,signals,Bluetooth,FM,FCC,frequency,science,education,visualizer`

## Description

Wavelength puts Bluetooth activity and radio reference data on a scrolling frequency visualization.

Explore FM station references and FCC frequency allocations. With permission, your iPhone can observe nearby Bluetooth Low Energy advertisements. Location helps select FM references and infer possible signals near airports and in selected US cities.

Features:

- GPU-rendered visualization with Viridis and Magma color maps
- Optional nearby Bluetooth Low Energy observation
- Bundled FM station and FCC allocation references
- Airport-based signal inferences
- Frequency, category, and educational details for selected signals
- No accounts, advertising, analytics, or tracking

Bluetooth observations stay in memory on your device. When location is allowed and the app is online, Wavelength sends coordinates to Apple's reverse-geocoding service to identify your city for probable 5G coverage. Public satellite orbital data is downloaded from CelesTrak without your location.

Reference entries and inferred signals do not confirm reception or physical presence. Wavelength does not measure raw RF energy across the displayed range. It is an educational reference and must not be used for safety, navigation, aviation, or security decisions.

## Promotional text

`Explore Bluetooth activity, FM station references, and FCC frequency allocations on a scrolling visualization. Learn what different frequencies are used for.`

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

Capture the current Release UI on a 6.9-inch iPhone at **1320x2868** in portrait. `TARGETED_DEVICE_FAMILY` is `1`, so an iPad capture is not required. If family `2` is added later, include a 13-inch iPad capture at **2064x2752**.

| Scene | Current UI and capture conditions | Caption |
|---|---|---|
| Frequency view | Main screen with frequency axis and bundled FCC allocation overlays. No sensor entries are required. | Explore frequency allocations |
| Display controls | "Settings" showing "Colormap" with "Viridis" and "Magma", and "Frequency Range". | Choose your color map and frequency range |
| Bluetooth details, if available | Physical iPhone with Bluetooth allowed and a real BLE advertisement. Tap at its frequency height and verify the selected detail sheet is Bluetooth before capture. Keep "Hide Bluetooth device names" on. Omit this scene if no observation is available. | Inspect Bluetooth activity |

Use unaltered Release screens. Do not insert DEBUG examples, provider attributions, satellite visibility claims, or captions claiming confirmed nearby signals. Reference entries and inferred strengths are not measurements.

## Release-owner checklist

- [ ] Confirm `com.waveylength.app` in Apple Developer and App Store Connect.
- [ ] Resolve provisioning, run a signed archive, and Validate App.
- [ ] Test Bluetooth allow/deny, location allow/deny, offline behavior, cache clearing, and rendering on physical devices.
- [ ] Follow the review path above on a physical Release build, including relaunch after granting location and frequency-based detail selection. Do not require local FM, airport, 5G, or satellite entries to appear.
- [ ] Confirm privacy nutrition labels against `PRIVACY.md`, Apple reverse geocoding, CelesTrak requests, and resolved dependency behavior.
- [ ] Capture the screenshot scenes above at 1320x2868 from a Release build. Use real BLE observations with names hidden for the optional Bluetooth scene; exclude DEBUG examples and unsupported confirmation or visibility captions.
- [ ] Decide price, territories, categories, age-rating answers, copyright, and support ownership.
- [ ] Complete TestFlight review before submission.
