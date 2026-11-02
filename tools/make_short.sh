#!/bin/sh
# YouTube Short (9:16, 1080x1920): nimmt den Short direkt aus dem Spiel auf (game/scripts/short_clip.gd) und setzt das 16:9-Bild
# ueber einen unscharfen, abgedunkelten Hintergrund mit Kopf- und Fusszeile. Ergebnis: out/trailer/short.mp4
# Benutzung: tools/make_short.sh          -> aufnehmen und umwandeln
#            tools/make_short.sh compose  -> nur umwandeln (out/trailer/short_raw.avi vorhanden)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAW="$ROOT/out/trailer/short_raw.avi"
OUT="$ROOT/out/trailer/short.mp4"
mkdir -p "$ROOT/out/trailer"
if [ "$1" != "compose" ]; then
  SHOT=short godot --path "$ROOT/game" --write-movie "$RAW" --fixed-fps 30 --resolution 1280x720
fi
python3 "$ROOT/tools/short_overlay.py" "$ROOT/out/trailer/short_overlay.png"
FC="[0:v]split[bgs][fgs];[bgs]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=28:6,eq=brightness=-0.18[bg];"
FC="${FC}[fgs]scale=1080:-2[fg];[bg][fg]overlay=0:(H-h)/2[o];[1:v]format=rgba[ov];[o][ov]overlay=0:0[vo]"
ffmpeg -y -loglevel error -i "$RAW" -i "$ROOT/out/trailer/short_overlay.png" -filter_complex "$FC" -map "[vo]" -map 0:a -c:v libx264 -crf 21 -preset medium -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k -movflags +faststart "$OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
