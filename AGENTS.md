# Lantern Keeper: agent guide

Rules for any AI agent or contributor working in this repo (Claude Code reads this via `CLAUDE.md`).

## What this is
A quiet, moody 2D top-down Godot 4.7 game (GDScript, Compatibility renderer, PC, Linux first).
Single-player, no game over. Read `docs/DESIGN.md`, `docs/STORY.md` (owner-reviewed story, goals, texts), `docs/ROADMAP.md` and especially
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
tools/run_tests.sh                                                                             # every test below; fails on any SCRIPT ERROR too
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_core.tscn   # exit 0 = pass
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_combat.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_threats.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_save.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_slots.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_ridge.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_story.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_waylamps.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_upgrades.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_leveling.tscn   # wick in a full Hollow clear vs the level targets
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_hollow.tscn # prototype branch only
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_onboarding.tscn # prototype: the first 10 minutes' main route
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_loop.tscn # prototype: the loop route, one-way Ridge, WayLamp fast travel
python3 tools/check_docs.py                                                                    # docs match the code
# A test that fails to parse never quits: wrap runs in `timeout 120`.
# In a fresh checkout the first --import can crash (Godot 4.7.2) and leave the font unimported, and then every
# test fails with "Could not preload resource file ...kenney_pixel.ttf". Run --import again until it exits 0.
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --quit-after 1800                    # no errors
```
## Performance benchmark (not a test; `run_tests.sh` doesn't run it)
```
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/bench/bench.tscn            # game logic only
xvfb-run -a -s "-screen 0 1280x720x24" godot --audio-driver Dummy --fixed-fps 60 --disable-vsync \
  --path . res://tools/bench/bench.tscn                                                              # adds frame time and draw calls
# optional: -- <lanterns> <foes> <frames>   (default 30 20 400)
```
- It places 30 lanterns around the start, keeps 20 foes in play, and prints a table (average and worst
  process / physics time, fog step, fog texture update, node count; draw calls when rendering).
- **Budget:** game logic (process + physics) averages well under 4 ms a frame at 30 lanterns and 20 foes
  (DECISIONS.md). Run it after changing the fog, foes, lanterns, the map or anything that redraws every frame.
- Hot paths to keep cheap: foes read lantern light from `LightSense` (one snapshot a frame, `bump()` it when
  lanterns appear, go or get refuelled); the fog only steps tiles below full fog or in light (call
  `FogGrid.mark_all_dirty()` after replacing `density` or `remembered` wholesale); the map is drawn once in
  `MapChunk`s; lanterns redraw only when their look changes.

- Add checks to `tools/tests/test_core.gd` for new rules. Tests run as a scene so autoloads exist.
- Tests and captures set `SaveGame.path` to a test file first: they must never read or overwrite the owner's real save.
- Tests strip joypad events first: a real controller on this PC would otherwise move the test keeper (this caused flaky runs).
- Automated runs are silent (`--audio-driver Dummy`). Don't play sound through the owner's speakers.
- Visual check without the owner's screen: render frames on a virtual display with `tools/capture/capture.tscn`
  (see the header of `tools/capture/capture.gd`; views: start, marsh, cold, map; the loop: loop_waylamp, loop_marsh_climb, loop_ridge_entry, loop_travel). Write frames under `~/.cache/openclaw/project-scratch/`, never in the repo.
- README images: `tools/capture/readme_shots.sh` renders the staged `readme_*` views into `docs/screenshots/` (look at each one before committing).
- Art: 16x16 sprites drawn at 2x, palette in `source/palette/`. Kenney sheets are recoloured from `source/vendor/`; placeholders come from `tools/art/make_placeholders.py`.

## Storage, git, licensing
- Never put project files, builds or scratch under `/tmp`. Use `~/.cache/openclaw/project-scratch/` for throwaway files and set `TMPDIR` there.
- Public repo: github.com/tim-carey-code/lantern-keeper. Commit with the GitHub noreply address; never commit secrets or personal data.
- Code is MIT (`LICENSE`); art, audio, story, docs and the name are all rights reserved (`LICENSE-ASSETS.md`).
- Every third-party asset needs a row in `assets/CREDITS.md` (source, author, license) in the same commit.

## Docs
- Docs change in the same branch as the code they describe. Follow `.agents/skills/lantern-keeper-docs/SKILL.md`
  (which doc owns what, when it changes, owner approval for story text) and run `python3 tools/check_docs.py` before committing.
- Combat, enemies, bosses, leveling, loot and NPCs follow `.agents/skills/lantern-keeper-arpg/SKILL.md`.

## Story and guidance
- All player-facing story text lives in `docs/STORY.md` (owner-reviewed) and is mirrored in `systems/story/story.gd` (goals, journal entries, tips, letter) and `scripts/main/main.gd` (landmark texts). Change both together.
- New regions must add their goals, landmarks and journal entries from STORY.md; the goal pointer must have a target for every goal that names a place.
- Tests and captures set `Story.skip_opening = true` so the new-game opening doesn't pause them.
