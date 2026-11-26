# Decisions log

Owner decisions that override or settle the design docs. Newest first.

## 2026-11-26 (answers to DESIGN §10)
1. **Sandbox after the finale: yes.** After the great lamp is relit the valley stays open; the player can keep building, tending and finishing the map.
2. **Hand lamp uses fuel: yes.** It burns fuel and dims as it runs low, but it never fully goes out: when empty it keeps a small ember glow (enough to walk home safely, too dim to reveal resources). This keeps the "no game over" rule.
3. **Mystery: answered in part, left open in part.** v1 resolves the immediate arc (why the great lamp went cold, and relighting it). The deeper "why" of the valley stays hinted, leaving room for future regions/updates. Every hint should still feel satisfying on its own.
4. **Gamepad support: in v1.** Moved from OUT to IN. All actions must work on keyboard/mouse and gamepad; UI must be navigable without a mouse.
5. **Project location:** `~/Projects/lantern-keeper`, its own git repo.

## Coordinator notes
- Wind moves from M5 to M3 so it is tested earlier.
- Renderer: Compatibility (OpenGL) for broad PC support; revisit only if a needed effect requires Forward+.
