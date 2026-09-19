#!/usr/bin/env python3
"""Build a motion-preview GIF from the supplied Sobra Poodle concept sheet.

This is deliberately a review prototype, not a production sprite exporter: it
keeps the six approved concept poses and gives each one a simple, readable
pixel-style movement so the motion direction can be approved before drawing
full frame-by-frame sheets.
"""

from __future__ import annotations

import math
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path('/Users/jaewook/Downloads/dog_image.png')
OUT_DIR = ROOT / 'design' / 'animations'
GIF_PATH = OUT_DIR / 'poodle-motion-preview.gif'
STILL_PATH = OUT_DIR / 'poodle-motion-preview.png'
FONT_PATH = ROOT / 'assets' / 'fonts' / 'PixelifySans.ttf'

PANEL_W = 360
PANEL_H = 310
HEADER_H = 72
CANVAS_SIZE = (PANEL_W * 3, HEADER_H + PANEL_H * 2)
BACKGROUND = (252, 250, 238, 255)
INK = (25, 45, 83, 255)
TEAL = (0, 126, 130, 255)
GOLD = (246, 172, 42, 255)

# x0, y0, x1, y1 — labels are intentionally excluded.
CROPS = {
    'IDLE': (700, 110, 975, 426),
    'ACTIVITY': (1004, 121, 1328, 425),
    'PROCESSING': (1372, 112, 1662, 430),
    'POSITIVE': (698, 480, 1005, 808),
    'SUCCESS': (1003, 482, 1337, 808),
    'WARNING': (1368, 482, 1652, 808),
}


def remove_connected_background(source: Image.Image) -> Image.Image:
    """Make the pale concept-sheet background transparent without erasing fur."""
    image = source.convert('RGBA')
    pixels = image.load()
    width, height = image.size
    seeds = []
    for x in range(width):
        seeds.extend(((x, 0), (x, height - 1)))
    for y in range(height):
        seeds.extend(((0, y), (width - 1, y)))

    background = image.getpixel((0, 0))[:3]
    queue = deque(seeds)
    seen: set[tuple[int, int]] = set()
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < width and 0 <= y < height):
            continue
        seen.add((x, y))
        red, green, blue, alpha = pixels[x, y]
        # The page is a very pale, low-saturation cream.  White muzzle and
        # chest pixels remain protected by their dark outline (not connected
        # to the crop edge), while the pale page becomes transparent.
        distance = abs(red - background[0]) + abs(green - background[1]) + abs(blue - background[2])
        if distance > 34 or alpha == 0:
            continue
        pixels[x, y] = (red, green, blue, 0)
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return image


def contain(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    result = Image.new('RGBA', size)
    alpha_box = image.getchannel('A').getbbox()
    if alpha_box is None:
        return result
    art = image.crop(alpha_box)
    scale = min(size[0] / art.width, size[1] / art.height)
    target = (round(art.width * scale), round(art.height * scale))
    art = art.resize(target, Image.Resampling.NEAREST)
    result.alpha_composite(art, ((size[0] - target[0]) // 2, (size[1] - target[1]) // 2))
    return result


def shift(image: Image.Image, x: int, y: int, scale: float = 1.0) -> Image.Image:
    """Nearest-neighbour transform on a fixed, transparent staging canvas."""
    width, height = image.size
    transformed = image
    if scale != 1.0:
        new_size = (round(width * scale), round(height * scale))
        transformed = image.resize(new_size, Image.Resampling.NEAREST)
    canvas = Image.new('RGBA', image.size)
    canvas.alpha_composite(
        transformed,
        ((width - transformed.width) // 2 + x, (height - transformed.height) // 2 + y),
    )
    return canvas


def pixel_star(draw: ImageDraw.ImageDraw, x: int, y: int, color: tuple[int, int, int, int], phase: int) -> None:
    radius = 3 if phase % 2 else 6
    draw.rectangle((x - radius, y - 1, x + radius, y + 1), fill=color)
    draw.rectangle((x - 1, y - radius, x + 1, y + radius), fill=color)
    if radius == 6:
        draw.rectangle((x - 3, y - 3, x + 3, y + 3), fill=color)


def draw_dust(draw: ImageDraw.ImageDraw, x: int, y: int, phase: int) -> None:
    for index, offset in enumerate((0, 16, 31)):
        size = 4 if (phase + index) % 3 else 7
        dx = x - offset - ((phase * 3 + index * 5) % 14)
        dy = y + (index % 2) * 9
        draw.rectangle((dx, dy, dx + size, dy + size), fill=(222, 171, 108, 220))


def draw_coin(draw: ImageDraw.ImageDraw, x: int, y: int) -> None:
    draw.rectangle((x - 8, y - 8, x + 8, y + 8), fill=INK)
    draw.rectangle((x - 6, y - 6, x + 6, y + 6), fill=GOLD)
    draw.rectangle((x - 2, y - 4, x + 3, y + 4), fill=(255, 224, 89, 255))


def place_panel(canvas: Image.Image, name: str, art: Image.Image, frame: int) -> None:
    index = list(CROPS).index(name)
    col, row = index % 3, index // 3
    left = col * PANEL_W
    top = HEADER_H + row * PANEL_H
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        (left + 9, top + 6, left + PANEL_W - 9, top + PANEL_H - 7),
        radius=12,
        fill=(255, 253, 246, 255),
        outline=(224, 215, 189, 255),
        width=2,
    )
    label_font = ImageFont.truetype(str(FONT_PATH), 28)
    label_box = draw.textbbox((0, 0), name, font=label_font)
    draw.text(
        (left + (PANEL_W - (label_box[2] - label_box[0])) // 2, top + 17),
        name,
        font=label_font,
        fill=INK,
    )

    base_x = left + (PANEL_W - art.width) // 2
    base_y = top + 55
    wave = math.sin(frame / 12 * math.tau)
    overlay = Image.new('RGBA', art.size)
    overlay_draw = ImageDraw.Draw(overlay)

    if name == 'IDLE':
        moving = shift(art, 0, round(wave * 4), 1.0 + 0.012 * wave)
        if frame in (4, 5):
            # A quiet blink signal without changing the source character.
            overlay_draw.rectangle((art.width // 2 - 28, 87, art.width // 2 - 16, 91), fill=INK)
            overlay_draw.rectangle((art.width // 2 + 15, 87, art.width // 2 + 27, 91), fill=INK)
    elif name == 'ACTIVITY':
        moving = shift(art, round(wave * 13), 3 if frame % 2 else -1, 1.0)
        draw_dust(overlay_draw, 52, art.height - 44, frame)
    elif name == 'PROCESSING':
        moving = shift(art, 0, round(wave * 3), 1.0)
        if frame % 3 != 0:
            x, y = art.width // 2 + 30, 160
            overlay_draw.rectangle((x - 15, y - 19, x + 15, y + 19), fill=(0, 176, 177, 65))
            overlay_draw.rectangle((x - 9, y - 11, x + 9, y + 11), fill=(65, 234, 225, 120))
    elif name == 'POSITIVE':
        moving = shift(art, 0, 2, 1.0)
        # The coin makes one readable arc, then returns to the bank.
        t = frame / 11
        x = art.width // 2 + round(32 * math.sin(t * math.pi))
        y = art.height - 99 - round(55 * math.sin(t * math.pi))
        draw_coin(overlay_draw, x, y)
    elif name == 'SUCCESS':
        lift = round(-22 * max(0, math.sin(frame / 11 * math.pi)))
        moving = shift(art, 0, lift, 1.0)
        for x, y, p in ((45, 78, 0), (art.width - 48, 65, 1), (55, 170, 2)):
            pixel_star(overlay_draw, x, y + lift, GOLD, frame + p)
    else:  # WARNING
        moving = shift(art, 0, round(4 + abs(wave) * 5), 1.0 - 0.01 * abs(wave))
        if frame in (0, 1, 7, 8):
            x = art.width // 2 + 53
            overlay_draw.rectangle((x - 3, 52, x + 3, 75), fill=GOLD)
            overlay_draw.rectangle((x - 3, 82, x + 3, 88), fill=GOLD)

    moving.alpha_composite(overlay)
    canvas.alpha_composite(moving, (base_x, base_y))


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(f'Missing input image: {SOURCE}')
    if not FONT_PATH.is_file():
        raise FileNotFoundError(f'Missing pixel font: {FONT_PATH}')
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert('RGBA')
    art = {
        name: contain(remove_connected_background(source.crop(bounds)), (255, 218))
        for name, bounds in CROPS.items()
    }
    frames: list[Image.Image] = []
    title_font = ImageFont.truetype(str(FONT_PATH), 40)
    sub_font = ImageFont.truetype(str(FONT_PATH), 20)
    for frame in range(12):
        canvas = Image.new('RGBA', CANVAS_SIZE, BACKGROUND)
        draw = ImageDraw.Draw(canvas)
        draw.text((28, 16), 'SOBRA POODLE', font=title_font, fill=INK)
        draw.text((449, 29), 'MOTION PREVIEW • 6 ROLES', font=sub_font, fill=TEAL)
        for name, sprite in art.items():
            place_panel(canvas, name, sprite, frame)
        frames.append(canvas.convert('P', palette=Image.Palette.ADAPTIVE))
    frames[0].save(
        GIF_PATH,
        save_all=True,
        append_images=frames[1:],
        duration=120,
        loop=0,
        disposal=2,
    )
    frames[6].convert('RGB').save(STILL_PATH)
    print(GIF_PATH)
    print(STILL_PATH)


if __name__ == '__main__':
    main()
