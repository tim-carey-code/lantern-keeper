extends Node
## The Windward Ridge: glass, constant wind, the Hooded Lamp and the Mirror Post. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_ridge.tscn

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var wind: Wind
var post_exposed: Lantern
var post_sheltered: Lantern
var hooded: Lantern
var source: Lantern
var m1: Lantern
var m2: Lantern
var lone: Lantern
var far_tile := Vector2.ZERO

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _ready() -> void:
	strip_real_input()
	Tuning.wick_enabled = false
	Story.skip_opening = true
	SaveGame.path = "user://test_ignore_save.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _find(pred: Callable) -> Vector2i:
	for y in fog.rows:
		for x in fog.cols:
			if pred.call(Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _connected(a: Vector2i, b: Vector2i) -> bool:
	var seen := {a: true}
	var q: Array[Vector2i] = [a]
	while not q.is_empty():
		var t: Vector2i = q.pop_front()
		if t == b:
			return true
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = t + d
			if fog.in_bounds(n) and not seen.has(n) and fog.solid[fog.idx(n)] == 0:
				seen[n] = true
				q.append(n)
	return false

func _landmark(id: String) -> Landmark:
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == id:
			return m
	return null

func _lamp(kind: String, p: Vector2, dir: int = 0) -> Lantern:
	var l := Lantern.new()
	l.kind = kind
	l.mirror_dir = dir
	l.position = fog.tile_center(fog.tile_of(p))
	main.get_node("Lanterns").add_child(l)
	return l

func _ridge_tile(pred: Callable) -> Vector2i:
	return _find(func(t): return fog.region[fog.idx(t)] == FogGrid.R_RIDGE and fog.terrain_of(t) == FogGrid.T_GROUND and pred.call(t))

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			wind = main.get_node("Wind")
			wind.force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			Tuning.lantern_burn_per_sec = 0.5
			var ridge := _ridge_tile(func(t): return true)
			check(ridge.x >= 0, "the Windward Ridge exists")
			check(_connected(fog.tile_of(main.start), fog.tile_of(_landmark("station").global_position)), "walkable path from the hut up to the signal station")
			var glass := get_tree().get_nodes_in_group("resource").filter(func(r): return r.kind == "glass")
			check(glass.size() >= 10, "glass on the Ridge (%d)" % glass.size())
			check(glass.all(func(r): return fog.region_at(r.global_position) == FogGrid.R_RIDGE), "glass only on the Ridge")
			# Hooded Lamp and Mirror Post unlocks.
			check(not Progress.is_unlocked("hooded") and not Progress.is_unlocked("mirror"), "Hooded Lamp and Mirror Post start locked")
			_landmark("glazier").activate()
			main.get_node("NoteReader").close()
			_landmark("station").activate()
			main.get_node("NoteReader").close()
			check(Progress.is_unlocked("hooded") and Progress.is_unlocked("mirror"), "the glazier and the signal station unlock them")
			# Costs need glass.
			Inventory.counts["scrap"] = 30
			Inventory.counts["glass"] = 0
			# Ridge wind: an exposed Post Lamp burns faster than a sheltered one (rock to the west).
			var exposed_t := _ridge_tile(func(t): return not _rock_within(t, Vector2i.LEFT, 2) and absi(t.y - 17) <= 1)
			var shelter_t := _ridge_tile(func(t): return fog.terrain_of(t + Vector2i.LEFT) == FogGrid.T_ROCK)
			post_exposed = _lamp("post", fog.tile_center(exposed_t))
			post_sheltered = _lamp("post", fog.tile_center(shelter_t))
			hooded = _lamp("hooded", fog.tile_center(exposed_t + Vector2i(0, 4)))
		4:
			check(post_exposed.in_ridge_wind() and is_equal_approx(post_exposed.burn_rate(), Tuning.lantern_burn_per_sec * Tuning.ridge_burn_mult), "an exposed lantern on the Ridge burns faster, even between gusts")
			check(not post_sheltered.in_ridge_wind(), "rock to the west shelters a lantern from the Ridge wind")
			check(post_exposed.get_light_radius() < Tuning.lantern_max_radius, "the Ridge wind shrinks exposed light")
			wind.force(Wind.State.GUST, Vector2i.RIGHT)
			check(post_exposed.burn_rate() > Tuning.lantern_burn_per_sec * Tuning.ridge_burn_mult, "gusts stack on top of the Ridge wind")
			check(not hooded.in_gust() and not hooded.in_ridge_wind() and is_equal_approx(hooded.burn_rate(), Tuning.lantern_burn_per_sec), "the Hooded Lamp ignores all wind")
			wind.force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			# Mirrors, on open Hollow ground east of the hut: a burning source, a mirror in its
			# light pointing east, a second mirror down the first one's beam, and a lone mirror.
			var base: Vector2 = main.start + Vector2(0, 160)
			source = _lamp("post", base)
			m1 = _lamp("mirror", base + Vector2(96, 0), 0)          # in the source's light, pointing east
			m2 = _lamp("mirror", base + Vector2(96 + 256, 0), 2)    # in m1's beam, pointing south
			lone = _lamp("mirror", base + Vector2(-400, -40), 0)    # nowhere near any light
			far_tile = base + Vector2(96 + 256, 128)                # down m2's beam, outside any lantern
		30:
			check(m1.is_lit(), "a mirror in a lantern's light catches it")
			check(m2.is_lit(), "a mirror in another mirror's beam catches it (chains work)")
			check(not lone.is_lit(), "a mirror on its own stays dark")
			check(not lone.needs_fuel() and not get_tree().get_first_node_in_group("lantern_markers").needs_attention().has(lone), "mirrors never ask for fuel")
			var w: Wickling = main.get_node("FogLayer/Wicklings").spawn_at(m1.global_position + Vector2(140, 0))
			check(w.light_level_at(w.global_position) > Tuning.wick_core, "a mirror beam burns Wicklings")
			w.queue_free()
			# Turning a mirror.
			var before := m1.mirror_dir
			player.position = m1.global_position + Vector2(0, 20)
			player.begin_interact()
			check(m1.mirror_dir == (before + 1) % 8, "interacting turns a mirror")
			player.begin_interact()
			for i in 6:
				player.begin_interact()
			check(m1.mirror_dir == before, "eight turns bring it back around")
		120:
			check(fog.density_at(far_tile) < 0.4, "a beam clears fog far from any lantern (%.2f)" % fog.density_at(far_tile))
			# Glass cost (on lit ground, so "too dark" doesn't come first).
			Inventory.counts["glass"] = 0
			Progress.selected = "mirror"
			player.position = source.global_position + Vector2(0, 64)
			check(player.place_block_reason(player.place_pos()).contains("glass"), "a Mirror Post costs glass (%s)" % player.place_block_reason(player.place_pos()))
			Inventory.counts["glass"] = 5
			check(player.try_place() != null and Inventory.get_count("glass") == 5 - Tuning.mirror_cost_glass, "building a Mirror Post spends glass")
			Progress.selected = "post"
		130:
			# Save and load keep mirror direction.
			SaveGame.path = "user://test_ridge_save.json"
			m2.mirror_dir = 5
			check(SaveGame.save(main), "save with mirrors")
			var f := FileAccess.open(SaveGame.path, FileAccess.READ)
			var data = JSON.parse_string(f.get_as_text())
			f.close()
			var saved := (data["lanterns"] as Array).filter(func(l): return l["kind"] == "mirror" and int(l["dir"]) == 5)
			check(saved.size() == 1, "mirror direction is saved")
			SaveGame.delete_save()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)

func _rock_within(t: Vector2i, dir: Vector2i, n: int) -> bool:
	for k in range(1, n + 1):
		if fog.terrain_of(t + dir * k) == FogGrid.T_ROCK:
			return true
	return false
