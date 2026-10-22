#!/usr/bin/env python3
"""Pack the selected crested penguin's generated poses into app sprite sheets."""

from __future__ import annotations

from pathlib import Path
from statistics import median

from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import _components, body_dimensions, validate_jump_scale


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/penguin"
RAW = SOURCE / "generated-v1"
OUTPUT = ROOT / "assets/characters/penguin"
PREVIEWS = SOURCE / "previews"
WIDTH, HEIGHT, BASELINE, MARGIN = 320, 360, 344, 16
COUNTS = {"idle": 8, "activity": 12, "processing": 12,
          "positive": 12, "success": 12, "warning": 8}
DURATIONS = {"idle": 2800, "activity": 1800, "processing": 3600,
             "positive": 4000, "success": 2200, "warning": 1600}
POSTERS = {"idle": 0, "activity": 3, "processing": 5,
           "positive": 4, "success": 6, "warning": 3}
SUCCESS_LIFTS = (0, 0, 0, 0, 16, 34, 42, 34, 15, 0, 0, 0)
TARGET_BODY_HEIGHT = 260


def bounds(points: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [x for x, _ in points]
    ys = [y for _, y in points]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def extract_poses(role: str, count: int) -> list[tuple[Image.Image, tuple[int, int, int, int]]]:
    raw = Image.open(RAW / f"{role}-{count}-raw.png").convert("RGBA")
    cols = count // 2
    poses = []
    for index in range(count):
        col, row = index % cols, index // cols
        # The generated art includes faint guide lines exactly on cell edges.
        left = round(col * raw.width / cols) + 2
        top = round(row * raw.height / 2) + 2
        right = round((col + 1) * raw.width / cols) - 2
        bottom = round((row + 1) * raw.height / 2) - 2
        cell = raw.crop((left, top, right, bottom))
        alpha = cell.getchannel("A").point(lambda value: 255 if value >= 100 else 0)
        cell.putalpha(alpha)
        components = _components(cell)
        if not components:
            raise ValueError(f"{role} frame {index + 1}: no character")
        body = max(components, key=len)
        if len(body) < 10000:
            raise ValueError(f"{role} frame {index + 1}: incomplete character")
        body_box = bounds(body)
        cleaned = Image.new("RGBA", cell.size)
        source, target = cell.load(), cleaned.load()
        for component in components:
            component_box = bounds(component)
            # Only sizable detached effects/coins may accompany the penguin.
            keep = component is body or (
                role in {"processing", "positive", "success"}
                and len(component) >= 180
                and component_box[0] >= 5
                and component_box[1] >= 5
                and component_box[2] <= cell.width - 5
                and component_box[3] <= cell.height - 5
            )
            if keep:
                for x, y in component:
                    target[x, y] = source[x, y]
        content_box = cleaned.getchannel("A").getbbox()
        assert content_box is not None
        cropped = cleaned.crop(content_box)
        relative_body = (
            body_box[0] - content_box[0], body_box[1] - content_box[1],
            body_box[2] - content_box[0], body_box[3] - content_box[1],
        )
        poses.append((cropped, relative_body))
    return poses


def normalize(role: str, poses: list[tuple[Image.Image, tuple[int, int, int, int]]]) -> list[Image.Image]:
    standing = (0, 1, 10, 11) if role == "success" else range(len(poses))
    standing_heights = [poses[i][1][3] - poses[i][1][1] for i in standing]
    scale = min(
        TARGET_BODY_HEIGHT / median(standing_heights),
        (WIDTH - 2 * MARGIN) / max(pose.width for pose, _ in poses),
        (HEIGHT - 2 * MARGIN - max(SUCCESS_LIFTS if role == "success" else (0,)))
        / max(pose.height for pose, _ in poses),
    )
    frames = []
    for index, (pose, body_box) in enumerate(poses):
        art = pose.resize((max(1, round(pose.width * scale)),
                           max(1, round(pose.height * scale))),
                          Image.Resampling.NEAREST)
        scaled_body = tuple(round(value * scale) for value in body_box)
        x = round(WIDTH / 2 - (scaled_body[0] + scaled_body[2]) / 2)
        y = BASELINE - (SUCCESS_LIFTS[index] if role == "success" else 0) - scaled_body[3]
        x = min(max(MARGIN, x), WIDTH - MARGIN - art.width)
        y = min(max(MARGIN, y), HEIGHT - MARGIN - art.height)
        frame = Image.new("RGBA", (WIDTH, HEIGHT))
        frame.alpha_composite(art, (x, y))
        box = frame.getchannel("A").getbbox()
        if box is None or box[0] < MARGIN or box[1] < MARGIN or \
                box[2] > WIDTH - MARGIN or box[3] > HEIGHT - MARGIN:
            raise ValueError(f"{role} frame {index + 1}: unsafe bounds {box}")
        frames.append(frame)
    if len({frame.tobytes() for frame in frames}) < len(frames) // 2:
        raise ValueError(f"{role}: too few distinct poses")
    return frames


def preview(frame: Image.Image) -> Image.Image:
    canvas = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    canvas.alpha_composite(frame)
    return canvas.convert("RGB")


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
        frames = normalize(role, extract_poses(role, count))
        if role == "success":
            validate_jump_scale(frames, reference_indices=(0, 1, 10, 11),
                                jump_indices=(4, 5, 6, 7), minimum_ratio=.85)
        all_frames[role] = frames
        sheet = Image.new("RGBA", (WIDTH * count, HEIGHT))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (WIDTH * index, 0))
        sheet.save(OUTPUT / f"{role}-{count}.png", optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (WIDTH * column, 0))
        save_gif(PREVIEWS / f"{role}.gif", frames, DURATIONS[role])
        sizes = [body_dimensions(frame) for frame in frames]
        print(f"{role}: {count} frames; body heights "
              f"{min(height for _, height in sizes)}-"
              f"{max(height for _, height in sizes)} px")
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
