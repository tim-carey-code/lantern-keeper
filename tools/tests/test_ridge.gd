extends Node
## The Windward Ridge: its layout, the Hooded Lamp and the Mirror Post unlocks, mirrors and their beams.
## M1b: its tending, ward and wind-burn checks are gone (lamps never burn; the ward is cut; wind is inert until M6,
## when the wind checks come back). Glass is cut: no glass on the Ridge, and lamp costs are scrap. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_ridge.tscn

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var wind: Wind
var source: Lantern
var m1: Lantern
var m2: Lantern
var lone: Lantern
var far_tile := Vector2.ZERO
var beam_victim: Wickling
var smotherer: Wickling

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
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when a note or menu pauses the world
	strip_real_input()
	Tuning.wick_enabled = false
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
	SaveGame.path = "user://test_ignore_save.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	Progress.unlock("post")

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
			var ridge := _ridge_tile(func(t): return true)
			check(ridge.x >= 0, "the Windward Ridge exists")
			check(_connected(fog.tile_of(main.start), fog.tile_of(_landmark("station").global_position)), "walkable path from the hut up to the signal station")
			var ridge_piles := get_tree().get_nodes_in_group("resource").filter(func(r): return fog.region_at(r.global_position) == FogGrid.R_RIDGE)
			check(ridge_piles.size() >= 10 and ridge_piles.all(func(r): return r.kind == "scrap"), "scrap piles on the Ridge, and no glass (%d)" % ridge_piles.size())
			# Hooded Lamp and Mirror Post unlocks.
			check(not Progress.is_unlocked("hooded") and not Progress.is_unlocked("mirror"), "Hooded Lamp and Mirror Post start locked")
			_landmark("glazier").activate()
			main.get_node("NoteReader").close()
			_landmark("station").activate()
			main.get_node("NoteReader").close()
			check(Progress.is_unlocked("hooded") and Progress.is_unlocked("mirror"), "the glazier and the signal station unlock them")
			Inventory.counts["scrap"] = 30
		4:
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
			check(not get_tree().get_first_node_in_group("lantern_markers").unlit_old_lamps().has(lone), "a dark mirror has no cold-lamp lure")
			var w: Wickling = main.get_node("FogLayer/Wicklings").spawn_at(m1.global_position + Vector2(140, 0))
			check(w.beam_level_at(w.global_position) > 0.0, "a Wickling in a mirror beam is caught by it")
			beam_victim = w
			# A Wickling clinging to a mirror smothers it (and the chain after it goes dark).
			smotherer = main.get_node("FogLayer/Wicklings").spawn_at(m2.global_position)
			smotherer.target = m2
			smotherer.state = Wickling.State.SEEK_LANTERN
			# Turning a mirror.
			var before := m1.mirror_dir
			player.position = m1.global_position + Vector2(0, 20)
			player.begin_interact()
			check(m1.mirror_dir == (before + 1) % 8, "interacting turns a mirror")
			player.begin_interact()
			for i in 6:
				player.begin_interact()
			check(m1.mirror_dir == before, "eight turns bring it back around")
			m1.turn(-1)
			check(m1.mirror_dir == posmod(before - 1, 8), "a mirror also turns left")
			m1.turn(1)
		100:
			check(not is_instance_valid(beam_victim), "a mirror beam burns a Wickling away in about a second")
			if is_instance_valid(smotherer):
				check(m2.is_smothered() and not m2.is_lit(), "a Wickling clinging to a mirror smothers it: it goes dark")
				smotherer.queue_free()
			else:
				check(false, "a Wickling clinging to a mirror drinks the beam instead of burning")
		200:
			check(fog.density_at(far_tile) < 0.4, "a beam clears fog far from any lantern (%.2f)" % fog.density_at(far_tile))
			# Costs are scrap only (M1b: glass is cut; GAME_PLAN §6).
			Inventory.counts["scrap"] = Tuning.mirror_cost_scrap - 1
			Progress.selected = "mirror"
			player.position = source.global_position + Vector2(0, 64)
			check(player.place_block_reason(player.place_pos()) == "needs %d scrap" % Tuning.mirror_cost_scrap, "a Mirror Post costs %d scrap (%s)" % [Tuning.mirror_cost_scrap, player.place_block_reason(player.place_pos())])
			Inventory.counts["scrap"] = Tuning.mirror_cost_scrap
			check(player.try_place() != null and Inventory.get_count("scrap") == 0, "building a Mirror Post spends scrap only")
			Progress.selected = "hooded"
			check(Lantern.cost_text("hooded") == "%d scrap" % Tuning.hooded_cost_scrap, "a Hooded Lamp costs %d scrap" % Tuning.hooded_cost_scrap)
			Progress.selected = "post"
		210:
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
