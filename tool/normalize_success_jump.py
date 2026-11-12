"""Keep the animal's apparent size steady during a celebratory jump.

Generated stars are separate from the animal. Treating both as a single image
when fitting a sprite frame shrinks the animal at the peak of the jump.
"""

from __future__ import annotations

from PIL import Image


def _components(frame: Image.Image) -> list[list[tuple[int, int]]]:
    width, height = frame.size
    alpha = frame.getchannel("A").load()
    visited = bytearray(width * height)
    components = []
    for start in range(width * height):
        x, y = start % width, start // width
        if visited[start] or alpha[x, y] < 32:
            continue
        pending = [start]
        visited[start] = 1
        points = []
        while pending:
            point = pending.pop()
            px, py = point % width, point // width
            points.append((px, py))
            for ny in range(max(0, py - 1), min(height, py + 2)):
                for nx in range(max(0, px - 1), min(width, px + 2)):
                    neighbour = ny * width + nx
                    if not visited[neighbour] and alpha[nx, ny] >= 32:
                        visited[neighbour] = 1
                        pending.append(neighbour)
        components.append(points)
    return components


def _extract(frame: Image.Image, points: list[tuple[int, int]]) -> Image.Image:
    left = min(x for x, _ in points)
    top = min(y for _, y in points)
    right = max(x for x, _ in points) + 1
    bottom = max(y for _, y in points) + 1
    cropped = Image.new("RGBA", (right - left, bottom - top))
    source = frame.load()
    target = cropped.load()
    for x, y in points:
        target[x - left, y - top] = source[x, y]
    return cropped


def body_dimensions(frame: Image.Image) -> tuple[int, int]:
    """Measure the animal, excluding detached celebration sparkles."""
    components = _components(frame)
    if not components:
        raise ValueError("Empty success frame")
    body = max(components, key=len)
    return (
        max(x for x, _ in body) - min(x for x, _ in body) + 1,
        max(y for _, y in body) - min(y for _, y in body) + 1,
    )


def validate_jump_scale(
    frames: list[Image.Image],
    *,
    reference_indices: tuple[int, ...],
    jump_indices: tuple[int, ...],
    minimum_ratio: float = 0.9,
) -> None:
    """Reject a jump pose that appears materially smaller than its neighbors."""
    reference = [body_dimensions(frames[i]) for i in reference_indices]
    reference_width = sorted(size[0] for size in reference)[len(reference) // 2]
    reference_height = sorted(size[1] for size in reference)[len(reference) // 2]
    for index in jump_indices:
        width, height = body_dimensions(frames[index])
        if (width < reference_width * minimum_ratio or
                height < reference_height * minimum_ratio):
            raise ValueError(
                f"Jump frame {index + 1} shrinks to {width}x{height}; "
                f"nearby pose is {reference_width}x{reference_height}"
            )


def rebalance_jump_frame(
    frame: Image.Image,
    *,
    body_size: tuple[int, int],
    lift: int,
    star_max_height: int = 20,
) -> Image.Image:
    """Resize the animal, then nest detached gold stars in the free headroom."""
    if frame.size != (320, 360):
        raise ValueError(f"Unexpected sprite frame size: {frame.size}")
    components = _components(frame)
    if not components:
        raise ValueError("Empty jump frame")
    main_index = max(range(len(components)), key=lambda i: len(components[i]))
    original = frame.load()
    body = _extract(frame, components[main_index]).resize(
        body_size, Image.Resampling.NEAREST
    )
    body_left = (320 - body.width) // 2
    body_top = 344 - lift - body.height
    if body_top < 16 or body_left < 16 or body_left + body.width > 304:
        raise ValueError("Jump body exceeds the safe sprite area")
    output = Image.new("RGBA", frame.size)
    output.alpha_composite(body, (body_left, body_top))

    star_points = []
    for i, points in enumerate(components):
        if i == main_index:
            continue
        gold = sum(
            original[x, y][0] > 150
            and original[x, y][1] > 85
            and original[x, y][2] < 130
            for x, y in points
        )
        if len(points) >= 8 and gold / len(points) >= 0.25:
            star_points.extend(points)
    if star_points:
        stars = _extract(frame, star_points)
        scale = min(1.0, star_max_height / stars.height, 100 / stars.width)
        stars = stars.resize(
            (max(1, round(stars.width * scale)),
             max(1, round(stars.height * scale))),
            Image.Resampling.NEAREST,
        )
        star_top = max(16, body_top - stars.height - 2)
        if star_top + stars.height <= body_top:
            output.alpha_composite(
                stars, ((320 - stars.width) // 2, star_top)
            )
    return output
