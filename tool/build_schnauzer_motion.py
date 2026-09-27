#!/usr/bin/env python3
"""Normalize the approved, frame-by-frame Schnauzer art for the app.

The generated strips live under design/characters/schnauzer/generated-v2.
This build only cuts and aligns their existing poses; it never invents paws or
stretches a single pose across the whole animation.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/schnauzer"
RAW = SOURCE / "generated-v2"
OUTPUT = ROOT / "assets/characters/schnauzer"
PREVIEWS = SOURCE / "previews"
FRAME_WIDTH = 320
FRAME_HEIGHT = 360
BASELINE = 344
SAFE_MARGIN = 16
ALPHA_CUTOFF = 32
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
    "idle": [320, 320, 319, 318, 319, 320, 320, 320],
    "activity": [310] * 12,
    "processing": [315] * 12,
    "positive": [318] * 12,
    "success": [320, 320, 304, 292, 305, 315, 315, 315, 315, 300, 312, 320],
    "warning": [320] * 8,
}

SUCCESS_LIFTS = [0, 0, 0, 0, 0, 3, 10, 18, 8, 0, 0, 0]
POSTERS = {
    "idle": 0,
    "activity": 0,
    "processing": 7,
    "positive": 8,
    "success": 11,
    "warning": 7,
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
    path = RAW / f"{role}-{count}-raw.png"
    sheet = Image.open(path).convert("RGBA")
    alpha = sheet.getchannel("A")
    pixels = alpha.load()
    opaque_per_column = [
        sum(pixels[x, y] >= VISIBLE_ALPHA for y in range(sheet.height))
        for x in range(sheet.width)
    ]

    # A beard or raised paw can cross an exact mathematical cell boundary.
    # Cut at the least occupied nearby column so a neighbour stays separate.
    boundaries = [0]
    cell_width = sheet.width / count
    search_radius = max(8, round(cell_width * 0.11))
    for index in range(1, count):
        expected = round(index * cell_width)
        candidates = range(
            expected - search_radius, expected + search_radius + 1
        )
        boundary = min(
            candidates,
            key=lambda x: (opaque_per_column[x], abs(x - expected)),
        )
        boundaries.append(boundary)
    boundaries.append(sheet.width)
    return [
        sheet.crop((boundaries[i], 0, boundaries[i + 1], sheet.height))
        for i in range(count)
    ]


def visible_bounds(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    pixels = alpha.load()
    rows = [
        y for y in range(image.height)
        if sum(pixels[x, y] >= VISIBLE_ALPHA for x in range(image.width)) >= 5
    ]
    columns = [
        x for x in range(image.width)
        if sum(pixels[x, y] >= VISIBLE_ALPHA for y in range(image.height)) >= 4
    ]
    if not rows or not columns:
        raise ValueError("A generated Schnauzer frame has no visible dog")
    return min(columns), min(rows), max(columns) + 1, max(rows) + 1


def remove_edge_fragments(cell: Image.Image) -> Image.Image:
    """Discard tiny pieces of a neighbouring pose at a cut boundary."""
    width, height = cell.size
    active = bytearray(
        value >= VISIBLE_ALPHA for value in cell.getchannel("A").getdata()
    )
    seen = bytearray(width * height)
    output = cell.copy()
    draw = ImageDraw.Draw(output)
    edge_width = 12
    for y in range(height):
        for x in (*range(edge_width), *range(width - edge_width, width)):
            start = y * width + x
            if not active[start] or seen[start]:
                continue
            pending = [start]
            seen[start] = 1
            size = 0
            left, top, right, bottom = width, height, 0, 0
            while pending:
                point = pending.pop()
                px, py = point % width, point // width
                size += 1
                left, top = min(left, px), min(top, py)
                right, bottom = max(right, px), max(bottom, py)
                for ny in range(max(0, py - 1), min(height, py + 2)):
                    for nx in range(max(0, px - 1), min(width, px + 2)):
                        neighbour = ny * width + nx
                        if active[neighbour] and not seen[neighbour]:
                            seen[neighbour] = 1
                            pending.append(neighbour)
            if size < 800:
                draw.rectangle((left, top, right, bottom), fill=(0, 0, 0, 0))
    return output


def normalize(role: str, cells: list[Image.Image]) -> list[Image.Image]:
    frames = []
    for index, cell in enumerate(cells):
        cell = remove_edge_fragments(cell)
        art = cell.crop(visible_bounds(cell))
        alpha = art.getchannel("A").point(
            lambda value: 0 if value < ALPHA_CUTOFF else value
        )
        art.putalpha(alpha)
        scale = min(
            TARGET_HEIGHTS[role][index] / art.height,
            (FRAME_WIDTH - SAFE_MARGIN * 2) / art.width,
        )
        art = art.resize(
            (round(art.width * scale), round(art.height * scale)),
            Image.Resampling.NEAREST,
        )
        requested_lift = SUCCESS_LIFTS[index] if role == "success" else 0
        lift = min(requested_lift, BASELINE - art.height - SAFE_MARGIN)
        frame = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT))
        frame.alpha_composite(
            art,
            ((FRAME_WIDTH - art.width) // 2, BASELINE - art.height - lift),
        )
        bounds = frame.getchannel("A").getbbox()
        if bounds is None:
            raise ValueError(f"{role} frame {index} is empty")
        left, top, right, bottom = bounds
        if (left < SAFE_MARGIN or top < SAFE_MARGIN or
                right > FRAME_WIDTH - SAFE_MARGIN or
                bottom > FRAME_HEIGHT - SAFE_MARGIN):
            raise ValueError(f"{role} frame {index} leaves safe area: {bounds}")
        frames.append(frame)
    if len({frame.tobytes() for frame in frames}) < len(frames) // 2:
        raise ValueError(f"{role} lacks distinct motion frames")
    return frames


def on_preview_background(frame: Image.Image) -> Image.Image:
    background = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    background.alpha_composite(frame)
    return background.convert("RGB")


def save_gif(path: Path, frames: list[Image.Image], duration_ms: int) -> None:
    preview = [on_preview_background(frame) for frame in frames]
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
    all_frames: dict[str, list[Image.Image]] = {}
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
        path = OUTPUT / f"{role}-{count}.png"
        sheet.save(path, optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (column * FRAME_WIDTH, 0))
        save_gif(PREVIEWS / f"{role}.gif", frames, DURATIONS_MS[role])
        print(f"{role}: {count} distinct frames -> {path.relative_to(ROOT)}")

    contact.save(SOURCE / "motion-contact.png", optimize=True)
    combined = []
    panel_height = FRAME_HEIGHT + 30
    font = ImageFont.truetype(
        str(ROOT / "assets/fonts/PixelifySans.ttf"), 24
    )
    for tick in range(12):
        preview = Image.new(
            "RGBA", (FRAME_WIDTH * 3, panel_height * 2),
            (255, 250, 242, 255),
        )
        draw = ImageDraw.Draw(preview)
        for slot, (role, count) in enumerate(COUNTS.items()):
            x = (slot % 3) * FRAME_WIDTH
            y = (slot // 3) * panel_height
            draw.text((x + 20, y + 2), f"{role.upper()}  {count}F",
                      font=font, fill=(30, 45, 75, 255))
            preview.alpha_composite(
                all_frames[role][tick * count // 12],
                (x, y + 30),
            )
        combined.append(preview)
    save_gif(SOURCE / "motion-preview.gif", combined, 1800)


if __name__ == "__main__":
    main()
