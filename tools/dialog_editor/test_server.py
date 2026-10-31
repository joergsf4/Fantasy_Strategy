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
