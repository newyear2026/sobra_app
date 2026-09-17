"""Builds the Play Console feature graphic (1024x500) from the icon's own parts.

The banner has to sit directly above the icon in the store listing, so it is
built from the same two things the icon is built from — the grid field and the
calico — rather than from new art that would only approximately match.

Two constraints shape the layout, and they pull in the same direction:

  * Play overlays a play button over the DEAD CENTRE when a promo video is set.
  * Some surfaces crop the outer edges, so content wants to stay inside roughly
    the central 80% (x 102..922, y 50..450).

So the composition is deliberately hollow in the middle: the calico sits left of
centre, a rising trail of coins sits right of it, and the gap between them is
where the play button lands. If no video is ever added, the gap still reads as
the space the coins are climbing through.

There is no text. The listing prints the app name immediately under this image,
and going textless means one asset serves en-US, es and ko instead of three.

The grid is drawn at the icon's own 32px pitch rather than at a fixed number of
cells, so the graph paper is the same size in both images and the pair looks
like two crops of one sheet.
"""

from __future__ import annotations

import importlib.util
from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent


def _icons():
    """The icon builder, imported for its palette and its character loader."""
    path = HERE.parent / "icon" / "build_icons.py"
    spec = importlib.util.spec_from_file_location("build_icons", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)  # main() is __main__-guarded, so this is inert
    return module


icons = _icons()

WIDTH, HEIGHT = 1024, 500
CELL = 32          # the icon's pitch: 1024 / GRID_CELLS

CAT_HEIGHT = 375
CAT_CENTRE = (268, 258)   # left edge lands on the safe bound, x=102

# Diameter and centre of each coin, big to small. The trail starts at the
# calico's feet and climbs to the top right, which reads as savings growing and
# also threads the play button: the first coin clears its lower edge (y=320) and
# every later one is right of its right edge (x=582).
COINS = [
    (104, (520, 382)),
    (86, (650, 300)),
    (70, (762, 228)),
    (56, (858, 168)),
]

# Where the coin lives inside the bbox-cropped character art. The source file is
# fixed art, so these are stable; the colour test below then drops the cream
# calculator face the coin is drawn on top of, leaving the coin free-standing.
COIN_BOX = (464, 644, 681, 866)


def grid_field(width: int, height: int) -> Image.Image:
    """Navy with the icon's faint graph-paper grid, at the icon's pitch."""
    field = Image.new("RGBA", (width, height), (*icons.NAVY, 255))
    lines = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    pen = ImageDraw.Draw(lines)
    stroke = max(1, round(width / 512))
    ink = (*icons.GRID, icons.GRID_ALPHA)
    for x in range(CELL, width, CELL):
        pen.line([(x, 0), (x, height)], fill=ink, width=stroke)
    for y in range(CELL, height, CELL):
        pen.line([(0, y), (width, y)], fill=ink, width=stroke)
    return Image.alpha_composite(field, lines)


def coin() -> Image.Image:
    """The coin from the calculator, lifted off the face it is drawn on."""
    art = icons.character()
    crop = art.crop(COIN_BOX).copy()
    px = crop.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b, a = px[x, y]
            gold = r > 190 and 110 < g < 240 and b < 130 and r - b > 80
            brown = 60 < r < 150 and 25 < g < 95 and b < 55 and r - b > 40
            if not (a > 100 and (gold or brown)):
                px[x, y] = (0, 0, 0, 0)
    return crop.crop(crop.getbbox())


def paste_centred(canvas: Image.Image, art: Image.Image, centre, height=None, width=None):
    if height is not None:
        scale = height / art.height
    else:
        scale = width / art.width
    art = art.resize((round(art.width * scale), round(art.height * scale)), Image.LANCZOS)
    cx, cy = centre
    canvas.alpha_composite(art, (round(cx - art.width / 2), round(cy - art.height / 2)))


def main() -> None:
    banner = grid_field(WIDTH, HEIGHT)

    paste_centred(banner, icons.character(), CAT_CENTRE, height=CAT_HEIGHT)

    money = coin()
    for diameter, centre in COINS:
        paste_centred(banner, money, centre, width=diameter)

    out = HERE / "sobrita-feature-graphic-1024x500.png"
    banner.convert("RGB").save(out)   # RGB because Play rejects an alpha channel
    print(f"wrote {out.name}")


if __name__ == "__main__":
    main()
