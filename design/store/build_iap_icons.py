#!/usr/bin/env python3
"""Build the 512x512 Play Console icons for the one-time products.

Matches the set first made for Tranqui, Lana and Pico: a flat pastel field
in one of the app's soft tokens, the companion's first idle frame scaled
up (Lanczos, as the first set was) until its longer side is 400 px, feet
on one line, and a hard-edged oval shadow 28 steps darker than the field.
Play asks for no text in product icons, so there is none.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
CHARACTERS = ROOT / "assets/characters"
OUTPUT = ROOT / "design/store/iap-icons"

SIZE = 512
FRAME_WIDTH = 320
LONG_SIDE = 400
FEET_Y = 465
SHADOW = (106, 438, 406, 476)
SHADOW_DARKEN = 28

# One soft token each, so no two neighbours in the store share a field.
CASH_SOFT = (247, 233, 206)
VIOLET_SOFT = (231, 220, 240)
TEAL_SOFT = (216, 237, 234)
DANGER_SOFT = (251, 225, 218)

PRODUCTS = {
    "sobra.character.capybara": ("capybara", CASH_SOFT),
    "sobra.character.alpaca": ("alpaca", VIOLET_SOFT),
    "sobra.character.platypus": ("platypus", TEAL_SOFT),
    "sobra.character.rabbit": ("rabbit", DANGER_SOFT),
}


def build(product_id: str, character: str, field: tuple[int, int, int]) -> Path:
    sheet = Image.open(CHARACTERS / character / "idle-8.png").convert("RGBA")
    frame = sheet.crop((0, 0, FRAME_WIDTH, sheet.height))
    sprite = frame.crop(frame.getbbox())
    scale = LONG_SIDE / max(sprite.size)
    sprite = sprite.resize(
        (round(sprite.width * scale), round(sprite.height * scale)),
        Image.Resampling.LANCZOS,
    )

    icon = Image.new("RGBA", (SIZE, SIZE), (*field, 255))
    shadow = tuple(channel - SHADOW_DARKEN for channel in field)
    ImageDraw.Draw(icon).ellipse(SHADOW, fill=(*shadow, 255))
    icon.alpha_composite(
        sprite,
        ((SIZE - sprite.width) // 2, FEET_Y + 1 - sprite.height),
    )

    OUTPUT.mkdir(parents=True, exist_ok=True)
    path = OUTPUT / f"{product_id}-512.png"
    icon.save(path, optimize=True)
    return path


def main() -> None:
    for product_id, (character, field) in PRODUCTS.items():
        path = build(product_id, character, field)
        print(f"{path.relative_to(ROOT)}  {path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
