#!/bin/sh
# Nimmt den Teaser direkt aus dem Spiel auf (feste 30 Bilder/s, mit Musik) und wandelt ihn nach MP4.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/out/trailer"
SHOT=trailer godot --path "$ROOT/game" --write-movie "$ROOT/out/trailer/trailer_raw.avi" --fixed-fps 30 --resolution 1280x720
ffmpeg -y -loglevel error -i "$ROOT/out/trailer/trailer_raw.avi" -c:v libx264 -crf 22 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "$ROOT/out/trailer/trailer.mp4"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$ROOT/out/trailer/trailer.mp4"
