#!/usr/bin/env python3
"""Adds a won sign to the bundled Pixelify Sans, which ships without one.

Pixelify Sans draws ¥, € and $ but no ₩ (U+20A9), and it has no Hangul either.
Sobra offers the Korean won as a money label, so without this the one string
the app exists to show -- the amount -- would put a system-font ₩ next to
pixel digits, or a tofu box where the sign goes.

The sign is not drawn from scratch. ₩ is a W crossed by two bars, so this
takes the font's own W, exactly as the designer drew it and carrying its own
`wght` deltas, and lays two bars across it. The bars sit on the lattice the
rest of the font is built on -- one filled row each, bounded by the holes
above and below -- so they thicken with the weight axis the way every other
horizontal stroke in the font does, and land on the same rhythm as the bar of
an 8 standing beside them.

Rows two and four, counting from the bottom, are the pair that leaves the W
legible: the three peaks stay open above the upper bar and the two feet below
the lower one. Bars any higher close the top into a block and the glyph stops
reading as a W at all.

Run from the project root, after `patch_pixelify_digits.py` if both are being
re-run from an upstream copy:

    python3 tool/patch_pixelify_won.py

It rewrites assets/fonts/PixelifySans.ttf in place and is safe to run twice:
the glyph is rebuilt from W every time rather than from whatever is there.
`--check` reports without writing.
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

WON = 0x20A9
GLYPH = 'won'

# The letter the sign is built out of, and the rows the bars cross it on.
SOURCE = 'W'
BAR_ROWS = (2, 4)

# The note the OFL asks a modified copy to carry. Appended to whatever is
# already there rather than replacing it, so this and the digit tool can each
# say their piece without erasing the other's.
NOTE = ('A won sign (U+20A9) was added for Sobra by tool/patch_pixelify_won.py, '
        'built from the font\'s own W.')


def bar(row: int) -> tuple[tuple[int, int, int, int], tuple[int, int, int, int]]:
    """One filled lattice row, at `wght` 400 and at 700.

    A filled row is bounded by the holes above and below it rather than by its
    own cell, which is why the edges come from the neighbouring rows and why
    `BOLD_Y` -- a table of where hole edges land at 700 -- widens the bar
    rather than shrinking it. The bar runs the full width of the glyph: the
    point of ₩ is that the bars cross the W, and one stopping short of the
    outer strokes reads as a W with something behind it.
    """
    low, high = grid.ROWS[row - 1][1], grid.ROWS[row + 1][0]
    return ((0, low, 0, high), (0, grid.BOLD_Y[low], 0, grid.BOLD_Y[high]))


def rectangle(x0: int, y0: int, x1: int, y1: int) -> list[tuple[int, int]]:
    """A closed box wound the way the source glyph's own contour is wound.

    Same direction on purpose: TrueType fills by the non-zero rule, so bars
    laid over the W simply add to it and no outline has to be cut.
    """
    return [(x0, y0), (x0, y1), (x1, y1), (x1, y0)]


def build(font: TTFont) -> Glyph:
    glyf, hmtx, gvar = font['glyf'], font['hmtx'], font['gvar']
    source = glyf[SOURCE]
    points = [tuple(point) for point in source.coordinates]
    variation = gvar.variations[SOURCE][0]
    deltas = [(0, 0) if delta is None else tuple(delta)
              for delta in variation.coordinates[:len(points)]]
    # The four the format appends for the sidebearings and the advance, which
    # ₩ shares with the W it is drawn from.
    phantom = list(variation.coordinates[len(points):])

    # The bars reach the glyph's own edges, at both ends of the weight axis.
    left, right = source.xMin, source.xMax
    bold_x = [x + delta[0] for (x, _), delta in zip(points, deltas)]
    bold_left, bold_right = min(bold_x), max(bold_x)

    ends = list(source.endPtsOfContours)
    for row in BAR_ROWS:
        (_, low, _, high), (_, bold_low, _, bold_high) = bar(row)
        flat = rectangle(left, low, right, high)
        bold = rectangle(bold_left, bold_low, bold_right, bold_high)
        points.extend(flat)
        deltas.extend((bx - x, by - y)
                      for (x, y), (bx, by) in zip(flat, bold))
        ends.append(len(points) - 1)

    glyph = Glyph()
    glyph.numberOfContours = len(ends)
    glyph.endPtsOfContours = ends
    glyph.coordinates = GlyphCoordinates(points)
    glyph.flags = bytearray([1] * len(points))  # every point on curve
    glyph.program = source.program
    glyf.glyphs[GLYPH] = glyph
    glyph.recalcBounds(glyf)

    order = font.getGlyphOrder()
    if GLYPH not in order:
        font.setGlyphOrder(list(order) + [GLYPH])
        glyf.glyphOrder = font.getGlyphOrder()
    hmtx[GLYPH] = (hmtx[SOURCE][0], glyph.xMin)
    gvar.variations[GLYPH] = [
        TupleVariation({'wght': (0.0, 1.0, 1.0)}, deltas + phantom)
    ]

    for table in font['cmap'].tables:
        if table.isUnicode():
            table.cmap[WON] = GLYPH

    # Advance variation lives in HVAR when it is present, and a glyph missing
    # from its map would read whatever index fell off the end. ₩ carries the
    # same advance as the W, so it points at the same entry.
    hvar = font.get('HVAR')
    if hvar is not None and hvar.table.AdvWidthMap is not None:
        mapping = hvar.table.AdvWidthMap.mapping
        mapping[GLYPH] = mapping[SOURCE]

    return glyph


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true',
                        help='report without writing')
    parser.add_argument('--out', default=str(FONT))
    args = parser.parse_args()

    # Not lazy, for the same reason the digit tool is not: gvar decompiles per
    # glyph on demand and checks point counts as it goes.
    font = TTFont(FONT, lazy=False)
    font['gvar']  # decompiled before any outline is added
    glyph = build(font)
    print(f'  {GLYPH:<6} {glyph.numberOfContours} contours, '
          f'{len(glyph.coordinates)} points, '
          f'x {glyph.xMin}..{glyph.xMax} y {glyph.yMin}..{glyph.yMax}, '
          f'advance {font["hmtx"][GLYPH][0]}')
    if args.check:
        print('checked only, nothing written')
        return 0

    name = font['name']
    for platform, encoding, language in ((3, 1, 0x409), (1, 0, 0)):
        record = name.getName(10, platform, encoding, language)
        existing = str(record) if record else ''
        if NOTE in existing:
            continue
        name.setName(f'{existing} {NOTE}'.strip(), 10,
                     platform, encoding, language)

    font.save(args.out)
    print(f'wrote {args.out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
