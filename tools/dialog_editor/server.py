#!/usr/bin/env python3
"""Dialog-Editor: lokale Weboberflaeche fuer alle Gespraeche des Spiels (nur Standardbibliothek).

Start:  python3 tools/dialog_editor/server.py   -> http://127.0.0.1:8765
Liest und schreibt game/data/story_<id>.json (Einleitung/Abschluss) sowie in game/data/missions/<id>.json
nur `triggers`, `flee` und `ideas`. Alles andere in diesen Dateien bleibt unveraendert.
"""
import glob
import json
import mimetypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "game" / "data"
ASSETS = ROOT / "game" / "assets"
WEB = Path(__file__).resolve().parent
PORT = int(os.environ.get("PORT", "8765"))
EXTRA_SPEAKERS = {"mutter": "Lieselotte", "$hero": "Auslösende Figur"}   # Sprecher ohne Kampfeinheit
CHAPTER_RE = re.compile(r"^ch\d+$")


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_atomic(path: Path, data) -> None:
    """Schreibt im Format der uebrigen Dateien (Einzug 1, kein Zeilenende) und ersetzt die Datei erst nach vollstaendigem Schreiben."""
    fd, tmp = tempfile.mkstemp(dir=path.parent, suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
    os.replace(tmp, path)


def chapter_ids() -> list:
    return sorted((Path(p).stem for p in glob.glob(str(DATA / "missions" / "ch*.json"))), key=lambda s: int(s[2:]))


def load_all() -> dict:
    units = read(DATA / "units.json")
    heroes = set()
    for cid in chapter_ids():
        m = read(DATA / "missions" / f"{cid}.json")
        heroes |= {p["id"] for p in read(ROOT / "game" / m["map"].removeprefix("res://"))["players"]}
    portraits = {p.stem for p in (ASSETS / "portraits").glob("*.png")}
    out_units = {}
    for uid, u in units.items():
        if uid.startswith("_") or "name" not in u:
            continue
        out_units[uid] = {"name": u["name"], "hero": uid in heroes, "flees": bool(u.get("flees")),
                          "exprs": [e for e in ("lachend", "wuetend") if f"{uid}_{e}" in portraits], "portrait": uid in portraits}
    for uid, name in EXTRA_SPEAKERS.items():
        out_units[uid] = {"name": name, "hero": False, "flees": False, "special": True,
                          "exprs": [e for e in ("lachend", "wuetend") if f"{uid}_{e}" in portraits], "portrait": uid in portraits}
    abilities = {k: v["name"] for k, v in read(DATA / "abilities.json").items() if not k.startswith("_")}
    chapters = []
    for cid in chapter_ids():
        m = read(DATA / "missions" / f"{cid}.json")
        s = read(DATA / f"story_{cid}.json")
        mp = read(ROOT / "game" / m["map"].removeprefix("res://"))
        chapters.append({"id": cid, "title": m["title"], "players": [e["id"] for e in mp["players"]],
                         "objects": [{"id": o["id"], "type": o["type"]} for o in mp.get("objects", [])], "briefing": m.get("briefing", ""), "intro": s["intro"], "outro": s["outro"],
                         "triggers": m.get("triggers", []), "flee": m.get("flee", {}), "ideas": m.get("ideas", [])})
    return {"chapters": chapters, "units": out_units, "abilities": abilities}


# ---------------------------------------------------------------- Pruefung (Vertrauensgrenze: nichts Kaputtes in die Spieldaten)
def check_lines(lines, where: str, speakers: set) -> None:
    if not isinstance(lines, list):
        raise ValueError(f"{where}: Zeilen muessen eine Liste sein")
    for i, l in enumerate(lines):
        w = f"{where}, Zeile {i + 1}"
        if not isinstance(l, dict):
            raise ValueError(f"{w}: kein Objekt")
        if not isinstance(l.get("text", l.get("text_by")), (str, dict)) or ("text" not in l and "text_by" not in l):
            raise ValueError(f"{w}: Text fehlt")
        for k in ("left", "right", "speaker"):
            if k in l and l[k] not in speakers:
                raise ValueError(f"{w}: unbekannte Figur '{l[k]}' in '{k}'")
        if l.get("speaker") not in (l.get("left"), l.get("right")):
            raise ValueError(f"{w}: Sprecher muss links oder rechts stehen")


def check_chapter(body: dict, speakers: set, abilities: set) -> None:
    check_lines(body["intro"], "Einleitung", speakers)
    check_lines(body["outro"], "Abschluss", speakers)
    for i, t in enumerate(body["triggers"]):
        w = f"Gespraech {i + 1}"
        if not isinstance(t.get("when"), dict) or not t["when"] or not isinstance(t.get("do"), list):
            raise ValueError(f"{w}: Ausloeser oder Schritte fehlen")
        for step in t["do"]:
            if "dialogue" in step:
                check_lines(step["dialogue"], w, speakers)
    for uid, lines in body["flee"].items():
        check_lines(lines, f"Rueckzug {uid}", speakers)
    if not isinstance(body["ideas"], list):
        raise ValueError("Ideen muessen eine Liste sein")


def tidy(body: dict) -> None:
    """Tippfehler-Hygiene beim Speichern: doppelte Leerzeichen zusammenziehen, Raender abschneiden."""
    def fix(t):
        return re.sub(r" {2,}", " ", t).strip()
    all_lines = body["intro"] + body["outro"] + [l for lines in body["flee"].values() for l in lines]
    all_lines += [l for t in body["triggers"] for step in t["do"] for l in step.get("dialogue", [])]
    for t in body["triggers"]:
        t["do"] = [step for step in t["do"] if step.get("dialogue", True) != []]   # leere Dialogschritte sind Ueberbleibsel
    for l in all_lines:
        if isinstance(l.get("text"), str):
            l["text"] = fix(l["text"])
        if isinstance(l.get("text_by"), dict):
            l["text_by"] = {k: fix(v) for k, v in l["text_by"].items()}


def save_chapter(cid: str, body: dict) -> None:
    if not CHAPTER_RE.match(cid) or cid not in chapter_ids():
        raise ValueError("unbekanntes Kapitel")
    data = load_all()
    check_chapter(body, set(data["units"]), set(data["abilities"]))
    tidy(body)
    story = read(DATA / f"story_{cid}.json")
    story["intro"], story["outro"] = body["intro"], body["outro"]
    mission = read(DATA / "missions" / f"{cid}.json")
    mission["triggers"] = body["triggers"]
    for key in ("flee", "ideas"):
        if body[key]:
            mission[key] = body[key]
        else:
            mission.pop(key, None)
    write_atomic(DATA / f"story_{cid}.json", story)
    write_atomic(DATA / "missions" / f"{cid}.json", mission)


# ---------------------------------------------------------------- Entwurf per Claude (nur auf Knopfdruck, kostet Token)
def find_claude():
    p = shutil.which("claude")
    if p:
        return p
    found = sorted(glob.glob(str(Path.home() / ".vscode/extensions/anthropic.claude-code-*/resources/native-binary/claude")))
    return found[-1] if found else None


SCHEMA = """Du hilfst beim Schreiben von Gespraechen fuer ein deutschsprachiges Fantasy-Rundenstrategiespiel (Humor, Anime-Dialoge).
Ein Gespraech besteht aus einem Ausloeser (when), optionaler Bedingung (if) und Zeilen (lines).
when (genau EIN Schluessel): {"turn": N} | {"enter": [x, y]} | {"object": {"id": "...", "state": "..."}} | {"heal": {"by": "id", "targets": N}}
 | {"ability": {"id": "faehigkeit", "by": "id"}} | {"kill": {"id": "id", "count": N}} | {"first_kill": true} | {"fall": {"id": "id"}}
 | {"hp_below": {"id": "id", "ratio": 0.5}} | {"near": {"a": "id", "b": "id oder any_enemy", "dist": N}} | {"enemies_left": N}
if (optional): {"present": ["id"], "absent": ["id"], "fled": ["id"], "object": {"id": "...", "state": "..."}}
lines: Liste von {"left": "id", "right": "id", "speaker": "id (muss left oder right sein)", "text": "...", "left_expr": "lachend|wuetend (optional)", "right_expr": ...}.
"$hero" ist der Platzhalter fuer die Figur, die das Ereignis ausloest.
Figuren (id = Name): %s
Faehigkeiten (id = Name): %s
Antworte NUR mit einem JSON-Objekt {"when": ..., "if": ... (weglassen wenn nicht noetig), "lines": [...]} ohne Erklaerung und ohne Codeblock. 2 bis 5 Zeilen, in der Stimme der Figuren."""


def draft(text: str, chapter: str) -> dict:
    exe = find_claude()
    if not exe:
        raise LookupError("Claude-CLI nicht gefunden")
    data = load_all()
    units = ", ".join(f"{k} = {v['name']}" for k, v in data["units"].items() if not v.get("special"))
    prompt = SCHEMA % (units, ", ".join(f"{k} = {v}" for k, v in data["abilities"].items()))
    prompt += f"\n\nKapitel: {chapter}\nBeschreibung von Nutzerin oder Nutzer: {text}"
    r = subprocess.run([exe, "-p", prompt], capture_output=True, text=True, timeout=240)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip()[:300] or "Claude hat einen Fehler gemeldet")
    m = re.search(r"\{.*\}", r.stdout, re.S)
    if not m:
        raise RuntimeError("Antwort enthielt kein JSON")
    out = json.loads(m.group(0))
    if not isinstance(out.get("when"), dict) or not out["when"]:
        raise RuntimeError("Entwurf ohne gueltigen Ausloeser")
    check_lines(out.get("lines", []), "Entwurf", set(data["units"]))
    return out


# ---------------------------------------------------------------- HTTP
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _json(self, code: int, obj) -> None:
        self._send(code, json.dumps(obj, ensure_ascii=False).encode(), "application/json; charset=utf-8")

    def _body(self) -> dict:
        return json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")

    def do_GET(self) -> None:
        path = self.path.split("?")[0]
        if path == "/api/data":
            return self._json(200, load_all())
        if path == "/api/draft/available":
            return self._json(200, {"available": find_claude() is not None})
        if path == "/":
            path = "/index.html"
        base, rel = (ASSETS, path[len("/assets/"):]) if path.startswith("/assets/") else (WEB, path.lstrip("/"))
        f = (base / rel).resolve()
        if base.resolve() not in f.parents or not f.is_file():
            return self._send(404, b"nicht gefunden", "text/plain")
        self._send(200, f.read_bytes(), mimetypes.guess_type(f.name)[0] or "application/octet-stream")

    def do_PUT(self) -> None:
        m = re.match(r"^/api/chapter/(ch\d+)$", self.path)
        if not m:
            return self._json(404, {"error": "unbekannt"})
        try:
            save_chapter(m.group(1), self._body())
            self._json(200, {"ok": True})
        except (ValueError, KeyError, TypeError) as e:
            self._json(400, {"error": str(e)})

    def do_POST(self) -> None:
        if self.path != "/api/draft":
            return self._json(404, {"error": "unbekannt"})
        try:
            b = self._body()
            self._json(200, draft(str(b["text"]), str(b.get("chapter", ""))))
        except LookupError as e:
            self._json(501, {"error": str(e)})
        except (RuntimeError, ValueError, KeyError, subprocess.TimeoutExpired) as e:
            self._json(502, {"error": str(e) or "Zeitueberschreitung"})


def main() -> None:
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)   # nur lokal erreichbar
    print(f"Dialog-Editor laeuft auf http://127.0.0.1:{PORT}  (Strg+C beendet)")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        sys.exit(0)


if __name__ == "__main__":
    main()
