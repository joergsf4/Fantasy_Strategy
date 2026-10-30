#!/usr/bin/env python3
"""Thumbnail 1920x1080: Karte als Hintergrund (SHOT=mapshot), grosse Helden, goldener Titel. Ausgabe: out/thumbnail/thumbnail.png"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance, ImageChops

ROOT = Path(__file__).resolve().parent.parent
PORT = ROOT / "game" / "assets" / "portraits"
FONT_T = str(ROOT / "game" / "assets" / "fonts" / "CinzelDecorative-Black.ttf")
FONT_B = str(ROOT / "game" / "assets" / "fonts" / "CinzelDecorative-Bold.ttf")
OUT = ROOT / "out" / "thumbnail"
W, H = 1920, 1080


def background():
    bg = Image.open(OUT / "map_bg.png").convert("RGB").resize((W, H), Image.LANCZOS)
    bg = bg.filter(ImageFilter.GaussianBlur(2.2))
    bg = ImageEnhance.Color(bg).enhance(1.25)
    bg = ImageEnhance.Brightness(bg).enhance(0.8)
    # Vignette
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse((-W * 0.2, -H * 0.25, W * 1.2, H * 1.25), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(200))
    dark = Image.new("RGB", (W, H), (6, 8, 20))
    return Image.composite(bg, dark, mask)


def cutout(name, height, flip=False):
    im = Image.open(PORT / f"{name}.png").convert("RGBA")
    if flip:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    k = height / im.height
    return im.resize((round(im.width * k), height), Image.LANCZOS)


def place(canvas, im, x, y, glow=(255, 214, 120)):
    """Mit Schatten und goldenem Schein hinter der Figur einsetzen."""
    a = im.getchannel("A")
    sh = Image.new("RGBA", im.size, (0, 0, 0, 0))
    sh.putalpha(a.point(lambda v: int(v * 0.65)))
    sh = sh.filter(ImageFilter.GaussianBlur(24))
    canvas.alpha_composite(sh, (x + 18, y + 24))
    halo = Image.new("RGBA", im.size, glow + (0,))
    halo.putalpha(a.filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.55)))
    canvas.alpha_composite(halo, (x, y))
    canvas.alpha_composite(im, (x, y))


def gold_text(canvas, text, font_path, size, center_x, y, stroke=16):
    f = ImageFont.truetype(font_path, size)
    d0 = ImageDraw.Draw(canvas)
    w = d0.textlength(text, font=f)
    x = center_x - w / 2
    # Schlagschatten
    sh = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((x + 10, y + 14), text, font=f, fill=(0, 0, 0, 200), stroke_width=stroke, stroke_fill=(0, 0, 0, 200))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(8)))
    # dunkle Kontur
    d0.text((x, y), text, font=f, fill=(40, 20, 8), stroke_width=stroke, stroke_fill=(40, 20, 8))
    # Goldverlauf
    mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(mask).text((x, y), text, font=f, fill=255)
    grad = Image.new("RGBA", canvas.size)
    gd = ImageDraw.Draw(grad)
    top, mid, bot = (255, 245, 190), (255, 205, 90), (190, 120, 40)
    y0, y1 = y, y + size * 1.15
    for yy in range(max(0, int(y0)), min(H, int(y1) + 1)):
        t = (yy - y0) / (y1 - y0)
        c = tuple(int(top[i] + (mid[i] - top[i]) * t / 0.5) for i in range(3)) if t < 0.5 else tuple(int(mid[i] + (bot[i] - mid[i]) * (t - 0.5) / 0.5) for i in range(3))
        gd.line([(0, yy), (W, yy)], fill=c + (255,))
    canvas.paste(grad, (0, 0), mask)
    return w


def main():
    c = background().convert("RGBA")
    # hinten: Gegnerin und Ritter, vorn: Mira und Takeda, Seiten: Elisabeth, Robo
    place(c, cutout("robo", 780), 1010, 320, glow=(255, 190, 110))
    place(c, cutout("ritter", 840), 250, 250)
    place(c, cutout("elisabeth_lachend", 700), -10, 380)
    place(c, cutout("maedchen_baer_lachend", 900), 560, 300)
    place(c, cutout("samurai_wuetend", 780), 1480, 330, glow=(255, 150, 90))
    # Abdunklung oben fuer den Titel
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for yy in range(0, 520):
        sd.line([(0, yy), (W, yy)], fill=(5, 8, 20, int(200 * (1 - yy / 520) ** 1.6)))
    c.alpha_composite(shade)
    gold_text(c, "STRATEGY", FONT_T, 150, W / 2, 20)
    gold_text(c, "FANTASY", FONT_T, 232, W / 2, 140)
    # Unterzeile
    band = Image.new("RGBA", (W, 110), (0, 0, 0, 0))
    bd = ImageDraw.Draw(band)
    for yy in range(110):
        bd.line([(0, yy), (W, yy)], fill=(8, 6, 16, int(210 * min(1, yy / 40))))
    c.alpha_composite(band, (0, H - 110))
    f = ImageFont.truetype(FONT_B, 44)
    d = ImageDraw.Draw(c)
    txt = "Rundentaktik  ·  13 Helden  ·  Lebendige 3D-Karten"
    w = d.textlength(txt, font=f)
    d.text(((W - w) / 2, H - 78), txt, font=f, fill=(250, 232, 190), stroke_width=6, stroke_fill=(30, 16, 8))
    out = OUT / "thumbnail.png"
    c.convert("RGB").save(out)
    c.convert("RGB").resize((1280, 720), Image.LANCZOS).save(OUT / "thumbnail_1280.jpg", quality=92)
    print(out)


main()
