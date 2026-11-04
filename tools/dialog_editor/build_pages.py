#!/usr/bin/env python3
"""Baut die Mitmach-Version des Text-Editors fuer GitHub Pages (reine Webseite, ohne Python-Server).

    python3 tools/dialog_editor/build_pages.py [Zielordner]      (Standard: out/pages)

Ergebnis im Zielordner:
  index.html          der Editor (mit <meta name="fz-static">, dadurch laeuft er ohne Server)
  data.json, missions.json, characters.json, secrets.json   Momentaufnahme der Spieldaten (dieselben Antworten wie die API des lokalen Servers)
  assets/portraits/*.png   Portraits, auf 420 Pixel Hoehe verkleinert (der Editor zeigt sie nur klein bis mittelgross)
  assets/fonts/*.ttf       die beiden Schriften des Editors
Die GitHub-Action .github/workflows/pages.yml ruft dieses Skript bei jeder Aenderung an Daten oder Editor auf.
"""
import json
import subprocess
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
sys.path.insert(0, str(HERE))
import server  # noqa: E402  (liefert dieselben Daten wie der lokale Editor)

PORTRAIT_HEIGHT = 420
FONTS = ["CinzelDecorative-Bold.ttf", "IMFeENrm28P.ttf"]


def git(*args: str) -> str:
    try:
        return subprocess.check_output(["git", *args], cwd=ROOT, text=True, stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def write_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")


def build(out: Path) -> dict:
    out.mkdir(parents=True, exist_ok=True)
    meta = {"commit": git("rev-parse", "--short", "HEAD") or "unbekannt", "built": time.strftime("%Y-%m-%d %H:%M"),
            "repo": (git("config", "--get", "remote.origin.url") or "https://github.com/joergsf4/Fantasy_Strategy").removesuffix(".git")}
    data = server.load_all()
    data["_meta"] = meta
    write_json(out / "data.json", data)
    write_json(out / "missions.json", server.missions())
    write_json(out / "characters.json", server.characters())
    write_json(out / "secrets.json", server.secrets())
    html = (HERE / "index.html").read_text(encoding="utf-8")
    marker = "<head>"
    if marker not in html:
        raise SystemExit("index.html ohne <head>")
    html = html.replace(marker, f'{marker}\n<meta name="fz-static" content="1">\n<meta name="fz-repo" content="{meta["repo"]}">', 1)
    (out / "index.html").write_text(html, encoding="utf-8")
    (out / ".nojekyll").write_text("", encoding="utf-8")
    # Bilder und Schriften
    from PIL import Image
    pdir = out / "assets" / "portraits"
    pdir.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in sorted((server.ASSETS / "portraits").glob("*.png")):
        im = Image.open(f)
        if im.height > PORTRAIT_HEIGHT:
            im = im.resize((round(im.width * PORTRAIT_HEIGHT / im.height), PORTRAIT_HEIGHT), Image.LANCZOS)
        im.save(pdir / f.name, optimize=True)
        n += 1
    fdir = out / "assets" / "fonts"
    fdir.mkdir(parents=True, exist_ok=True)
    for name in FONTS:
        (fdir / name).write_bytes((server.ASSETS / "fonts" / name).read_bytes())
    meta["portraits"] = n
    return meta


if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "out" / "pages"
    info = build(target)
    size = sum(p.stat().st_size for p in target.rglob("*") if p.is_file()) / 1e6
    print(f"Pages-Version in {target}: {info['portraits']} Portraits, {size:.1f} MB, Stand {info['commit']} ({info['built']})")
