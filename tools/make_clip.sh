#!/bin/sh
# Nimmt ein Geheimnis im Spiel auf (Szene und Effekt mit Ton) und oeffnet das Video:  tools/make_clip.sh futter_fuer_brumm
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ID="${1:-futter_fuer_brumm}"
mkdir -p "$ROOT/out/clips"
CLIP_SECRET="$ID" SHOT=secretclip godot --path "$ROOT/game" --write-movie "$ROOT/out/clips/${ID}_raw.avi" --fixed-fps 30 --resolution 1280x720
ffmpeg -y -loglevel error -i "$ROOT/out/clips/${ID}_raw.avi" -c:v libx264 -crf 22 -preset medium -pix_fmt yuv420p -c:a aac -b:a 160k -movflags +faststart "$ROOT/out/clips/${ID}.mp4"
echo "$ROOT/out/clips/${ID}.mp4"
