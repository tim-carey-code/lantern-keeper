#!/usr/bin/env python3
"""Placeholder HUD icons (16x16, 14-colour palette), drawn with ImageMagick.
Writes assets/art/ui/icon_*.png. Existing files are kept (your art is safe); --force redraws."""
import pathlib, subprocess, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/art/ui"
C = {"d0": "#0b0e1a", "d1": "#141a2e", "b4": "#36507a", "b5": "#4a6a94", "b6": "#6d8fb3", "b7": "#a3bcd4",
     "a0": "#fff1c1", "a1": "#ffd27a", "a2": "#f5a742", "a3": "#d9772b", "w": "#9c4a22", "w2": "#5a2a1c"}
def r(c, x0, y0, x1, y1): return f"fill {C[c]} rectangle {x0},{y0} {x1},{y1}"
def poly(c, pts): return f"fill {C[c]} polygon " + " ".join(f"{x},{y}" for x, y in pts)

ICONS = {
    "icon_fuel.png": [poly("a3", [(4, 15), (3, 9), (6, 4), (8, 0), (10, 4), (13, 9), (12, 15)]),
                      poly("a2", [(5, 15), (5, 10), (8, 4), (11, 10), (11, 15)]),
                      poly("a1", [(6, 15), (7, 10), (8, 7), (9, 10), (10, 15)]), r("a0", 7, 12, 8, 14)],
    "icon_scrap.png": [poly("d1", [(1, 15), (3, 7), (9, 4), (15, 8), (15, 15)]), poly("b5", [(2, 14), (4, 8), (9, 5), (14, 9), (14, 14)]),
                       r("b7", 5, 9, 7, 10), r("b6", 9, 11, 11, 12), r("w", 3, 12, 4, 13), r("b7", 11, 7, 12, 7)],
    "icon_glass.png": [poly("b6", [(1, 15), (4, 5), (7, 15)]), poly("b7", [(6, 15), (9, 1), (12, 15)]), poly("b6", [(11, 15), (13, 8), (15, 15)]),
                       r("a0", 9, 4, 9, 6)],
    "icon_lamp.png": [r("w2", 6, 0, 9, 1), r("d1", 3, 2, 12, 3), r("d1", 3, 4, 3, 13), r("d1", 12, 4, 12, 13), r("a1", 4, 4, 11, 13),
                      r("a2", 6, 7, 9, 12), r("a0", 7, 9, 8, 11), r("d1", 3, 14, 12, 15)],
    "icon_warmth.png": [poly("b7", [(8, 15), (1, 8), (1, 4), (4, 1), (8, 4), (12, 1), (15, 4), (15, 8)]),
                        poly("a1", [(8, 12), (5, 8), (7, 4), (8, 6), (9, 4), (11, 8)])],
    "icon_wind.png": [r("b7", 1, 4, 10, 5), r("b7", 10, 2, 12, 3), r("b6", 3, 8, 14, 9), r("b6", 14, 6, 15, 7), r("b5", 1, 12, 8, 13)],
    "icon_cold.png": [r("w2", 7, 4, 8, 15), r("d1", 4, 6, 11, 12), r("b4", 5, 7, 10, 11), r("b5", 5, 7, 6, 8), r("w2", 3, 4, 12, 5)],
    "icon_goal.png": [poly("a2", [(8, 1), (15, 8), (8, 15), (1, 8)]), poly("a1", [(8, 4), (12, 8), (8, 12), (4, 8)]), r("a0", 7, 7, 8, 8)],
}

def main():
    force = "--force" in sys.argv
    OUT.mkdir(parents=True, exist_ok=True)
    for name, ops in ICONS.items():
        target = OUT / name
        if target.exists() and not force:
            print("kept", name)
            continue
        cmd = ["magick", "-size", "16x16", "xc:none", "+antialias"]
        for o in ops:
            cmd += ["-draw", o]
        subprocess.run(cmd + [f"PNG32:{target}"], check=True)
        print("wrote", name)
main()
