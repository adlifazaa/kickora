"""Inspect launcher icon transparency and edge pixels."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def analyze(path: Path) -> dict:
    im = Image.open(path)
    rgba = im.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    transparent = 0
    opaque = 0
    semi = 0
    white_opaque = 0
    white_edge = 0
    near_white_edge = 0

    min_x, min_y, max_x, max_y = w, h, 0, 0

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                transparent += 1
            elif a == 255:
                opaque += 1
            else:
                semi += 1

            if a > 8:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)

            is_white = r >= 248 and g >= 248 and b >= 248
            if is_white and a > 200:
                white_opaque += 1

            if a > 0:
                on_edge = x == 0 or y == 0 or x == w - 1 or y == h - 1
                if on_edge:
                    if is_white and a > 200:
                        white_edge += 1
                    if r >= 235 and g >= 235 and b >= 235 and a > 200:
                        near_white_edge += 1

    bbox_w = max_x - min_x + 1 if max_x >= min_x else 0
    bbox_h = max_y - min_y + 1 if max_y >= min_y else 0
    cx = (min_x + max_x) / 2 if bbox_w else w / 2
    cy = (min_y + max_y) / 2 if bbox_h else h / 2
    center_dx = abs(cx - (w - 1) / 2)
    center_dy = abs(cy - (h - 1) / 2)

    corners = {
        "TL": px[0, 0],
        "TR": px[w - 1, 0],
        "BL": px[0, h - 1],
        "BR": px[w - 1, h - 1],
    }

    return {
        "path": str(path.relative_to(ROOT)),
        "size": (w, h),
        "mode": im.mode,
        "transparent": transparent,
        "opaque": opaque,
        "semi": semi,
        "white_opaque": white_opaque,
        "white_edge": white_edge,
        "near_white_edge": near_white_edge,
        "bbox": (min_x, min_y, max_x, max_y, bbox_w, bbox_h),
        "center_offset_px": (round(center_dx, 2), round(center_dy, 2)),
        "corners": corners,
    }


def main() -> None:
    targets = [ROOT / "assets/branding/final/app_icon_1024.png"]
    targets += sorted((ROOT / "android/app/src/main/res").glob("mipmap-*/ic_launcher.png"))
    targets += sorted((ROOT / "android/app/src/main/res").glob("mipmap-*/ic_launcher_foreground.png"))

    for path in targets:
        if not path.exists():
            continue
        r = analyze(path)
        print("---", r["path"], "---")
        print(f"  size={r['size']} mode={r['mode']}")
        print(
            f"  alpha: transparent={r['transparent']} opaque={r['opaque']} semi={r['semi']}"
        )
        print(
            f"  white opaque px={r['white_opaque']} | canvas edge white={r['white_edge']} near-white={r['near_white_edge']}"
        )
        print(f"  content bbox={r['bbox'][:4]} size={r['bbox'][4:6]}")
        print(f"  center offset from canvas center={r['center_offset_px']}")
        print(f"  corners RGBA={r['corners']}")


if __name__ == "__main__":
    main()
