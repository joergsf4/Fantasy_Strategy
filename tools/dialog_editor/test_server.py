"""python3 -m unittest tools/dialog_editor/test_server.py : Pruefung und Speichern des Dialog-Editors (auf einer Kopie der Daten)."""
import copy
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import server


class EditorTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        shutil.copytree(server.ROOT / "game" / "data", self.tmp / "data")
        self.orig = server.DATA
        server.DATA = self.tmp / "data"
        self.addCleanup(lambda: (setattr(server, "DATA", self.orig), shutil.rmtree(self.tmp)))

    def body(self, cid="ch2"):
        return {k: copy.deepcopy([c for c in server.load_all()["chapters"] if c["id"] == cid][0][k]) for k in ("intro", "outro", "triggers", "flee", "ideas")}

    def test_unveraendert_speichern_aendert_nichts(self):
        before = {p.name: p.read_bytes() for p in server.DATA.rglob("*.json")}
        for cid in server.chapter_ids():
            server.save_chapter(cid, self.body(cid))
        self.assertEqual(before, {p.name: p.read_bytes() for p in server.DATA.rglob("*.json")})

    def test_text_aendern_laesst_den_rest_der_mission_unberuehrt(self):
        b = self.body()
        b["intro"][0]["text"] = "Neuer Text"
        server.save_chapter("ch2", b)
        m = server.read(server.DATA / "missions" / "ch2.json")
        self.assertEqual(server.read(server.DATA / "story_ch2.json")["intro"][0]["text"], "Neuer Text")
        self.assertIn("goals", m)
        self.assertIn("map", m)

    def test_doppelte_leerzeichen_werden_beim_speichern_bereinigt(self):
        b = self.body()
        b["intro"][0]["text"] = "Ich  knacke   das Schloss! "
        server.save_chapter("ch2", b)
        self.assertEqual(server.read(server.DATA / "story_ch2.json")["intro"][0]["text"], "Ich knacke das Schloss!")

    def test_leere_dialogschritte_werden_entfernt(self):
        b = self.body("ch4")
        b["triggers"][0]["do"].append({"dialogue": []})
        server.save_chapter("ch4", b)
        self.assertFalse(any(s.get("dialogue") == [] for t in server.read(server.DATA / "missions" / "ch4.json")["triggers"] for s in t["do"]))

    def test_charaktere_erstes_auftreten_und_faehigkeiten(self):
        data = server.characters()
        by = {c["id"]: c for c in data["characters"]}
        self.assertEqual(len(data["chapters"]), len(server.chapter_ids()))
        self.assertEqual(by["wart"]["first"]["chapter"], 2)
        self.assertIn("Gegner", by["wart"]["first"]["roles"])
        self.assertEqual(by["xiulan"]["first"]["chapter"], 4)
        self.assertEqual(by["hund"]["first"]["chapter"], 5)
        self.assertIn("stößt dazu", by["hund"]["first"]["roles"])
        self.assertEqual(by["magical_girl"]["first"]["chapter"], 7)
        self.assertEqual(by["quacksalber"]["first"]["chapter"], 3)      # stößt in Mühlbach zur Gruppe
        self.assertEqual(by["quacksalber"]["intro"], 3)
        for uid in ("claude", "fuerst", "dummy"):
            self.assertIsNone(by[uid]["first"], uid)       # noch in keiner Mission
        self.assertEqual(by["wart"]["abilities"][0]["name"], "Raketenwerfer")
        eli = {a["id"]: a["source"] for a in by["elisabeth"]["abilities"]}
        self.assertEqual(eli["kanone"], "Einheit")
        self.assertEqual(eli["breitseite"], "nur in Kapitel 6")

    def test_charaktere_dialogzeilen_stimmen_mit_den_daten(self):
        by = {c["id"]: c for c in server.characters()["characters"]}
        story = server.read(server.DATA / "story_ch1.json")
        n = sum(1 for k in ("intro", "outro") for l in story[k] if l.get("speaker") == "wendy")
        self.assertGreaterEqual(by["wendy"]["chapters"]["1"]["total"], n)
        self.assertEqual(by["wendy"]["chapters"]["1"]["lines"].get("Einleitung", 0), sum(1 for l in story["intro"] if l.get("speaker") == "wendy"))
        self.assertEqual(by["oskar"]["no_flee"], [7])
        self.assertTrue(by["wart"]["flees"])
        self.assertTrue(all(c["lines_total"] == sum(v["total"] for v in c["chapters"].values()) for c in by.values()))

    def test_missionen_lesen_und_gruppe_speichern(self):
        data = server.missions()["missions"]
        by = {m["id"]: m for m in data}
        self.assertEqual(len(data), len(server.chapter_ids()))
        self.assertTrue(any(e["id"] == "wart" for e in by["ch2"]["enemies"]))
        self.assertIn("wart", by["ch3"]["returns"])
        self.assertGreater(by["ch4"]["speakers"]["kungfu"], 0)
        # eine Figur mehr in die Gruppe von Kapitel 2 (freies Landfeld), dann zurueck: Datei bleibt byteweise gleich
        path = server.map_path("ch2")
        before = path.read_bytes()
        m = by["ch2"]
        taken = {tuple(e["pos"]) for e in m["players"] + m["enemies"]} | {tuple(o["pos"]) for o in m["objects"]}
        spot = next([x, y] for y, row in enumerate(m["rows"]) for x, ch in enumerate(row) if ch == "G" and (x, y) not in taken)
        server.save_mission("ch2", {"players": m["players"] + [{"id": "claude", "pos": spot}], "enemies": m["enemies"]})
        self.assertEqual(len(server.missions()["missions"][1]["players"]), len(m["players"]) + 1)
        server.save_mission("ch2", {"players": m["players"], "enemies": m["enemies"]})
        self.assertEqual(path.read_bytes(), before)

    def test_mission_speichern_lehnt_ungueltiges_ab(self):
        m = {x["id"]: x for x in server.missions()["missions"]}["ch2"]
        water = next(([x, y] for y, row in enumerate(m["rows"]) for x, ch in enumerate(row) if ch == "W"), None)
        taken = m["players"][0]["pos"]
        cases = [
            {"players": m["players"] + [{"id": "gibtsnicht", "pos": [0, 0]}], "enemies": m["enemies"]},
            {"players": m["players"] + [{"id": "claude", "pos": [99, 99]}], "enemies": m["enemies"]},
            {"players": m["players"] + [{"id": "claude", "pos": taken}], "enemies": m["enemies"]},
            {"players": m["players"] + [m["players"][0]], "enemies": m["enemies"]},
            {"players": [], "enemies": m["enemies"]},
        ]
        if water:
            cases.append({"players": m["players"] + [{"id": "claude", "pos": water}], "enemies": m["enemies"]})
        before = server.map_path("ch2").read_bytes()
        for body in cases:
            with self.assertRaises(ValueError):
                server.save_mission("ch2", body)
        self.assertEqual(before, server.map_path("ch2").read_bytes())

    def test_faehigkeitsfelder_vorbelegt_speichern_und_zuruecksetzen(self):
        by = {c["id"]: c for c in server.characters()["characters"]}
        ritter = by["ritter"]["ability_notes"]["defaults"]
        self.assertTrue(ritter[0].startswith("Schlachtruf") and ritter[1].startswith("Verspotten"))     # zwei Faehigkeiten: beide Felder gefuellt
        ninjas = by["ninjas"]["ability_notes"]["defaults"]
        self.assertTrue(ninjas[0].startswith("Versteck") and ninjas[1].startswith("Hinterh"))           # zwei Faehigkeiten (seit den neuen Faehigkeiten)
        claude = by["claude"]["ability_notes"]["defaults"]
        self.assertTrue(claude[0].startswith("Polymorph") and claude[1] == "")                          # eine Faehigkeit: zweites Feld leer
        self.assertEqual(by["soldat_infanterie"]["ability_notes"]["defaults"], ["", ""])                # keine: beide leer
        server.save_ability_note("ninjas", 1, "  Rauchbombe: legt eine Nebelwand.  ")
        n = {c["id"]: c for c in server.characters()["characters"]}["ninjas"]["ability_notes"]
        self.assertEqual(n["saved"], [None, "Rauchbombe: legt eine Nebelwand."])
        server.save_ability_note("ninjas", 1, None)
        self.assertNotIn("ninjas", server.read(server.DATA / "ability_notes.json"))                       # Eintrag entfernt
        for bad in ((("gibtsnicht", 0, "x")), ("ninjas", 2, "x"), ("ninjas", 0, "x" * 2001), ("ninjas", 0, 5)):
            with self.assertRaises(ValueError):
                server.save_ability_note(*bad)

    def test_geheimnisse_lesen_pruefen_speichern(self):
        d = server.secrets()
        sec = d["secrets"][0]
        self.assertEqual((sec["trigger"]["by"], sec["trigger"]["ability"], sec["trigger"]["target"]), ("braumeisterin", "fasswurf", "kungfu"))
        self.assertIn("fasswurf", d["units"]["braumeisterin"]["abilities"])        # nur Faehigkeiten mit Gegner-Ziel
        self.assertIn("sec_lin_betrunken", d["portraits"])
        before = server.read(server.DATA / "secrets.json")
        server.save_secrets({"secrets": d["secrets"]})
        self.assertEqual(before, server.read(server.DATA / "secrets.json"))        # unveraendert speichern aendert nichts
        import copy
        new = copy.deepcopy(d["secrets"])
        new[0]["name"] = "Anderer Name"; new[0]["effects"]["atk_pct"] = 15; new[0]["scene"]["lines"][0]["text"] = "  Neu   getextet  "
        server.save_secrets({"secrets": new})
        got = server.read(server.DATA / "secrets.json")
        self.assertEqual(got["secrets"][0]["name"], "Anderer Name")
        self.assertEqual(got["secrets"][0]["scene"]["lines"][0]["text"], "Neu getextet")
        self.assertIn("_info", got)                                                  # Kopfzeile bleibt
        bad = []
        for mutate in (lambda s: s["trigger"].update(ability="baerenpranke"), lambda s: s["trigger"].update(by="gibtsnicht"), lambda s: s["trigger"].update(target="braumeisterin"),
                       lambda s: s["effects"].update(atk_pct=500), lambda s: s["effects"].update(grant_ability="nix"), lambda s: s["scene"].update(left="nix"),
                       lambda s: s["scene"]["lines"][0].update(speaker="ritter"),
                       lambda s: s.update(id="Gross Klein")):
            c = copy.deepcopy(new); mutate(c[0]); bad.append(c)
        c = copy.deepcopy(new) + copy.deepcopy(new); bad.append(c)                   # doppelte Kennung
        for b in bad:
            with self.assertRaises(ValueError):
                server.save_secrets({"secrets": b})
        self.assertEqual(server.read(server.DATA / "secrets.json")["secrets"][0]["name"], "Anderer Name")

    def test_geheimnis_als_freitext_idee_ohne_technik(self):
        d = server.secrets()
        first = d["secrets"][0]
        self.assertEqual(first["characters"], ["braumeisterin", "kungfu"])        # Figuren und Prompt sind Teil jedes Geheimnisses
        self.assertIn("Fass", first["prompt"])
        idee = {"id": "kuerbis_idee", "name": "Kuerbisse", "characters": ["maedchen_baer", "wendy"], "prompt": "  Zwei Figuren treffen einen sprechenden Kuerbis.\nDer Kuerbis stellt ein Raetsel.  "}
        server.save_secrets({"secrets": d["secrets"] + [idee]})
        got = server.read(server.DATA / "secrets.json")["secrets"]
        n = len(d["secrets"])
        self.assertEqual(len(got), n + 1)
        self.assertNotIn("trigger", got[n])                                         # Idee ohne technische Umsetzung
        self.assertEqual(got[n]["prompt"], "Zwei Figuren treffen einen sprechenden Kuerbis.\nDer Kuerbis stellt ein Raetsel.")
        self.assertEqual(server.secrets()["secrets"][n]["characters"], ["maedchen_baer", "wendy"])
        # frisch angelegte Technik mit leerer Zeile oder ganz ohne Zeilen speichert (leere Zeilen werden ignoriert)
        tech = {"id": "t_idee", "name": "T", "characters": ["braumeisterin", "kungfu"], "prompt": "",
                "trigger": {"type": "ability_on_ally", "by": "braumeisterin", "ability": "fasswurf", "target": "kungfu"},
                "effects": {"atk_pct": 5, "grant_ability": "", "status": "betrunken"},
                "scene": {"left": "braumeisterin", "right": "kungfu", "lines": [{"speaker": "braumeisterin", "text": ""}]}}
        other_trigger = copy.deepcopy(tech); other_trigger["trigger"]["target"] = "ritter"; other_trigger["scene"]["right"] = "ritter"
        server.save_secrets({"secrets": d["secrets"][:0] + [other_trigger]})
        self.assertEqual(server.read(server.DATA / "secrets.json")["secrets"][0]["scene"]["lines"], [])
        wrong = copy.deepcopy(other_trigger); wrong["scene"]["lines"] = [{"speaker": "wendy", "text": "Hallo"}]
        with self.assertRaisesRegex(ValueError, "Zeile 1: Sprecher 'Wendy Wolle'"):
            server.save_secrets({"secrets": [wrong]})
        server.save_secrets({"secrets": d["secrets"] + [idee]})
        for bad in ({"characters": ["gibtsnicht"]}, {"prompt": "x" * 6001}, {"name": ""}):
            with self.assertRaises(ValueError):
                server.save_secrets({"secrets": d["secrets"] + [dict(idee, id="x_idee", **bad)]})
        # nur Ideen sind im Spiel nicht aktiv: die Datei bleibt fuer das Spiel gueltig
        for sec in got:
            self.assertTrue(sec["id"] and sec["name"])

    def test_geheimnis_strahl_ueber_verbuendeten(self):
        d = server.secrets()
        beam = next(x for x in d["secrets"] if x.get("trigger", {}).get("type") == "beam_via_ally")
        self.assertEqual((beam["trigger"]["by"], beam["trigger"]["via"], beam["effects"]["reflect_pct"], beam["effects"]["radius"]), ("robo", "samurai", 75, 2))
        self.assertIn("roter_laser", d["units"]["robo"]["beams"])
        self.assertIn("gruener_laser", d["units"]["robo"]["beams"])
        server.save_secrets({"secrets": d["secrets"]})                              # unveraendert speichern geht
        import copy
        for mutate in (lambda s: s["trigger"].update(abilities=[]), lambda s: s["trigger"].update(abilities=["kanone"]), lambda s: s["trigger"].update(via="gibtsnicht"),
                       lambda s: s["trigger"].update(via="robo"), lambda s: s["effects"].update(reflect_pct=0), lambda s: s["effects"].update(radius=9),
                       lambda s: s["effects"].update(cutin={"unit": "nix", "title": "x"}), lambda s: s["scene"]["lines"][0].update(speaker="ritter")):
            sl = copy.deepcopy(d["secrets"])
            mutate(next(x for x in sl if x.get("trigger", {}).get("type") == "beam_via_ally"))
            with self.assertRaises(ValueError):
                server.save_secrets({"secrets": sl})
        sl = copy.deepcopy(d["secrets"])
        b2 = next(x for x in sl if x.get("trigger", {}).get("type") == "beam_via_ally")
        b2["effects"].pop("cutin"); b2["effects"]["reflect_pct"] = 50
        server.save_secrets({"secrets": sl})                                        # Auftritt ist optional
        saved = [x for x in server.read(server.DATA / "secrets.json")["secrets"] if x.get("trigger", {}).get("type") == "beam_via_ally"][0]
        self.assertEqual(saved["effects"], {"mode": "reflect", "reflect_pct": 50, "radius": 2})
        # Wirkungsart "catch" (Futter fuer Brumm)
        catch = next(x for x in d["secrets"] if x.get("effects", {}).get("mode") == "catch")
        self.assertEqual(catch["effects"]["heal"], 8)
        self.assertEqual(catch["effects"]["status"], {"id": "satt", "turns": 3, "reduce_pct": 25})
        for bad in ({"mode": "unbekannt"}, {"heal": 500}, {"status": {"id": "Satt!", "turns": 3, "reduce_pct": 25}}, {"status": {"id": "satt", "turns": 3, "reduce_pct": 99}}):
            sl = copy.deepcopy(d["secrets"])
            c = next(x for x in sl if x.get("effects", {}).get("mode") == "catch")
            c["effects"].update(bad)
            with self.assertRaises(ValueError):
                server.save_secrets({"secrets": sl})

    def test_geheimnis_wurf_regen(self):
        import copy
        d = server.secrets()
        wurf = next(x for x in d["secrets"] if x.get("trigger", {}).get("type") == "throw_ally")
        self.assertEqual((wurf["trigger"]["by"], wurf["trigger"]["ability"], wurf["trigger"]["target"], wurf["effects"]["rain_pct"]), ("museklaugust", "wurf", "ninjas", 75))
        self.assertIn("wurf", d["units"]["museklaugust"]["throws"])
        server.save_secrets({"secrets": d["secrets"]})
        for mutate in (lambda s: s["trigger"].update(ability="bearhug"), lambda s: s["trigger"].update(target="museklaugust"), lambda s: s["effects"].update(rain_pct=0),
                       lambda s: s["effects"].update(radius=9), lambda s: s["effects"].update(height=20), lambda s: s["trigger"].update(by="ritter")):
            sl = copy.deepcopy(d["secrets"])
            mutate(next(x for x in sl if x.get("trigger", {}).get("type") == "throw_ally"))
            with self.assertRaises(ValueError):
                server.save_secrets({"secrets": sl})

    def test_geheimnis_reaktion_in_der_naehe(self):
        import copy
        d = server.secrets()
        near = next(x for x in d["secrets"] if x.get("trigger", {}).get("type") == "ability_near_ally")
        self.assertEqual((near["trigger"]["by"], near["trigger"]["ability"], near["trigger"]["near"], near["effects"]["react_ability"]), ("elisabeth", "kanone", "wendy", "wollmantel"))
        self.assertIn("wollmantel", d["units"]["wendy"]["all_abilities"])
        server.save_secrets({"secrets": d["secrets"]})
        for mutate in (lambda s: s["trigger"].update(ability="gibtsnicht"), lambda s: s["effects"].update(react_ability="schlachtruf"), lambda s: s["effects"].update(react_ability="gruppenheilung"),
                       lambda s: s["effects"].update(radius=0), lambda s: s["trigger"].update(near="elisabeth")):
            sl = copy.deepcopy(d["secrets"])
            mutate(next(x for x in sl if x.get("trigger", {}).get("type") == "ability_near_ally"))
            with self.assertRaises(ValueError):
                server.save_secrets({"secrets": sl})

    def test_geheimnis_treffer_neben_verbuendetem(self):
        import copy
        d = server.secrets()
        hit = next(x for x in d["secrets"] if x.get("trigger", {}).get("type") == "hit_near_ally")
        self.assertEqual((hit["trigger"]["by"], hit["trigger"]["ability"], hit["trigger"]["near"], hit["effects"]["status"]["atk_pct"]), ("magical_girl", "sternschnuppe", "ritter", 25))
        server.save_secrets({"secrets": d["secrets"]})
        for mutate in (lambda s: s["trigger"].update(ability="sternensegen"), lambda s: s["effects"]["status"].update(atk_pct=0), lambda s: s["effects"]["status"].update(turns=0),
                       lambda s: s["effects"]["status"].update(id="Ins Piriert"), lambda s: s["trigger"].update(near="magical_girl")):
            sl = copy.deepcopy(d["secrets"])
            mutate(next(x for x in sl if x.get("trigger", {}).get("type") == "hit_near_ally"))
            with self.assertRaises(ValueError):
                server.save_secrets({"secrets": sl})

    def test_leere_flee_und_ideen_werden_entfernt_und_ideen_gespeichert(self):
        b = self.body("ch3")
        b["flee"] = {}
        b["ideas"] = [{"text": "Wenn Oskar flieht, schreit Maja."}]
        server.save_chapter("ch3", b)
        m = server.read(server.DATA / "missions" / "ch3.json")
        self.assertNotIn("flee", m)
        self.assertEqual(m["ideas"][0]["text"], "Wenn Oskar flieht, schreit Maja.")

    def test_ungueltige_daten_werden_abgelehnt_und_nichts_geschrieben(self):
        orig = (server.DATA / "story_ch2.json").read_bytes()
        for mutate, msg in [
            (lambda b: b["intro"][0].update(speaker="wendy" if b["intro"][0].get("left") != "wendy" and b["intro"][0].get("right") != "wendy" else "ritter"), "Sprecher"),
            (lambda b: b["intro"][0].update(left="gibtsnicht"), "unbekannte Figur"),
            (lambda b: b["triggers"][0].update(when={}), "Ausloeser"),
            (lambda b: b["outro"][0].pop("text"), "Text"),
        ]:
            b = self.body()
            mutate(b)
            with self.assertRaises(ValueError, msg=msg):
                server.save_chapter("ch2", b)
        self.assertEqual(orig, (server.DATA / "story_ch2.json").read_bytes())

    def test_unbekanntes_kapitel_und_pfadtrick(self):
        for cid in ("ch99", "../units", "ch2/../x"):
            with self.assertRaises(ValueError):
                server.save_chapter(cid, self.body())


if __name__ == "__main__":
    unittest.main()
