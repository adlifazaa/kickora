"""Crop white padding and add transparency to world_cup_badge.png."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "images" / "world_cup_badge.png"
OUT = SRC
CANVAS = 1024
FILL_RATIO = 0.90


def luminance(r: int, g: int, b: int) -> float:
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def is_background(r: int, g: int, b: int, a: int = 255) -> bool:
    if a == 0:
        return True
    # Outer padding, anti-aliased white fringe, and soft drop shadow on white.
    if r >= 235 and g >= 235 and b >= 235:
        return True
    if luminance(r, g, b) >= 245 and max(r, g, b) - min(r, g, b) <= 18:
        return True
    return False


def flood_background_mask(rgba: Image.Image) -> list[list[bool]]:
    w, h = rgba.size
    px = rgba.load()
    bg = [[False] * w for _ in range(h)]
    q: deque[tuple[int, int]] = deque()

    def try_seed(x: int, y: int) -> None:
        r, g, b, a = px[x, y]
        if is_background(r, g, b, a):
            bg[y][x] = True
            q.append((x, y))

    for x in range(w):
        try_seed(x, 0)
        try_seed(x, h - 1)
    for y in range(h):
        try_seed(0, y)
        try_seed(w - 1, y)

    while q:
        x, y = q.popleft()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not bg[ny][nx]:
                r, g, b, a = px[nx, ny]
                if is_background(r, g, b, a):
                    bg[ny][nx] = True
                    q.append((nx, ny))
    return bg


def cleanup_semi_transparent_fringe(out: Image.Image) -> None:
    px = out.load()
    w, h = out.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            sat = max(r, g, b) - min(r, g, b)
            lum = luminance(r, g, b)
            if a < 250 and sat <= 24 and 150 <= lum <= 230:
                px[x, y] = (0, 0, 0, 0)


def defringe(out: Image.Image, passes: int = 10) -> None:
    """Remove light halos and semi-transparent fringe from former white background."""
    px = out.load()
    w, h = out.size
    for _ in range(passes):
        to_clear: list[tuple[int, int]] = []
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a == 0:
                    continue
                lum = luminance(r, g, b)
                sat = max(r, g, b) - min(r, g, b)
                near_trans = False
                for dx in range(-2, 3):
                    for dy in range(-2, 3):
                        if dx == 0 and dy == 0:
                            continue
                        nx, ny = x + dx, y + dy
                        if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] == 0:
                            near_trans = True
                            break
                    if near_trans:
                        break
                if near_trans and sat <= 28 and lum >= 150:
                    to_clear.append((x, y))
                elif a < 235 and lum >= 180 and sat <= 35:
                    to_clear.append((x, y))
        for x, y in to_clear:
            px[x, y] = (0, 0, 0, 0)
    cleanup_semi_transparent_fringe(out)


def main() -> None:
    # Re-process from repo if backup missing: use current file only when already processed.
    # For re-run, user should restore original; here we work on whatever is at SRC.
    src = Image.open(SRC).convert("RGBA")
    w, h = src.size
    bg = flood_background_mask(src)
    out = src.copy()
    px = out.load()

    for y in range(h):
        for x in range(w):
            if bg[y][x]:
                px[x, y] = (px[x, y][0], px[x, y][1], px[x, y][2], 0)

    defringe(out, passes=10)

    min_x, min_y, max_x, max_y = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 8:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)

    cropped = out.crop((min_x, min_y, max_x + 1, max_y + 1))
    cw, ch = cropped.size
    side = max(cw, ch)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.paste(cropped, ((side - cw) // 2, (side - ch) // 2))

    target = int(CANVAS * FILL_RATIO)
    square = square.resize((target, target), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    offset = (CANVAS - target) // 2
    canvas.paste(square, (offset, offset), square)
    canvas.save(OUT, format="PNG", optimize=True)
    print(f"Saved {OUT} ({CANVAS}x{CANVAS}, fill={FILL_RATIO:.0%})")


if __name__ == "__main__":
    main()
