"""Verify Android launcher PNG assets have transparent corners."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "android" / "app" / "src" / "main" / "res"

FAIL = False
for pattern in ("mipmap-*/ic_launcher.png", "drawable-*/ic_launcher_foreground.png"):
    for path in sorted(ROOT.glob(pattern)):
        im = Image.open(path).convert("RGBA")
        px = im.load()
        w, h = im.size
        corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
        transparent = sum(1 for y in range(h) for x in range(w) if px[x, y][3] == 0)
        opaque_black = sum(
            1
            for y in range(h)
            for x in range(w)
            if px[x, y][3] > 200 and px[x, y][0] < 20 and px[x, y][1] < 20 and px[x, y][2] < 20
        )
        ok = all(c[3] == 0 for c in corners) and transparent > 0
        status = "OK" if ok else "FAIL"
        if not ok:
            FAIL = True
        print(
            f"{status} {path.relative_to(ROOT)} size={im.size} "
            f"transparent={transparent} opaque_black={opaque_black} corners={corners}"
        )

if FAIL:
    raise SystemExit(1)
