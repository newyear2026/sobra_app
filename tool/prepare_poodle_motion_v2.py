#!/usr/bin/env python3
"""Normalize generated poodle frame strips and build review GIFs.

The source strips are image-generation outputs with equal horizontal cells but
large transparent margins.  This keeps every pose's relative movement while
converting them to Sobra's 320x360 per-frame contract.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_RAW_DIR = ROOT / 'design' / 'animations' / 'poodle-generated-v2'
DEFAULT_OUTPUT_DIR = ROOT / 'design' / 'animations' / 'poodle-motion-v2'
RAW_DIR = DEFAULT_RAW_DIR
OUTPUT_DIR = DEFAULT_OUTPUT_DIR
FONT_PATH = ROOT / 'assets' / 'fonts' / 'PixelifySans.ttf'

FRAME_SIZE = (320, 360)
SAFE_MARGIN = 16
BASELINE_Y = 344
ALPHA_CLEANUP = 24
ALPHA_BOUNDS = 96


@dataclass(frozen=True)
class Motion:
    name: str
    frame_count: int
    duration_ms: int


MOTIONS = (
    Motion('idle', 8, 350),
    Motion('activity', 12, 150),
    Motion('processing', 12, 300),
    Motion('positive', 12, 330),
    Motion('success', 12, 185),
    Motion('warning', 8, 200),
)


def _threshold_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    alpha = image.getchannel('A').point(
        lambda value: 255 if value >= ALPHA_BOUNDS else 0
    )
    return alpha.getbbox()


def _clean_alpha(image: Image.Image) -> Image.Image:
    rgba = image.convert('RGBA')
    alpha = rgba.getchannel('A').point(
        lambda value: 0 if value < ALPHA_CLEANUP else value
    )
    rgba.putalpha(alpha)
    return rgba


def _source_cells(motion: Motion) -> list[Image.Image]:
    path = RAW_DIR / f'{motion.name}-{motion.frame_count}-raw.png'
    source = Image.open(path).convert('RGBA')
    mask = source.getchannel('A').point(
        lambda value: 255 if value >= ALPHA_BOUNDS else 0
    )

    # Image generation leaves transparent separator columns between almost
    # every pose, but props or sparkles occasionally bridge one separator.
    # Use real transparent runs when present and a narrow inset around the
    # mathematically expected boundary when they are bridged.  This prevents
    # a piece of the neighbouring pose appearing at either edge of a frame.
    gap_runs: list[tuple[int, int]] = []
    gap_start: int | None = None
    for x in range(source.width + 1):
        empty = x < source.width and mask.crop((x, 0, x + 1, source.height)).getbbox() is None
        if empty and gap_start is None:
            gap_start = x
        elif not empty and gap_start is not None:
            if x - gap_start >= 3:
                gap_runs.append((gap_start, x - 1))
            gap_start = None

    separators: list[tuple[int, int]] = []
    tolerance = source.width / motion.frame_count * 0.28
    for index in range(motion.frame_count + 1):
        expected = round(index * source.width / motion.frame_count)
        nearby = [
            run
            for run in gap_runs
            if abs((run[0] + run[1]) / 2 - expected) <= tolerance
        ]
        if nearby:
            separators.append(
                min(nearby, key=lambda run: abs((run[0] + run[1]) / 2 - expected))
            )
        elif index == 0:
            separators.append((-1, -1))
        elif index == motion.frame_count:
            separators.append((source.width, source.width))
        else:
            inset = max(4, round(source.width / motion.frame_count * 0.035))
            separators.append((expected - inset, expected + inset))

    cells: list[Image.Image] = []
    for index in range(motion.frame_count):
        left = separators[index][1] + 1
        right = separators[index + 1][0]
        cells.append(_clean_alpha(source.crop((left, 0, right, source.height))))
    return cells


def normalize(motion: Motion) -> list[Image.Image]:
    cells = _source_cells(motion)
    boxes = [_threshold_bbox(cell) for cell in cells]
    if any(box is None for box in boxes):
        raise ValueError(f'{motion.name}: one or more generated frames are empty')

    visible_boxes = [box for box in boxes if box is not None]
    top = min(box[1] for box in visible_boxes)
    bottom = max(box[3] for box in visible_boxes)
    source_width = max(cell.width for cell in cells)
    source_height = bottom - top
    scale = min(
        (FRAME_SIZE[0] - SAFE_MARGIN * 2) / source_width,
        (FRAME_SIZE[1] - SAFE_MARGIN * 2) / source_height,
    )

    frames: list[Image.Image] = []
    for cell in cells:
        region = cell.crop((0, top, cell.width, bottom))
        resized = region.resize(
            (round(region.width * scale), round(region.height * scale)),
            Image.Resampling.NEAREST,
        )
        frame = Image.new('RGBA', FRAME_SIZE)
        left = (FRAME_SIZE[0] - resized.width) // 2
        upper = BASELINE_Y - resized.height
        frame.alpha_composite(resized, (left, upper))
        frames.append(frame)
    return frames


def save_sheet(motion: Motion, frames: list[Image.Image]) -> Path:
    sheet = Image.new('RGBA', (FRAME_SIZE[0] * motion.frame_count, FRAME_SIZE[1]))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (index * FRAME_SIZE[0], 0))
    path = OUTPUT_DIR / f'{motion.name}-{motion.frame_count}.png'
    sheet.save(path)
    return path


def save_gif(motion: Motion, frames: list[Image.Image]) -> Path:
    path = OUTPUT_DIR / f'{motion.name}.gif'
    paletted = [frame.convert('P', palette=Image.Palette.ADAPTIVE) for frame in frames]
    paletted[0].save(
        path,
        save_all=True,
        append_images=paletted[1:],
        duration=motion.duration_ms,
        loop=0,
        disposal=2,
        transparency=0,
    )
    return path


def save_combined_preview(all_frames: dict[str, list[Image.Image]]) -> Path:
    panel_width = 330
    panel_height = 330
    title_height = 62
    canvas_size = (panel_width * 3, title_height + panel_height * 2)
    background = (252, 250, 238, 255)
    ink = (25, 45, 83, 255)
    teal = (0, 126, 130, 255)
    title_font = ImageFont.truetype(str(FONT_PATH), 34)
    label_font = ImageFont.truetype(str(FONT_PATH), 24)
    preview_frames: list[Image.Image] = []

    for timeline_index in range(24):
        canvas = Image.new('RGBA', canvas_size, background)
        draw = ImageDraw.Draw(canvas)
        draw.text((22, 13), 'SOBRA POODLE', font=title_font, fill=ink)
        draw.text((370, 23), 'FRAME-BY-FRAME MOTION V2', font=label_font, fill=teal)

        for motion_index, motion in enumerate(MOTIONS):
            column = motion_index % 3
            row = motion_index // 3
            left = column * panel_width
            top = title_height + row * panel_height
            draw.rounded_rectangle(
                (left + 7, top + 6, left + panel_width - 7, top + panel_height - 7),
                radius=11,
                fill=(255, 253, 246, 255),
                outline=(224, 215, 189, 255),
                width=2,
            )
            label = motion.name.upper()
            label_box = draw.textbbox((0, 0), label, font=label_font)
            draw.text(
                (left + (panel_width - label_box[2] + label_box[0]) // 2, top + 12),
                label,
                font=label_font,
                fill=ink,
            )

            frames = all_frames[motion.name]
            # The 24-step review timeline gives 8-frame motions three holds and
            # 12-frame motions two holds per source frame.
            frame_index = timeline_index * len(frames) // 24
            sprite = frames[frame_index].resize((240, 270), Image.Resampling.NEAREST)
            canvas.alpha_composite(sprite, (left + 45, top + 50))
        preview_frames.append(canvas)

    path = OUTPUT_DIR / 'poodle-motion-preview-v2.gif'
    paletted = [frame.convert('P', palette=Image.Palette.ADAPTIVE) for frame in preview_frames]
    paletted[0].save(
        path,
        save_all=True,
        append_images=paletted[1:],
        duration=95,
        loop=0,
        disposal=2,
    )
    preview_frames[8].convert('RGB').save(
        OUTPUT_DIR / 'poodle-motion-preview-v2.png'
    )
    return path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--raw-dir', type=Path, default=DEFAULT_RAW_DIR)
    parser.add_argument('--output-dir', type=Path, default=DEFAULT_OUTPUT_DIR)
    args = parser.parse_args()

    global RAW_DIR, OUTPUT_DIR
    RAW_DIR = args.raw_dir.resolve()
    OUTPUT_DIR = args.output_dir.resolve()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    all_frames: dict[str, list[Image.Image]] = {}
    for motion in MOTIONS:
        frames = normalize(motion)
        all_frames[motion.name] = frames
        print(save_sheet(motion, frames))
        print(save_gif(motion, frames))
    print(save_combined_preview(all_frames))


if __name__ == '__main__':
    main()
