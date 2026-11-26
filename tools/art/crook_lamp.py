#!/usr/bin/env python3
"""The shepherd's-crook Post Lamp (owner's pick), as a starting point to refine in Pixelorama.
Writes assets/art/placeholders/post_lamp_lit.png and post_lamp_cold.png (16x32).
Skips files that already exist (your edits are safe) unless --force."""
import pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/art/placeholders"
C = {"d1": "#141a2e", "b3": "#28385e", "b4": "#36507a", "a0": "#fff1c1", "a1": "#ffd27a", "a2": "#f5a742",
     "w": "#9c4a22", "w2": "#5a2a1c"}
def r(c, x0, y0, x1, y1): return f"fill {C[c]} rectangle {x0},{y0} {x1},{y1}"

FRAME = [
    # post (3 px wide), with a foot
    r("w2", 3, 4, 5, 31), r("w", 4, 5, 4, 30), r("w2", 1, 29, 7, 31), r("w", 2, 30, 6, 30),
    # the crook: arm over the top, curling down into a hook
    r("w2", 4, 2, 11, 4), r("w", 5, 3, 10, 3), r("w2", 11, 3, 13, 6), r("w", 12, 4, 12, 5),
    # chain
    r("d1", 12, 7, 12, 8),
    # lamp: little roof, frame, base, finial
    r("d1", 10, 9, 14, 9), r("w2", 9, 10, 15, 10), r("d1", 9, 11, 9, 18), r("d1", 15, 11, 15, 18),
    r("w2", 9, 19, 15, 19), r("d1", 12, 20, 12, 21),
]
LIT = [r("a1", 10, 11, 14, 18), r("a2", 11, 13, 13, 17), r("a0", 12, 14, 12, 16), r("d1", 12, 11, 12, 11)]
COLD = [r("b3", 10, 11, 14, 18), r("b4", 10, 12, 10, 14), r("b4", 11, 12, 11, 12)]

def draw(ops, path):
    cmd = ["magick", "-size", "16x32", "xc:none", "+antialias"]
    for o in ops:
        cmd += ["-draw", o]
    subprocess.run(cmd + [f"PNG32:{path}"], check=True)

def main():
    force = "--force" in sys.argv
    for name, ops in (("post_lamp_lit.png", FRAME + LIT), ("post_lamp_cold.png", FRAME + COLD)):
        target = OUT / name
        if target.exists() and not force:
            print("kept", target.name)
            continue
        draw(ops, target)
        print("wrote", target.name)
main()
