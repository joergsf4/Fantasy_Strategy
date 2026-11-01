#!/usr/bin/env python3
"""Entfernt den Gruenscreen aus den Figurenbildern und schreibt PNGs mit Alpha.

Der Gruenton unterscheidet sich pro Bild. Deshalb wird die Hintergrundfarbe aus dem
Bildrand geschaetzt und nur zusammenhaengende Gruenflaechen werden entfernt, die den
Rand beruehren oder gross genug sind (Luecken zwischen Arm und Koerper). Gruene
Kleidung bleibt so erhalten.
"""
import sys
from pathlib import Path
import numpy as np
from PIL import Image
from scipy import ndimage as ndi

SRC = Path(__file__).resolve().parent.parent / "strategie"
DST = Path(__file__).resolve().parent.parent / "game" / "assets" / "portraits"

# Bildname (Teil des Dateinamens) -> Figuren-ID
NAMES = {
    "1ilw25": "bienenmaedchen",
    "1zbg22": "museklaugust",
    "356iau": "samurai",
    "3qn25o": "ritter",
    "455gim": "wendy",
    "51gj00": "kungfu",
    "6bzmcc": "ninjas",
    "6nooi7": "elisabeth",
    "96miwt": "robo",
    "btb16a": "hund",
    "kq5h0v": "braumeisterin",
    "o9escf": "maedchen_baer",
    "yh4g19": "claude",
}


def key_image(img: Image.Image, tol: float = 70.0) -> Image.Image:
    rgb = np.asarray(img.convert("RGB")).astype(np.float32)
    h, w, _ = rgb.shape
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    # Randpixel, die gruen aussehen, bestimmen die Hintergrundfarbe
    greenish = border[(border[:, 1] > border[:, 0] + 30) & (border[:, 1] > border[:, 2] + 30)]
    bg = np.median(greenish if len(greenish) else border, axis=0)

    dist = np.linalg.norm(rgb - bg, axis=2)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    green_dom = (g > r + 25) & (g > b + 25)
    cand = (dist < tol) & green_dom

    labels, n = ndi.label(cand)
    sizes = ndi.sum(cand, labels, range(1, n + 1))
    edge_labels = set(np.unique(np.concatenate([labels[0], labels[-1], labels[:, 0], labels[:, -1]]))) - {0}
    bgmask = np.zeros_like(cand)
    strict = dist < 40  # Innenloecher nur entfernen, wenn sie dem Hintergrund fast gleichen (Robo-Auge!)
    for i, s in enumerate(sizes, start=1):
        comp = labels == i
        if i in edge_labels:
            bgmask |= comp
        elif s > 150 and strict[comp].mean() > 0.6:
            bgmask |= comp

    # Kleine Inseln im Vordergrund und Loecher im Hintergrund bereinigen
    fg = ~bgmask
    fg = ndi.binary_opening(fg, iterations=1)
    lab, n = ndi.label(fg)
    if n > 1:
        sz = ndi.sum(fg, lab, range(1, n + 1))
        keep = [i for i, s in enumerate(sz, start=1) if s > 0.002 * h * w]
        fg = np.isin(lab, keep)

    # Weiche Kante: 1px erodieren, dann leicht blurren
    core = ndi.binary_erosion(fg, iterations=1)
    alpha = ndi.gaussian_filter(core.astype(np.float32), 0.8)
    alpha = np.clip(alpha * 1.2 - 0.1, 0, 1)

    # Gruen-Saum entfernen: g auf max(r,b)+kleiner Spielraum klemmen, nur nahe der Kante
    near_edge = ndi.binary_dilation(~core, iterations=3) & fg
    out = rgb.copy()
    cap = np.maximum(r, b) + 8
    out[..., 1] = np.where(near_edge & (g > cap), cap, g)

    rgba = np.dstack([out, alpha * 255]).clip(0, 255).astype(np.uint8)
    im = Image.fromarray(rgba)
    bbox = im.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox()
    return im.crop(bbox) if bbox else im


def neu_portraits() -> None:
    """Neue Bilder aus strategie/neu (Soldaten-Portraits, lachend/wuetend) -> assets/portraits."""
    for f in sorted((SRC / "neu").glob("*.jpg")):
        if f.stem.endswith("_chibi") or f.stem.startswith(("fx_", "bg_")):
            continue
        out = largest_component(key_image(Image.open(f)))
        out.save(DST / f"{f.stem}.png")
        print(f"portrait {f.stem}: {out.size}")


def backgrounds() -> None:
    """Hintergruende (bg_*.jpg aus strategie/neu) -> game/assets/secrets/*.jpg, auf 1920 Pixel Breite verkleinert (ohne Freistellen)."""
    out_dir = DST.parent / "secrets"
    out_dir.mkdir(parents=True, exist_ok=True)
    for f in sorted((SRC / "neu").glob("bg_*.jpg")):
        im = Image.open(f).convert("RGB")
        im = im.resize((1920, round(im.height * 1920 / im.width)), Image.LANCZOS)
        im.save(out_dir / f"{f.stem}.jpg", quality=90)
        print(f"bg {f.stem}: {im.size}")


def main() -> None:
    DST.mkdir(parents=True, exist_ok=True)
    for f in sorted(SRC.glob("*.jpg")):
        fid = next((v for k, v in NAMES.items() if k in f.name), None)
        if fid is None:
            print("uebersprungen:", f.name)
            continue
        out = key_image(Image.open(f))
        out.save(DST / f"{fid}.png")
        print(f"{fid}: {out.size}")




# ---------------------------------------------------------------- Karten-Token (Chibis)
TOKENS = DST.parent / "tokens"
TOKEN_SKIP: set[str] = set()   # Chibis, die (noch) nicht freigestellt werden sollen


def largest_component(im: Image.Image, grow: int = 4) -> Image.Image:
    """Behaelt nur die groesste zusammenhaengende Figur (entfernt Vorlagen-Geister)."""
    a = np.asarray(im)[..., 3] > 40
    lab, n = ndi.label(ndi.binary_dilation(a, iterations=grow))
    if n <= 1:
        return im
    sizes = ndi.sum(a, lab, range(1, n + 1))
    keep = int(np.argmax(sizes)) + 1
    arr = np.array(im)
    arr[..., 3] = np.where(lab == keep, arr[..., 3], 0)
    out = Image.fromarray(arr)
    return out.crop(out.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox())


def fx_sprites() -> None:
    """Effekt-Sprites (fx_*.jpg aus strategie/neu) -> game/assets/fx/*.png, mit grossem Zusammenhalt fuer Funken."""
    out_dir = DST.parent / "fx"
    out_dir.mkdir(parents=True, exist_ok=True)
    for f in sorted((SRC / "neu").glob("fx_*.jpg")):
        out = largest_component(key_image(Image.open(f)), grow=14)
        if f.stem == "fx_zelt":      # Gruenes Hintergrund-Loch im Zelteingang (nicht mit dem Rand verbunden) wird dunkler Innenraum
            a = np.array(out)
            i = a.astype(np.int16)
            g = (i[..., 1] > 100) & (i[..., 1] > i[..., 0] + 55) & (i[..., 1] > i[..., 2] + 40) & (i[..., 3] > 0)
            a[g] = [38, 26, 20, 255]
            out = Image.fromarray(a)
        out.thumbnail((512, 512))
        out.save(out_dir / f"{f.stem}.png")
        print(f"fx {f.stem}: {out.size}")


def tokens() -> None:
    TOKENS.mkdir(parents=True, exist_ok=True)
    for f in sorted((SRC / "neu").glob("*_chibi.jpg")):
        if f.stem in TOKEN_SKIP:
            continue
        out = largest_component(key_image(Image.open(f)))
        name = f.stem.removesuffix("_chibi")
        out.save(TOKENS / f"{name}.png")
        print(f"token {name}: {out.size}")


if __name__ == "__main__":
    sys.exit(backgrounds() if "bg" in sys.argv[1:] else fx_sprites() if "fx" in sys.argv[1:] else tokens() if "tokens" in sys.argv[1:] else (neu_portraits() if "neu" in sys.argv[1:] else main()))
