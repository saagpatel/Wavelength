#!/usr/bin/env python3
"""Check that Fastlane's en-US listing matches APPSTORE-METADATA.md."""

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parent.parent
SOURCE = (ROOT / "APPSTORE-METADATA.md").read_text(encoding="utf-8")
METADATA = ROOT / "fastlane" / "metadata" / "en-US"


def section(title: str) -> str:
    match = re.search(
        rf"^## {re.escape(title)}\s*\n(.*?)(?=^## |\Z)",
        SOURCE,
        flags=re.MULTILINE | re.DOTALL,
    )
    if not match:
        raise ValueError(f"Missing section: {title}")
    return match.group(1).strip()


def table_value(field: str) -> str:
    match = re.search(rf"^\| {re.escape(field)} \| (.*?) \|$", SOURCE, re.MULTILINE)
    if not match:
        raise ValueError(f"Missing table value: {field}")
    return match.group(1).strip("`")


def url_value(field: str) -> str | None:
    match = re.search(rf"^- {re.escape(field)}: (\S+)\s*$", section("URLs"), re.MULTILINE)
    return match.group(1) if match else None


description = section("Description")
description_lines = description.splitlines()
description_lines = [
    line[2:] if line.startswith("- ") else line for line in description_lines
]
description_lines = [
    line
    for index, line in enumerate(description_lines)
    if not (line == "" and index > 0 and description_lines[index - 1] == "Features:")
]
description = "\n".join(description_lines)
promotional_text = re.sub(r"^`(.*)`$", r"\1", section("Promotional text"))
keyword_match = re.search(r"^`(.*)`$", section("Keywords"), re.DOTALL)
if not keyword_match:
    raise ValueError("Keywords must be a single inline-code value")

expected = {
    "name.txt": table_value("Name"),
    "subtitle.txt": table_value("Subtitle"),
    "description.txt": description,
    "keywords.txt": keyword_match.group(1),
    "promotional_text.txt": promotional_text,
    "support_url.txt": url_value("Support"),
    "privacy_url.txt": url_value("Privacy"),
    "release_notes.txt": "Initial release.",
}
marketing_url = url_value("Marketing")
if marketing_url is not None:
    expected["marketing_url.txt"] = marketing_url

for filename, value in expected.items():
    if value is None:
        raise ValueError(f"Missing source value for {filename}")
    path = METADATA / filename
    actual = path.read_bytes()
    wanted = (value + "\n").encode("utf-8")
    if actual != wanted:
        raise SystemExit(f"FAIL {path.relative_to(ROOT)}: differs from APPSTORE-METADATA.md")
    print(f"OK {path.relative_to(ROOT)}: byte-for-byte match ({len(actual)} bytes)")
