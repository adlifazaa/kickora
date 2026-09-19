"""Generate Google Play feature graphic (1024x500) for Kickora Arabic.

Run: python tool/generate_feature_graphic.py
Output: assets/branding/final/feature_graphic_1024x500.png
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

try:
    import arabic_reshaper
    from bidi.algorithm import get_display

    def _shape_arabic(text: str) -> str:
        return get_display(arabic_reshaper.reshape(text))

except ImportError:  # pragma: no cover

    def _shape_arabic(text: str) -> str:
        return text

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "branding" / "final" / "feature_graphic_1024x500.png"
ICON = ROOT / "assets" / "branding" / "final" / "app_icon_launcher_transparent.png"
ICON_FALLBACK = ROOT / "assets" / "branding" / "final" / "play_store_icon_512.png"

W, H = 1024, 500

# Kickora brand palette (lib/app/app_colors.dart + launcher green)
DARK_BG = (8, 10, 15)
DARK_SURFACE = (17, 21, 29)
PITCH_TOP = (47, 159, 77)
PITCH_MID = (31, 124, 57)
PITCH_BOTTOM = (18, 77, 35)
LAUNCHER_GREEN = (26, 107, 52)
TEAL = (0, 209, 193)
TEAL_DEEP = (0, 143, 134)
NEON_LIME = (183, 255, 69)
WHITE = (255, 255, 255)


def _lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def _gradient_bg() -> Image.Image:
    img = Image.new("RGB", (W, H))
    px = img.load()
    for y in range(H):
        for x in range(W):
            t = (x / W * 0.55 + y / H * 0.45)
            t = max(0.0, min(1.0, t))
            if t < 0.5:
                u = t / 0.5
                r = _lerp(DARK_BG[0], PITCH_BOTTOM[0], u)
                g = _lerp(DARK_BG[1], PITCH_BOTTOM[1], u)
                b = _lerp(DARK_BG[2], PITCH_BOTTOM[2], u)
            else:
                u = (t - 0.5) / 0.5
                r = _lerp(PITCH_BOTTOM[0], PITCH_MID[0], u)
                g = _lerp(PITCH_BOTTOM[1], PITCH_MID[1], u)
                b = _lerp(PITCH_BOTTOM[2], PITCH_MID[2], u)
            px[x, y] = (r, g, b)
    return img


def _draw_pitch_lines(draw: ImageDraw.ImageDraw, alpha_layer: Image.Image) -> None:
  """Subtle field markings — decorative only, no tournament branding."""
  overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
  od = ImageDraw.Draw(overlay)
  line = (255, 255, 255, 28)
  cx, cy = W * 0.72, H * 0.52
  rx, ry = 340, 200
  od.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=line, width=2)
  od.line((cx - rx, cy, cx + rx, cy), fill=line, width=2)
  od.line((W * 0.45, 0, W * 0.45, H), fill=(255, 255, 255, 18), width=2)
  alpha_layer.alpha_composite(overlay)


def _draw_accent_glow(base: Image.Image) -> Image.Image:
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse((-80, 80, 420, 520), fill=(*TEAL, 35))
    gd.ellipse((680, -60, 1120, 280), fill=(*NEON_LIME, 22))
    glow = glow.filter(ImageFilter.GaussianBlur(48))
    base = base.convert("RGBA")
    base.alpha_composite(glow)
    return base


def _load_font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = []
    if bold:
        candidates += [
            "C:/Windows/Fonts/segoeuib.ttf",
            "C:/Windows/Fonts/arialbd.ttf",
            "C:/Windows/Fonts/tahomabd.ttf",
        ]
    else:
        candidates += [
            "C:/Windows/Fonts/segoeui.ttf",
            "C:/Windows/Fonts/arial.ttf",
            "C:/Windows/Fonts/tahoma.ttf",
            "C:/Windows/Fonts/trado.ttf",
        ]
    for path in candidates:
        p = Path(path)
        if p.exists():
            return ImageFont.truetype(str(p), size=size)
    return ImageFont.load_default()


def _rounded_icon_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def _composite_icon(base: Image.Image) -> Image.Image:
    icon_path = ICON if ICON.exists() else ICON_FALLBACK
    icon = Image.open(icon_path).convert("RGBA")
    size = 300
    icon = icon.resize((size, size), Image.Resampling.LANCZOS)
    mask = _rounded_icon_mask(size, 56)
    icon.putalpha(mask)

    shadow = Image.new("RGBA", (size + 40, size + 40), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((12, 18, size + 12, size + 18), radius=56, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(14))

    x, y = 88, (H - size) // 2
    base = base.convert("RGBA")
    base.alpha_composite(shadow, (x - 8, y - 4))
    base.alpha_composite(icon, (x, y))
    return base


def _draw_text(base: Image.Image) -> Image.Image:
    draw = ImageDraw.Draw(base)
    title_font = _load_font(78, bold=True)
    sub_font = _load_font(42, bold=False)

    title = "Kickora"
    subtitle = _shape_arabic("نتائج كرة القدم مباشرة")

    tx = 430
    ty = 158

    # Soft title shadow
    draw.text((tx + 2, ty + 3), title, font=title_font, fill=(0, 0, 0, 90))
    draw.text((tx, ty), title, font=title_font, fill=WHITE)

    # Teal accent underline
    bbox = draw.textbbox((tx, ty), title, font=title_font)
    draw.rounded_rectangle(
        (tx, bbox[3] + 10, tx + 180, bbox[3] + 14),
        radius=2,
        fill=TEAL,
    )

    sy = bbox[3] + 36
    draw.text((tx + 1, sy + 2), subtitle, font=sub_font, fill=(0, 0, 0, 70))
    draw.text((tx, sy), subtitle, font=sub_font, fill=(235, 245, 240))

    return base


def _draw_speed_streaks(base: Image.Image) -> Image.Image:
    """Echo launcher K-mark energy — abstract, not a logo."""
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    streaks = [
        ((360, 380), (520, 290), (*NEON_LIME, 55)),
        ((380, 400), (540, 310), (*TEAL, 40)),
        ((400, 420), (560, 330), (*WHITE, 25)),
    ]
    for a, b, color in streaks:
        d.polygon([a, (b[0] + 18, b[1]), b, (a[0] + 18, a[1])], fill=color)
    return Image.alpha_composite(base.convert("RGBA"), overlay)


def main() -> None:
    base = _gradient_bg().convert("RGBA")
    base = _draw_accent_glow(base)

    lines = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    _draw_pitch_lines(ImageDraw.Draw(lines), lines)
    base = Image.alpha_composite(base, lines)

    base = _composite_icon(base)
    base = _draw_speed_streaks(base)
    base = _draw_text(base)

    # Subtle vignette for premium depth
    vignette = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rectangle((0, 0, W, H), fill=(0, 0, 0, 0))
    for i in range(24):
        a = int(8 + i * 2.2)
        vd.rectangle((i * 2, i, W - i * 2, H - i), outline=(0, 0, 0, a))
    base = Image.alpha_composite(base, vignette)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    base.convert("RGB").save(OUT, format="PNG", optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
