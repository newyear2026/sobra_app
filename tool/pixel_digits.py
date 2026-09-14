"""Draws Pixelify Sans digits from 5x7 bitmaps, in the font's own geometry.

Pixelify's digits are not free outlines. Every coordinate in all ten of them
comes from one lattice of five columns and seven rows, and every one of those
lattice lines lands on exactly one other value at `wght` 700 -- checked across
all ten glyphs, with no coordinate ever mapping to two. A digit is therefore
fully described by which cells are lit, and a redrawn one can carry a correct
variation delta by looking its coordinates up in the same table.

Within a glyph the cells are not drawn one by one. Runs of two or more cells in
a line are drawn as a single stroke that overshoots its end cells by the 10
unit gap, so strokes meeting at a corner overlap and close it. A cell with no
neighbour along an axis is not stretched along that axis. That rule reproduces
all ten shipped digits exactly; `verify()` checks it.
"""

# Lattice, outer edge to outer edge, read out of the shipped font.
COLS = [(60, 151), (161, 241), (251, 333), (343, 423), (433, 525)]
# Bottom row first, the way the coordinate system runs.
ROWS = [(-12, 78), (88, 169), (179, 260), (270, 350), (359, 440), (450, 530),
        (540, 631)]
BOX = (60, -12, 525, 631)

# Where each lattice line lands at `wght` 700.
BOLD_X = {60: 61, 151: 149, 161: 188, 241: 237, 251: 276, 333: 326, 343: 365,
          423: 414, 433: 453, 525: 542}
BOLD_Y = {-12: -11, 78: 74, 88: 125, 169: 160, 179: 211, 260: 246, 270: 297,
          350: 331, 359: 381, 440: 416, 450: 467, 530: 501, 540: 552,
          631: 638}

ADVANCE = 586


def parse(art):
    """A seven line, five column picture into the set of lit (row, col).

    Row 0 is the top line of the picture and the lattice counts from the
    bottom, so the flip happens here rather than in every bitmap.
    """
    lines = [l for l in art.strip('\n').splitlines() if l.strip()]
    assert len(lines) == 7, f'{len(lines)} rows, want 7'
    cells = set()
    for i, line in enumerate(lines):
        assert len(line.rstrip()) <= 5, line
        for c, ch in enumerate(line):
            if ch not in ' ·.':
                cells.add((6 - i, c))
    return frozenset(cells)


def holes(cells):
    """The blocks cut out of the glyph box, as (x0, y0, x1, y1).

    Pixelify does not draw a digit stroke by stroke. It fills the whole box and
    takes the unlit cells back out, which is why a stroke beside a counter runs
    all the way to that counter's edge while the same stroke beside the outside
    of the glyph stops at the cell line: the notch at every corner is an unlit
    corner cell, not a join between two strokes. Unlit cells side by side take
    the gap between them out with them; unlit cells meeting only at a corner
    leave that little square standing, which is what rounds the corner.
    """
    out = []
    for r in range(len(ROWS)):
        for c in range(len(COLS)):
            if (r, c) in cells: continue
            x0, x1 = COLS[c]
            y0, y1 = ROWS[r]
            # Reach to the neighbour's own edge rather than by a fixed
            # amount: the gaps in this lattice are ten units everywhere except
            # between rows three and four, where they are nine.
            if c and (r, c - 1) not in cells: x0 = COLS[c - 1][1]
            if c + 1 < len(COLS) and (r, c + 1) not in cells: x1 = COLS[c + 1][0]
            if r and (r - 1, c) not in cells: y0 = ROWS[r - 1][1]
            if r + 1 < len(ROWS) and (r + 1, c) not in cells: y1 = ROWS[r + 1][0]
            out.append((x0, y0, x1, y1))
    return out


def contours(cells):
    """Boundary loops of the drawn shape, collinear points dropped."""
    cut = holes(cells)
    xs = sorted({BOX[0], BOX[2]} | {v for h in cut for v in (h[0], h[2])
                                    if BOX[0] < v < BOX[2]})
    ys = sorted({BOX[1], BOX[3]} | {v for h in cut for v in (h[1], h[3])
                                    if BOX[1] < v < BOX[3]})
    inside = set()
    for i in range(len(xs) - 1):
        for j in range(len(ys) - 1):
            cx = (xs[i] + xs[i + 1]) / 2
            cy = (ys[j] + ys[j + 1]) / 2
            if not any(x0 < cx < x1 and y0 < cy < y1 for x0, y0, x1, y1 in cut):
                inside.add((i, j))

    # Every edge of a filled square that faces an empty one, directed so the
    # filled side stays on the left.
    edges = {}
    for i, j in inside:
        if (i - 1, j) not in inside: edges.setdefault((xs[i], ys[j]), []).append((xs[i], ys[j + 1]))
        if (i, j + 1) not in inside: edges.setdefault((xs[i], ys[j + 1]), []).append((xs[i + 1], ys[j + 1]))
        if (i + 1, j) not in inside: edges.setdefault((xs[i + 1], ys[j + 1]), []).append((xs[i + 1], ys[j]))
        if (i, j - 1) not in inside: edges.setdefault((xs[i + 1], ys[j]), []).append((xs[i], ys[j]))

    loops = []
    while edges:
        start = next(iter(edges))
        loop = [start]
        here = start
        while True:
            nxt = edges[here].pop()
            if not edges[here]: del edges[here]
            if nxt == start: break
            loop.append(nxt)
            here = nxt
        pruned = [p for i, p in enumerate(loop)
                  if not (loop[i - 1][0] == p[0] == loop[(i + 1) % len(loop)][0]
                          or loop[i - 1][1] == p[1] == loop[(i + 1) % len(loop)][1])]
        loops.append(pruned)
    return loops


def bold(point):
    """The same point at `wght` 700."""
    return (BOLD_X[point[0]], BOLD_Y[point[1]])
