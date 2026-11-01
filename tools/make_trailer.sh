#!/bin/sh
# Nimmt einen Trailer direkt aus dem Spiel auf (feste 30 Bilder/s, mit Musik) und wandelt ihn nach MP4.
# Benutzung: tools/make_trailer.sh            -> Teaser (ca. 40 s)  out/trailer/trailer.mp4
#            tools/make_trailer.sh trailer2   -> Trailer 2 (ca. 2 min)  out/trailer/trailer2.mp4
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:-trailer}"
mkdir -p "$ROOT/out/trailer"
SHOT="$NAME" godot --path "$ROOT/game" --write-movie "$ROOT/out/trailer/${NAME}_raw.avi" --fixed-fps 30 --resolution 1280x720
ffmpeg -y -loglevel error -i "$ROOT/out/trailer/${NAME}_raw.avi" -c:v libx264 -crf 22 -preset medium -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "$ROOT/out/trailer/${NAME}.mp4"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$ROOT/out/trailer/${NAME}.mp4"
