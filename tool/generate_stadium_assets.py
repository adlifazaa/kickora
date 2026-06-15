"""Generate bundled stadium banner JPEGs (local assets, no runtime network)."""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent.parent / "assets" / "stadiums"

STADIUMS = [
    ("metlife.jpg", "MetLife Stadium", "East Rutherford, USA", (26, 58, 107)),
    ("att.jpg", "AT&T Stadium", "Arlington, USA", (0, 53, 148)),
    ("sofi.jpg", "SoFi Stadium", "Inglewood, USA", (0, 128, 200)),
    ("mercedes_benz.jpg", "Mercedes-Benz Stadium", "Atlanta, USA", (139, 0, 0)),
    ("hard_rock.jpg", "Hard Rock Stadium", "Miami Gardens, USA", (0, 142, 151)),
    ("nrg.jpg", "NRG Stadium", "Houston, USA", (3, 32, 47)),
    ("lincoln_financial.jpg", "Lincoln Financial Field", "Philadelphia, USA", (0, 76, 84)),
    ("levis.jpg", "Levi's Stadium", "Santa Clara, USA", (170, 0, 0)),
    ("lumen.jpg", "Lumen Field", "Seattle, USA", (0, 34, 68)),
    ("arrowhead.jpg", "Arrowhead Stadium", "Kansas City, USA", (227, 24, 55)),
    ("gillette.jpg", "Gillette Stadium", "Foxborough, USA", (0, 34, 68)),
    ("bmo.jpg", "BMO Field", "Toronto, Canada", (206, 17, 65)),
    ("bc_place.jpg", "BC Place", "Vancouver, Canada", (0, 32, 91)),
    ("azteca.jpg", "Estadio Azteca", "Mexico City, Mexico", (0, 104, 71)),
    ("akron.jpg", "Estadio Akron", "Guadalajara, Mexico", (139, 0, 0)),
    ("bbva.jpg", "Estadio BBVA", "Monterrey, Mexico", (0, 75, 135)),
]

W, H = 640, 360


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    try:
        font_l = ImageFont.truetype("arialbd.ttf", 34)
        font_s = ImageFont.truetype("arial.ttf", 22)
    except OSError:
        font_l = ImageFont.load_default()
        font_s = ImageFont.load_default()

    for fname, name, city, rgb in STADIUMS:
        img = Image.new("RGB", (W, H))
        px = img.load()
        for y in range(H):
            t = y / max(H - 1, 1)
            for x in range(W):
                r = int(rgb[0] * (1 - t * 0.45))
                g = int(rgb[1] * (1 - t * 0.45))
                b = int(rgb[2] * (1 - t * 0.45))
                px[x, y] = (max(0, r), max(0, g), max(0, b))

        draw = ImageDraw.Draw(img)
        draw.rectangle([40, H - 90, W - 40, H - 30], fill=(18, 92, 60))
        draw.rectangle([40, H - 90, W - 40, H - 30], outline=(220, 220, 220), width=2)
        draw.line([W // 2, H - 90, W // 2, H - 30], fill=(220, 220, 220), width=2)
        draw.text((36, 36), name, fill=(255, 255, 255), font=font_l)
        draw.text((36, 82), city, fill=(230, 230, 230), font=font_s)
        draw.text((36, H - 125), "FIFA World Cup 2026", fill=(212, 175, 55), font=font_s)

        path = OUT / fname
        img.save(path, "JPEG", quality=88, optimize=True)
        print(f"Wrote {fname} ({path.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
