#!/usr/bin/env python3
"""
Build airports.json for Wavelength from OurAirports data.

Downloads airports.csv, filters to US large/medium airports,
outputs a compact JSON array.

Usage:
  python3 scripts/build_airports_json.py
"""

import csv
import io
import json
import os
import sys
import urllib.request

AIRPORTS_CSV_URL = "https://davidmegginson.github.io/ourairports-data/airports.csv"

OUTPUT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Wavelength", "Resources", "airports.json",
)


def download_airports() -> str:
    print(f"Downloading airports from {AIRPORTS_CSV_URL} ...")
    with urllib.request.urlopen(AIRPORTS_CSV_URL, timeout=30) as resp:
        return resp.read().decode("utf-8")


def parse_and_filter(csv_text: str) -> list[dict]:
    reader = csv.DictReader(io.StringIO(csv_text))
    airports = []
    for row in reader:
        if row.get("iso_country") != "US":
            continue
        if row.get("type") not in ("large_airport", "medium_airport"):
            continue

        ident = row.get("ident", "")
        name = row.get("name", "")
        try:
            lat = float(row.get("latitude_deg", "0"))
            lon = float(row.get("longitude_deg", "0"))
        except ValueError:
            continue

        if not ident or not name:
            continue

        airports.append({
            "ident": ident,
            "name": name,
            "lat": round(lat, 4),
            "lon": round(lon, 4),
        })

    return airports


def main() -> None:
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)

    csv_text = download_airports()
    airports = parse_and_filter(csv_text)

    print(f"Filtered {len(airports)} US large/medium airports")
    assert len(airports) >= 200, f"Expected >= 200 airports, got {len(airports)}"

    with open(OUTPUT_PATH, "w") as f:
        json.dump(airports, f, separators=(",", ":"))

    size_kb = os.path.getsize(OUTPUT_PATH) / 1024
    print(f"Output: {OUTPUT_PATH} ({size_kb:.1f} KB, {len(airports)} entries)")
    print("Done.")


if __name__ == "__main__":
    main()
