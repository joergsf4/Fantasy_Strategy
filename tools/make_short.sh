#!/bin/sh
# YouTube Short (9:16, 1080x1920) aus dem fertigen Trailer 4: Ausschnitte, gestapelt ueber unscharfem Hintergrund, mit Kopf- und Fusszeile.
# Benutzung: tools/make_short.sh   (braucht out/trailer/trailer4.mp4, siehe tools/make_trailer.sh trailer4)  -> out/trailer/short.mp4
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/out/trailer/trailer4.mp4"
OUT="$ROOT/out/trailer/short.mp4"
# Ausschnitte (Start Dauer): Ueberfahrt mit seekrankem Hund, Robo und Hund, Wuestenkampf, Wurf ueber die Mauer, Laser-Reflektor, Abspann
SEG="41 10 4 6 12 7 34 7 64 9 78.9 1.4"
set -- $SEG
FC=""; IN=""; N=0
while [ $# -gt 0 ]; do
  S=$1; D=$2; shift 2
  FC="$FC[0:v]trim=start=$S:duration=$D,setpts=PTS-STARTPTS[v$N];[0:a]atrim=start=$S:duration=$D,asetpts=PTS-STARTPTS,afade=t=in:d=0.2,afade=t=out:st=$(echo "$D - 0.25" | bc):d=0.25[a$N];"
  IN="$IN[v$N][a$N]"; N=$((N+1))
done
FC="${FC}${IN}concat=n=$N:v=1:a=1[v][a];"
FC="${FC}[v]split[bgs][fgs];[bgs]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=28:6,eq=brightness=-0.18[bg];"
FC="${FC}[fgs]scale=1080:-2[fg];[bg][fg]overlay=0:(H-h)/2[o];"
python3 "$ROOT/tools/short_overlay.py" "$ROOT/out/trailer/short_overlay.png"
FC="${FC}[1:v]format=rgba[ov];[o][ov]overlay=0:0[vo]"
ffmpeg -y -loglevel error -i "$SRC" -i "$ROOT/out/trailer/short_overlay.png" -filter_complex "$FC" -map "[vo]" -map "[a]" -c:v libx264 -crf 21 -preset medium -pix_fmt yuv420p -r 30 -c:a aac -b:a 192k -movflags +faststart "$OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
