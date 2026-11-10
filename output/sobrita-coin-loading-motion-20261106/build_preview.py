"""Encode image-generated keyframes as a local motion preview.
No art is drawn here: FFmpeg crops the generated sheet and composites it over
the image-generated background plate, then encodes the animation.
"""
from pathlib import Path
import json
import subprocess

ROOT = Path(__file__).resolve().parent
DATA = json.loads((ROOT / "motion.json").read_text())
FRAMES = ROOT / "frames"
FRAMES.mkdir(exist_ok=True)

def run(args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args],
                   check=True, cwd=ROOT)

# The generated 1448x1086 sheet is exactly 4x3 cells of 362px.
# Preserve a fixed tile and ground position throughout the one-shot action.
for index in range(12):
    col, row = index % 4, index // 4
    filters = (
        f"[0:v]crop=362:362:{col*362}:{row*362},format=rgba[actor];"
        "[1:v]scale=426:922:flags=lanczos,format=rgba[plate];"
        "[plate][actor]overlay=42:350:format=auto,format=rgb24[out]"
    )
    run(["-i", "sprite-sheet.png", "-i", "background.png",
         "-filter_complex", filters, "-map", "[out]",
         "-frames:v", "1", f"frames/{index:02}.png"])

durations = DATA["frameDurationsMs"].copy()
durations[-1] += DATA["previewHoldMs"]
concat = ["ffconcat version 1.0"]
for index, duration in enumerate(durations):
    concat += [f"file 'frames/{index:02}.png'", f"duration {duration/1000:.3f}"]
concat += ["file 'frames/11.png'"]
(ROOT / "frames.ffconcat").write_text("\n".join(concat) + "\n")
run(["-f", "concat", "-safe", "0", "-i", "frames.ffconcat",
     "-vf", "fps=50,format=yuv420p", "-t", "3.5",
     "-c:v", "libx264", "-preset", "medium", "-crf", "18",
     "-movflags", "+faststart", "-an", "coin-loading-preview.mp4"])
run(["-f", "concat", "-safe", "0", "-i", "frames.ffconcat",
     "-filter_complex",
     "[0:v]fps=50,split[a][b];[a]palettegen=stats_mode=diff:reserve_transparent=0[p];"
     "[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle",
     "-t", "3.5", "-loop", "0", "coin-loading-preview.gif"])
print("Created 12 frames, 2.5-second action + 1-second preview hold, GIF and MP4.")

