#!/usr/bin/env python3
"""Opens up the three letters of the bundled Pixelify Sans that read as an O.

Pixelify draws `C`, `G` and `c` as the closed ring of `O` and `o` with a
single lattice cell taken out of the right side. On a screen a cell is about
one pixel of gap, and at the 12-17 px Sobra sets most of its text, and in bold
especially, that gap closes: "Comida" read "Oomida", "Ciclo de presupuesto"
read "Oiclo", "Michi curioso" read "Michi ourioso", "Gastos" read "Oastos".
Mexican Spanish leans on all three -- Comida, Compras, Colección, Ciclo,
Gasto, Configuración -- so this is not a corner case for the app.

Each is redrawn on the font's own lattice, at the font's own stroke weight and
along the same `wght` axis, exactly as `patch_pixelify_digits.py` redraws the
figures; only which cells are lit changes. What the new shapes buy is a right
side that is visibly open: three cells for `C`, two above a crossbar for `G`,
and the whole side for `c`.

Run from the project root, after `patch_pixelify_digits.py` (which rewrites
the font's note) if both are being re-run from an upstream copy:

    python3 tool/patch_pixelify_letters.py

It rewrites assets/fonts/PixelifySans.ttf in place and is safe to run twice:
every glyph it touches is drawn from the picture, not from what is already
there. `--check` reports without writing.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import patch_pixelify_digits as digits  # noqa: E402
import pixel_digits as grid  # noqa: E402
from fontTools.ttLib import TTFont  # noqa: E402

FONT = Path('assets/fonts/PixelifySans.ttf')

# Capitals stand on the same five-by-seven lattice as the figures.
CAPITALS = {
    # The ring keeps its two terminals and opens three cells between them,
    # where the shipped C opened one.
    'C': '''
.###.
#...#
#....
#....
#....
#...#
.###.
''',
    # Open above a crossbar that turns in from the right wall: the opening
    # says "not an O", the bar says "not a C". The shipped G kept the right
    # wall to within a cell of the top.
    'G': '''
.###.
#...#
#....
#....
#.###
#...#
.###.
''',
}

# The lowercase c is not a seven-row picture. Its x-height is five rows of
# the same lattice, but the top row stops at 450 where a capital's fifth row
# stops at 440, so `grid.contours` cannot draw it. The outline is given
# directly instead, in the same terms the holes model would produce:
#
#     .####
#     #....
#     #....
#     #....
#     .####
#
# a left wall and two bars that run to the right edge. The shipped c had the
# o's right wall above and below a one-row gap.
LOWER_C = [[
    (151, -12), (151, 78), (60, 78), (60, 359), (151, 359), (151, 450),
    (525, 450), (525, 350), (161, 350), (161, 88), (525, 88), (525, -12),
]]

NOTE = ('The letters C, G and c were opened up for Sobra by '
        'tool/patch_pixelify_letters.py, so they no longer read as O.')


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--check', action='store_true',
                        help='report without writing')
    parser.add_argument('--out', default=str(FONT))
    args = parser.parse_args()

    # Not lazy, and gvar read up front, for the reasons the digit tool gives.
    font = TTFont(FONT, lazy=False)
    gvar = font['gvar']
    for name, art in CAPITALS.items():
        digits.build(font, gvar, name, art)
    # Every coordinate of the c is a lattice line `grid.bold` knows, and the
    # shipped c moved each of them by exactly that table's amount.
    digits.install(font, gvar, 'c', LOWER_C)
    for name in [*CAPITALS, 'c']:
        glyph = font['glyf'][name]
        assert all(grid.bold(p) for p in glyph.coordinates)
        print(f'  {name:<6} {glyph.numberOfContours} contour(s), '
              f'{len(glyph.coordinates)} points, '
              f'x {glyph.xMin}..{glyph.xMax} y {glyph.yMin}..{glyph.yMax}')
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
