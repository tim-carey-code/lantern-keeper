---
name: lantern-keeper-docs
description: Keep Lantern Keeper's docs in step with the game. Use after any change to gameplay, story text, controls, art placeholders or tests; when the owner marks up a doc or makes a decision; before merging a branch; when asked whether the docs are up to date; and when refreshing the README or its screenshots.
---

# Lantern Keeper docs

The game changes often. The docs must say what the game does now, what the owner decided, and what's
only planned. This skill says which doc owns what, when each one changes, and how to check them.

## Who decides what
- **The code** decides what is in the game today.
- **`docs/DECISIONS.md`** decides what was agreed. Where it disagrees with another doc, it wins. Its newest entries make `docs/replan/GAME_PLAN.md` (approved 2026-11-27) the plan of record. The "Standing decisions" index at its top points to the entries that still stand.
- **The owner** decides story text, design direction and scope. Agents draft; the owner approves.

## Which doc owns what

| Doc | Owns | Changes when |
|---|---|---|
| `docs/DECISIONS.md` | Every owner decision and scope change, newest first: date, decision, why. Append-only; the index at the top only points to entries | The owner decides something, or a playtest changes the plan. Update the index when a decision starts or stops standing |
| `docs/DESIGN.md` | The game as built: systems, numbers, regions, lamps, foes, controls. Unbuilt parts are marked **PLANNED (Mx)** with their milestone; things the plan removes are marked **to be cut (Mx)**. Measured numbers live here | Any gameplay change. Keep its "Synced to commit" line current |
| `docs/STORY.md` | Every player-facing text: goals (id and HUD text), journal entries, tips, title card, letter, landmark and WayLamp notes, UI lines (cards, toasts, boss-bar hints, the faint note, travel texts), people's lines, plus planned story. Texts are marked **APPROVED**, **DECIDED**, **DEFAULT** or **DRAFT**. §13 lists texts that need rewriting | Any text change in `systems/story/story.gd`, `scripts/main/main.gd`, `scripts/world/`, `scripts/ui/`, `scripts/enemies/`, `scripts/player/` or `dialogue/` |
| `docs/ROADMAP.md` | Milestones M1a-M9 (from the game plan §18): scope, owner checks, tests, risks, status; a short history | A milestone starts, passes its playtest gate, or changes scope |
| `docs/PLAYTEST.md` | The next playtest and the current one: how to run it, what to try, the questions, and the owner's results | A build is ready for the owner to play, or the owner reports back |
| `docs/ART_CHECKLIST.md` | Every image the owner may draw, with path, size, status and milestone. One row per placeholder | A placeholder is added or replaced, the owner finishes art, or a milestone adds things to draw |
| `docs/replan/` | The approved game plan, the audit and the plan's review. The plan of record until the owner approves the new DESIGN and ROADMAP; then the folder moves to `docs/archive/` | Not edited, except to move it |
| `docs/research/` | Reference material (the ARPG reference brief) | Rarely |
| `docs/PLAN_*.md` | Proposals waiting to be merged: `PLAN_NPCS_ENEMIES.md` (M4) and `PLAN_LAKESHORE.md` (M7) | Merged into DESIGN, STORY and DECISIONS at their milestone, then moved to `docs/archive/` |
| `docs/archive/` | Retired docs, kept unchanged, with a README that says what each was and why it was retired | A doc is retired (`git mv` it here). Never edit what's inside |
| `dialogue/*.dialogue` | People's lines, one Dialogue Manager file per person (PLANNED, M4) | With STORY.md, word for word, in the same change |
| `README.md` | The public page: pitch, status, screenshots, features, how to run, controls, tests, credits, license. Describes `main` only. Rewritten when M1b merges to `main` | Controls, features or status change on `main`; at each milestone |
| `AGENTS.md` | Rules for agents, and the full test command list | A test scene, tool or rule is added |
| `assets/CREDITS.md` | Every third-party asset and add-on, its source and license | In the same commit as the asset |

## Rules
1. **Update docs in the same branch as the code change.** A gameplay commit without its doc update is unfinished work.
2. **Story text needs the owner.** New or changed player-facing text goes into STORY.md marked **DRAFT** in the same change as the code. Only the owner turns DRAFT into APPROVED. Never rewrite APPROVED or DECIDED text without asking; suggest new wording in STORY §13 instead.
3. **Code and STORY.md must match word for word** (the checker enforces it). When the owner marks up STORY.md, copy their exact wording into the code. From M4, `.dialogue` files must match STORY.md too.
4. **Planned is not built.** DESIGN describes the code. Mark everything else PLANNED with its milestone, and never describe a milestone as built before it merges into the branch you are documenting.
5. **Prototypes stay on their branch.** The README describes `main` and at most mentions the prototype line in one line.
6. **Decisions go in DECISIONS.md.** That includes "we tried X and dropped it". Link the playtest or message that led to it. Never edit an old entry; add a new one.
7. **Don't duplicate.** The README links to DESIGN, STORY and the rest. It doesn't copy them. Numbers live in DESIGN.md (from `systems/tuning.gd`), nowhere else.
8. **Archive, don't delete.** A retired doc moves to `docs/archive/` with `git mv`, unchanged, and gets a row in the archive README.
9. **Voice:** short, plain sentences. Calm. No hype, no emoji. Mark uncertainty.
10. **Pronouns:** Oswin is "he". Ebba is "she". The keeper is "they". The Soul of the Wick is "it". Amos, Maud, Kit and Ivo get no pronouns until the owner chooses.
11. **Public repo:** no personal details, secrets or machine-specific private paths in docs.

## Procedure
1. See what changed: `git diff --stat main...HEAD` (or since the last doc commit).
2. Map each change to its docs with the table above and update them.
3. Run the checker and fix every FAIL. Read every WARN; each one names code that changed after a doc was last touched:
   ```
   python3 tools/check_docs.py            # exit 1 = docs out of date
   python3 tools/check_docs.py --strict   # warnings fail too (use before merging to main)
   ```
4. If the HUD, art or a region changed visibly, refresh the README images (needs xvfb-run and ffmpeg; silent):
   ```
   tools/capture/readme_shots.sh
   ```
   Then look at every image before committing. The staged views are the `readme_*` views in `tools/capture/capture.gd`.
5. In the report to the owner, list which docs changed and which DRAFT lines need their markup.

## What the checker covers
`tools/check_docs.py` fails when:
- STORY.md is missing a goal (id and HUD text), journal entry, tip, title-card line, letter line, or landmark/WayLamp note line from the code;
- STORY.md is missing a level-up card (title and text on one line), a level-up screen line, the Ashbrood's toast, a boss-bar hint, a line of the faint note, or a fast-travel text (STORY §12);
- ART_CHECKLIST.md has no row for an image in `assets/art/placeholders/`;
- AGENTS.md (or the README, if it lists tests) misses a test scene in `tools/tests/`, or AGENTS.md misses a benchmark in `tools/bench/`.

It warns when code a doc describes changed after that doc's last commit, when a note's title isn't in STORY.md, or when a STORY §12 source file exists but its texts can't be read (its format changed). A §12 source file that is gone is skipped.
It can't judge whether DESIGN.md's prose or numbers are right. Read the changed code and check by hand.
**Not covered yet** (future work): `dialogue/*.dialogue` files (M4), skill and item texts (M1a-M3), other HUD and prompt lines.
If a code format changes (for example how goals are declared), update the checker in the same commit.
