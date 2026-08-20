"""Build Play Console icon and feature graphic from the launcher icon."""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LAUNCHER = ROOT / "assets" / "icon" / "launcher_icon.png"
OUT_ICON = ROOT / "store-assets" / "play-store-icon.png"
OUT_FEATURE = ROOT / "store-assets" / "feature-graphic.png"
OUT_FEATURE_SOURCE = ROOT / "store-assets" / "feature-graphic-source.png"

FONT_BOLD = Path(r"C:\Windows\Fonts\segoeuib.ttf")
FONT_REG = Path(r"C:\Windows\Fonts\segoeui.ttf")

PURPLE_DEEP = (71, 23, 179)
PURPLE_MID = (97, 34, 213)
PURPLE_LIGHT = (147, 59, 248)
GREEN = (61, 219, 143)
CREAM = (244, 243, 238)
MUTED = (226, 214, 255)


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def round_corners(im: Image.Image, radius: int) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    im.putalpha(mask)
    return im


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    w, h = size
    im = Image.new("RGB", size)
    px = im.load()
    for y in range(h):
        t = y / max(1, h - 1)
        color = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = color
    return im


def star(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float, fill) -> None:
    pts = []
    for i in range(8):
        ang = math.radians(i * 45 - 90)
        rad = r if i % 2 == 0 else r * 0.32
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    draw.polygon(pts, fill=fill)


def build_play_icon(src: Image.Image) -> Image.Image:
    icon = src.convert("RGBA").resize((512, 512), Image.Resampling.LANCZOS)
    return icon.filter(ImageFilter.UnsharpMask(radius=0.8, percent=60, threshold=2))


def build_feature_graphic(src: Image.Image) -> Image.Image:
    w, h = 1024, 500
    canvas = vertical_gradient((w, h), PURPLE_LIGHT, PURPLE_DEEP).convert("RGBA")

    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse((-180, -160, 520, 520), fill=(255, 255, 255, 28))
    g.ellipse((620, 220, 1180, 720), fill=(61, 219, 143, 22))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    canvas = Image.alpha_composite(canvas, glow)

    sparks = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sparks)
    for cx, cy, r, a in (
        (86, 78, 11, 170),
        (168, 430, 8, 130),
        (940, 72, 10, 150),
        (980, 250, 7, 110),
        (890, 420, 12, 140),
        (640, 56, 6, 100),
        (400, 460, 7, 90),
    ):
        star(sd, cx, cy, r, (255, 255, 255, a))
        sd.ellipse((cx - r * 0.22, cy - r * 0.22, cx + r * 0.22, cy + r * 0.22), fill=(255, 255, 255, a))
    canvas = Image.alpha_composite(canvas, sparks)

    tile = src.convert("RGBA").resize((288, 288), Image.Resampling.LANCZOS)
    tile = round_corners(tile, 68)
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sh = Image.new("L", (288, 288), 0)
    ImageDraw.Draw(sh).rounded_rectangle((0, 0, 287, 287), radius=68, fill=90)
    sh = sh.filter(ImageFilter.GaussianBlur(10))
    shade = Image.new("RGBA", (288, 288), (20, 8, 50, 0))
    shade.putalpha(sh)
    icon_xy = (92, (h - 288) // 2)
    shadow.paste(shade, (icon_xy[0], icon_xy[1] + 8), shade)
    canvas = Image.alpha_composite(canvas, shadow)
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    layer.paste(tile, icon_xy, tile)
    canvas = Image.alpha_composite(canvas, layer)

    text = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(text)
    title_font = font(FONT_BOLD, 54)
    sub_font = font(FONT_REG, 24)
    title = "Attendance Flow"
    sub = "Track your days. See your progress."
    tx = 420
    tw = d.textlength(title, font=title_font)
    d.rounded_rectangle((tx, 168, tx + 56, 176), radius=4, fill=GREEN + (255,))
    d.text((tx, 192), title, font=title_font, fill=CREAM + (255,))
    d.text((tx, 262), sub, font=sub_font, fill=MUTED + (255,))
    _ = tw
    canvas = Image.alpha_composite(canvas, text)
    return canvas.convert("RGB")


def save_png(im: Image.Image, path: Path) -> None:
    im.save(path, format="PNG", optimize=True)
    print(f"{path.name:28} {im.size[0]}x{im.size[1]} {im.mode} {path.stat().st_size // 1024} KB")


def main() -> None:
    src = Image.open(LAUNCHER)
    icon = build_play_icon(src)
    feature = build_feature_graphic(src)
    save_png(icon, OUT_ICON)
    save_png(feature, OUT_FEATURE)
    save_png(feature, OUT_FEATURE_SOURCE)
    if OUT_ICON.stat().st_size > 1024 * 1024:
        raise SystemExit("Play Store icon exceeds 1024 KB")


if __name__ == "__main__":
    main()
