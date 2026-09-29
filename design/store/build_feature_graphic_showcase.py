"""Builds the showcase variant of the Play feature graphic: icon and name on the
left, two framed screens on the right.

This is the layout most of the comparable apps use (Habicat, Fortune City,
Habit Slayer), and it trades one thing for another. It says what the app is
without the viewer having to guess from a character, but it fills the whole
1024 width, so there is no longer a hole in the middle for the play button Play
overlays when a promo video is set. That overlay would clip the left edge of the
front phone. Nothing readable is lost — the name and the icon sit far to the
left of it — and none of the competing apps clear it either.

Device frames are against Play's own recommendation for this slot. Four of the
six apps surveyed use them anyway; what actually breaks at this size is text
inside the screenshots, so the screens here are chosen for their SHAPE and
colour rather than for anything the viewer is meant to read.

The left column reuses the launcher icon, so whatever the store shows next to
the app name is literally the same artwork.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent


def _minimal():
    """The other feature-graphic build, imported for the grid field and coin."""
    spec = importlib.util.spec_from_file_location(
        "build_feature_graphic", HERE / "build_feature_graphic.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


base = _minimal()

WIDTH, HEIGHT = 1024, 500

PAPER = (0xF6, 0xEF, 0xE0)   # AppPalette.paper — the name
TAGLINE = (0x9F, 0xAC, 0xCE)  # a tint of the field, so it reads as secondary
FRAME = (0x14, 0x19, 0x2E)   # a shade under the field, so the bezel is a shadow

FONT = ROOT / "assets" / "fonts" / "PixelifySans.ttf"

NAME = "Sobrita"
TAGLINE_LINES = ["Track your spending.", "Raise a pixel cat."]

# Two coins from the icon's own artwork, sitting above and below the play
# button's zone rather than beside it. They tie the column to the phones across
# the gap and keep the middle from reading as a hole, without putting anything
# where the overlay would land.
COINS = []

COLUMN_X = 265           # centre of the left column
ICON_SIZE = 128
ICON_Y = 175
NAME_Y = 292
TAGLINE_Y = (347, 379)

# Back phone first, then the front one. Two constraints set the sizes: the front
# phone's left edge has to clear the play button's right edge at 582, and the
# back phone's right edge has to stay inside the crop bound at 922. That leaves
# 330px for two phones, so they are smaller than they would otherwise be and
# overlap by about 20px — enough to read as a pair, little enough that the back
# phone still shows its own content rather than a sliver.
PHONES = [
    ("cash-count.png", 320, (838, 244)),  # back
    ("budget.png", 350, (682, 262)),      # front
]


def pixel_font(size: int, weight: int = 400) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONT), size)
    font.set_variation_by_axes([weight])
    return font


def rounded(art: Image.Image, radius: int) -> Image.Image:
    mask = Image.new("L", art.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, *[v - 1 for v in art.size]], radius, fill=255)
    out = Image.new("RGBA", art.size, (0, 0, 0, 0))
    out.paste(art, (0, 0), mask)
    return out


def phone(screen: str, height: int) -> Image.Image:
    """A screenshot in a plain dark bezel."""
    shot = Image.open(ROOT / "design" / "screens" / screen).convert("RGB")
    width = round(height * shot.width / shot.height)
    shot = shot.resize((width, height), Image.LANCZOS)

    bezel = 5
    frame = Image.new("RGBA", (width + bezel * 2, height + bezel * 2), (0, 0, 0, 0))
    ImageDraw.Draw(frame).rounded_rectangle(
        [0, 0, frame.width - 1, frame.height - 1], radius=round(height * 0.055), fill=(*FRAME, 255)
    )
    frame.paste(shot, (bezel, bezel), rounded(shot.convert("RGBA"), round(height * 0.04)).split()[3])
    return frame


def lifted(art: Image.Image, blur: int = 16, drop: int = 10, alpha: int = 135) -> Image.Image:
    """The art on a transparent pad, with a soft shadow under it.

    The pad is symmetric so the result can still be pasted by its centre.
    """
    pad = blur * 3
    canvas = Image.new("RGBA", (art.width + pad * 2, art.height + pad * 2), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow.paste(Image.new("RGBA", art.size, (0, 0, 0, alpha)), (pad, pad + drop), art.split()[3])
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(art, (pad, pad))
    return canvas


def main() -> None:
    banner = base.grid_field(WIDTH, HEIGHT)

    for screen, height, centre in PHONES:
        art = lifted(phone(screen, height))
        banner.alpha_composite(art, (round(centre[0] - art.width / 2),
                                     round(centre[1] - art.height / 2)))

    money = base.coin()
    for diameter, centre in COINS:
        base.paste_centred(banner, money, centre, width=diameter)

    icon = Image.open(ROOT / "design" / "icon" / "sobra-icon-grid-store-512.png").convert("RGBA")
    icon = rounded(icon.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS), round(ICON_SIZE * 0.22))
    icon = lifted(icon, blur=12, drop=7, alpha=120)
    banner.alpha_composite(icon, (round(COLUMN_X - icon.width / 2), round(ICON_Y - icon.height / 2)))

    pen = ImageDraw.Draw(banner)
    pen.text((COLUMN_X, NAME_Y), NAME, font=pixel_font(60, 700), fill=(*PAPER, 255), anchor="mm")
    for line, y in zip(TAGLINE_LINES, TAGLINE_Y):
        pen.text((COLUMN_X, y), line, font=pixel_font(23, 500), fill=(*TAGLINE, 255), anchor="mm")

    out = HERE / "sobrita-feature-graphic-showcase-1024x500.png"
    banner.convert("RGB").save(out)
    print(f"wrote {out.name}")


if __name__ == "__main__":
    main()
