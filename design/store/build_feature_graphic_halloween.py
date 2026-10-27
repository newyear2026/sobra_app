"""Builds the Halloween variant of the Play feature graphic (1024x500), es only.

It is the showcase layout with the phones swapped for the costumes: the offer
on the left, six friends in their costumes on the right. It is meant to run in
the listing only while the gift can be claimed (until 3 Nov 2026), then the
regular graphic goes back.

The night is the one the in-app announcement card draws (_CostumeNight in
release_announcement.dart): the same plum sky, square stars and moon, laid over
the icon's grid field so the banner still belongs to the icon above it.

The friends are the first pose of each costume sheet, so they are the exact
art the gift sheet shows, not a repaint. The lineup leads with Michi in front,
flanked by the pumpkin and the ghost as on the Instagram poster, and puts the
catrina and the calavera musician in the back row for Día de Muertos, which
falls inside the event.

Like the showcase, this fills the width, so a promo video's play button would
land on the edge of the back row. Michi, the title and the date stay clear of
it.
"""

from __future__ import annotations

import importlib.util
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
COSTUMES = ROOT / "assets" / "costumes" / "autumn_2026"


def _showcase():
    """The showcase build, imported for its field, font and shadow helpers."""
    spec = importlib.util.spec_from_file_location(
        "build_feature_graphic_showcase", HERE / "build_feature_graphic_showcase.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


showcase = _showcase()

WIDTH, HEIGHT = 1024, 500

SKY = (0x2B, 0x25, 0x50)      # _CostumeNight._sky
STAR = (0xF7, 0xE9, 0xCE)     # _CostumeNight._star
MOON = (0xF2, 0xD5, 0x8A)     # _CostumeNight._moon
PUMPKIN = (0xF2, 0x9A, 0x3A)  # the jack-o'-lantern in the costume art
GLOW = (0xF2, 0x9A, 0x3A)
OUTLINE = (0x14, 0x19, 0x2E)  # showcase.FRAME
PILL = (0x84, 0x5A, 0x1E)     # AppColors.cashInk

TITLE = ["Disfraces de", "Halloween"]
OFFER = "¡12 GRATIS!"
DATE = "Hasta el 3 de nov."
KEEP = "Tuyos para siempre"

COLUMN_X = 262

# (character, height, centre). Back row first so the front row overlaps it.
FRIENDS = [
    ("alpaca", 168, (612, 236)),
    ("rabbit", 168, (742, 214)),
    ("penguin", 172, (864, 222)),
    ("guinea-pig", 172, (624, 366)),
    ("maltese", 172, (868, 366)),
    ("michi", 222, (752, 344)),
]

STARS = [(72, 58), (180, 34), (402, 70), (468, 30), (560, 104), (650, 44),
         (962, 160), (990, 60), (36, 300), (470, 420), (128, 470)]


def first_pose(character: str) -> Image.Image:
    """The sheet's first frame, trimmed to the character."""
    layout = json.loads((COSTUMES / "layout.json").read_text())[character]
    sheet = Image.open(COSTUMES / f"{character}.png").convert("RGBA")
    x, y, w, h = layout["frames"][0]
    width, height = sheet.size
    frame = sheet.crop((round(x * width), round(y * height),
                        round((x + w) * width), round((y + h) * height)))
    return frame.crop(frame.getbbox())


def night() -> Image.Image:
    """The grid field under a plum sky that fades out toward the ground."""
    field = showcase.base.grid_field(WIDTH, HEIGHT)
    fade = Image.new("L", (1, HEIGHT))
    for y in range(HEIGHT):
        fade.putpixel((0, y), round(235 * max(0.0, 1 - y / (HEIGHT * 0.85))))
    sky = Image.new("RGBA", (WIDTH, HEIGHT), (*SKY, 255))
    sky.putalpha(fade.resize((WIDTH, HEIGHT)))
    field.alpha_composite(sky)

    # Lantern light pooling under the friends.
    glow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([520, 330, 990, 500], fill=(*GLOW, 150))
    field.alpha_composite(glow.filter(ImageFilter.GaussianBlur(48)))

    pen = ImageDraw.Draw(field)
    for x, y in STARS:
        pen.rectangle([x, y, x + 4, y + 4], fill=(*STAR, 255))
    moon = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    ImageDraw.Draw(moon).ellipse([846, 52, 910, 116], fill=(*MOON, 90))
    field.alpha_composite(moon.filter(ImageFilter.GaussianBlur(14)))
    pen.ellipse([856, 62, 900, 106], fill=(*MOON, 255))
    return field


def outlined(pen: ImageDraw.ImageDraw, xy, text: str, font, fill, stroke: int) -> None:
    pen.text(xy, text, font=font, fill=(*fill, 255), anchor="mm",
             stroke_width=stroke, stroke_fill=(*OUTLINE, 255))


def main() -> None:
    banner = night()

    for character, height, centre in FRIENDS:
        art = first_pose(character)
        art = art.resize((round(art.width * height / art.height), height), Image.LANCZOS)
        art = showcase.lifted(art, blur=10, drop=6, alpha=110)
        banner.alpha_composite(art, (round(centre[0] - art.width / 2),
                                     round(centre[1] - art.height / 2)))

    pen = ImageDraw.Draw(banner)
    title = showcase.pixel_font(46, 700)
    for line, y in zip(TITLE, (118, 168)):
        outlined(pen, (COLUMN_X, y), line, title, showcase.PAPER, 4)
    outlined(pen, (COLUMN_X, 246), OFFER, showcase.pixel_font(74, 700), PUMPKIN, 6)

    date = showcase.pixel_font(26, 600)
    left, top, right, bottom = pen.textbbox((COLUMN_X, 330), DATE, font=date, anchor="mm")
    pen.rectangle([left - 20, top - 14, right + 20, bottom + 14],
                  fill=(*PILL, 255), outline=(*STAR, 255), width=3)
    pen.text((COLUMN_X, 330), DATE, font=date, fill=(*STAR, 255), anchor="mm")
    pen.text((COLUMN_X, 386), KEEP, font=showcase.pixel_font(23, 500),
             fill=(*showcase.TAGLINE, 255), anchor="mm")

    out = HERE / "sobrita-feature-graphic-halloween-es-1024x500.png"
    banner.convert("RGB").save(out)   # RGB because Play rejects an alpha channel
    print(f"wrote {out.name}")


if __name__ == "__main__":
    main()
