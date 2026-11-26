extends Node
## Headless checks for the core loop (M1 + M2) and the Reedmarsh (M3). Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_core.tscn
## Exit code 0 = all passed. Runs as a scene so the autoloads are available.

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var lamp: Lantern
var woodpile: ResourceNode
var scrap_pile: ResourceNode
var built: Lantern
var start := Vector2.ZERO
var lamp_density_cold := 0.0
var wind: Wind
var reservoir: Lantern
var fed: Lantern

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

## Tests must not react to a real controller plugged into this PC (the owner may be playing).
func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _ready() -> void:
	strip_real_input()
	SaveGame.path = "user://test_ignore_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			start = main.start
			lamp = main.get_node("Lanterns").get_child(0)
			wind = main.get_node("Wind")
			wind.force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)   # no random gusts during tests
			for r in get_tree().get_nodes_in_group("resource"):
				if r.always_regrow:
					woodpile = r
				elif r.kind == "scrap" and r.global_position.distance_to(start) < 100.0:
					scrap_pile = r
			check(lamp != null and lamp.is_lit(), "starting lantern exists and is lit")
			check(woodpile != null and scrap_pile != null, "hut woodpile and starter scrap exist")
			var res := get_tree().get_nodes_in_group("resource")
			check(res.size() >= 40, "resources scattered in the Hollow (%d)" % res.size())
			check(res.all(func(r): return not r.is_revealed()), "all resources start hidden in fog")
			check(Inventory.get_count("fuel") == 0 and Inventory.get_count("scrap") == 0, "keeper starts with nothing")
			check(fog.is_solid_at(Vector2(8, 8)) and not fog.is_solid_at(start), "rock rings the Hollow, start is open")
			check(player.place_block_reason(Vector2(16, 16)) == "rock", "cannot build on rock")
		120:
			check(fog.density_at(lamp.global_position) < 0.1, "light clears fog at the lantern")
			check(fog.density_at(lamp.global_position + Vector2(400, 0)) > 0.9, "fog stays outside the radius")
			check(woodpile.is_revealed() and scrap_pile.is_revealed(), "light reveals nearby resources")
			check(lamp.fuel < Tuning.lantern_max_fuel, "lantern burns fuel")
			check(player.place_block_reason(start + Vector2(0, 96)).begins_with("needs"), "cannot build without scrap")
			player.position = scrap_pile.global_position + Vector2(12, 0)
			Input.action_press("interact")
		240:
			Input.action_release("interact")
			check(Inventory.get_count("scrap") == 6 and scrap_pile.amount == 0, "holding interact gathers scrap (%d)" % Inventory.get_count("scrap"))
			player.position = start + Vector2(0, 96)
		242:
			built = player.try_place()
			check(built != null, "can build a Post Lamp on lit ground")
			check(Inventory.get_count("scrap") == 1, "building costs %d scrap" % Tuning.post_lamp_cost_scrap)
			check(player.place_block_reason(player.place_pos()) != "", "cannot build twice in one spot")
			player.position = built.global_position
		244:
			player.pick_up_nearest()
		248:
			check(get_tree().get_nodes_in_group("lantern").size() == 1, "pick up removes the lantern")
			check(Inventory.get_count("scrap") == 3, "pick up refunds half the scrap")
			check(Inventory.get_count("fuel") >= 9, "pick up returns the tank's fuel (%d)" % Inventory.get_count("fuel"))
			# Hand lamp: walk deep into the dark with no fuel.
			Inventory.counts["fuel"] = 0
			Tuning.hand_lamp_drain_per_sec = 1.0
			player.position = start + Vector2(-420, 0)
		320:
			check(player.lamp_charge == 0.0, "hand lamp dims in the dark")
			check(is_equal_approx(player.get_light_radius(), Tuning.hand_lamp_ember_radius) and player.get_light_radius() > 0.0, "hand lamp never goes out (ember)")
			Inventory.add("fuel", 5)
		330:
			check(Inventory.get_count("fuel") < 5 and player.lamp_charge > 0.0, "hand lamp burns carried fuel when low")
			Tuning.hand_lamp_drain_per_sec = 1.0 / 45.0
			# Soft-lock scenario: every lantern cold, nothing carried, woodpile empty.
			lamp.fuel = 0.0
			Inventory.counts["fuel"] = 0
			woodpile.amount = 0
			woodpile.regrow_sec = 0.5
			Tuning.fog_creep_per_sec = 0.5
			player.position = woodpile.global_position + Vector2(12, 0)
		400:
			check(not lamp.is_lit(), "unfuelled lantern goes cold")
			var markers = main.get_node("FogLayer/LanternMarkers")
			check(markers.needs_attention().has(lamp), "a cold lantern is marked so you can find it to refuel")
			check(main.get_node("HUD").label.text.contains("Needs fuel: 1 cold"), "HUD counts lanterns that need fuel")
			check(woodpile.amount >= 1, "hut woodpile regrows: no soft-lock")
			Input.action_press("interact")
		460:
			Input.action_release("interact")
			check(Inventory.get_count("fuel") >= 1, "gathered fuel from the woodpile")
			lamp_density_cold = fog.density_at(lamp.global_position)
			check(lamp_density_cold > 0.15, "fog creeps back over a cold lantern (%.2f)" % lamp_density_cold)
			var t := fog.tile_of(lamp.global_position)
			check(fog.remembered[t.y * fog.cols + t.x] == 1, "faded tile stays remembered")
			Tuning.fog_creep_per_sec = 0.05
			player.position = lamp.global_position + Vector2(12, 0)
			Input.action_press("interact")
		462:
			Input.action_release("interact")
		465:
			check(lamp.is_lit(), "carried fuel relights a cold lantern")
			Inventory.counts["fuel"] = 0
			check(Inventory.add("fuel", 100) == Inventory.carry_limit, "carry limit caps gathering")
			_m3_checks()
		500:
			var streaks = main.get_node("FogLayer/WindStreaks")
			check(streaks.active_count() == 0, "no wind streaks when calm")
		530:
			check(_landmark("stone_way")._spotted, "a landmark is announced when the light first finds it")
			check(main.get_node("HUD").toast.text.contains("Carved stone") or _landmark("stone_way").glow.enabled, "unread landmark glows")
			check(fed.fuel > 10.0, "Reservoir Lamp tops up a lantern in its light (%.2f)" % fed.fuel)
			check(reservoir.fuel < Tuning.reservoir_max_fuel - Tuning.reservoir_burn_per_sec * 1.0, "Reservoir spends its own tank feeding others")
			_wind_checks()
		540:
			check(main.get_node("FogLayer/WindStreaks").active_count() > 40, "wind streaks blow across the screen in a gust")
			check(main.get_node("HUD").toast.text != "" , "HUD toast active")
			wind.force(Wind.State.CALM)
		541:
			Art._ph.clear()   # release cached textures so exit is clean
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)


# --- M3 ------------------------------------------------------------------------

func _find_tile(pred: Callable) -> Vector2i:
	for y in fog.rows:
		for x in fog.cols:
			if pred.call(Vector2i(x, y)):
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func _connected(a: Vector2i, b: Vector2i) -> bool:
	var seen := {a: true}
	var queue: Array[Vector2i] = [a]
	while not queue.is_empty():
		var t: Vector2i = queue.pop_front()
		if t == b:
			return true
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = t + d
			if fog.in_bounds(n) and not seen.has(n) and fog.solid[fog.idx(n)] == 0:
				seen[n] = true
				queue.append(n)
	return false

func _landmark(id: String) -> Landmark:
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == id:
			return m
	return null

func _m3_checks() -> void:
	check(Progress.regions_seen.has(FogGrid.R_HOLLOW), "lighting the Hollow reveals its name")
	var marsh := _find_tile(func(t): return fog.terrain_of(t) == FogGrid.T_MARSH)
	var walk := _find_tile(func(t): return fog.terrain_of(t) == FogGrid.T_BOARDWALK)
	check(marsh.x >= 0 and fog.region[fog.idx(marsh)] == FogGrid.R_MARSH, "the Reedmarsh exists")
	check(fog.build_block(fog.tile_center(marsh)).begins_with("soft ground"), "cannot build on soft marsh")
	check(walk.x >= 0 and fog.build_block(fog.tile_center(walk)) == "", "can build on a boardwalk")
	var pump := _landmark("pumphouse")
	check(get_tree().get_nodes_in_group("landmark").size() == 9, "nine landmarks placed (5 Hollow/marsh, 4 Ridge)")
	check(pump != null and _connected(fog.tile_of(start), fog.tile_of(pump.global_position)), "walkable path from the hut to the pumphouse")
	var peat := get_tree().get_nodes_in_group("resource").filter(func(r): return r.label == "Peat")
	check(peat.size() >= 15, "peat in the marsh (%d)" % peat.size())
	# Reading a landmark.
	var reader = main.get_node("NoteReader")
	_landmark("ledger").activate()
	check(reader.is_open() and Progress.notes_read.has("ledger"), "reading the ledger opens the note")
	reader.close()
	# The pumphouse unlocks the Reservoir Lamp.
	check(not Progress.is_unlocked("reservoir"), "Reservoir Lamp starts locked")
	pump.activate()
	check(Progress.is_unlocked("reservoir"), "pumphouse unlocks the Reservoir Lamp")
	reader.close()
	Progress.selected = "reservoir"
	Inventory.counts["scrap"] = 0
	check(player.place_block_reason(start + Vector2(0, 96)) == "needs %d scrap" % Tuning.reservoir_cost_scrap, "Reservoir costs %d scrap" % Tuning.reservoir_cost_scrap)
	Progress.selected = "post"
	# Reservoir feeding.
	reservoir = Lantern.new()
	reservoir.kind = "reservoir"
	reservoir.position = fog.tile_center(fog.tile_of(start + Vector2(0, 200)))
	main.get_node("Lanterns").add_child(reservoir)
	fed = Lantern.new()
	fed.position = reservoir.position + Vector2(64, 0)
	fed.fuel = 10.0
	main.get_node("Lanterns").add_child(fed)
	# Walk the keeper to the carved stone so its tile gets lit (checked at frame 530).
	player.position = _landmark("stone_way").global_position + Vector2(0, 20)
	# Map screen.
	var map = main.get_node("MapScreen")
	map.toggle()
	map.render()
	check(map.is_open() and map.img != null and map.img.get_width() == fog.cols, "map screen opens and draws the valley")
	map.toggle()

func _wind_checks() -> void:
	# A Hollow tile with rock right next to it on the west.
	var t := _find_tile(func(q): return fog.terrain_of(q) == FogGrid.T_GROUND and fog.region[fog.idx(q)] == FogGrid.R_HOLLOW and fog.terrain_of(q + Vector2i.LEFT) == FogGrid.T_ROCK)
	var sheltered := Lantern.new()
	sheltered.position = fog.tile_center(t)
	main.get_node("Lanterns").add_child(sheltered)
	var exposed := Lantern.new()
	exposed.position = start + Vector2(0, -160)
	main.get_node("Lanterns").add_child(exposed)
	wind.force(Wind.State.GUST, Vector2i.RIGHT)   # blowing from the west
	check(exposed.in_gust() and is_equal_approx(exposed.burn_rate(), Tuning.lantern_burn_per_sec * Tuning.wind_burn_mult), "gust doubles burn on an exposed lantern")
	check(exposed.get_light_radius() < Tuning.lantern_max_radius, "gust shrinks an exposed lantern's light")
	check(not sheltered.in_gust() and is_equal_approx(sheltered.burn_rate(), Tuning.lantern_burn_per_sec), "rock upwind shelters a lantern")
	check(wind.status_text().contains("west"), "HUD names the wind direction")
	var hud = main.get_node("HUD")
	check(hud.toast.text.contains("Gust from the west"), "a gust is announced in the middle of the screen")
	check(exposed.in_gust() and wind.is_gusting(), "gust stays on for the streak check")
