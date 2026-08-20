"""Build Play Console screenshots from raw captures.

Phone:  1080 x 1920  (9:16)
7-inch: 1920 x 1080  (16:9)
10-inch: 2560 x 1440 (16:9)

JPEG or 24-bit PNG, no alpha. Taglines stay under 20% of the frame.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "store-assets" / "screenshots" / "_source"
OUT_ROOT = ROOT / "store-assets" / "screenshots"

PHONE = (1080, 1920)
TABLET_7 = (1920, 1080)
TABLET_10 = (2560, 1440)

FONT_BOLD = Path(r"C:\Windows\Fonts\segoeuib.ttf")
FONT_REG = Path(r"C:\Windows\Fonts\segoeui.ttf")

LIGHT = {
    "bg": (232, 236, 248),
    "blob": (79, 126, 255, 38),
    "blob2": (52, 196, 124, 28),
    "dot": (79, 126, 255, 70),
    "title": (26, 26, 46),
    "sub": (90, 96, 122),
    "accent": (79, 126, 255),
    "card": (255, 255, 255),
    "bezel": (255, 255, 255),
    "shadow": (36, 46, 88, 40),
}
DARK = {
    "bg": (18, 22, 38),
    "blob": (107, 147, 255, 48),
    "blob2": (61, 219, 143, 28),
    "dot": (107, 147, 255, 80),
    "title": (244, 243, 238),
    "sub": (168, 174, 196),
    "accent": (107, 147, 255),
    "card": (21, 24, 33),
    "bezel": (28, 32, 48),
    "shadow": (0, 0, 0, 50),
}

SLIDES = [
    {
        "id": "01_your_month",
        "source": "screenshot_1.jpeg",
        "theme": LIGHT,
        "title": "Your month, clearly",
        "sub": "Tap a day to mark yourself present",
        "focus": "full",
    },
    {
        "id": "02_progress",
        "source": "screenshot_1.jpeg",
        "theme": LIGHT,
        "title": "Progress you can see",
        "sub": "Present days and a monthly percentage",
        "focus": "stats",
    },
    {
        "id": "03_dark_mode",
        "source": "screenshot_2.jpeg",
        "theme": DARK,
        "title": "A calm dark mode",
        "sub": "Easy on the eyes. Same simple flow.",
        "focus": "full",
    },
    {
        "id": "04_on_device",
        "source": "screenshot_2.jpeg",
        "theme": DARK,
        "title": "Just you and your calendar",
        "sub": "Attendance stays on your device",
        "focus": "full",
    },
]


def font(path: Path, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(path), size)


def round_corners(im: Image.Image, radius: int) -> Image.Image:
    im = im.convert("RGBA")
    w, h = im.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    im.putalpha(mask)
    return im


def fit_contain(im: Image.Image, box: tuple[int, int]) -> Image.Image:
    bw, bh = box
    scale = min(bw / im.width, bh / im.height)
    nw, nh = max(1, int(im.width * scale)), max(1, int(im.height * scale))
    return im.resize((nw, nh), Image.Resampling.LANCZOS)


def make_shadow(
    size: tuple[int, int],
    radius: int,
    color: tuple[int, int, int, int],
    blur: int,
    offset: tuple[int, int] = (0, 8),
) -> tuple[Image.Image, tuple[int, int]]:
    """Soft rounded shadow. Keep blur small so the halo follows the curve, not a square."""
    w, h = size
    pad = blur * 3 + 12
    canvas = (w + pad * 2, h + pad * 2)
    alpha = Image.new("L", canvas, 0)
    ImageDraw.Draw(alpha).rounded_rectangle(
        (pad, pad, pad + w - 1, pad + h - 1),
        radius=radius,
        fill=color[3],
    )
    if blur > 0:
        alpha = alpha.filter(ImageFilter.GaussianBlur(blur))
    shadow = Image.new("RGBA", canvas, (*color[:3], 0))
    shadow.putalpha(alpha)
    origin = (pad - offset[0], pad - offset[1])
    return shadow, origin


def screenshot_card(src: Image.Image, max_box: tuple[int, int], focus: str, radius: int) -> Image.Image:
    if focus == "stats":
        src = src.crop((0, int(src.height * 0.10), src.width, src.height))
    shot = fit_contain(src, max_box)
    return round_corners(shot, radius)


def paste_card(
    canvas: Image.Image,
    card: Image.Image,
    xy: tuple[int, int],
    radius: int,
    shadow_color: tuple[int, int, int, int],
    blur: int,
) -> Image.Image:
    shadow, origin = make_shadow(card.size, radius, shadow_color, blur)
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sx, sy = xy[0] - origin[0], xy[1] - origin[1]
    layer.paste(shadow, (sx, sy), shadow)
    layer.paste(card, xy, card)
    return Image.alpha_composite(canvas.convert("RGBA"), layer)


def decorate(canvas: Image.Image, theme: dict) -> Image.Image:
    w, h = canvas.size
    overlay = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse((-int(w * 0.28), -int(h * 0.18), int(w * 0.55), int(h * 0.38)), fill=theme["blob"])
    d.ellipse((int(w * 0.55), int(h * 0.62), int(w * 1.22), int(h * 1.18)), fill=theme["blob2"])
    r = max(6, w // 90)
    gap = r * 3
    ox, oy = int(w * 0.78), int(h * 0.08)
    for i in range(3):
        for j in range(4):
            x = ox + i * gap
            y = oy + j * gap
            d.ellipse((x, y, x + r, y + r), fill=theme["dot"])
    return Image.alpha_composite(canvas.convert("RGBA"), overlay)


def wrap_text(draw: ImageDraw.ImageDraw, text: str, fnt, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        trial = word if not current else f"{current} {word}"
        if draw.textlength(trial, font=fnt) <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines or [text]


def draw_text_block(
    overlay: Image.Image,
    theme: dict,
    title: str,
    sub: str,
    box: tuple[int, int, int, int],
    title_size: int,
    sub_size: int,
    align: str = "center",
) -> None:
    d = ImageDraw.Draw(overlay)
    x0, y0, x1, y1 = box
    max_w = x1 - x0
    tf = font(FONT_BOLD, title_size)
    sf = font(FONT_REG, sub_size)
    title_lines = wrap_text(d, title, tf, max_w)
    sub_lines = wrap_text(d, sub, sf, max_w)
    line_h = int(title_size * 1.12)
    sub_h = int(sub_size * 1.28)
    gap = int(title_size * 0.28)
    accent_h = max(6, title_size // 10)
    block_h = accent_h + int(title_size * 0.35) + len(title_lines) * line_h + gap + len(sub_lines) * sub_h
    y = y0 + max(0, (y1 - y0 - block_h) // 2)

    bar_w = max(48, title_size * 2)
    if align == "left":
        bx = x0
    else:
        bx = x0 + (max_w - bar_w) // 2
    d.rounded_rectangle((bx, y, bx + bar_w, y + accent_h), radius=accent_h // 2, fill=theme["accent"] + (255,))
    y += accent_h + int(title_size * 0.32)

    for line in title_lines:
        tw = d.textlength(line, font=tf)
        x = x0 if align == "left" else x0 + (max_w - tw) / 2
        d.text((x, y), line, font=tf, fill=theme["title"] + (255,))
        y += line_h
    y += gap
    for line in sub_lines:
        tw = d.textlength(line, font=sf)
        x = x0 if align == "left" else x0 + (max_w - tw) / 2
        d.text((x, y), line, font=sf, fill=theme["sub"] + (255,))
        y += sub_h


def compose_portrait(slide: dict, src: Image.Image, size: tuple[int, int]) -> Image.Image:
    w, h = size
    theme = slide["theme"]
    canvas = Image.new("RGB", size, theme["bg"])
    canvas = decorate(canvas, theme)

    text_h = int(h * 0.18)
    side = int(w * 0.10)
    bottom = int(h * 0.05)
    max_box = (w - side * 2, h - text_h - bottom)
    radius = max(40, min(max_box) // 16)
    card = screenshot_card(src, max_box, slide["focus"], radius)
    xy = ((w - card.width) // 2, text_h + (max_box[1] - card.height) // 2)

    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_text_block(
        overlay,
        theme,
        slide["title"],
        slide["sub"],
        (int(w * 0.08), int(h * 0.03), int(w * 0.92), text_h),
        title_size=max(42, w // 16),
        sub_size=max(22, w // 30),
        align="center",
    )

    out = paste_card(canvas, card, xy, radius, theme["shadow"], blur=max(8, w // 90))
    out = Image.alpha_composite(out, overlay)
    return out.convert("RGB")


def compose_landscape(slide: dict, src: Image.Image, size: tuple[int, int]) -> Image.Image:
    w, h = size
    theme = slide["theme"]
    canvas = Image.new("RGB", size, theme["bg"])
    canvas = decorate(canvas, theme)

    left_w = int(w * 0.40)
    margin = int(h * 0.08)
    max_box = (w - left_w - margin, h - margin * 2)
    radius = max(32, min(max_box) // 16)
    card = screenshot_card(src, max_box, slide["focus"], radius)
    xy = (w - margin - card.width, (h - card.height) // 2)

    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw_text_block(
        overlay,
        theme,
        slide["title"],
        slide["sub"],
        (int(w * 0.05), int(h * 0.18), left_w - int(w * 0.02), int(h * 0.82)),
        title_size=max(40, h // 12),
        sub_size=max(20, h // 22),
        align="left",
    )

    out = paste_card(canvas, card, xy, radius, theme["shadow"], blur=max(8, h // 80))
    out = Image.alpha_composite(out, overlay)
    return out.convert("RGB")


def save_rgb(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    im.convert("RGB").save(path, format="PNG", optimize=True)
    print(f"  {path.relative_to(ROOT)}  {im.size[0]}x{im.size[1]}")


def main() -> None:
    sources = {
        "screenshot_1.jpeg": Image.open(SOURCE_DIR / "screenshot_1.jpeg").convert("RGB"),
        "screenshot_2.jpeg": Image.open(SOURCE_DIR / "screenshot_2.jpeg").convert("RGB"),
    }

    jobs = [
        ("phone", PHONE, compose_portrait),
        ("tablet-7", TABLET_7, compose_landscape),
        ("tablet-10", TABLET_10, compose_landscape),
    ]

    for folder, size, composer in jobs:
        print(f"\n{folder} {size[0]}x{size[1]}")
        out_dir = OUT_ROOT / folder
        out_dir.mkdir(parents=True, exist_ok=True)
        for slide in SLIDES:
            src = sources[slide["source"]]
            frame = composer(slide, src, size)
            save_rgb(frame, out_dir / f"{slide['id']}.png")


if __name__ == "__main__":
    main()
