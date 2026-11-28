extends Node
## Headless checks for the core loop and the Reedmarsh. M1b (no more tending): lamps never burn or dim, the old
## lamps are lit by touch, scrap is the one material and comes in one-off piles, the woodpile is scenery, the
## lantern markers and chips are gone (only the cold-frame lure on unlit old lamps), and wind is inert. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_core.tscn
## Exit code 0 = all passed. Runs as a scene so the autoloads are available.

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var lamp: Lantern
var scrap_pile: ResourceNode
var built: Lantern
var start := Vector2.ZERO
var lamp_density_out := 0.0
var wind: Wind
var reservoir: Lantern

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
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when a note or menu pauses the world
	strip_real_input()
	Story.skip_opening = true
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
			wind = main.get_node("Wind")
			for l in get_tree().get_nodes_in_group("lantern"):
				if l.global_position.distance_to(main.start_lantern_pos) < 8.0:
					lamp = l
			for r in get_tree().get_nodes_in_group("resource"):
				if r.global_position.distance_to(start) < 100.0:
					scrap_pile = r
			check(lamp != null and lamp.old and not lamp.is_lit() and lamp.can_light_by_touch(), "the old lantern by the hut starts cold, to be lit by touch (the first goal)")
			check(not Progress.is_unlocked("post"), "the Post Lamp starts locked until the Hollow find")
			Progress.unlock("post")  # the remaining core checks cover the build loop
			check(scrap_pile != null and scrap_pile.amount == 6, "a little scrap beside the hut (one-off)")
			var res := get_tree().get_nodes_in_group("resource")
			check(res.size() >= 40, "scrap piles scattered in the valley (%d)" % res.size())
			check(res.all(func(r): return r.kind == "scrap"), "every pile is scrap: no fuel spots, peat or glass (M1b)")
			check(res.all(func(r): return not r.is_revealed()), "all piles start hidden in fog")
			check(main.get_node("Terrain/Woodpile") != null and not res.any(func(r): return r.global_position.distance_to(start + main.WOODPILE_OFFSET) < 20.0), "the woodpile by the hut is scenery, not something to gather")
			check(Inventory.counts.keys() == ["scrap"] and Inventory.get_count("scrap") == 0, "the keeper carries only scrap, and starts with none")
			check(fog.is_solid_at(Vector2(8, 8)) and not fog.is_solid_at(start), "rock rings the Hollow, start is open")
			check(player.place_block_reason(Vector2(16, 16)) == "rock", "cannot build on rock")
			# Lit by touch: walk up to the old lamp and press A / E once.
			player.position = lamp.global_position + Vector2(12, 0)
			check(main.get_node("FogLayer/WorldPrompt").lines_for(lamp) == [[InputHint.key("interact"), "Light it"]], "the old lamp's prompt says Light it")
			player.begin_interact()
			check(lamp.is_lit() and not lamp.cold, "one touch lights the old lamp (no fuel)")
			player.position = start
		120:
			check(fog.density_at(lamp.global_position) < 0.1, "light clears fog at the lantern")
			check(fog.density_at(lamp.global_position + Vector2(400, 0)) > 0.9, "fog stays outside the radius")
			check(scrap_pile.is_revealed(), "light reveals nearby scrap")
			check(lamp.is_lit() and is_equal_approx(lamp.get_light_radius(), Tuning.lantern_max_radius), "a lit lamp shines at full radius and never dims (%.0f px)" % lamp.get_light_radius())
			check(player.place_block_reason(start + Vector2(0, 96)).begins_with("needs"), "cannot build without scrap")
			player.position = scrap_pile.global_position + Vector2(12, 0)
			check(main.get_node("FogLayer/WorldPrompt").lines_for(scrap_pile) == [[InputHint.key("interact"), "Take  6 scrap"]], "a pile's prompt says Take and how much")
			Input.action_press("interact")
		122:
			Input.action_release("interact")
		124:
			check(Inventory.get_count("scrap") == 6, "one press takes the whole pile (%d)" % Inventory.get_count("scrap"))
			check(not is_instance_valid(scrap_pile) or scrap_pile.is_queued_for_deletion() or not scrap_pile.is_in_group("resource"), "and the pile is gone for good (one-off)")
			player.position = start + Vector2(0, 96)
		126:
			built = player.try_place()
			check(built != null, "can build a Post Lamp on lit ground")
			check(Inventory.get_count("scrap") == 1, "building costs %d scrap" % Tuning.post_lamp_cost_scrap)
			check(player.place_block_reason(player.place_pos()) != "", "cannot build twice in one spot")
			check(built.is_lit() and not built.old and built.can_pick_up(), "a planted lamp is lit at once and can be picked up")
			player.position = built.global_position
		128:
			player.pick_up_nearest()
		132:
			check(get_tree().get_nodes_in_group("lantern").size() == 3, "pick up removes the lantern (the hut's, the north path's and the bowl's rim lamp stay)")
			check(Inventory.get_count("scrap") == 6, "pick up refunds all the scrap (M1c, PLAN_LANTERNS §5)")
			check(player.replant_t > 0.0 and player.place_block_reason(player.place_pos()).begins_with("Your hands are full"), "and planting waits a moment (the 8 s replant)")
			player.replant_t = 0.0
			player.position = lamp.global_position + Vector2(6, 0)
			player.pick_up_nearest()
		134:
			check(is_instance_valid(lamp) and lamp.is_inside_tree() and lamp.is_in_group("lantern"), "the valley's old lamps can't be picked up")
			# Hand lamp (M1a, GAME_PLAN §5): out in the dark, an empty lamp refills slowly by itself (kl_charge_regen).
			player.position = start + Vector2(-420, 0)
			player.lamp_charge = 0.0
		206:
			var want: float = Tuning.kl_charge_regen * 72.0 / 60.0
			check(absf(player.lamp_charge - want) < 0.02, "in the dark an empty hand lamp refills slowly by itself (%.3f, want %.3f)" % [player.lamp_charge, want])
			check(player.get_light_radius() >= Tuning.hand_lamp_ember_radius and player.get_light_radius() < Progress.lamp_max_radius(), "hand lamp never goes out (ember)")
			# A snuffed lamp (the Ashbrood's dive): dark for a while, then it relights by itself. Fog creeps back meanwhile.
			Tuning.fog_creep_per_sec = 0.5
			lamp.snuff(2.0)
			check(not lamp.is_lit() and lamp.get_light_radius() == 0.0 and lamp.is_snuffed(), "a snuffed lamp goes dark")
		300:
			lamp_density_out = fog.density_at(lamp.global_position)
			check(lamp_density_out > 0.15, "fog creeps back over a dark lamp (%.2f)" % lamp_density_out)
			var t := fog.tile_of(lamp.global_position)
			check(fog.remembered[t.y * fog.cols + t.x] == 1, "faded tile stays remembered")
			Tuning.fog_creep_per_sec = 0.05
		340:
			check(lamp.is_lit() and not lamp.is_snuffed(), "a snuffed lamp relights by itself (kl_snuff_sec)")
			# The cold-frame lure: only for old lamps not yet lit. The north path's waits until the ledger is read.
			var markers = main.get_node("FogLayer/LanternMarkers")
			var waypost: Lantern = get_tree().get_nodes_in_group("lantern").filter(func(l): return l.global_position.distance_to(main.waypost_lantern_pos) < 8.0)[0]
			check(not markers.unlit_old_lamps().has(lamp), "a lit old lamp has no lure")
			check(not markers.unlit_old_lamps().has(waypost), "the north path's lamp waits its turn (ledger unread)")
			Story.done["read_ledger"] = true
			check(markers.unlit_old_lamps() == [waypost], "then its cold frame shows through the fog")
			Story.done.erase("read_ledger")
			var chips := str(main.get_node("HUD").status_items()).to_lower()
			check(not chips.contains("lantern") and not chips.contains("fuel") and not chips.contains("gust"), "no lantern, fuel or wind chips on the HUD (%s)" % chips)
			_m3_checks()
		400:
			var streaks = main.get_node("FogLayer/WindStreaks")
			check(streaks.active_count() == 0, "no wind streaks when calm")
			check(wind.state == Wind.State.CALM, "wind is inert: no gust starts by itself (until M6)")
		430:
			check(_landmark("stone_way")._spotted, "a landmark is announced when the light first finds it")
			check(main.get_node("HUD").toast.text.contains("Carved stone") or _landmark("stone_way").glow.enabled, "unread landmark glows")
			check(reservoir.is_lit() and is_equal_approx(reservoir.get_light_radius(), Tuning.reservoir_radius) and not ("fuel" in reservoir), "a Reservoir Lamp is a wide light with no tank (feeding is cut)")
			wind.force(Wind.State.GUST, Vector2i.RIGHT)   # a gust can still be forced (M6 brings them back on the Ridge)
		440:
			check(main.get_node("FogLayer/WindStreaks").active_count() > 40, "a forced gust still draws its streaks (for M6)")
			check(lamp.is_lit() and is_equal_approx(lamp.get_light_radius(), Tuning.lantern_max_radius), "wind no longer touches a lamp")
			wind.force(Wind.State.CALM)
			_interaction_setup()
		441:
			Progress._input_block_until = 0   # a note closed earlier blocks input for 200 ms of real time; headless runs faster
			Input.action_press("interact")   # a tap takes the pile beside the lantern
		480:
			Input.action_release("interact")
			check(Inventory.get_count("scrap") > scrap_before, "a tap beside a lit lantern takes the scrap pile (%d -> %d)" % [scrap_before, Inventory.get_count("scrap")])
			check(is_instance_valid(hint_lantern) and hint_lantern.is_inside_tree(), "and holding on doesn't pick the lantern up while a pile was in reach")
		481:
			_slot_checks()
			Art._ph.clear()   # release cached textures so exit is clean
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)


# --- Interaction: lanterns beside scrap, quiet building -----------------------

var scrap_before := 0
var hint_lantern: Lantern

func _interaction_setup() -> void:
	# A scrap pile with a lantern right beside it: the lantern is nearer, but a tap still takes the pile.
	var pile: ResourceNode = null
	for r in get_tree().get_nodes_in_group("resource"):
		if r.amount > 0 and r.label == "" and (pile == null or r.global_position.distance_to(start) < pile.global_position.distance_to(start)):
			pile = r
	if pile:
		fog.clear_burst(pile.global_position, 96.0, 1.0)   # the light finds it
	check(pile != null, "found a scrap pile for the interaction checks")
	check(player.place_block_reason(pile.global_position) == "on a resource", "you can't build right on top of a pile")
	hint_lantern = Lantern.new()
	hint_lantern.position = pile.global_position + Vector2(24, 0)
	main.get_node("Lanterns").add_child(hint_lantern)
	player.global_position = pile.global_position + Vector2(30, 8)
	Inventory.counts["scrap"] = 0
	scrap_before = 0
	check(player.nearest_target() == hint_lantern and player.nearest_resource() == pile, "the lantern is the nearest thing, the pile is still in reach")
	var lines: Array = main.get_node("FogLayer/WorldPrompt").lines_for(hint_lantern)
	check(lines.any(func(l): return String(l[1]).begins_with("Take")), "the lantern's prompt offers to take the pile")
	# Building stays quiet until a build fails.
	check(player.build_hint_t <= 0.0, "no build outline or text by default")
	player.try_place()
	check(player.build_hint_t > 0.0 and player.build_hint != "", "a build that can't happen says why, for a moment (%s)" % player.build_hint)

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

## Everything reachable on foot from the hut (one flood fill).
func _reachable_from(a: Vector2i) -> PackedByteArray:
	var seen := PackedByteArray()
	seen.resize(fog.cols * fog.rows)
	seen[fog.idx(a)] = 1
	var queue: Array[Vector2i] = [a]
	var head := 0
	while head < queue.size():
		var t: Vector2i = queue[head]
		head += 1
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = t + d
			if fog.in_bounds(n) and seen[fog.idx(n)] == 0 and fog.solid[fog.idx(n)] == 0:
				seen[fog.idx(n)] = 1
				queue.append(n)
	return seen

## The bigger map (2026-11-27: every region 4x the area): its size, and that the route still works.
func _map_size_checks() -> void:
	check(fog.cols == 224 and fog.rows == 200, "the valley is 224 x 200 tiles (%d x %d)" % [fog.cols, fog.rows])
	var area := {}
	for i in fog.region.size():
		if fog.solid[i] == 0:
			area[fog.region[i]] = area.get(fog.region[i], 0) + 1
	print("region open tiles: %s" % str(area))
	check(area.get(FogGrid.R_HOLLOW, 0) > 4000 and area.get(FogGrid.R_MARSH, 0) > 6500 and area.get(FogGrid.R_RIDGE, 0) > 3500, "every region is about 4x its old area (%s)" % str(area))
	var reach := _reachable_from(fog.tile_of(start))
	var cut := []
	for n in get_tree().get_nodes_in_group("landmark") + get_tree().get_nodes_in_group("waylamp") + get_tree().get_nodes_in_group("resource"):
		if reach[fog.idx(fog.tile_of(n.global_position))] == 0:
			cut.append("%s %s" % [n.get("id") if n.get("id") != null else n.display_name(), str(fog.tile_of(n.global_position))])
	check(cut.is_empty(), "every landmark, WayLamp, find, cache and resource can be reached on foot from the hut (%s)" % str(cut))
	var ne := 0
	for y in range(0, 80):
		for x in range(140, fog.cols):
			if fog.solid[y * fog.cols + x] == 0:
				ne += 1
	check(ne == 0, "the north-east stays free for the Lakeshore and the Still Lake (%d open tiles)" % ne)

func _landmark(id: String) -> Landmark:
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == id:
			return m
	return null

## M1c lamp slots (PLAN_LANTERNS §5; owner 2026-11-28): 2 at the start, 3 at level 4, 4 at 8, 5 at 12; old lamps and
## lamps in held ground are free; a refused plant says why; pick-up refunds all and replanting waits 8 s.
func _slot_checks() -> void:
	check(Progress.lamp_slots(1) == 2 and Progress.lamp_slots(3) == 2 and Progress.lamp_slots(4) == 3 and Progress.lamp_slots(7) == 3, "lamp slots: 2 at levels 1-3, 3 at 4-7")
	check(Progress.lamp_slots(8) == 4 and Progress.lamp_slots(11) == 4 and Progress.lamp_slots(12) == 5, "4 at levels 8-11, 5 at level 12")
	check(Progress.lamp_slots(12) <= Tuning.kl_lamp_slots_max, "never past kl_lamp_slots_max (%d)" % Tuning.kl_lamp_slots_max)
	# Clear the planted lamps, then plant at level 3: the 3rd is refused with the reason; at level 4 it plants.
	for l in get_tree().get_nodes_in_group("lantern"):
		if not l.old:
			l.remove_from_group("lantern")
			l.queue_free()
	LightSense.bump()
	Progress.selected = "post"
	Progress.level = 3
	Inventory.counts["scrap"] = 30
	player.replant_t = 0.0
	var spots := [start + Vector2(-160, 160), start + Vector2(-60, 160), start + Vector2(40, 160)]
	var placed := 0
	for i in 2:
		player.position = spots[i]
		if player.try_place():
			placed += 1
	check(placed == 2 and player.lamps_used() == 2, "at level 3 two lamps plant (%d, %d used)" % [placed, player.lamps_used()])
	player.position = spots[2]
	check(player.place_block_reason(player.place_pos()) == Player_SLOTS_FULL(), "a 3rd is refused: \"%s\"" % player.place_block_reason(player.place_pos()))
	check(player.try_place() == null and player.build_hint == player.SLOTS_FULL, "and the refusal shows the reason by the keeper")
	var hud = main.get_node("HUD")
	check(hud.lamp_pip_state()[0] == 2 and hud.lamp_pip_state()[1] == 2, "the HUD shows 2 pips, both lit (%s)" % str(hud.lamp_pip_state()))
	Progress.level = 4
	check(player.try_place() != null and player.lamps_used() == 3, "at level 4 the 3rd plants")
	check(hud.lamp_pip_state()[0] == 3, "and the HUD shows 3 pips")
	# Old lamps don't count.
	var old_n := get_tree().get_nodes_in_group("lantern").filter(func(l): return l.old).size()
	check(old_n == 3 and player.lamps_used() == 3, "the valley's old lamps use no slot (%d old)" % old_n)
	# Pick one up: all the scrap back, then an 8 s wait before planting again (shown on the next free pip).
	var before := Inventory.get_count("scrap")
	player.position = spots[2] + Vector2(4, 0)
	player.pick_up_nearest()
	check(Inventory.get_count("scrap") == before + Tuning.post_lamp_cost_scrap, "pick-up gives back all %d scrap" % Tuning.post_lamp_cost_scrap)
	check(is_equal_approx(player.replant_t, Tuning.kl_lamp_replant_cd) and Tuning.kl_lamp_replant_cd == 8.0, "and replanting waits %.0f s" % Tuning.kl_lamp_replant_cd)
	check(hud.lamp_pip_state()[2] > 0.99, "the HUD shows the wait on the free pip")
	player.replant_t = 0.0
	Progress.level = 1

func Player_SLOTS_FULL() -> String:
	return "All your lamps are lit."

func _m3_checks() -> void:
	check(Progress.regions_seen.has(FogGrid.R_HOLLOW), "lighting the Hollow reveals its name")
	var marsh := _find_tile(func(t): return fog.terrain_of(t) == FogGrid.T_MARSH)
	var walk := _find_tile(func(t): return fog.terrain_of(t) == FogGrid.T_BOARDWALK)
	check(marsh.x >= 0 and fog.region[fog.idx(marsh)] == FogGrid.R_MARSH, "the Reedmarsh exists")
	check(fog.build_block(fog.tile_center(marsh)).begins_with("soft ground"), "cannot build on soft marsh")
	check(walk.x >= 0 and fog.build_block(fog.tile_center(walk)) == "", "can build on a boardwalk")
	var pump := _landmark("pumphouse")
	var notes := get_tree().get_nodes_in_group("landmark").filter(func(m): return m.upgrade == "" and not m.scenery)
	check(notes.size() == 12, "twelve story landmarks to read, including the Hollow find; the rack is scenery (%d)" % notes.size())
	check(_landmark("rack") != null and _landmark("rack").scenery and _landmark("letter") == null, "the rack is just scenery and the door letter is gone (less to read at the start)")
	check(pump != null and _connected(fog.tile_of(start), fog.tile_of(pump.global_position)), "walkable path from the hut to the pumphouse")
	_map_size_checks()
	var caches := get_tree().get_nodes_in_group("resource").filter(func(r): return r.label == "Old cache")
	check(caches.size() == main.CACHES.size() and caches.all(func(r): return r.kind == "scrap"), "every old cache holds scrap (the fuel and glass caches too) (%d)" % caches.size())
	check(Lantern.cost("hooded") == Tuning.hooded_cost_scrap and Lantern.cost("mirror") == Tuning.mirror_cost_scrap and Lantern.cost_text("mirror") == "%d scrap" % Tuning.mirror_cost_scrap, "lamp costs fold into scrap (Hooded %d, Mirror %d)" % [Tuning.hooded_cost_scrap, Tuning.mirror_cost_scrap])
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
	# A Reservoir Lamp: a wide dim light, nothing to feed.
	reservoir = Lantern.new()
	reservoir.kind = "reservoir"
	reservoir.position = fog.tile_center(fog.tile_of(start + Vector2(0, 200)))
	main.get_node("Lanterns").add_child(reservoir)
	# Walk the keeper to the carved stone so its tile gets lit (checked at frame 530).
	player.position = _landmark("stone_way").global_position + Vector2(0, 20)
	# Map screen.
	var map = main.get_node("MapScreen")
	map.toggle()
	map.render()
	check(map.is_open() and map.img != null and map.img.get_width() == fog.cols, "map screen opens and draws the valley")
	map.toggle()
