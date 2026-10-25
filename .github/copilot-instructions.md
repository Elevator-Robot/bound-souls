# Copilot Instructions for Bound Souls

## Build, test, and lint commands

- Open the existing `project.godot` in Summer Engine, or use `npx -y summer-engine@4.8.0 run .` (Node.js 22+ and the Summer desktop app required). See the README for setup and verification.
- Keep `project.godot`, the Godot 4.4 feature tag, and GL Compatibility renderer unless a tested change requires otherwise; do not recreate this project from a Summer template.
- For an external agent, connect Summer's local MCP server using the client's supported configuration and confirm the project context points to this checkout before editing.
- Godot fallback: open the editor with `godot --editor --path .`.
- Import a fresh checkout with `godot --headless --editor --path . --import`, then run a startup smoke check with `godot --headless --path . --quit-after 120`. Check logs for errors, not only the exit code. This does not replace a Summer playtest.
- Export presets are in `export_presets.cfg` (`Linux/X11`, `Windows Desktop`, `Web`). The existing itch.io workflow exports `Web` using Godot 4.4; preserve it unless deployment migration is requested.
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
