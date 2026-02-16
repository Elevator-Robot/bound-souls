# Copilot Instructions for Bound Souls

## Build, test, and lint commands

- Open the project in Godot: `godot --path .`
- Run a headless startup smoke check: `godot --headless --path . --quit`
- Build/export commands are not configured in-repo yet (no export preset files committed).
- Test commands are not configured in-repo yet (no test framework files or single-test entrypoints committed).
- Lint commands are not configured in-repo yet.

## High-level architecture

- `project.godot` is the source of truth for startup wiring:
  - `run/main_scene` points to `res://scenes/main/main.tscn`
  - `[autoload]` registers `GameState` from `res://scripts/autoload/game_state.gd`
- `scenes/main/main.tscn` is the current entry scene:
  - root `Node2D` (`Main`) with attached script `scripts/main/main.gd`
  - `PlayerSpawn` (`Marker2D`) reserved for player instantiation
  - `UI` (`CanvasLayer`) containing the startup `Title` label
- `scripts/autoload/game_state.gd` holds run-level global state (`souls_collected`) and reset behavior.
- Directory layout is scaffolded for feature growth:
  - scenes split by domain (`main`, `characters`, `world`, `ui`)
  - scripts split by role (`autoload`, `core`, `main`, `player`, `ui`)
  - assets grouped by content type (`audio`, `music`, `sfx`, `sprites`, `ui`)

## Key conventions in this repository

- Keep scene/script pairing mirrored by path when adding features (for example `scenes/<feature>/...` with `scripts/<feature>/...`).
- Put globally accessible systems in `scripts/autoload/` and register them in `project.godot` under `[autoload]`.
- Follow typed GDScript style used here (`var name: Type`, `func ... -> void`, typed `@onready` node references).
- Preserve placeholder folders with `.gitkeep` until real assets/scenes/scripts are added.
