"""Prepare render-only local system fonts. Font files are not distributed."""
from pathlib import Path
from fontTools.ttLib import TTFont

target = Path('/private/tmp/sobrita-promo-localized-fonts')
target.mkdir(exist_ok=True)
for name, path, number in [
    ('ko-regular.ttf', '/System/Library/Fonts/AppleSDGothicNeo.ttc', 0),
    ('ko-bold.ttf', '/System/Library/Fonts/AppleSDGothicNeo.ttc', 6),
    ('ja-regular.otf', '/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc', 0),
    ('ja-bold.otf', '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc', 0),
]:
    TTFont(path, fontNumber=number).save(target / name)
