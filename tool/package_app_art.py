"""Encode room and base-character PNGs as quality-90 WebP for shipping.

The PNG originals live in design/png-sources/{rooms,characters}/ and mirror
the asset tree: design/png-sources/rooms/casa_torre/x.png ships as
assets/rooms/casa_torre/x.webp. Edit or regenerate the PNG, then run

    python3 tool/package_app_art.py            # every source
    python3 tool/package_app_art.py rooms/casa_torre  # one folder

This is file-format packaging, not artwork editing: no crop, resize or
retouch. Colour is lossy (quality 90), which keeps the app under Play's
download cap; alpha is kept exact so sprite bounds and transparency match the
PNG the motion tools measured. Costume atlases have their own packager,
tool/package_costume_motion_assets.py.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import math
import sys

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "design/png-sources"
ASSETS = ROOT / "assets"
QUALITY = 90
# Floor for alpha-weighted PSNR. On 2026-10-26 the 135 q90 files measured
# 32.2 dB (penguin/warning-8) and up; a lower value means settings drifted.
MIN_PSNR = 30.0


def visible_psnr(source, encoded):
    """PSNR of RGB weighted by alpha, i.e. how much of the error is seen."""
    alpha = source.getchannel("A")
    count = alpha.point(lambda value: 255 if value else 0).histogram()[255] or 1
    squared = 0
    for a, b in zip(source.convert("RGB").split(), encoded.convert("RGB").split()):
        diff = ImageChops.multiply(ImageChops.difference(a, b), alpha)
        squared += sum(value * value * n for value, n in enumerate(diff.histogram()))
    mse = squared / (count * 3)
    return math.inf if mse == 0 else 10 * math.log10(255 * 255 / mse)


def package(source):
    target = (ASSETS / source.relative_to(SOURCES)).with_suffix(".webp")
    target.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as image:
        image = image.convert("RGBA")
    image.save(target, format="WEBP", quality=QUALITY, alpha_quality=100, method=6)
    with Image.open(target) as encoded:
        encoded = encoded.convert("RGBA")
    assert encoded.size == image.size, target
    assert encoded.getchannel("A").tobytes() == image.getchannel("A").tobytes(), (
        target, "alpha changed")
    psnr = visible_psnr(image, encoded)
    assert psnr >= MIN_PSNR, (target, f"PSNR {psnr:.1f} dB")
    stray = target.with_suffix(".png")
    assert not stray.exists(), (stray, "PNG left in assets would also ship")
    return source.stat().st_size, target.stat().st_size, psnr


def main():
    folders = [SOURCES / arg for arg in sys.argv[1:]] or [SOURCES]
    sources = sorted({path for folder in folders for path in folder.rglob("*.png")})
    assert sources, folders
    with ThreadPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(package, sources))
    before, after = sum(r[0] for r in results), sum(r[1] for r in results)
    print(f"{len(results)} q{QUALITY} assets with exact alpha: {before:,} -> {after:,} bytes; "
          f"saved {(1 - after / before) * 100:.1f}%; "
          f"lowest visible PSNR {min(r[2] for r in results):.1f} dB")


if __name__ == "__main__":
    main()
