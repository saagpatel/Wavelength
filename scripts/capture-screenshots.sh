#!/bin/bash
set -euo pipefail

# Run from any directory. Requires full Xcode, XcodeGen, Python 3, and this simulator.
# SHOT_WAIT defaults to 4 seconds; SHOT_WAIT_1, _2, _3 override individual shots.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DERIVED="${DERIVED:-.build/shots}"
OUTPUT="screenshots/appstore"
DEVICE_NAMES=("iPhone 18 Pro Max")
SHOTS=(1 2 3)
booted_devices=()
overridden_devices=()

fail() { echo "capture-screenshots: $*" >&2; exit 1; }

cleanup() {
    local result=$? id
    trap - EXIT
    set +e
    for id in "${overridden_devices[@]:-}"; do
        [[ -n "$id" ]] || continue
        if ! xcrun simctl status_bar "$id" clear; then
            echo "capture-screenshots: could not clear status bar for $id" >&2
            result=1
        fi
    done
    for id in "${booted_devices[@]:-}"; do
        [[ -n "$id" ]] || continue
        if ! xcrun simctl shutdown "$id"; then
            echo "capture-screenshots: could not shut down $id" >&2
            result=1
        fi
    done
    exit "$result"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for tool in xcodebuild xcodegen xcrun python3 sips; do
    command -v "$tool" >/dev/null || fail "required tool '$tool' is missing"
done

# Resolve every required device before building. Prefer the newest installed iOS runtime;
# duplicates within that runtime are ambiguous and must be resolved by the operator.
devices_json="$(xcrun simctl list devices available -j)"
device_rows="$(printf '%s' "$devices_json" | python3 -c '
import json, re, sys
devices = json.load(sys.stdin)["devices"]
for name in sys.argv[1:]:
    candidates = []
    for runtime, entries in devices.items():
        if ".iOS-" not in runtime:
            continue
        version = tuple(map(int, re.findall(r"\d+", runtime.split(".iOS-", 1)[1])))
        for device in entries:
            if device["name"] == name and device.get("isAvailable", True):
                candidates.append((version, device))
    if not candidates:
        sys.exit(f"capture-screenshots: missing available simulator {name!r}; install its iOS runtime and create the device in Xcode")
    newest = max(version for version, _ in candidates)
    matches = [device for version, device in candidates if version == newest]
    if len(matches) != 1:
        sys.exit(f"capture-screenshots: multiple simulators named {name!r} in the newest runtime; remove or rename duplicates")
    device = matches[0]
    print(device["udid"], device["state"], name.lower().replace(" ", "-"), sep="|")
' "${DEVICE_NAMES[@]}")"

# Generated project output is ignored; regenerate so all source files are included.
xcodegen generate
xcodebuild build -project Wavelength.xcodeproj -scheme Wavelength \
    -configuration Debug -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO

app="$DERIVED/Build/Products/Debug-iphonesimulator/Wavelength.app"
[[ -d "$app" ]] || fail "built app not found at $app"
bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Info.plist")"
[[ -n "$bundle_id" ]] || fail "built Info.plist has no bundle ID"

while IFS='|' read -r id state slug; do
    case "$state" in
        Shutdown)
            # Record ownership first so cleanup also handles a partially failed boot.
            booted_devices+=("$id")
            xcrun simctl boot "$id"
            ;;
        Booted) ;;
        *) fail "simulator $id is in state '$state'; wait until Booted or Shutdown" ;;
    esac
    xcrun simctl bootstatus "$id" -b
    overridden_devices+=("$id")
    xcrun simctl status_bar "$id" override --time 9:41 --dataNetwork wifi \
        --wifiBars 3 --cellularBars 4 --batteryState charged --batteryLevel 100
    xcrun simctl install "$id" "$app"
    xcrun simctl ui "$id" appearance dark
    mkdir -p "$OUTPUT/$slug"

    for shot in "${SHOTS[@]}"; do
        wait_var="SHOT_WAIT_$shot"
        settle="${!wait_var:-${SHOT_WAIT:-4}}"
        [[ "$settle" =~ ^[0-9]+([.][0-9]+)?$ ]] || fail "$wait_var/SHOT_WAIT must be nonnegative seconds"
        printf -v filename '%s/%s/%02d.png' "$OUTPUT" "$slug" "$shot"
        # simctl terminate reports an error when the app is already stopped.
        xcrun simctl terminate "$id" "$bundle_id" >/dev/null 2>&1 || true
        xcrun simctl launch "$id" "$bundle_id" -AppStoreScreenshot "$shot"
        sleep "$settle"
        xcrun simctl io "$id" screenshot "$filename"
        dimensions="$(sips -g pixelWidth -g pixelHeight "$filename")"
        width="$(printf '%s\n' "$dimensions" | awk '/pixelWidth:/ {print $2}')"
        height="$(printf '%s\n' "$dimensions" | awk '/pixelHeight:/ {print $2}')"
        [[ "$width" == 1320 && "$height" == 2868 ]] || \
            fail "$filename is ${width}x${height}; required portrait size is 1320x2868 (6.9-inch)"
        echo "Captured $filename (${width}x${height})"
    done
done <<< "$device_rows"
