"""Generate neutral launcher PNGs until final art exists at assets/branding/final/app_icon_1024.png.

Run: python tool/generate_neutral_launcher_assets.py
Then for production: replace final master and run dart run flutter_launcher_icons
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"

BG = (8, 10, 15, 255)
TEAL = (0, 209, 193, 255)
WHITE = (255, 255, 255, 255)


def _draw_neutral_icon(size: int, *, legacy_square: bool) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pad = size * 0.08
    box = (pad, pad, size - pad, size - pad)
    if legacy_square:
        draw.rounded_rectangle(box, radius=size * 0.22, fill=BG)
    cx = cy = size / 2
    r = size * 0.28
    draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=TEAL)
    pentagon = []
    for i in range(5):
        angle = math.radians(-90 + i * 72)
        pentagon.append((cx + r * 0.55 * math.cos(angle), cy + r * 0.55 * math.sin(angle)))
    draw.polygon(pentagon, fill=WHITE)
    inner = size * 0.1
    draw.ellipse((cx - inner, cy - inner, cx + inner, cy + inner), fill=BG)
    return img


def _write_mipmap(name: str, size: int) -> None:
    folder = ANDROID_RES / name
    folder.mkdir(parents=True, exist_ok=True)
    icon = _draw_neutral_icon(size, legacy_square=True)
    icon.save(folder / "ic_launcher.png")


def _write_master() -> Path:
    final_dir = ROOT / "assets" / "branding" / "final"
    final_dir.mkdir(parents=True, exist_ok=True)
    master = _draw_neutral_icon(1024, legacy_square=True)
    path = final_dir / "app_icon_1024_NEUTRAL_TEMP.png"
    master.save(path)
    return path


def main() -> None:
    densities = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in densities.items():
        _write_mipmap(folder, px)

    master = _write_master()
    print(f"Wrote neutral launcher mipmaps under {ANDROID_RES}")
    print(f"Temporary master (do not ship): {master}")
    print("Production: replace assets/branding/final/app_icon_1024.png and run flutter_launcher_icons")


if __name__ == "__main__":
    main()
