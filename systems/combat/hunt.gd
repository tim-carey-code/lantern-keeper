class_name Hunt
extends RefCounted
## "Hunted" (GAME_PLAN glossary): an awake foe has the keeper as its target within 12 tiles
## (Tuning.travel_hunt_radius, 384 px). One rule for all of these:
##   - WayLamp fast travel is refused (the loop's check, scripts/ui/travel_menu.gd);
##   - Rest at a lit WayLamp is refused;
##   - light gives warmth only when not hunted, and charge only slowly (GAME_PLAN §5);
##   - the Skills list is greyed.
## Counts: an awake Clinker, any Spitwick, the Ashbrood, a Wickling chasing the keeper, and a Wickling that was
## chasing and now waits at the edge of the light the keeper stepped into (so you clear the area before you rest).
## Doesn't count: nests, a Wickling that only wanders or flees, anything past the radius.

## The first foe hunting the keeper at `at`, or null.
static func hunter(tree: SceneTree, at: Vector2) -> Node:
	if tree == null:
		return null
	for f in tree.get_nodes_in_group("foe"):
		if f.is_queued_for_deletion() or f._dead or f is WickNest:
			continue
		if f.global_position.distance_to(at) > Tuning.travel_hunt_radius:
			continue
		if f is Ashbrood or (f is Clinker and f.awake) or f is Spitwick:
			return f
		if f is Wickling and (f.state == Wickling.State.CHASE or f.waiting_for_keeper):
			return f
	return null

static func is_hunted(tree: SceneTree, at: Vector2) -> bool:
	return hunter(tree, at) != null
