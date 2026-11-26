# Lantern Keeper: agent guide

Rules for any AI agent or contributor working in this repo (Claude Code reads this via `CLAUDE.md`).

## What this is
A quiet, moody 2D top-down Godot 4.7 game (GDScript, Compatibility renderer, PC, Linux first).
Single-player, no game over. Read `docs/DESIGN.md`, `docs/ROADMAP.md` and especially
`docs/DECISIONS.md` (owner decisions override the design doc) before changing behaviour.

## Working rules
- Build in milestones (`docs/ROADMAP.md`). Each ends with an owner playtest in `docs/PLAYTEST.md`.
  Don't start the next milestone, or add content to fix a loop that isn't fun, before the gate passes.
- Scope is locked: new ideas go in the DESIGN "Maybe later" list, not into the game.
- Every action must work on keyboard/mouse **and** gamepad. Menus must be usable without a mouse.
  Input actions are defined by `tools/setup_input.gd`; edit that and re-run it, don't hand-edit `[input]`.
- Placeholder numbers live in the `Tuning` autoload (`systems/tuning.gd`); expose new ones in the
  debug panel (`scripts/ui/debug_panel.gd`) when they are worth tuning live.
- Never leave the game able to soft-lock: the hut woodpile always regrows.

## Layout
- `systems/` game-wide logic: `tuning.gd`, `inventory.gd`, `progress.gd` (autoloads), `fog/`, `wind/`, `light/`, `audio/`
- `scripts/` per-feature nodes: `main/` (world generation), `player/`, `lanterns/`, `resources/`, `world/` (landmarks), `ui/`
- `scenes/main/main.tscn` the game scene; `tools/` setup and tests; `docs/` design docs
- `assets/` files the game loads; `source/` working files (Pixelorama `.pxo`, REAPER projects)

## Verify before committing
```
godot --headless --audio-driver Dummy --path . --import
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_core.tscn   # exit 0 = pass
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --quit-after 1800                    # no errors
```
- Add checks to `tools/tests/test_core.gd` for new rules. Tests run as a scene so autoloads exist.
- Automated runs are silent (`--audio-driver Dummy`). Don't play sound through the owner's speakers.
- Visual check without the owner's screen: render frames on a virtual display with `tools/capture/capture.tscn`
  (see the header of `tools/capture/capture.gd`; views: start, marsh, cold, map). Write frames under `~/.cache/openclaw/project-scratch/`, never in the repo.
- Art: 16x16 sprites drawn at 2x, palette in `source/palette/`. Kenney sheets are recoloured from `source/vendor/`; placeholders come from `tools/art/make_placeholders.py`.

## Storage, git, licensing
- Never put project files, builds or scratch under `/tmp`. Use `~/.cache/openclaw/project-scratch/` for throwaway files and set `TMPDIR` there.
- Public repo: github.com/tim-carey-code/lantern-keeper. Commit with the GitHub noreply address; never commit secrets or personal data.
- Code is MIT (`LICENSE`); art, audio, story, docs and the name are all rights reserved (`LICENSE-ASSETS.md`).
- Every third-party asset needs a row in `assets/CREDITS.md` (source, author, license) in the same commit.
