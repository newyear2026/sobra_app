#!/usr/bin/env python3
"""Cuts a Japanese fallback face for Sobra out of Galmuri, sized to its Latin.

The Japanese twin of `build_hangul_fallback.py`, whose docstring has the
reasoning: Pixelify draws no kana and no kanji, and a pixel app that sets half
its words in the phone's own face is not a pixel app. Galmuri11 draws both, on
the same eleven-pixel square as its Hangul.

Sized off the Hangul, not off a kanji. The scale is the one that makes `한`
stand as tall as a Pixelify capital, read out of the same Galmuri file -- so a
kanji here and a syllable in SobraHangul come out the same size, as they are
in Galmuri itself, and the two fallbacks cannot drift apart.

Kept: kana, the CJK punctuation block, fullwidth forms, and every kanji
Galmuri draws -- JIS X 0208, 6,355 of them. The UI needs a few hundred, but a
note the user types can reach any of them, same as the Hangul subset keeps all
11,172 syllables.

Regular only. Galmuri11-Bold has no kana and no kanji at all -- its bold is
redrawn by hand, and only for Hangul and Latin. Smearing the regular one pixel
sideways was tried and clogs the dense kanji (`繰越`, `曜日`, `記録`) into
blocks, so Japanese sets headings at regular weight and carries hierarchy on
size. With no 700 face registered, Flutter falls back to this one rather than
synthesising a bold.

    python3 tool/build_japanese_fallback.py ~/Downloads/Galmuri/Galmuri11.ttf

It writes into assets/fonts/ and puts the licence beside it.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.ttLib.scaleUpem import scale_upem

FONTS = Path('assets/fonts')
LICENCE = FONTS / 'OFL-SobraJapanese.txt'
HOST = Path('assets/fonts/PixelifySans.ttf')

# Measured in the source for the scale, as the Hangul tool does, and then
# dropped: SobraHangul already carries it.
SYLLABLE = 0xD55C  # 한
CAPITAL = 'H'

FAMILY = 'SobraJapanese'

KEEP = [
    # CJK symbols and punctuation: 、。「」『』〜々 and the ideographic space.
    (0x3000, 0x303F),
    (0x3040, 0x309F),  # Hiragana.
    (0x30A0, 0x30FF),  # Katakana, with ・ and ー.
    (0x31F0, 0x31FF),  # Small katakana for Ainu; cheap, and an IME can send it.
    # Kanji. Galmuri draws JIS X 0208's 6,355 of this block; asking for all of
    # it keeps exactly those.
    (0x4E00, 0x9FFF),
    # Fullwidth ！？（）：％ and friends. Pixelify draws the ASCII forms, and
    # these are separate code points, so nothing here can win one of its
    # characters by accident.
    (0xFF01, 0xFF5E),
    (0xFFE0, 0xFFE6),  # Fullwidth ￥ and the rest of the currency forms.
]

NOTE = (
    'Kana and kanji for Sobra, cut from Galmuri11 by '
    'tool/build_japanese_fallback.py: subset to Japanese and rescaled to '
    'match SobraHangul beside the Latin face. Nothing was redrawn. Original: '
    'Galmuri by Lee Minseo, under the SIL Open Font License 1.1, which this '
    'modified copy is also under.'
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('source', help='path to Galmuri11.ttf')
    parser.add_argument('--out', default=str(FONTS / f'{FAMILY}.ttf'))
    args = parser.parse_args()

    host = TTFont(HOST, lazy=False)
    capital = host['glyf'][CAPITAL]
    target = capital.yMax - capital.yMin
    target_upem = host['head'].unitsPerEm

    font = TTFont(args.source, lazy=False)
    if font['OS/2'].usWeightClass >= 600:
        parser.error('Galmuri draws no bold kana or kanji; pass Galmuri11.ttf')
    reference = font['glyf'][font.getBestCmap()[SYLLABLE]]
    source_height = reference.yMax - reference.yMin
    source_upem = font['head'].unitsPerEm

    options = subset.Options()
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

    scale_upem(font, round(source_upem * target / source_height))
    font['head'].unitsPerEm = target_upem

    hhea, os2 = font['hhea'], font['OS/2']
    hhea.ascent, hhea.descent, hhea.lineGap = (
        host['hhea'].ascent,
        host['hhea'].descent,
        host['hhea'].lineGap,
    )
    host_os2 = host['OS/2']
    os2.sTypoAscender = host_os2.sTypoAscender
    os2.sTypoDescender = host_os2.sTypoDescender
    os2.sTypoLineGap = host_os2.sTypoLineGap
    os2.usWinAscent = host_os2.usWinAscent
    os2.usWinDescent = host_os2.usWinDescent

    os2.fsSelection = (os2.fsSelection & ~0x61) | 0x40
    font['head'].macStyle &= ~0x01

    name = font['name']
    for record in list(name.names):
        if record.nameID in (1, 2, 3, 4, 6, 10, 16, 17):
            name.names.remove(record)
    for platform, encoding, language in ((3, 1, 0x409), (1, 0, 0)):
        name.setName(FAMILY, 1, platform, encoding, language)
        name.setName('Regular', 2, platform, encoding, language)
        name.setName(f'{FAMILY} Regular', 4, platform, encoding, language)
        name.setName(f'{FAMILY}-Regular', 6, platform, encoding, language)
        name.setName(f'{FAMILY}:Regular:2026', 3, platform, encoding, language)
        name.setName(NOTE, 10, platform, encoding, language)

    out = Path(args.out)
    font.save(out)

    licence = Path(args.source).parent / 'LICENSE.txt'
    if licence.exists():
        LICENCE.write_text(licence.read_text())

    cmap = font.getBestCmap()
    kanji = sum(1 for cp in cmap if 0x4E00 <= cp <= 0x9FFF)
    sample = font['glyf'][cmap[0x65E5]]  # 日
    print(f'  {len(cmap)} characters ({kanji} kanji), '
          f'{out.stat().st_size / 1024:.0f}KB')
    print(f'  日 stands {sample.yMax - sample.yMin} against a {CAPITAL} of '
          f'{target}, in a {target_upem}-unit em')
    print(f'wrote {out}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
