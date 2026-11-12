#!/usr/bin/env python3
"""Cuts a Hangul fallback face for Sobra out of Galmuri, sized to its Latin.

Pixelify Sans carries no Hangul, which is why `SobraLanguage.korean` shipped
to nobody: Korean text fell back to whatever face the phone happened to have,
and a pixel app rendering half its words in Roboto is not a pixel app. Galmuri
is a pixel Hangul face under the same licence, so the glyphs exist -- what is
missing is that the two fonts are drawn at different sizes.

What they are matched on is the letter, not the pixel. Galmuri7 would line its
pixels up with Pixelify's exactly -- both stand seven pixels tall -- and that
is the wrong thing to optimise: a Hangul syllable packs two or three jamo into
the square a Latin letter gets one of, and at seven pixels the result is a
blur. `남은` came out reading as `남온`. Galmuri11 spends eleven pixels on the
same square, so scaled to the height of a Pixelify capital its pixels land
finer than Pixelify's -- a texture that is visibly not the same grid, and
worth it, because the alternative is a word the reader has to guess at.

So: every coordinate is scaled until a syllable stands exactly as tall as the
capital it sits beside, both faces are given the same em and the same vertical
metrics, and the two read as one size even though they do not read as one
grid.

Only Hangul is kept. The Korean UI needs 407 syllables and not one other
character Pixelify is missing, but a note the user types can hold any of the
11,172, and an IME shows bare jamo while a syllable is still being assembled
-- so the subset is all of both and nothing else. Latin, digits and
punctuation are deliberately dropped: Pixelify draws those, and a fallback
that also carried them would win the ones Pixelify lacks by accident.

Galmuri is not vendored here -- it is 20MB of zip for one file we need.
Download a release from https://github.com/quiple/galmuri and point this at
the Galmuri11.ttf inside it:

    python3 tool/build_hangul_fallback.py ~/Downloads/Galmuri/Galmuri11.ttf
    python3 tool/build_hangul_fallback.py ~/Downloads/Galmuri/Galmuri11-Bold.ttf

Run it on both: Pixelify carries its weight on a variable axis and Galmuri
cannot, so a bold Korean heading needs a second file or it renders at the same
weight as the sentence under it. The style is read off the source rather than
asked for, and names the file.

It writes into assets/fonts/ and puts the licence beside them.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.ttLib.scaleUpem import scale_upem

FONTS = Path('assets/fonts')
LICENCE = FONTS / 'OFL-SobraHangul.txt'

# What OS/2 calls bold, and what this writes out for each side of it.
BOLD_FROM = 600

# The face this has to sit beside, read rather than hardcoded so the two
# cannot drift apart silently.
HOST = Path('assets/fonts/PixelifySans.ttf')

# The two glyphs whose heights are made equal: a Hangul syllable and the
# capital it stands beside. Measured rather than written down, so a new
# Galmuri size needs no arithmetic here and a redrawn Pixelify cannot drift
# away from it unnoticed.
SYLLABLE = 0xD55C  # 한
CAPITAL = 'H'

FAMILY = 'SobraHangul'

KEEP = [
    # The 11,172 precomposed syllables. The Korean UI reaches 407 of them and
    # a note the user types can reach any.
    (0xAC00, 0xD7A3),
    # Compatibility jamo, which is what a Korean IME puts on screen while a
    # syllable is still being assembled. Galmuri draws 52 of this block and no
    # conjoining jamo (U+1100) at all — Android's IME does not send those, so
    # asking for the block would only add an empty range.
    (0x3130, 0x318F),
]

NOTE = (
    'Hangul for Sobra, cut from Galmuri7 by tool/build_hangul_fallback.py: '
    'subset to Hangul and rescaled onto the lattice of the Latin face it sits '
    'beside. Nothing was redrawn. Original: Galmuri by Lee Minseo, under the '
    'SIL Open Font License 1.1, which this modified copy is also under.'
)


def vertical_metrics(font: TTFont) -> dict[str, int]:
    """The line box Sobra's Latin face asks for.

    A fallback keeps its own vertical metrics, and a line holding only Korean
    would otherwise be a different height from the line above it.
    """
    hhea, os2 = font['hhea'], font['OS/2']
    return {
        'ascent': hhea.ascent,
        'descent': hhea.descent,
        'lineGap': hhea.lineGap,
        'typoAscender': os2.sTypoAscender,
        'typoDescender': os2.sTypoDescender,
        'typoLineGap': os2.sTypoLineGap,
        'winAscent': os2.usWinAscent,
        'winDescent': os2.usWinDescent,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('source', help='path to Galmuri11.ttf or -Bold.ttf')
    parser.add_argument('--out', help='defaults to the style of the source')
    args = parser.parse_args()

    host = TTFont(HOST, lazy=False)
    metrics = vertical_metrics(host)
    capital = host['glyf'][CAPITAL]
    target = capital.yMax - capital.yMin
    target_upem = host['head'].unitsPerEm

    font = TTFont(args.source, lazy=False)
    bold = font['OS/2'].usWeightClass >= BOLD_FROM
    out = Path(args.out) if args.out else (
        FONTS / f'{FAMILY}{"-Bold" if bold else ""}.ttf'
    )

    options = subset.Options()
    # Layout tables and hinting are for text this face never sets on its own,
    # and every one kept is weight in the APK.
    options.drop_tables += ['GSUB', 'GPOS', 'GDEF', 'prep', 'fpgm', 'cvt ']
    options.hinting = False
    options.desubroutinize = True
    options.notdef_outline = False
    options.recalc_bounds = True
    options.glyph_names = False
    subsetter = subset.Subsetter(options=options)
    subsetter.populate(
        unicodes=[cp for low, high in KEEP for cp in range(low, high + 1)]
    )
    subsetter.subset(font)

    # `scale_upem` is the only handle fontTools offers on every coordinate at
    # once — outlines, metrics and variations together — so the scale is asked
    # for as an em and the em is relabelled afterwards without moving anything
    # again.
    syllable = font['glyf'][font.getBestCmap()[SYLLABLE]]
    source_height = syllable.yMax - syllable.yMin
    source_upem = font['head'].unitsPerEm
    scale_upem(font, round(source_upem * target / source_height))
    font['head'].unitsPerEm = target_upem

    hhea, os2 = font['hhea'], font['OS/2']
    hhea.ascent = metrics['ascent']
    hhea.descent = metrics['descent']
    hhea.lineGap = metrics['lineGap']
    os2.sTypoAscender = metrics['typoAscender']
    os2.sTypoDescender = metrics['typoDescender']
    os2.sTypoLineGap = metrics['typoLineGap']
    os2.usWinAscent = metrics['winAscent']
    os2.usWinDescent = metrics['winDescent']

    # The two files are one family with two weights, so the family name is
    # shared and only the style differs. A font whose bold bits disagree with
    # each other is one the shaper may pick for the wrong weight, and
    # subsetting leaves them however the source had them.
    style = 'Bold' if bold else 'Regular'
    os2.fsSelection = (os2.fsSelection & ~0x61) | (0x20 if bold else 0x40)
    head = font['head']
    head.macStyle = (head.macStyle & ~0x01) | (0x01 if bold else 0x00)

    name = font['name']
    for record in list(name.names):
        if record.nameID in (1, 2, 3, 4, 6, 10, 16, 17):
            name.names.remove(record)
    for platform, encoding, language in ((3, 1, 0x409), (1, 0, 0)):
        name.setName(FAMILY, 1, platform, encoding, language)
        name.setName(style, 2, platform, encoding, language)
        name.setName(f'{FAMILY} {style}', 4, platform, encoding, language)
        name.setName(f'{FAMILY}-{style}', 6, platform, encoding, language)
        name.setName(f'{FAMILY}:{style}:2026', 3, platform, encoding, language)
        name.setName(NOTE, 10, platform, encoding, language)

    font.save(out)

    licence = Path(args.source).parent / 'LICENSE.txt'
    if licence.exists():
        LICENCE.write_text(licence.read_text())

    kept = len(font.getBestCmap())
    size = out.stat().st_size
    scaled = font['glyf'][font.getBestCmap()[SYLLABLE]]
    print(f'  {style.lower()}: {kept} characters, {size / 1024:.0f}KB')
    print(f'  한 stands {scaled.yMax - scaled.yMin} against a {CAPITAL} of '
          f'{target}, in a {target_upem}-unit em')
    print(f'wrote {out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
