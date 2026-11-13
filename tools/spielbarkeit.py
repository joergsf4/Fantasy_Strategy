#!/usr/bin/env python3
"""Spielbarkeit aller Missionen mit dem Spieltest-Bot (game/scripts/bot/), langer Lauf mit Varianten.

Benutzung:
  python3 tools/spielbarkeit.py                       # alle Missionen, alle Varianten, 3 Stile
  python3 tools/spielbarkeit.py --scale 0.1 --styles 1   # schneller Probelauf
  python3 tools/spielbarkeit.py --missions ch5,ch8       # nur diese Missionen
  python3 tools/spielbarkeit.py --resume                 # abgebrochenen Lauf fortsetzen
  python3 tools/spielbarkeit.py --report                 # nur Bericht aus gespeicherten Ergebnissen

Varianten je Mission: Standard, zufaellige regelkonforme Gruppen, ohne / beste Ausruestung, weniger / keine / nur
Angriffs-Talentpunkte, jede Faehigkeit der Standardgruppe einzeln gesperrt, leerer Rucksack, ohne zurueckkehrende Gegner,
anderer Zufallsstart. Jede Variante laeuft mit bis zu drei Stilen (normal, vorsichtig, forsch); sie gilt als schaffbar, wenn
ein Stil gewinnt. Ein Bot-Sieg beweist, dass die Mission schaffbar ist, eine Niederlage nicht das Gegenteil.

Ergebnisse: out/spielbarkeit/results.jsonl, Bericht: docs/spielbarkeit.md
"""
import argparse
import datetime
import json
import math
import os
import random
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
OUT = ROOT / "out" / "spielbarkeit"
RESULTS = OUT / "results.jsonl"
META = OUT / "missionen.json"
REPORT = ROOT / "docs" / "spielbarkeit.md"
STYLES = [("normal", {"caution": 1.0}), ("vorsichtig", {"caution": 1.6}), ("forsch", {"caution": 0.6})]
WORKERS = max(1, (os.cpu_count() or 4) - 1)


def godot(args, log=None):
    cmd = ["godot", "--headless", "--path", str(GAME), "--script", "scripts/bot/bot_run.gd", "--"] + args
    return subprocess.Popen(cmd, stdout=log or subprocess.DEVNULL, stderr=subprocess.STDOUT)


def load_meta():
    OUT.mkdir(parents=True, exist_ok=True)
    godot([f"list={META}"]).wait()
    meta = json.loads(META.read_text())
    return dict(sorted(meta.items(), key=lambda kv: kv[1]["order"]))


def variants(cid, m, rnd, n_squads):
    """Varianten einer Mission: [(Name, Achse, variant, banned)]."""
    out = [("Standard", "standard", {}, {})]
    if not m["fixed_squad"]:
        free = [h for h in m["roster"] if h not in m["fixed"]]
        k = len(m["squad"]) - len(m["fixed"])
        seen = {tuple(sorted(m["squad"]))}
        tries = 0
        while len([v for v in out if v[1] == "gruppe"]) < n_squads and tries < 400 and k > 0 and len(free) >= k:
            tries += 1
            sq = m["fixed"] + rnd.sample(free, k)
            key = tuple(sorted(sq))
            if key in seen:
                continue
            seen.add(key)
            out.append(("Gruppe " + ", ".join(sq), "gruppe", {"squad": sq}, {}))
    out.append(("ohne Ausrüstung", "ausruestung", {"gear": "none"}, {}))
    out.append(("beste Ausrüstung", "ausruestung", {"gear": "best"}, {}))
    if m["points"] > 0:
        out.append(("ein Talentpunkt weniger", "talente", {"talents": {"delta": -1}}, {}))
        out.append(("keine Talentpunkte", "talente", {"talents": {"mode": "zero"}}, {}))
        out.append(("Talente nur Angriff", "talente", {"talents": {"mode": "atk"}}, {}))
    for hero, abs_ in m["abilities"].items():
        for ab in abs_:
            out.append((f"ohne {ab} ({hero})", "faehigkeit", {}, {hero: [ab]}))
    out.append(("leerer Rucksack", "sonder", {"inventory": "none"}, {}))
    if m["nemesis"]:
        out.append(("ohne zurückkehrende Gegner", "sonder", {"nemesis": "none"}, {}))
    out.append(("anderer Zufallsstart", "sonder", {"seed": 7}, {}))
    return out


def build_jobs(meta, scale, n_styles, missions):
    jobs = []
    for cid, m in meta.items():
        if missions and cid not in missions:
            continue
        rnd = random.Random(4100 + m["order"])
        vs = variants(cid, m, rnd, max(1, round(20 * scale)) if scale < 1 else 20)
        if scale < 1:      # Probelauf: Standard immer, dazu ein Anteil der uebrigen Varianten
            keep = vs[:1] + [v for i, v in enumerate(vs[1:]) if rnd.random() < scale]
            vs = keep
        for vi, (name, axis, var, banned) in enumerate(vs):
            for sname, style in STYLES[:n_styles]:
                jobs.append({"id": f"{cid}|{vi}|{sname}", "mission": cid, "variant": var, "banned": banned, "style": style,
                             "name": name, "axis": axis, "style_name": sname})
    return jobs


def run(jobs):
    """Verteilt die Jobs auf parallele Godot-Prozesse; jeder schreibt eine JSON-Zeile je Kampf."""
    for f in OUT.glob("part_*.jsonl"):
        f.unlink()
    # lange Missionen zuerst gleichmaessig verteilen: reihum
    parts = [jobs[w::WORKERS] for w in range(WORKERS)]
    procs = []
    t0 = time.time()
    for w, part in enumerate(parts):
        if not part:
            continue
        jf, of = OUT / f"job_{w}.json", OUT / f"part_{w}.jsonl"
        jf.write_text(json.dumps({"jobs": part}))
        log = open(OUT / f"log_{w}.txt", "w")
        procs.append((w, godot([f"job={jf}", f"out={of}"], log), log))
    total = len(jobs)
    while any(p.poll() is None for _, p, _ in procs):
        time.sleep(5)
        done = sum(sum(1 for _ in open(OUT / f"part_{w}.jsonl")) for w, _, _ in procs if (OUT / f"part_{w}.jsonl").exists())
        el = time.time() - t0
        eta = el / done * (total - done) if done else 0
        print(f"\r  {done}/{total} Kämpfe, {el / 60:.1f} min, Rest ca. {eta / 60:.1f} min   ", end="", flush=True)
    print()
    for _, _, log in procs:
        log.close()
    by_id = {j["id"]: j for j in jobs}
    with open(RESULTS, "a") as out:
        for w, _, _ in procs:
            pf = OUT / f"part_{w}.jsonl"
            if not pf.exists():
                continue
            for line in open(pf):
                try:
                    r = json.loads(line)
                except json.JSONDecodeError:
                    continue
                j = by_id.get(r["id"], {})
                r.update({k: j.get(k) for k in ("name", "axis", "style_name", "variant", "banned")})
                out.write(json.dumps(r, ensure_ascii=False) + "\n")
    missing = set(by_id) - done_ids()
    if missing:
        print(f"  {len(missing)} Kämpfe ohne Ergebnis (Absturz?), siehe out/spielbarkeit/log_*.txt")


def done_ids():
    if not RESULTS.exists():
        return set()
    return {json.loads(l)["id"] for l in open(RESULTS) if l.strip()}


def pct(a, b):
    return f"{a / b:.0%}" if b else "–"


def report(meta):
    rows = [json.loads(l) for l in open(RESULTS) if l.strip()] if RESULTS.exists() else []
    if not rows:
        print("keine Ergebnisse")
        return
    units = json.loads((GAME / "data" / "units.json").read_text())
    abil = json.loads((GAME / "data" / "abilities.json").read_text())
    name = lambda h: units.get(h, {}).get("name", h)
    abname = lambda a: abil.get(a, {}).get("name", a) if isinstance(abil.get(a), dict) else a
    # Variante = Mission + Index; schaffbar, wenn ein Stil gewinnt
    var = {}
    for r in rows:
        cid, vi, _ = r["id"].split("|")
        v = var.setdefault((cid, int(vi)), {"cid": cid, "name": r.get("name"), "axis": r.get("axis"), "runs": []})
        v["runs"].append(r)
    for v in var.values():
        v["ok"] = any(x["won"] for x in v["runs"])
        v["best"] = min((x for x in v["runs"] if x["won"]), key=lambda x: x["turns"], default=None)
    commit = subprocess.run(["git", "rev-parse", "--short", "HEAD"], cwd=ROOT, capture_output=True, text=True).stdout.strip()
    L = ["# Spielbarkeit aller Missionen", "",
         f"Erzeugt von `tools/spielbarkeit.py` am {datetime.date.today():%d.%m.%Y} (Stand `{commit}`), {len(rows)} Kämpfe.",
         "Ein Bot (`game/scripts/bot/`) spielt den echten Kampf über dieselben Klicks und Menüknöpfe wie ein Mensch, Schwierigkeit „Normal“. "
         "Jede Variante läuft mit bis zu drei Spielstilen (normal, vorsichtig, forsch) und gilt als **schaffbar**, wenn ein Stil gewinnt. "
         "**Ein Bot-Sieg beweist, dass die Mission schaffbar ist; eine Bot-Niederlage beweist nicht das Gegenteil**, der Bot ist schwächer als ein Mensch.", "",
         "## Übersicht", "",
         "| Mission | Standard | Gruppen | ohne / beste Ausrüstung | Talente (−1 / 0 / Angriff) | ohne einzelne Fähigkeit | Sonderfälle |",
         "|---|---|--:|---|---|--:|---|"]
    warn = []
    for cid, m in meta.items():
        vs = [v for (c, _), v in sorted(var.items()) if c == cid]
        if not vs:
            continue
        def cell(axis):
            xs = [v for v in vs if v["axis"] == axis]
            return f"{sum(v['ok'] for v in xs)}/{len(xs)}" if xs else "–"
        std = next((v for v in vs if v["axis"] == "standard"), None)
        std_s = "–"
        if std:
            std_s = f"✓ {std['best']['turns']} R." if std["ok"] else "✗"
        def named(axis, label):
            v = next((v for v in vs if v["name"] == label), None)
            return "–" if not v else ("✓" if v["ok"] else "✗")
        L.append(f"| {cid} {m['title']} | {std_s} | {cell('gruppe')} | {named('ausruestung', 'ohne Ausrüstung')} / {named('ausruestung', 'beste Ausrüstung')} | "
                 f"{named('talente', 'ein Talentpunkt weniger')} / {named('talente', 'keine Talentpunkte')} / {named('talente', 'Talente nur Angriff')} | {cell('faehigkeit')} | {cell('sonder')} |")
        for v in vs:
            if not v["ok"]:
                reasons = sorted({x["reason"] for x in v["runs"]})
                warn.append((m["order"], f"**{cid}** {v['name']}: in keinem Stil geschafft ({', '.join(reasons)}, {len(v['runs'])} Versuche)"))
    L += ["", "## Warnungen", ""]
    L += [f"- {w}" for _, w in sorted(warn)] or ["Keine: jede Variante wurde in mindestens einem Stil geschafft."]
    # Gruppen: Beitrag der Helden (Anteil geschaffter Gruppen mit dem Helden)
    L += ["", "## Gruppen: schwächste Varianten je Mission", ""]
    for cid, m in meta.items():
        gs = [v for (c, _), v in var.items() if c == cid and v["axis"] == "gruppe"]
        bad = [v for v in gs if not v["ok"]]
        if gs:
            L.append(f"- **{cid}:** {sum(v['ok'] for v in gs)}/{len(gs)} Gruppen geschafft" + (": nicht geschafft mit " + "; ".join(v["name"].removeprefix("Gruppe ") for v in bad[:3]) if bad else ""))
    # Abdeckung der Faehigkeiten
    offered, usedn = {}, {}
    for r in rows:
        for h, d in (r.get("abilities_offered") or {}).items():
            for a in d:
                offered[a] = offered.get(a, 0) + 1
        for h, d in (r.get("abilities_used") or {}).items():
            for a, n in d.items():
                usedn[a] = usedn.get(a, 0) + n
    hero_abs = sorted({a for h, u in units.items() if u.get("hero") for a in u.get("abilities", [])})
    L += ["", "## Abdeckung der Fähigkeiten", "",
          "Wie oft eine Heldenfähigkeit im Menü einsetzbar war (Kämpfe) und wie oft der Bot sie benutzt hat.", "",
          "| Fähigkeit | einsetzbar (Kämpfe) | benutzt |", "|---|--:|--:|"]
    for a in hero_abs:
        L.append(f"| {abname(a)} | {offered.get(a, 0)} | {usedn.get(a, 0)} |")
    never_used = [abname(a) for a in hero_abs if offered.get(a, 0) > 0 and usedn.get(a, 0) == 0]
    never_offered = [abname(a) for a in hero_abs if offered.get(a, 0) == 0]
    L += ["", f"- **Nie benutzt** (aber einsetzbar): {', '.join(never_used) or 'keine'}",
          f"- **Nie einsetzbar** (kein gültiges Ziel oder Held nie dabei): {', '.join(never_offered) or 'keine'}"]
    # Objekte und Aktionen
    menu, items = {}, {}
    for r in rows:
        for k, n in (r.get("menu_used") or {}).items():
            k = k.split(" (")[0]
            menu[k] = menu.get(k, 0) + n
        for k, n in (r.get("items_used") or {}).items():
            items[k] = items.get(k, 0) + n
    L += ["", "## Objekte, Aktionen und Gegenstände", "",
          "- Menü-Aktionen: " + (", ".join(f"{k} ×{n}" for k, n in sorted(menu.items())) or "keine"),
          "- Gegenstände: " + (", ".join(f"{k} ×{n}" for k, n in sorted(items.items())) or "keine")]
    secrets = sorted({s for r in rows for s in (r.get("secrets") or [])})
    L.append("- Geheimnisse: " + (", ".join(secrets) or "keine (der Bot löst Geheimnisse nicht gezielt aus)"))
    # Planabweichungen und Haenger
    mm = [(r["id"], x) for r in rows for x in (r.get("mismatches") or [])]
    hang = [r for r in rows if r["reason"] in ("haengt", "schleife", "zeitlimit")]
    L += ["", "## Planabweichungen und Hänger", "",
          f"{len(mm)} Planabweichungen (Bot wollte etwas, das das Menü nicht anbot), {len(hang)} Hänger, Schleifen oder Zeitlimits.", ""]
    for i, x in mm[:15]:
        L.append(f"- `{i}`: {x}")
    for r in hang[:10]:
        L.append(f"- `{r['id']}` {r['reason']}: " + " / ".join(r.get("last_actions", [])[-3:]))
    secs = sum(r.get("wall_s", 0) for r in rows)
    L += ["", f"Kampfzeit gesamt {secs / 60:.0f} min (auf {WORKERS} Prozesse verteilt).", ""]
    REPORT.write_text("\n".join(L))
    print(f"{REPORT.relative_to(ROOT)} geschrieben: {sum(v['ok'] for v in var.values())}/{len(var)} Varianten geschafft, {len(warn)} Warnungen")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scale", type=float, default=1.0)
    ap.add_argument("--styles", type=int, default=3)
    ap.add_argument("--missions", default="")
    ap.add_argument("--resume", action="store_true")
    ap.add_argument("--report", action="store_true")
    a = ap.parse_args()
    meta = load_meta()
    if not a.report:
        missions = [m for m in a.missions.split(",") if m]
        jobs = build_jobs(meta, a.scale, a.styles, missions)
        if a.resume:
            have = done_ids()
            jobs = [j for j in jobs if j["id"] not in have]
        elif RESULTS.exists():
            RESULTS.unlink()
        print(f"{len(jobs)} Kämpfe auf {WORKERS} Prozessen")
        run(jobs)
    report(meta)


if __name__ == "__main__":
    main()
