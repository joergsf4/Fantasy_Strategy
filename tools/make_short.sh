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
# Bildausschnitt je Abschnitt: "n" = schmaler Mittelstreifen (576 von 1280 Pixeln Breite, 4:5) fuer Kampf, Dialog und Faehigkeiten,
# "w" = breiterer Ausschnitt (960 Pixel) fuer Titelbild, geheime Szene mit Auftritt und Abspann, deren Schrift sonst abgeschnitten wuerde.
# Abschnitte: Start, Ende, Art
SEGS="0 5.0 w 5.0 27.0 n 27.0 32.4 w 32.4 35.4 n 35.4 99 w"
set -- $SEGS
FC=""; IN=""; N=0
while [ $# -gt 0 ]; do
  S=$1; E=$2; K=$3; shift 3
  if [ "$K" = "w" ]; then CROP="crop=960:720:160:0,scale=1080:810:flags=lanczos"; else CROP="crop=576:720:352:0,scale=1080:1350:flags=lanczos"; fi
  FC="${FC}[0:v]trim=start=$S:end=$E,setpts=PTS-STARTPTS,split[b$N][f$N];[b$N]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=28:6,eq=brightness=-0.22[bg$N];[f$N]${CROP}[fg$N];[bg$N][fg$N]overlay=0:(H-h)/2[c$N];"
  IN="$IN[c$N]"; N=$((N+1))
done
FC="${FC}${IN}concat=n=$N:v=1:a=0[o];[1:v]format=rgba[ov];[o][ov]overlay=0:0[vo]"
ffmpeg -y -loglevel error -i "$RAW" -i "$ROOT/out/trailer/short_overlay.png" -filter_complex "$FC" -map "[vo]" -map 0:a -c:v libx264 -crf 21 -preset medium -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k -movflags +faststart "$OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
