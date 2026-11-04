"""Tests fuer den Import von Aenderungspaketen: python3 -m unittest tools/dialog_editor/test_import_package.py"""
import contextlib
import copy
import io
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import import_package as ip
import server


class ImportTest(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        shutil.copytree(server.ROOT / "game" / "data", self.tmp / "data")
        self.orig = server.DATA
        server.DATA = self.tmp / "data"
        self.addCleanup(lambda: (setattr(server, "DATA", self.orig), shutil.rmtree(self.tmp)))

    def chapter(self, cid="ch2"):
        return [c for c in server.load_all()["chapters"] if c["id"] == cid][0]

    def package(self, items):
        return {"format": "fuzaketa-aenderungen", "version": 1, "author": "Test", "note": "", "created": "2026-11-04T10:00:00Z", "base": {"commit": "x"}, "items": items}

    def intro_item(self, text="Neuer Einleitungstext", before=None):
        c = self.chapter()
        after = copy.deepcopy(c["intro"])
        after[0]["text"] = text
        return {"kind": "chapter", "chapter": "ch2", "part": "intro", "before": before if before is not None else c["intro"], "after": after}

    def run_report(self, p):
        with contextlib.redirect_stdout(io.StringIO()) as out:
            rows = ip.report(p, ip.State())
        return rows, out.getvalue()

    def test_passendes_paket_wird_uebernommen(self):
        p = self.package([self.intro_item()])
        rows, text = self.run_report(p)
        self.assertEqual([s for _, s in rows], ["passt"])
        self.assertIn("Neuer Einleitungstext", text)
        ip.apply_items([it for it, s in rows if s == "passt"], ip.State())
        self.assertEqual(self.chapter()["intro"][0]["text"], "Neuer Einleitungstext")
        rows, _ = self.run_report(p)           # zweites Mal: schon enthalten
        self.assertEqual([s for _, s in rows], ["schon enthalten"])

    def test_konflikt_wird_nicht_ohne_take_uebernommen(self):
        old = copy.deepcopy(self.chapter()["intro"])
        old[0]["text"] = "anderer Ausgangstext"
        p = self.package([self.intro_item(before=old)])
        rows, _ = self.run_report(p)
        self.assertEqual([s for _, s in rows], ["Konflikt"])
        original = self.chapter()["intro"][0]["text"]
        chosen = [it for it, s in rows if s == "passt"]
        self.assertEqual(chosen, [])
        self.assertEqual(self.chapter()["intro"][0]["text"], original)
        ip.apply_items([it for it, _ in rows], ip.State())      # --take: ausdruecklich uebernommen
        self.assertEqual(self.chapter()["intro"][0]["text"], "Neuer Einleitungstext")

    def test_ungueltige_teile_und_pakete(self):
        rows, _ = self.run_report(self.package([{"kind": "chapter", "chapter": "ch999", "part": "intro", "before": [], "after": []},
                                                {"kind": "chapter", "chapter": "ch2", "part": "../../etc", "before": [], "after": []},
                                                {"kind": "note", "character": "ritter", "slot": 7, "before": None, "after": "x"}, {"kind": "geheim"}]))
        self.assertEqual({s for _, s in rows}, {"ungueltig"})
        with self.assertRaises(SystemExit):
            ip.parse_package('{"format": "x"}')
        with self.assertRaises(SystemExit):
            ip.parse_package("kein json")

    def test_server_pruefung_lehnt_kaputte_daten_ab(self):
        bad = self.intro_item()
        bad["after"][0]["speaker"] = "gibtsnicht"
        with self.assertRaises(ValueError):
            ip.apply_items([bad], ip.State())

    def test_notiz_und_geheimnis(self):
        sec = copy.deepcopy([s for s in server.secrets()["secrets"] if s["id"] == "turbo_treibstoff"][0])
        new = copy.deepcopy(sec)
        new["prompt"] = "Neuer Prompt von einem Texter"
        items = [{"kind": "secret", "id": "turbo_treibstoff", "before": sec, "after": new},
                 {"kind": "note", "character": "ritter", "slot": 0, "before": None, "after": "Neuer Fähigkeits-Text"}]
        rows, _ = self.run_report(self.package(items))
        self.assertEqual([s for _, s in rows], ["passt", "passt"])
        ip.apply_items([it for it, _ in rows], ip.State())
        self.assertEqual([s for s in server.secrets()["secrets"] if s["id"] == "turbo_treibstoff"][0]["prompt"], "Neuer Prompt von einem Texter")
        self.assertEqual([c for c in server.characters()["characters"] if c["id"] == "ritter"][0]["ability_notes"]["saved"][0], "Neuer Fähigkeits-Text")


if __name__ == "__main__":
    unittest.main()
