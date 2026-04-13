# App Store Metadata — Wavelength

## Identity

| Field | Value |
|---|---|
| Name | Wavelength |
| Subtitle | See the Invisible RF World |
| Bundle ID | com.wavelength.app |
| SKU | WAVELENGTH-001 |
| Primary Category | Utilities |
| Secondary Category | Education |
| Age Rating | 4+ |
| Price | Free |
| Availability | All territories |

---

## Keywords

*(100 character limit — comma-separated)*

```
spectrum,RF,radio,electromagnetic,signals,Bluetooth,WiFi,cellular,satellite,FCC,scanner
```

Character count: 88

---

## Description

*(4,000 character limit)*

**Wavelength turns your iPhone into a window into the invisible electromagnetic world around you.**

The radio frequency spectrum is alive with signals — Bluetooth headphones, LTE towers, GPS satellites, FM broadcasts, aircraft transponders. Wavelength renders all of it in a real-time, GPU-accelerated spectrogram so you can see exactly what is transmitting, at what frequency, and why.

**Three tiers of signal intelligence**

Wavelength distinguishes what your device actually detects from what contextual data confirms is nearby:

- **Live** — signals sensed directly by your iPhone hardware: Bluetooth devices in range, your connected Wi-Fi access point, and your cellular carrier's active band
- **Nearby** — signals confirmed present at your GPS location via FCC databases, OpenCellID tower records, and live satellite position calculations
- **Probable** — signals inferred from context, such as ADS-B aircraft transponders near airports and 5G markers in dense urban areas

**Real-time Metal rendering**

The spectrogram runs on the GPU — a 1024-frequency-bin × 512-time-column texture rendered at 30 fps using a Viridis colormap optimized for OLED displays and colorblind users. A logarithmic frequency axis gives the FM broadcast band, GPS, Bluetooth, Wi-Fi 5 GHz, and 5G C-band each appropriate visual space.

**Annotated contextual overlay**

Every signal on screen is labeled. Tap any annotation to open a detail panel showing the carrier name, exact frequency, signal strength (when available), provenance explanation, and a plain-language description of what that signal is and why it exists.

**What you will find at any location**

- FM broadcast stations by call sign, city, and licensed frequency
- Cell towers from OpenCellID with operator and band information
- GPS, Iridium, and Starlink satellites currently overhead, updated from live TLE data
- FCC spectrum allocation bands color-coded by service type (broadcast, cellular, aviation)
- Bluetooth devices classified by type (headphones, smartwatch, beacon)

**Privacy by design**

Wavelength has no user accounts, no analytics, no advertising, and no backend. All contextual data is cached locally. Bluetooth device names are hidden by default. Location data is rounded to ~111 meters in all logs. The only outbound connections are to OpenCellID (cell tower lookup), CelesTrak (satellite orbital data), and the FCC FM station database — each cached for days to weeks. Open source under the MIT license.

**Who this is for**

RF engineers curious about what their hardware actually sees. IT and security professionals auditing wireless environments. Anyone who has ever wondered what "the spectrum" looks like in a coffee shop, an airport, or a dense urban block.

---

## Promotional Text

*(170 character limit — can be updated without a new app review)*

```
Now with Magma colormap option. See every Bluetooth, Wi-Fi, cellular, satellite, and FM signal around you — rendered live on your iPhone's GPU.
```

Character count: 143

---

## Support and Privacy URLs

| Field | URL |
|---|---|
| Support URL | https://github.com/saagpatel/Wavelength/issues |
| Marketing URL | https://github.com/saagpatel/Wavelength |
| Privacy Policy URL | https://github.com/saagpatel/Wavelength/blob/main/PRIVACY.md |

*Replace `[owner]` with the GitHub username before submission.*

---

## Screenshots Plan

### iPhone 6.9" (iPhone 16 Pro Max — 1320×2868 px) — 4 required

| # | Screen | Description | Key elements to show |
|---|---|---|---|
| 1 | Main spectrogram — populated urban environment | Full-screen spectrogram with Viridis colormap, at least 8 signal annotations visible across FM, cellular, and Bluetooth bands | Log-scale frequency axis on left; Live/Nearby/Probable color coding; annotation labels at FM 98.5 MHz, GPS 1575 MHz, Wi-Fi 2.4 GHz band |
| 2 | Signal detail panel — cell tower | Bottom sheet open on a tapped LTE tower signal | Tower operator name, band (e.g. "T-Mobile LTE Band 71"), exact frequency, signal strength in dBm, provenance line "Nearby — confirmed via OpenCellID at this location", educational blurb |
| 3 | Settings view | NavigationStack settings screen | Colormap picker (Viridis selected), frequency range preset, Privacy toggle, Cache stats row showing tower count and last-updated date, GitHub link |
| 4 | Outdoor environment — satellite pass | Spectrogram captured outdoors with GPS and Iridium satellites annotated as Nearby signals at 1575 MHz and 1621 MHz | At least 4 GPS Nearby signals visible; ADS-B Probable signal at 1090 MHz if near airport; clear sky condition implied by satellite density |

### iPad 13" (iPad Pro M4 — 2064×2752 px) — 4 required

| # | Screen | Description |
|---|---|---|
| 1 | Full landscape spectrogram | Wide layout with spectrogram filling most of the screen; sidebar showing Live/Nearby/Probable legend; frequency axis readable |
| 2 | Signal detail panel open | Same content as iPhone screenshot 2, adapted to iPad split-view style |
| 3 | Dense signal environment | Coffee shop or urban scene with 10+ annotations across all frequency tiers |
| 4 | FCC band tint overlay | Zoom to FM–cellular range showing color-coded FCC allocation bands (blue FM, green cellular, amber broadcast) visible beneath signal annotations |

---

## App Review Notes

**Test environment:** The app requires device hardware (Bluetooth, CoreTelephony, CoreLocation) for Live signals. The simulator will show contextual (Nearby/Probable) signals only; Live signals from cellular and Bluetooth will be absent. This is expected behavior.

**How to see signals:**

1. Grant location permission when prompted (required for contextual data)
2. Grant Bluetooth permission when prompted (required for Live BLE signals)
3. Contextual signals (Nearby/Probable) populate within 10–15 seconds of location fix on a physical device
4. Tap any signal annotation on the spectrogram to open the detail panel
5. Open Settings via the gear icon to toggle colormap or view cache statistics

**NEHotspotHelper:** The app requests the `com.apple.developer.networking.HotspotHelper` entitlement. If not provisioned, the app gracefully falls back to showing only the currently connected AP — there is no crash or error shown to the user.

**Network connections:** The app connects to three domains only: `opencellid.org` (cell tower lookup, API key in encrypted bundle), `celestrak.org` (satellite TLE data, no auth), and `transition.fcc.gov` (FM station data, no auth). All responses are cached. No analytics or crash-reporting SDKs are present.

**Privacy:** No user accounts are created. No data is transmitted to any developer-controlled server. See `PrivacyInfo.xcprivacy` for the full privacy manifest.

---

## Submission Checklist

### Metadata
- [ ] App name: "Wavelength" (confirm no trademark conflict in primary markets)
- [ ] Subtitle within 30 characters
- [ ] Keywords within 100 characters, no duplicate terms
- [ ] Description reviewed for App Store guideline compliance (no competitor mentions, no guarantee of signal detection accuracy)
- [ ] Promotional text within 170 characters
- [ ] Support URL live and resolves
- [ ] Privacy Policy URL live and covers location and Bluetooth data use

### Screenshots
- [ ] iPhone 6.9" — 4 screenshots at 1320×2868 px
- [ ] iPhone 6.1" — 4 screenshots at 1179×2556 px (or use 6.9" — accepted for this size)
- [ ] iPad 13" — 4 screenshots at 2064×2752 px
- [ ] No device frames unless captured with Xcode device bezel (App Store Connect accepts either)
- [ ] No screenshots show personal data (real device names, contact info, location precision better than city-level)

### Build
- [ ] `xcodebuild archive` succeeds on Release scheme, zero warnings
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) declares: Location (precise, while using), Bluetooth (nearby interactions), no tracking
- [ ] Entitlements file lists only required entitlements: Location, Bluetooth, NEHotspotHelper (if provisioned)
- [ ] `UIRequiredDeviceCapabilities` does NOT include `lidar-sensor` — Wavelength runs on all iPhones with iOS 17
- [ ] Version string and build number set in target settings
- [ ] App icon present in all required sizes (use Xcode asset catalog with single 1024×1024 source)

### App Store Connect
- [ ] Age rating questionnaire completed (4+)
- [ ] Export compliance: app uses standard HTTPS encryption only — answer "No" to proprietary encryption questions (AES-GCM for the OpenCellID API key is not an export-restricted algorithm)
- [ ] Category: Primary = Utilities, Secondary = Education
- [ ] Price: Free
- [ ] Availability: All territories (or configure as needed)
- [ ] TestFlight internal testing completed — 7+ days, 0 crashes, ≥8 signal annotations in each test environment (home, urban outdoor, coffee shop)

## Copyright
© 2026 saagpatel
