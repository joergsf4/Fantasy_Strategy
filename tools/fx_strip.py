#!/usr/bin/env python3
"""Setzt die Aufnahmen aus out/fxstrip/<id>_NN.png zu einem Bildstreifen out/gallery/fx_<id>.jpg zusammen."""
import sys
import glob
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
import os
FXDIR = os.environ.get("FXDIR", "fxstrip")
for fid in sys.argv[1:]:
    files = sorted(glob.glob(str(ROOT / "out" / FXDIR / f"{fid}_*.png")))
    if not files:
        print("keine Bilder fuer", fid)
        continue
    n = min(8, len(files))
    pick = [files[round(i * (len(files) - 1) / max(1, n - 1))] for i in range(n)]
    W, H = 640, 360
    cols = 4
    rows = (n + cols - 1) // cols
    sheet = Image.new("RGB", (W * cols, H * rows), (20, 20, 28))
    d = ImageDraw.Draw(sheet)
    for i, f in enumerate(pick):
        im = Image.open(f).convert("RGB")
        # Ausschnitt um die Mitte (Aktion), dann verkleinern
        w, h = im.size
        im = im.crop((int(w * 0.12), int(h * 0.1), int(w * 0.88), int(h * 0.9))).resize((W, H))
        sheet.paste(im, ((i % cols) * W, (i // cols) * H))
        t = int(Path(f).stem.split("_")[-1]) * 0.15
        d.text(((i % cols) * W + 8, (i // cols) * H + 6), f"{t:.2f} s", fill=(255, 255, 255))
    out = ROOT / "out" / "gallery" / f"fx_{fid}.jpg"
    sheet.save(out, quality=88)
    print(out)
