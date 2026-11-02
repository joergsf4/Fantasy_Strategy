#!/usr/bin/env python3
"""Schreibt die Kopf- und Fusszeile des YouTube Shorts als transparentes PNG (ffmpeg hat hier kein drawtext). Aufruf: short_overlay.py <ziel.png>"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

FONT = Path(__file__).resolve().parent.parent / "game" / "assets" / "fonts" / "CinzelDecorative-Black.ttf"


def line(d: ImageDraw.ImageDraw, text: str, y: int, size: int, fill: tuple) -> None:
    f = ImageFont.truetype(str(FONT), size)
    w = d.textlength(text, font=f)
    d.text(((1080 - w) / 2, y), text, font=f, fill=fill, stroke_width=7, stroke_fill=(42, 20, 8, 255))


img = Image.new("RGBA", (1080, 1920), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
line(d, "Rundentaktik, die", 90, 66, (242, 193, 78, 255))
line(d, "Spaß macht", 180, 66, (242, 193, 78, 255))
line(d, "Demnächst", 1690, 60, (255, 255, 255, 255))
img.save(sys.argv[1])
