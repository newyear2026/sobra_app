#!/usr/bin/env python3
"""Build the silver Dutch rabbit's six 320x360 motion sprite sheets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import _components, body_dimensions, validate_jump_scale


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/rabbit"
RAW = SOURCE / "generated-v1"
OUTPUT = ROOT / "assets/characters/rabbit"
PREVIEWS = SOURCE / "previews"
WIDTH, HEIGHT, BASELINE, MARGIN = 320, 360, 344, 16
COUNTS = {"idle": 8, "activity": 12, "processing": 12,
          "positive": 12, "success": 12, "warning": 8}
DURATIONS = {"idle": 2800, "activity": 1800, "processing": 3600,
             "positive": 4000, "success": 2200, "warning": 1600}
POSTERS = {"idle": 0, "activity": 5, "processing": 4,
           "positive": 8, "success": 5, "warning": 4}
LIFTS = {
    "activity": [0, 0, 4, 14, 25, 32, 20, 9, 0, 0, 0, 0],
    "success": [0, 0, 2, 10, 22, 27, 16, 6, 0, 0, 0, 0],
}


def bounds_of(image: Image.Image) -> tuple[int, int, int, int]:
    mask = image.getchannel("A").point(lambda a: 255 if a >= 40 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("Empty rabbit frame")
    return bounds


def split_row(row: Image.Image, columns: int) -> list[Image.Image]:
    alpha = row.getchannel("A")
    pixels = alpha.load()
    occupancy = [sum(pixels[x, y] >= 64 for y in range(row.height))
                 for x in range(row.width)]
    cell_width = row.width / columns
    boundaries = [0]
    for i in range(1, columns):
        expected = round(i * cell_width)
        radius = round(cell_width * .22)
        boundaries.append(min(
            range(expected - radius, expected + radius + 1),
            key=lambda x: (occupancy[x], abs(x - expected)),
        ))
    boundaries.append(row.width)
    if boundaries != sorted(set(boundaries)):
        raise ValueError(f"Invalid rabbit cell boundaries: {boundaries}")
    return [row.crop((boundaries[i], 0, boundaries[i + 1], row.height))
            for i in range(columns)]


def cells(role: str, count: int) -> list[Image.Image]:
    strip = Image.open(RAW / f"{role}-{count}-raw.png").convert("RGBA")
    # Calculator and savings illustrations use two rows so full props fit.
    rows = 2 if role in {"processing", "positive"} else 1
    result = []
    for row in range(rows):
        top = round(row * strip.height / rows)
        bottom = round((row + 1) * strip.height / rows)
        result.extend(split_row(strip.crop((0, top, strip.width, bottom)),
                                count // rows))
    if len(result) != count:
        raise ValueError(f"{role}: expected {count} frames, got {len(result)}")
    return result


def main_component_bounds(art: Image.Image) -> tuple[int, int, int, int]:
    main = max(_components(art), key=len)
    return (min(x for x, _ in main), min(y for _, y in main),
            max(x for x, _ in main) + 1, max(y for _, y in main) + 1)


def remove_neighbor_fragments(cell: Image.Image, role: str) -> Image.Image:
    """Discard disconnected scraps clipped from the next contact-sheet pose."""
    if role == "success":
        return cell
    components = _components(cell)
    main = max(components, key=len)
    clean = cell.copy()
    pixels = clean.load()
    for component in components:
        if component is main:
            continue
        left = min(x for x, _ in component)
        right = max(x for x, _ in component)
        # A detached coin/calculator is legitimate only inside the tile.
        is_prop = role in {"processing", "positive"} and len(component) > 1500
        if is_prop and left > 4 and right < cell.width - 5:
            continue
        for x, y in component:
            pixels[x, y] = (0, 0, 0, 0)
    return clean


def normalize(role: str, source: list[Image.Image]) -> list[Image.Image]:
    frames = []
    for index, cell in enumerate(source):
        cell = remove_neighbor_fragments(cell, role)
        art = cell.crop(bounds_of(cell))
        body_left, body_top, body_right, body_bottom = main_component_bounds(art)
        body_w, body_h = body_right - body_left, body_bottom - body_top
        lift = LIFTS.get(role, [0] * len(source))[index]
        scale = min(260 / body_h, 245 / body_w,
                    (BASELINE - MARGIN - lift) / body_h)
        if role != "success":
            scale = min(scale, (WIDTH - 2 * MARGIN) / art.width,
                        (BASELINE - MARGIN - lift) / art.height)
        art = art.resize((max(1, round(art.width * scale)),
                          max(1, round(art.height * scale))),
                         Image.Resampling.NEAREST)
        frame = Image.new("RGBA", (WIDTH, HEIGHT))
        if role == "success":
            # Anchor the rabbit body, not its detached celebration sparkles.
            scaled_left = round(body_left * scale)
            scaled_right = round(body_right * scale)
            scaled_bottom = round(body_bottom * scale)
            x = (WIDTH - (scaled_right - scaled_left)) // 2 - scaled_left
            y = BASELINE - lift - scaled_bottom
        else:
            x = (WIDTH - art.width) // 2
            y = BASELINE - lift - art.height
        frame.alpha_composite(art, (x, y))
        if role == "success" and index >= 9:
            # Remove faint, detached star scraps after the celebration ends.
            components = _components(frame)
            main = max(components, key=len)
            pixels = frame.load()
            for component in components:
                if component is not main:
                    for px, py in component:
                        pixels[px, py] = (0, 0, 0, 0)
        box = bounds_of(frame)
        if (box[0] < MARGIN or box[1] < MARGIN or
                box[2] > WIDTH - MARGIN or box[3] > HEIGHT - MARGIN):
            raise ValueError(f"{role} frame {index + 1} outside safe area: {box}")
        frames.append(frame)
    if len({frame.tobytes() for frame in frames}) < len(frames) // 2:
        raise ValueError(f"{role}: too few distinct frames")
    return frames


def preview(frame: Image.Image) -> Image.Image:
    background = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    background.alpha_composite(frame)
    return background.convert("RGB")


def save_gif(path: Path, frames: list[Image.Image], duration: int) -> None:
    colored = [preview(frame) for frame in frames]
    colored[0].save(path, save_all=True, append_images=colored[1:],
                    duration=round(duration / len(frames)), loop=0,
                    optimize=True)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    all_frames = {}
    contact = Image.new("RGBA", (WIDTH * len(COUNTS), HEIGHT),
                        (255, 250, 242, 255))
    for column, (role, count) in enumerate(COUNTS.items()):
        frames = normalize(role, cells(role, count))
        if role == "success":
            validate_jump_scale(frames, reference_indices=(3, 4, 8),
                                jump_indices=(5, 6), minimum_ratio=.88)
        all_frames[role] = frames
        sheet = Image.new("RGBA", (WIDTH * count, HEIGHT))
        for i, frame in enumerate(frames):
            sheet.alpha_composite(frame, (WIDTH * i, 0))
        sheet.save(OUTPUT / f"{role}-{count}.png", optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (WIDTH * column, 0))
        save_gif(PREVIEWS / f"{role}.gif", frames, DURATIONS[role])
        dimensions = [body_dimensions(frame) for frame in frames]
        print(f"{role}: {count} frames; body widths "
              f"{min(w for w, _ in dimensions)}-{max(w for w, _ in dimensions)} px")
    contact.save(SOURCE / "motion-contact.png", optimize=True)

    font = ImageFont.truetype(str(ROOT / "assets/fonts/PixelifySans.ttf"), 24)
    combined = []
    panel_height = HEIGHT + 30
    for tick in range(12):
        panel = Image.new("RGBA", (WIDTH * 3, panel_height * 2),
                          (255, 250, 242, 255))
        draw = ImageDraw.Draw(panel)
        for slot, (role, count) in enumerate(COUNTS.items()):
            x, y = slot % 3 * WIDTH, slot // 3 * panel_height
            draw.text((x + 20, y + 2), f"{role.upper()}  {count}F",
                      font=font, fill=(30, 45, 75, 255))
            panel.alpha_composite(all_frames[role][tick * count // 12],
                                  (x, y + 30))
        combined.append(panel)
    save_gif(SOURCE / "motion-preview.gif", combined, 1800)


if __name__ == "__main__":
    main()
