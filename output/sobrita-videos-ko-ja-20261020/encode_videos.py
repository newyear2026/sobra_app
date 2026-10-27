"""Encode localized Flutter footage and preserve the original AAC soundtrack."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SOURCE = ROOT / 'design/marketing/video-v1/sobrita-promo-es-1080x1920.mp4'
FRAMES = Path('/private/tmp/sobrita-promo-localized-20261020')
LANGUAGES = {
    'ko': ('kor', 'Sobrita — 매일의 가계부에 작은 친구를'),
    'ja': ('jpn', 'Sobrita — 毎日の家計簿に、小さな相棒を'),
}


def run(*args: str) -> None:
    subprocess.run(list(args), check=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('languages', nargs='*')
    args = parser.parse_args()
    selected = args.languages or list(LANGUAGES)
    for language in selected:
        if language not in LANGUAGES:
            parser.error(f'Unsupported language: {language}')
        iso, title = LANGUAGES[language]
        frames = FRAMES / language / 'frames'
        numbered = sorted(frames.glob('*.png'))
        if len(numbered) != 600:
            raise RuntimeError(f'{language}: expected 600 frames, found {len(numbered)}')
        if [p.name for p in numbered] != [f'{i:05d}.png' for i in range(600)]:
            raise RuntimeError(f'{language}: incomplete frame sequence')
        video = HERE / f'sobrita-promo-{language}-1080x1920.mp4'
        run(
            'ffmpeg', '-y', '-hide_banner', '-loglevel', 'warning',
            '-framerate', '30', '-i', str(frames / '%05d.png'),
            '-i', str(SOURCE),
            '-map', '0:v:0', '-map', '1:a:0', '-map_metadata', '-1',
            '-vf', 'fade=t=in:st=0:d=0.15:color=0xfaf5e9,'
                   'fade=t=out:st=19.65:d=0.35:color=0xfaf5e9,format=yuv420p',
            '-c:v', 'libx264', '-preset', 'medium', '-crf', '18',
            '-c:a', 'copy', '-t', '20', '-movflags', '+faststart',
            '-metadata', f'title={title}',
            '-metadata:s:v:0', f'language={iso}',
            '-metadata', 'comment=Localized real app widgets with fictional demo data; original soundtrack preserved.',
            str(video),
        )
        run(
            'ffmpeg', '-y', '-hide_banner', '-loglevel', 'error',
            '-ss', '1', '-i', str(video), '-frames:v', '1',
            '-update', '1', str(HERE / f'sobrita-promo-{language}-poster.jpg'),
        )
        result = subprocess.run(
            ['ffprobe', '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(video)],
            check=True, capture_output=True, text=True,
        )
        probe = json.loads(result.stdout)
        picture = next(s for s in probe['streams'] if s['codec_type'] == 'video')
        sound = next(s for s in probe['streams'] if s['codec_type'] == 'audio')
        assert (picture['width'], picture['height']) == (1080, 1920)
        assert picture['nb_frames'] == '600'
        assert picture['avg_frame_rate'] == '30/1'
        assert abs(float(probe['format']['duration']) - 20) < 0.05
        assert picture['codec_name'] == 'h264'
        assert sound['codec_name'] == 'aac'
        run('ffmpeg', '-v', 'error', '-i', str(video), '-f', 'null', '-')
        (HERE / f'validation-{language}.json').write_text(
            json.dumps(probe, ensure_ascii=False, indent=2) + '\n', encoding='utf-8',
        )
        print(f'Validated {video.name}: 1080x1920, 20 seconds, 600 frames, original AAC', flush=True)


if __name__ == '__main__':
    main()
