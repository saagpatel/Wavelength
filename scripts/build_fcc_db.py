#!/usr/bin/env python3
"""
Build the bundled FCC spectrum allocation database for Wavelength.

Sources:
  1. FCC spectrum-band-plans GitHub repo (225 MHz - 3700 MHz, official JSON)
  2. Curated US band allocations for 70 MHz - 225 MHz and 3700 MHz - 6425 MHz

Output: Wavelength/Resources/fcc_spectrum.sqlite

Usage:
  python3 scripts/build_fcc_db.py
"""

import json
import os
import re
import sqlite3
import sys
import urllib.request

FCC_JSON_URL = (
    "https://raw.githubusercontent.com/FCC/"
    "spectrum-band-plans/master/v0.1/spectrum-band-plan.json"
)

OUTPUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Wavelength", "Resources", "fcc_spectrum.sqlite",
)

# Curated allocations for bands the FCC JSON doesn't cover (70-225 MHz, 3700-6425 MHz)
# and notable point frequencies within the FCC range.
CURATED_ALLOCATIONS = [
    # (freq_low, freq_high, service_name, allocation_type, itu_region, notes)
    # VHF TV Low Band
    (54.0, 72.0, "TV Broadcast (VHF Low, Ch 2-4)", "PRIMARY", "Region 2", None),
    (76.0, 88.0, "TV Broadcast (VHF Low, Ch 5-6)", "PRIMARY", "Region 2", None),
    # FM Broadcast
    (88.0, 108.0, "FM Broadcasting", "PRIMARY", "Region 2", "Commercial FM radio"),
    # Aviation
    (108.0, 118.0, "Aeronautical Radionavigation (VOR/ILS)", "PRIMARY", "Region 2", None),
    (118.0, 137.0, "Aeronautical Mobile (Air Traffic Control)", "PRIMARY", "Region 2", None),
    (121.5, 121.5, "Aviation Emergency (ELT)", "PRIMARY", "Region 2", "International distress frequency"),
    # Weather & Space
    (137.0, 138.0, "Meteorological-Satellite / Space Operation", "PRIMARY", "Region 2", None),
    # Amateur Radio
    (144.0, 148.0, "Amateur Radio (2m Band)", "PRIMARY", "Region 2", None),
    # Land & Maritime Mobile
    (150.8, 162.0, "Land Mobile / Maritime Mobile", "PRIMARY", "Region 2", None),
    (162.0, 162.0, "National Distress (VHF Ch 16)", "PRIMARY", "Region 2", None),
    (162.4, 162.55, "NOAA Weather Radio", "PRIMARY", "Region 2", "Continuous weather broadcasts"),
    # VHF TV High Band
    (174.0, 216.0, "TV Broadcast (VHF High, Ch 7-13)", "PRIMARY", "Region 2", None),
    # Amateur & Land Mobile
    (220.0, 225.0, "Amateur Radio (1.25m) / Land Mobile", "SECONDARY", "Region 2", None),
    # Emergency Beacons
    (406.0, 406.1, "Emergency Position Indicating Radiobeacon (EPIRB/PLB)", "PRIMARY", "Region 2", None),
    # ISM Band
    (420.0, 450.0, "Amateur Radio (70cm) / Radiolocation", "SECONDARY", "Region 2", None),
    (433.05, 434.79, "ISM Band (433 MHz)", "PRIMARY", "Region 2", "Smart home / IoT devices"),
    # UHF TV
    (470.0, 608.0, "TV Broadcast (UHF, Ch 14-36)", "PRIMARY", "Region 2", None),
    (614.0, 698.0, "TV Broadcast / 600 MHz Band (Repacked)", "PRIMARY", "Region 2", None),
    # Aviation / Navigation
    (1090.0, 1090.0, "ADS-B Aircraft Transponders", "PRIMARY", "Region 2", "Mode S extended squitter"),
    (1164.0, 1215.0, "Aeronautical Radionavigation (DME/TACAN)", "PRIMARY", "Region 2", None),
    (1215.0, 1240.0, "Radiolocation / Amateur Radio (23cm)", "SECONDARY", "Region 2", None),
    (1240.0, 1300.0, "Aeronautical Radionavigation / Radiolocation", "PRIMARY", "Region 2", None),
    # Satellite Communications
    (1525.0, 1559.0, "Mobile-Satellite (Space-to-Earth)", "PRIMARY", "Region 2", None),
    (1559.0, 1610.0, "Aeronautical Radionavigation (GPS/GNSS)", "PRIMARY", "Region 2", None),
    (1575.42, 1575.42, "GPS L1 Signal", "PRIMARY", "Region 2", "Primary GPS civilian signal"),
    (1610.0, 1618.725, "Mobile-Satellite (Earth-to-Space) / RDSS", "PRIMARY", "Region 2", None),
    (1616.0, 1626.5, "Iridium Satellite", "PRIMARY", "Region 2", "LEO satellite phone constellation"),
    # Upper cellular / 5G
    (3700.0, 4200.0, "5G C-Band (n77/n78)", "PRIMARY", "Region 2", "C-band auction winners"),
    (4200.0, 4400.0, "Aeronautical Radionavigation (Radio Altimeters)", "PRIMARY", "Region 2", None),
    # Wi-Fi 5 GHz
    (5150.0, 5250.0, "UNII-1 (Wi-Fi 5 GHz Indoor)", "PRIMARY", "Region 2", None),
    (5250.0, 5350.0, "UNII-2 (Wi-Fi 5 GHz)", "PRIMARY", "Region 2", "DFS required"),
    (5470.0, 5725.0, "UNII-2 Extended (Wi-Fi 5 GHz)", "PRIMARY", "Region 2", "DFS required"),
    (5725.0, 5850.0, "UNII-3 / ISM (Wi-Fi 5 GHz)", "PRIMARY", "Region 2", None),
    # DSRC / V2X
    (5850.0, 5925.0, "Dedicated Short-Range Communications (DSRC/C-V2X)", "PRIMARY", "Region 2", None),
    # Wi-Fi 6E
    (5925.0, 6425.0, "UNII-5 (Wi-Fi 6E Low)", "PRIMARY", "Region 2", "Standard power + low power indoor"),
    (6425.0, 7125.0, "UNII-7/8 (Wi-Fi 6E High)", "PRIMARY", "Region 2", "Under consideration for unlicensed"),
    # US Cellular bands (from 3GPP band numbering)
    (617.0, 652.0, "LTE Band 71 Uplink (T-Mobile 600 MHz)", "PRIMARY", "Region 2", None),
    (663.0, 698.0, "LTE Band 71 Downlink (T-Mobile 600 MHz)", "PRIMARY", "Region 2", None),
    (699.0, 716.0, "LTE Band 12 Uplink (AT&T/T-Mobile 700 MHz)", "PRIMARY", "Region 2", None),
    (729.0, 746.0, "LTE Band 12 Downlink (AT&T/T-Mobile 700 MHz)", "PRIMARY", "Region 2", None),
    (777.0, 787.0, "LTE Band 13 Uplink (Verizon 700C)", "PRIMARY", "Region 2", None),
    (746.0, 756.0, "LTE Band 13 Downlink (Verizon 700C)", "PRIMARY", "Region 2", None),
    (704.0, 716.0, "LTE Band 17 Uplink (AT&T 700b)", "PRIMARY", "Region 2", None),
    (734.0, 746.0, "LTE Band 17 Downlink (AT&T 700b)", "PRIMARY", "Region 2", None),
    (824.0, 849.0, "Cellular Band A/B Uplink (850 MHz)", "PRIMARY", "Region 2", None),
    (869.0, 894.0, "Cellular Band A/B Downlink (850 MHz)", "PRIMARY", "Region 2", None),
    (1710.0, 1755.0, "LTE Band 4/66 Uplink (AWS)", "PRIMARY", "Region 2", None),
    (2110.0, 2155.0, "LTE Band 4/66 Downlink (AWS)", "PRIMARY", "Region 2", None),
    (1850.0, 1915.0, "LTE Band 25 Uplink (Sprint PCS)", "PRIMARY", "Region 2", None),
    (1930.0, 1995.0, "LTE Band 25 Downlink (Sprint PCS)", "PRIMARY", "Region 2", None),
    (1900.0, 1920.0, "LTE Band 2 Uplink (PCS)", "PRIMARY", "Region 2", None),
    (1990.0, 2000.0, "LTE Band 2 Downlink (PCS)", "PRIMARY", "Region 2", None),
    (2496.0, 2690.0, "LTE Band 41 (T-Mobile Mid-Band TDD)", "PRIMARY", "Region 2", None),
    (3300.0, 4200.0, "5G NR n77 (C-Band TDD)", "PRIMARY", "Region 2", None),
    (3300.0, 3800.0, "5G NR n78 (C-Band TDD)", "PRIMARY", "Region 2", None),
    # Additional notable allocations
    (902.0, 928.0, "ISM Band (900 MHz)", "PRIMARY", "Region 2", "LoRa / Z-Wave / IoT"),
    (2400.0, 2483.5, "ISM Band (2.4 GHz) / Bluetooth / Wi-Fi", "PRIMARY", "Region 2", None),
    (1227.60, 1227.60, "GPS L2 Signal", "PRIMARY", "Region 2", "Military/authorized GPS"),
    (1176.45, 1176.45, "GPS L5 Signal", "PRIMARY", "Region 2", "Safety-of-life GPS"),
    (156.0, 156.0, "Marine VHF Ch 6 (Safety)", "PRIMARY", "Region 2", None),
    (156.8, 156.8, "Marine VHF Ch 16 (Distress)", "PRIMARY", "Region 2", "International calling/distress"),
    (243.0, 243.0, "Military Emergency (Guard)", "PRIMARY", "Region 2", "Military distress frequency"),
    (462.5625, 462.7250, "FRS/GMRS (Family Radio Service)", "PRIMARY", "Region 2", None),
    (460.0, 470.0, "UHF Business/Land Mobile", "PRIMARY", "Region 2", None),
    (746.0, 806.0, "Lower 700 MHz Band (Public Safety + Commercial)", "PRIMARY", "Region 2", None),
    (806.0, 824.0, "Upper 800 MHz (Public Safety)", "PRIMARY", "Region 2", None),
    (896.0, 901.0, "Narrowband PCS", "PRIMARY", "Region 2", None),
    # Per-channel FM frequencies (every 0.2 MHz from 88.1 to 107.9)
    *[
        (freq, freq, f"FM {freq:.1f} MHz", "PRIMARY", "Region 2", "FM broadcast channel")
        for freq in [88.1 + i * 0.2 for i in range(100)]
    ],
]


def create_schema(cur: sqlite3.Cursor) -> None:
    """Create the fcc_allocations table with index."""
    cur.execute("""
        CREATE TABLE IF NOT EXISTS fcc_allocations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            freq_low_mhz REAL NOT NULL,
            freq_high_mhz REAL NOT NULL,
            service_name TEXT NOT NULL,
            allocation_type TEXT NOT NULL,
            itu_region TEXT,
            notes TEXT
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_alloc_freq
        ON fcc_allocations(freq_low_mhz, freq_high_mhz)
    """)


def download_fcc_band_plans() -> list[dict]:
    """Download and parse the FCC spectrum band plans.

    The FCC file is NOT valid JSON — it's repeated "band-plan": { ... }
    objects without array wrapping. We extract each JSON object with regex.
    """
    print(f"Downloading FCC data from {FCC_JSON_URL} ...")
    with urllib.request.urlopen(FCC_JSON_URL, timeout=30) as resp:
        raw = resp.read().decode("utf-8")

    # Extract all JSON objects that follow "band-plan":
    # Each band-plan value is a { ... } block
    plans = []
    # Find each complete JSON object after "band-plan":
    pattern = r'"band-plan"\s*:\s*(\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\})'
    for match in re.finditer(pattern, raw):
        try:
            plan = json.loads(match.group(1))
            plans.append(plan)
        except json.JSONDecodeError:
            continue

    print(f"Parsed {len(plans)} band plans from FCC data")
    return plans


def insert_fcc_data(cur: sqlite3.Cursor, plans: list[dict]) -> int:
    """Insert FCC band-plans and their blocks. Returns row count."""
    count = 0

    for plan in plans:
        bottom = plan.get("bottom", 0)
        top = plan.get("top", 0)
        desc = plan.get("desc", "Unknown")

        if not bottom or not top:
            continue

        cur.execute(
            "INSERT INTO fcc_allocations "
            "(freq_low_mhz, freq_high_mhz, service_name, allocation_type, itu_region, notes) "
            "VALUES (?, ?, ?, 'PRIMARY', 'Region 2', NULL)",
            (bottom, top, str(desc)[:200]),
        )
        count += 1

        for block in plan.get("blocks", []):
            if not isinstance(block, dict):
                continue
            block_name = block.get("name", "")
            block_bottom = block.get("bottom", bottom)
            block_top = block.get("top", top)

            if block_name and block_name != desc:
                cur.execute(
                    "INSERT INTO fcc_allocations "
                    "(freq_low_mhz, freq_high_mhz, service_name, allocation_type, itu_region, notes) "
                    "VALUES (?, ?, ?, 'SECONDARY', 'Region 2', ?)",
                    (block_bottom, block_top, str(block_name)[:200],
                     f"Block within {bottom:.0f}-{top:.0f} MHz band"),
                )
                count += 1

    return count


def insert_curated(cur: sqlite3.Cursor) -> int:
    """Insert curated allocations for bands not covered by FCC JSON."""
    count = 0
    for row in CURATED_ALLOCATIONS:
        cur.execute(
            "INSERT INTO fcc_allocations "
            "(freq_low_mhz, freq_high_mhz, service_name, allocation_type, itu_region, notes) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            row,
        )
        count += 1
    return count


def verify(cur: sqlite3.Cursor) -> None:
    """Run acceptance criteria checks."""
    cur.execute("SELECT COUNT(*) FROM fcc_allocations")
    total = cur.fetchone()[0]
    print(f"Total rows: {total}")
    assert total >= 500, f"Expected >= 500 rows, got {total}"

    cur.execute(
        "SELECT COUNT(*) FROM fcc_allocations "
        "WHERE freq_low_mhz <= 98.1 AND freq_high_mhz >= 98.1"
    )
    fm_count = cur.fetchone()[0]
    print(f"FM 98.1 MHz query results: {fm_count}")
    assert fm_count >= 1, "FM query must return at least one row"

    # Verify file size
    db_size = os.path.getsize(OUTPUT_PATH)
    print(f"Database size: {db_size / 1024:.1f} KB")
    assert db_size <= 10 * 1024 * 1024, f"File too large: {db_size} bytes (max 10MB)"

    print("All acceptance criteria PASSED.")


def main() -> None:
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

    if os.path.exists(OUTPUT_PATH):
        os.remove(OUTPUT_PATH)

    conn = sqlite3.connect(OUTPUT_PATH)
    cur = conn.cursor()

    create_schema(cur)

    try:
        plans = download_fcc_band_plans()
        fcc_count = insert_fcc_data(cur, plans)
        print(f"Inserted {fcc_count} rows from FCC data")
    except Exception as e:
        print(f"Warning: FCC data download failed ({e}), using curated data only")

    curated_count = insert_curated(cur)
    print(f"Inserted {curated_count} curated rows")

    conn.commit()
    verify(cur)

    conn.close()
    print(f"Output: {OUTPUT_PATH}")
    print("Done.")


if __name__ == "__main__":
    main()
