#!/usr/bin/env python3
"""Docs drift check for Lantern Keeper. The code is the authority on what is in the game;
this checks that the docs still describe it.

    python3 tools/check_docs.py            # exit 1 if anything is out of date
    python3 tools/check_docs.py --strict   # warnings count as failures too

Failures (the docs are wrong):
  1. docs/STORY.md is missing a player-facing text from the code: a goal (id and HUD text), a
     journal entry, a tip, the title card, the letter, or a landmark / WayLamp note.
     Also (STORY.md section 12; AUDIT M23): the level-up cards (title and text on one line) and the
     level-up screen's lines, the Ashbrood's toast, its boss-bar hints, the faint note and the
     fast-travel texts. Each of these sources is optional: if its file is gone, it is skipped, and if
     the file is there but nothing can be read from it, that is a warning, not a failure.
  2. docs/ART_CHECKLIST.md doesn't list an image in assets/art/placeholders/.
  3. AGENTS.md doesn't list a test scene in tools/tests/ or a benchmark scene in tools/bench/.
Warnings (worth a look):
  4. Code that a doc describes changed after the last commit that touched that doc.
  5. A landmark or WayLamp title is not in docs/STORY.md.

Matching ignores markdown emphasis, quote markers, curly quotes and dash styles, and runs of
whitespace, so a line can be quoted, italic or in a table. See
.agents/skills/lantern-keeper-docs/SKILL.md for when and how to update each doc.
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STRING = r'"((?:[^"\\]|\\.)*)"'

# Which code each doc describes (for the "changed since" warning).
WATCH = {
    "docs/DESIGN.md": ["scripts", "systems", "scenes", "project.godot"],
    "docs/STORY.md": ["systems/story", "scripts/main/main.gd", "scripts/world"],
    "README.md": ["project.godot", "scripts/ui/pause_menu.gd", "tools/tests"],
}


def gd_unescape(s: str) -> str:
    out, i = [], 0
    while i < len(s):
        if s[i] == "\\" and i + 1 < len(s):
            out.append({"n": "\n", "t": "\t", '"': '"', "\\": "\\"}.get(s[i + 1], s[i + 1]))
            i += 2
        else:
            out.append(s[i])
            i += 1
    return "".join(out)


def norm(s: str) -> str:
    s = re.sub(r"(?m)^\s*>\s?", "", s)                      # blockquote markers
    for a, b in (("—", "-"), ("–", "-"), ("‘", "'"), ("’", "'"),
                 ("“", '"'), ("”", '"'), ("…", "...")):
        s = s.replace(a, b)
    s = s.replace("*", "").replace("`", "")                  # emphasis and code marks
    s = s.replace("\\|", "|")                                # escaped table pipes
    return re.sub(r"\s+", " ", s).strip()


def read(rel: str) -> str:
    p = ROOT / rel
    return p.read_text(encoding="utf-8") if p.exists() else ""


def block(src: str, start: str) -> str:
    """The text of a const block, from its declaration to the matching close bracket."""
    i = src.find(start)
    if i < 0:
        return ""
    j = i + len(start)
    opener = src[j - 1]
    closer = {"[": "]", "{": "}"}[opener]
    depth, k, in_str = 1, j, False
    while k < len(src) and depth:
        c = src[k]
        if in_str:
            if c == "\\":
                k += 1
            elif c == '"':
                in_str = False
        elif c == '"':
            in_str = True
        elif c == "#":
            k = src.find("\n", k)
            if k < 0:
                break
        elif c == opener:
            depth += 1
        elif c == closer:
            depth -= 1
        k += 1
    return src[j:k - 1]


def story_texts(story_gd: str) -> dict:
    goals = re.findall(r'\{"id": ' + STRING + r', "text": ' + STRING, block(story_gd, "const GOALS := ["))
    entries = re.findall(r"(?m)^\s*(\d+): \[" + STRING + r", " + STRING + r"\]", block(story_gd, "const ENTRIES := {"))
    tips = re.findall(STRING + r": " + STRING, block(story_gd, "const TIPS := {"))
    title = re.findall(STRING, block(story_gd, "const TITLE_CARD := ["))
    letter = re.search(r"const LETTER := " + STRING, story_gd)
    return {
        "goals": [(gd_unescape(i), gd_unescape(t)) for i, t in goals],
        "entries": [(int(n), gd_unescape(a), gd_unescape(b)) for n, a, b in entries],
        "tips": [(gd_unescape(k), gd_unescape(v)) for k, v in tips],
        "title_card": [gd_unescape(t) for t in title],
        "letter": gd_unescape(letter.group(1)) if letter else "",
    }


def notes(main_gd: str) -> list:
    """(kind, id, title, text) for every landmark and WayLamp placed in main.gd."""
    out = []
    for m in re.finditer(r'_add_landmark\(\s*' + STRING + r',\s*' + STRING + r',\s*' + STRING + r',(.*?),\s*' + STRING + r'\s*\)', main_gd, re.S):
        out.append(("landmark", gd_unescape(m.group(1)), gd_unescape(m.group(2)), gd_unescape(m.group(5))))
    for m in re.finditer(r'_add_waylamp\(\s*' + STRING + r',(.*?),\s*' + STRING + r',\s*' + STRING + r'\s*\)', main_gd, re.S):
        out.append(("WayLamp", gd_unescape(m.group(1)), gd_unescape(m.group(3)), gd_unescape(m.group(4))))
    return out


def extra_texts() -> tuple[list, list]:
    """Other player-facing texts (STORY.md section 12). Returns (checks, warnings).
    A check is (label, [lines]); every line must appear in STORY.md. For a card, title and text must
    share one line of STORY.md (its table row). Format strings (with %) and empty strings are skipped."""
    checks, warns = [], []

    def plain(s: str) -> bool:
        return s.strip() != "" and "%" not in s

    def source(rel: str):
        src = read(rel)
        return src if src else None

    # Level-up cards and screen (the card screen goes in M2; then this file is gone and is skipped).
    src = source("scripts/ui/level_up.gd")
    if src is not None:
        cards = re.findall(r'"title":\s*' + STRING + r',\s*"body":\s*' + STRING, src)
        lines = [gd_unescape(t) for t in re.findall(r'\.text = ' + STRING, src) if plain(gd_unescape(t))]
        # M2: the card screen is gone; level_up.gd now holds the level-up lines (const ..._LINE), checked below.
        lines += [gd_unescape(t) for t in re.findall(r'(?m)^const [A-Z0-9_]+_LINE := ' + STRING, src) if plain(gd_unescape(t))]
        if not cards and not lines:
            warns.append("check_docs: no level-up cards or lines found in scripts/ui/level_up.gd (did its format change?)")
        for title, body in cards:
            checks.append(("card", f"level-up card {gd_unescape(title)!r}", [gd_unescape(title), gd_unescape(body)]))
        for line in lines:
            checks.append(("line", "level-up screen", [line]))
    # The Ashbrood's toast and its boss-bar hints.
    src = source("scripts/enemies/ashbrood.gd")
    if src is not None:
        toasts = [gd_unescape(t) for t in re.findall(r'_show_toast\(' + STRING, src) if plain(gd_unescape(t))]
        if not toasts:
            warns.append("check_docs: no toast found in scripts/enemies/ashbrood.gd (did its format change?)")
        for t in toasts:
            checks.append(("line", "Ashbrood toast", [t]))
    src = source("scripts/ui/boss_bar.gd")
    if src is not None:
        hints = []
        for m in re.finditer(r'(?m)^\s*(?:var\s+)?hint\s*:?=\s*(.*)$', src):
            hints += [gd_unescape(h) for h in re.findall(STRING, m.group(1)) if plain(gd_unescape(h))]
        if not hints:
            warns.append("check_docs: no boss-bar hints found in scripts/ui/boss_bar.gd (did its format change?)")
        for h in hints:
            checks.append(("line", "boss-bar hint", [h]))
    # Notes the keeper is shown that aren't landmarks (the faint note).
    src = source("scripts/player/player.gd")
    if src is not None:
        for title, body in re.findall(r'note_opened\.emit\(\s*' + STRING + r',\s*' + STRING + r'\s*\)', src):
            parts = [gd_unescape(title)] + [l for l in gd_unescape(body).split("\n") if plain(l)]
            checks.append(("line", f"note {gd_unescape(title)!r} in player.gd", [p for p in parts if plain(p)]))
    # Fast-travel texts.
    src = source("scripts/ui/travel_menu.gd")
    if src is not None:
        consts = [gd_unescape(c) for c in re.findall(r'(?m)^const [A-Z_]+ := ' + STRING, src)]
        consts = [c for c in consts if plain(c)]
        if not consts:
            warns.append("check_docs: no text constants found in scripts/ui/travel_menu.gd (did its format change?)")
        for c in consts:
            checks.append(("line", "fast-travel text", [c]))
    return checks, warns


def git(*args: str) -> str:
    try:
        return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, check=True).stdout
    except (OSError, subprocess.CalledProcessError):
        return ""


def main() -> int:
    strict = "--strict" in sys.argv
    fails: list[str] = []
    warns: list[str] = []

    # 1. STORY.md has every player-facing text in the code.
    story_md = read("docs/STORY.md")
    hay = norm(story_md)
    lines = [norm(l) for l in story_md.splitlines()]
    st = story_texts(read("systems/story/story.gd"))
    if not st["goals"]:
        fails.append("could not read GOALS from systems/story/story.gd (did its format change? update tools/check_docs.py)")
    for gid, text in st["goals"]:
        rows = [l for l in lines if re.search(r"(^|[^\w])" + re.escape(gid) + r"([^\w]|$)", l)]
        if not rows:
            fails.append(f"STORY.md: goal `{gid}` is missing (HUD text: {text!r})")
        elif not any(norm(text) in r for r in rows):
            fails.append(f"STORY.md: goal `{gid}` text differs; the game says {text!r}")
    for n, title, text in st["entries"]:
        if not any(norm(title) in l and norm(text) in l for l in lines):
            fails.append(f"STORY.md: journal entry {n} ({title!r}) is missing or differs; the game says {text!r}")
    for tid, text in st["tips"]:
        if norm(text) not in hay:
            fails.append(f"STORY.md: tip `{tid}` is missing or differs; the game says {text!r}")
    for line in st["title_card"]:
        if norm(line) not in hay:
            fails.append(f"STORY.md: title card line differs; the game says {line!r}")
    for line in (l for l in st["letter"].split("\n") if l.strip()):
        if norm(line) not in hay:
            fails.append(f"STORY.md: letter line differs; the game says {line!r}")
    found = notes(read("scripts/main/main.gd"))
    if not found:
        fails.append("could not read any _add_landmark(...) calls from scripts/main/main.gd (update tools/check_docs.py)")
    for kind, nid, title, text in found:
        for line in (l for l in text.split("\n") if l.strip()):
            if norm(line) not in hay:
                fails.append(f"STORY.md: {kind} `{nid}` note line missing or differs; the game says {line!r}")
        if norm(title) not in hay:
            warns.append(f"STORY.md: {kind} `{nid}` title {title!r} isn't mentioned")

    checks, extra_warns = extra_texts()
    warns += extra_warns
    for kind, label, parts in checks:
        if kind == "card":
            if not any(all(norm(p) in l for p in parts) for l in lines):
                fails.append(f"STORY.md: {label} is missing or differs; the game says {parts[0]!r}: {parts[1]!r}")
        else:
            for p in parts:
                if norm(p) not in hay:
                    fails.append(f"STORY.md: {label} missing or differs; the game says {p!r}")

    # 2. ART_CHECKLIST.md lists every placeholder image.
    checklist = read("docs/ART_CHECKLIST.md")
    for png in sorted((ROOT / "assets/art/placeholders").glob("*.png")):
        if png.name not in checklist:
            fails.append(f"ART_CHECKLIST.md: no row for assets/art/placeholders/{png.name}")

    # 3. Every test scene is listed where tests are listed.
    tests = sorted(p.name for p in (ROOT / "tools/tests").glob("test_*.tscn"))
    agents = read("AGENTS.md")
    for t in tests:
        if t not in agents:
            fails.append(f"AGENTS.md: test {t} isn't in 'Verify before committing'")
    # Benchmarks aren't tests (run_tests.sh skips them), but agents must know how to run them.
    for b in sorted(p.name for p in (ROOT / "tools/bench").glob("*.tscn")):
        if f"tools/bench/{b}" not in agents:
            fails.append(f"AGENTS.md: benchmark tools/bench/{b} isn't listed")

    # 4. Code a doc describes changed after the doc was last touched.
    for doc, paths in WATCH.items():
        last = git("log", "-1", "--format=%h", "--", doc).strip()
        if not last or git("diff", "--name-only", "HEAD", "--", doc).strip():
            continue   # never committed, or being updated right now
        changed = [f for f in git("diff", "--name-only", f"{last}..HEAD", "--", *paths).split() if f]
        changed += [f for f in git("diff", "--name-only", "HEAD", "--", *paths).split() if f and f not in changed]
        if changed:
            more = f" (+{len(changed) - 6} more)" if len(changed) > 6 else ""
            warns.append(f"{doc} last changed in {last}; since then: {', '.join(changed[:6])}{more}. Check it still matches.")

    for w in warns:
        print("WARN  " + w)
    for f in fails:
        print("FAIL  " + f)
    bad = len(fails) + (len(warns) if strict else 0)
    print(f"check_docs: {len(fails)} failure(s), {len(warns)} warning(s)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
