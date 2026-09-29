#!/usr/bin/env python3
"""Build the selected round-honey platypus motion pack from source strips."""

from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import _components, body_dimensions, validate_jump_scale


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/platypus"
RAW = SOURCE / "generated-v2"
OUTPUT = ROOT / "assets/characters/platypus"
PREVIEWS = SOURCE / "previews"
WIDTH, HEIGHT, BASELINE, MARGIN = 320, 360, 344, 16
COUNTS = {"idle": 8, "activity": 12, "processing": 12,
          "positive": 12, "success": 12, "warning": 8}
DURATIONS = {"idle": 2800, "activity": 1800, "processing": 3600,
             "positive": 4000, "success": 2200, "warning": 1600}
POSTERS = {"idle": 0, "activity": 4, "processing": 5,
           "positive": 7, "success": 6, "warning": 3}
LIFTS = [0, 0, 0, 4, 10, 18, 13, 5, 0, 0, 0, 0]


def cells(role: str, count: int) -> list[Image.Image]:
    strip = Image.open(RAW / f"{role}-{count}-raw.png").convert("RGBA")
    alpha = strip.getchannel("A")
    pixels = alpha.load()
    occupancy = [sum(pixels[x, y] >= 64 for y in range(strip.height))
                 for x in range(strip.width)]
    cell_width = strip.width / count
    bounds = [0]
    for i in range(1, count):
        expected = round(i * cell_width)
        radius = round(cell_width * .22)
        bounds.append(min(range(expected - radius, expected + radius + 1),
                          key=lambda x: (occupancy[x], abs(x - expected))))
    bounds.append(strip.width)
    if bounds != sorted(set(bounds)):
        raise ValueError(f"{role}: invalid boundaries {bounds}")
    return [strip.crop((bounds[i], 0, bounds[i + 1], strip.height))
            for i in range(count)]


def bounds_of(art: Image.Image) -> tuple[int, int, int, int]:
    mask = art.getchannel("A").point(lambda x: 255 if x >= 40 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError("Empty source frame")
    return bounds


def normalize(role: str, source: list[Image.Image]) -> list[Image.Image]:
    frames = []
    for index, cell in enumerate(source):
        art = cell.crop(bounds_of(cell))
        body_w, body_h = body_dimensions(art)
        lift = LIFTS[index] if role == "success" else 0
        # Size from the connected animal, not detachable stars or props.
        scale = min(245 / body_w, 255 / body_h,
                    (WIDTH - 2 * MARGIN) / art.width,
                    (BASELINE - 2 * MARGIN - lift) / art.height)
        art = art.resize((max(1, round(art.width * scale)),
                          max(1, round(art.height * scale))),
                         Image.Resampling.NEAREST)
        frame = Image.new("RGBA", (WIDTH, HEIGHT))
        frame.alpha_composite(art, ((WIDTH - art.width) // 2,
                                    BASELINE - art.height - lift))
        # Late celebration frames should contain only the animal: faint star
        # fragments at adjacent source-cell edges otherwise flash on landing.
        if role == "success" and index >= 9:
            components = _components(frame)
            main = max(components, key=len)
            pixels = frame.load()
            for component in components:
                if component is main:
                    continue
                for x, y in component:
                    pixels[x, y] = (0, 0, 0, 0)
        box = bounds_of(frame)
        if (box[0] < MARGIN or box[1] < MARGIN or
                box[2] > WIDTH - MARGIN or box[3] > HEIGHT - MARGIN):
            raise ValueError(f"{role} frame {index + 1} outside safe area: {box}")
        frames.append(frame)
    if len({f.tobytes() for f in frames}) < len(frames) // 2:
        raise ValueError(f"{role}: too few distinct frames")
    return frames


def backdrop(frame: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    canvas.alpha_composite(frame)
    return canvas.convert("RGB")


def save_gif(path: Path, frames: list[Image.Image], duration: int) -> None:
    colored = [backdrop(frame) for frame in frames]
    colored[0].save(path, save_all=True, append_images=colored[1:],
                    duration=round(duration / len(frames)), loop=0, optimize=True)


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
        sizes = [body_dimensions(frame) for frame in frames]
        print(f"{role}: {count} frames, body range "
              f"{min(w for w, _ in sizes)}-{max(w for w, _ in sizes)} px")
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
