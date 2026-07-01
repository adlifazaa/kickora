"""Build transparent launcher source from the approved master icon.

Reads assets/branding/final/app_icon_1024.png (unchanged) and writes
assets/branding/final/app_icon_launcher_transparent.png with outer black
padding converted to alpha transparency for Android launcher generation.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets" / "branding" / "final" / "app_icon_1024.png"
OUT = ROOT / "assets" / "branding" / "final" / "app_icon_launcher_transparent.png"


def is_outer_black(r: int, g: int, b: int, a: int = 255) -> bool:
    if a == 0:
        return True
    return r <= 24 and g <= 24 and b <= 24


def flood_outer_black(rgba: Image.Image) -> None:
    w, h = rgba.size
    px = rgba.load()
    bg = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    def seed(x: int, y: int) -> None:
        r, g, b, a = px[x, y]
        if is_outer_black(r, g, b, a):
            bg[y][x] = True
            q.append((x, y))

    for x in range(w):
        seed(x, 0)
        seed(x, h - 1)
    for y in range(h):
        seed(0, y)
        seed(w - 1, y)

    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[ny][nx]:
                r, g, b, a = px[nx, ny]
                if is_outer_black(r, g, b, a):
                    bg[ny][nx] = True
                    q.append((nx, ny))

    for y in range(h):
        for x in range(w):
            if bg[y][x]:
                px[x, y] = (0, 0, 0, 0)


def defringe(rgba: Image.Image, passes: int = 6) -> None:
    px = rgba.load()
    w, h = rgba.size
    for _ in range(passes):
        clear: list[tuple[int, int]] = []
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a == 0:
                    continue
                if r > 40 or g > 40 or b > 40:
                    continue
                near_trans = any(
                    0 <= x + dx < w
                    and 0 <= y + dy < h
                    and px[x + dx, y + dy][3] == 0
                    for dx in (-1, 0, 1)
                    for dy in (-1, 0, 1)
                    if dx or dy
                )
                if near_trans and r <= 32 and g <= 32 and b <= 32:
                    clear.append((x, y))
        for x, y in clear:
            px[x, y] = (0, 0, 0, 0)


def main() -> None:
    src = Image.open(MASTER).convert("RGBA")
    out = src.copy()
    flood_outer_black(out)
    defringe(out)
    out.save(OUT, format="PNG", optimize=True)

    px = out.load()
    w, h = out.size
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    transparent = sum(1 for y in range(h) for x in range(w) if px[x, y][3] == 0)
    print(f"Wrote {OUT}")
    print(f"corners={corners} transparent_pixels={transparent}")


if __name__ == "__main__":
    main()
