"""Static roster/resource checks. These do not replace a Godot gameplay test."""
import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
NAMES = ("Whisp", "Nyx", "Moss", "Maw", "Malgharok", "Khefret", "Juniper")


class SoulAssetsTest(unittest.TestCase):
    def test_runtime_resource_paths_exist(self):
        files = [ROOT / "project.godot"]
        for folder in ("scripts", "scenes", "resources", "assets"):
            files.extend(p for p in (ROOT / folder).rglob("*")
                         if p.suffix in (".gd", ".tscn", ".tres"))
        for path in files:
            for ref in re.findall(r'res://[^"\s]+', path.read_text()):
                with self.subTest(file=str(path.relative_to(ROOT)), ref=ref):
                    self.assertTrue((ROOT / ref[6:]).is_file())
                    self.assertIsNone(re.search(r'/sprites/(?:ow1|sprite\d+)(?:_|\.)', ref))

    def test_seven_distinct_species_and_starter(self):
        text = (ROOT / "scripts/autoload/game_state.gd").read_text()
        roster = text.split("const STARTING_SOUL:")[0]
        self.assertEqual(re.findall(r'^\t"(\w+)": \{', roster, re.M), list(NAMES))
        self.assertIn('"name": "Whisp"', text.split("const STARTING_SOUL:")[1])
        self.assertNotIn("evolves_to", text)
        for name in NAMES:
            self.assertIn(f'assets/sprites/{name.lower()}-complete-battle.tscn', roster)

    def test_imported_files_match_recorded_hashes_and_clips(self):
        records = json.loads((ROOT / ".daydream/assets.json").read_text())["assets"]
        for name in NAMES:
            asset_id = name.lower() + "-complete-battle"
            record = next(r for r in records if r["name"] == asset_id)
            with self.subTest(soul=name):
                self.assertEqual(record["approval"]["revision_hash"], record["revision_hash"])
                for filename, digest in record["sha256"].items():
                    self.assertEqual(hashlib.sha256((ROOT / filename).read_bytes()).hexdigest(), digest)
                source = json.loads((ROOT / record["paths"]["source"]).read_text())
                clips = {clip["name"]: clip for clip in source["animations"]}
                self.assertTrue(clips["idle"]["loop"])
                for clip in ("attack", "hurt", "death"):
                    self.assertFalse(clips[clip]["loop"])
                    self.assertGreater(len(clips[clip]["frames"]), 1)
                scene = (ROOT / record["paths"]["scene"]).read_text()
                self.assertIn("centered = false", scene)
                self.assertIn("texture_filter = 1", scene)

    def test_legacy_images_are_removed(self):
        legacy = re.compile(r'(?:ow1|sprite(?:[1-9]|1[0-6])(?:_idle|_attack)?)\.png(?:\.import)?$')
        self.assertEqual([p.name for p in (ROOT / "assets/sprites").iterdir()
                          if legacy.fullmatch(p.name)], [])


if __name__ == "__main__":
    unittest.main()
