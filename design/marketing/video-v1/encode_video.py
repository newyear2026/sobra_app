"""Encode the real Flutter capture frames and the original synthesized score."""
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
output = HERE / 'sobrita-promo-es-1080x1920.mp4'
subprocess.run([
    'ffmpeg', '-y', '-hide_banner', '-loglevel', 'warning',
    '-framerate', '30', '-i', str(HERE/'frames/%05d.png'),
    '-i', str(HERE/'sobrita-original-music.wav'),
    '-map', '0:v:0', '-map', '1:a:0',
    '-vf', 'fade=t=in:st=0:d=0.15:color=0xfaf5e9,fade=t=out:st=19.65:d=0.35:color=0xfaf5e9,format=yuv420p',
    '-af', 'loudnorm=I=-19:TP=-2:LRA=7',
    '-c:v', 'libx264', '-preset', 'medium', '-crf', '18',
    '-c:a', 'aac', '-b:a', '192k', '-ar', '48000',
    '-t', '20', '-movflags', '+faststart',
    '-metadata', 'title=Sobrita — Tu quincena, con compañía',
    '-metadata', 'comment=Real app widgets with fictional demo data; original synthesized music.',
    str(output),
], check=True)
subprocess.run([
    'ffmpeg', '-y', '-hide_banner', '-loglevel', 'warning',
    '-ss', '1.0', '-i', str(output), '-frames:v', '1', '-update', '1',
    str(HERE/'sobrita-promo-poster.jpg'),
], check=True)
print(output)
