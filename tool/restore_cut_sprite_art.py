#!/usr/bin/env python3
"""Restore character art the frame slicer cut off, from the raw sheets.

The generated sheets pack each pose tightly, and neighbouring poses' ears and
outlines touch. Slicing them into 320x360 frames cut some ears, tails and
sparkles off along straight lines, and left slivers of the next pose behind.

For every shipped frame this finds its pose in the raw sheet, recovers the
scale and offset that map the pose onto the frame (they agree on 98%+ of the
pixels), then adds back only the solid areas that touch a straight,
outline-less edge in the shipped frame, and drops detached slivers the raw
pose doesn't have. Everything else in the shipped frame is left as is.

Usage (from the repository root, with Pillow, NumPy and SciPy):
    python3 tool/restore_cut_sprite_art.py maltese success
    python3 tool/restore_cut_sprite_art.py --all
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]

# Where each character's raw generated sheets live.
RAW_DIRS = {
    'maltese': 'design/characters/maltese/generated-v2',
    'rabbit': 'design/characters/rabbit/generated-v1',
    'guinea-pig': 'design/characters/guinea-pig/generated-v1',
    'poodle': 'design/animations/poodle-generated-v5',
    'schnauzer': 'design/characters/schnauzer/generated-v2',
}


def characters(raw, count):
    """Per-character label image, characters numbered in reading order."""
    a = np.array(raw)[..., 3] > 16
    for it in range(1, 30):
        er = ndimage.binary_erosion(a, iterations=it)
        lab, n = ndimage.label(er)
        if n == 0:
            break
        sizes = ndimage.sum(er, lab, range(1, n + 1))
        order = np.argsort(sizes)[::-1]
        if len(order) >= count and sizes[order[count - 1]] > 4 * max(
            sizes[order[count]] if len(order) > count else 0, 1
        ):
            big = [int(k) + 1 for k in order[:count]]
            break
    else:
        raise ValueError('could not separate characters')
    cents = [ndimage.center_of_mass(lab == k) for k in big]
    # Reading order: rows are centres within a quarter sheet of each other.
    idx = sorted(range(count), key=lambda i: cents[i][0])
    groups, cur = [], [idx[0]]
    for i in idx[1:]:
        if abs(cents[i][0] - cents[cur[0]][0]) < raw.height / 4:
            cur.append(i)
        else:
            groups.append(cur)
            cur = [i]
    groups.append(cur)
    ordered = [i for g in groups for i in sorted(g, key=lambda i: cents[i][1])]
    seeds = np.zeros(lab.shape, np.int32)
    for j, i in enumerate(ordered, 1):
        seeds[lab == big[i]] = j
    _, (iy, ix) = ndimage.distance_transform_edt(seeds == 0, return_indices=True)
    nearest = seeds[iy, ix]
    out = np.where(a, nearest, 0)
    return out


def fit(frame, labels, j):
    fa = np.array(frame)[..., 3] > 16
    mask = labels == j
    ys, xs = np.nonzero(mask)
    rt, rb, rl, rr = ys.min(), ys.max(), xs.min(), xs.max()
    fys, fxs = np.nonzero(fa)
    ft, fb = fys.min(), fys.max()
    best = None
    base = (fb - ft) / (rb - rt)
    for s in np.linspace(base * .97, base * 1.03, 25):
        oy0 = ft - rt * s
        for dy in (-2, -1, 0, 1, 2):
            oy = oy0 + dy
            for dx in range(-12, 13):
                ox = (fxs.min() + fxs.max()) / 2 - ((rl + rr) / 2) * s + dx
                yy = ((fys - oy) / s).round().astype(int)
                xx = ((fxs - ox) / s).round().astype(int)
                ok = (yy >= 0) & (yy < mask.shape[0]) & (xx >= 0) & (xx < mask.shape[1])
                score = mask[yy[ok], xx[ok]].mean() * ok.mean()
                if best is None or score > best[0]:
                    best = (score, s, ox, oy)
    return best


def render(raw, labels, j, s, ox, oy, size=(320, 360)):
    rgba = np.array(raw).copy()
    rgba[labels != j] = 0
    out = np.zeros((size[1], size[0], 4), np.uint8)
    Y, X = np.mgrid[0:size[1], 0:size[0]]
    sy = np.floor((Y + .5 - oy) / s).astype(int)
    sx = np.floor((X + .5 - ox) / s).astype(int)
    ok = (sy >= 0) & (sy < rgba.shape[0]) & (sx >= 0) & (sx < rgba.shape[1])
    out[ok] = rgba[sy[ok], sx[ok]]
    out[out[..., 3] < 16] = 0
    return out


def cut_edges(o, min_run=10):
    """Pixels on a straight, outline-less edge: where the slicer cut."""
    op = o[..., 3] > 60
    tr = o[..., 3] < 10
    lt = op & (o[..., :3].astype(int).sum(-1) > 330)
    edge = np.zeros(op.shape, bool)
    cand = {
        'left': lt & np.pad(tr, ((0, 0), (1, 0)), constant_values=True)[:, :-1],
        'right': lt & np.pad(tr, ((0, 0), (0, 1)), constant_values=True)[:, 1:],
        'top': lt & np.pad(tr, ((1, 0), (0, 0)), constant_values=True)[:-1, :],
    }
    for name, m in cand.items():
        lines = m if name == 'top' else m.T
        for k in range(lines.shape[0]):
            run = 0
            for idx in range(lines.shape[1] + 1):
                v = idx < lines.shape[1] and lines[k, idx]
                if v:
                    run += 1
                    continue
                if run >= min_run:
                    if name == 'top':
                        edge[k, idx - run:idx] = True
                    else:
                        edge[idx - run:idx, k] = True
                run = 0
    return edge


def patch(old, new):
    o = np.array(old)
    oa = o[..., 3] > 16
    na = new[..., 3] > 16
    extra = na & ~oa
    cut = cut_edges(o)
    edge = ndimage.binary_dilation(cut, iterations=3)
    core = ndimage.binary_opening(extra, structure=np.ones((3, 3)))
    lab, k = ndimage.label(core)
    keep = np.zeros_like(core)
    for j in range(1, k + 1):
        m = lab == j
        if m.sum() >= 20 and (m & edge).any():
            keep |= m
    # Only near the cut: a pose registered a pixel off would otherwise
    # trace a second outline along the rest of the silhouette.
    keep &= ndimage.distance_transform_edt(~cut) <= 48
    keep = ndimage.binary_dilation(keep, iterations=2) & extra
    out = o.copy()
    out[keep] = new[keep]
    lab2, k2 = ndimage.label(oa)
    near = ndimage.binary_dilation(na, iterations=3)
    removed = 0
    for j in range(1, k2 + 1):
        m = lab2 == j
        if not (m & near).any():
            out[m] = 0
            removed += int(m.sum())
    return out, int(keep.sum()), removed


def restore(sheet_path, raw_path, count, min_fit=.98):
    sheet = Image.open(sheet_path).convert('RGBA')
    raw = Image.open(raw_path).convert('RGBA')
    labels = characters(raw, count)
    fixed = np.array(sheet).copy()
    report = []
    for i in range(count):
        fr = sheet.crop((i * 320, 0, i * 320 + 320, 360))
        score, s, ox, oy = fit(fr, labels, i + 1)
        if score < min_fit:
            # The raw pose isn't the one shipped; leave the frame alone.
            report.append((i, round(float(score), 4), 0, 0))
            continue
        new = render(raw, labels, i + 1, s, ox, oy)
        out, added, removed = patch(fr, new)
        report.append((i, round(float(score), 4), added, removed))
        fixed[:, i * 320:(i + 1) * 320] = out
    return Image.fromarray(fixed), report


def sheets(character: str):
    text = (ROOT / f'assets/characters/{character}/character.yaml').read_text()
    pattern = r'\n  (\w+):\n    asset: (\S+)\n    frameCount: (\d+)'
    for role, asset, count in re.findall(pattern, text):
        yield role, asset, int(count)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('character', nargs='?', choices=sorted(RAW_DIRS))
    parser.add_argument('role', nargs='?')
    parser.add_argument('--all', action='store_true')
    parser.add_argument('--min-fit', type=float, default=.98)
    args = parser.parse_args()
    characters_ = sorted(RAW_DIRS) if args.all else [args.character]
    for character in characters_:
        raw_dir = ROOT / RAW_DIRS[character]
        for role, asset, count in sheets(character):
            if args.role and role != args.role:
                continue
            best = None
            for raw in sorted(raw_dir.glob(f'{role}-{count}-raw*.png')):
                image, report = restore(
                    ROOT / f'assets/characters/{character}/{asset}',
                    raw,
                    count,
                    args.min_fit,
                )
                worst = sorted(fit for _, fit, _, _ in report)[len(report) // 2]
                if best is None or worst > best[0]:
                    best = (worst, raw, image, report)
            if best is None:
                print(f'skip   {character} {role}: no raw sheet')
                continue
            worst, raw, image, report = best
            changed = [(i, a, r) for i, _, a, r in report if a or r]
            if worst < args.min_fit:
                print(f'skip   {character} {role}: raw {raw.name} fits {worst:.3f}')
                continue
            loose = [i for i, fit, _, _ in report if fit < args.min_fit]
            if loose:
                print(f'note   {character} {role}: left frames {loose} as shipped')
            if not changed:
                print(f'ok     {character} {role}')
                continue
            image.save(ROOT / f'assets/characters/{character}/{asset}', optimize=True)
            print(f'write  {character} {role} from {raw.name} (median fit {worst:.3f}): '
                  + ', '.join(f'f{i} +{a}/-{r}' for i, a, r in changed))



if __name__ == '__main__':
    main()
