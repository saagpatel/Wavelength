#!/usr/bin/env python3
"""
Build the bundled FM station database for Wavelength.

Downloads active US FM station data from FCC FM Query (pipe-delimited format),
parses call signs, frequencies, coordinates, and ERP, and writes to SQLite.

Usage:
  python3 scripts/build_fm_db.py
"""

import os
import re
import sqlite3
import sys
import urllib.request

# FCC FM Query base URL — queried per-state to avoid timeout on full US query
FCC_FM_BASE = (
    "https://transition.fcc.gov/fcc-bin/fmq"
    "?call=&city=&freq=88&fre2=108"
    "&type=2&status=A&list=4&size=9"
)

US_STATES = [
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA",
    "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD",
    "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ",
    "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC",
    "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY",
    "DC", "PR", "VI", "GU", "AS",
]

OUTPUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Wavelength", "Resources", "fm_stations.sqlite",
)


def create_schema(cur: sqlite3.Cursor) -> None:
    cur.execute("""
        CREATE TABLE IF NOT EXISTS fm_stations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            call_sign TEXT NOT NULL,
            frequency_mhz REAL NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            erp_watts INTEGER,
            city TEXT,
            fetched_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        )
    """)
    cur.execute("""
        CREATE INDEX IF NOT EXISTS idx_fm_location
        ON fm_stations(latitude, longitude)
    """)


def dms_to_decimal(degrees: float, minutes: float, seconds: float, direction: str) -> float:
    """Convert degrees/minutes/seconds to decimal degrees."""
    decimal = abs(degrees) + minutes / 60.0 + seconds / 3600.0
    if direction in ("S", "W"):
        decimal = -decimal
    return decimal


def parse_frequency(freq_str: str) -> float | None:
    """Extract numeric frequency from string like '98.1  MHz'."""
    match = re.search(r"([\d.]+)", freq_str.strip())
    if match:
        return float(match.group(1))
    return None


def parse_erp(erp_str: str) -> int | None:
    """Extract ERP in watts from string like '50.   kW'."""
    match = re.search(r"([\d.]+)\s*(kW|W)", erp_str.strip(), re.IGNORECASE)
    if not match:
        return None
    value = float(match.group(1))
    unit = match.group(2).lower()
    if unit == "kw":
        return int(value * 1000)
    return int(value)


def download_fcc_fm() -> str:
    """Download FCC FM data state-by-state to avoid timeout on full US query."""
    all_lines: list[str] = []
    for i, state in enumerate(US_STATES):
        url = f"{FCC_FM_BASE}&state={state}"
        print(f"  [{i+1}/{len(US_STATES)}] Fetching {state} ...", end=" ", flush=True)
        try:
            req = urllib.request.Request(url)
            req.add_header("User-Agent", "Wavelength-BuildScript/1.0")
            with urllib.request.urlopen(req, timeout=120) as resp:
                text = resp.read().decode("utf-8", errors="replace")
                lines = [l for l in text.split("\n") if l.strip().startswith("|")]
                all_lines.extend(lines)
                print(f"{len(lines)} lines")
        except Exception as e:
            print(f"FAILED ({e})")
            continue
    print(f"Total lines from all states: {len(all_lines)}")
    return "\n".join(all_lines)


def parse_stations(raw: str) -> list[dict]:
    """Parse pipe-delimited FCC FM query output.

    Fields are separated by | characters. The format per line:
    |CALL|FREQ|SERVICE|CHANNEL|DIR|HOURS|CLASS|HAAT_CLASS|STATUS|CITY|STATE|COUNTRY|...
    |...|ERP_H|ERP_V|HAAT|HAAT_V|FACID|N/S|LAT_DEG|LAT_MIN|LAT_SEC|W/E|LON_DEG|LON_MIN|LON_SEC|...|
    """
    stations = []
    seen = set()

    for line in raw.split("\n"):
        line = line.strip()
        if not line or not line.startswith("|"):
            continue

        fields = [f.strip() for f in line.split("|")]
        # Remove empty first/last from leading/trailing |
        if fields and fields[0] == "":
            fields = fields[1:]
        if fields and fields[-1] == "":
            fields = fields[:-1]

        if len(fields) < 24:
            continue

        call_sign = fields[0].strip()
        freq = parse_frequency(fields[1])
        service = fields[2].strip()
        status = fields[8].strip()
        city = fields[9].strip()
        state = fields[10].strip()

        # Only include licensed FM stations (not translators/boosters for now)
        if service not in ("FM",):
            continue
        if status != "LIC":
            continue
        if freq is None or freq < 88.0 or freq > 108.0:
            continue

        erp = parse_erp(fields[13]) if len(fields) > 13 else None

        # Parse coordinates (DMS format)
        try:
            ns_dir = fields[18].strip()
            lat_deg = float(fields[19])
            lat_min = float(fields[20])
            lat_sec = float(fields[21])

            ew_dir = fields[22].strip()
            lon_deg = float(fields[23])
            lon_min = float(fields[24])
            lon_sec = float(fields[25])
        except (ValueError, IndexError):
            continue

        latitude = dms_to_decimal(lat_deg, lat_min, lat_sec, ns_dir)
        longitude = dms_to_decimal(lon_deg, lon_min, lon_sec, ew_dir)

        # Basic validation
        if not (-90 <= latitude <= 90) or not (-180 <= longitude <= 180):
            continue

        # Deduplicate by call sign + frequency
        key = f"{call_sign}-{freq}"
        if key in seen:
            continue
        seen.add(key)

        city_state = f"{city}, {state}" if city and state else city or state or None

        stations.append({
            "call_sign": call_sign,
            "frequency_mhz": freq,
            "latitude": round(latitude, 6),
            "longitude": round(longitude, 6),
            "erp_watts": erp,
            "city": city_state,
        })

    return stations


def main() -> None:
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

    if os.path.exists(OUTPUT_PATH):
        os.remove(OUTPUT_PATH)

    raw = download_fcc_fm()
    stations = parse_stations(raw)
    print(f"Parsed {len(stations)} licensed FM stations")

    conn = sqlite3.connect(OUTPUT_PATH)
    cur = conn.cursor()
    create_schema(cur)

    for s in stations:
        cur.execute(
            "INSERT INTO fm_stations (call_sign, frequency_mhz, latitude, longitude, erp_watts, city) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (s["call_sign"], s["frequency_mhz"], s["latitude"], s["longitude"],
             s["erp_watts"], s["city"]),
        )

    conn.commit()

    # Verify
    cur.execute("SELECT COUNT(*) FROM fm_stations")
    count = cur.fetchone()[0]
    print(f"Total rows: {count}")

    cur.execute("SELECT COUNT(*) FROM fm_stations WHERE frequency_mhz BETWEEN 98.0 AND 98.2")
    fm98 = cur.fetchone()[0]
    print(f"Stations at ~98.1 MHz: {fm98}")

    conn.close()

    size_kb = os.path.getsize(OUTPUT_PATH) / 1024
    print(f"Output: {OUTPUT_PATH} ({size_kb:.1f} KB)")

    if count < 500:
        print(f"WARNING: Only {count} stations (expected ~3000). FCC API may have returned partial data.")
        print("The app will still work with reduced FM station coverage.")

    print("Done.")


if __name__ == "__main__":
    main()
