#!/usr/bin/env python3
"""Slice approved capybara pose strips into the shared 320x360 sprite format.

The source artwork is generated independently for each motion in
design/characters/capybara/generated-v1. This script only cuts, fits and
aligns those poses; it never fabricates or duplicates character limbs.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import rebalance_jump_frame, validate_jump_scale


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/capybara"
RAW = SOURCE / "generated-v1"
OUTPUT = ROOT / "assets/characters/capybara"
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
    "idle": [300] * 8,
    "activity": [292] * 12,
    "processing": [300] * 12,
    "positive": [298] * 12,
    "success": [300, 300, 286, 294, 300, 300, 300, 300, 300, 300, 300, 300],
    "warning": [300] * 8,
}
SUCCESS_LIFTS = [0, 0, 0, 0, 4, 12, 20, 14, 5, 0, 0, 0]
POSTERS = {
    "idle": 0,
    "activity": 4,
    "processing": 5,
    "positive": 6,
    "success": 6,
    "warning": 4,
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
        "success-12-raw-v2.png" if role == "success"
        else f"{role}-{count}-raw.png"
    )
    sheet = Image.open(RAW / filename).convert("RGBA")
    alpha = sheet.getchannel("A")
    pixels = alpha.load()
    occupancy = [
        sum(pixels[x, y] >= VISIBLE_ALPHA for y in range(sheet.height))
        for x in range(sheet.width)
    ]
    runs = []
    start = None
    for x, value in enumerate(occupancy + [0]):
        if value >= 3 and start is None:
            start = x
        elif value < 3 and start is not None:
            if x - start > 10:
                runs.append((start, x))
            start = None
    if len(runs) == count:
        boundaries = [0] + [
            (runs[i - 1][1] + runs[i][0]) // 2 for i in range(1, count)
        ] + [sheet.width]
    else:
        cell_width = sheet.width / count
        radius = round(cell_width * 0.38)
        boundaries = [0]
        for i in range(1, count):
            expected = round(i * cell_width)
            boundary = min(
                range(expected - radius, expected + radius + 1),
                key=lambda x: (occupancy[x], abs(x - expected)),
            )
            boundaries.append(boundary)
        boundaries.append(sheet.width)
    if boundaries != sorted(set(boundaries)):
        raise ValueError(f"{role}: invalid split boundaries: {boundaries}")
    return [
        sheet.crop((boundaries[i], 0, boundaries[i + 1], sheet.height))
        for i in range(count)
    ]


def clean_alpha(cell: Image.Image) -> Image.Image:
    cell = cell.copy()
    alpha = cell.getchannel("A").point(lambda a: 0 if a < 32 else a)
    cell.putalpha(alpha)
    return cell


def visible_bounds(cell: Image.Image) -> tuple[int, int, int, int]:
    """Ignore isolated generation specks when sizing a source pose."""
    alpha = cell.getchannel("A")
    pixels = alpha.load()
    rows = [
        y for y in range(cell.height)
        if sum(pixels[x, y] >= VISIBLE_ALPHA for x in range(cell.width)) >= 5
    ]
    columns = [
        x for x in range(cell.width)
        if sum(pixels[x, y] >= VISIBLE_ALPHA for y in range(cell.height)) >= 4
    ]
    if not rows or not columns:
        raise ValueError("A capybara frame has no visible character")
    return min(columns), min(rows), max(columns) + 1, max(rows) + 1


def remove_edge_islands(frame: Image.Image) -> Image.Image:
    """Erase isolated pieces of a neighbour cut at a sprite-cell boundary."""
    width, height = frame.size
    active = bytearray(a >= 32 for a in frame.getchannel("A").getdata())
    seen = bytearray(width * height)
    components = []
    for start in range(width * height):
        if not active[start] or seen[start]:
            continue
        pending = [start]
        seen[start] = 1
        pixels = []
        left, right = width, 0
        while pending:
            point = pending.pop()
            pixels.append(point)
            x, y = point % width, point // width
            left, right = min(left, x), max(right, x)
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbour = ny * width + nx
                    if active[neighbour] and not seen[neighbour]:
                        seen[neighbour] = 1
                        pending.append(neighbour)
        components.append((pixels, left, right))
    if not components:
        return frame
    largest = max(range(len(components)), key=lambda i: len(components[i][0]))
    output = frame.copy()
    draw = ImageDraw.Draw(output)
    for i, (pixels, left, right) in enumerate(components):
        if i == largest or not (left < 80 or right >= width - 80):
            continue
        for point in pixels:
            draw.point((point % width, point // width), fill=(0, 0, 0, 0))
    return output


def normalize(role: str, cells: list[Image.Image]) -> list[Image.Image]:
    frames = []
    for index, cell in enumerate(cells):
        cell = clean_alpha(cell)
        bounds = visible_bounds(cell)
        art = cell.crop(bounds)
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
        if role in {"idle", "activity", "success", "warning"}:
            frame = remove_edge_islands(frame)
        if role == "success" and index == 6:
            frame = rebalance_jump_frame(
                frame, body_size=(238, 288), lift=12
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
        if role == "success":
            validate_jump_scale(
                frames, reference_indices=(4, 5, 7), jump_indices=(6,)
            )
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
