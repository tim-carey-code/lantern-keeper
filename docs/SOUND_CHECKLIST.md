# Sound checklist (owner's Freesound hunt)

Tick the box when the file is picked, downloaded and sent to the assistant (or dropped in `assets/audio/sfx/`).
Status key: `[ ]` not done, `[~]` found but needs tweaks, `[x]` done.

## Rules for every sound
- **Licence: CC0 only.** On Freesound, filter by License -> "Creative Commons 0". Check the licence box on each sound's own page before using it.
- **Format:** download the WAV or the original file. The game wants `.ogg`; the assistant converts it and logs it in `assets/CREDITS.md` (sound name, author, link, licence).
- **Short effects:** 0.1 to 1.5 seconds, no long silent tail, no music or voice in it. Mono is fine.
- **Variants:** for sounds that repeat a lot (footsteps, hits, gathering) grab 3 to 5 similar ones so they don't get tiring.
- **Loops:** only for ambience. 30 to 120 seconds long, no obvious start or end, and no single loud event (a bird, a bang) that will be noticed every minute.
- **Mood:** quiet, soft, a bit mournful. Avoid bright, cartoony or "arcade" sounds. Dark, woody, airy, glassy.
- **Quality:** avoid clipped or very quiet recordings. The game sets the volumes.

## A. Combat (nothing exists yet: the biggest gap)
- [ ] **Beam, loop while held** (a soft rising hum or glow, 2 to 4 s loop). Search: `light beam hum`, `energy loop soft`, `lantern hum`
- [ ] **Beam hitting an enemy, loop** (sizzle, burning light). Search: `sizzle`, `burn loop`, `scorch`
- [ ] **Burst** (a bright whoosh with a chime). Search: `flare whoosh`, `magic burst soft`, `light flash`
- [ ] **Dash** (short airy swish). Search: `dash whoosh`, `cloth swish`, `air swish short`
- [ ] **Dash not ready / out of charge** (a dull click). Search: `dull click`, `denied soft`
- [ ] **Enemy hit**, 3 variants (soft thud with a hiss). Search: `soft impact`, `shadow hit`
- [ ] **Wickling dies**, 2 variants (a fading puff or hiss). Search: `puff`, `fade hiss`, `poof soft`
- [ ] **Elite shell cracks** (glassy crack). Search: `ice crack`, `shell crack`, `glass crack small`
- [ ] **Elite shell breaks** (bigger crack or shatter). Search: `shatter soft`, `glass break small`
- [ ] **Elite growl** (low, not scary-loud). Search: `low growl creature`, `monster rumble`
- [ ] **Wickling whisper when it spots you** (eerie, quiet). Search: `whisper creature`, `eerie chitter`
- [ ] **Player takes a hit** (a soft thump, no grunt). Search: `body thud soft`, `cloth hit`
- [ ] **Warmth low warning, loop** (a slow heartbeat or low pulse). Search: `heartbeat slow`, `low pulse`
- [ ] **Faint** (a long soft fall and fade). Search: `faint fall`, `fading drone`
- [ ] **Wake up at a lantern** (a warm chime, 1 to 2 s). Search: `warm chime`, `soft bell`

## B. Lanterns and the world
- [ ] **Lantern burning low** (a gentle crackle or sputter). Search: `flame flicker`, `candle sputter`
- [ ] **Lantern goes cold** (a soft puff out). Search: `candle blow out`, `flame out`
- [ ] **WayLamp kindling, loop** (a growing fire and a hum). Search: `fire grow`, `bonfire start`
- [ ] **WayLamp lit** (a big warm swell, 2 to 4 s). Search: `fire whoosh ignite`, `warm swell`
- [ ] **Mirror Post turns** (a metal creak and a glass tick). Search: `metal creak small`, `glass tick`
- [ ] **Mirror beam connects** (a glassy shimmer). Search: `glass shimmer`, `crystal chime soft`
- [ ] **Gust warning** (a rising wind whoosh, about 5 s). Search: `wind rise`, `gust whoosh`
- [ ] **Landmark found** ("something catches the light": a soft chime). Search: `discover chime soft`, `soft bell single`
- [ ] **Region reached** (a low, calm drone note, 3 s). Search: `drone swell soft`, `pad swell`
- [ ] **Resource regrows** (a faint sparkle). Search: `sparkle soft`

## C. Pickups and UI (you have Kenney versions; upgrade only if you want a better feel)
- [ ] **Fuel pickup** (a small ember pop). Search: `ember pop`
- [ ] **Scrap pickup** (a small metal clink). Search: `metal clink small`
- [ ] **Level up** (when it exists: a bright, short rising chime). Search: `level up soft`, `chime rising`
- [ ] **Level-up card pick** (a soft click and glow). Search: `ui confirm soft`
- [ ] **Save** (a quiet, short tick or bell, 0.3 s). Search: `ui save soft`

## D. Ambience (loops, one file each)
- [ ] **Hollow, night base** (low wind through still trees, a few distant crickets). Search: `night forest wind loop`, `night ambience quiet`
- [ ] **Reedmarsh** (frogs, insects, reeds, water lapping). Search: `night marsh frogs`, `swamp night ambience`
- [ ] **Windward Ridge** (steady, strong wind with a high whistle). Search: `mountain wind loop`, `wind howl loop`
- [ ] **Lakeshore, planned** (still water, soft ripples, fog). Search: `lake shore night`, `water lapping calm`
- [ ] **Still Lake, planned** (near silence, a deep hum, distant water). Search: `deep drone hush`, `underwater ambience soft`
- [ ] **Wicklings nearby, loop** (a faint whispering). Search: `whispers eerie loop`, `ghostly wind voices`

## E. Footsteps (you have grass, marsh and wood from Kenney)
- [ ] **Stone steps**, 4 variants (for the Ridge and ruins). Search: `footstep stone`, `footstep gravel`
- [ ] **Shallow-water steps**, 4 variants (for the Lake edge). Search: `footstep water shallow`

## F. Music (your REAPER job, not Freesound)
- [ ] **Title / save slot screen** (calm, 1 to 2 min loop)
- [ ] **Hollow** (quiet, sparse)
- [ ] **Danger layer** (adds on top of exploration music when Wicklings are near)
- [ ] **Guardian fight** (one per WayLamp)
- [ ] **Soul of the Wick** (finale)
- [ ] **Ending**

## Already in the game (nothing to do)
Kenney CC0: footsteps (grass, marsh, wood), gather fuel and scrap, place and pick up lantern, refuel, relight, unlock, note open and close, UI open, close, tick and error. The ambience (base rumble, marsh hiss, wind rush) is generated by code, so sections A and D are what really need real recordings.

## Suggested order
1. **A:** beam, burst, dash, enemy hit, enemy dies, shell crack (this makes combat feel real)
2. **D:** Hollow night base, Reedmarsh, Ridge wind
3. **B:** lantern low, WayLamp kindling and lit
4. Everything else as you come across it
