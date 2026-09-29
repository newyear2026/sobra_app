#!/usr/bin/env python3
"""Turn approved alpaca pose strips into six 320x360 character motions."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import (
    body_dimensions,
    rebalance_jump_frame,
    validate_jump_scale,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/alpaca"
RAW = SOURCE / "generated-v1"
OUTPUT = ROOT / "assets/characters/alpaca"
PREVIEWS = SOURCE / "previews"
FRAME_WIDTH = 320
FRAME_HEIGHT = 360
BASELINE = 344
SAFE_MARGIN = 16

COUNTS = {
    "idle": 8,
    "activity": 12,
    "processing": 12,
    "positive": 12,
    "success": 12,
    "warning": 8,
}
TARGET_HEIGHTS = {
    "idle": [300] * 8,
    "activity": [292] * 12,
    # The floor calculator extends below the hooves in perspective. Reserve
    # its extra height so the alpaca itself stays as tall as the idle pose.
    "processing": [320] * 12,
    "positive": [300] * 12,
    "success": [300, 288, 295, 300, 300, 300, 300, 300, 300, 290, 300, 300],
    "warning": [300] * 8,
}
SUCCESS_LIFTS = [0, 0, 0, 8, 15, 24, 16, 8, 0, 0, 0, 0]
POSTERS = {
    "idle": 0,
    "activity": 4,
    "processing": 5,
    "positive": 6,
    "success": 5,
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
    filename = (
        "processing-12-raw-v2.png" if role == "processing"
        else f"{role}-{count}-raw.png"
    )
    sheet = Image.open(RAW / filename).convert("RGBA")
    alpha = sheet.getchannel("A")
    pixels = alpha.load()
    occupancy = [
        sum(pixels[x, y] >= 96 for y in range(sheet.height))
        for x in range(sheet.width)
    ]
    cell_width = sheet.width / count
    radius = round(cell_width * 0.11)
    boundaries = [0]
    for index in range(1, count):
        expected = round(index * cell_width)
        boundaries.append(
            min(
                range(expected - radius, expected + radius + 1),
                key=lambda x: (occupancy[x], abs(x - expected)),
            )
        )
    boundaries.append(sheet.width)
    if boundaries != sorted(set(boundaries)):
        raise ValueError(f"{role}: invalid split boundaries {boundaries}")
    return [
        sheet.crop((boundaries[i], 0, boundaries[i + 1], sheet.height))
        for i in range(count)
    ]


def clean_alpha(cell: Image.Image) -> Image.Image:
    cell = cell.copy()
    data = list(cell.getdata())
    cleaned = []
    for red, green, blue, alpha in data:
        # Generated cutouts can carry red registration specks outside the
        # navy outline. They are not part of the alpaca's cream/pink palette.
        red_speck = red > 190 and green < 100 and blue < 100
        cleaned.append((red, green, blue, 0 if alpha < 32 or red_speck else alpha))
    cell.putdata(cleaned)
    return cell


def visible_bounds(cell: Image.Image) -> tuple[int, int, int, int]:
    alpha = cell.getchannel("A")
    pixels = alpha.load()
    rows = [
        y for y in range(cell.height)
        if sum(pixels[x, y] >= 96 for x in range(cell.width)) >= 5
    ]
    columns = [
        x for x in range(cell.width)
        if sum(pixels[x, y] >= 96 for y in range(cell.height)) >= 4
    ]
    if not rows or not columns:
        raise ValueError("An alpaca frame has no visible pose")
    return min(columns), min(rows), max(columns) + 1, max(rows) + 1


def remove_tiny_islands(frame: Image.Image, role: str) -> Image.Image:
    """Drop isolated cut-boundary flecks without erasing coins or sparkles."""
    width, height = frame.size
    active = bytearray(value >= 32 for value in frame.getchannel("A").getdata())
    visited = bytearray(width * height)
    output = frame.copy()
    draw = ImageDraw.Draw(output)
    minimum = 20 if role == "success" else 120 if role == "warning" else 80
    for start in range(width * height):
        if not active[start] or visited[start]:
            continue
        pending = [start]
        visited[start] = 1
        points = []
        while pending:
            point = pending.pop()
            points.append(point)
            x, y = point % width, point // width
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbour = ny * width + nx
                    if active[neighbour] and not visited[neighbour]:
                        visited[neighbour] = 1
                        pending.append(neighbour)
        if len(points) < minimum:
            for point in points:
                draw.point((point % width, point // width), fill=(0, 0, 0, 0))
    return output


def normalize(role: str, cells: list[Image.Image]) -> list[Image.Image]:
    frames = []
    for index, cell in enumerate(cells):
        cell = clean_alpha(cell)
        art = cell.crop(visible_bounds(cell))
        lift = SUCCESS_LIFTS[index] if role == "success" else 0
        scale = min(
            TARGET_HEIGHTS[role][index] / art.height,
            (FRAME_WIDTH - 2 * SAFE_MARGIN) / art.width,
            (BASELINE - SAFE_MARGIN - lift) / art.height,
        )
        art = art.resize(
            (round(art.width * scale), round(art.height * scale)),
            Image.Resampling.NEAREST,
        )
        frame = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT))
        frame.alpha_composite(
            art,
            ((FRAME_WIDTH - art.width) // 2, BASELINE - art.height - lift),
        )
        frame = remove_tiny_islands(frame, role)
        if frame.getchannel("A").getbbox() is None:
            raise ValueError(f"{role} frame {index + 1} is empty")
        frames.append(frame)

    if role == "success":
        reference = [body_dimensions(frames[i]) for i in (3, 4, 6)]
        reference.sort(key=lambda dimensions: dimensions[0] * dimensions[1])
        target_width, target_height = reference[1]
        width, height = body_dimensions(frames[5])
        if width < target_width * 0.9 or height < target_height * 0.9:
            frames[5] = rebalance_jump_frame(
                frames[5],
                body_size=(target_width, target_height),
                lift=SUCCESS_LIFTS[5],
            )
        validate_jump_scale(
            frames,
            reference_indices=(3, 4, 6),
            jump_indices=(5,),
        )

    for index, frame in enumerate(frames):
        left, top, right, bottom = frame.getchannel("A").getbbox()
        if (left < SAFE_MARGIN or top < SAFE_MARGIN or
                right > FRAME_WIDTH - SAFE_MARGIN or
                bottom > FRAME_HEIGHT - SAFE_MARGIN):
            raise ValueError(f"{role} frame {index + 1} exceeds safe area")
    if len({frame.tobytes() for frame in frames}) < len(frames) // 2:
        raise ValueError(f"{role} has too few distinct poses")
    return frames


def save_gif(path: Path, frames: list[Image.Image], duration_ms: int) -> None:
    preview = []
    for frame in frames:
        background = Image.new("RGBA", frame.size, (255, 250, 242, 255))
        background.alpha_composite(frame)
        preview.append(background.convert("RGB"))
    preview[0].save(
        path,
        save_all=True,
        append_images=preview[1:],
        duration=round(duration_ms / len(preview)),
        loop=0,
        optimize=True,
    )


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    frames_by_role = {}
    contact = Image.new("RGBA", (FRAME_WIDTH * len(COUNTS), FRAME_HEIGHT),
                        (255, 250, 242, 255))
    for column, (role, count) in enumerate(COUNTS.items()):
        frames = normalize(role, split_cells(role, count))
        frames_by_role[role] = frames
        sheet = Image.new("RGBA", (FRAME_WIDTH * count, FRAME_HEIGHT))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (index * FRAME_WIDTH, 0))
        destination = OUTPUT / f"{role}-{count}.png"
        sheet.save(destination, optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (column * FRAME_WIDTH, 0))
        save_gif(PREVIEWS / f"{role}.gif", frames, DURATIONS_MS[role])
        print(f"{role}: {count} frames -> {destination.relative_to(ROOT)}")
    contact.save(SOURCE / "motion-contact.png", optimize=True)

    font = ImageFont.truetype(str(ROOT / "assets/fonts/PixelifySans.ttf"), 24)
    combined = []
    panel_height = FRAME_HEIGHT + 30
    for tick in range(12):
        preview = Image.new("RGBA", (FRAME_WIDTH * 3, panel_height * 2),
                            (255, 250, 242, 255))
        draw = ImageDraw.Draw(preview)
        for slot, (role, count) in enumerate(COUNTS.items()):
            x, y = slot % 3 * FRAME_WIDTH, slot // 3 * panel_height
            draw.text((x + 20, y + 2), f"{role.upper()}  {count}F",
                      font=font, fill=(30, 45, 75, 255))
            preview.alpha_composite(
                frames_by_role[role][tick * count // 12], (x, y + 30)
            )
        combined.append(preview)
    save_gif(SOURCE / "motion-preview.gif", combined, 1800)


if __name__ == "__main__":
    main()
