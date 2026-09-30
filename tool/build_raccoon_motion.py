#!/usr/bin/env python3
"""Extract the classic gray raccoon's motion contact sheets as app sprites."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import _components, _extract, body_dimensions, validate_jump_scale


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/raccoon"
RAW = SOURCE / "generated-v1"
OUTPUT = ROOT / "assets/characters/raccoon"
PREVIEWS = SOURCE / "previews"
WIDTH, HEIGHT, BASELINE, MARGIN = 320, 360, 344, 16
COUNTS = {
    "idle": 8,
    "activity": 12,
    "processing": 12,
    "positive": 12,
    "success": 12,
    "warning": 8,
}
DURATIONS = {
    "idle": 2800,
    "activity": 1800,
    "processing": 3600,
    "positive": 4000,
    "success": 2200,
    "warning": 1600,
}
POSTERS = {"idle": 0, "activity": 5, "processing": 4,
           "positive": 8, "success": 4, "warning": 3}
LIFTS = {
    "activity": [0, 0, 3, 8, 15, 20, 24, 16, 9, 2, 0, 0],
    "success": [0, 0, 3, 12, 20, 25, 18, 9, 2, 0, 0, 0],
}
TARGET_HEIGHT = {"idle": 300, "activity": 260, "processing": 300,
                 "positive": 300, "success": 290, "warning": 300}


def bounds(points: list[tuple[int, int]]) -> tuple[int, int, int, int]:
    xs = [x for x, _ in points]
    ys = [y for _, y in points]
    return min(xs), min(ys), max(xs) + 1, max(ys) + 1


def body_components(role: str, count: int) -> tuple[Image.Image, list[list[tuple[int, int]]], list[list[tuple[int, int]]]]:
    image = Image.open(RAW / f"{role}-{count}-raw.png").convert("RGBA")
    components = _components(image)
    bodies = [points for points in components if len(points) > 10000]
    if len(bodies) != count:
        raise ValueError(f"{role}: expected {count} complete raccoons, found {len(bodies)}")
    bodies.sort(key=lambda p: (
        0 if (bounds(p)[1] + bounds(p)[3]) / 2 < image.height / 2 else 1,
        (bounds(p)[0] + bounds(p)[2]) / 2,
    ))
    extras = [points for points in components if len(points) <= 10000]
    return image, bodies, extras


def frame_for(
    image: Image.Image,
    points: list[tuple[int, int]],
    role: str,
    index: int,
    extras: list[list[tuple[int, int]]],
) -> Image.Image:
    left, top, right, bottom = bounds(points)
    body = _extract(image, points)
    lift = LIFTS.get(role, [0] * COUNTS[role])[index]
    scale = min(
        TARGET_HEIGHT[role] / body.height,
        (WIDTH - 2 * MARGIN) / body.width,
        (BASELINE - MARGIN - lift) / body.height,
    )
    body = body.resize((round(body.width * scale), round(body.height * scale)),
                       Image.Resampling.NEAREST)
    dest_left = (WIDTH - body.width) // 2
    dest_top = BASELINE - lift - body.height
    frame = Image.new("RGBA", (WIDTH, HEIGHT))
    frame.alpha_composite(body, (dest_left, dest_top))

    if role == "success":
        # Detached gold sparkles follow their own frame, never entering the
        # fit calculation that determines the raccoon's jump size.
        for sparkle in extras:
            if len(sparkle) < 100 or len(sparkle) > 3000:
                continue
            sleft, stop, sright, sbottom = bounds(sparkle)
            center_x = (sleft + sright) / 2
            center_y = (stop + sbottom) / 2
            if abs(center_x - (left + right) / 2) > (right - left) / 2 + 35:
                continue
            if abs(center_y - (top + bottom) / 2) > (bottom - top) / 2 + 30:
                continue
            raw = image.load()
            gold = sum(raw[x, y][0] > 150 and raw[x, y][1] > 85 and
                       raw[x, y][2] < 150 for x, y in sparkle)
            if gold / len(sparkle) < .35:
                continue
            star = _extract(image, sparkle)
            star = star.resize((max(1, round(star.width * scale)),
                                max(1, round(star.height * scale))),
                               Image.Resampling.NEAREST)
            sx = dest_left + round((sleft - left) * scale)
            sy = dest_top + round((stop - top) * scale)
            if (sx >= MARGIN and sy >= MARGIN and
                    sx + star.width <= WIDTH - MARGIN and
                    sy + star.height <= HEIGHT - MARGIN):
                frame.alpha_composite(star, (sx, sy))

    box = frame.getchannel("A").getbbox()
    if box is None or box[0] < MARGIN or box[1] < MARGIN or \
            box[2] > WIDTH - MARGIN or box[3] > HEIGHT - MARGIN:
        raise ValueError(f"{role} frame {index + 1} exceeds safe area: {box}")
    return frame


def on_cream(frame: Image.Image) -> Image.Image:
    background = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    background.alpha_composite(frame)
    return background.convert("RGB")


def save_gif(path: Path, frames: list[Image.Image], duration: int) -> None:
    colored = [on_cream(frame) for frame in frames]
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
        image, bodies, extras = body_components(role, count)
        frames = [frame_for(image, points, role, index, extras)
                  for index, points in enumerate(bodies)]
        if role == "success":
            validate_jump_scale(frames, reference_indices=(2, 3, 9),
                                jump_indices=(4, 5, 6), minimum_ratio=.88)
        if len({frame.tobytes() for frame in frames}) < count // 2:
            raise ValueError(f"{role}: too few distinct frames")
        all_frames[role] = frames
        sheet = Image.new("RGBA", (WIDTH * count, HEIGHT))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (WIDTH * index, 0))
        sheet.save(OUTPUT / f"{role}-{count}.png", optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (WIDTH * column, 0))
        save_gif(PREVIEWS / f"{role}.gif", frames, DURATIONS[role])
        dimensions = [body_dimensions(frame) for frame in frames]
        print(f"{role}: {count} frames; body heights "
              f"{min(h for _, h in dimensions)}-{max(h for _, h in dimensions)} px")
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
