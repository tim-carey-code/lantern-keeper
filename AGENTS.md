# Lantern Keeper: agent guide

Rules for any AI agent or contributor working in this repo (Claude Code reads this via `CLAUDE.md`).

## What this is
A quiet, moody 2D top-down Godot 4.7 game (GDScript, Compatibility renderer, PC, Linux first).
Single-player, no game over. Read `docs/DESIGN.md`, `docs/STORY.md` (owner-reviewed story, goals, texts), `docs/ROADMAP.md` and especially
`docs/DECISIONS.md` (owner decisions override the design doc) before changing behaviour.

## Working rules
- Build in milestones (`docs/ROADMAP.md`). Each ends with an owner playtest in `docs/PLAYTEST.md`.
  Don't start the next milestone, or add content to fix a loop that isn't fun, before the gate passes.
- Scope follows the game plan and ROADMAP: `docs/replan/GAME_PLAN.md` (approved by the owner 2026-11-27) and the milestones in `docs/ROADMAP.md`. New ideas go in the DESIGN "Maybe later" list, not into the game.
- Every action must work on keyboard/mouse **and** gamepad. Menus must be usable without a mouse.
  Input actions are defined by `tools/setup_input.gd`; edit that and re-run it, don't hand-edit `[input]`.
- Placeholder numbers live in the `Tuning` autoload (`systems/tuning.gd`); expose new ones in the
  debug panel (`scripts/ui/debug_panel.gd`) when they are worth tuning live.
- Never leave the game able to soft-lock. (Since M1b nothing needs fuel: lamps never burn, the old lamps and WayLamps light by touch, and the hut woodpile is scenery. The old rule, "the woodpile always regrows", is retired with it.)

## Layout
- `systems/` game-wide logic: `tuning.gd`, `inventory.gd`, `progress.gd` (autoloads), `fog/`, `wind/`, `light/`, `audio/`, `combat/` (`hunt.gd`, `faint_rule.gd`)
- Lanterns: everything a lit lantern does to the world (light radius, bright core, keeping small dark out, refilling the keeper) lives in the "Effects" section of `scripts/lanterns/lantern.gd`; foes read it through `LightSense`. Add new lantern mechanics there (the owner is redesigning lanterns).
- `scripts/` per-feature nodes: `main/` (world generation), `player/`, `lanterns/`, `resources/`, `world/` (landmarks), `ui/`
- `scenes/main/main.tscn` the game scene; `tools/` setup and tests; `docs/` design docs (`docs/archive/` holds retired docs, kept unchanged)
- `assets/` files the game loads; `source/` working files: Pixelorama `.pxo` in `source/art/`, the palette in `source/palette/`, original vendor sheets in `source/vendor/`. `source/audio/` is empty for now; sound and music are the owner's job.

## Verify before committing
```
godot --headless --audio-driver Dummy --path . --import
tools/run_tests.sh                                                                             # every test below; fails on any SCRIPT ERROR too
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_core.tscn   # exit 0 = pass
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_skills.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_flasks.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_input.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_threats.tscn   # light reactions, warmth, the faint (M1b: the ward is gone)
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_save.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_slots.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_ridge.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_story.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_waylamps.tscn  # lit by touch, the Ashbrood's ember, hold fights
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_faint.tscn     # the faint rule (M1b): cleared stays cleared, nothing carried lost, bosses keep their phase
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_upgrades.tscn
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_leveling.tscn   # the curve: L2 at the crook; the Ashbrood kill gives L5 (beeline) or L6 (explorer)
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_telegraphs.tscn # foe wind-ups, the fairness rules, the keeper's feedback, the art swap hook
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_sprite_tool.tscn # the sprite pipeline (tools/art/README.md) on a synthetic sheet
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_hollow.tscn # prototype branch only
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_onboarding.tscn # prototype: the first 10 minutes' main route
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_loop.tscn # prototype: the loop route, one-way Ridge, WayLamp fast travel
python3 tools/check_docs.py                                                                    # docs match the code
# A test that fails to parse never quits: wrap runs in `timeout 120`.
# test_save sometimes hangs at exit after printing "RESULT fails=0" (exit 124 from the timeout): an engine thread spins after quit().
# It happens on the M1a base commit too (5 of 12 runs there). Re-run it; a real failure prints FAIL or fails>0.
# M1b: the same hang hits about one test per full run (test_story, test_upgrades, test_waylamps; one unnamed engine
# thread at 100% after quit() while the main thread waits). Stopping every audio player at quit didn't end it. Cause
# unknown (ptrace is off and godot is stripped). Re-run; exit 124 after "RESULT fails=0" with no FAIL is this hang.
# In a fresh checkout the first --import can crash (Godot 4.7.2) and leave the font unimported, and then every
# test fails with "Could not preload resource file ...kenney_pixel.ttf". Run --import again until it exits 0.
# After merging a branch that adds a new `class_name` script, run --import before the tests, or they fail with
# "Identifier ... not declared in the current scope" (the global class cache is stale).
godot --headless --audio-driver Dummy --fixed-fps 60 --path . --quit-after 1800                    # no errors
```
## Performance benchmark (not a test; `run_tests.sh` doesn't run it)
```
godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/bench/bench.tscn            # game logic only
xvfb-run -a -s "-screen 0 1280x720x24" godot --audio-driver Dummy --fixed-fps 60 --disable-vsync \
  --path . res://tools/bench/bench.tscn                                                              # adds frame time and draw calls
# optional: -- <lanterns> <foes> <frames> <bolts> <burning> [profile] [tells=N]   (default 30 20 400 40 4; "-- 30 20 400 0 0" = no fight)
#   profile: also times each kind of node (foes, bolts, effects, lanterns, the keeper, telegraphs) on its own
#   tells=N: adds N Spitwicks winding up at the keeper without a pause, the Ashbrood and the Clinker
```
- It places 30 lanterns around the start, keeps 20 foes in play, runs a fight at a firing range away from the keeper (40 Lampfire bolts always in
  the air hitting 8 targets that can't die, with splash, effects and damage numbers, over 4 burning areas), keeps the level-up cards from pausing
  the world (it reports any paused frames), and prints a table (average and worst
  process / physics time, fog step, fog texture update, node count; draw calls when rendering).
- **Budget:** game logic (process + physics) averages well under 4 ms a frame at 30 lanterns and 20 foes
  (DECISIONS.md). Run it after changing the fog, foes, lanterns, the map or anything that redraws every frame.
- Hot paths to keep cheap: foes read lantern light, WayLamps and mirrors from `LightSense` (one snapshot a frame,
  `bump()` it when lanterns appear, go, are lit, snuffed or relight; it caches each lantern's core from its Effects);
  never start an `AudioStreamPlayer` per hit (`Sfx` mixes through one polyphonic player); the fog only steps tiles below full fog or in light (call
  `FogGrid.mark_all_dirty()` after replacing `density` or `remembered` wholesale); the map is drawn once in
  `MapChunk`s; lanterns redraw only when their look changes.

- Add checks to `tools/tests/test_core.gd` for new rules. Tests run as a scene so autoloads exist.
- Tests and captures set `SaveGame.path` to a test file first: they must never read or overwrite the owner's real save.
  Settings (`user://settings.cfg`) are never read or written by a scene run from `res://tools/`; tests also set `Settings.path` to a test file and call `Settings.use_defaults()`.
  `tools/run_tests.sh` also points `XDG_DATA_HOME` at a scratch folder, so every `user://` file a test writes is kept away from the owner's data.
- Tests strip joypad events first: a real controller on this PC would otherwise move the test keeper (this caused flaky runs).
- Automated runs are silent (`--audio-driver Dummy`). Don't play sound through the owner's speakers.
- Visual check without the owner's screen: render frames on a virtual display with `tools/capture/capture.tscn`
  (see the header of `tools/capture/capture.gd`; views: start, marsh, cold, map; the loop: loop_waylamp, loop_marsh_climb, loop_ridge_entry, loop_travel; readability: tell_puff, tell_puff_reduce, tell_adds, tell_dive, tell_dive_arrow, tell_spit, tell_lane, tell_reach, tell_hatch, keeper_dash, keeper_cast, keeper_drink, keeper_hurt; M1b: m1b_opening, m1b_opening_lit, m1b_faint, m1b_wake, m1b_lures, m1b_ember, m1b_kindle). Write frames under `~/.cache/openclaw/project-scratch/`, never in the repo.
- README images: `tools/capture/readme_shots.sh` renders the staged `readme_*` views into `docs/screenshots/` (look at each one before committing).
- Art: 16x16 sprites drawn at 2x, palette in `source/palette/`. Kenney sheets are recoloured from `source/vendor/`; placeholders come from `tools/art/make_placeholders.py`. The approved creature, keeper and Amos strips come from `tools/art/make_sprites.sh` (private sheets in `tools/art/samples/`, never committed); see `tools/art/README.md`.
  Key-pose sheets become strips with `tools/art/sprite_from_sheet.gd` (`tools/art/README.md`). Its output is the owner's to approve: don't commit generated PNGs to `assets/`, and keep concept images out of the repo.

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
