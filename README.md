# Lantern Keeper

A quiet, moody 2D top-down game about pushing back the dark. Godot 4.7, GDScript, PC (Linux first).

- Design: [docs/DESIGN.md](docs/DESIGN.md)
- Roadmap: [docs/ROADMAP.md](docs/ROADMAP.md)
- Decisions log: [docs/DECISIONS.md](docs/DECISIONS.md)
- Asset licenses: [assets/CREDITS.md](assets/CREDITS.md)
- Current playtest: [docs/PLAYTEST.md](docs/PLAYTEST.md)



## Run
Open the folder in Godot (Project Manager → Import → `project.godot`) and press F5.
Command line: `godot --path ~/Projects/lantern-keeper`

## Controls
| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD / arrows | Left stick / D-pad |
| Interact (gather, refuel, relight) | E | A (bottom) |
| Place lantern | Space / left click | X (left) |
| Cancel | Q / right click | B (right) |
| Build menu | Tab | Y (top) |
| Pause | Esc | Start |
| Tuning panel | F1 | Select / Back |

## Folders
- `scenes/` scenes, grouped by feature
- `scripts/` GDScript, mirroring scenes
- `systems/` game-wide systems (light, fog, resources, save)
- `assets/art|audio|fonts/` exported files the game loads
- `source/` working files (Pixelorama `.pxo`, REAPER projects); not loaded by the game
- `tools/` one-off editor/CLI helper scripts
- `docs/` design docs
