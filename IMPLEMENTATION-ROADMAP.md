# Wavelength — Implementation Roadmap

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────┐
│                    SwiftUI Layer                    │
│  SpectrogramView (Metal MTKView)                    │
│  FrequencyAxisView │ SignalDetailPanel              │
│  SettingsView      │ LegendView                    │
│  OnboardingView                                     │
└──────────────┬──────────────────────────────────────┘
               │ Observes (@Observable)
┌──────────────▼──────────────────────────────────────┐
│              SignalRegistry (@Observable)            │
│  [LiveSignal] + [NearbySignal] + [ProbableSignal]   │
└───┬──────────────┬───────────────────┬──────────────┘
    │              │                   │
┌───▼──────┐  ┌───▼──────────┐  ┌────▼─────────────┐
│  Sensing │  │  Contextual  │  │   Metal Renderer  │
│  Engine  │  │  Data Engine │  │   (GPU Pipeline)  │
│  (Actor) │  │  (Actor)     │  │                   │
├──────────┤  ├──────────────┤  ├──────────────────┤
│CoreBT    │  │FCC SQLite DB │  │MTLDevice          │
│NEHotspot │  │OpenCellID API│  │MTLTexture 1024×512│
│CoreTeleph│  │CelesTrak TLE │  │RGBA16F circular   │
│CoreLocatn│  │FM Station API│  │buffer             │
└──────────┘  └──────┬───────┘  │Compute Shader     │
                     │          │(viridis colormap) │
              ┌──────▼───────┐  └──────────────────┘
              │  GRDB SQLite │
              │  (local only)│
              └──────────────┘
```

### File Structure

```
Wavelength/
├── Wavelength.xcodeproj
├── Wavelength/
│   ├── App/
│   │   ├── WavelengthApp.swift          # @main, scene lifecycle
│   │   └── AppDelegate.swift            # Background task registration
│   ├── Core/
│   │   ├── SignalRegistry.swift         # @Observable central signal store
│   │   ├── Signal.swift                 # Signal struct + provenance/category enums
│   │   └── FrequencyBand.swift          # Band model + log-scale position math
│   ├── Sensing/
│   │   ├── SensingEngine.swift          # Actor coordinating all live sensors
│   │   ├── BluetoothScanner.swift       # CoreBluetooth → BLEDevice emissions
│   │   ├── WiFiScanner.swift            # NEHotspotHelper + NEHotspotNetwork fallback
│   │   ├── CellularMonitor.swift        # CoreTelephony → band frequency lookup
│   │   └── LocationMonitor.swift        # CoreLocation + 500m geofence trigger
│   ├── Contextual/
│   │   ├── ContextualEngine.swift       # Actor coordinating DB + API services
│   │   ├── FCCDatabase.swift            # Query bundled fcc_spectrum.sqlite
│   │   ├── CellTowerService.swift       # OpenCellID API + GRDB cache
│   │   ├── SatelliteService.swift       # CelesTrak TLE fetch + SGP4 propagation
│   │   └── FMStationService.swift       # FCC FM lookup API + GRDB cache
│   ├── Metal/
│   │   ├── SpectrogramRenderer.swift    # MTKViewDelegate, manages GPU pipeline
│   │   ├── SpectrogramTexture.swift     # Circular buffer texture manager
│   │   ├── Shaders.metal                # Compute shader (viridis colormap mapping)
│   │   └── AnnotationOverlay.swift      # CALayer overlay for signal labels
│   ├── UI/
│   │   ├── SpectrogramView.swift        # MTKView wrapped in UIViewRepresentable
│   │   ├── FrequencyAxisView.swift      # Log-scale Y-axis with landmark labels
│   │   ├── SignalDetailPanel.swift      # Bottom sheet on signal tap
│   │   ├── LegendView.swift             # Live/Nearby/Probable three-tier legend
│   │   ├── SettingsView.swift           # Colormap, range, privacy, cache controls
│   │   └── OnboardingView.swift         # First-launch 3-screen permission flow
│   ├── Database/
│   │   ├── DatabaseManager.swift        # GRDB setup + migration runner
│   │   └── Migrations/
│   │       ├── Migration001_schema.swift   # All runtime tables
│   │       └── Migration002_fcc_index.swift
│   ├── Models/
│   │   └── Types.swift                  # All shared structs, enums, type aliases
│   └── Resources/
│       ├── fcc_spectrum.sqlite          # Bundled, pre-processed FCC data (~8MB)
│       ├── itu_regions.json             # Static ITU band allocations (non-US)
│       └── airports.json               # ~500 airports for ADS-B Probable inference
├── scripts/
│   └── build_fcc_db.py                  # One-time FCC data processor (not in app)
├── WavelengthTests/
│   ├── FrequencyBandTests.swift
│   ├── FCCDatabaseTests.swift
│   ├── TLEParsingTests.swift
│   ├── SignalRegistryTests.swift
│   └── CellTowerCacheTests.swift
└── README.md
```

### Data Model

```sql
-- Runtime cache: cell tower data from OpenCellID
CREATE TABLE cell_towers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    mcc INTEGER NOT NULL,
    mnc INTEGER NOT NULL,
    lac INTEGER NOT NULL,
    cell_id INTEGER NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    frequency_mhz REAL NOT NULL,
    band_name TEXT NOT NULL,
    operator_name TEXT,
    signal_dbm INTEGER,
    fetched_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(mcc, mnc, lac, cell_id)
);
CREATE INDEX idx_towers_location ON cell_towers(latitude, longitude);
CREATE INDEX idx_towers_fetched ON cell_towers(fetched_at);

-- Runtime cache: TLE data for satellite position computation
CREATE TABLE satellite_tles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    norad_id INTEGER NOT NULL UNIQUE,
    line1 TEXT NOT NULL,
    line2 TEXT NOT NULL,
    frequency_mhz REAL NOT NULL,
    constellation TEXT NOT NULL,    -- GPS, IRIDIUM, STARLINK
    fetched_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Runtime cache: FM broadcast stations by location
CREATE TABLE fm_stations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    call_sign TEXT NOT NULL,
    frequency_mhz REAL NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    erp_watts INTEGER,
    city TEXT,
    fetched_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_fm_location ON fm_stations(latitude, longitude);

-- Bundled read-only: FCC spectrum allocations (populated by build_fcc_db.py)
CREATE TABLE fcc_allocations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    freq_low_mhz REAL NOT NULL,
    freq_high_mhz REAL NOT NULL,
    service_name TEXT NOT NULL,
    allocation_type TEXT NOT NULL,  -- PRIMARY, SECONDARY
    itu_region TEXT,
    notes TEXT
);
CREATE INDEX idx_alloc_freq ON fcc_allocations(freq_low_mhz, freq_high_mhz);

-- User settings (single-row enforced)
CREATE TABLE settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    colormap TEXT NOT NULL DEFAULT 'viridis',
    freq_low_mhz REAL NOT NULL DEFAULT 70.0,
    freq_high_mhz REAL NOT NULL DEFAULT 6000.0,
    show_probable INTEGER NOT NULL DEFAULT 1,
    privacy_mode INTEGER NOT NULL DEFAULT 1,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Rolling 24h signal log (for EM walk feature, v2)
CREATE TABLE signal_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    signal_id TEXT NOT NULL,        -- SHA256(uuid + app_salt) — never raw UUID
    provenance TEXT NOT NULL,       -- LIVE, NEARBY, PROBABLE
    frequency_mhz REAL NOT NULL,
    signal_dbm REAL,
    latitude REAL,                  -- Rounded to 3 decimal places (~111m)
    longitude REAL,
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_history_time ON signal_history(recorded_at);
CREATE INDEX idx_history_signal ON signal_history(signal_id, recorded_at);
```

### Type Definitions (Swift)

```swift
// Core/Signal.swift

enum SignalProvenance: String, Codable, Sendable {
    case live       // Actively sensed by device hardware
    case nearby     // Confirmed present via database + GPS anchor
    case probable   // Inferred from location context heuristics
}

enum SignalCategory: String, Codable, Sendable {
    case bluetooth, wifi, cellular, fm, gps, satellite, broadcast, emergency
}

struct Signal: Identifiable, Sendable {
    let id: String
    let category: SignalCategory
    let provenance: SignalProvenance
    let frequencyMHz: Double
    let bandwidthMHz: Double?       // nil = point source on spectrogram
    let signalDBM: Double?          // nil for contextual/probable
    let label: String               // "T-Mobile LTE Band 71"
    let sublabel: String?           // "707 MHz downlink"
    let lastUpdated: Date
    var isActive: Bool              // Live signals expire after 30s without update
}

// Core/FrequencyBand.swift

struct FrequencyBand: Sendable {
    let lowMHz: Double
    let highMHz: Double
    let name: String
    let allocationSource: String    // "FCC", "ITU", "Inferred"

    /// Convert center frequency to log-scale Y position [0.0, 1.0]
    func logPosition(in range: ClosedRange<Double>) -> Double {
        let logLow = log10(range.lowerBound)
        let logHigh = log10(range.upperBound)
        let logCenter = log10((lowMHz + highMHz) / 2.0)
        return (logCenter - logLow) / (logHigh - logLow)
    }
}

// Sensing output types (Models/Types.swift)

struct BLEDevice: Sendable {
    let uuid: UUID
    let rssi: Int                   // dBm
    let deviceType: String          // "Headphones", "Watch", "Beacon", "Unknown"
    let advertisedName: String?     // nil when privacy_mode = true
}

struct WiFiNetwork: Sendable {
    let ssid: String
    let bssid: String
    let rssi: Int                   // dBm
    let channelMHz: Double
    let band: WiFiBand
}

enum WiFiBand: Sendable { case band24, band5, band6 }

struct CellularInfo: Sendable {
    let carrier: String
    let radioTech: String           // "LTE", "NR", "HSPA"
    let bandName: String?
    let frequencyMHz: Double?
}
```

### External API Contracts

| Service | Endpoint | Method | Auth | Rate Limit | Cache TTL |
|---|---|---|---|---|---|
| OpenCellID | `https://opencellid.org/cell/get?mcc={mcc}&mnc={mnc}&lac={lac}&cellid={cellid}&format=json` | GET | `?key=` query param | 1,000/day | 7 days |
| CelesTrak GPS | `https://celestrak.org/SOCRATES/query.php?GROUP=gps-ops&FORMAT=TLE` | GET | None | 1/day polite | 24 hours |
| CelesTrak Iridium | `https://celestrak.org/SOCRATES/query.php?GROUP=iridium&FORMAT=TLE` | GET | None | 1/day polite | 24 hours |
| FCC FM Query | `https://transition.fcc.gov/fcc-bin/fmq?state=0&call=&city=&freq={low}&fre2={high}&type=2&status=A&format=2` | GET | None | No limit documented | 30 days |

**OpenCellID response shape:**
```json
{
  "lat": 37.7749,
  "lon": -122.4194,
  "mcc": 310,
  "mnc": 260,
  "lac": 12345,
  "cellid": 67890,
  "averageSignalStrength": -85,
  "range": 500,
  "status": "ok"
}
```

### Dependencies

```bash
# All via Swift Package Manager (Xcode → File → Add Package Dependencies)

# GRDB.swift — SQLite ORM
# URL: https://github.com/groue/GRDB.swift
# Version: Up to Next Major from 6.0.0

# Alamofire — HTTP networking
# URL: https://github.com/Alamofire/Alamofire
# Version: Up to Next Major from 5.9.0

# SwiftyTLE — TLE parsing + SGP4 propagator
# URL: https://github.com/SatelliteKit/SwiftyTLE
# Version: Up to Next Major from latest
# NOTE: Verify maintained status in Phase 0 Week 1.
#       If abandoned, implement SGP4 from Vallado reference (MIT, ~400 lines C → bridged)
```

---

## Scope Boundaries

**In scope (v1):**
- Spectrogram rendering via Metal GPU pipeline (30fps, 1024×512 texture)
- Live sensing: Bluetooth LE, Wi-Fi (NEHotspotHelper + fallback), Cellular band
- Contextual overlay: FCC allocations, OpenCellID towers, FCC FM stations, GPS/Iridium satellites
- Probable inference: airports (ADS-B), dense urban (5G marker)
- Signal detail panel with educational content
- Three-tier provenance visualization (Live/Nearby/Probable)
- Settings: colormap, frequency range, privacy mode, cache management
- Full offline mode with cached contextual data
- App Store distribution + GitHub open source (MIT)

**Out of scope (never in v1):**
- RTL-SDR hardware integration
- mmWave (28 GHz+) spectrum
- Real-time spectrum analysis (hardware limitation — iOS black-box RF)
- User accounts, cloud sync, analytics
- Gamification, badges, social features
- Non-US regulatory databases (ITU static overlay only)

**Deferred (v2+):**
- Historical EM recording + playback ("EM walk")
- AR overlay (signal sources in camera view)
- RTL-SDR USB-C dongle support
- Signal education mode (in-app explainers per band)
- Magma colormap (ships in v1 settings, visual polish is v2)
- Per-country FCC equivalents

---

## Security & Credentials

- **OpenCellID API key:** Stored as CryptoKit AES-GCM encrypted string in app bundle. Key material derived from `bundleIdentifier + UIDevice.current.identifierForVendor` using HKDF. Never in source code, never in `.env`. Document setup in README as: "Generate key at opencellid.org → add to Config.xcconfig (gitignored) → build script encrypts at compile time."
- **Data leaving device:** OpenCellID receives MCC/MNC/LAC/CellID + GPS coords rounded to 2 decimal places (~1km). CelesTrak receives nothing (pure GET). FCC receives frequency range only. No user-identifiable data transmitted anywhere.
- **Bluetooth privacy:** CoreBluetooth UUIDs are iOS-randomized per-app (not real MACs). Signal history stores `SHA256(uuid + appSalt)` only — never raw UUID. Advertised device names hidden by default (privacy_mode = 1).
- **Location:** `signal_history.latitude/longitude` rounded to 3 decimal places (~111m precision). Background location used only for 500m geofence trigger — not continuous logging.
- **Charles proxy test (Phase 3):** Verify zero outbound connections except to opencellid.org, celestrak.org, transition.fcc.gov.

---

## Phase 0: Foundation (Weeks 1–2)

**Objective:** Xcode project configured with all dependencies and entitlements. SQLite schema running. All external API integrations verified. Bundled FCC database built. NEHotspotHelper application submitted.

**Tasks:**

1. Create Xcode project: iOS 17+ target, Swift 6 language mode, SwiftUI lifecycle, bundle ID `com.yourname.wavelength`. Add SPM packages: GRDB.swift, Alamofire, SwiftyTLE. **Acceptance:** `xcodebuild build -scheme Wavelength` → 0 errors, 0 warnings under Swift 6 strict concurrency.

2. Configure `Wavelength.entitlements` with `com.apple.developer.networking.HotspotHelper`. Write and submit entitlement justification letter to Apple Developer portal (frame as "network environment awareness tool for IT/security professionals"). **Acceptance:** Confirmation email from Apple received; entitlement request visible in developer portal.

3. Implement `DatabaseManager.swift` using GRDB with migration runner. Implement `Migration001_schema.swift` creating all 6 tables with exact schema from this document. **Acceptance:** `sqlite3 ~/Library/Developer/CoreSimulator/.../Documents/wavelength.db .schema` → all 6 tables present with correct columns and indexes.

4. Write `scripts/build_fcc_db.py` (Python 3, not in iOS app): download FCC ULS database → filter to FM broadcast (88–108 MHz), TV broadcast (54–698 MHz), cellular band allocations (600 MHz–6 GHz) → insert into `fcc_spectrum.sqlite` → add file to Xcode bundle target. **Acceptance:** Resulting `fcc_spectrum.sqlite` is ≤10MB; `SELECT COUNT(*) FROM fcc_allocations` returns ≥500; `SELECT * FROM fcc_allocations WHERE freq_low_mhz <= 98.1 AND freq_high_mhz >= 98.1` returns at least one FM row.

5. Verify OpenCellID integration: hardcode MCC=310, MNC=260, LAC=12345, CellID=67890 (or any valid T-Mobile Bay Area tower from opencellid.org explorer) → call API via Alamofire → parse JSON → log lat/lon. **Acceptance:** Logged coordinates within 2km of the tower's known position.

6. Verify CelesTrak TLE integration: fetch GPS TLE set → parse with SwiftyTLE → compute position of first satellite for `Date.now` → log altitude. **Acceptance:** Computed altitude is between 19,000 km and 21,000 km (GPS orbital shell). If SwiftyTLE is unmaintained, flag and implement Vallado SGP4 instead.

7. Implement `LocationMonitor.swift` with `CLLocationManager`, requesting `whenInUse` authorization (upgrade to `always` in Phase 3 for background geofence). Implement 500m significant-change trigger using `startMonitoringSignificantLocationChanges()`. **Acceptance:** Simulator location changed by >500m → `LocationMonitor` publishes new coordinate within 5 seconds.

**Verification checklist:**
- [ ] `xcodebuild build -scheme Wavelength` → 0 errors, 0 warnings
- [ ] NEHotspotHelper entitlement request submitted and confirmed
- [ ] `SELECT COUNT(*) FROM fcc_allocations` → ≥500
- [ ] OpenCellID API response logs valid lat/lon
- [ ] CelesTrak TLE parse logs altitude 19,000–21,000 km
- [ ] LocationMonitor logs coordinate update on simulated location change

**Risks:**
- SwiftyTLE unmaintained → Audit in Week 1; implement Vallado SGP4 if needed (allocate 4h)
- NEHotspotHelper rejected → Build NEHotspotNetwork fallback in Phase 1 (plan assumes this anyway)
- FCC database >10MB → Filter more aggressively (US only, remove TV allocations, use on-demand resources API)

---

## Phase 1: Core Spectrogram + Live Sensing (Weeks 3–5)

**Objective:** Metal spectrogram renders at ≥30fps with live Bluetooth, Wi-Fi, and cellular signals appearing as annotated bands. `SignalRegistry` is the single source of truth. Three provenance tiers visually distinct.

**Tasks:**

1. Implement `Signal.swift` and `SignalRegistry.swift` as `@Observable`. Registry holds `liveSignals: [Signal]`, `nearbySignals: [Signal]`, `probableSignals: [Signal]`. Computed var `allSignals` returns all three arrays merged and sorted by `frequencyMHz`. **Acceptance:** Unit test in `SignalRegistryTests.swift`: add 3 signals of each provenance → `allSignals.count == 9`, sorted ascending by frequency.

2. Implement Metal compute shader in `Shaders.metal`. Shader takes a `float` buffer (1024 dBm values mapped to [0,1]) and writes one column of viridis-mapped RGBA16F values into a 1024×512 `MTLTexture`. Viridis colormap hardcoded as 256-entry LUT in the shader. **Acceptance:** Pass uniform input of 0.5 (mid-range signal) → output texture column is all blue-green (viridis midpoint ~RGB 33,145,140).

3. Implement `SpectrogramTexture.swift`. Wraps a 1024×512 `MTLTexture` as a circular column buffer. `advanceColumn(data: [Float])` writes one column at `writeIndex % 512` then increments `writeIndex`. **Acceptance:** Call `advanceColumn` 600 times → `writeIndex == 600`; read the texture → oldest 88 columns are overwritten; Instruments Allocations → texture memory flat at ~2MB, no growth.

4. Implement `SpectrogramRenderer.swift` as `MTKViewDelegate`. On each 30fps `draw(in:)` call: read `SignalRegistry.allSignals` → build 1024-element `[Float]` dBm array mapped to log-scale frequency bins → call `SpectrogramTexture.advanceColumn` → blit texture to drawable. **Acceptance:** On physical iPhone: Xcode Metal debugger → frame time ≤33ms; GPU utilization ≤40% over 60s.

5. Implement `SpectrogramView.swift` — `UIViewRepresentable` wrapping `MTKView`. Attach `SpectrogramRenderer` as delegate. Size to full screen. Overlay `FrequencyAxisView` and `LegendView` using SwiftUI ZStack. **Acceptance:** Simulator launch → dark background with scrolling texture visible; log-scale axis labels render at correct positions.

6. Implement `BluetoothScanner.swift`. `CBCentralManager` scan with `CBCentralManagerScanOptionAllowDuplicatesKey: false`. For each discovered peripheral: classify device type from service UUIDs (0x1108=headphones, 0x1805=health/watch, 0xFEAA=Eddystone beacon, 0x180F=BLE generic). Map RSSI to Signal at BLE center frequency 2441 MHz (midpoint of 2402–2480 MHz band), bandwidth 78 MHz. Emit to `SignalRegistry.liveSignals`. **Acceptance:** AirPods + Apple Watch in room → both appear as distinct Live signals in 2.4 GHz band within 15s of scan start.

7. Implement `CellularMonitor.swift`. Use `CTTelephonyNetworkInfo.serviceCurrentRadioAccessTechnology` to get radio tech string. Map to frequency using hardcoded lookup (20 most common US bands — see Appendix). Emit single `Signal` to `SignalRegistry.liveSignals`. **Acceptance:** On physical device on LTE → a Live signal appears in 700–2100 MHz range matching the known band for the carrier.

8. Implement `WiFiScanner.swift` — Phase 1 path is `NEHotspotNetwork` only (connected AP). `NEHotspotNetwork.fetchCurrent` → map channel to frequency (ch1=2412, ch6=2437, ch11=2462, ch36=5180, ch149=5745, ch1=5955 for 6GHz). Emit to `SignalRegistry.liveSignals`. **Acceptance:** Connected to a 5GHz AP → Live signal appears in 5150–5850 MHz range.

9. Implement `FrequencyAxisView.swift`. Draw Y-axis labels at: 88 MHz (FM), 433 MHz (ISM), 700 MHz (Cell low), 1.5 GHz (GPS), 2.4 GHz (BT/WiFi), 5 GHz (WiFi 5), 6 GHz (WiFi 6E). Position each label using `FrequencyBand.logPosition(in: 70...6000)`. **Acceptance:** Visual inspection on iPhone 15 — FM label at bottom ~20%, 2.4 GHz label at ~80%, spacing proportional.

10. Implement `LegendView.swift` — three rows: Live (filled circle, full opacity), Nearby (filled circle, 50% opacity), Probable (hollow circle). One-line description each. **Acceptance:** Visual inspection — legible at Dynamic Type "Large" size.

**Verification checklist:**
- [ ] `SignalRegistryTests`: 9 signals across 3 tiers → `allSignals.count == 9`, sorted by frequency
- [ ] Metal: sustained 30fps on physical iPhone (Instruments GPU track)
- [ ] BT scan: AirPod and Watch appear as distinct Live signals within 15s
- [ ] Cellular: Live signal in correct band (verify carrier band chart)
- [ ] Wi-Fi: Live signal at correct 5GHz channel frequency (±20 MHz)
- [ ] Log-scale axis: FM label at ~20% height, Wi-Fi 5 label at ~85% height

---

## Phase 2: Contextual Overlay (Weeks 6–8)

**Objective:** FCC band shading, OpenCellID towers, FCC FM stations, and GPS/Iridium satellites all rendering as Nearby/Probable signals. Signal detail panel functional. Location-triggered refresh working.

**Tasks:**

1. Implement `FCCDatabase.swift`. Query bundled `fcc_spectrum.sqlite` for allocations where `freq_low_mhz <= viewMax AND freq_high_mhz >= viewMin`. Return as `[FrequencyBand]`. Render as semi-transparent CALayer background rectangles on spectrogram (separate from Metal texture — UIKit overlay). Use distinct colors per allocation type (FM=blue tint, cellular=green tint, broadcast=amber tint). **Acceptance:** Visual inspection — FM band (88–108 MHz) shows distinct background tint; cellular bands (700–2100 MHz) show different tint.

2. Implement `CellTowerService.swift`. On location fix from `LocationMonitor`: check `cell_towers` table for towers within 5km with `fetched_at > now - 7days`. If cache miss: call OpenCellID API for serving cell MCC/MNC/LAC/CellID → parse → insert/update `cell_towers`. Emit each tower as `Signal(provenance: .nearby)` at its `frequency_mhz`. **Acceptance:** First launch with GPS fix → ≥1 row in `cell_towers` table → at least 1 Nearby signal in cellular band on spectrogram.

3. Implement `SatelliteService.swift`. Fetch TLEs from CelesTrak if `fetched_at` is nil or >24h ago. Store in `satellite_tles`. Every 30 seconds: for each satellite with `elevation > 10°` (computed via SGP4 from current location + timestamp) → emit `Signal(provenance: .nearby)` at `frequency_mhz`. GPS at 1575.42 MHz, Iridium at 1621 MHz. **Acceptance:** Outdoors, clear sky → `SELECT COUNT(*) FROM satellite_tles WHERE constellation = 'GPS'` returns ≥24; ≥4 GPS Nearby signals appear at 1575.42 MHz.

4. Implement `FMStationService.swift`. Call FCC FM query API for stations within ±2 MHz of each 0.2 MHz step from 88–108 MHz, anchored to current GPS coordinates. Cache results in `fm_stations` with 30-day TTL. Emit each station as `Signal(provenance: .nearby)` at exact licensed frequency. **Acceptance:** In US urban area → ≥5 FM station Nearby signals appear in 88–108 MHz band; call signs visible in annotation overlay.

5. Implement `ContextualEngine.swift` as an actor. Subscribes to `LocationMonitor`'s 500m geofence publisher. On trigger: fire all four services in sequence (FCC is sync/local → runs first; towers → FM → satellites). Manages service call ordering and error recovery. **Acceptance:** Simulate location move >500m → all four services fire within 10 seconds → new signals appear on spectrogram.

6. Implement Probable signal inference in `ContextualEngine.swift`. Load `airports.json` bundle at init. On location update: if within 2km of any airport entry → emit `Signal(provenance: .probable)` at 1090 MHz (ADS-B), label "Aircraft transponders (ADS-B)". If `CLGeocoder` returns locality with population >250,000 → emit Probable 5G marker capped at 6 GHz boundary. **Acceptance:** Set simulator location to SFO coordinates → ADS-B Probable signal appears at 1090 MHz within 30s.

7. Implement `SignalDetailPanel.swift` as a SwiftUI `.sheet` (half-height detent). Trigger: tap gesture on spectrogram → hit-test annotation layer → find nearest signal within 20px → open panel. Panel shows: signal label, exact frequency, provenance explanation string ("Nearby — confirmed via OpenCellID database at this location"), operator/station info, signal strength if known, 2-sentence educational blurb per `SignalCategory`. **Acceptance:** Tap on FM station signal → panel shows call sign, frequency to 1 decimal place, city, ERP wattage, educational blurb.

8. Implement `AnnotationOverlay.swift` — `CALayer` overlay on top of Metal view. Draws signal labels as text at correct log-scale Y positions. Updates at 1fps (not 30fps). Label text: short label on the band line, truncated to 14 characters. Full label in detail panel only. **Acceptance:** ≥3 annotations visible simultaneously with no text overlap on iPhone 15 display.

**Verification checklist:**
- [ ] FCC band tints visible on spectrogram (visual, 3 distinct colors)
- [ ] `cell_towers`: ≥1 row after GPS fix, ≥1 Nearby signal in cellular band
- [ ] `satellite_tles`: ≥24 GPS rows, ≥4 Nearby signals at 1575.42 MHz outdoors
- [ ] `fm_stations`: ≥5 rows in US city, ≥5 Nearby signals in FM band
- [ ] Location move >500m → all services refresh within 10s
- [ ] SFO simulator location → ADS-B Probable signal at 1090 MHz
- [ ] Signal tap → detail panel shows correct data for that signal type

---

## Phase 3: NEHotspotHelper + Polish + App Store (Weeks 9–10)

**Objective:** NEHotspotHelper live (or graceful fallback confirmed), offline mode fully functional, settings complete, App Store submission ready.

**Tasks:**

1. Integrate NEHotspotHelper in `WiFiScanner.swift`. Add `NEHotspotHelper.register` handler. On `.filterPackets` / network-join events: enumerate visible networks via `NEHotspotHelper.supportedNetworkInterfaces()` → for each: map channel → frequency → emit Live signal. Gate behind `NEHotspotHelperCommand` availability check — if entitlement not granted, log and continue with `NEHotspotNetwork` fallback. **Acceptance (granted):** In location with 10+ visible networks → all appear as Live signals. **Acceptance (not granted):** App launches without crash, 1 connected-AP signal appears, no error shown to user.

2. Implement offline mode. On app launch: check `NWPathMonitor` for network reachability. If offline: load all cached contextual data from GRDB ignoring TTL → populate `SignalRegistry.nearbySignals`. Show `Text("Offline — using cached data from \(formattedDate)")` banner in amber below legend. **Acceptance:** Enable airplane mode + re-enable BT → launch → contextual signals appear from cache; amber banner visible; BT Live signals still appear.

3. Implement `SettingsView.swift` with NavigationStack. Sections: Display (colormap picker: viridis/magma, frequency range preset picker: Full/Broadcast/Mobile), Privacy (toggle: hide BT device names), Signals (toggle: show Probable signals), Cache (text: "Cell towers: 24 towers, last updated X days ago" + Clear Cache button), About (version string + GitHub link via `Link`). **Acceptance:** Toggle viridis→magma → spectrogram colormap updates within 1 render frame; Clear Cache → `cell_towers` + `fm_stations` + `satellite_tles` truncated; app functions normally after clear.

4. Implement `OnboardingView.swift`. Three pages via `TabView(.page)`: (1) Title "Wavelength" + subtitle "See the invisible electromagnetic world" + three-tier provenance diagram; (2) Permission request page — Location (button triggers `CLLocationManager.requestWhenInUseAuthorization()`) + Bluetooth (button triggers `CBCentralManager` init which triggers system prompt); (3) Legend explainer with Live/Nearby/Probable icons. Store `hasSeenOnboarding: Bool` in settings table. **Acceptance:** Fresh install (reset simulator) → onboarding appears; grant both permissions → spectrogram visible within 5 seconds of dismissing onboarding.

5. Privacy audit. Verify with Charles Proxy on same Wi-Fi: (a) launch app cold → observe all outbound connections; (b) expected: opencellid.org (1 call), celestrak.org (1-2 calls), transition.fcc.gov (async); (c) zero calls to any analytics, crash reporting, or ad network domains. Also verify: `signal_history` contains no raw BT UUIDs (check with sqlite3 CLI). **Acceptance:** Charles shows exactly 3 domains in outbound traffic; `signal_history.signal_id` column values are all 64-char hex strings (SHA256 output).

6. Build App Store metadata. Write app description (educational/awareness framing, IT/security professional angle, no spectrum analyzer claims). Create 3 screenshots at 6.9" (iPhone 16 Pro Max): (a) populated spectrogram with FM + cellular + BT signals annotated; (b) signal detail panel open on a cell tower; (c) settings view. Write Privacy Nutrition Label: Location (precise, while using), Bluetooth (nearby interactions). **Acceptance:** `fastlane deliver --metadata_path ./metadata` dry-run → 0 validation errors.

7. TestFlight internal beta: install on physical device. Use for 7 days across ≥3 environments (home, coffee shop, outdoor urban). Log all issues with severity. Fix all P1 (crashes, blank spectrogram) before submission. **Acceptance:** 0 crashes across 7 days; ≥8 signal annotations visible in each test location.

8. App Store submission via Xcode Organizer or `fastlane deliver`. **Acceptance:** Passes App Review (typically 24–72h for utility apps).

**Verification checklist:**
- [ ] NEHotspotHelper path OR graceful fallback — both tested explicitly
- [ ] Airplane mode + BT on → contextual signals load from cache, amber banner shown
- [ ] Settings: colormap toggle changes spectrogram within 1 frame
- [ ] Clear Cache → GRDB tables empty, app functions normally
- [ ] Charles proxy: exactly 3 outbound domains, zero analytics/ads
- [ ] `signal_history.signal_id` values are SHA256 hex strings
- [ ] TestFlight: 7 days, 0 crashes, ≥8 annotations in each environment

---

## Appendix A: US Cellular Band Frequency Lookup Table

```swift
// CellularMonitor.swift — map CTRadioAccessTechnology strings to frequency
let bandFrequencyMap: [String: Double] = [
    CTRadioAccessTechnologyLTE: 700.0,       // Generic LTE fallback
    CTRadioAccessTechnologyNR: 2500.0,       // Generic 5G NR fallback
    CTRadioAccessTechnologyHSDPA: 1900.0,
    CTRadioAccessTechnologyEdge: 850.0,
    CTRadioAccessTechnologyGPRS: 850.0,
]

// For precise band, use CTCarrier + bandwidthParts from CoreTelephony (iOS 16+)
// Band 71 (T-Mobile 600MHz): 617–652 MHz uplink, 663–698 MHz downlink
// Band 12 (AT&T/T-Mobile 700MHz): 699–716 MHz uplink, 729–746 MHz downlink
// Band 13 (Verizon 700C): 777–787 MHz uplink, 746–756 MHz downlink
// Band 17 (AT&T 700b): 704–716 MHz uplink, 734–746 MHz downlink
// Band 4/66 (AWS): 1710–1755 MHz uplink, 2110–2155 MHz downlink
// Band 25 (Sprint PCS): 1850–1915 MHz uplink, 1930–1995 MHz downlink
// Band 41 (T-Mobile mid): 2496–2690 MHz (TDD)
// Band n77 (5G C-band): 3300–4200 MHz (TDD)
// Band n78 (5G C-band): 3300–3800 MHz (TDD)
// Band n260 (5G mmWave): 37000–40000 MHz — out of scope v1
```

## Appendix B: Key Frequency Landmarks for Annotation Layer

| Frequency | Signal | Label |
|---|---|---|
| 88–108 MHz | FM Broadcast | FM Radio (per-station call signs) |
| 121.5 MHz | Aviation Emergency | Aviation ELT |
| 162.4–162.55 MHz | NOAA Weather Radio | NOAA Weather |
| 406 MHz | Emergency Beacons | EPIRB / PLB |
| 433.92 MHz | ISM / IoT | Smart Home (433 MHz) |
| 700–900 MHz | Cellular low-band | LTE / 5G Low Band |
| 1090 MHz | ADS-B | Aircraft Transponders |
| 1575.42 MHz | GPS L1 | GPS Satellites |
| 1616–1626.5 MHz | Iridium | Iridium Satellites |
| 1710–2155 MHz | Cellular mid-band | LTE AWS / PCS |
| 2400–2480 MHz | BT + Wi-Fi 2.4 | Bluetooth + Wi-Fi 2.4 GHz |
| 2496–2690 MHz | Cellular Band 41 | 5G Mid-Band |
| 3300–4200 MHz | Cellular n77/n78 | 5G C-Band |
| 5150–5850 MHz | Wi-Fi 5 GHz | Wi-Fi 5 GHz |
| 5925–7125 MHz | Wi-Fi 6E | Wi-Fi 6E |
