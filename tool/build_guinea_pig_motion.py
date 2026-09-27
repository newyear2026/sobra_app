#!/usr/bin/env python3
"""Cut the approved guinea-pig pose strips into app-sized sprite sheets.

Generated artwork stays in design/characters/guinea-pig/generated-v1. This
script only extracts, cleans and aligns those poses; it does not synthesize
new character art or duplicate a paw to create motion.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/guinea-pig"
RAW = SOURCE / "generated-v1"
OUTPUT = ROOT / "assets/characters/guinea-pig"
PREVIEWS = SOURCE / "previews"
FRAME_WIDTH = 320
FRAME_HEIGHT = 360
BASELINE = 344
SAFE_MARGIN = 16
VISIBLE_ALPHA = 96

COUNTS = {
    "idle": 8,
    "activity": 12,
    "processing": 12,
    "positive": 12,
    "success": 12,
    "warning": 8,
}
TARGET_HEIGHTS = {
    "idle": [300, 301, 300, 299, 299, 300, 301, 300],
    "activity": [285] * 12,
    "processing": [300] * 12,
    "positive": [295] * 12,
    "success": [300, 300, 300, 300, 296, 294, 294, 294, 294, 300, 300, 300],
    "warning": [300] * 8,
}
SUCCESS_LIFTS = [0, 0, 0, 0, 4, 14, 22, 24, 15, 0, 0, 0]
POSTERS = {
    "idle": 0,
    "activity": 4,
    "processing": 4,
    "positive": 6,
    "success": 7,
    "warning": 3,
}
DURATIONS_MS = {
    "idle": 2800,
    "activity": 1800,
    "processing": 3600,
    "positive": 4000,
    "success": 2200,
    "warning": 1600,
}


def split_cells(role: str, count: int) -> list[Image.Image]:
    sheet = Image.open(RAW / f"{role}-{count}-raw.png").convert("RGBA")
    alpha = sheet.getchannel("A")
    pixels = alpha.load()
    occupancy = [
        sum(pixels[x, y] >= VISIBLE_ALPHA for y in range(sheet.height))
        for x in range(sheet.width)
    ]
    cell_width = sheet.width / count
    radius = max(7, round(cell_width * 0.09))
    boundaries = [0]
    for index in range(1, count):
        expected = round(index * cell_width)
        boundary = min(
            range(expected - radius, expected + radius + 1),
            key=lambda x: (occupancy[x], abs(x - expected)),
        )
        boundaries.append(boundary)
    boundaries.append(sheet.width)
    return [
        sheet.crop((boundaries[i], 0, boundaries[i + 1], sheet.height))
        for i in range(count)
    ]


def clean_cell(cell: Image.Image) -> Image.Image:
    """Remove faint generation noise and tiny cut-boundary fragments."""
    cell = cell.copy()
    alpha = cell.getchannel("A").point(lambda value: 0 if value < 32 else value)
    cell.putalpha(alpha)
    width, height = cell.size
    active = bytearray(value >= VISIBLE_ALPHA for value in alpha.getdata())
    seen = bytearray(width * height)
    draw = ImageDraw.Draw(cell)
    for start in range(width * height):
        if not active[start] or seen[start]:
            continue
        pending = [start]
        seen[start] = 1
        points = []
        while pending:
            point = pending.pop()
            points.append(point)
            x, y = point % width, point // width
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbour = ny * width + nx
                    if active[neighbour] and not seen[neighbour]:
                        seen[neighbour] = 1
                        pending.append(neighbour)
        if len(points) < 80:
            for point in points:
                draw.point((point % width, point // width), fill=(0, 0, 0, 0))
    return cell


def normalize(role: str, cells: list[Image.Image]) -> list[Image.Image]:
    frames = []
    for index, cell in enumerate(cells):
        cell = clean_cell(cell)
        bounds = cell.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"{role} frame {index + 1} is empty")
        art = cell.crop(bounds)
        scale = min(
            TARGET_HEIGHTS[role][index] / art.height,
            (FRAME_WIDTH - 2 * SAFE_MARGIN) / art.width,
        )
        art = art.resize(
            (round(art.width * scale), round(art.height * scale)),
            Image.Resampling.NEAREST,
        )
        lift = SUCCESS_LIFTS[index] if role == "success" else 0
        lift = min(lift, BASELINE - art.height - SAFE_MARGIN)
        frame = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT))
        frame.alpha_composite(
            art,
            ((FRAME_WIDTH - art.width) // 2, BASELINE - art.height - lift),
        )
        left, top, right, bottom = frame.getchannel("A").getbbox()
        if (left < SAFE_MARGIN or top < SAFE_MARGIN or
                right > FRAME_WIDTH - SAFE_MARGIN or
                bottom > FRAME_HEIGHT - SAFE_MARGIN):
            raise ValueError(f"{role} frame {index + 1} outside safe area")
        frames.append(frame)
    if len({frame.tobytes() for frame in frames}) < len(frames) // 2:
        raise ValueError(f"{role} has too few distinct frames")
    return frames


def preview_frame(frame: Image.Image) -> Image.Image:
    background = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    background.alpha_composite(frame)
    return background.convert("RGB")


def save_gif(path: Path, frames: list[Image.Image], duration_ms: int) -> None:
    preview = [preview_frame(frame) for frame in frames]
    preview[0].save(
        path, save_all=True, append_images=preview[1:],
        duration=round(duration_ms / len(preview)), loop=0, optimize=True,
    )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    all_frames = {}
    contact = Image.new(
        "RGBA", (FRAME_WIDTH * len(COUNTS), FRAME_HEIGHT),
        (255, 250, 242, 255),
    )
    for column, (role, count) in enumerate(COUNTS.items()):
        frames = normalize(role, split_cells(role, count))
        all_frames[role] = frames
        sheet = Image.new("RGBA", (FRAME_WIDTH * count, FRAME_HEIGHT))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (index * FRAME_WIDTH, 0))
        output = OUTPUT / f"{role}-{count}.png"
        sheet.save(output, optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (column * FRAME_WIDTH, 0))
        save_gif(PREVIEWS / f"{role}.gif", frames, DURATIONS_MS[role])
        print(f"{role}: {count} frames -> {output.relative_to(ROOT)}")
    contact.save(SOURCE / "motion-contact.png", optimize=True)

    font = ImageFont.truetype(str(ROOT / "assets/fonts/PixelifySans.ttf"), 24)
    combined = []
    panel_height = FRAME_HEIGHT + 30
    for tick in range(12):
        preview = Image.new(
            "RGBA", (FRAME_WIDTH * 3, panel_height * 2),
            (255, 250, 242, 255),
        )
        draw = ImageDraw.Draw(preview)
        for slot, (role, count) in enumerate(COUNTS.items()):
            x, y = slot % 3 * FRAME_WIDTH, slot // 3 * panel_height
            draw.text((x + 20, y + 2), f"{role.upper()}  {count}F",
                      font=font, fill=(30, 45, 75, 255))
            preview.alpha_composite(
                all_frames[role][tick * count // 12], (x, y + 30)
            )
        combined.append(preview)
    save_gif(SOURCE / "motion-preview.gif", combined, 1800)


if __name__ == "__main__":
    main()
