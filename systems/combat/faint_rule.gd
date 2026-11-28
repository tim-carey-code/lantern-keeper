class_name FaintRule
extends RefCounted
## The faint rule (M1b, GAME_PLAN §12; replaces the old "a faint re-arms every pack and drops half your fuel and
## scrap"). The keeper's part (nothing carried is lost; unspent wick waits where you fell) is in player.gd faint().
##   - Cleared packs and nests stay cleared (Progress.cleared is never touched).
##   - A half-fought pack is whole and asleep again: its living members go, its dead stay dead
##     (EnemyPack.sleep_again). A half-burned nest is whole again and stops hatching until you come back.
##   - A mid-boss (the Clinker) or guardian (the Ashbrood) goes back to the start of the phase it reached, shell
##     regrown, its phase oil armed again.
##   - Summoned foes (hatchlings, the Ashbrood's adds) go. Other Wicklings lose you for a moment (they flee).
##   - You wake at the nearest lit light in the region you fell in (a lit lantern or a lit WayLamp). Any light
##     within kl_faint_skip_radius of an unbeaten fight (a pack, a nest, the Clinker, the Ashbrood) is skipped, so
##     faints don't chain. No light left: any region's; none at all: the hut.

static func reset_fights(tree: SceneTree) -> void:
	for p in tree.get_nodes_in_group("enemy_pack"):
		p.sleep_again()
	for f in tree.get_nodes_in_group("foe"):
		if f.is_queued_for_deletion() or f._dead:
			continue
		if f.summoned:
			FaintRule.vanish(f)
		elif f is Ashbrood:
			f.restart_phase()
		elif f is Clinker:
			f.reset_for_faint()
		elif f is WickNest:
			f.reset_for_faint()
		elif f is Wickling:
			f.state = Wickling.State.FLEE
			f._flee_t = 3.0
	for h in tree.get_nodes_in_group("burst_hatch"):
		h.queue_free()   # a Bursting elite's hatch that hasn't risen yet (M2)
	for e in tree.get_nodes_in_group("cold_ember"):
		e.queue_free()   # the Ashbrood's cold embers (M2)
	LightSense.bump()

## Takes a foe out at once, with no drops and no wick (a faint undoes the fight, it doesn't win it).
static func vanish(f: Node) -> void:
	for g in ["foe", "wickling"]:
		if f.is_in_group(g):
			f.remove_from_group(g)
	f.queue_free()

## Where unbeaten fights are: [position, ...] (packs and nests not cleared, the Clinker and the Ashbrood alive).
static func unbeaten_spots(tree: SceneTree) -> Array:
	var out := []
	for p in tree.get_nodes_in_group("enemy_pack"):
		if not Progress.cleared.has("pack_" + p.id):
			out.append(p.global_position)
	for f in tree.get_nodes_in_group("foe"):
		if f.is_queued_for_deletion() or f._dead:
			continue
		if f is WickNest and not Progress.cleared.has(f.foe_id):
			out.append(f.global_position)
		elif f is Clinker:
			out.append(f.home if f.home != Vector2.ZERO else f.global_position)
		elif f is Ashbrood:
			out.append(f.global_position)
	return out

## The lit lights a keeper may wake by: [[position to stand, region], ...].
static func lights(tree: SceneTree, fog: FogGrid) -> Array:
	var out := []
	for l in tree.get_nodes_in_group("lantern"):
		if l.kind != "mirror" and l.is_lit():
			out.append([l.global_position + Vector2(0, 24), fog.region_at(l.global_position) if fog else 0])
	for w in tree.get_nodes_in_group("waylamp"):
		if w.is_lit():
			out.append([w.global_position + Vector2(0, 40), fog.region_at(w.global_position) if fog else 0])
	return out

## The spot the keeper wakes at after falling at `fell` (see the header). `home` is the hut.
static func wake_spot(tree: SceneTree, fell: Vector2, home: Vector2) -> Vector2:
	var fog := tree.get_first_node_in_group("fog_grid") as FogGrid
	var region := fog.region_at(fell) if fog else 0
	var danger := unbeaten_spots(tree)
	var safe := lights(tree, fog).filter(func(c): return not danger.any(func(d): return (d as Vector2).distance_to(c[0]) < Tuning.kl_faint_skip_radius))
	for same_region in [true, false]:
		var best := Vector2.INF
		for c in safe:
			if same_region and int(c[1]) != region:
				continue
			if best == Vector2.INF or fell.distance_to(c[0]) < fell.distance_to(best):
				best = c[0]
		if best != Vector2.INF:
			return best
	return home
