# Lantern Keeper

A quiet, moody 2D top-down game about pushing back the dark. Godot 4.7, GDScript, PC (Linux first).

- Design: [docs/DESIGN.md](docs/DESIGN.md)
- Roadmap: [docs/ROADMAP.md](docs/ROADMAP.md)
- Decisions log: [docs/DECISIONS.md](docs/DECISIONS.md)
- Asset licenses: [assets/CREDITS.md](assets/CREDITS.md)
- Art checklist (what to draw): [docs/ART_CHECKLIST.md](docs/ART_CHECKLIST.md)
- Current playtest: [docs/PLAYTEST.md](docs/PLAYTEST.md)



## Run
Open the folder in Godot (Project Manager → Import → `project.godot`) and press F5.
Command line: `godot --path ~/Projects/lantern-keeper`

## Controls
| Action | Keyboard / mouse | Gamepad |
|---|---|---|
| Move | WASD / arrows | Left stick / D-pad |
| Read, refuel / relight, turn a Mirror Post right (tap); gather (hold) | E | A (bottom) |
| Turn a Mirror Post left (next to one) | Space | X (left) |
| Build selected lantern | Space / left click | X (left) |
| Pick up lantern | Q / right click | B (right) |
| Switch lantern (tap) / lantern list (hold) / pick 1-4 | Tab / 1-4 | Y (top) |
| Pause menu (resume, save, new game, save and quit, goal pointer, tips) | Esc | Start |
| Map | M | LB |
| Journal (goals, story so far, notes) | J | Back / View |
| Tuning panel | F1 | Left stick click |
| Fullscreen on/off | F11 | |

## Folders
- `scenes/` scenes, grouped by feature
- `scripts/` GDScript, mirroring scenes
- `systems/` game-wide systems (light, fog, resources, save)
- `assets/art|audio|fonts/` exported files the game loads
- `source/` working files (Pixelorama `.pxo`, REAPER projects); not loaded by the game
- `tools/` one-off editor/CLI helper scripts
- `docs/` design docs

## License
- **Code** (GDScript, shaders, scenes, project config, tools): MIT, see [LICENSE](LICENSE).
- **Art, audio, story, design docs, name and logo**: all rights reserved, see [LICENSE-ASSETS.md](LICENSE-ASSETS.md).
- **Third-party assets**: their own licenses, listed in [assets/CREDITS.md](assets/CREDITS.md).
