#!/usr/bin/env python3
"""Draw the placeholder sprites in the 14-colour palette with ImageMagick.

Run from the repo root:  python3 -I tools/art/make_placeholders.py
Writes assets/art/placeholders/*.png (transparent, crisp, no anti-aliasing).
Replace any output with your own Pixelorama art of the same name and size.
Existing files are never overwritten (your art is safe); pass --force to redraw them.
"""
import pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/art/placeholders"

C = {
    "d0": "#0b0e1a", "d1": "#141a2e", "b3": "#28385e", "b4": "#36507a", "b5": "#4a6a94",
    "b6": "#6d8fb3", "b7": "#a3bcd4", "a0": "#fff1c1", "a1": "#ffd27a", "a2": "#f5a742",
    "w": "#9c4a22", "w2": "#5a2a1c",
}

def r(c, x0, y0, x1, y1):
    return f"fill {C[c]} rectangle {x0},{y0} {x1},{y1}"

def poly(c, pts):
    return f"fill {C[c]} polygon " + " ".join(f"{x},{y}" for x, y in pts)

POST = [r("w2", 6, 12, 9, 31), r("w", 7, 12, 8, 30), r("w2", 4, 29, 11, 31), r("w", 5, 29, 10, 30), r("d1", 3, 2, 12, 12)]
CAP = [r("w2", 2, 1, 13, 3), r("w", 3, 1, 12, 2), r("w2", 7, 0, 8, 0)]
RES = [r("w2", 2, 20, 4, 31), r("w2", 11, 20, 13, 31), r("w", 3, 20, 3, 30), r("w", 12, 20, 12, 30),
       r("d1", 1, 10, 14, 21), r("b5", 2, 11, 13, 20), r("b6", 2, 11, 13, 12), r("w", 2, 17, 13, 20), r("d1", 5, 2, 10, 9)]

HOOD = [r("w2", 6, 14, 9, 31), r("w", 7, 14, 8, 30), r("w2", 4, 29, 11, 31), r("w", 5, 29, 10, 30),
        r("d1", 3, 4, 12, 14), r("b4", 2, 2, 13, 5), r("b5", 3, 2, 12, 3), r("b4", 2, 5, 3, 12), r("b4", 12, 5, 13, 12)]
MIRROR = [r("w2", 7, 12, 8, 31), r("w", 7, 12, 7, 30), r("w2", 5, 29, 10, 31),
          poly("d1", [(2, 10), (5, 1), (14, 4), (11, 13)])]

WAY = [r("d1", 6, 40, 25, 47), r("b5", 7, 41, 24, 46), r("b6", 7, 41, 24, 41), r("d1", 9, 36, 22, 40), r("b4", 10, 37, 21, 39),
       r("d1", 14, 16, 17, 36), r("b4", 15, 17, 16, 35),
       r("d1", 7, 3, 24, 17), r("w2", 5, 1, 26, 3), r("w", 6, 1, 25, 2), r("d1", 15, 0, 16, 0), r("d1", 8, 17, 23, 18)]

SPRITES = {
    "post_lamp_lit.png": ((16, 32), POST + [r("a1", 4, 4, 11, 11), r("a2", 6, 6, 9, 10), r("a0", 7, 7, 8, 9)] + CAP),
    "post_lamp_cold.png": ((16, 32), POST + [r("b3", 4, 4, 11, 11), r("b4", 5, 5, 6, 7)] + CAP),
    "reservoir_lamp_lit.png": ((16, 32), RES + [r("a1", 6, 3, 9, 8), r("a0", 7, 4, 8, 7)]),
    "reservoir_lamp_cold.png": ((16, 32), RES + [r("b3", 6, 3, 9, 8)]),
    "hooded_lamp_lit.png": ((16, 32), HOOD + [r("a1", 5, 7, 10, 12), r("a2", 6, 8, 9, 11), r("a0", 7, 9, 8, 10)]),
    "hooded_lamp_cold.png": ((16, 32), HOOD + [r("b3", 5, 7, 10, 12)]),
    "mirror_post_lit.png": ((16, 32), MIRROR + [poly("a0", [(3, 10), (6, 2), (13, 5), (10, 12)]), r("a1", 6, 5, 9, 8)]),
    "mirror_post_dark.png": ((16, 32), MIRROR + [poly("b6", [(3, 10), (6, 2), (13, 5), (10, 12)]), r("b7", 6, 4, 7, 5)]),
    "glass.png": ((16, 16), [
        poly("b6", [(2, 14), (4, 7), (7, 12)]), poly("b7", [(6, 14), (9, 3), (12, 13)]), poly("b6", [(11, 14), (13, 9), (15, 14)]),
        r("a0", 9, 5, 9, 6), r("b7", 4, 9, 4, 9)]),
    "waylamp_lit.png": ((32, 48), WAY + [r("a1", 8, 4, 23, 16), r("a2", 11, 6, 20, 15), r("a0", 14, 8, 17, 13), r("d1", 15, 4, 16, 16), r("d1", 8, 10, 23, 10)]),
    "waylamp_cold.png": ((32, 48), WAY + [r("b3", 8, 4, 23, 16), r("b4", 9, 5, 11, 8), r("d1", 15, 4, 16, 16), r("d1", 8, 10, 23, 10)]),
    "satchel.png": ((16, 16), [
        r("w2", 4, 2, 11, 3), r("w2", 4, 3, 4, 6), r("w2", 11, 3, 11, 6),
        r("w2", 1, 6, 14, 15), r("w", 2, 7, 13, 14), poly("w2", [(1, 6), (14, 6), (13, 10), (2, 10)]),
        poly("w", [(2, 7), (13, 7), (12, 9), (3, 9)]), r("a2", 7, 9, 8, 11), r("a1", 7, 9, 7, 9), r("w2", 2, 12, 13, 12)]),
    "lamp_glass.png": ((16, 16), [
        poly("b5", [(5, 14), (4, 10), (6, 6), (6, 2), (10, 2), (10, 6), (12, 10), (11, 14)]),
        poly("b6", [(6, 13), (5, 10), (7, 7), (7, 3), (9, 3), (9, 7), (11, 10), (10, 13)]),
        r("a0", 6, 8, 6, 11), r("b7", 8, 4, 8, 5), r("b7", 5, 1, 11, 2), r("b4", 4, 14, 12, 15)]),
    "dead_tree.png": ((16, 32), [
        r("d1", 6, 14, 9, 31), r("d1", 4, 30, 11, 31), r("b4", 7, 14, 8, 30),
        r("b4", 7, 6, 8, 13), r("b4", 7, 3, 7, 5),
        r("b4", 6, 12, 6, 13), r("b4", 5, 10, 5, 11), r("b4", 4, 8, 4, 9), r("b4", 3, 7, 3, 7),
        r("b4", 9, 12, 9, 13), r("b4", 10, 10, 10, 11), r("b4", 11, 8, 11, 9), r("b4", 12, 6, 12, 7), r("b4", 13, 5, 13, 5),
        r("b4", 3, 12, 4, 12), r("b4", 2, 13, 2, 13), r("b4", 12, 10, 13, 10)]),
    "reeds.png": ((16, 16), [
        r("b5", 2, 7, 2, 15), r("b5", 6, 4, 6, 15), r("b5", 10, 8, 10, 15), r("b5", 13, 6, 13, 15),
        r("b4", 3, 10, 3, 15), r("b4", 11, 11, 11, 15), r("w", 5, 3, 6, 5), r("w", 13, 5, 13, 7)]),
    "scrap_pile.png": ((16, 16), [
        poly("d1", [(1, 15), (4, 8), (9, 6), (14, 9), (15, 15)]), poly("b5", [(2, 14), (5, 9), (9, 7), (13, 10), (14, 14)]),
        r("b7", 5, 10, 7, 11), r("b7", 10, 11, 11, 12), r("b6", 7, 12, 9, 13), r("w", 3, 12, 4, 13)]),
    "peat.png": ((16, 16), [
        poly("d0", [(1, 15), (3, 9), (8, 7), (13, 9), (15, 15)]), poly("w2", [(2, 14), (4, 10), (8, 8), (12, 10), (14, 14)]),
        r("w", 5, 11, 6, 12), r("w", 9, 10, 10, 11)]),
}

def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    force = "--force" in sys.argv
    for name, ((w, h), ops) in SPRITES.items():  # noqa
        if (OUT / name).exists() and not force:
            continue
        cmd = ["magick", "-size", f"{w}x{h}", "xc:none", "+antialias"]
        for op in ops:
            cmd += ["-draw", op]
        cmd.append(f"PNG32:{OUT / name}")
        subprocess.run(cmd, check=True)
        print("wrote", name)
    return 0

if __name__ == "__main__":
    sys.exit(main())
