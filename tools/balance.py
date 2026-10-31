#!/usr/bin/env python3
"""Balancing-Experimente mit dem grafikfreien Simulator (game/sim/).

Benutzung:
  python3 tools/balance.py calib e0 e1 e2 e3 e4 report      # alles nacheinander
  python3 tools/balance.py --scale 0.2 calib e0              # schneller Probelauf (20 % der Kaempfe)
  python3 tools/balance.py report                            # nur Bericht aus gespeicherten Ergebnissen

Ergebnisse: out/sim/results.json, Bericht: docs/balance.md, Schwierigkeit: game/data/difficulty.json
"""
import argparse
import json
import math
import os
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAME = ROOT / "game"
OUT = ROOT / "out" / "sim"
RESULTS = OUT / "results.json"

HEROES = ["maedchen_baer", "ritter", "samurai", "kungfu", "ninjas", "elisabeth", "museklaugust",
          "robo", "hund", "wendy", "claude", "bienenmaedchen", "braumeisterin"]
SOLDIERS = ["soldat_infanterie", "soldat_beritten", "soldat_bogenschuetze", "soldat_priester"]
NAMES = {
    "maedchen_baer": "Mira & Brumm", "ritter": "Ser Albrecht", "samurai": "Takeda", "kungfu": "Meister Lin",
    "ninjas": "Kage-Schwestern", "elisabeth": "Käpt’n Elisabeth", "museklaugust": "Muskelaugust", "robo": "Robo",
    "hund": "Blauer Hundsfreund", "wendy": "Wendy Wolle", "claude": "Claude", "bienenmaedchen": "Stachelia",
    "braumeisterin": "Brunhilde Bräu", "soldat_infanterie": "Infanterie", "soldat_beritten": "Reiter",
    "soldat_bogenschuetze": "Bogenschütze", "soldat_priester": "Priester",
}
# Standard-Gegnerverband: gewichtet gezogen (4 Infanterie : 2 Reiter : 1 Bogen : 1 Priester)
ENEMY_POOL = ["soldat_infanterie"] * 4 + ["soldat_beritten"] * 2 + ["soldat_bogenschuetze", "soldat_priester"]

SCALE = 1.0
WORKERS = max(1, (os.cpu_count() or 4) - 1)


# ------------------------------------------------------------------ Infrastruktur

def merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        for k, v in b.items():
            a[k] = merge(a[k], v) if k in a else v
        return a
    if isinstance(a, list) and isinstance(b, list):
        return a + b
    return a + b


def run_cells(cells):
    """Verteilt die Zellen auf parallele Godot-Prozesse und addiert die Ergebnisse."""
    OUT.mkdir(parents=True, exist_ok=True)
    for f in OUT.glob("job_*.json"):
        f.unlink()
    for f in OUT.glob("out_*.json"):
        f.unlink()
    for c in cells:
        c["n"] = max(4, int(round(c["n"] * SCALE)))
    procs = []
    t0 = time.time()
    for w in range(WORKERS):
        cs = []
        for c in cells:
            ch = -(-c["n"] // WORKERS)
            lo, hi = w * ch, min(c["n"], (w + 1) * ch)
            if lo < hi:
                d = dict(c)
                d["from"], d["to"] = lo, hi
                cs.append(d)
        if not cs:
            continue
        jf, of = OUT / f"job_{w}.json", OUT / f"out_{w}.json"
        jf.write_text(json.dumps({"cells": cs}))
        procs.append((w, subprocess.Popen(
            ["godot", "--headless", "--path", str(GAME), "--script", "sim/run.gd", "--", f"job={jf}", f"out={of}"],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True), of))
    merged = {}
    for w, p, of in procs:
        out, _ = p.communicate()
        if "SCRIPT ERROR" in out or not of.exists():
            print(out[-3000:])
            raise SystemExit(f"Worker {w} fehlgeschlagen")
        merged = merge(merged, json.loads(of.read_text()))
    total = sum(m["n"] for m in merged.values())
    print(f"   {len(cells)} Zellen, {total} Kämpfe in {time.time() - t0:.0f} s ({WORKERS} Prozesse)")
    return merged


def load():
    return json.loads(RESULTS.read_text()) if RESULTS.exists() else {}


def save(key, value):
    r = load()
    r[key] = value
    OUT.mkdir(parents=True, exist_ok=True)
    RESULTS.write_text(json.dumps(r, indent=1))


def wr(agg):
    return agg["wins"] / max(1, agg["n"])


def se(p, n):
    return math.sqrt(max(p * (1 - p), 1e-9) / max(1, n))


def party(**kw):
    return kw


# ------------------------------------------------------------------ Experimente

def calib():
    """Wie stark muessen 12 Standard-Soldaten sein (Leben und Angriff x m), damit eine zufaellige 6er-Heldengruppe ~60 % gewinnt?"""
    print("Kalibrierung: Soldatenstärke für 60 % Siegquote (12 Soldaten)")
    mults = [1.3, 1.4, 1.5, 1.55, 1.6, 1.65, 1.7, 1.8, 1.9, 2.0]
    cells = [{"name": f"c{m}", "n": 300, "seed": 100000, "map": "open", "party": {"pool": HEROES, "size": 6},
              "enemy": {"pool": ENEMY_POOL, "count": 12}, "e_mods": {"hp": m, "atk": m}} for m in mults]
    res = run_cells(cells)
    rows = [(m, wr(res[f"c{m}"]), res[f"c{m}"]["turns"] / res[f"c{m}"]["n"]) for m in mults]
    for m, p, t in rows:
        print(f"   Soldaten ×{m}: Siegquote {p:5.1%}, Ø {t:.1f} Runden")
    best = min(rows, key=lambda r: abs(r[1] - 0.6))
    save("calib", {"rows": rows, "count": 12, "mult": best[0]})
    print(f"   -> gewählt: ×{best[0]}")


def e0_ratings():
    """Wert jeder Figur in Infanteristen: wie viele Infanteristen schlägt sie allein (50 % Siegquote)?"""
    print("E0: Einzelkampf-Wertung gegen K Infanteristen")
    ks = [1, 2, 3, 4, 6, 8, 12, 16, 24, 30]
    cells = []
    for uid in HEROES + SOLDIERS:
        for k in ks:
            cells.append({"name": f"{uid}|{k}", "n": 120, "seed": 200000, "map": "open",
                          "party": {"fixed": [uid]}, "enemy": {"mix": {"soldat_infanterie": k}}})
    res = run_cells(cells)
    out = {}
    for uid in HEROES + SOLDIERS:
        curve = [(k, wr(res[f"{uid}|{k}"])) for k in ks]
        out[uid] = {"curve": curve, "rating": rating_from_curve(curve)}
    save("e0", out)
    for uid in sorted(out, key=lambda u: -out[u]["rating"]):
        print(f"   {NAMES[uid]:20s} {out[uid]['rating']:5.1f} Infanteristen")


def rating_from_curve(curve):
    """Anzahl Infanteristen bei 50 % Siegquote (logarithmisch interpoliert). < 1 -> unter einem Infanteristen."""
    if curve[0][1] < 0.5:
        return max(0.05, curve[0][1] / 0.5 * 1.0 * 0.9)     # unter 1: grob nach Siegquote gegen 1
    for (k0, p0), (k1, p1) in zip(curve, curve[1:]):
        if p0 >= 0.5 > p1:
            f = (p0 - 0.5) / max(1e-9, p0 - p1)
            return math.exp(math.log(k0) + f * (math.log(k1) - math.log(k0)))
    return float(curve[-1][0])    # gewinnt auch gegen den groessten Verband


def enemy_count():
    r = load().get("calib")
    return r["count"] if r else 12


def enemy_mult():
    r = load().get("calib")
    return r["mult"] if r else 2.0


def e1_contribution():
    """Zufaellige 6er-Gruppen gegen den kalibrierten Verband: Beitrag jedes Helden zur Siegquote."""
    n_enemy, m = enemy_count(), enemy_mult()
    print(f"E1: Heldenbeitrag (zufällige 6er-Gruppen gegen {n_enemy} Soldaten ×{m})")
    res = run_cells([{"name": "e1", "n": 4000, "seed": 300000, "map": "open", "party": {"pool": HEROES, "size": 6},
                      "enemy": {"pool": ENEMY_POOL, "count": n_enemy}, "e_mods": {"hp": m, "atk": m}}])["e1"]
    save("e1", {"agg": res, "enemy_count": n_enemy, "mult": m})
    print(f"   Gesamt-Siegquote {wr(res):.1%}")


def ability_list():
    defs = json.loads((GAME / "data" / "units.json").read_text())
    return [(h, a) for h in HEROES for a in defs[h].get("abilities", [])]


def e2_ablation():
    """Gepaarter Vergleich: Held H + 5 Zufallshelden, mit und ohne seine Fähigkeit."""
    n_enemy, m = enemy_count(), enemy_mult()
    abl = ability_list()
    print(f"E2: Fähigkeiten abschalten ({len(abl)} Fähigkeiten, {n_enemy} Gegner ×{m})")
    cells = []
    for h in HEROES:
        base = {"n": 1500, "seed": 400000, "map": "open", "party": {"forced": [h], "pool": HEROES, "size": 6},
                "enemy": {"pool": ENEMY_POOL, "count": n_enemy}, "e_mods": {"hp": m, "atk": m}}
        cells.append(dict(base, name=f"ctl|{h}"))
        cells.append(dict(base, name=f"all|{h}", disabled={h: ["*"]}))
    for h, a in abl:
        cells.append({"n": 1500, "seed": 400000, "map": "open", "party": {"forced": [h], "pool": HEROES, "size": 6},
                      "enemy": {"pool": ENEMY_POOL, "count": n_enemy}, "e_mods": {"hp": m, "atk": m},
                      "name": f"abl|{h}|{a}", "disabled": {h: [a]}})
    res = run_cells(cells)
    save("e2", {"cells": res, "abilities": abl, "enemy_count": n_enemy, "mult": m})


def loadout_ch1():
    lo = json.loads((GAME / "data" / "items.json").read_text())["loadout_chapter1"]
    return {"inventory": lo["inventory"], "equip_map": lo["equipment"]}


def ch1_unit_ids():
    m = json.loads((GAME / "data" / "map_ch1.json").read_text())
    return [e["id"] for e in m["players"]], [e["id"] for e in m["enemies"]]


def e3_difficulty(items=True):
    """Kapitel 1 mit Gegnerstärke-Faktor, zusätzlichen Gegnern und KI-Fehlerquote (mit Startausrüstung und Rucksack)."""
    p_ids, e_ids = ch1_unit_ids()
    lo = loadout_ch1() if items else {}
    print("E3: Schwierigkeitskurve Kapitel 1" + (" (mit Ausrüstung)" if items else " (ohne Gegenstände)"))
    cells = []
    mults = [round(0.6 + 0.2 * i, 2) for i in range(0, 20)]   # bis x4,4: die Kurve muss unter 25 % Siegquote fallen
    for m in mults:
        cells.append({"name": f"m|{m}", "n": 600, "seed": 500000, "map": "ch1", "party": {"fixed": p_ids}, "loadout": lo,
                      "enemy": {"fixed": e_ids}, "e_mods": {"hp": m, "atk": m}})
    for extra in range(0, 9):
        cells.append({"name": f"x|{extra}", "n": 600, "seed": 500000, "map": "ch1", "party": {"fixed": p_ids}, "loadout": lo,
                      "enemy": {"fixed": e_ids + ["soldat_infanterie"] * extra}})
    for noise in [0.0, 0.1, 0.2, 0.3, 0.45]:
        cells.append({"name": f"n|{noise}", "n": 600, "seed": 500000, "map": "ch1", "party": {"fixed": p_ids}, "loadout": lo,
                      "enemy": {"fixed": e_ids}, "p_ai": {"noise": noise}})
    res = run_cells(cells)
    save("e3" if items else "e3_noitems", {"cells": res, "mults": mults, "party": p_ids, "enemy": e_ids, "items": items})
    for m in mults:
        a = res[f"m|{m}"]
        print(f"   Gegner x{m}: {wr(a):5.1%}  Ø {a['turns'] / a['n']:.1f} Runden, {a['p_alive'] / a['n']:.0%} der Helden überleben")


def e5_items():
    """Wert von Ausruestung und Verbrauchsgegenstaenden: gepaarte Vergleiche mit zufaelligen 6er-Gruppen (wie E1)."""
    n_enemy, m = enemy_count(), enemy_mult()
    items = json.loads((GAME / "data" / "items.json").read_text())
    print(f"E5: Gegenstände und Ausrüstung ({len(items['equipment'])} Ausrüstungen, {len(items['consumables'])} Verbrauchsgüter)")
    base = {"n": 2500, "seed": 700000, "map": "open", "party": {"pool": HEROES, "size": 6},
            "enemy": {"pool": ENEMY_POOL, "count": n_enemy}, "e_mods": {"hp": m, "atk": m}}
    cells = [dict(base, name="none")]
    cells.append(dict(base, name="ch1", loadout=loadout_ch1()))
    cells.append(dict(base, name="rich", loadout={"inventory": {"heiltrank": 5, "gegengift": 3, "aether": 3, "rauchbombe": 2, "bier": 2}}))
    for cid in items["consumables"]:
        cells.append(dict(base, name=f"inv|{cid}", loadout={"inventory": {cid: 2}}))
    for eid in items["equipment"]:
        cells.append(dict(base, name=f"eq|{eid}", loadout={"equip_one": eid}))
    res = run_cells(cells)
    save("e5", {"cells": res, "items": items, "enemy_count": n_enemy, "mult": m})
    p0 = wr(res["none"])
    print(f"   ohne: {p0:.1%}, Kapitel-1-Ausstattung: {wr(res['ch1']):.1%}, reich: {wr(res['rich']):.1%}")


TANK_TAUNTS = {"ritter": ["verspotten"], "maedchen_baer": ["baerenpranke"], "braumeisterin": ["fasswurf"]}


def e6_defend():
    """Verteidigen (halber Schaden, kein Gegenschlag): Wirkung auf Gruppen, auf Tanks mit Spott (Spott wirkt aktuell
    1 Gegnerphase, Variante 2 Phasen) und auf einen einzelnen Ablenker."""
    n_enemy, m = enemy_count(), enemy_mult()
    print("E6: Verteidigen, Spott und Ablenker")
    base = {"map": "open", "seed": 800000, "enemy": {"pool": ENEMY_POOL, "count": n_enemy}, "e_mods": {"hp": m, "atk": m}}
    cells = []
    for d in (0, 1):
        cells.append(dict(base, name=f"grp|{d}", n=3000, party={"pool": HEROES, "size": 6}, p_ai={"defend": bool(d)}))
    for h, abl in TANK_TAUNTS.items():
        for taunt in ("aus", "1", "2"):          # Spott aus / wirkt 1 Gegnerphase (aktuell) / 2 Gegnerphasen
            for d in (0, 1):
                c = dict(base, name=f"tank|{h}|{taunt}|{d}", n=1200, party={"forced": [h], "pool": HEROES, "size": 6},
                         p_ai={"defend": bool(d)})
                if taunt == "aus":
                    c["disabled"] = {h: abl}
                elif taunt == "2":
                    c["ab_status_turns"] = {a: 3 for a in abl}
                cells.append(c)
    for atk in (1.0, 1.2, 1.4):                   # Soldatenangriff 5 / 6 / 7 gegen einen einzelnen Ablenker (Meister Lin)
        for d in (0, 1):
            cells.append({"name": f"decoy|{atk}|{d}", "n": 500, "seed": 900000, "map": "open", "max_turns": 6,
                          "party": {"fixed": ["kungfu"]}, "enemy": {"mix": {"soldat_infanterie": 3, "soldat_bogenschuetze": 1}},
                          "e_mods": {"hp": 1.0, "atk": atk}, "p_ai": {"defend": bool(d)}})
    res = run_cells(cells)
    save("e6", {"cells": res, "enemy_count": n_enemy, "mult": m})
    g0, g1 = res["grp|0"], res["grp|1"]
    print(f"   Gruppen: ohne Verteidigen {wr(g0):.1%}, mit {wr(g1):.1%}")


def e10_wait():
    """Warten (wachsam, +N Angriff fuer den Gegenschlag) gegen Verteidigen: Gruppen mit zufaelligen Helden."""
    n_enemy, m = enemy_count(), enemy_mult()
    print("E10: Warten = wachsam")
    base = {"map": "open", "seed": 810000, "enemy": {"pool": ENEMY_POOL, "count": n_enemy}, "e_mods": {"hp": m, "atk": m},
            "party": {"pool": HEROES, "size": 6}}
    cells = []
    for w in (0, 2, 3):
        for d in (0, 1):
            cells.append(dict(base, name=f"wait|{w}|{d}", n=2000, wait_atk=w, p_ai={"defend": bool(d)}))
    res = run_cells(cells)
    save("e10", {"cells": res, "enemy_count": n_enemy, "mult": m})
    for w in (0, 2, 3):
        print("  ", f"+{w} Angriff:", [(d, round(wr(res[f'wait|{w}|{d}']), 3)) for d in (0, 1)])


def e8_bees():
    """Mission 5 (Waisenhaus): Siegquote, gestochene Kinder, Glocke und Stoecke bei steigender Gegnerstaerke."""
    print("E8: Mission 5, Bienenstoecke, Glocke und Hundsfreund")
    party = ["maedchen_baer", "ritter", "wendy", "elisabeth", "ninjas", "samurai"]
    mission = json.loads((GAME / "data" / "map_ch5.json").read_text())
    foes = [e["id"] for e in mission["enemies"]]   # wie in Mission 5 (Stachelia mit den Leben laut Karte)
    variants = {
        "voll": {},
        "ohne_glocke": {"bell": False},
        "ohne_staecke": {"hive": False},
        "weder_noch": {"bell": False, "hive": False},
    }
    mults = [1.0, 1.5, 2.0]
    if os.environ.get("E8_QUICK"):   # nur die volle Variante, zum Einstellen der Werte
        variants = {"voll": {}}
    cells = []
    for v, ai in variants.items():
        for m in mults:
            cells.append({"name": f"{v}|{m}", "n": 500, "seed": 970000, "map": "ch5", "party": {"fixed": party}, "enemy": {"fixed": foes},
                          "e_mods": {"hp": m, "atk": m}, "p_ai": ai, "e_ai": {"retreat": True}})
    res = run_cells(cells)
    if os.environ.get("E8_QUICK"):
        print("  ", [(m, round(wr(res[f'voll|{m}']), 2), round(res[f'voll|{m}']['stung_battles'] / res[f'voll|{m}']['n'], 2), round(res[f'voll|{m}']['turns'] / res[f'voll|{m}']['n'], 1)) for m in mults])
        return
    save("e8", {"cells": res, "mults": mults, "variants": list(variants)})
    for v in variants:
        print("  ", v, [(m, round(wr(res[f'{v}|{m}']), 2), round(res[f'{v}|{m}']['stung_battles'] / res[f'{v}|{m}']['n'], 2)) for m in mults])


def e9_harbor():
    """Mission 6 (Hafenstadt, Ziel: ein Held erreicht das Schiff): Siegquote mit/ohne Breitseite, Wart und Trainingspuppe bei steigender Gegnerstaerke.
    Spawns der Mission (Wart Runde 3, Puppe Runde 4, Beiboot Runde 5) kommen aus den Ausloesern in missions/ch6.json."""
    print("E9: Mission 6, Hafenstadt und Breitseite")
    party = ["hund", "maedchen_baer", "elisabeth", "ritter", "robo", "samurai"]
    mission = json.loads((GAME / "data" / "map_ch6.json").read_text())
    foes = [e["id"] for e in mission["enemies"]]
    base = dict(enemy={"fixed": foes}, nemesis=["wart"])
    variants = {
        "voll": base,                                               # Wart, Puppe und Beiboot, mit Breitseite
        "ohne_breitseite": dict(base, disabled={"elisabeth": ["breitseite"]}),
        "ohne_wart": dict(base, nemesis=[]),                        # z. B. Levelwaehler ohne Vorgeschichte
    }
    mults = [1.0, 1.5, 2.0]
    if os.environ.get("E9_QUICK"):
        variants = {k: variants[k] for k in ("voll",)}
        mults = [1.0, 1.5, 1.75]
    cells = []
    for v, spec in variants.items():
        for m in mults:
            cells.append(dict({"name": f"{v}|{m}", "n": 250 if os.environ.get("E9_QUICK") else 500, "seed": 990000, "map": "ch6", "party": {"fixed": party},
                               "e_mods": {"hp": m, "atk": m}, "e_ai": {}}, **spec))
    res = run_cells(cells)
    if os.environ.get("E9_QUICK"):
        for v in variants:
            print("  ", v, [(m, round(wr(res[f'{v}|{m}']), 2), round(res[f'{v}|{m}']['turns'] / res[f'{v}|{m}']['n'], 1)) for m in mults])
        return
    save("e9", {"cells": res, "mults": mults, "variants": list(variants)})
    for v in variants:
        print("  ", v, [(m, round(wr(res[f'{v}|{m}']), 2), round(res[f'{v}|{m}']['turns'] / res[f'{v}|{m}']['n'], 1)) for m in mults])


def e7_fire():
    """Mission 3 (Feuer): Siegquote und gerettete Haeuser mit/ohne Loeschen, mit/ohne Brunhilde, bei steigender Gegnerstaerke."""
    print("E7: Mission 3, Feuer und Loeschen")
    base_party = ["ritter", "maedchen_baer", "braumeisterin", "wendy", "elisabeth", "samurai"]
    no_bru = [("kungfu" if h == "braumeisterin" else h) for h in base_party]
    foes = ["soldat_infanterie", "soldat_infanterie", "soldat_infanterie", "soldat_bogenschuetze", "soldat_beritten", "oskar", "maja"]   # wie in Mission 3
    variants = {
        "voll": dict(party={"fixed": base_party}),
        "ohne_fasswurf": dict(party={"fixed": base_party}, disabled={"braumeisterin": ["fasswurf"]}),
        "ohne_loeschen": dict(party={"fixed": base_party}, p_ai={"douse": False}),
        "ohne_brunhilde": dict(party={"fixed": no_bru}),
    }
    mults = [1.0, 1.6, 2.2]
    cells = []
    for v, spec in variants.items():
        for m in mults:
            cells.append(dict({"name": f"{v}|{m}", "n": 500, "seed": 950000, "map": "ch3", "enemy": {"fixed": foes},
                               "e_mods": {"hp": m, "atk": m}}, **spec))
    res = run_cells(cells)
    save("e7", {"cells": res, "mults": mults, "variants": list(variants)})
    for v in variants:
        print("  ", v, [(m, round(wr(res[f'{v}|{m}']), 2), round(res[f'{v}|{m}']['houses_lost'] / res[f'{v}|{m}']['n'], 2)) for m in mults])


def e4_power_ratio():
    """Zufaellige Gruppen und Verbaende: wie haengt die Siegquote vom Verhaeltnis der Einzelwertungen ab?"""
    print("E4: Siegquote gegen Stärkeverhältnis")
    res = run_cells([{"name": "e4", "n": 12000, "seed": 600000, "map": "open", "raw": True, "e_mult_range": [1.0, 3.0],
                      "party": {"pool": HEROES, "size_range": [3, 8]},
                      "enemy": {"pool": SOLDIERS + SOLDIERS + SOLDIERS + ["bienenmaedchen"], "count_range": [4, 18]}}])["e4"]
    save("e4", {"raw": res["raw"]})
    print(f"   {len(res['raw'])} Kämpfe")


# ------------------------------------------------------------------ Auswertung und Bericht

def logistic_fit(points):
    """Passe p = 1/(1+exp(-k*(x-x0))) an (x, gewonnen) an (Gitter, Log-Loss)."""
    best = (1e18, 1.0, 0.0)
    for k10 in range(5, 120, 3):
        k = k10 / 10
        for x0100 in range(-120, 121, 4):
            x0 = x0100 / 100
            ll = 0.0
            for x, y in points:
                p = 1 / (1 + math.exp(-k * (x - x0)))
                p = min(max(p, 1e-6), 1 - 1e-6)
                ll -= math.log(p) if y else math.log(1 - p)
            if ll < best[0]:
                best = (ll, k, x0)
    return best[1], best[2]


def interp_x(xs, ps, target):
    """Zu welchem x sinkt die Quote unter target (lineare Interpolation, ps fallend)."""
    for (x0, p0), (x1, p1) in zip(zip(xs, ps), zip(xs[1:], ps[1:])):
        if p0 >= target >= p1 and p0 != p1:
            return x0 + (p0 - target) / (p0 - p1) * (x1 - x0)
    return xs[0] if ps[0] < target else xs[-1]


def report():
    R = load()
    if not R:
        raise SystemExit("keine Ergebnisse, erst Experimente laufen lassen")
    L = []
    w = L.append
    w("# Balancing-Bericht\n")
    w("Erzeugt von `tools/balance.py` mit dem grafikfreien Simulator (`game/sim/`). Er nutzt dieselben Regeln wie das Spiel "
      "(Parität per `tests/test_sim.gd` geprüft) und lässt beide Seiten von derselben einfachen KI spielen. "
      "Die Zahlen zeigen **relative Stärke**, nicht das Verhalten menschlicher Spieler.\n")

    e0 = R.get("e0", {})
    e1 = R.get("e1")
    e2 = R.get("e2")
    e3 = R.get("e3")
    e4 = R.get("e4")
    notes = []

    # ---- E0
    if e0:
        w("## 1. Einzelwertung: Wert in Infanteristen\n")
        w("Wie viele Infanteristen schlägt die Figur allein mit 50 % Siegquote? (Karte zufällig, KI wie im Spiel.)\n")
        w("| Figur | Wert (Infanteristen) | Siegquote gegen 1 / 3 / 6 |")
        w("|---|--:|---|")
        for uid in sorted(e0, key=lambda u: -e0[u]["rating"]):
            c = dict((k, p) for k, p in e0[uid]["curve"])
            w(f"| {NAMES[uid]} | {e0[uid]['rating']:.1f} | {c[1]:.0%} / {c[3]:.0%} / {c[6]:.0%} |")
        w("")
        w("Unterstützer (Heiler) haben allein kaum Wert; ihr Beitrag zeigt sich erst in der Gruppe (siehe 2.).\n")

    # ---- E1
    if e1:
        agg = e1["agg"]
        base = wr(agg)
        w(f"## 2. Beitrag zur Gruppe\n")
        w(f"Zufällige 6er-Gruppen aus allen 13 Helden gegen {e1['enemy_count']} Soldaten (Standardmischung, Leben und Angriff ×{e1['mult']}). "
          f"Gesamt-Siegquote {base:.1%} bei {agg['n']} Kämpfen. „Δ Sieg“ = Siegquote mit dem Helden minus Gesamtquote.\n")
        w("| Held | Δ Sieg | Überlebt | Schaden/Kampf | Erlitten/Kampf | Geheilt/Kampf | Besiegt/Kampf |")
        w("|---|--:|--:|--:|--:|--:|--:|")
        rows = []
        for h in HEROES:
            s = agg["ids"].get(f"p:{h}")
            if not s or s["n"] == 0:
                continue
            p = s["wins"] / s["n"]
            rows.append((p - base, h, s, se(p, s["n"])))
        for d, h, s, e in sorted(rows, reverse=True):
            n = s["n"]
            w(f"| {NAMES[h]} | {d * 100:+.1f} Pp ± {e * 200:.1f} | {s['alive'] / n:.0%} | {s['dealt'] / n:.0f} | {s['taken'] / n:.0f} | {s['healed'] / n:.0f} | {s['kills'] / n:.1f} |")
        w("")
        top = sorted(rows, reverse=True)
        notes.append(f"Stärkste Gruppenbeiträge: " + ", ".join(f"{NAMES[h]} ({d * 100:+.1f} Pp)" for d, h, _, _ in top[:3]))
        notes.append(f"Schwächste Gruppenbeiträge: " + ", ".join(f"{NAMES[h]} ({d * 100:+.1f} Pp)" for d, h, _, _ in top[-3:]))

    # ---- E2
    if e2:
        cells = e2["cells"]
        w("## 3. Wie stark ist jede Fähigkeit?\n")
        w("Gepaarter Vergleich: derselbe Held mit 5 Zufallshelden gegen denselben Verband (gleiche Karten und Gruppen), "
          "einmal mit, einmal ohne die Fähigkeit. „Δ Sieg“ ist der Siegquoten-Gewinn durch die Fähigkeit in Prozentpunkten (Pp). "
          "„Schaden/Heilung“ = pro Einsatz.\n")
        w("| Held | Fähigkeit | Δ Sieg | ± | Einsätze/Kampf | Schaden pro Einsatz | Heilung pro Einsatz | Status pro Einsatz | Abklingzeit |")
        w("|---|---|--:|--:|--:|--:|--:|--:|--:|")
        abd = json.loads((GAME / "data" / "abilities.json").read_text())
        weak, strong = [], []
        for h, a in e2["abilities"]:
            ctl = cells[f"ctl|{h}"]
            abl = cells[f"abl|{h}|{a}"]
            d = wr(ctl) - wr(abl)
            err = math.sqrt(se(wr(ctl), ctl["n"]) ** 2 + se(wr(abl), abl["n"]) ** 2)
            ab = ctl["abs"].get(f"{h}/{a}", {"uses": 0, "dmg": 0, "heal": 0, "status": 0, "battles": 1})
            hero_n = ctl["ids"][f"p:{h}"]["n"]
            uses = ab["uses"]
            per = lambda x: x / uses if uses else 0
            w(f"| {NAMES[h]} | {abd[a]['name']} | {d * 100:+.1f} Pp | {err * 100:.1f} | {uses / hero_n:.2f} | {per(ab['dmg']):.1f} | {per(ab['heal']):.1f} | {per(ab['status']):.2f} | {abd[a]['cd']} |")
            if d * 100 < 1.0 + 2 * err * 100:
                weak.append((abd[a]["name"], d * 100))
            if d * 100 > 6.0:
                strong.append((abd[a]["name"], d * 100))
        w("")
        w("### Alle Fähigkeiten eines Helden abgeschaltet\n")
        w("Zeigt, wie viel die Spezialfähigkeiten insgesamt zum Helden beitragen (nur normaler Angriff bleibt).\n")
        w("| Held | Δ Sieg durch alle Fähigkeiten | ± |")
        w("|---|--:|--:|")
        for h in HEROES:
            ctl, al = cells[f"ctl|{h}"], cells[f"all|{h}"]
            d = wr(ctl) - wr(al)
            err = math.sqrt(se(wr(ctl), ctl["n"]) ** 2 + se(wr(al), al["n"]) ** 2)
            w(f"| {NAMES[h]} | {d * 100:+.1f} Pp | {err * 100:.1f} |")
        w("")
        if strong:
            notes.append("Sehr starke Fähigkeiten (> +6 Pp): " + ", ".join(f"{n} ({d:+.1f})" for n, d in sorted(strong, key=lambda x: -x[1])))
        if weak:
            notes.append("Kaum messbarer Nutzen (< +1 Pp oder im Rauschen): " + ", ".join(f"{n} ({d:+.1f})" for n, d in sorted(weak, key=lambda x: x[1])))

    # ---- E3
    levels = None
    if e3:
        cells = e3["cells"]
        mults = e3["mults"]
        w("## 4. Schwierigkeit Kapitel 1\n")
        w(f"Aufstellung wie im Spiel ({len(e3['party'])} Helden gegen {len(e3['enemy'])} Gegner). Siegquote der Spielergruppe, wenn die Gegner "
          "entsprechend stärker (Leben und Angriff) werden:\n")
        w("| Gegner-Faktor | Siegquote | Ø Runden | Überlebende Helden |")
        w("|--:|--:|--:|--:|")
        ps = []
        for m in mults:
            a = cells[f"m|{m}"]
            ps.append(wr(a))
            w(f"| ×{m:.1f} | {wr(a):.0%} | {a['turns'] / a['n']:.1f} | {a['p_alive'] / a['n']:.0%} |")
        w("")
        w("Zusätzliche Infanteristen (bei Faktor ×1,0):\n")
        w("| Zusätzliche Gegner | Siegquote | Überlebende Helden |")
        w("|--:|--:|--:|")
        for x in range(0, 9):
            a = cells[f"x|{x}"]
            w(f"| +{x} | {wr(a):.0%} | {a['p_alive'] / a['n']:.0%} |")
        w("")
        w("Spielerfehler (Zufallsanteil in der Zugwahl der Spielergruppe, 0 = optimal):\n")
        w("| Fehlerquote | Siegquote |")
        w("|--:|--:|")
        for nz in [0.0, 0.1, 0.2, 0.3, 0.45]:
            a = cells[f"n|{nz}"]
            w(f"| {nz:.0%} | {wr(a):.0%} |")
        w("")
        targets = [("leicht", "Leicht", 0.9), ("normal", "Normal", 0.7), ("schwer", "Schwer", 0.45), ("meister", "Meister", 0.25)]
        levels = []
        w("### Vorschlag für die Schwierigkeitsstufen\n")
        w("Gewählt nach Ziel-Siegquote einer optimal spielenden Gruppe; ein menschlicher Spieler gewinnt erfahrungsgemäß seltener "
          "(siehe Fehlerquote), die Stufen haben also Luft nach oben.\n")
        w("| Stufe | Ziel-Siegquote | Gegner-Leben | Gegner-Angriff | Gemessene Siegquote |")
        w("|---|--:|--:|--:|--:|")
        for key, name, tp in targets:
            m = interp_x(mults, ps, tp)
            m = round(m, 2)
            near = min(mults, key=lambda x: abs(x - m))
            levels.append({"id": key, "name": name, "enemy_hp_mult": m, "enemy_atk_mult": m,
                           "target_win_rate": tp, "measured_win_rate": round(wr(cells[f"m|{near}"]), 3)})
            w(f"| {name} | {tp:.0%} | ×{m:.2f} | ×{m:.2f} | {wr(cells[f'm|{near}']):.0%} |")
        w("")

    # ---- E4
    if e4:
        import numpy as np
        raw = e4["raw"]
        types = SOLDIERS + ["bienenmaedchen"]
        feats = HEROES + types
        X = np.zeros((len(raw), len(feats) + 1))
        y = np.zeros(len(raw))
        for r, (p_ids, e_ids, win, turns, alive, mult) in enumerate(raw):
            for h in p_ids:
                X[r, feats.index(h)] = 1.0
            for t in e_ids:
                X[r, feats.index(t)] -= mult * mult        # Gegnerstaerke wirkt ~ quadratisch (Leben x Angriff)
            X[r, -1] = 1.0
            y[r] = 1.0 if win == "p" else 0.0
        wts = np.zeros(X.shape[1])
        ridge = 0.5
        for _ in range(40):                                  # Newton-Verfahren fuer logistische Regression (IRLS)
            z = X @ wts
            p = 1 / (1 + np.exp(-z))
            g = X.T @ (y - p) - ridge * wts
            H = (X.T * (p * (1 - p))) @ X + ridge * np.eye(X.shape[1])
            wts += np.linalg.solve(H, g)
        p = 1 / (1 + np.exp(-(X @ wts)))
        acc = float(np.mean((p > 0.5) == (y > 0.5)))
        unit = wts[feats.index("soldat_infanterie")]        # Kosten eines Infanteristen (Faktor 1) in Log-Odds
        coef = dict(zip(feats + ["c"], wts))
        save("e4_model", {"coef": coef, "acc": acc, "n": len(raw)})
        R["e4_model"] = {"coef": coef, "acc": acc, "n": len(raw)}
        w("## 5. Stärkemodell (Grundlage für Gegnerbudgets)\n")
        w(f"Aus {len(raw)} zufälligen Kämpfen (3–8 Helden gegen 4–18 Soldaten und Stachelia, Gegnerstärke ×1,0–×3,0) "
          "per logistischer Regression angepasst. Trefferquote des Modells bei der Vorhersage von Sieg oder Niederlage: "
          f"**{acc:.0%}**.\n")
        w("**Formel:** `Siegwahrscheinlichkeit = 1 / (1 + e^(−z))` mit `z = c + Σ Heldenwert − Σ (Gegnerkosten × Faktor²)`; "
          "Faktor = Gegner-Leben/Angriff-Multiplikator.\n")
        w(f"Konstante c = {coef['c']:+.2f}. Werte in Log-Odds; „Punkte“ = Wert geteilt durch die Kosten eines Infanteristen ({-unit if unit < 0 else unit:.2f}), "
          "also **Infanteristen-Äquivalente**.\n")
        w("| Held | Wert (Log-Odds) | Punkte |")
        w("|---|--:|--:|")
        unit_cost = abs(coef["soldat_infanterie"])
        for h in sorted(HEROES, key=lambda x: -coef[x]):
            w(f"| {NAMES[h]} | {coef[h]:+.2f} | {coef[h] / unit_cost:+.1f} |")
        w("")
        w("| Gegnertyp (Faktor 1) | Kosten (Log-Odds) | Punkte |")
        w("|---|--:|--:|")
        for t in types:
            w(f"| {NAMES.get(t, t)} | {-coef[t]:+.2f} | {-coef[t] / unit_cost:+.1f} |")
        w("")
        w("**Benutzung für neue Kapitel:** Kampfgruppe wählen, Σ Heldenwerte ausrechnen, Gegner so zusammenstellen, "
          "dass `z` dem Ziel entspricht (z = 0 → 50 %, z = +1 → 73 %, z = +2 → 88 %, z = −1 → 27 %).\n")
        notes.append(f"Stärkemodell: Trefferquote {acc:.0%}; höchste Heldenwerte " + ", ".join(
            f"{NAMES[h]} ({coef[h] / unit_cost:+.1f})" for h in sorted(HEROES, key=lambda x: -coef[x])[:3]))

    # ---- E5
    e5 = R.get("e5")
    if e5:
        cells = e5["cells"]
        items = e5["items"]
        p0 = wr(cells["none"])
        model = R.get("e4_model")
        unit_cost = abs(model["coef"]["soldat_infanterie"]) if model else None

        def logit(p):
            p = min(max(p, 0.005), 0.995)
            return math.log(p / (1 - p))

        def row(name, key, extra=""):
            a = cells[key]
            p = wr(a)
            d = p - p0
            err = math.sqrt(se(p, a["n"]) ** 2 + se(p0, cells["none"]["n"]) ** 2)
            pts = f"{(logit(p) - logit(p0)) / unit_cost:+.1f}" if unit_cost else "–"
            return f"| {name} | {d * 100:+.1f} Pp | {err * 100:.1f} | {pts} |{extra}"

        w("## 6. Gegenstände und Ausrüstung\n")
        w(f"Zufällige 6er-Gruppen gegen {e5['enemy_count']} Soldaten (Leben/Angriff ×{e5['mult']}); Grundlinie ohne Gegenstände: **{p0:.1%}** Siegquote "
          f"bei {cells['none']['n']} Kämpfen. „Punkte“ = Gewinn in Infanteristen-Äquivalenten (Stärkemodell aus Abschnitt 5; ein Held ist typisch +3 bis +10 Punkte wert).\n")
        w("### Pakete\n")
        w("| Paket | Δ Sieg | ± | Punkte |")
        w("|---|--:|--:|--:|")
        w(row("Kapitel-1-Ausstattung (2 Heiltränke, 1 Gegengift, 1 Äther, 6 Ausrüstungsstücke)", "ch1"))
        w(row("Reicher Rucksack (5 Heiltränke, 3 Gegengifte, 3 Äther, 2 Rauchbomben, 2 Bier)", "rich"))
        w("")
        w("### Verbrauchsgüter (jeweils 2 Stück im Rucksack)\n")
        w("| Gegenstand | Δ Sieg | ± | Punkte | Einsätze/Kampf | Wirkung pro Einsatz |")
        w("|---|--:|--:|--:|--:|--:|")
        for cid, it in items["consumables"].items():
            a = cells[f"inv|{cid}"]
            uses = sum(v["uses"] for k, v in a["abs"].items() if k.endswith(f"/item:{cid}"))
            heal = sum(v["heal"] for k, v in a["abs"].items() if k.endswith(f"/item:{cid}"))
            sta = sum(v["status"] for k, v in a["abs"].items() if k.endswith(f"/item:{cid}"))
            eff = f"{heal / uses:.1f} Leben" if uses and heal else (f"{sta / uses:.1f} Statuseffekte" if uses else "–")
            w(row(it["name"], f"inv|{cid}", f" {uses / a['n']:.2f} | {eff} |"))
        w("")
        w("### Ausrüstung (ein Stück an eine zufällige passende Figur der Gruppe)\n")
        w("| Ausrüstung | Platz | Δ Sieg | ± | Punkte |")
        w("|---|---|--:|--:|--:|")
        eq_rows = []
        for eid, it in items["equipment"].items():
            a = cells[f"eq|{eid}"]
            eq_rows.append((wr(a) - p0, eid, it))
        for d, eid, it in sorted(eq_rows, reverse=True):
            r = row(it["name"], f"eq|{eid}").replace(f"| {it['name']} |", f"| {it['name']} ({it['text']}) | {it['slot']} |", 1)
            w(r)
        w("")
        best = sorted(eq_rows, reverse=True)
        notes.append("Ausrüstung: stärkstes Stück " + f"{best[0][2]['name']} ({best[0][0] * 100:+.1f} Pp), schwächstes {best[-1][2]['name']} ({best[-1][0] * 100:+.1f} Pp)")
        notes.append(f"Kapitel-1-Ausstattung hebt die Siegquote um {(wr(cells['ch1']) - p0) * 100:+.1f} Pp")

    # ---- E6
    e6 = R.get("e6")
    if e6:
        cells = e6["cells"]
        g0, g1 = cells["grp|0"], cells["grp|1"]
        dsum = sum(v["uses"] for k, v in g1["abs"].items() if k.endswith("/_defend"))
        err = math.sqrt(se(wr(g0), g0["n"]) ** 2 + se(wr(g1), g1["n"]) ** 2)
        w("## 7. Verteidigen und Spott\n")
        w("Verteidigen: bis zur nächsten eigenen Phase **halber Schaden** (Tanks ×0,4, aufgerundet, mindestens 1), **kein Gegenschlag**, der Zug endet. "
          "Die Simulations-KI wählt es nur, wenn ihr bei Bleiben mindestens 35 % der Leben drohen.\n")
        w("### Zufällige Gruppen\n")
        w("| | ohne Verteidigen | mit Verteidigen | Δ |")
        w("|---|--:|--:|--:|")
        w(f"| Siegquote | {wr(g0):.1%} | {wr(g1):.1%} | {(wr(g1) - wr(g0)) * 100:+.1f} Pp ± {err * 100:.1f} |")
        w(f"| Überlebende Helden | {g0['p_alive'] / g0['n']:.0%} | {g1['p_alive'] / g1['n']:.0%} | {(g1['p_alive'] / g1['n'] - g0['p_alive'] / g0['n']) * 100:+.1f} Pp |")
        w(f"| Ø Runden | {g0['turns'] / g0['n']:.1f} | {g1['turns'] / g1['n']:.1f} | |")
        w(f"| Einsätze von Verteidigen pro Kampf | – | {dsum / g1['n']:.2f} | |")
        w("")
        w("### Tanks mit Spott (Gruppe: der Tank + 5 Zufallshelden)\n")
        w("Spott „1 Phase“ ist der heutige Stand: Der Spott hat „2 Runden“, wirkt durch die Zählweise aber nur auf die nächste Gegnerphase. „2 Phasen“ würde ihn echt auf zwei Gegnerphasen verlängern.\n")
        w("| Tank | Spott | Siegquote ohne / mit Verteidigen | Δ durch Verteidigen | Tank überlebt ohne / mit |")
        w("|---|---|--:|--:|--:|")
        worst = ("", 0.0)
        for h in TANK_TAUNTS:
            for taunt in ("aus", "1", "2"):
                a, c = cells[f"tank|{h}|{taunt}|0"], cells[f"tank|{h}|{taunt}|1"]
                da = (wr(c) - wr(a)) * 100
                sa = a["ids"][f"p:{h}"]["alive"] / a["ids"][f"p:{h}"]["n"]
                sc = c["ids"][f"p:{h}"]["alive"] / c["ids"][f"p:{h}"]["n"]
                label = {"aus": "aus", "1": "1 Phase (aktuell)", "2": "2 Phasen"}[taunt]
                w(f"| {NAMES[h]} | {label} | {wr(a):.0%} / {wr(c):.0%} | {da:+.1f} Pp | {sa:.0%} / {sc:.0%} |")
                if taunt == "2" and wr(c) > worst[1]:
                    worst = (NAMES[h], wr(c))
        w("")
        w("Zusatzgewinn durch den Spott (jeweils mit Verteidigen), Siegquote in Pp gegenüber „Spott aus“:\n")
        w("| Tank | Spott 1 Phase | Spott 2 Phasen | Zusammenspiel (2 Phasen mit Verteidigen − ohne) |")
        w("|---|--:|--:|--:|")
        for h in TANK_TAUNTS:
            o = wr(cells[f"tank|{h}|aus|1"])
            t1 = wr(cells[f"tank|{h}|1|1"])
            t2 = wr(cells[f"tank|{h}|2|1"])
            syn = (wr(cells[f"tank|{h}|2|1"]) - wr(cells[f"tank|{h}|2|0"])) - (wr(cells[f"tank|{h}|aus|1"]) - wr(cells[f"tank|{h}|aus|0"]))
            w(f"| {NAMES[h]} | {(t1 - o) * 100:+.1f} | {(t2 - o) * 100:+.1f} | {syn * 100:+.1f} |")
        w("")
        w("### Einzelner Ablenker (Meister Lin allein gegen 3 Infanteristen und 1 Bogenschützen, 6 Runden)\n")
        w("| Soldatenangriff | Lin überlebt ohne Verteidigen | mit Verteidigen |")
        w("|---|--:|--:|")
        for atk, lbl in ((1.0, "5 (heute)"), (1.2, "6"), (1.4, "7")):
            a, c = cells[f"decoy|{atk}|0"], cells[f"decoy|{atk}|1"]
            w(f"| {lbl} | {a['ids']['p:kungfu']['alive'] / a['ids']['p:kungfu']['n']:.0%} | {c['ids']['p:kungfu']['alive'] / c['ids']['p:kungfu']['n']:.0%} |")
        w("")
        notes.append(f"Verteidigen: Gruppen {(wr(g1) - wr(g0)) * 100:+.1f} Pp Siegquote, {dsum / g1['n']:.1f} Einsätze pro Kampf")

    # ---- E7
    e7 = R.get("e7")
    if e7:
        cells = e7["cells"]
        nm = {"voll": "Voll (Fasswurf + Löschen von Hand)", "ohne_fasswurf": "Ohne Fasswurf (nur Löschen von Hand)",
              "ohne_loeschen": "Gar nicht löschen", "ohne_brunhilde": "Ohne Brunhilde (Lin statt ihr, nur Löschen von Hand)"}
        w("## 8. Mission 3: Feuer\n")
        w("Aufstellung wie im Spiel (Albrecht, Mira, Brunhilde, Wendy, Elisabeth, Takeda gegen 3 Büttel, 1 Bogenschützen, 1 Reiter und die Zwillinge Oskar und Maja). "
          "Zahlen: Siegquote / durchschnittlich verlorene Häuser von 4, bei steigender Gegnerstärke (Leben und Angriff ×).\n")
        w("| Variante | " + " | ".join(f"×{m}" for m in e7["mults"]) + " |")
        w("|---|" + "--:|" * len(e7["mults"]))
        for v in e7["variants"]:
            row = []
            for m in e7["mults"]:
                a = cells[f"{v}|{m}"]
                row.append(f"{wr(a):.0%} / {a['houses_lost'] / a['n']:.1f}")
            w(f"| {nm[v]} | " + " | ".join(row) + " |")
        w("")
        a0, a1 = cells["voll|1.0"], cells["ohne_loeschen|1.0"]
        notes.append(f"Mission 3: ohne Löschen gehen im Schnitt {a1['houses_lost'] / a1['n']:.1f} von 4 Häusern verloren, mit voller Löschung {a0['houses_lost'] / a0['n']:.1f}")

    # ---- E8
    e8 = R.get("e8")
    if e8:
        cells = e8["cells"]
        nm = {"voll": "Voll (Glocke und Stöcke)", "ohne_glocke": "Ohne Glocke (kein Hundsfreund)", "ohne_staecke": "Stöcke ignoriert",
              "weder_noch": "Weder Glocke noch Stöcke"}
        w("## 9. Mission 5: Waisenhaus, Bienenstöcke und Glocke\n")
        w("Aufstellung wie im Spiel (Mira, Albrecht, Wendy, Elisabeth, Kage-Schwestern, Takeda gegen Stachelia mit 40 Leben und 5 Bienenkrieger, dazu 3 Stöcke). "
          "Zahlen: Siegquote / Anteil der Kämpfe mit gestochenen Kindern / durchschnittliche Runden, bei steigender Gegnerstärke.\n")
        w("| Variante | " + " | ".join(f"×{m}" for m in e8["mults"]) + " |")
        w("|---|" + "--:|" * len(e8["mults"]))
        for v in e8["variants"]:
            row = []
            for m in e8["mults"]:
                a = cells[f"{v}|{m}"]
                row.append(f"{wr(a):.0%} / {a['stung_battles'] / a['n']:.0%} / {a['turns'] / a['n']:.1f}")
            w(f"| {nm[v]} | " + " | ".join(row) + " |")
        w("")
        a0, a1 = cells["voll|1.0"], cells["weder_noch|1.0"]
        notes.append(f"Mission 5: bei ×1,0 gewinnt die Gruppe {wr(a0):.0%}, Kinder werden in {a0['stung_battles'] / a0['n']:.0%} der Kämpfe gestochen (ohne Glocke und Stöcke: {wr(a1):.0%} / {a1['stung_battles'] / a1['n']:.0%})")

    # ---- E9
    e9 = R.get("e9")
    if e9:
        cells = e9["cells"]
        nm = {"voll": "Voll (Wart, Puppe, Beiboot, Breitseite)", "ohne_breitseite": "Ohne Breitseite", "ohne_wart": "Ohne Wart (keine Vorgeschichte)"}
        w("## 10. Mission 6: Hafenstadt, Ziel Schiff\n")
        w("Aufstellung wie im Spiel (Hundsfreund, Mira, Elisabeth, Albrecht, Robo, Takeda gegen die Aufstellung der Karte: Büttel, Bogenschützen und Reiter, Wachen auf dem Steg, Kisten-Sperre). Die Auslöser der Mission sind nachgebildet: Wart Runde 3 auf dem Steg, die Trainingspuppe Runde 4 von hinten, das Beiboot mit Verstärkung Runde 5. "
          "Zahlen: Siegquote / durchschnittliche Runden bis zum Schiff, bei steigender Gegnerstärke.\n")
        w("| Variante | " + " | ".join(f"×{m}" for m in e9["mults"]) + " |")
        w("|---|" + "--:|" * len(e9["mults"]))
        for v in e9["variants"]:
            row = []
            for m in e9["mults"]:
                a = cells[f"{v}|{m}"]
                row.append(f"{wr(a):.0%} / {a['turns'] / a['n']:.1f}")
            w(f"| {nm[v]} | " + " | ".join(row) + " |")
        w("")
        a0, a1 = cells["voll|1.0"], cells["ohne_breitseite|1.0"]
        notes.append(f"Mission 6: bei ×1,0 gewinnt die Gruppe {wr(a0):.0%} in {a0['turns'] / a0['n']:.1f} Runden (ohne Breitseite {wr(a1):.0%})")

    # ---- E10
    e10 = R.get("e10")
    if e10:
        cells = e10["cells"]
        w("## 11. Warten (wachsam) und Verteidigen\n")
        w("„Warten“ gibt bis zur nächsten eigenen Phase +N Angriff, der nur für den Gegenschlag zählt. Zufällige Gruppen aus 6 Helden gegen "
          f"{e10['enemy_count']} Soldaten (Stärke ×{e10['mult']}). Siegquote, mit Verteidigen aus und an; Einsätze pro Kampf von Warten und Verteidigen.\n")
        w("| Bonus Warten | Verteidigen aus | Verteidigen an | Warten-Einsätze (an) | Verteidigen-Einsätze (an) |")
        w("|---|--:|--:|--:|--:|")
        for wv in (0, 2, 3):
            a0, a1 = cells[f"wait|{wv}|0"], cells[f"wait|{wv}|1"]
            def uses(a, tag):
                return sum(v["uses"] for k, v in a["abs"].items() if k.endswith("/" + tag) and k.split("/")[0] in HEROES) / a["n"]
            w(f"| +{wv} Angriff | {wr(a0):.1%} | {wr(a1):.1%} | {uses(a1, '_wait'):.1f} | {uses(a1, '_defend'):.1f} |")
        w("Die Simulations-KI wartet nur, wenn sie nichts zu tun hat, und nutzt Gegenschläge nicht gezielt. Der Bonus ist hier deshalb neutral (innerhalb des Messrauschens von etwa ±1,5 Pp), er verschiebt das Gleichgewicht nicht. Die Wirkung zeigt sich erst im bewussten Spiel. Für Gegner gilt der Bonus nicht.")
        w("")
        a2, a0 = cells["wait|2|1"], cells["wait|0|1"]
        notes.append(f"Warten (wachsam, +2 Angriff): Siegquote {wr(a2):.1%} gegen {wr(a0):.1%} ohne Bonus (Verteidigen an)")

    # ---- Kurzfassung oben
    head = ["## Kurzfassung\n"] + [f"- {n}" for n in notes] + [""]
    L[2:2] = head if notes else []
    w("## Grenzen\n")
    w("- Die KI spielt solide, aber nicht perfekt; Fähigkeiten, die kluges Positionieren brauchen (Stabsprung, Wurf, Versteck), werden eher unter- als überschätzt.")
    w("- Beide Seiten nutzen dieselbe KI; Spott zwingt auch Spielerfiguren (im Spiel entscheidet der Spieler selbst).")
    w("- Höhenunterschiede sind in der Simulation grob (Berg +1,0, Wasser −0,5); das Spiel nutzt ein stetiges Höhenfeld.")
    w("- Zufallskarten (12×10, Startzonen links/rechts) statt handgebauter Karten.")
    (ROOT / "docs").mkdir(exist_ok=True)
    (ROOT / "docs" / "balance.md").write_text("\n".join(L) + "\n")
    print("docs/balance.md geschrieben")
    if levels:
        d = {"_info": "Erzeugt von tools/balance.py (E3). Faktoren gelten für Leben und Angriff der Gegner; gemessen mit der Simulations-KI.",
             "reference": "Kapitel 1", "levels": levels}
        (GAME / "data" / "difficulty.json").write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n")
        print("game/data/difficulty.json geschrieben")


STEPS = {"calib": calib, "e0": e0_ratings, "e1": e1_contribution, "e2": e2_ablation, "e3": e3_difficulty,
         "e3base": lambda: e3_difficulty(False), "e4": e4_power_ratio, "e5": e5_items, "e6": e6_defend, "e7": e7_fire, "e8": e8_bees, "e9": e9_harbor, "e10": e10_wait, "report": report}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("steps", nargs="+", choices=list(STEPS))
    ap.add_argument("--scale", type=float, default=1.0, help="Anteil der Kämpfe (0.2 = schneller Probelauf)")
    a = ap.parse_args()
    SCALE = a.scale
    for s in a.steps:
        STEPS[s]()
