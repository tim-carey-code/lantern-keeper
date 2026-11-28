# Sprite pipeline: key poses to game strips

One image of key poses becomes PNG strips the game loads (`Art.frames`, ART_DIRECTION §6.2-§6.4). You then only
touch up the key frames in Pixelorama. The tool never ships anything: it writes files for you to look at and approve.

```
godot --headless --path . -s tools/art/sprite_from_sheet.gd -- <sheet image> <manifest.cfg> [options]
  --out <dir>           art root (default res://assets/art/): strips go in <dir>/creatures/<subject>/, keeper/ or people/<name>/
  --preview-dir <dir>   where the 8x previews go (default ~/.cache/openclaw/project-scratch/sprite-previews/)
  --preview-only        only the previews: nothing written to the art folders
  --force               overwrite strips you drew or touched up (normally they always win)
```

To try a sheet without touching the game, add `--out ~/.cache/openclaw/project-scratch/sprite-out/`.

**The committed sprites** (the six approved samples, DECISIONS 2026-11-27; the Clinker on `proto/kl-clinker-art`, waiting for approval, DECISIONS 2026-11-28) are rebuilt by `tools/art/make_sprites.sh`
(`--force` to replace touched-up strips too). It needs the private sheets in `tools/art/samples/` (ignored by git;
a `.gdignore` there keeps Godot from importing them), then run `godot --headless --import`. The one-row pilot
`wickling_timid_sample.cfg` is left out: it would write the same timid file names as `wickling.cfg`.

## 1. Make the sheet

Ask for one image with every key pose in a grid of equal cells on flat magenta. A prompt pattern that works:

> Pixel-art style concept sheet, a 3 x 4 grid of equal square cells on a flat pure magenta (#FF00FF) background,
> no grid lines, no text, no shadows on the ground. One creature per cell, the same size and scale in every
> cell, all facing right, whole body visible with a clear magenta gap around it. Row 1: [variant] idle, drift,
> notice (eyes flared), flee. Row 2: ... Dark smoky body, two small pale blue-white square eyes, cold blue
> rim light on top. Palette: near-black navy, slate blues, pale blue-grey (no warm colours).

- Describe the subject from the art bible (ART_DIRECTION §2-§3), never another game.
- JPEG is fine: the magenta is keyed with a tolerance.
- Dark purple grid lines or dark magenta ground shadows: set `key_mode = "hue"`.
- Rows of different heights: set `layout = "auto"` (cells are found from the magenta gaps).
- Poses that overlap in x or y (a wing reaching under the next pose): set `layout = "components"`. The biggest
  shapes in each row are the poses; smaller ones (an ash ring's pieces, flames, motes) join the nearest pose.
- Concept images stay private and out of the repo (ART_DIRECTION §7, question 2). Keep them in
  `tools/art/samples/` (not committed) or outside the repo.

## 2. Write the manifest

Copy one from `tools/art/manifests/`: `wickling.cfg` (3 variants, 16 and 24 px), `spitwick.cfg` and `nest.cfg`
(one shared sheet, non-square frames), `keeper_poses.cfg`, `ashbrood.cfg` (48 px, overlapping poses, the ember kept amber), `clinker.cfg` (32 px, 4 x 6 cells, every strip hand-keyed with `sequence`: a reordered curl, a roll turned half round), `amos.cfg` (a person, skin and green recoloured, the cart as a 48 x 32 prop),
`wickling_timid_sample.cfg` (one row of four idle frames). A `.cfg` is a Godot ConfigFile:

| Section | Keys |
|---|---|
| `[sheet]` | `subject`, `kind` (`creature`, `keeper`, `person`, `prop`), `rows`, `cols`, `frame_size` (16, 24, 32, 48 or `Vector2i(16, 32)`), `anchor` (`foot` or `center`), `facing` (`right`), `layout` (`grid`, `auto` or `components`), `margin` (px trimmed off each grid cell), `key_mode` (`magenta` or `hue`), plus any variant key as the default |
| `[cells]` | `r0c0 = "brave/idle"` (variant/pose; no slash = no variant), or `"skip"`. Several cells with the same pose become one hand-keyed strip of those frames |
| `[variant.<v>]` | `role` (see below), `allow`, `deny`, `special` (colour groups), `frame_size`, `anchor`, `rim` (`small` #36507a, `elite` #4a6a94, `none` or a hex), `outline` (1 px #141a2e), `eyes` (how many to repair; 0 = off), `eye_threshold` (0-1 brightness), `palette` (`cold`, `all` or a list of hexes), `gain` (brighten before snapping), `fill` (0-1 of the frame), `sway`, `seed`, `keep`, `warm` (`snap`: everything to the palette; `ember`: fire-coloured pixels keep the four ambers, optionally only inside `ember_region`; `drop`: fire-coloured pixels clear), `recolour` (`{"beige": [hexes], "skin": [...], "green": [...]}`: pixels of a colour kind (`green`, `beige`, `skin`, `fire`, `grey`, `lit`, `any`) snap only to the colours given), `recolour_regions` (`{"lit": [x0, y0, x1, y1]}`: a rule only in part of the cell) |
| `[cell.rXcY]` | `keep` (`all`, or `largest`: drop separate bits such as a fireball), `keep_near` (px), `region` (`[x0, y0, x1, y1]`, fractions of the cell), `role`, `allow`, `deny`, `special`, `palette`, `warm`, `ember_region`, `recolour`, `recolour_regions`, `eyes`, and any variant key |
| `[pose.<v>.<pose>]` | `rule` (`idle`, `move`, `notice`, `attack`, `hold`, `keys`; `none` = just the key pose), `sequence` (a hand-keyed strip in any order: `["0", "1", "sleep 1", "2 r180"]`; each item a key frame's index in cell order, optionally another pose's name before it to borrow its frame, and `r180` (turned half round on the same foot line, a rolling ball) or `flip` after it; frames may repeat; implies `keys`), `derive` (`["hurt", "death", "spawn", "notice", "windup"]`; `[]` = none), `anim` (output name), `frames`, `bob`, `lean`, `sway`, `fit` (`variant`, `own` = scale this pose by itself, `clip`), `prop` + `file` (a still prop with its own file name, e.g. `amos_cart`, left out of the frames file) |
| `[anim.<name>]` | `fps`, `loop`, `timed_by` (a Tuning name): copied into the frames file if it doesn't have them |

Use `base` for the no-variant name in section names (`[pose.base.idle]`). Defaults by kind: creatures get the rim,
2 eyes and a wisp sway; the keeper, people and props get the outline and no eye repair.

**Palette roles** (the 23 colours, ART_DIRECTION §1.4). `role` defaults to the kind; each role may use these groups:

| Role | Groups |
|---|---|
| `creature` | darks, blues, cold (`#a3bcd4`). Never skin, greens or amber: `allow` can't add them; the Ashbrood's ember comes in only through `warm = "ember"` |
| `person` | everything but the marsh greens (`allow = ["greens"]` to use them) |
| `keeper` | darks, blues, amber, wood, skin |
| `prop` | everything |

Groups: `darks`, `blues`, `cold`, `amber`, `wood`, `skin`, `bone`, `stone`, `greens`, `plum`. `allow` adds groups for plain
snapping, `deny` removes them, and `special` adds groups usable only through `recolour` (the Ashbrood's bone skull
and stone bowl, never its ashen body). All three can be set per cell, variant or sheet. Animation names follow ART_DIRECTION §6.2 (`idle`, `move`, `notice`, `windup`, `attack`, `recover`,
`hurt`, `death`, `spawn`; `windup_puff` and so on for a second attack).

## 3. What the tool does

Per cell: keys out the magenta, crops to the subject, scales it into the frame (every pose of a variant shares one
scale and one baseline), snaps every pixel to the colours its role allows (below) and makes every pixel fully solid or fully clear.
Repairs: the eyes are found in the big image and painted back in `#a3bcd4` (at least 1 px each, the pair kept
apart), then the rim (creatures) or outline (the keeper, people, props).

Auto frames from a key pose (each can be turned off per pose):

| Animation | Frames | Made from |
|---|---|---|
| idle | 4 | the key pose bobbing 0, -1, -1, 0 px; the wisp (bottom third) sways |
| move | 4 | the key pose with a 1 px bob (flee: 2) |
| hurt | 2 | a pale flash of the silhouette, then the key pose |
| notice | 2 | the key pose, then the eyes 1 px bigger |
| death | 5 | a dissolve, outer pixels first (seeded), the eyes last |
| spawn | 5 | the death backwards |
| windup / attack | 1 / 2 | the key pose held; the attack leans its top half 1 px forward |

It writes `<subject>[_<variant>]_<anim>.png` and merges `<subject>.frames.cfg` (frame size per variant, anchor, fps,
loop; keys already there are kept). It prints a summary and writes an 8x preview of every strip on `#1d2745`, with
the source pose beside it: one sheet `<manifest>_preview.png` plus one `<manifest>/<strip>_8x.png` per strip.

**Your art always wins.** The tool records what it wrote in `<subject>.generated.cfg`. A strip that isn't the tool's
(you drew it), or that changed since (you touched it up), is kept and reported as kept. Only `--force` replaces it.

## 4. Touch up in Pixelorama

1. Open the strip as a spritesheet (Pixelorama asks how to import a PNG), with horizontal frames = the frame
   count from the summary, 1 vertical frame. (Menu names are from memory, not checked here.)
2. Fix the key frames first: eyes, rim and silhouette. The palette is `source/palette/lantern-keeper-23.gpl`.
3. Export the same file name, frames left to right, no padding. Keep the `.pxo` in `source/art/<same path>/`.
4. Run the game: the new strip shows (no import step beyond Godot's own). Re-running the tool keeps your version.

## The keeper

The keeper sheets are drawn facing right. Since the sprites step `assets/art/keeper/` has the approved strips, so
the keeper shows them in every direction, mirrored for left; up and down look sideways (DECISIONS 2026-11-27, "the
sprites approved", for the owner to confirm). The Puny sheet's 8 direction rows (`scripts/player/player.gd`) stay
as the fallback. Options later: use the strips only for the side views and the Puny frames for up and down (a small
change in `player.gd`), or draw `_n` and `_s` strips too (ART_DIRECTION §6.2 suffixes).

Tested by `tools/tests/test_sprite_tool.tscn`.
