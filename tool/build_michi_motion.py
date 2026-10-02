#!/usr/bin/env python3
"""Pack generated Michi v2 keyframes; preserve the art, align, and preview.

Run from any directory with Python and Pillow. Raw art is generated with the
built-in image tool; this script only slices, registers, and scales that art.
"""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from normalize_success_jump import _components


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "design/characters/michi"
RAW = SOURCE / "generated-v2"
OUTPUT = ROOT / "assets/characters/michi"
PREVIEWS = SOURCE / "previews"
WIDTH, HEIGHT, BASELINE, MARGIN = 320, 360, 344, 16
COUNTS = {"idle": 8, "activity": 12, "processing": 12,
          "positive": 12, "success": 12, "warning": 8}
DURATIONS = {"idle": 2800, "activity": 1800, "processing": 3600,
             "positive": 4000, "success": 2200, "warning": 1600}
POSTERS = {"idle": 0, "activity": 0, "processing": 7,
           "positive": 8, "success": 5, "warning": 7}
LIFTS = [0, 0, 0, 8, 20, 28, 16, 0, 0, 0, 0, 0]
# End the savings loop with the still-held coin: the generated last frame
# releases it, which would make the next loop recreate a coin from nowhere.
ORDERS = {"positive": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 0]}


def gutter(values: list[int], expected: int, radius: int) -> int:
    return min(range(max(1, expected-radius), min(len(values)-1, expected+radius)+1),
               key=lambda i: (values[i], abs(i-expected)))


def split_grid(role: str, count: int) -> list[Image.Image]:
    sheet = Image.open(RAW / f"{role}-{count}-raw.png").convert("RGBA")
    sheet.putalpha(sheet.getchannel("A").point(lambda a: 0 if a < 96 else a))
    alpha = sheet.getchannel("A")
    rows, columns = count // 4, 4
    row_ink = [sum(v > 0 for v in alpha.crop((0, y, sheet.width, y+1)).getdata())
               for y in range(sheet.height)]
    ys = [0] + [gutter(row_ink, round(sheet.height*r/rows),
                       round(sheet.height/rows*.12)) for r in range(1, rows)] + [sheet.height]
    cells = []
    for row in range(rows):
        strip = sheet.crop((0, ys[row], sheet.width, ys[row+1]))
        a = strip.getchannel("A")
        col_ink = [sum(v > 0 for v in a.crop((x, 0, x+1, strip.height)).getdata())
                   for x in range(strip.width)]
        xs = [0] + [gutter(col_ink, round(sheet.width*c/columns),
                           round(sheet.width/columns*.12)) for c in range(1, columns)] + [sheet.width]
        for col in range(columns):
            cell = strip.crop((xs[col], 0, xs[col+1], strip.height))
            # Remove isolated alpha specks; retain detached props such as jars.
            parts = _components(cell)
            large = [part for part in parts if len(part) >= 80]
            if not large or len(max(large, key=len)) < 5000:
                raise ValueError(f"{role}: missing complete character at {len(cells)}")
            mask = Image.new("L", cell.size)
            pixels = mask.load()
            original = cell.getchannel("A").load()
            for part in large:
                for x, y in part:
                    pixels[x, y] = original[x, y]
            cell.putalpha(mask)
            cells.append(cell.crop(mask.getbbox()))
    return cells


def normalize(role: str, cells: list[Image.Image]) -> list[Image.Image]:
    frames = []
    for index, source_index in enumerate(ORDERS.get(role, range(len(cells)))):
        art = cells[source_index]
        lift = LIFTS[index] if role == "success" else 0
        scale = min(300 / art.height, (WIDTH-2*MARGIN) / art.width,
                    (BASELINE-MARGIN-lift) / art.height)
        art = art.resize((round(art.width*scale), round(art.height*scale)),
                         Image.Resampling.NEAREST)
        frame = Image.new("RGBA", (WIDTH, HEIGHT))
        frame.alpha_composite(art, ((WIDTH-art.width)//2, BASELINE-lift-art.height))
        box = frame.getchannel("A").getbbox()
        if not box or box[0] < MARGIN or box[1] < MARGIN or box[2] > WIDTH-MARGIN or box[3] > BASELINE:
            raise ValueError(f"{role} frame {index}: unsafe bounds {box}")
        frames.append(frame)
    if len({frame.tobytes() for frame in frames}) < len(frames)//2:
        raise ValueError(f"{role}: insufficient distinct generated poses")
    return frames


def on_cream(frame: Image.Image) -> Image.Image:
    bg = Image.new("RGBA", frame.size, (255, 250, 242, 255))
    bg.alpha_composite(frame)
    return bg.convert("RGB")


def save_gif(path: Path, frames: list[Image.Image], durations: list[int]) -> None:
    colored = [on_cream(frame) for frame in frames]
    colored[0].save(path, save_all=True, append_images=colored[1:],
                    duration=durations, loop=0, optimize=True, disposal=2)


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    PREVIEWS.mkdir(parents=True, exist_ok=True)
    all_frames = {role: normalize(role, split_grid(role, count))
                  for role, count in COUNTS.items()}
    # Reuse the approved calm pose for the success landing/hold, so switching
    # back to idle cannot change the character's apparent size or identity.
    all_frames["success"][-1] = all_frames["idle"][0].copy()
    report = {}
    contact = Image.new("RGBA", (WIDTH*6, HEIGHT), (255, 250, 242, 255))
    for slot, (role, frames) in enumerate(all_frames.items()):
        sheet = Image.new("RGBA", (WIDTH*len(frames), HEIGHT))
        for index, frame in enumerate(frames):
            sheet.alpha_composite(frame, (WIDTH*index, 0))
        sheet.save(OUTPUT / f"{role}-{len(frames)}.png", optimize=True)
        contact.alpha_composite(frames[POSTERS[role]], (WIDTH*slot, 0))
        durations = [round(DURATIONS[role]/len(frames)/10)*10]*len(frames)
        durations[-1] += DURATIONS[role]-sum(durations)
        if role in ("success", "warning"):
            durations[-1] += 1400  # Demonstrate app's hold, then replay preview.
        save_gif(PREVIEWS / f"{role}.gif", frames, durations)
        report[role] = {"frames": len(frames), "durationMs": DURATIONS[role],
                        "bounds": [f.getchannel("A").getbbox() for f in frames],
                        "uniqueFrames": len({f.tobytes() for f in frames})}
        print(role, report[role])
    contact.save(SOURCE / "motion-contact.png", optimize=True)
    font = ImageFont.truetype(str(ROOT / "assets/fonts/PixelifySans.ttf"), 22)
    combined = []
    for tick in range(42):
        elapsed = tick*100
        panel = Image.new("RGBA", (WIDTH*3, (HEIGHT+40)*2), (255, 250, 242, 255))
        draw = ImageDraw.Draw(panel)
        for slot, (role, frames) in enumerate(all_frames.items()):
            duration = DURATIONS[role]
            progress = min(elapsed/duration, .9999) if role in ("success", "warning") else (elapsed%duration)/duration
            index = min(int(progress*len(frames)), len(frames)-1)
            x, y = slot%3*WIDTH, slot//3*(HEIGHT+40)
            draw.text((x+16, y+6), f"{role.upper()}  {duration/1000:g}s", font=font, fill=(30,45,75,255))
            panel.alpha_composite(frames[index], (x, y+40))
        combined.append(panel)
    save_gif(SOURCE / "motion-preview.gif", combined, [100]*len(combined))
    (SOURCE / "validation.json").write_text(json.dumps(report, indent=2)+"\n")


if __name__ == "__main__":
    main()
