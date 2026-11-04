"""Tests fuer die Mitmach-Version (GitHub Pages): python3 -m unittest tools/dialog_editor/test_build_pages.py"""
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_pages


class BuildPagesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.out = Path(cls.tmp.name)
        cls.meta = build_pages.build(cls.out)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_dateien_und_momentaufnahme(self):
        for f in ("index.html", "data.json", "missions.json", "characters.json", "secrets.json", ".nojekyll"):
            self.assertTrue((self.out / f).exists(), f)
        data = json.loads((self.out / "data.json").read_text(encoding="utf-8"))
        self.assertGreaterEqual(len(data["chapters"]), 17)
        self.assertIn("commit", data["_meta"])
        self.assertTrue(json.loads((self.out / "secrets.json").read_text(encoding="utf-8"))["secrets"])
        self.assertTrue(json.loads((self.out / "characters.json").read_text(encoding="utf-8"))["characters"])

    def test_seite_laeuft_ohne_server(self):
        html = (self.out / "index.html").read_text(encoding="utf-8")
        self.assertIn('<meta name="fz-static" content="1">', html)
        self.assertNotIn('"/assets/', html)          # alle Pfade relativ, denn Pages liegt unter /Repo-Name/
        self.assertNotIn("fetch(`/api", html)
        self.assertNotIn('fetch("/api', html)

    def test_bilder_klein_und_vollstaendig(self):
        from PIL import Image
        src = {p.name for p in (build_pages.server.ASSETS / "portraits").glob("*.png")}
        dst = {p.name for p in (self.out / "assets" / "portraits").glob("*.png")}
        self.assertEqual(src, dst)
        self.assertLessEqual(max(Image.open(p).height for p in (self.out / "assets" / "portraits").glob("*.png")), build_pages.PORTRAIT_HEIGHT)
        for f in build_pages.FONTS:
            self.assertTrue((self.out / "assets" / "fonts" / f).exists())
        self.assertLess(sum(p.stat().st_size for p in self.out.rglob("*") if p.is_file()), 60e6)    # Pages-Grenze 1 GB, wir bleiben weit darunter


if __name__ == "__main__":
    unittest.main()
