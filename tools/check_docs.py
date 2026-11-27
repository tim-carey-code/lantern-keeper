#!/usr/bin/env python3
"""Docs drift check for Lantern Keeper. The code is the authority on what is in the game;
this checks that the docs still describe it.

    python3 tools/check_docs.py            # exit 1 if anything is out of date
    python3 tools/check_docs.py --strict   # warnings count as failures too

Failures (the docs are wrong):
  1. docs/STORY.md is missing a player-facing text from the code: a goal (id and HUD text), a
     journal entry, a tip, the title card, the letter, or a landmark / WayLamp note.
  2. docs/ART_CHECKLIST.md doesn't list an image in assets/art/placeholders/.
  3. AGENTS.md (and README.md, if it lists tests) doesn't list a test scene in tools/tests/.
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

    # 2. ART_CHECKLIST.md lists every placeholder image.
    checklist = read("docs/ART_CHECKLIST.md")
    for png in sorted((ROOT / "assets/art/placeholders").glob("*.png")):
        if png.name not in checklist:
            fails.append(f"ART_CHECKLIST.md: no row for assets/art/placeholders/{png.name}")

    # 3. Every test scene is listed where tests are listed.
    tests = sorted(p.name for p in (ROOT / "tools/tests").glob("test_*.tscn"))
    agents = read("AGENTS.md")
    readme = read("README.md")
    for t in tests:
        if t not in agents:
            fails.append(f"AGENTS.md: test {t} isn't in 'Verify before committing'")
        if "tools/tests/test_" in readme and t not in readme and not t.startswith("test_prototype_"):
            fails.append(f"README.md: test {t} isn't listed")

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
