"""Export idle frames from Flutter character sheets for Android RemoteViews.

Run from the repository root with Pillow installed. The widget cannot read
Flutter assets directly, so its native drawables are derived from the same art.
"""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "android/app/src/main/res/drawable-nodpi"
CHARACTERS = ("michi", "poodle", "schnauzer", "guinea-pig")
FRAME_INDICES = (0, 2, 4, 6)
FRAME_WIDTH = 320
FRAME_HEIGHT = 360


def main() -> None:
    for character in CHARACTERS:
        sheet = Image.open(ROOT / f"assets/characters/{character}/idle-8.png")
        if sheet.size != (8 * FRAME_WIDTH, FRAME_HEIGHT):
            raise ValueError(f"Unexpected idle sheet size for {character}: {sheet.size}")
        for number, index in enumerate(FRAME_INDICES, start=1):
            frame = sheet.crop(
                (index * FRAME_WIDTH, 0, (index + 1) * FRAME_WIDTH, FRAME_HEIGHT)
            )
            frame = frame.resize((160, 180), Image.Resampling.NEAREST)
            name = character.replace("-", "_")
            frame.save(OUTPUT / f"widget_{name}_{number}.png", optimize=True)


if __name__ == "__main__":
    main()
