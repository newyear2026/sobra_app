import collections
import hashlib
import html
import json
import struct
import zlib
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
LANGUAGES = {
    'ko': ('한국어', 'Korean', 'Sobrita_Korean_10_images.zip'),
    'en': ('English', 'English', 'Sobrita_English_10_images.zip'),
    'pt-BR': ('Português (Brasil)', 'Brazilian Portuguese', 'Sobrita_Portuguese_BR_10_images.zip'),
}
LANGUAGE_ORDER = list(LANGUAGES)
RATIOS = {'square': 1.0, 'landscape': 1.91, 'portrait': 0.8}
MINIMUMS = {'square': (200, 200), 'landscape': (600, 314), 'portrait': (320, 400)}
SHAPE_LABELS = {'square': '정사각형 · 1:1', 'landscape': '가로형 · 1.91:1', 'portrait': '세로형 · 4:5'}


def inspect_png(path):
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', path
    width, height = struct.unpack('>II', data[16:24])
    offset = 8
    while offset < len(data):
        size = struct.unpack('>I', data[offset:offset + 4])[0]
        kind = data[offset + 4:offset + 8]
        chunk = data[offset + 8:offset + 8 + size]
        expected_crc = struct.unpack('>I', data[offset + 8 + size:offset + 12 + size])[0]
        assert zlib.crc32(kind + chunk) & 0xffffffff == expected_crc, path
        offset += size + 12
        if kind == b'IEND':
            break
    assert offset == len(data), path
    return width, height, len(data), hashlib.sha256(data).hexdigest()


assets = [json.loads(p.read_text()) for p in (ROOT / 'generation-log').glob('*.json')]
assets.sort(key=lambda a: (a['n'], LANGUAGE_ORDER.index(a['folder'])))
assert len(assets) == 30
assert len({a['id'] for a in assets}) == 30
assert len(list(ROOT.glob('*/*.png'))) == 30
for lang in LANGUAGES:
    subset = [a for a in assets if a['folder'] == lang]
    assert [a['n'] for a in subset] == list(range(1, 11)), lang
    assert collections.Counter(a['shape'] for a in subset) == {'square': 5, 'landscape': 3, 'portrait': 2}

for a in assets:
    width, height, size, sha = inspect_png(ROOT / a['file'])
    deviation = abs((width / height) / RATIOS[a['shape']] - 1)
    minimum_width, minimum_height = MINIMUMS[a['shape']]
    assert size < 5_000_000, a['id']
    assert width >= minimum_width and height >= minimum_height, a['id']
    assert deviation <= 0.01, (a['id'], deviation)
    a.update(width=width, height=height, bytes=size, sha256=sha,
             aspect_ratio=round(width / height, 6),
             target_ratio=RATIOS[a['shape']],
             ratio_deviation_percent=round(deviation * 100, 4))
assert len({a['sha256'] for a in assets}) == 30

manifest = {
    'created': '2026-10-22',
    'brand': 'Sobrita',
    'tool': 'built-in image_gen image editing',
    'languages': {'ko': 'Korean', 'en': 'English', 'pt-BR': 'Brazilian Portuguese'},
    'total_pngs': 30,
    'layout_per_language': {'square_1_1': 5, 'landscape_1_91_1': 3, 'portrait_4_5': 2},
    'validation': {
        'png_chunk_crc': 'passed for all 30 files',
        'file_size': 'all below 5 MB',
        'aspect_ratio': 'all within 1% of the target ratio',
        'minimum_dimensions': 'all passed',
        'visual_review': 'all generated images reviewed for copy, clipping and legibility',
    },
    'assets': assets,
}
(ROOT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')

readme = '''Sobrita localized advertising images — 2026-10-22

30 PNG images: Korean 10 / English 10 / Brazilian Portuguese 10.
Each language: IMG01–05 square (1:1), IMG06–08 landscape (1.91:1),
IMG09–10 portrait (4:5). Matching image numbers use the same source artwork.

Created with the built-in ImageGen editing tool from the new Spanish set.
The mascot, scene and brand name are retained; headlines, secondary copy
and footer are localized. Portuguese uses Brazilian Portuguese (pt-BR).

Contents
- ko/, en/, pt-BR/: PNG advertising assets
- copy.txt in each language folder: localized text for all ten images
- gallery.html: local preview with language and format filters
- localization-prompts.json: all 30 generation prompts and localized copy
- manifest.json: dimensions, byte sizes, source provenance and SHA-256 hashes

Checks: all 30 PNG chunk CRCs valid; all images below 5 MB; dimensions exceed
Google Ads minimums; aspect ratios within 1% of the target. Images were
visually reviewed for localized text, legibility and clipping.
The generated files were kept at their native output dimensions.

Google Ads image specifications:
https://support.google.com/google-ads/answer/9948381

To view the complete gallery, extract the full 30-image archive and open
gallery.html. Upload the PNG files from the appropriate language folder.
'''
(ROOT / 'README.txt').write_text(readme)

for lang, (label, english_label, archive) in LANGUAGES.items():
    subset = [a for a in assets if a['folder'] == lang]
    paragraphs = [f'Sobrita — {english_label}\n']
    for a in subset:
        paragraphs.append(f"IMG{a['n']:02d} — {a['shape']}\n{a['headline']}\n{a['sub']}\n{a['footer']}\n")
    (ROOT / lang / 'copy.txt').write_text('\n'.join(paragraphs))

cards = []
for a in assets:
    label = LANGUAGES[a['folder']][0]
    headline = html.escape(a['headline']).replace('\n', '<br>')
    cards.append(f'''<article data-language="{a['folder']}" data-shape="{a['shape']}">
      <a class="art" href="{a['file']}" target="_blank" rel="noopener"><img src="{a['file']}" alt="{html.escape(a['headline'].replace(chr(10), ' '), quote=True)}" loading="lazy" width="{a['width']}" height="{a['height']}"></a>
      <div class="details"><div class="meta"><span>IMG{a['n']:02d} · {label}</span><span>{SHAPE_LABELS[a['shape']]}</span></div>
      <h2>{headline}</h2><p>{html.escape(a['sub'])}</p>
      <div class="meta"><span>{a['width']} × {a['height']} · {a['bytes']/1_000_000:.2f} MB</span><a href="{a['file']}" download>PNG 저장 ↓</a></div></div>
    </article>''')

page = '''<!doctype html>
<html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sobrita · 한국어 / English / Português</title>
<style>
:root{color-scheme:light;font-family:system-ui,-apple-system,BlinkMacSystemFont,"Apple SD Gothic Neo",sans-serif;color:#11243b;background:#f7f5ed}
*{box-sizing:border-box}body{margin:0}header,main{max-width:1500px;margin:auto;padding:32px}header{padding-bottom:20px}h1{font-size:clamp(32px,5vw,54px);margin:8px 0 12px;letter-spacing:-.04em}.eyebrow{font-weight:750;color:#007f80;letter-spacing:.08em;font-size:13px}header p{color:#53676a;line-height:1.6}a{color:#007c7d}nav{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}nav a{background:white;border:1px solid #d4dfd9;border-radius:9px;padding:10px 14px;text-decoration:none;font-weight:650}.filters{display:flex;align-items:center;gap:12px;flex-wrap:wrap;padding:16px 0;border-top:1px solid #d4dfd9}label{font-size:14px;font-weight:650}select{padding:9px 30px 9px 10px;border:1px solid #c4d0c9;border-radius:7px;background:white;color:#11243b;font:inherit}#count{font-size:14px;color:#53676a;margin-left:auto}.grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:24px}article{background:white;border:1px solid #dde2db;border-radius:14px;overflow:hidden}article[hidden]{display:none}.art{display:flex;align-items:center;justify-content:center;background:#eaece4;height:370px}.art img{display:block;max-width:100%;max-height:100%;width:auto;height:auto}.details{padding:18px}.meta{display:flex;justify-content:space-between;gap:10px;flex-wrap:wrap;color:#53676a;font-size:12px;line-height:1.6}h2{font-size:21px;line-height:1.4;margin:14px 0 8px;letter-spacing:-.02em}.details p{font-size:14px;line-height:1.6;margin:0 0 18px;color:#53676a}.details a{font-weight:700}footer{padding:28px 0;color:#53676a;font-size:12px;line-height:1.7}@media(max-width:1100px){.grid{grid-template-columns:repeat(2,minmax(0,1fr))}.art{height:350px}}@media(max-width:650px){header,main{padding:20px}.grid{grid-template-columns:1fr}.art{height:auto;max-height:640px}.art img{width:100%;max-height:640px;object-fit:contain}#count{margin-left:0}}
</style></head><body><header><div class="eyebrow">SOBRITA · AD IMAGE COLLECTION</div><h1>작은 기록, 세 가지 언어.</h1><p>한국어 · English · Português (Brasil)<br>언어별 10장 · 총 30장 · 정사각형 5장 + 가로형 3장 + 세로형 2장</p>
<div class="filters"><label for="language">언어</label><select id="language"><option value="all">전체 언어</option><option value="ko">한국어</option><option value="en">English</option><option value="pt-BR">Português (Brasil)</option></select><label for="shape">형식</label><select id="shape"><option value="all">전체 형식</option><option value="square">정사각형 1:1</option><option value="landscape">가로형 1.91:1</option><option value="portrait">세로형 4:5</option></select><span id="count">30 images</span></div></header>
<main><div class="grid">''' + '\n'.join(cards) + '''</div><footer>브라질 포르투갈어(pt-BR) 기준입니다. 내장 ImageGen으로 제작했습니다.<br>문구와 프롬프트: <a href="localization-prompts.json">localization-prompts.json</a> · 파일 정보: <a href="manifest.json">manifest.json</a></footer></main>
<script>const language=document.querySelector('#language'),shape=document.querySelector('#shape'),cards=[...document.querySelectorAll('article')];function update(){let count=0;for(const card of cards){card.hidden=!((language.value==='all'||card.dataset.language===language.value)&&(shape.value==='all'||card.dataset.shape===shape.value));if(!card.hidden)count++;}document.querySelector('#count').textContent=count+' images';}language.addEventListener('change',update);shape.addEventListener('change',update);</script></body></html>'''
(ROOT / 'gallery.html').write_text(page)

archive_info = []
for lang, (label, english_label, archive) in LANGUAGES.items():
    files = sorted((ROOT / lang).glob('*')) + [ROOT / 'README.txt']
    with zipfile.ZipFile(ROOT / archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for p in files:
            z.write(p, p.relative_to(ROOT))
    with zipfile.ZipFile(ROOT / archive) as z:
        assert z.testzip() is None
        assert sum(name.endswith('.png') for name in z.namelist()) == 10
    archive_info.append({'archive': archive, 'bytes': (ROOT / archive).stat().st_size, 'pngs': 10})

full_archive = 'Sobrita_KO_EN_PTBR_30_images.zip'
files = [ROOT / a['file'] for a in assets]
files += [ROOT / lang / 'copy.txt' for lang in LANGUAGES]
files += [ROOT / n for n in ['README.txt', 'gallery.html', 'localization-prompts.json', 'manifest.json']]
with zipfile.ZipFile(ROOT / full_archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for p in files:
        z.write(p, p.relative_to(ROOT))
with zipfile.ZipFile(ROOT / full_archive) as z:
    assert z.testzip() is None
    assert sum(name.endswith('.png') for name in z.namelist()) == 30
archive_info.append({'archive': full_archive, 'bytes': (ROOT / full_archive).stat().st_size, 'pngs': 30})
print(json.dumps({'pngs': len(assets), 'max_image_bytes': max(a['bytes'] for a in assets),
                  'dimensions': sorted({(a['width'], a['height']) for a in assets}),
                  'archives': archive_info}, ensure_ascii=False, indent=2))
