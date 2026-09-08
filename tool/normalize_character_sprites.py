#!/usr/bin/env python3
"""Normalize Sobra character sprite sheets to the shared 8-frame contract."""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


FRAME_COUNT = 8
FRAME_WIDTH = 320
FRAME_HEIGHT = 360
SAFE_MARGIN = 16
BASELINE_Y = 344
ALPHA_THRESHOLD = 16


@dataclass(frozen=True)
class MotionSource:
    role: str
    source: str


ROLES = ("idle", "activity", "processing", "positive", "success", "warning")

MICHI_LEGACY_MOTIONS = (
    MotionSource("idle", "assets/cats/cat-idle-8.png"),
    MotionSource("activity", "assets/cats/cat-walk-8.png"),
    MotionSource("processing", "assets/cats/cat-expense-8.png"),
    MotionSource("positive", "assets/cats/cat-saving-8.png"),
    MotionSource("success", "assets/cats/cat-celebrate-8.png"),
    MotionSource("warning", "design/animations/cat-concern-8-proposal.png"),
)


def _validate_character_id(value: str) -> str:
    if re.fullmatch(r"[a-z0-9][a-z0-9-]*", value) is None:
        raise argparse.ArgumentTypeError(
            "character id must contain only lowercase letters, numbers, and hyphens"
        )
    return value


def _resolve_motions(
    project_root: Path, character_id: str, source_dir: str | None
) -> tuple[MotionSource, ...]:
    if source_dir is None:
        if character_id != "michi":
            raise ValueError("--source-dir is required for characters other than michi")
        return MICHI_LEGACY_MOTIONS

    directory = (project_root / source_dir).resolve()
    if directory == (project_root / "assets/characters" / character_id).resolve():
        raise ValueError("source and output directories must be different")
    return tuple(
        MotionSource(role, str(directory / f"{role}-8.png")) for role in ROLES
    )


def _clean_alpha(frame: Image.Image) -> Image.Image:
    rgba = frame.convert("RGBA")
    pixels = rgba.load()
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha < ALPHA_THRESHOLD:
                pixels[x, y] = (0, 0, 0, 0)
            else:
                pixels[x, y] = (red, green, blue, alpha)
    return rgba


def _union_box(frames: list[Image.Image]) -> tuple[int, int, int, int]:
    boxes = [frame.getchannel("A").getbbox() for frame in frames]
    non_empty = [box for box in boxes if box is not None]
    if len(non_empty) != FRAME_COUNT:
        raise ValueError("Every source frame must contain visible pixels")
    return (
        min(box[0] for box in non_empty),
        min(box[1] for box in non_empty),
        max(box[2] for box in non_empty),
        max(box[3] for box in non_empty),
    )


def normalize(source: Path) -> tuple[Image.Image, float]:
    sheet = Image.open(source).convert("RGBA")
    if sheet.width % FRAME_COUNT != 0:
        raise ValueError(f"{source}: width must be divisible by {FRAME_COUNT}")

    source_frame_width = sheet.width // FRAME_COUNT
    frames = [
        _clean_alpha(
            sheet.crop(
                (
                    index * source_frame_width,
                    0,
                    (index + 1) * source_frame_width,
                    sheet.height,
                )
            )
        )
        for index in range(FRAME_COUNT)
    ]

    left, top, right, bottom = _union_box(frames)
    content_width = right - left
    content_height = bottom - top
    safe_width = FRAME_WIDTH - (SAFE_MARGIN * 2)
    safe_height = FRAME_HEIGHT - (SAFE_MARGIN * 2)
    scale = min(safe_width / content_width, safe_height / content_height)
    target_width = round(content_width * scale)
    target_height = round(content_height * scale)
    target_x = (FRAME_WIDTH - target_width) // 2
    target_y = BASELINE_Y - target_height

    normalized = Image.new(
        "RGBA", (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT), (0, 0, 0, 0)
    )
    for index, frame in enumerate(frames):
        cropped = frame.crop((left, top, right, bottom))
        if cropped.size != (target_width, target_height):
            cropped = cropped.resize(
                (target_width, target_height), Image.Resampling.NEAREST
            )
        normalized.alpha_composite(cropped, (index * FRAME_WIDTH + target_x, target_y))

    return normalized, scale


def validate(sheet: Image.Image, path: Path) -> None:
    expected_size = (FRAME_WIDTH * FRAME_COUNT, FRAME_HEIGHT)
    if sheet.mode != "RGBA" or sheet.size != expected_size:
        raise ValueError(
            f"{path}: expected RGBA {expected_size}, got {sheet.mode} {sheet.size}"
        )

    for index in range(FRAME_COUNT):
        frame = sheet.crop(
            (index * FRAME_WIDTH, 0, (index + 1) * FRAME_WIDTH, FRAME_HEIGHT)
        )
        box = frame.getchannel("A").getbbox()
        if box is None:
            raise ValueError(f"{path}: frame {index + 1} is empty")
        left, top, right, bottom = box
        if (
            left < SAFE_MARGIN
            or top < SAFE_MARGIN
            or right > FRAME_WIDTH - SAFE_MARGIN
            or bottom > FRAME_HEIGHT - SAFE_MARGIN
        ):
            raise ValueError(
                f"{path}: frame {index + 1} exceeds the 16 px safe area: {box}"
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--character-id",
        type=_validate_character_id,
        default="michi",
        help="Output folder name under assets/characters (default: michi).",
    )
    parser.add_argument(
        "--source-dir",
        help="Folder containing six role-named source sheets for a new character.",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Validate existing normalized files without rewriting them.",
    )
    args = parser.parse_args()

    project_root = Path(__file__).resolve().parents[1]
    output_dir = project_root / "assets/characters" / args.character_id
    if not args.check:
        output_dir.mkdir(parents=True, exist_ok=True)
    motions = (
        tuple(MotionSource(role, "") for role in ROLES)
        if args.check
        else _resolve_motions(project_root, args.character_id, args.source_dir)
    )

    for motion in motions:
        output = output_dir / f"{motion.role}-8.png"
        if args.check:
            validate(Image.open(output), output)
            print(f"ok     {output.relative_to(project_root)}")
            continue

        source = Path(motion.source)
        if not source.is_absolute():
            source = project_root / source
        normalized, scale = normalize(source)
        validate(normalized, output)
        normalized.save(output, optimize=True)
        print(
            f"write  {output.relative_to(project_root)} "
            f"({FRAME_WIDTH * FRAME_COUNT}x{FRAME_HEIGHT}, scale={scale:.4f})"
        )


if __name__ == "__main__":
    main()
