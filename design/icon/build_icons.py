"""Builds the launcher icon masters from the transparent character art.

The design is the "pixel grid": the calico on the app's ink navy, over a faint
graph-paper grid that reads as pixel-art rather than as a flat tile. Navy is
what makes this work without any frame around the character — the cat's body is
#FCEED3 against #202848, so the silhouette carries itself at any size. (On the
cream field it could not: that pairing is a contrast ratio of about 1.02.)

The grid is deliberately near-invisible at launcher size. It is there for the
1024 store listing, and it costs nothing at 48px because it degrades to flat
navy rather than to mud.

Two masters come out, because the platforms crop differently:

  * iOS and legacy Android get the full square: grid field plus character.
  * Play Console wants that same square at exactly 512, so it is drawn at 512
    rather than downscaled from the 1024: the grid pitch is a function of the
    canvas, so drawing it gives a clean one-pixel line where halving the master
    would smear each two-pixel line across two.
  * Android adaptive splits into two layers. The background is the grid field,
    which can be cropped anywhere without losing anything because the pattern
    is uniform. The foreground is the character alone.

The character's size is quoted against the FINAL VISIBLE icon, not against the
file, so the two platforms match. An adaptive layer is 108dp of which only the
central 72dp (66.7%) is ever drawn, and flutter_launcher_icons wraps the
foreground in `android:inset="16%"` on top of that. ANDROID_PARITY undoes both.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

HERE = Path(__file__).parent
SOURCE = HERE / "sobra-app-icon-foreground-transparent-v1.png"

NAVY = (0x20, 0x28, 0x48)   # AppPalette.ink — the field
GRID = (0x3A, 0x46, 0x78)   # one step up from the field, not a new hue

SIZE = 1024
STORE_SIZE = 512   # Play Console accepts this size and no other
GRID_CELLS = 32      # matches the pixel pitch of the character art
GRID_ALPHA = 84
CAT_SPAN = 0.70      # character height as a fraction of the visible icon

# What the generated `android:inset="16%"` leaves of the foreground drawable.
LAUNCHER_INSET = 0.68
# What an adaptive layer actually shows.
ADAPTIVE_VISIBLE = 2 / 3
# Draw the character this much larger in the foreground file so that, after the
# inset and the crop, it covers the same share of the icon as it does on iOS.
ANDROID_PARITY = ADAPTIVE_VISIBLE / LAUNCHER_INSET


def character() -> Image.Image:
    art = Image.open(SOURCE).convert("RGBA")
    return art.crop(art.getbbox())


def grid_field(size: int) -> Image.Image:
    """Navy with a faint graph-paper grid."""
    field = Image.new("RGBA", (size, size), (*NAVY, 255))
    lines = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pen = ImageDraw.Draw(lines)
    step = size / GRID_CELLS
    width = max(1, round(size / 512))
    for i in range(1, GRID_CELLS):
        at = round(i * step)
        pen.line([(at, 0), (at, size)], fill=(*GRID, GRID_ALPHA), width=width)
        pen.line([(0, at), (size, at)], fill=(*GRID, GRID_ALPHA), width=width)
    return Image.alpha_composite(field, lines)


def place_character(canvas: Image.Image, span: float) -> Image.Image:
    art = character()
    box = canvas.width * span
    scale = min(box / art.width, box / art.height)
    art = art.resize((round(art.width * scale), round(art.height * scale)), Image.LANCZOS)
    canvas.alpha_composite(
        art, ((canvas.width - art.width) // 2, (canvas.height - art.height) // 2)
    )
    return canvas


def main() -> None:
    master = place_character(grid_field(SIZE), CAT_SPAN)
    master.convert("RGB").save(HERE / "sobra-icon-grid-master-1024.png")

    store = place_character(grid_field(STORE_SIZE), CAT_SPAN)
    store.convert("RGB").save(HERE / "sobra-icon-grid-store-512.png")

    grid_field(SIZE).convert("RGB").save(HERE / "sobra-icon-grid-background-1024.png")

    foreground = place_character(
        Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0)), CAT_SPAN * ANDROID_PARITY
    )
    foreground.save(HERE / "sobra-icon-grid-foreground-1024.png")

    for name in ("master", "background", "foreground"):
        print(f"wrote sobra-icon-grid-{name}-1024.png")
    print("wrote sobra-icon-grid-store-512.png")


if __name__ == "__main__":
    main()
