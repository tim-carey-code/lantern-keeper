# Decisions log

Owner decisions that override or settle the design docs. Newest first.

## 2026-11-26 (after M3 playtest)
- Cold lanterns stay findable, as DESIGN 3.1/4 intended ("keeps its frame"): their frame and a pulse are drawn above fog and darkness. Lanterns below 25% fuel get an amber pulse. Off-screen cold/low lanterns get an arrow at the screen edge. The HUD counts them and the map colours them (red cold, yellow low).

## 2026-11-26 (M3 build choices, coordinator)
- Wind gusts are valley-wide from M3 (not only the Windward Ridge), as the one weather effect. Shelter = rock 1-2 tiles upwind. The Ridge will get stronger, more frequent gusts later.
- The Reservoir Lamp also refuels cold lanterns in its light (relights them), not only lit ones.
- Ambience is synthesized live as a placeholder; real CC0/REAPER sounds arrive in M4.
- Five landmarks in M3: ledger, carved stone, eastward frames, chalk lake drawings, pumphouse.

## 2026-11-26 (answers to DESIGN §10)
1. **Sandbox after the finale: yes.** After the great lamp is relit the valley stays open; the player can keep building, tending and finishing the map.
2. **Hand lamp uses fuel: yes.** It burns fuel and dims as it runs low, but it never fully goes out: when empty it keeps a small ember glow (enough to walk home safely, too dim to reveal resources). This keeps the "no game over" rule.
3. **Mystery: answered in part, left open in part.** v1 resolves the immediate arc (why the great lamp went cold, and relighting it). The deeper "why" of the valley stays hinted, leaving room for future regions/updates. Every hint should still feel satisfying on its own.
4. **Gamepad support: in v1.** Moved from OUT to IN. All actions must work on keyboard/mouse and gamepad; UI must be navigable without a mouse.
5. **Project location:** `~/Projects/lantern-keeper`, its own git repo.

## Coordinator notes
- Wind moves from M5 to M3 so it is tested earlier.
- Renderer: Compatibility (OpenGL) for broad PC support; revisit only if a needed effect requires Forward+.
