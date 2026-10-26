"""Encode generated PNGs as quality-90 WebP for shipping.

This is file-format packaging, not artwork editing. No crop, resize, palette
change or retouch is performed. Original PNG sources remain in design/.

Colour is lossy (quality 90), which keeps the bundle under Play's download
cap; alpha is kept exact so transparency and frame bounds match the sources
that build_costume_motion_metadata.py measured.
"""

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import math
import shutil

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/costumes/autumn_2026/motion_v2"
RAW = ROOT / "design/seasonal/2026-halloween-dia-de-muertos/motion-v2/raw"
QUALITY = 90
# Floor for alpha-weighted PSNR. On 2026-10-26 the 72 q90 sheets measured
# 29.2-38.2 dB (dense costume texture keeps PSNR modest while side-by-side
# review showed no visible change); a lower value means the settings drifted.
MIN_PSNR = 28.0


def visible_psnr(source, encoded):
    """PSNR of RGB weighted by alpha, i.e. how much of the error is seen."""
    alpha = source.getchannel("A")
    count = alpha.point(lambda value: 255 if value else 0).histogram()[255]
    squared = 0
    for a, b in zip(source.convert("RGB").split(), encoded.convert("RGB").split()):
        diff = ImageChops.multiply(ImageChops.difference(a, b), alpha)
        squared += sum(value * value * n for value, n in enumerate(diff.histogram()))
    mse = squared / (count * 3)
    return math.inf if mse == 0 else 10 * math.log10(255 * 255 / mse)


def package(source):
    relative = source.relative_to(ASSETS if source.is_relative_to(ASSETS) else RAW)
    target = (ASSETS / relative).with_suffix(".webp")
    original = RAW / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    original.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as image:
        assert image.mode == "RGBA", source
        image.load()
        image.save(target, format="WEBP", quality=QUALITY, alpha_quality=100, method=6)
    with Image.open(target) as encoded:
        assert encoded.mode == "RGBA" and encoded.size == image.size, target
        assert encoded.getchannel("A").tobytes() == image.getchannel("A").tobytes(), (
            target, "alpha changed")
        psnr = visible_psnr(image, encoded)
        assert psnr >= MIN_PSNR, (target, f"PSNR {psnr:.1f} dB")
    if source != original:
        shutil.copy2(source, original)
        assert original.read_bytes() == source.read_bytes()
        source.unlink()
    return original.stat().st_size, target.stat().st_size, psnr


def main():
    sources = {path.relative_to(RAW): path for path in RAW.glob("*/*.png")}
    sources.update({path.relative_to(ASSETS): path for path in ASSETS.glob("*/*.png")})
    assert len(sources) == 72, len(sources)
    with ThreadPoolExecutor(max_workers=4) as executor:
        results = list(executor.map(package, sources.values()))
    before, after = sum(r[0] for r in results), sum(r[1] for r in results)
    print(f"72 q{QUALITY} assets with exact alpha: {before:,} -> {after:,} bytes; "
          f"saved {(1 - after / before) * 100:.1f}%; "
          f"lowest visible PSNR {min(r[2] for r in results):.1f} dB")


if __name__ == "__main__":
    main()
