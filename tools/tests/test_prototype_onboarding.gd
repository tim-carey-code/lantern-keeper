extends Node
## The first 10 minutes (docs/PLAN_ONBOARDING.md, owner answers 2026-11-27, Option B). Checks the main route as
## placed (after _spot_in_region snaps each spot): hut, the north path's cold lamp, Oswin's crook with its small
## guard and 6-scrap cache, nest A, the Clinker as a mid-boss, the WayLamp. "On the route" means within that
## foe's wake radius of the route's straight legs. Prints the layout as tile offsets from the hut.
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_onboarding.tscn

const T := FogGrid.TILE

var main: Node
var frame := 0
var fails := 0
var start := Vector2.ZERO
var test_clinker: Clinker

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		fails += 1

func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	strip_real_input()
	Story.skip_opening = true
	# M1c: this test predates the light states and lamp slots (test_light_states, test_combos and test_core's slot
	# checks cover those). The light rule and the slot limit are off here, so its sums stay as they were.
	Tuning.kl_dark_dmg_mult = 1.0
	Tuning.kl_lit_dmg_mult = 1.0
	Tuning.kl_lit_shell_mult = 1.0
	Tuning.kl_dark_shell_floor = 0.0
	Tuning.kl_ashbrood_needs_light = false
	Tuning.kl_lamp_slots_base = 6
	Tuning.kl_lamp_replant_cd = 0.0
	Tuning.wick_enabled = false
	SaveGame.path = "user://test_onboarding.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func off(p: Vector2) -> String:
	var t: Vector2i = main.fog.tile_of(p) - main.fog.tile_of(start)
	return "(%+d,%+d)" % [t.x, t.y]

func tiles(d: float) -> float:
	return d / T

func _dist_to_path(p: Vector2, path: Array) -> float:
	var best := INF
	for i in path.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1])))
	return best

## Every hostile that can wake: [node, label, wake radius px].
func hostiles() -> Array:
	var out := []
	for p in get_tree().get_nodes_in_group("enemy_pack"):
		out.append([p, ("guard" if p.guard else "pack %s" % p.id), p.wake_px()])
	for f in get_tree().get_nodes_in_group("foe"):
		if f is WickNest:
			out.append([f, f.foe_id, Tuning.kl_nest_wake_radius])
		elif f is Clinker:
			out.append([f, "Clinker", Tuning.kl_clinker_wake_radius])
	return out

func _landmark(id: String) -> Node2D:
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == id:
			return m
	return null

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			_layout()
			_tips_setup()
		3:
			_goals()
		100:
			check(Story.tips_seen.has("dash"), "the Clinker's first roll tell shows the dash tip")
			test_clinker.queue_free()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)

func _layout() -> void:
	start = main.start
	var crook := _landmark("crook_post")
	var waypost: Vector2 = main.waypost_lantern_pos
	var wl: Vector2 = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0].global_position
	var clinker: Clinker = get_tree().get_nodes_in_group("foe").filter(func(f): return f is Clinker)[0]
	var nest_a: WickNest = get_tree().get_nodes_in_group("foe").filter(func(f): return f is WickNest and f.foe_id == "nest_hollow_4")[0]
	var guard: EnemyPack = get_tree().get_nodes_in_group("enemy_pack").filter(func(p): return p.guard)[0]
	var all := hostiles()
	var first_leg := [start, waypost, crook.global_position]
	var second_leg := [crook.global_position, nest_a.global_position, clinker.global_position, wl]
	var route := first_leg + second_leg.slice(1)
	print("--- Main route, tile offsets from the hut (+x east, -y north), straight-line distance in tiles:")
	for row in [["the north path's cold lamp", waypost], ["Oswin's crook (the Post Lamp)", crook.global_position], ["the crook's guard", guard.global_position],
			["nest A", nest_a.global_position], ["the Clinker", clinker.global_position], ["the WayLamp", wl]]:
		print("    %-30s %s  %.1f" % [row[0], off(row[1]), tiles(start.distance_to(row[1]))])
	var on_first := []
	var on_second := []
	for h in all:
		var n: Node2D = h[0]
		if _dist_to_path(n.global_position, first_leg) <= h[2]:
			on_first.append(h)
		if _dist_to_path(n.global_position, second_leg) <= h[2]:
			on_second.append(h)
	for h in on_first + on_second.filter(func(x): return not on_first.has(x)):
		var n: Node2D = h[0]
		var what: String = "%d foes (%d Spitwick, %d elite) Lv %d, wakes at %.0f tiles" % [n.count, n.spitwicks, n.elites, n.level, tiles(h[2])] if n is EnemyPack else "Lv %d, wakes at %.0f tiles" % [n.level, tiles(h[2])]
		print("    on the route: %-22s %s  %.1f  %s" % [h[1], off(n.global_position), tiles(start.distance_to(n.global_position)), what])

	# The route is walkable ground the whole way (straight legs; the Hollow has no rock inside).
	var walk_ok := true
	for i in route.size() - 1:
		var a: Vector2 = route[i]
		var b: Vector2 = route[i + 1]
		var steps := int(a.distance_to(b) / 8.0)
		for s in steps + 1:
			var t: Vector2i = main.fog.tile_of(a.lerp(b, float(s) / maxf(steps, 1)))
			if main.fog.terrain_of(t) != FogGrid.T_GROUND:
				walk_ok = false
	check(walk_ok, "the main route is open ground all the way from the hut to the WayLamp")

	# 1. A calm hut: nothing wakes while you gather, relight and read (owner 2026-11-27).
	var woodpile: Vector2 = main.get_node("Terrain/Woodpile").global_position   # scenery since M1b
	var calm := {"the hut": start, "the hut lantern": main.start_lantern_pos, "the woodpile": woodpile, "the ledger": _landmark("ledger").global_position,
		"the hut's scrap": main.fog.tile_center(main.fog.tile_of(start + Vector2(64, -32)))}
	var wakes := []
	for spot in calm:
		for h in all:
			if (h[0] as Node2D).global_position.distance_to(calm[spot]) <= h[2] + T:
				wakes.append("%s at %s" % [h[1], spot])
	check(wakes.is_empty(), "nothing wakes at the hut, its lantern, the woodpile, the scrap or the ledger, even a tile off (%s)" % str(wakes))

	# 2. The first route to the find.
	var first_packs := on_first.filter(func(h): return h[0] is EnemyPack and not h[0].guard)
	var foes := 0
	var spit := 0
	var elite := 0
	for h in first_packs:
		foes += h[0].count
		spit += h[0].spitwicks
		elite += h[0].elites
	check(first_packs.size() <= 2 and foes <= 4 and spit == 0 and elite == 0, "hut to crook: at most 2 packs, 4 Wicklings, no Spitwick or elite (%d packs, %d foes, %d Spitwicks, %d elites)" % [first_packs.size(), foes, spit, elite])
	check(on_first.filter(func(h): return h[0] is WickNest or h[0] is Clinker).is_empty(), "hut to crook: no nest and no Clinker")
	check(on_first.any(func(h): return h[0] == guard), "the crook's guard is on the way")
	var lone: Array = first_packs.filter(func(h): return h[0].count == 1)
	var nearest: Variant = null
	for h in all:
		if nearest == null or start.distance_to(h[0].global_position) < start.distance_to(nearest[0].global_position):
			nearest = h
	check(lone.size() == 1 and nearest == lone[0] and lone[0][0].level == 1, "the first thing on the road is one lone Lv 1 Wickling (%s)" % (nearest[1] if nearest else "none"))
	var within16 := all.filter(func(h): return start.distance_to(h[0].global_position) < 16.0 * T)
	check(within16.size() == 1 and within16[0] == lone[0], "only the lone Wickling sits within 16 tiles of the hut (owner: it may come closer)")

	# 3. After the find.
	var second_packs := on_second.filter(func(h): return h[0] is EnemyPack and not h[0].guard)
	var second_nests := on_second.filter(func(h): return h[0] is WickNest)
	check(second_packs.size() <= 2 and second_nests.size() == 1 and second_nests[0][0] == nest_a, "crook to WayLamp: at most 2 packs and exactly one nest, nest A (%d packs, %d nests)" % [second_packs.size(), second_nests.size()])
	var route_packs := {}
	for h in first_packs + second_packs:
		route_packs[h[0]] = true
	var table_packs := get_tree().get_nodes_in_group("enemy_pack").filter(func(p): return not p.guard)
	var nests := get_tree().get_nodes_in_group("foe").filter(func(f): return f is WickNest)
	check(route_packs.size() <= 3 and table_packs.size() == 24 and nests.size() == 12, "the whole route wakes at most 3 of the 24 packs and 1 of the 12 nests; the rest is optional (%d)" % route_packs.size())

	# 4. Safe surroundings.
	var near_nest := nests.filter(func(n): return start.distance_to(n.global_position) < 28.0 * T)
	check(near_nest.is_empty(), "no nest within 28 tiles of the hut (nest A is %.1f)" % tiles(start.distance_to(nest_a.global_position)))
	var tough := table_packs.filter(func(p): return (p.spitwicks > 0 or p.elites > 0) and start.distance_to(p.global_position) < 25.0 * T)
	check(tough.is_empty(), "no Spitwick or elite pack within 25 tiles of the hut; the crook's guard is the first elite (%s)" % str(tough.map(func(p): return p.id)))

	# 5. Clear fight spots.
	var warmups := first_packs.map(func(h): return h[0])
	var at_haven := all.filter(func(h): return not warmups.has(h[0]) and h[0].global_position.distance_to(waypost) <= h[2])
	check(at_haven.is_empty(), "only the two warm-up fights can wake by the north path's lamp (%s)" % str(at_haven.map(func(h): return h[1])))
	var at_crook := all.filter(func(h): return not warmups.has(h[0]) and h[0] != guard and h[0].global_position.distance_to(crook.global_position) <= h[2])
	check(at_crook.is_empty(), "nothing but the guard and the warm-ups wakes at the crook (%s)" % str(at_crook.map(func(h): return h[1])))
	check(guard.global_position.distance_to(waypost) > guard.wake_px() + T, "the guard sleeps while you relight the north path's lamp (%.1f tiles)" % tiles(guard.global_position.distance_to(waypost)))
	var at_nest := all.filter(func(h): return h[0] != nest_a and h[0].global_position.distance_to(nest_a.global_position) <= h[2] + T)
	check(at_nest.is_empty(), "nothing else wakes while you burn out nest A (%s)" % str(at_nest.map(func(h): return h[1])))
	check(nest_a.global_position.distance_to(crook.global_position) >= Tuning.kl_nest_wake_radius + T, "nest A doesn't hatch during the guard fight (%.1f tiles past the crook)" % tiles(nest_a.global_position.distance_to(crook.global_position)))

	# 6. The north path's cold lamp (a haven).
	var lamp: Array = get_tree().get_nodes_in_group("lantern").filter(func(l): return l.global_position.distance_to(waypost) < 8.0)
	var d_lamp := tiles(start.distance_to(waypost))
	check(lamp.size() == 1 and not lamp[0].is_lit() and d_lamp >= 10.0 and d_lamp <= 14.0, "a second cold old lantern waits on the north path, %.1f tiles out" % d_lamp)
	check(waypost.y < start.y and crook.global_position.y < waypost.y, "it lies on the way north, before the crook")

	# 7. The find: Option B, ~18 tiles north, a small guard, a 6-scrap cache.
	var d_crook := tiles(start.distance_to(crook.global_position))
	check(d_crook >= 16.0 and d_crook <= 21.0 and crook.global_position.y < start.y, "Oswin's crook lies about 18 tiles north of the hut (%.1f)" % d_crook)
	check(guard.count == 1 and guard.elites == 1 and guard.spitwicks == 0 and guard.global_position.distance_to(crook.global_position) <= T, "its guard is small: one shelled Wickling on the crook, not the Clinker")
	check(guard.level == Tuning.kl_post_guard_level and not guard.awake, "the guard is Lv %d and sleeps until you come within %.0f tiles" % [guard.level, tiles(guard.wake_px())])
	var cache := get_tree().get_nodes_in_group("resource").filter(func(r): return r.label == "Old cache" and r.kind == "scrap" and r.global_position.distance_to(crook.global_position) <= 3.0 * T)
	check(cache.size() == 1 and cache[0].amount == 6 and cache[0].amount >= Tuning.post_lamp_cost_scrap, "a 6-scrap cache at the crook pays for a Post Lamp right away (%s)" % str(cache.map(func(r): return r.amount)))

	# 8. The Clinker: a mid-boss near the WayLamp, before the Ashbrood, with its sleep and leash.
	var d_cw := clinker.global_position.distance_to(wl)
	check(d_cw < 10.0 * T and d_cw > Tuning.kl_clinker_wake_radius + T, "the Clinker sits near the WayLamp (%.1f tiles), but out of the Ashbrood fight's reach" % tiles(d_cw))
	check(clinker.global_position.distance_to(crook.global_position) > 15.0 * T and not clinker.awake, "it no longer sits on the crook, and sleeps until you come close")
	# The loop (2026-11-27): after nest A the road turns east to the WayLamp, so "after nest A" is measured from the
	# crook, not the hut (the Clinker is now nearer the hut than nest A is, but farther along the road).
	check(clinker.global_position.distance_to(nest_a.global_position) > Tuning.kl_clinker_wake_radius + T and crook.global_position.distance_to(clinker.global_position) > crook.global_position.distance_to(nest_a.global_position), "it comes after nest A on the road (%.1f vs %.1f tiles from the crook)" % [tiles(crook.global_position.distance_to(clinker.global_position)), tiles(crook.global_position.distance_to(nest_a.global_position))])

	# 9. Level 2 at the find: the wick from the fights before it (Progress.kill_wick, level gap and all).
	var lv := 1
	var wick := 0.0
	for h in on_first:
		var p: EnemyPack = h[0]
		for i in p.count:
			var base := Tuning.kl_spitwick_wick if i < p.spitwicks else (Tuning.kl_elite_wick if i >= p.count - p.elites else Tuning.kl_wickling_wick)
			wick += Progress.kill_wick(base, p.level, lv)
			if wick >= Progress.wick_for_level(lv):
				wick -= Progress.wick_for_level(lv)
				lv += 1
	check(lv == 2, "the road to the crook and its guard give level 2 at the find (L%d)" % lv)

	# 10. Levels rise toward the WayLamp along the route.
	var lv_route := [nearest[0].level, guard.level, nest_a.level, Tuning.kl_clinker_level, Tuning.kl_ashbrood_level]
	var rising := true
	for i in lv_route.size() - 1:
		rising = rising and lv_route[i] <= lv_route[i + 1]
	check(rising, "foe levels rise along the route (%s)" % str(lv_route))

func _goals() -> void:
	var ids := []
	for g in Story.GOALS.slice(0, 6):
		ids.append(g["id"])
	check(ids == ["relight_first", "read_ledger", "relight_waypost", "build_post", "burn_nest", "kindle_hollow"], "the Hollow's goals in order, starting with the hut lamp lit by touch (%s)" % str(ids))
	var ptr = get_tree().get_first_node_in_group("goal_pointer")
	var missing := []
	for id in ids:
		Story.current = id
		if ptr.target_pos() == null:
			missing.append(id)
	Story.current = ""
	check(missing.is_empty(), "every one of them has a pointer target (%s)" % str(missing))
	var tips_ok := true
	for k in ["haven", "burst", "shell", "dash", "nest", "build_here"]:
		tips_ok = tips_ok and Story.TIPS.has(k)
	check(tips_ok, "the new tips are in: haven, burst, shell, dash, nest, build_here")
	# The shell tip: the first beam on a shell (the guard).
	var w := Wickling.new()
	w.elite = true
	w.position = main.player.global_position + Vector2(0, 400)
	main.get_node("FogLayer/Wicklings").add_child(w)
	w.tick_foe(0.01)
	w.hurt(0.5, false, "beam")
	check(Story.tips_seen.has("shell"), "beaming a shell shows the shell tip")
	w.queue_free()
	# The burst tip: two Wicklings close. M1a: the old burst is Hearth ring, an optional skill that isn't on the
	# default bar, so the tip waits until it is on a slot (it would name an empty button otherwise).
	var pair := []
	for i in 2:
		var x := Wickling.new()
		x.position = main.player.global_position + Vector2(40 + i * 20, 0)
		main.get_node("FogLayer/Wicklings").add_child(x)
		pair.append(x)
	Story.update(main)
	check(not Story.tips_seen.has("burst"), "with Hearth ring off the bar, two Wicklings close don't show the burst tip yet")
	Progress.bind("skill_4", "hearth_ring")
	Story.update(main)
	check(Story.tips_seen.has("burst") and Story.tip_text("burst").contains(InputHint.key("skill_4")), "with it on slot 4, two Wicklings close show the burst tip, naming its button")
	Progress.bar = Progress.default_bar()
	for x in pair:
		x.queue_free()
	# The nest tips: in reach of a nest; with the Post Lamp and its scrap, the build tip too.
	var nest_a: Node2D = get_tree().get_nodes_in_group("foe").filter(func(f): return f is WickNest and f.foe_id == "nest_hollow_4")[0]
	var home: Vector2 = main.player.global_position
	main.player.global_position = nest_a.global_position + Vector2(0, 200)
	Story.update(main)
	check(Story.tips_seen.has("nest") and not Story.tips_seen.has("build_here"), "seeing a nest shows the nest tip; the build tip waits for the Post Lamp")
	Progress.unlocks["post"] = true
	Inventory.counts["scrap"] = Tuning.post_lamp_cost_scrap
	Story.update(main)
	check(Story.tips_seen.has("build_here"), "with the Post Lamp and %d scrap by a nest: plant one beside it" % Tuning.post_lamp_cost_scrap)
	main.player.global_position = home

## The dash tip comes from a real Clinker's roll tell (checked at frame 100).
func _tips_setup() -> void:
	test_clinker = Clinker.new()
	test_clinker.position = main.player.global_position + Vector2(160, 0)
	main.get_node("FogLayer/Wicklings").add_child(test_clinker)
