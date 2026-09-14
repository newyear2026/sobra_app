#!/usr/bin/env python3
"""Redraws the digits of the bundled Pixelify Sans so an amount can be read.

Pixelify's own figures are drawn on a five-by-seven grid where the closed
double-loop frame of `8` is shared, almost cell for cell, by `0`, `3`, `5`, `6`
and `9`: its `5` in particular is an S with a diagonal waist, and at the sizes
Sobra shows money at it is read as an 8. A budget app can afford a misread
label; it cannot afford a misread amount.

The replacements below stay inside the font's own geometry -- same lattice,
same stroke weight, same `wght` axis -- and change only which cells are lit, so
a redrawn digit sits beside the untouched letters without announcing itself.
What they buy is silhouette: a flat full-width bar, or an open side, where the
original had another copy of the same closed ring.

Run from the project root:

    python3 tool/patch_pixelify_digits.py

It rewrites assets/fonts/PixelifySans.ttf in place and is safe to run twice:
every glyph it touches is drawn from the bitmap, not from what is already
there. `--check` reports without writing.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import pixel_digits as grid  # noqa: E402
from fontTools.ttLib import TTFont  # noqa: E402
from fontTools.ttLib.tables._g_l_y_f import Glyph, GlyphCoordinates  # noqa: E402
from fontTools.ttLib.tables.TupleVariation import TupleVariation  # noqa: E402

FONT = Path('assets/fonts/PixelifySans.ttf')

# Only the figures that were reading as each other. Everything else in the
# font, letters included, is left exactly as the designer drew it.
DIGITS = {
    # An S no longer: the top bar runs the full width and the shoulder below
    # it is open on the right, so nothing about the outline recalls an 8.
    'five': '''
#####
#....
#....
####.
....#
#...#
.###.
''',
    # Was the 8 frame with two cells missing. Now it opens at the top, and
    # the entry stroke leans in the way a 6 does.
    'six': '''
..##.
.#...
#....
####.
#...#
#...#
.###.
''',
    # The mirror of the six, so the pair reads as a pair.
    'nine': '''
.###.
#...#
#...#
.####
....#
...#.
.##..
''',
    # No left wall at all, which is the one thing an 8 can never do.
    'three': '''
####.
....#
....#
.###.
....#
....#
####.
''',
    # Ends on a full-width bar rather than the 8's closed bottom ring.
    'two': '''
.###.
#...#
....#
...#.
..#..
.#...
#####
''',
}

# The advance never changes, so the variation on the advance phantom point is
# copied from whatever the glyph already carried.
PHANTOM = 4


def build(font: TTFont, gvar, name: str, art: str) -> None:
    cells = grid.parse(art)
    loops = grid.contours(cells)

    points: list[tuple[int, int]] = []
    ends: list[int] = []
    for loop in loops:
        points.extend(loop)
        ends.append(len(points) - 1)

    glyf = font['glyf']
    glyph = Glyph()
    glyph.numberOfContours = len(ends)
    glyph.endPtsOfContours = ends
    glyph.coordinates = GlyphCoordinates(points)
    glyph.flags = bytearray([1] * len(points))  # every point on curve
    glyph.program = glyf[name].program
    glyf[name] = glyph
    glyph.recalcBounds(glyf)

    # The left side bearing follows the outline, the advance does not move.
    advance, _ = font['hmtx'][name]
    font['hmtx'][name] = (advance, glyph.xMin)

    # One delta per point, plus the four phantom points the format appends.
    old = gvar.variations[name][0]
    tail = list(old.coordinates[-PHANTOM:])
    deltas = [(grid.bold(p)[0] - p[0], grid.bold(p)[1] - p[1]) for p in points]
    deltas += [(0, 0) if d is None else d for d in tail]
    gvar.variations[name] = [
        TupleVariation({'wght': (0.0, 1.0, 1.0)}, deltas)
    ]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true',
                        help='report without writing')
    parser.add_argument('--out', default=str(FONT))
    args = parser.parse_args()

    # Not lazy: gvar decompiles per glyph on demand otherwise, and a glyph
    # whose outline has already been replaced fails that check noisily.
    font = TTFont(FONT, lazy=False)
    # Read the variations before any outline moves: decompiling them checks
    # point numbers against the glyphs, and half-replaced glyphs fail that.
    gvar = font['gvar']
    for name, art in DIGITS.items():
        build(font, gvar, name, art)
        glyph = font['glyf'][name]
        print(f'  {name:<6} {glyph.numberOfContours} contour(s), '
              f'{len(glyph.coordinates)} points, '
              f'x {glyph.xMin}..{glyph.xMax} y {glyph.yMin}..{glyph.yMax}')
    if args.check:
        print('checked only, nothing written')
        return 0
    # The OFL asks a modified copy to say so. Pixelify Sans reserves no font
    # name, so the family keeps its own; this note is what travels with the
    # file to explain why its figures are not the ones the designer drew.
    name = font['name']
    note = ('Figures redrawn for Sobra by tool/patch_pixelify_digits.py. '
            'All other glyphs are unchanged. Original: Pixelify Sans by The '
            'Pixelify Sans Project Authors, under the SIL Open Font License '
            '1.1, which this modified copy is also under.')
    for record in list(name.names):
        if record.nameID == 10:
            name.names.remove(record)
    name.setName(note, 10, 3, 1, 0x409)
    name.setName(note, 10, 1, 0, 0)

    font.save(args.out)
    print(f'wrote {args.out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
