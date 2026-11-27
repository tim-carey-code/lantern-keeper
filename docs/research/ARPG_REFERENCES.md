# ARPG reference brief for the Lantern Keeper re-plan

Researched 2026-11-27. **Reference only.** No names, characters, art, levels or content from these games go into our design. Diablo IV, Path of Exile 2 and Last Epoch change every season, so claims about them carry a date.

**Key:** **UNVERIFIED** means I couldn't confirm it from an accessible primary or reputable source. *Inference* marks my own reasoning. poewiki.net and poe2wiki.net block AI agents, and I respected that, so the Path of Exile details are thin. Search engines blocked automated queries, so every source was reached directly.

## Top findings

1. **Six combat inputs is the proven pad ceiling.** Diablo IV fits basic, core, four skill slots, potion (on **LB**) and evade on a pad with no modifier layer ([Starter Guide][d4pad]).
2. **Diablo IV's Dec 2025 potion rework is the closest model for our flasks:** 35% max Life healed instantly, no upgrades, one charge back every 12 s, extra charges from a gear affix ([patch 2.5][d4-25]).
3. **Bosses must feed flasks.** Last Epoch made bosses drop potions *when hit*, because fights with no adds starved players ([dev blog][le-pot]).
4. **Free, endless out-of-combat regen makes flasks pointless.** Grim Dawn players retreated to heal instead of spending potions, so the team added a finite regen pool ([Crate][gd-con]).
5. **Diablo IV's 2026 skill tree suits a 12-level cap:** three branches per skill that open with level, one pick each, and the third pick is a behaviour-changing variant that can even change the element ([Blizzard][d4-loh]).
6. **Picks that change behaviour beat percentage bumps.** Diablo III runes "often completely chang[e] the gameplay" ([Wikipedia][d3wp]). Last Epoch nodes "transform them entirely" ([lastepoch.com][le-skills]).
7. **A small bar is a deliberate design choice.** Last Epoch caps you at five skills to force real choices ([dev blog][le-5]).
8. **Godot's docs recommend additive Sprite2D over 2D lights "for bullets or explosions".** That's key for a game about light ([docs][g-lights]).
9. **Area2D overlap lists lag one physics step.** For instant AoE, use ShapeCast2D with `force_shapecast_update()` or `intersect_shape()` in `_physics_process` ([Area2D][g-area], [ShapeCast2D][g-shapecast], [ray-casting][g-ray]).
10. **The scope killers are stretch-goal platforms, co-op, and multi-year slips** ([HLD][hldwp], [Last Epoch][lewp]).

---

## 1. Action bars

### Diablo IV
- **Controller** (official, 2023; [Starter Guide p.10][d4pad], viewed via [IGN][ign-d4]):
  - **A**: interact plus basic skill
  - **X**: core skill
  - **Y, RB, LT, RT**: the other four slots
  - **LB**: potion
  - **B**: evade
  - **D-pad**: action wheel, town portal, mount, social
  - The image labels LT "Skill Slot 1", the same as Y. That is probably a typo.
- **Keyboard and mouse** ([Fextralife, edited Sep 2026][d4kbm]): left mouse for basic and interact, right mouse for core, 1–4 for slots, **Q** for potion, Space for evade, T for town portal.
- Skills come from a tree and are assigned to slots ([Blizzard][d4-loh]). The assignment UI and how cooldowns and resources are shown are **UNVERIFIED**.

### Diablo III (console)
- On PC, Diablo III swapped the potion bar for a skill bar of quickbar buttons. Earlier games bound only two skills, one per mouse button ([Wikipedia][d3wp]).
- The console edition added direct stick control, an **Evade** move, and quick-equip on the D-pad ([Blizzard FAQ, archived][d3con]).
- The exact button map and the six-slot count are **UNVERIFIED** (player posts only, e.g. [forum][d3-6slot]).

### Path of Exile 2 (controller)
- Path of Exile added controller support in 3.18 ([Wikipedia][poewp]). PoE2 stresses chaining skills into combos ([Wikipedia][poe2wp]).
- The layout is **UNVERIFIED**: slot count, any held-trigger second skill bank, and flask buttons.

### Last Epoch
- **Five equipped skills, on purpose.** More slots would fill up with the same "good supplemental" skills. Five forces "interesting decision making" ([dev blog, 2018][le-5]).
- The game is "built around the limit of five specialized skills". The developers treat skills that work best on auto-cast as a design failure ([FAQ, 2022][le-faq]).
- Controller support exists; patch 1.3.5 fixed "controller and WASD issues" ([Sep 2025][le-ctrl]). Default bindings are **UNVERIFIED**.

### Small top-down games
- **Hades:** five verbs: attack, special, ranged "cast", dash (brief intangibility, and it can deal damage with boons) and a summon "call". There is no item bar ([Wikipedia][hadeswp]).
- **Death's Door:** sword combos plus a bow. **Bow ammo refills by landing sword hits.** Later weapons and three magic projectiles are added, but "the basic attack mechanics remain". The player starts with 4 HP ([Wikipedia][ddwp]).
- **Hyper Light Drifter:** an energy sword plus modules (guns, area attacks), often powered by batteries found in the world ([Wikipedia][hldwp]). Ammo refilling from sword hits and a health-pack button are **UNVERIFIED**.
- Button maps for all three: **UNVERIFIED**.

### What this means for us
- **Proposed bar:** basic light attack, 3–4 flame skills, 1 flask and 1 dodge.
  - Pad: face buttons plus RB/RT for skills, **LB for the flask**, B/Circle for dodge.
  - Keyboard and mouse: left mouse basic, right mouse main skill, 1–3 others, **Q flask**, Space dodge.
  - No held-modifier second bank.
- **The optional beam can use the Death's Door loop.** Basic hits charge it, so it stays distinct from the flame skills without bringing back a fuel economy. *Inference.*
- **Cooldown display** (*inference*; no verified reference): a radial sweep on each icon, a number for anything over about 3 s, and flask charges as pips on the flask slot.

## 2. Flasks and potions

| Game | Model | Verified details |
|---|---|---|
| **Diablo IV** (2.5, 3 Dec 2025) | Timed charges | Heals 35% max Life instantly, no healing over time; "no longer need to be upgraded"; one charge back every **12 s** (was 30 s); Potion Count affix on leg armour; life-regen, life-on-kill and life-per-hit affixes buffed ([patch notes][d4-25]; players on the removed upgrades: [forum][d4-alch]). |
| **Diablo III** | Health globes plus a potion | Enemies drop health orbs, "replacing the need to have a potion bar" ([Wikipedia][d3wp]). The legendary potion "Instantly restores 60% Life" ([Blizzard, archived][d3pot]). The 30 s cooldown is **UNVERIFIED** ([player post][d3-cd]). |
| **Path of Exile** | Flask charges | Flasks were reworked in 3.15 ([Wikipedia][poewp]). Charges from kills, and PoE2's checkpoint refills, are **UNVERIFIED**. |
| **Grim Dawn** | Cooldown potions bought with in-game currency, plus a finite regen pool | 2013: "Health potion cooldown reduced to 12s and cost to 150 iron" ([log][gd-b12]). 2015: 25% instant plus 50% over a short time ([log][gd-2015]). 2016: energy potion on a 25 s cooldown ([log][gd-1007]). Current values are **UNVERIFIED**. |
| **Last Epoch** (0.7.4, 2019) | Potions refilled from drops | Heals 50 + 4 × level. "Bosses will now occasionally drop potions when hit." Potion affixes were cut because potions "nearly always heal you to full" ([dev blog][le-pot]). Current values are **UNVERIFIED**. |

**Pacing lessons:**
- **Grim Dawn:** with free, unlimited out-of-combat regen, players "felt compelled to use it instead of 'wasting' expensive health potions", causing "an excessive amount of leaving combat and running around to heal". A finite pool fixed it and created "feast and famine" moments ([Medierra, 2014][gd-con]).
- **Diablo III:** health globes drop from enemies, so healing pulls you into fights.
- **Diablo IV:** the timer makes the potion a dependable panic button that can't be farmed. Long-run sustain moves to gear.

### What this means for us
- **Hybrid flasks:** 3 lamp-oil charges at the start, plus a charge-capacity affix on one gear slot.
- **Refills:** one charge per fixed pack cleared, a full refill at a lit WayLamp, and a slow trickle timer so nobody is stranded on a boss. Fixed packs mean kill-based refills can't be farmed.
- **Bosses drop oil** at phase thresholds or on hits (the Last Epoch fix).
- **Heal a percentage of max Life** (as Diablo IV does), so healing scales across 12 levels without retuning.
- **Don't sell flasks for gold**, and pick one stance on out-of-combat regen: none (flasks matter) or quick but finite (the Grim Dawn fix).
- **Close the free-heal loop.** Teleporting to a WayLamp plus refilling there is a free full heal. *Inference:* refill only when you light or rest at a lamp, not on arrival.

## 3. Getting and growing skills under a low level cap

- **Diablo IV, Lord of Hatred** (23 Apr 2026; [Blizzard][d4-loh]):
  - "Each Active skill has three skill branches that open progressively as you level", with one modifier per branch.
  - Branches 1 and 2 are general modifiers. Branch 3 offers a "choice of three build-defining properties" (variants), and many "change the category of the skill, such as Fire to Frost".
  - Passive nodes were removed. Skill ranks strengthen the variants.
- **Diablo III runes** ([Wikipedia][d3wp]): runes unlock with level, aren't items, and "often completely chang[e] the gameplay of each skill". For example, one meteor rune cuts its cost; another turns it to ice for cold damage.
- **Last Epoch** ([lastepoch.com][le-skills]):
  - Skills "earn experience" and level on their own. Each has a tree of up to 20 points, and nodes "empower your skills, reduce their mana cost, or transform them entirely".
  - Official examples: a lightning orb that becomes orbiting ball lightning, or a bouncing frost ball; a thrown spear that becomes three falling from the sky.
- **Hades** ([Wikipedia][hadeswp]): boons are a "choice of three", themed by god (lightning effects; knock-back waves), and they can make the dash deal damage. Whether boons attach to specific verbs is **UNVERIFIED**.

### What this means for us
- **Three picks per skill:** four flame skills × three picks is about 12 decisions, which fits roughly 11 level-ups.
  - Picks 1–2 tune the skill (size, speed, cost or cooldown).
  - Pick 3 changes its behaviour: split, orbit, linger as burning ground, chain, or pierce-then-explode.
- **Every pick should change shape or verb, not just a percentage.** Projectile count, path, on-hit or on-death effect, ground effect and status are what make picks memorable in all four games.
- **Make respecs cheap** (Diablo III-style) so players experiment.
- **Skip per-skill XP.** Last Epoch's second progression track would double the tuning work for us. *Inference.*
- **Don't use random "pick 1 of 3" offers.** They suit run-based games; we should show fixed choices.

## 4. Combat feel ("juice") for projectiles

- **Jan Willem Nijman, "The Art of Screenshake"** (INDIGO Classes 2013; [video][nijman]): why "one game plays great and another, similar game feels terrible".
  - The techniques below are from memory, not a transcript (**UNVERIFIED**): bigger and faster bullets, muzzle flash, impact effects, enemy hit flash and knockback, player recoil, a brief freeze on hit ("sleep"), camera kick and lerp, screen shake, and debris that stays on screen.
- **Jonasson and Purho, "Juice it or lose it"** ([video][juice], [source][juice-gh]):
  - Layered tweening, particles, sound and shake turn a plain breakout game into "a juicy game [that] feels alive and responds to everything you do".
  - The repo says it was made for Nordic Game Indie Night; the talk is often cited as GDC Europe 2012.
- **Squirrel Eiserloh, "Juicing Your Cameras With Math"** (GDC 2016; [video][eiserloh], [Vault][eiserloh-v]): smoothing, framing and shake.
  - The Godot 4 recipe based on it ([KidsCanCode][kcc-shake]): events add "trauma" (0–1), trauma decays over time, offset = max × trauma² (or ³), plus a little rotation and smooth noise.
  - Its code still uses Godot 3 names (`export`, `rand_range`, `OpenSimplexNoise`), so it needs porting.
- **Masahiro Sakurai:**
  - ["Eight Hit Stop Techniques"][sak-hs]
  - ["Hit Marks"][sak-hm]: important "especially" when "the camera is pulled back", which applies directly to top-down.
  - ["Knockback"][sak-kb]
- **Overview:** Game Maker's Toolkit, ["Secrets of Game Feel and Juice"][gmtk].
- **Supergiant:** no combat-feel write-up located (**UNVERIFIED**).
- **Godot hook:** `Engine.time_scale` scales the global clock ([docs][g-engine]).

### What this means for us
A feedback budget per projectile (*inference*, built from the techniques above):

| Event | Feedback |
|---|---|
| Cast | Additive muzzle flare, slight recoil, sound |
| Travel | Short trail, additive glow |
| Hit | Target white-flash for 1–2 frames, sparks, small knockback, a damage number that pops then drifts |
| Kill | 40–80 ms hit-stop, bigger burst, a lingering scorch mark |
| Big AoE | Camera trauma, ring flash, a flickering burning-ground decal |

- **Hit-stop:** freeze the attacker and target only. Global `time_scale` stops will stutter at high fire rates. *Inference.*
- **Accessibility:** ship a screen-shake slider and a "reduce flashes" toggle from day one.

## 5. Waypoints and fast travel

- **Diablo III:** taking damage interrupts Town Portal. A legendary item exists only to remove that rule: "Your Town Portal is no longer interrupted by taking damage" ([Blizzard, archived][d3-tp]).
- **Diablo IV:** Town Portal is on the D-pad and on T ([Starter Guide][d4pad], [Fextralife][d4kbm]). Teleporting from the map and any combat lock are **UNVERIFIED** (player posts only).
- **Path of Exile:** some currency items "create portals to town" ([Wikipedia][poewp]).
- **Death's Door:** doors are checkpoints and link every area back to the hub. Players "respawn at the nearest door without otherwise losing progress" ([Wikipedia][ddwp]).

### What this means for us
- **Travel only from a lit WayLamp** to another lit WayLamp. With no field recall, there's no need for combat-lock rules.
- **If field recall is ever added,** use the Diablo III rule (a channel that damage interrupts) and block it while any enemy is aggroed. *Inference.*
- **No town-portal item.** With three regions, lamp-to-lamp travel is enough.
- **Respawn at the last lit WayLamp** (the Death's Door model).
- **Decide whether resting resets fixed packs.** If it does, travel becomes a farming loop. If not, XP and loot are finite, which pairs well with the XP falloff by level gap.

## 6. Scope traps for small indie ARPGs

These are development histories from Wikipedia (which cites interviews) plus developer posts. They are not formal postmortems; I couldn't reach one.

- **Hyper Light Drifter** ([Wikipedia][hldwp]):
  - The Kickstarter asked for about $27k and raised over $600k. Stretch goals added console and portable platforms.
  - Planned for mid-2014, it shipped in 2016 "due to the expanded scope", polish and the lead's health.
  - Co-op "was cut due to time constraints" and patched in later. Wii U and Vita versions were cancelled, and the PlayStation and Xbox port took six months.
- **Death's Door** ([Wikipedia][ddwp]): a two-person core plus two concept artists and a modeller. It deliberately reused ideas from their last game to make "a more advanced, polished game".
- **Last Epoch** ([Wikipedia][lewp]):
  - Kickstarter in 2018, early access in 2019.
  - 1.0 was planned for April 2020, slipped to Q4 2020, then 2021, and shipped in February 2024.
  - The Mac client was cancelled, and Linux updates stopped in 2024.
- **Grim Dawn** ([Wikipedia][gdwp]): even with a licensed ARPG engine (2009), it took until 2016 to reach 1.0 (Kickstarter 2012, early access 2013).

### Traps to avoid
1. **No co-op and no extra platforms** until the single-player loop ships.
2. **Systems multiply.** Rarity × affixes × slots × picks × flasks multiplies tuning work. *Inference:* first pass at about 3 rarities, about 6 slots, about 15 affixes, and about 4 skills × 3 picks.
3. **Reuse:** one projectile system for player and enemies, and one status system for burning ground and hazards.
4. **No second progression track** (see section 3).
5. **Ship in vertical slices,** one region fully playable before the next, because every case above slipped by years.

## 7. Godot 4 notes for many projectiles

Our project targets **Godot 4.7 with the GL Compatibility renderer** (`project.godot`). The docs were checked against godot-docs master on 2026-11-27.

- **Area2D:** overlap lists update "once during the physics step, not immediately after objects are moved". The docs say to use signals instead ([Area2D][g-area]).
- **ShapeCast2D:** with `target_position = (0,0)` and `force_shapecast_update()`, it gives same-frame overlaps, overcoming "some limitations of Area2D". It costs more than a ray ([ShapeCast2D][g-shapecast]).
- **Direct-space queries:** `intersect_ray`, `intersect_shape` (`max_results` 32 by default) and `cast_motion` ([class ref][g-pdss]). They're only safe in `_physics_process()`, because the space may otherwise be "locked" ([ray-casting][g-ray]).
- **Tunnelling:** fast objects can pass through thin colliders. Stretch the shape with speed, raise the tick rate, or use Continuous CD ([troubleshooting][g-trouble]).
- **Servers:** driving `PhysicsServer2D` and `RenderingServer` by RID is the documented route when "tens of thousands of instances" become a bottleneck ([docs][g-servers]). The official [Bullet Shower demo][g-bullets] (GDScript, Compatibility renderer) runs 500 RID bodies with collision mask 0 (bullets don't test each other) and draws them all in one `_draw()`.
- **Node cost:** "Every node has a cost"; trouble starts between thousands and tens of thousands, depending on platform. Detaching with `remove_child` can beat hiding or pausing ([CPU optimization][g-cpu]). Lighter `Object` and `RefCounted` types exist for data ([docs][g-nodealt]).
- **Pooling:** GDScript uses reference counting, "instead of a garbage collector" ([docs][g-mem]). The docs mention pooling only for C# garbage collection ([docs][g-cpu]), so in GDScript pooling saves instancing cost, not GC pauses. Profile first. *Inference.*
- **Glow:** use additive `Sprite2D` (CanvasItemMaterial, Blend Mode Add) "for short-lived dynamic effects, such as bullets or explosions". The trade-off: no shadows, and it can't really light fully dark areas ([2D lights][g-lights]).
- **Particles:** GPUParticles2D is recommended; CPUParticles2D "may perform better on low-end systems" ([docs][g-particles]). The MultiMesh page is flagged as outdated ([docs][g-multimesh]).

### What this means for us
- **We need dozens of projectiles, not thousands.** Use scene-based projectiles with a simple pool (detach, don't free). Move to servers only if the profiler demands it.
- **Collision by job** (*inference*):
  - slow fireballs: Area2D plus signals
  - fast bolts and the beam: a ray or shape cast along each tick's motion
  - instant bursts: one `intersect_shape` at detonation
  - burning ground: a long-lived Area2D that ticks damage on its overlaps
- **Glow budget:** additive sprites for projectiles, trails and explosions. Keep real `PointLight2D`s for the keeper's lantern and WayLamps.

---

## Sources

**Blizzard (official)**
- [d4pad]: Diablo IV Starter Guide p.10, Xbox controls (© 2023 Blizzard), image as hosted by IGN: https://oyster.ignimgs.com/mediawiki/apis.ign.com/diablo-4/9/9a/Diablo_4_xbox_controls.png
- [ign-d4]: IGN page carrying that image: https://www.ign.com/wikis/diablo-4/Controls
- [d4-25]: Diablo IV Patch Notes (2.5), 3 Dec 2025: https://news.blizzard.com/en-us/article/24244466/diablo-iv-patch-notes
- [d4-loh]: "Prepare for the Reckoning: Lord of Hatred Draws Near", 23 Apr 2026: https://news.blizzard.com/en-us/article/24267729/prepare-for-the-reckoning-lord-of-hatred-draws-near
- [d4-alch]: D4 forum thread (players), Dec 2025: https://us.forums.blizzard.com/en/d4/t/236368
- [d3con]: Diablo III console FAQ (archived Jan 2015): http://web.archive.org/web/20150106011925/http://us.battle.net/d3/en/console/
- [d3-tp]: Homing Pads item page (archived Mar 2016): http://web.archive.org/web/20160317050113/http://us.battle.net/d3/en/item/homing-pads
- [d3pot]: Bottomless Potion of Regeneration (archived Dec 2015): http://web.archive.org/web/20151227032318/http://us.battle.net:80/d3/en/item/bottomless-potion-of-regeneration
- [d3-cd]: D3 forum, player post on potion cooldown: https://us.forums.blizzard.com/en/d3/t/63784
- [d3-6slot]: D3 forum, player post on six slots: https://us.forums.blizzard.com/en/d3/t/10142

**Other developers (official)**
- [le-skills]: Last Epoch "Skills": https://lastepoch.com/skills/
- [le-5]: "Skills to Pay the Bills" dev blog, 4 Mar 2018: https://forum.lastepoch.com/t/1333
- [le-faq]: Official Last Epoch General FAQ, 7 Mar 2022: https://forum.lastepoch.com/t/47963
- [le-pot]: "Potion Changes Coming in Patch 0.7.4", 11 Nov 2019: https://forum.lastepoch.com/t/16332
- [le-ctrl]: Eterra Monthly, Sept 2025: https://forum.lastepoch.com/t/79907
- [gd-b12]: Grim Dawn B12 change log, 12 Sep 2013: https://forums.crateentertainment.com/t/28292
- [gd-2015]: Grim Dawn change log, 5 Sep 2015: https://forums.crateentertainment.com/t/29112
- [gd-1007]: Grim Dawn v1.0.0.7 hotfix 2, 24 Dec 2016: https://forums.crateentertainment.com/t/36226
- [gd-con]: Medierra (Crate) on Constitution, 27 May 2014: https://forums.crateentertainment.com/t/28552/50

**Wikipedia (retrieved 2026-11-27)**
- [d3wp]: https://en.wikipedia.org/wiki/Diablo_III
- [poewp]: https://en.wikipedia.org/wiki/Path_of_Exile
- [poe2wp]: https://en.wikipedia.org/wiki/Path_of_Exile_2
- [lewp]: https://en.wikipedia.org/wiki/Last_Epoch
- [gdwp]: https://en.wikipedia.org/wiki/Grim_Dawn
- [hadeswp]: https://en.wikipedia.org/wiki/Hades_(video_game)
- [ddwp]: https://en.wikipedia.org/wiki/Death%27s_Door_(video_game)
- [hldwp]: https://en.wikipedia.org/wiki/Hyper_Light_Drifter

**Community wiki**
- [d4kbm]: Fextralife Diablo 4 Controls: https://diablo4.wiki.fextralife.com/Controls

**Talks and videos**
- [nijman]: https://www.youtube.com/watch?v=AJdEqssNZ-U
- [juice]: https://www.youtube.com/watch?v=Fy0aCDmgnxg
- [juice-gh]: https://github.com/grapefrukt/juicy-breakout
- [eiserloh]: https://www.youtube.com/watch?v=tu-Qe66AvtY
- [eiserloh-v]: https://gdcvault.com/play/1023557/Math-for-Game-Programmers-Juicing
- [kcc-shake]: https://kidscancode.org/godot_recipes/4.x/2d/screen_shake/index.html
- [sak-hs]: https://www.youtube.com/watch?v=tycbMSjDDLg
- [sak-hm]: https://www.youtube.com/watch?v=B-P4ysHSjCg
- [sak-kb]: https://www.youtube.com/watch?v=HVktK4a9Yfo
- [gmtk]: https://www.youtube.com/watch?v=216_5nu4aVQ

**Godot docs**
- [g-area]: https://docs.godotengine.org/en/stable/classes/class_area2d.html
- [g-shapecast]: https://docs.godotengine.org/en/stable/classes/class_shapecast2d.html
- [g-pdss]: https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html
- [g-ray]: https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html
- [g-trouble]: https://docs.godotengine.org/en/stable/tutorials/physics/troubleshooting_physics_issues.html
- [g-servers]: https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html
- [g-bullets]: https://github.com/godotengine/godot-demo-projects/tree/master/2d/bullet_shower
- [g-cpu]: https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html
- [g-nodealt]: https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html
- [g-mem]: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#memory-management
- [g-lights]: https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
- [g-particles]: https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html
- [g-multimesh]: https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html
- [g-engine]: https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-property-time-scale

[d4pad]: https://oyster.ignimgs.com/mediawiki/apis.ign.com/diablo-4/9/9a/Diablo_4_xbox_controls.png
[ign-d4]: https://www.ign.com/wikis/diablo-4/Controls
[d4-25]: https://news.blizzard.com/en-us/article/24244466/diablo-iv-patch-notes
[d4-loh]: https://news.blizzard.com/en-us/article/24267729/prepare-for-the-reckoning-lord-of-hatred-draws-near
[d4-alch]: https://us.forums.blizzard.com/en/d4/t/236368
[d3con]: http://web.archive.org/web/20150106011925/http://us.battle.net/d3/en/console/
[d3-tp]: http://web.archive.org/web/20160317050113/http://us.battle.net/d3/en/item/homing-pads
[d3pot]: http://web.archive.org/web/20151227032318/http://us.battle.net:80/d3/en/item/bottomless-potion-of-regeneration
[d3-cd]: https://us.forums.blizzard.com/en/d3/t/63784
[d3-6slot]: https://us.forums.blizzard.com/en/d3/t/10142
[le-skills]: https://lastepoch.com/skills/
[le-5]: https://forum.lastepoch.com/t/1333
[le-faq]: https://forum.lastepoch.com/t/47963
[le-pot]: https://forum.lastepoch.com/t/16332
[le-ctrl]: https://forum.lastepoch.com/t/79907
[gd-b12]: https://forums.crateentertainment.com/t/28292
[gd-2015]: https://forums.crateentertainment.com/t/29112
[gd-1007]: https://forums.crateentertainment.com/t/36226
[gd-con]: https://forums.crateentertainment.com/t/28552/50
[d3wp]: https://en.wikipedia.org/wiki/Diablo_III
[poewp]: https://en.wikipedia.org/wiki/Path_of_Exile
[poe2wp]: https://en.wikipedia.org/wiki/Path_of_Exile_2
[lewp]: https://en.wikipedia.org/wiki/Last_Epoch
[gdwp]: https://en.wikipedia.org/wiki/Grim_Dawn
[hadeswp]: https://en.wikipedia.org/wiki/Hades_(video_game)
[ddwp]: https://en.wikipedia.org/wiki/Death%27s_Door_(video_game)
[hldwp]: https://en.wikipedia.org/wiki/Hyper_Light_Drifter
[d4kbm]: https://diablo4.wiki.fextralife.com/Controls
[nijman]: https://www.youtube.com/watch?v=AJdEqssNZ-U
[juice]: https://www.youtube.com/watch?v=Fy0aCDmgnxg
[juice-gh]: https://github.com/grapefrukt/juicy-breakout
[eiserloh]: https://www.youtube.com/watch?v=tu-Qe66AvtY
[eiserloh-v]: https://gdcvault.com/play/1023557/Math-for-Game-Programmers-Juicing
[kcc-shake]: https://kidscancode.org/godot_recipes/4.x/2d/screen_shake/index.html
[sak-hs]: https://www.youtube.com/watch?v=tycbMSjDDLg
[sak-hm]: https://www.youtube.com/watch?v=B-P4ysHSjCg
[sak-kb]: https://www.youtube.com/watch?v=HVktK4a9Yfo
[gmtk]: https://www.youtube.com/watch?v=216_5nu4aVQ
[g-area]: https://docs.godotengine.org/en/stable/classes/class_area2d.html
[g-shapecast]: https://docs.godotengine.org/en/stable/classes/class_shapecast2d.html
[g-pdss]: https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html
[g-ray]: https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html
[g-trouble]: https://docs.godotengine.org/en/stable/tutorials/physics/troubleshooting_physics_issues.html
[g-servers]: https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html
[g-bullets]: https://github.com/godotengine/godot-demo-projects/tree/master/2d/bullet_shower
[g-cpu]: https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html
[g-nodealt]: https://docs.godotengine.org/en/stable/tutorials/best_practices/node_alternatives.html
[g-mem]: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#memory-management
[g-lights]: https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html
[g-particles]: https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html
[g-multimesh]: https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html
[g-engine]: https://docs.godotengine.org/en/stable/classes/class_engine.html#class-engine-property-time-scale

## Not verified

- Diablo IV: how cooldowns and resources are shown; the skill-to-slot assignment UI; waypoint and town-portal rules (teleport from the map, any combat lock).
- Diablo III: the console button map, the six-slot count and the 30 s potion cooldown (player posts only).
- Path of Exile and PoE2: the controller layout, flask charges from kills, and checkpoint refills (the community wikis block AI agents and I respected that; GGG's forum archive pages didn't load).
- Last Epoch: default keyboard and controller bindings, and whether the 2019 potion values are still current.
- Grim Dawn: current potion values.
- Hades: button map, and whether boons attach to specific verbs.
- Hyper Light Drifter: ammo refill from sword hits, and a health-pack button.
- Death's Door: button map.
- Nijman's full list of techniques (no transcript available).
- A Supergiant combat-feel write-up (none located).
- A formal ARPG postmortem (none reached; section 6 relies on development histories).
