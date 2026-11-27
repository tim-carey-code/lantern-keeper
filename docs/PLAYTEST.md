# Playtests

## PROTOTYPE build (branch `proto/kl-hollow`): Keeper's Light in the Hollow

Open the `proto/kl-hollow` worktree in Godot and press F5. This build uses a separate prototype save, so your regular save remains untouched. Automated checks use the Dummy audio driver; normal play keeps audio enabled.

Since the loop (branch `proto/kl-loop`), the passage east is open; the old climb north is closed by fallen stones until you come back down it from the Ridge. Start by relighting the hut lantern. Find the red pulse north of the hut, fight the Clinker for the Post Lamp, and burn out the nests with a built lantern's bright core. The blue glints mark two guarded upgrades. Feed the Hollow WayLamp 15 fuel to wake the Ashbrood; break its shell with the beam, then learn its second phase. The level-up screen pauses play and offers three of twelve upgrades.

**Controls:** beam: hold left click / RT; burst: F / RB; dash: Shift / LT. Move: WASD / left stick. Interact/read/refuel: E / A. Build: Space / X. F1 opens the tuning panel; Esc / Start pauses.

**Bigger regions (2026-11-27, branch `proto/kl-big`):** every region is now 4x the area (224 × 200 tiles). The Hollow holds 24 packs and 12 nests instead of 6 and 3, plus three old caches at dead ends. A save from the smaller map starts fresh. Extra questions: does the Hollow now feel big enough, or too big to walk? Is it too full of packs and nests, or too empty anywhere? Does it still run smoothly with many lanterns out?

**Leveling balance (2026-11-27, branch `proto/kl-balance`):** levels now come on a rising curve (6 wick to level 2, then 14, 24, 34, 45, 56, 68...). Expect level 2 after the first pack or two, level 3 or 4 by the Clinker, about level 7 at the Ashbrood and level 8 when it falls (since the level-gap pass). The HUD shows "Lv 3" and the wick toward the next level ("12/24"); a level-up plays a chime, flashes the card screen, and the wick row glows after you choose. Four more upgrades (Hot core, Steady hand, Lee, Spill) make twelve, so every offer has three cards. (Superseded by the level-gap pass below: hatched and re-fought foes pay again, scaled by level.) Extra questions: did levels come at a good pace, early and late? Did any stretch feel like a long wait for the next one? Is the Ashbrood still a real fight at level 7?

**Wick by level gap (2026-11-27, branch `proto/kl-xpgap`):** every foe now has a level, shown on its name bar ("Wickling Lv 2"): Lv 1 around the hut and in the south, rising to 6 by the WayLamp; the Clinker is Lv 4, the Ashbrood Lv 7. Foes well below you pay little and then nothing: the name dims and the "+wick" popup turns grey. Hatchlings and packs that come back after a faint pay again, scaled the same way. The Hollow's last level (8) now comes the moment the Ashbrood falls; lighting the WayLamp gives only a little. Extra questions: did you notice the levels and the grey popups? Did farming near the hut stop paying at about the right point? Did going north feel like the faster way up?

**The first 10 minutes (2026-11-27, branch `proto/kl-onboard`):** start a **new game** (the map changed; an old prototype save keeps old clears). The road north is now short and stepped: one lone Wickling about 10 tiles out, a second cold old lamp at 12 to relight, a pack of 3, then Oswin's crook at about 19 tiles with one shelled Wickling sleeping on it and 6 scrap beside it. The Post Lamp's first job is the nest 11 tiles past the crook. Then one pack with a Spitwick and an elite, the Clinker (now a mid-boss near the WayLamp), and the WayLamp. The rest of the Hollow, the south included, is optional. What to try: play from the letter to the WayLamp without the F1 panel, then once more wandering south and sideways first. Extra questions: did you always know where to go next? Did anything wake while you were at the hut? Was the lone Wickling a good first fight, and did the tips show at the right moment? Did the crook still feel earned with a small guard? Did burning the first nest with your own lamp click? Is the second old lamp a good safe spot, or too cheesy (owner: cut it if so)? Best of all, hand it to someone new and watch their first 10 minutes without helping.

**The loop and WayLamp fast travel (2026-11-27, branch `proto/kl-loop`):** start a **new game** (the map changed). The Hollow's road north is the same up to the first nest; then it turns east to pack 2, the Clinker and the WayLamp, which now stands north-east of the hut, a few steps above the carved stone. Kindle it and go straight on east into the Reedmarsh, and through it to the pumphouse and its WayLamp as before. Then climb north out of the marsh: the path starts at its north-west corner by a cairn (it is open as soon as you reach the marsh; the cairn asks you to light the marsh first). It comes up at the Ridge's east end, beside the glazier's workshop and the lens. From there the Ridge runs one way: the coat, the signal station, its WayLamp, the old steps (the Lakeshore below them is still empty). The far west of the Ridge is optional. The marsh and the Ridge have no Keeper's Light foes yet; their WayLamps still bring the old swarm. **Fast travel:** at any lit WayLamp, press E / A: a list of every lit WayLamp opens. Pick one and you are there after a short fade. B / Q / Esc / Start closes it. It won't open while something hunts you, while a WayLamp kindles or during the Ashbrood fight; the WayLamp says why. What to try: play the whole loop once from a new game without F1 and without looking at the map, then use fast travel back and forth: the Hollow to the marsh and back, on the pad and with the mouse. Try to open it with a pack chasing you. Walk down the old climb from the Ridge and see the stones give way. Extra questions: did you ever have to walk back the way you came? Was it clear to leave east right after the Hollow's WayLamp, and to climb out of the marsh? Did the Ridge feel like one walk, entry to steps? Should the marsh climb stay open, or open only once the marsh is lit? Did fast travel feel quick and safe? Is "pushing the stones down" a good shortcut, or should the old climb just stay open? Texts to mark up: the ledger, cairn and pumphouse lines, two goal lines and the travel texts (STORY.md, DRAFT).

**Prototype limits:** creatures and effects are code-drawn placeholders. Leads, journal changes, the third boss phase, foes beyond the Hollow, and full animation/audio polish are not included. Values are prototypes and can be adjusted in F1.

Questions (decision gate):
1. Did aiming and firing the beam feel good on mouse and pad? What felt off: reach, speed, sound or hit feedback?
2. Did you dash on purpose to dodge? When hit, did it feel fair?
3. Did you work out how shells and nests are damaged? Did the Clinker take too long?
4. Did finding the Post Lamp change how you fought? Did it feel earned?
5. Did the level-up choices feel distinct and useful?
6. Was the Ashbrood tense but fair? Did you understand each phase?
7. Did the lures pull you along? Did the Hollow still feel empty anywhere?
8. Did you still build lamps, and why?

### Results: 2026-11-27, owner (gamepad only so far)
1. Aiming and firing the beam feels good. **Hit feedback felt off** → added a hit flash, screen shake on the burst, kills and big hits (a short freeze on a kill was already in).
2. Dashed on purpose to dodge; hits felt fair.
3. Didn't know what the Clinker or the Ashbrood were → **names and health bars over foes, a pale shell bar above the red one, and a boss bar for the Ashbrood**.
4. The Post Lamp felt earned and changed how he fought.
5. Choices mostly distinct; **"Quick fill" was useless** (the lamp already refills fast) → replaced by **"Kindled kills"** (each kill gives back 10% charge).
6. Couldn't tell the Ashbrood's phases apart or whether it was taking damage → the boss bar shows phase, health, shell and a one-line hint for each phase.
7. The lures pulled him along.
8. Built lamps because monsters are afraid of them, which may be too strong → now about half the Wicklings are timid and stay out; the brave ones walk in, burn after 2.5 s and run. Elites, the Clinker and the Ashbrood ignore lanterns completely.

---

Older playtests (M1, M2, M3, the Wicklings and the WayLamps) are in `docs/archive/PLAYTEST_PRE_ARPG.md`, unchanged.
