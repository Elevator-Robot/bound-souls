"""Static roster/resource checks. These do not replace a Godot gameplay test."""
import hashlib
import json
from pathlib import Path
import re
import struct
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

    def test_old_battle_backgrounds_are_not_referenced(self):
        for folder in ("scripts", "scenes", "resources", "assets"):
            for path in (ROOT / folder).rglob("*"):
                if path.suffix not in (".gd", ".tscn", ".tres"):
                    continue
                with self.subTest(file=str(path.relative_to(ROOT))):
                    self.assertNotRegex(path.read_text(), r'background[123]\.png')

    def test_battle_backdrop_preserves_aspect_and_fills_viewport(self):
        scene = (ROOT / "scenes/battle/battle_scene.tscn").read_text()
        backdrop = scene.split('[node name="Background"')[1].split("\n[node ")[0]
        self.assertIn('type="TextureRect"', backdrop)
        self.assertIn("anchor_right = 1.0", backdrop)
        self.assertIn("anchor_bottom = 1.0", backdrop)
        self.assertIn("mouse_filter = 2", backdrop)
        self.assertIn("texture_filter = 2", backdrop)
        self.assertIn("expand_mode = 1", backdrop)
        self.assertIn("stretch_mode = 6", backdrop)
        self.assertIn('texture = ExtResource("2_background")', backdrop)
        self.assertIn("assets/backgrounds/battle/moonlit-turquoise-mushroom-clearing.png", scene)

    def test_battle_backgrounds_match_all_thirteen_originals(self):
        inventory = json.loads((ROOT / "art/backgrounds/sources.json").read_text())
        self.assertEqual(len(inventory["images"]), 13)
        expected_paths = {image["texture"] for image in inventory["images"]}
        self.assertEqual(len(expected_paths), 13)
        script = (ROOT / "scripts/battle/battle_scene.gd").read_text()
        background_list = script.split("const BACKGROUND_PATHS:")[1].split("const BATTLE_SOUNDS:")[0]
        paths = re.findall(r'"res://([^"]+)"', background_list)
        self.assertEqual(len(paths), 13)
        self.assertEqual(set(paths), expected_paths)
        self.assertIn("\t_load_random_background()", script.split("func _ready()")[1].split("func _start_battle()")[0])
        copied_paths = {p.relative_to(ROOT).as_posix()
                        for p in (ROOT / "assets/backgrounds/battle").glob("*.png")}
        self.assertEqual(copied_paths, expected_paths)
        for image in inventory["images"]:
            with self.subTest(background=image["original_filename"]):
                data = (ROOT / image["texture"]).read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), image["sha256"])
                self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
                self.assertEqual(struct.unpack(">II", data[16:24]),
                                 (inventory["width"], inventory["height"]))

    def test_battle_backgrounds_have_lossless_godot_import_settings(self):
        inventory = json.loads((ROOT / "art/backgrounds/sources.json").read_text())
        for image in inventory["images"]:
            with self.subTest(background=image["original_filename"]):
                settings = (ROOT / (image["texture"] + ".import")).read_text()
                self.assertIn('importer="texture"', settings)
                self.assertIn('type="CompressedTexture2D"', settings)
                self.assertIn(f'source_file="res://{image["texture"]}"', settings)
                self.assertIn("compress/mode=0", settings)
                self.assertIn("process/size_limit=0", settings)

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

    def test_battle_atlases_have_godot_import_settings(self):
        for name in NAMES:
            atlas = f"assets/sprites/{name.lower()}-complete-battle.png"
            settings = (ROOT / (atlas + ".import")).read_text()
            self.assertIn('importer="texture"', settings)
            self.assertIn(f'source_file="res://{atlas}"', settings)
            self.assertIn('type="CompressedTexture2D"', settings)


if __name__ == "__main__":
    unittest.main()
