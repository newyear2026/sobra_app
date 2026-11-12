#!/bin/sh
# Package actual Flutter-rendered frames; no artwork is synthesized here.
set -eu
preview_root='design/seasonal/2026-halloween-dia-de-muertos/motion-v2/previews'
for costume_frames in "$preview_root"/*-frames; do
  costume_name=$(basename "$costume_frames" -frames)
  ffmpeg -hide_banner -loglevel error -y -framerate 10 -i "$costume_frames/%03d.png" -vf 'split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=none' "$preview_root/$costume_name.gif"
done
