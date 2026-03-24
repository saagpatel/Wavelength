#!/usr/bin/env python3
"""Generate the Viridis colormap LUT for Shaders.metal.

Requires: pip install matplotlib numpy
Output: prints 256-entry Metal constant array to stdout.

Usage:
  python3 scripts/generate_viridis.py > /tmp/viridis_lut.txt
  # Then paste into Shaders.metal
"""

import sys

try:
    import matplotlib.cm as cm
    import numpy as np
except ImportError:
    print("matplotlib and numpy required: pip install matplotlib numpy", file=sys.stderr)
    # Fallback: generate from hardcoded anchor points with linear interpolation
    # These 9 anchor points define viridis precisely enough for 256 entries
    anchors = [
        (0, 0.267004, 0.004874, 0.329415),
        (32, 0.282327, 0.140926, 0.457517),
        (64, 0.253935, 0.265254, 0.529983),
        (96, 0.190631, 0.407061, 0.556089),
        (128, 0.127568, 0.566949, 0.550556),
        (160, 0.134692, 0.658636, 0.517649),
        (192, 0.477504, 0.821444, 0.318195),
        (224, 0.741388, 0.873449, 0.149561),
        (255, 0.993248, 0.906157, 0.143936),
    ]

    def lerp(a, b, t):
        return a + (b - a) * t

    print("constant float4 viridis[256] = {")
    for i in range(256):
        # Find surrounding anchors
        lo = anchors[0]
        hi = anchors[-1]
        for j in range(len(anchors) - 1):
            if anchors[j][0] <= i <= anchors[j + 1][0]:
                lo = anchors[j]
                hi = anchors[j + 1]
                break
        span = hi[0] - lo[0]
        t = (i - lo[0]) / span if span > 0 else 0
        r = lerp(lo[1], hi[1], t)
        g = lerp(lo[2], hi[2], t)
        b = lerp(lo[3], hi[3], t)
        comma = "," if i < 255 else ""
        print(f"    float4({r:.6f}, {g:.6f}, {b:.6f}, 1.0){comma}  // {i}")
    print("};")
    sys.exit(0)

colors = cm.viridis(np.linspace(0, 1, 256))
print("constant float4 viridis[256] = {")
for i, c in enumerate(colors):
    comma = "," if i < 255 else ""
    print(f"    float4({c[0]:.6f}, {c[1]:.6f}, {c[2]:.6f}, 1.0){comma}  // {i}")
print("};")
