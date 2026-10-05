#!/usr/bin/env python3
"""Normalize the selected Maltese's generated motion poses for the app.

The image generator supplies distinct poses. This script only extracts them,
uses one scale per role, and packs the app's standard 320x360 sprite sheets.
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import (
    _components,
    _extract,
    body_dimensions,
    validate_jump_scale,
)


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/maltese"
OUTPUT = ROOT / "assets/characters/maltese"
WIDTH, HEIGHT, BASELINE, MARGIN = 320, 360, 344, 16
COUNTS = {
    "idle": 8,
    "activity": 12,
    "processing": 12,
    "positive": 12,
    "success": 12,
    "warning": 8,
}
GRIDS = {role: (4 if count == 8 else 6, 2) for role, count in COUNTS.items()}
DURATIONS = {
    "idle": 2800,
    "activity": 1800,
    "processing": 3600,
    "positive": 4000,
    "success": 2200,
    "warning": 1600,
}
POSTERS = {
    "idle": 0,
    "activity": 2,
    "processing": 3,
    "positive": 5,
    "success": 3,
    "warning": 3,
}
TARGET_BODY_HEIGHT = 300


def bounds(points: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [x for x, _ in points]
    ys = [y for _, y in points]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


@dataclass
class Pose:
    image: Image.Image
    body_box: tuple[int, int, int, int]
    body_bottom_in_cell: int


def isolated_poses(raw: Image.Image, role: str) -> list[Pose]:
    """Eight-pose sheets have overlapping nominal cells but separate dogs."""
    components = _components(raw)
    dogs = [points for points in components if len(points) > 10000]
    if len(dogs) != COUNTS[role]:
        raise ValueError(f"{role}: found {len(dogs)} dogs, expected {COUNTS[role]}")
    dogs.sort(key=lambda points: (
        0 if (bounds(points)[1] + bounds(points)[3]) / 2 < raw.height / 2 else 1,
        (bounds(points)[0] + bounds(points)[2]) / 2,
    ))
    if sum(bounds(points)[1] < raw.height / 2 for points in dogs) != 4:
        raise ValueError(f"{role}: expected four poses in each row")
    poses = []
    for points in dogs:
        cropped = _extract(raw, points)
        poses.append(Pose(cropped, (0, 0, cropped.width, cropped.height),
                          bounds(points)[3]))
    return poses


def gridded_poses(raw: Image.Image, role: str) -> list[Pose]:
    cols, rows = GRIDS[role]
    poses = []
    for index in range(COUNTS[role]):
        col, row = index % cols, index // cols
        left = round(col * raw.width / cols)
        top = round(row * raw.height / rows)
        right = round((col + 1) * raw.width / cols)
        bottom = round((row + 1) * raw.height / rows)
        cell = raw.crop((left, top, right, bottom))
        components = _components(cell)
        if not components or max(map(len, components)) < 10000:
            raise ValueError(f"{role} frame {index + 1}: no complete dog")
        dog = max(components, key=len)
        dog_box = bounds(dog)
        clean = Image.new("RGBA", cell.size)
        for points in components:
            if points is not dog:
                # A generated six-column pose occasionally strays into the
                # next cell. Keep only role-specific detached props/effects,
                # never a white sliver of the neighboring Maltese.
                if len(points) < 12:
                    continue
                pixels = [cell.getpixel(point) for point in points]
                teal = sum(g > r * 1.22 and b > r * 1.08
                           for r, g, b, _ in pixels) / len(pixels)
                gold = sum(r > 145 and g > 75 and b < 140
                           for r, g, b, _ in pixels) / len(pixels)
                keep = ((role in ("processing", "positive") and teal > .12)
                        or (role in ("positive", "success") and gold > .24))
                if not keep:
                    continue
            x, y, _, _ = bounds(points)
            clean.alpha_composite(_extract(cell, points), (x, y))
        content_box = clean.getchannel("A").getbbox()
        if content_box is None:
            raise ValueError(f"{role} frame {index + 1}: empty pose")
        cropped = clean.crop(content_box)
        adjusted_box = (
            dog_box[0] - content_box[0], dog_box[1] - content_box[1],
            dog_box[2] - content_box[0], dog_box[3] - content_box[1],
        )
        poses.append(Pose(cropped, adjusted_box, dog_box[3]))
    return poses


def normalize_poses(poses: list[Pose], role: str, version: int) -> list[Image.Image]:
    if role == "success":
        reference_indices = ((0, 1, 10, 11) if version == 2
                             else (0, 1, 5, 6, 7, 11))
    else:
        reference_indices = range(len(poses))
    reference_heights = [
        poses[index].body_box[3] - poses[index].body_box[1]
        for index in reference_indices
    ]
    y_scale = min(
        TARGET_BODY_HEIGHT / median(reference_heights),
        (HEIGHT - 2 * MARGIN) / max(pose.image.height for pose in poses),
    )
    x_scale = min(
        y_scale,
        (WIDTH - 2 * MARGIN) / max(pose.image.width for pose in poses),
    )
    standing_bottom = median(
        poses[index].body_bottom_in_cell for index in reference_indices
    )
    frames = []
    for index, pose in enumerate(poses):
        scaled = pose.image.resize((round(pose.image.width * x_scale),
                                    round(pose.image.height * y_scale)),
                                   Image.Resampling.NEAREST)
        dog_center_x = (pose.body_box[0] + pose.body_box[2]) * x_scale / 2
        x = round(WIDTH / 2 - dog_center_x)
        x = min(max(MARGIN, x), WIDTH - MARGIN - scaled.width)
        body_bottom = round(pose.body_box[3] * y_scale)
        if role == "success":
            # Keep the original jump displacement; never scale by sparkles.
            target_bottom = BASELINE - round(
                (standing_bottom - pose.body_bottom_in_cell) * y_scale
            )
        else:
            target_bottom = BASELINE
        y = target_bottom - body_bottom
        y = min(max(MARGIN, y), HEIGHT - MARGIN - scaled.height)
        frame = Image.new("RGBA", (WIDTH, HEIGHT))
        frame.alpha_composite(scaled, (x, y))
        box = frame.getchannel("A").getbbox()
        if box is None or box[0] < MARGIN or box[1] < MARGIN or \
                box[2] > WIDTH - MARGIN or box[3] > HEIGHT - MARGIN:
            raise ValueError(f"{role} frame {index + 1}: unsafe bounds {box}")
        frames.append(frame)
    return frames


def on_cream(frame: Image.Image) -> Image.Image:
    background = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    background.alpha_composite(frame)
    return background.convert("RGB")


def save_gif(path: Path, frames: list[Image.Image], duration: int) -> None:
    colored = [on_cream(frame) for frame in frames]
    colored[0].save(path, save_all=True, append_images=colored[1:],
                    duration=round(duration / len(frames)), loop=0,
                    optimize=True)


def main(version: int) -> None:
    if version not in (1, 2):
        raise ValueError(f"unsupported Maltese motion version: {version}")
    raw_directory = SOURCE / f"generated-v{version}"
    previews = SOURCE / ("previews" if version == 1 else f"previews-v{version}")
    suffix = "" if version == 1 else f"-v{version}"
    output_directory = (SOURCE / "previous-sheets-v1" if version == 1
                        else OUTPUT)
    output_directory.mkdir(parents=True, exist_ok=True)
    previews.mkdir(parents=True, exist_ok=True)
    all_frames: dict[str, list[Image.Image]] = {}
    contact = Image.new("RGBA", (WIDTH * len(COUNTS), HEIGHT),
                        (255, 250, 242, 255))
    for column, (role, count) in enumerate(COUNTS.items()):
        raw = Image.open(raw_directory / f"{role}-{count}-raw.png").convert("RGBA")
        poses = (isolated_poses(raw, role) if count == 8
                 else gridded_poses(raw, role))
        frames = normalize_poses(poses, role, version)
        if role == "success":
            validate_jump_scale(
                frames,
                reference_indices=((0, 1, 10, 11) if version == 2
                                   else (0, 1, 5, 6, 7, 11)),
                jump_indices=((3, 4, 5, 6, 7) if version == 2
                              else (3, 4, 9)), minimum_ratio=.85,
            )
        distinct = len({frame.tobytes() for frame in frames})
        if distinct < count // 2:
            raise ValueError(f"{role}: only {distinct} distinct frames")
        all_frames[role] = frames
        sheet = Image.new("RGBA", (WIDTH * count, HEIGHT))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (WIDTH * index, 0))
        sheet.save(output_directory / f"{role}-{count}{suffix}.png",
                   optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (WIDTH * column, 0))
        save_gif(previews / f"{role}.gif", frames, DURATIONS[role])
        sizes = [body_dimensions(frame) for frame in frames]
        print(f"{role}: {count} frames, {distinct} distinct; body heights "
              f"{min(h for _, h in sizes)}-{max(h for _, h in sizes)} px")
    contact.save(SOURCE / f"motion-contact{suffix}.png", optimize=True)

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
    save_gif(SOURCE / f"motion-preview{suffix}.gif", combined, 1800)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", type=int, default=1, choices=(1, 2))
    main(parser.parse_args().version)
