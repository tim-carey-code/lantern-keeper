---
name: lantern-keeper-docs
description: Keep Lantern Keeper's docs in step with the game. Use after any change to gameplay, story text, controls, art placeholders or tests; when the owner marks up a doc or makes a decision; before merging a branch; when asked whether the docs are up to date; and when refreshing the README or its screenshots.
---

# Lantern Keeper docs

The game changes often. The docs must say what the game does now, what the owner decided, and what's
only planned. This skill says which doc owns what, when each one changes, and how to check them.

## Who decides what
- **The code** decides what is in the game today.
- **`docs/DECISIONS.md`** decides what was agreed. Where it disagrees with another doc, it wins.
- **The owner** decides story text, design direction and scope. Agents draft; the owner approves.

## Which doc owns what

| Doc | Owns | Changes when |
|---|---|---|
| `docs/DECISIONS.md` | Every owner decision and scope change, newest first: date, decision, why | The owner decides something, or a playtest changes the plan |
| `docs/DESIGN.md` | The game as built on `main`: systems, numbers, regions, lanterns, controls. Unbuilt things marked **planned**, prototypes in their own section | Any gameplay change. Keep its "Synced to commit" line current |
| `docs/STORY.md` | Every player-facing text: goals (id and HUD text), journal entries, tips, title card, letter, landmark and WayLamp notes, plus planned story. Lines are marked DECIDED, DEFAULT or DRAFT | Any text change in `systems/story/story.gd`, `scripts/main/main.gd` or `scripts/world/` |
| `docs/ROADMAP.md` | Milestones and their status | A milestone starts, passes its playtest gate, or changes scope |
| `docs/PLAYTEST.md` | The current playtest: how to run it, what to try, the questions | A build is ready for the owner to play |
| `docs/ART_CHECKLIST.md` | Every image the owner may draw, with path, size and status. One row per placeholder | A placeholder is added or replaced, or the owner finishes art |
| `docs/PLAN_*.md` | Proposals waiting for owner markup | Drafted; folded into DESIGN/STORY/DECISIONS once approved |
| `README.md` | The public page: pitch, status, screenshots, features, how to run, controls, tests, credits, license. Describes `main` only | Controls, features or status change; at each milestone |
| `AGENTS.md` | Rules for agents, and the full test command list | A test scene, tool or rule is added |
| `assets/CREDITS.md` | Every third-party asset, its source and license | In the same commit as the asset |

## Rules
1. **Update docs in the same branch as the code change.** A gameplay commit without its doc update is unfinished work.
2. **Story text needs the owner.** New or changed player-facing text goes into STORY.md marked **DRAFT** in the same change as the code. Only the owner turns DRAFT into DECIDED. Never rewrite DECIDED text without asking.
3. **Code and STORY.md must match word for word** (the checker enforces it). When the owner marks up STORY.md, copy their exact wording into the code.
4. **Prototypes stay on their branch.** Describe a prototype in DESIGN.md's prototype section on that branch, with its playtest questions in PLAYTEST.md. The README describes `main` and at most mentions the prototype in one line.
5. **Decisions go in DECISIONS.md.** That includes "we tried X and dropped it". Link the playtest or message that led to it.
6. **Don't duplicate.** The README links to DESIGN, STORY and the rest. It doesn't copy them. Numbers live in DESIGN.md (from `systems/tuning.gd`), nowhere else.
7. **Voice:** short, plain sentences. Calm. No hype, no emoji. Use "they" for H. and for the keeper.
8. **Public repo:** no personal details, secrets or machine-specific private paths in docs.

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
- ART_CHECKLIST.md has no row for an image in `assets/art/placeholders/`;
- AGENTS.md (or the README, if it lists tests) misses a test scene in `tools/tests/`.

It warns when code a doc describes changed after that doc's last commit, or a note's title isn't in STORY.md.
It can't judge whether DESIGN.md's prose or numbers are right. Read the changed code and check by hand.
If a code format changes (for example how goals are declared), update the checker in the same commit.
