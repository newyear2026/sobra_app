"""Inspect image_gen animation atlases and register their unmodified frames.

This tool reads pixels and writes JSON/Dart metadata only. It never writes,
retouches, warps, recolors or resamples artwork. The app renders the registered
source/target rectangles with its normal 320x360 character canvas.
"""

import argparse
import hashlib
import json
from pathlib import Path
from statistics import median

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/costumes/autumn_2026/motion_v2"
DESIGN = ROOT / "design/seasonal/2026-halloween-dia-de-muertos/motion-v2"
RAW = DESIGN / "raw"
CHARACTERS = [
    "michi", "poodle", "schnauzer", "guinea-pig", "capybara", "alpaca",
    "raccoon", "platypus", "rabbit", "penguin", "quokka", "maltese",
]
COUNTS = {"idle": 8, "activity": 12, "processing": 12,
          "positive": 12, "success": 12, "warning": 8}
DURATIONS = {"idle": 2800, "activity": 1800, "processing": 3600,
             "positive": 4000, "success": 2200, "warning": 1600}
POSTERS = {"idle": 0, "activity": 0, "processing": 7,
           "positive": 6, "success": 5, "warning": 7}
LIFTS = [0, 0, 0, 5, 17, 25, 17, 6, 0, 0, 0, 0]
SUCCESS_HEIGHTS = [300, 300, 286, 292, 300, 300, 300, 288, 296, 300, 300, 300]


def projection(mask):
    width, height = mask.size
    data = mask.tobytes()
    rows = [sum(data[y * width:(y + 1) * width]) // 255 for y in range(height)]
    transposed = mask.transpose(Image.Transpose.TRANSPOSE).tobytes()
    columns = [sum(transposed[x * height:(x + 1) * height]) // 255
               for x in range(width)]
    return rows, columns


def gutter(values, expected, radius):
    choices = range(max(1, round(expected - radius)),
                    min(len(values) - 1, round(expected + radius)) + 1)
    index = min(choices, key=lambda value: (values[value], abs(value - expected)))
    return index, values[index]


def inspect(path, character_id, role):
    count, rows, columns = COUNTS[role], COUNTS[role] // 4, 4
    with Image.open(path) as image:
        assert image.mode == "RGBA", (path, image.mode)
        width, height = image.size
        alpha = image.getchannel("A")
        histogram = alpha.histogram()
        clear_fraction = histogram[0] / (width * height)
        assert clear_fraction > .12, (path, "background is not transparent")
        mask = alpha.point(lambda value: 255 if value >= 96 else 0)
        row_ink, _ = projection(mask)
        cuts = [gutter(row_ink, height * row / rows, height / rows * .16)
                for row in range(1, rows)]
        ys = [0] + [cut for cut, _ in cuts] + [height]
        separators = [ink for _, ink in cuts]
        bounds, hashes = [], []
        for row in range(rows):
            y0, y1 = ys[row:row + 2]
            strip = mask.crop((0, y0, width, y1))
            _, col_ink = projection(strip)
            cuts = [gutter(col_ink, width * col / columns, width / columns * .16)
                    for col in range(1, columns)]
            xs = [0] + [cut for cut, _ in cuts] + [width]
            separators.extend(ink for _, ink in cuts)
            for col in range(columns):
                x0, x1 = xs[col:col + 2]
                cell = mask.crop((x0, y0, x1, y1))
                box = cell.getbbox()
                assert box, (path, "empty frame", len(bounds))
                assert box[2] - box[0] > width / columns * .24, (path, box)
                assert box[3] - box[1] > height / rows * .35, (path, box)
                left, top = max(x0, x0 + box[0] - 1), max(y0, y0 + box[1] - 1)
                right, bottom = min(x1, x0 + box[2] + 1), min(y1, y0 + box[3] + 1)
                bounds.append((left, top, right, bottom))
                hashes.append(hashlib.sha256(
                    image.crop((left, top, right, bottom)).tobytes()).hexdigest())
        assert len(bounds) == count, path
        assert len(set(hashes)) >= count // 2, (path, "repeated flat poses")
        # Do not normalize on every changing tail tip. Small height differences
        # preserve drawn breathing; outliers are capped to prevent size pumping.
        reference_height = median(bottom - top for _, top, _, bottom in bounds)
        targets, sources = [], []
        for index, (left, top, right, bottom) in enumerate(bounds):
            art_width, art_height = right - left, bottom - top
            if role == "success":
                target_height = SUCCESS_HEIGHTS[index]
            else:
                ratio = min(1.015, max(.985, art_height / reference_height))
                target_height = 300 * ratio
            scale = min(target_height / art_height, 284 / art_width)
            target_width, target_height = art_width * scale, art_height * scale
            lift = LIFTS[index] if role == "success" else 0
            targets.append([round((320 - target_width) / 2, 6),
                            round(344 - lift - target_height, 6),
                            round(target_width, 6), round(target_height, 6)])
            sources.append([round(left / width, 9), round(top / height, 9),
                            round(art_width / width, 9), round(art_height / height, 9)])
        # Explicitly close loops on the first actual pose. Success uses the
        # preloaded exact idle image for its last two settling/hold frames.
        if role in {"idle", "activity", "processing", "positive"}:
            sources[-1] = sources[0].copy()
            targets[-1] = targets[0].copy()
        return {
            "asset": (ASSETS / character_id / f"{role}-{count}.webp").relative_to(ROOT).as_posix(),
            "size": [width, height], "frameCount": count,
            "durationMs": DURATIONS[role], "posterFrame": POSTERS[role],
            "loop": role not in {"success", "warning"},
            # The repaired raccoon finishes on its own anatomically reviewed
            # landing. Replacing it with the older idle art discards that pose.
            "landingFrameStart": 10 if role == "success" and character_id != "raccoon" else None,
            "sources": sources, "targets": targets,
            "validation": {"uniqueGeneratedFrames": len(set(hashes)),
                           "transparentFraction": round(clear_fraction, 4),
                           "separatorInkPixels": separators,
                           "requiresVisualReview": max(separators, default=0) > 3},
        }


def dart_rect(values):
    return "Rect.fromLTWH(" + ", ".join(str(value) for value in values) + ")"


def write_dart(layouts):
    lines = ["// Generated by tool/build_costume_motion_metadata.py. Do not hand-edit.",
             "import 'dart:ui';", "import '../models/costume_motion.dart';", "",
             "const costumeMotionAtlases = <String, Map<String, CostumeMotionAtlas>>{"]
    for character_id, roles in layouts.items():
        lines.append(f"  '{character_id}': {{")
        for role, data in roles.items():
            lines.extend([f"    '{role}': CostumeMotionAtlas(",
                          f"      asset: '{data['asset']}',",
                          f"      durationMs: {data['durationMs']},",
                          f"      posterFrame: {data['posterFrame']},",
                          f"      loop: {str(data['loop']).lower()},"])
            if data["landingFrameStart"] is not None:
                lines.append(f"      landingFrameStart: {data['landingFrameStart']},")
            for key in ["sources", "targets"]:
                lines.append(f"      {key}: [")
                lines.extend(f"        {dart_rect(rect)}," for rect in data[key])
                lines.append("      ],")
            lines.append("    ),")
        lines.append("  },")
    lines.append("};")
    (ROOT / "lib/data/costume_motion_atlases.dart").write_text(
        "\n".join(lines) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--allow-incomplete", action="store_true")
    args = parser.parse_args()
    layouts, missing = {}, []
    for character_id in CHARACTERS:
        roles = {}
        for role, count in COUNTS.items():
            path = RAW / character_id / f"{role}-{count}.png"
            if not path.exists():
                missing.append(f"{character_id}/{role}")
                continue
            roles[role] = inspect(path, character_id, role)
            warnings = roles[role]["validation"]["requiresVisualReview"]
            print(f"{character_id}/{role}: {count} frames" +
                  ("; crowded separator: review required" if warnings else "; clear separators"))
        if roles:
            layouts[character_id] = roles
    if missing and not args.allow_incomplete:
        raise SystemExit("Missing generated motions: " + ", ".join(missing))
    ASSETS.mkdir(parents=True, exist_ok=True)
    DESIGN.mkdir(parents=True, exist_ok=True)
    (ASSETS / "layout.json").write_text(json.dumps(layouts, indent=2) + "\n", encoding="utf-8")
    write_dart(layouts)
    (DESIGN / "validation.json").write_text(json.dumps({
        "motionCount": sum(map(len, layouts.values())),
        "missing": missing,
        "characters": layouts,
    }, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
