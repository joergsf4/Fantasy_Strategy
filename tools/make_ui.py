#!/usr/bin/env python3
"""Erzeugt die Fantasy-UI-Texturen (Pixel-Art, 4x hochskaliert) nach game/assets/ui/."""
import random
from pathlib import Path
from PIL import Image

OUT = Path(__file__).resolve().parent.parent / "game" / "assets" / "ui"
OUT.mkdir(parents=True, exist_ok=True)
SCALE = 4
SUFFIX = ""

DARK = (13, 10, 20, 255)
GOLD_D = (138, 100, 32, 255)
GOLD = (230, 194, 90, 255)
GOLD_L = (255, 240, 168, 255)
DIM = (92, 74, 42, 255)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def save(im, name):
    name = name.replace(".png", SUFFIX + ".png")
    im.resize((im.width * SCALE, im.height * SCALE), Image.NEAREST).save(OUT / name)


def fill_gradient(im, box, top, bottom, noise=3, seed=1):
    rnd = random.Random(seed)
    x0, y0, x1, y1 = box
    for y in range(y0, y1 + 1):
        t = (y - y0) / max(1, y1 - y0)
        base = lerp(top, bottom, t)
        for x in range(x0, x1 + 1):
            n = rnd.randint(-noise, noise)
            im.putpixel((x, y), (max(0, min(255, base[0] + n)), max(0, min(255, base[1] + n)), max(0, min(255, base[2] + n)), 255))


def frame(im, gold=GOLD, gold_d=GOLD_D, light=GOLD_L):
    w, h = im.size
    for inset, col in ((0, DARK), (1, gold_d), (2, gold), (3, DARK)):
        for x in range(inset, w - inset):
            for y in (inset, h - 1 - inset):
                im.putpixel((x, y), col)
        for y in range(inset, h - inset):
            for x in (inset, w - 1 - inset):
                im.putpixel((x, y), col)
    # Bevel auf der goldenen Linie
    for x in range(2, w - 2):
        im.putpixel((x, 2), light)
        im.putpixel((x, h - 3), gold_d)
    for y in range(2, h - 2):
        im.putpixel((2, y), light)
        im.putpixel((w - 3, y), gold_d)


def stud(im, cx, cy):
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            d = abs(dx) + abs(dy)
            if d == 3:
                im.putpixel((cx + dx, cy + dy), DARK)
            elif d == 2:
                im.putpixel((cx + dx, cy + dy), GOLD)
            elif d <= 1:
                im.putpixel((cx + dx, cy + dy), GOLD_L if d == 0 else GOLD)


def panel(name, top, bottom, size=40, studs=True, inner_line=True):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fill_gradient(im, (4, 4, size - 5, size - 5), top, bottom)
    frame(im)
    if inner_line:
        k = 7
        for i in range(10, size - 10):
            for p in ((i, k), (i, size - 1 - k), (k, i), (size - 1 - k, i)):
                im.putpixel(p, DIM)
    if studs:
        for cx, cy in ((4, 4), (size - 5, 4), (4, size - 5), (size - 5, size - 5)):
            stud(im, cx, cy)
    save(im, name)


def button(name, top, bottom, border, light, pressed=False):
    w, h = 32, 16
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fill_gradient(im, (3, 3, w - 4, h - 4), bottom if pressed else top, top if pressed else bottom, noise=2, seed=5)
    for inset, col in ((0, DARK), (1, border), (2, DARK)):
        for x in range(inset, w - inset):
            for y in (inset, h - 1 - inset):
                im.putpixel((x, y), col)
        for y in range(inset, h - inset):
            for x in (inset, w - 1 - inset):
                im.putpixel((x, y), col)
    if not pressed:
        for x in range(3, w - 3):
            im.putpixel((x, 3), light)
    # abgeschnittene Ecken
    for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        im.putpixel(p, (0, 0, 0, 0))
    save(im, name)


def plate(name):
    w, h = 48, 16
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    top, bottom = (122, 36, 52, 255), (74, 20, 34, 255)
    fill_gradient(im, (5, 2, w - 6, h - 3), top, bottom, noise=2, seed=9)
    for x in range(5, w - 5):
        for y, col in ((1, DARK), (2, GOLD_L), (h - 3, GOLD_D), (h - 2, DARK)):
            im.putpixel((x, y), col)
    # Enden: Schwalbenschwanz
    for side in (0, 1):
        for y in range(1, h - 1):
            for k in range(5):
                x = k if side == 0 else w - 1 - k
                notch = abs(y - h // 2) < (4 - k) * 1.2
                if not notch:
                    t = y / h
                    im.putpixel((x, y), lerp((90, 26, 40, 255), (58, 16, 28, 255), t) if k > 0 else DARK)
        for y in range(1, h - 1):
            x = 0 if side == 0 else w - 1
            im.putpixel((x, y), (0, 0, 0, 0))
    save(im, name)


def bar(name, top, bottom):
    w, h = 16, 8
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fill_gradient(im, (1, 1, w - 2, h - 2), top, bottom, noise=0)
    for x in range(w):
        im.putpixel((x, 0), DARK)
        im.putpixel((x, h - 1), DARK)
    for y in range(h):
        im.putpixel((0, y), DARK)
        im.putpixel((w - 1, y), DARK)
    for x in range(1, w - 1):
        im.putpixel((x, 1), lerp(top, (255, 255, 255, 255), 0.35))
    save(im, name)


def portrait_frame(name):
    s = 24
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    fill_gradient(im, (3, 3, s - 4, s - 4), (30, 34, 54, 255), (18, 20, 34, 255))
    frame(im)
    for cx, cy in ((3, 3), (s - 4, 3), (3, s - 4), (s - 4, s - 4)):
        im.putpixel((cx, cy), GOLD_L)
    save(im, name)


def make_all():
    panel("panel.png", (36, 40, 64, 255), (20, 22, 40, 255))
    panel("panel_dark.png", (24, 26, 44, 255), (12, 13, 26, 255), studs=True)
    panel("panel_small.png", (34, 38, 60, 255), (20, 22, 38, 255), size=24, studs=False, inner_line=False)
    plate("plate.png")
    button("btn_normal.png", (122, 40, 54, 255), (72, 22, 36, 255), GOLD, GOLD_L)
    button("btn_hover.png", (160, 62, 72, 255), (98, 32, 46, 255), GOLD_L, (255, 250, 210, 255))
    button("btn_pressed.png", (96, 30, 44, 255), (52, 14, 26, 255), GOLD_D, GOLD, pressed=True)
    button("btn_disabled.png", (52, 54, 66, 255), (36, 38, 48, 255), (92, 96, 112, 255), (110, 114, 130, 255))
    bar("bar_green.png", (96, 214, 96, 255), (40, 140, 60, 255))
    bar("bar_yellow.png", (240, 216, 80, 255), (190, 150, 40, 255))
    bar("bar_red.png", (236, 90, 80, 255), (160, 40, 44, 255))
    bar("bar_bg.png", (40, 34, 46, 255), (22, 18, 30, 255))
    portrait_frame("frame.png")


make_all()
SCALE, SUFFIX = 2, "_s"   # feine Variante fuer die Kampfoberflaeche
make_all()
print(sorted(p.name for p in OUT.glob("*.png")))
