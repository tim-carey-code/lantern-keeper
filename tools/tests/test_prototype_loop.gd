extends Node
## The loop (owner 2026-11-27, DECISIONS "route: one loop"): Hollow -> Reedmarsh -> up out of the marsh ->
## the Ridge one way, east end to the old steps -> the Lakeshore (still empty). Checks, as placed:
##   1. the Hollow's WayLamp stretch: the WayLamp north-east by the passage, pack 2 and the Clinker before it,
##      the Clinker out of the Ashbrood fight, nothing else waking on the road east;
##   2. the marsh climb: walkable from the marsh to the Ridge, west of the Lakeshore; the cairn at its foot;
##      the old climb closed by fallen stones until pushed down from above (the later shortcut);
##   3. the Ridge one way: the glazier and the lens by the entry, then the coat, the station, its WayLamp and
##      the steps, each nearer the steps, with no walk back west; the far west optional;
##   4. goals, pointer targets and notes in loop order;
##   5. WayLamp fast travel: only lit WayLamps listed, travel moves the keeper, blocked while hunted or during a
##      WayLamp or guardian fight, gamepad / keyboard / mouse, focus, clean close, Ark Pixel sizes;
##   6. save round trips (lit WayLamps, the opened stones, an older save without them).
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_loop.tscn

const T := FogGrid.TILE
const MAIN := preload("res://scripts/main/main.gd")

var main: Node
var frame := 0
var fails := 0
var menu: Node
var pad_ok := false
var _wait_until := 0
var _step := 0
var _mouse_target: Button

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		fails += 1

## The project maps A to interact, B to cancel, Start to pause and the D-pad to ui_up / ui_down (setup_input.gd).
## Recorded before the real controller's events are stripped (a pad on this PC would move the test keeper).
func _record_pad() -> bool:
	var want := {"interact": JOY_BUTTON_A, "cancel": JOY_BUTTON_B, "pause": JOY_BUTTON_START, "ui_down": JOY_BUTTON_DPAD_DOWN, "ui_up": JOY_BUTTON_DPAD_UP}
	for action in want:
		var found := false
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton and e.button_index == want[action]:
				found = true
		if not found:
			print("    (no pad button for %s)" % action)
			return false
	return true

func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pad_ok = _record_pad()
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
	SaveGame.path = "user://test_loop.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func tiles(d: float) -> float:
	return d / T

func _landmark(id: String) -> Node2D:
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == id:
			return m
	return null

func _waylamp(id: String) -> WayLamp:
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.id == id:
			return w
	return null

func _dist_to_path(p: Vector2, path: Array) -> float:
	var best := INF
	for i in path.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, path[i], path[i + 1])))
	return best

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

## Breadth-first walk over open tiles (ground, boardwalk, marsh). Returns {tile: parent}.
func _bfs(from: Vector2i, allow: Callable) -> Dictionary:
	var fog: FogGrid = main.fog
	var seen := {from: from}
	var q: Array[Vector2i] = [from]
	var i := 0
	while i < q.size():
		var t := q[i]
		i += 1
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = t + d
			if seen.has(n) or not fog.in_bounds(n) or fog.solid[fog.idx(n)] == 1 or not allow.call(n):
				continue
			seen[n] = t
			q.append(n)
	return seen

func _walk(seen: Dictionary, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not seen.has(to):
		return out
	var t := to
	while seen[t] != t:
		out.append(t)
		t = seen[t]
	out.append(t)
	out.reverse()
	return out

func _process(_delta: float) -> void:
	frame += 1
	if _wait_until > 0 and frame < _wait_until:
		return
	_wait_until = 0
	match frame:
		2:
			_hollow()
			_marsh_climb()
			_ridge()
			_goals()
			_stones_closed()
		3:
			_stones_open_from_above()
		6:
			_travel_setup()
		_:
			if frame > 6:
				_travel_steps()

# --- 1. The Hollow's WayLamp stretch -----------------------------------------------------

func _hollow() -> void:
	var start: Vector2 = main.start
	var wl := _waylamp("hollow").global_position
	var clinker: Clinker = get_tree().get_nodes_in_group("foe").filter(func(f): return f is Clinker)[0]
	var nest_a: WickNest = get_tree().get_nodes_in_group("foe").filter(func(f): return f is WickNest and f.foe_id == "nest_hollow_4")[0]
	var pack2: EnemyPack = get_tree().get_nodes_in_group("enemy_pack").filter(func(p): return p.id == "hollow_2")[0]
	var crook := _landmark("crook_post").global_position
	var stone := _landmark("stone_way").global_position
	var exit: Vector2 = main.fog.tile_center(Vector2i(96, 136))   # the passage, where the Hollow ends
	var t_wl: Vector2i = main.fog.tile_of(wl) - main.fog.tile_of(start)
	print("--- The Hollow's WayLamp stretch (tiles; offsets from the hut):")
	print("    pack 2 %s, the Clinker %s, the WayLamp %s; carved stone %s" % [main.fog.tile_of(pack2.global_position), main.fog.tile_of(clinker.global_position), main.fog.tile_of(wl), main.fog.tile_of(stone)])
	print("    the Clinker to the WayLamp %.1f, pack 2 to the Clinker %.1f, nest A to pack 2 %.1f, the WayLamp to the carved stone %.1f" % [
		tiles(clinker.global_position.distance_to(wl)), tiles(pack2.global_position.distance_to(clinker.global_position)),
		tiles(nest_a.global_position.distance_to(pack2.global_position)), tiles(wl.distance_to(stone))])
	check(t_wl.x >= 20 and t_wl.y <= -8, "the Hollow's WayLamp moved north-east of the hut (%+d,%+d)" % [t_wl.x, t_wl.y])
	check(wl.distance_to(stone) <= 12.0 * T and stone.x > wl.x, "it stands by the way east: the carved stone and the passage are %.1f tiles on" % tiles(wl.distance_to(stone)))
	var d_cw := clinker.global_position.distance_to(wl)
	check(d_cw > Tuning.kl_clinker_wake_radius + T and d_cw < 10.0 * T, "the Clinker sits %.1f tiles before the WayLamp: more than its 7-tile wake plus a tile, so it stays out of the Ashbrood fight" % tiles(d_cw))
	check(clinker.global_position.distance_to(nest_a.global_position) > clinker.global_position.distance_to(wl) and pack2.global_position.distance_to(wl) > d_cw,
		"the road runs nest A, pack 2, the Clinker, the WayLamp")
	var all := hostiles()
	var wake_at := func(spot: Vector2, skip: Array) -> Array:
		return all.filter(func(h): return not skip.has(h[0]) and (h[0] as Node2D).global_position.distance_to(spot) <= h[2] + T).map(func(h): return h[1])
	var at_wl: Array = wake_at.call(wl, [])
	check(at_wl.is_empty(), "nothing wakes at the WayLamp, even a tile off (%s)" % str(at_wl))
	var at_cl: Array = wake_at.call(clinker.global_position, [clinker])
	check(at_cl.is_empty(), "nothing but the Clinker wakes at its post (%s)" % str(at_cl))
	var at_p2: Array = wake_at.call(pack2.global_position, [pack2])
	check(at_p2.is_empty(), "nothing else wakes while you fight pack 2 (%s)" % str(at_p2))
	var road_east := [wl, stone, exit]
	var on_east := all.filter(func(h): return _dist_to_path((h[0] as Node2D).global_position, road_east) <= h[2]).map(func(h): return h[1])
	check(on_east.is_empty(), "the road east, from the WayLamp past the carved stone into the passage, wakes nothing (%s)" % str(on_east))
	var route := [start, main.waypost_lantern_pos, crook, nest_a.global_position, pack2.global_position, clinker.global_position, wl, stone, exit]
	var walk_ok := true
	for i in route.size() - 1:
		var a: Vector2 = route[i]
		var b: Vector2 = route[i + 1]
		var steps := int(a.distance_to(b) / 8.0)
		for s in steps + 1:
			if main.fog.terrain_of(main.fog.tile_of(a.lerp(b, float(s) / maxf(steps, 1)))) != FogGrid.T_GROUND:
				walk_ok = false
	check(walk_ok, "the whole Hollow road, hut to passage, is open ground")

# --- 2. The marsh climb and the old climb's stones --------------------------------------------

func _marsh_climb() -> void:
	var fog: FogGrid = main.fog
	var foot: Vector2i = Vector2i(MAIN.MARSH_CLIMB[0])
	var top: Vector2i = MAIN.RIDGE_ENTRY
	var any := func(_t): return true
	var no_marsh_climb := func(t: Vector2i): return fog.region[fog.idx(t)] != FogGrid.R_MARSH
	var from_marsh := _bfs(fog.tile_of(fog.tile_center(Vector2i(160, 136))), any)
	var path := _walk(from_marsh, top)
	check(not path.is_empty(), "a path climbs from the Reedmarsh up to the Ridge's east rim (%d steps from the marsh's middle)" % path.size())
	var ridge_t := 0
	var max_x := 0
	for t in path:
		if t.y < 90:
			max_x = maxi(max_x, t.x)   # the climb itself, above the marsh
		if fog.region[fog.idx(t)] == FogGrid.R_RIDGE:
			ridge_t += 1
	# The Lakeshore's space (docs/PLAN_LAKESHORE.md, about x 132-164, y 18-74, and the Still Lake east of it)
	# stays solid rock down to the marsh: the climb runs west of it (it reaches x %d).
	var shore_open := 0
	for y in range(0, 82):
		for x in range(132, fog.cols):
			if fog.terrain_of(Vector2i(x, y)) != FogGrid.T_ROCK:
				shore_open += 1
	check(shore_open == 0 and max_x < 132, "it stays west of the Lakeshore's space, which is still empty rock (path reaches x %d; %d open tiles there)" % [max_x, shore_open])
	var foot_d: float = fog.tile_center(fog.tile_of(_landmark("climb_cairn").global_position)).distance_to(fog.tile_center(foot))
	check(foot_d <= 8.0 * T and fog.region_at(_landmark("climb_cairn").global_position) == FogGrid.R_MARSH, "the cairn stands at its foot, in the marsh (%.1f tiles from the first step)" % tiles(foot_d))
	# The Ridge is reached from the Hollow only through the marsh while the old climb's stones are down.
	var hollow_only := _bfs(fog.tile_of(main.start), no_marsh_climb)
	check(not hollow_only.has(top) and not hollow_only.has(fog.tile_of(_landmark("station").global_position)), "with the stones down, the Ridge can't be reached from the Hollow without going through the marsh")
	var hut_to_ridge := _bfs(fog.tile_of(main.start), any)
	check(hut_to_ridge.has(top) and hut_to_ridge.has(fog.tile_of(_landmark("station").global_position)), "but the hut, the marsh and the station are one connected walk")
	print("    marsh climb: %d tiles of walk on the Ridge side; it reaches the Ridge at %s" % [ridge_t, top])

func _stones_closed() -> void:
	var stones: ClimbStones = main.climb_stones
	var fog: FogGrid = main.fog
	check(stones.tiles.size() >= 8 and stones.tiles.all(func(t): return fog.terrain_of(t) == FogGrid.T_ROCK), "the old climb is closed by %d tiles of fallen stones" % stones.tiles.size())
	check(not stones.is_open and stones.body != null and stones.body.get_child_count() == stones.tiles.size(), "with their own collision, so the keeper can't walk through")
	# From below (the Hollow side) the keeper can't push them.
	main.player.global_position = stones.center() + Vector2(0, 2.0 * T)
	stones._process(0.0)
	check(not stones.is_open, "standing below them (the Hollow side) does nothing")
	main.player.global_position = stones.center() + Vector2(0, -2.0 * T)

func _stones_open_from_above() -> void:
	var stones: ClimbStones = main.climb_stones
	var fog: FogGrid = main.fog
	check(stones.is_open and Progress.cleared.has(ClimbStones.ID), "coming down from the Ridge, the keeper pushes the stones down: the old climb is the shortcut now")
	check(stones.tiles.all(func(t): return fog.terrain_of(t) == FogGrid.T_GROUND and fog.region[fog.idx(t)] == FogGrid.R_HOLLOW) and stones.body == null, "the stones are ground again, without collision")
	var through := _bfs(fog.tile_of(main.start), func(t: Vector2i): return fog.region[fog.idx(t)] != FogGrid.R_MARSH)
	check(through.has(MAIN.RIDGE_ENTRY), "and the Hollow reaches the Ridge directly up the old climb")
	main.player.global_position = main.start

# --- 3. The Ridge, one way ---------------------------------------------------------------------

func _ridge() -> void:
	var fog: FogGrid = main.fog
	var entry := fog.tile_center(MAIN.RIDGE_ENTRY)
	var stops := [["the entry", entry], ["the glazier", _landmark("glazier").global_position], ["the lens", _landmark("lens").global_position],
		["the coat", _landmark("coat").global_position], ["the station", _landmark("station").global_position],
		["the WayLamp", _waylamp("ridge").global_position], ["the steps", _landmark("ridge_steps").global_position]]
	var steps: Vector2 = stops[-1][1]
	print("--- The Ridge, one way (tile; tiles from the entry; tiles to the steps):")
	for s in stops:
		print("    %-12s %s  %5.1f  %5.1f" % [s[0], fog.tile_of(s[1]), tiles(entry.distance_to(s[1])), tiles(steps.distance_to(s[1]))])
	check(entry.distance_to(stops[1][1]) <= 8.0 * T and entry.distance_to(stops[2][1]) <= 12.0 * T, "the glazier (the Hooded Lamp, the Ridge's find) and the lens wait close to the marsh entry")
	check(steps.distance_to(stops[4][1]) <= 12.0 * T and steps.distance_to(stops[5][1]) <= 8.0 * T, "the station and the Ridge's WayLamp stand toward the old steps")
	var nearer := true
	for i in stops.size() - 1:
		if steps.distance_to(stops[i + 1][1]) >= steps.distance_to(stops[i][1]):
			nearer = false
	check(nearer, "every stop is nearer the steps than the one before")
	var farther := true
	for i in range(1, 4):
		if entry.distance_to(stops[i + 1][1]) <= entry.distance_to(stops[i][1]):
			farther = false
	check(farther, "and the glazier, lens, coat and station each lie farther from the entry")
	# Walk it: each leg by the shortest open path over Ridge ground. No leg goes back west of the entry, and the
	# whole walk is not much longer than walking straight from the entry to the steps.
	var on_ridge := func(t: Vector2i): return fog.region[fog.idx(t)] == FogGrid.R_RIDGE
	var legs := 0
	var min_x := 9999
	var all_ok := true
	for i in stops.size() - 1:
		var seen := _bfs(fog.tile_of(stops[i][1]), on_ridge)
		var w := _walk(seen, fog.tile_of(stops[i + 1][1]))
		if w.is_empty():
			all_ok = false
			print("    no walk from %s to %s" % [stops[i][0], stops[i + 1][0]])
			continue
		legs += w.size() - 1
		for t in w:
			min_x = mini(min_x, t.x)
	var direct := _walk(_bfs(fog.tile_of(entry), on_ridge), fog.tile_of(steps)).size() - 1
	check(all_ok, "every leg is walkable on the Ridge")
	check(min_x >= MAIN.RIDGE_ENTRY.x - 6, "no leg goes back west across the Ridge (westmost tile x %d, the entry is x %d)" % [min_x, MAIN.RIDGE_ENTRY.x])
	check(legs <= int(direct * 1.6), "the whole trail is %d steps, against %d straight from the entry to the steps: no backtracking" % [legs, direct])
	var west := 0
	for g in Story.GOALS:
		var target: Variant = _goal_pos(g["id"])
		if target != null and fog.region_at(target) == FogGrid.R_RIDGE and fog.tile_of(target).x < MAIN.RIDGE_ENTRY.x - 6:
			west += 1
	check(west == 0, "no goal sends you to the far west of the Ridge: it is optional (%d)" % west)
	# The Lakeshore (still empty space, docs/PLAN_LAKESHORE.md: about x 132-164, y 18-74) begins just past the steps.
	var to_shore := fog.tile_of(steps).distance_to(Vector2i(132, 34))
	check(to_shore <= 10.0, "the trail ends at the steps, %.1f tiles from where the Lakeshore will begin" % to_shore)

# --- 4. Goals, pointer and notes ------------------------------------------------------------------

func _goal_pos(id: String) -> Variant:
	var ptr = get_tree().get_first_node_in_group("goal_pointer")
	var was := Story.current
	var mode := Story.pointer_mode
	Story.pointer_mode = "on"
	Story.current = id
	var p = ptr.target_pos()
	Story.current = was
	Story.pointer_mode = mode
	return p

func _goals() -> void:
	var order := ["kindle_hollow", "stone_way", "enter_marsh", "frames_east", "chalk_lake", "pumphouse", "kindle_marsh",
		"climb_north", "glazier", "lens", "coat", "station", "kindle_ridge", "descend"]
	var ids: Array = Story.GOALS.map(func(g): return g["id"])
	var in_order := true
	for i in order.size() - 1:
		if ids.find(order[i]) >= ids.find(order[i + 1]):
			in_order = false
	check(in_order, "the goals run the loop: the Hollow's WayLamp, east through the marsh, its WayLamp, up out of the marsh, the Ridge to the steps")
	var regions := []
	var missing := []
	for id in order:
		var p = _goal_pos(id)
		if p == null:
			missing.append(id)
		else:
			regions.append(main.fog.region_at(p))
	check(missing.is_empty(), "each has a pointer target (%s)" % str(missing))
	var rising := true
	for i in regions.size() - 1:
		rising = rising and regions[i] <= regions[i + 1]
	check(rising, "and the targets go Hollow, then marsh, then Ridge, never back (%s)" % str(regions))
	var cairn = _goal_pos("climb_north")
	check(cairn != null and main.fog.region_at(cairn) == FogGrid.R_MARSH, "\"%s\" points at the cairn at the foot of the marsh climb" % Story.goal_text("climb_north"))
	check(_landmark("ledger").text.contains("Then the WayLamp, on the way east."), "the ledger sends you to the WayLamp on the way east (DRAFT)")
	check(_landmark("climb_cairn").text.contains("Light the marsh before you climb."), "the cairn asks you to light the marsh before you climb (DRAFT)")
	check(_landmark("pumphouse").text.contains("Now go up, north of the reeds."), "the pumphouse sends you up out of the marsh, not back past the Hollow (DRAFT)")

# --- 5. Fast travel ----------------------------------------------------------------------------------

func _travel_setup() -> void:
	menu = get_tree().get_first_node_in_group("travel_menu")
	check(menu != null, "the travel menu is in the game")
	check(pad_ok, "the pad mapping: A interacts, B cancels, Start pauses, the D-pad moves focus")
	check(menu.lit_waylamps().is_empty(), "no WayLamp is lit at the start: nothing to travel to")
	for w in get_tree().get_nodes_in_group("waylamp"):
		Progress.notes_read["waylamp_" + w.id] = true
	# Unlit: interact lights it (M1b: by touch, waking its guardian); it doesn't open travel.
	var hollow := _waylamp("hollow")
	main.player.global_position = menu.arrive_pos(hollow)
	main.player.begin_interact()
	check(not menu.is_open() and main.player.last_touch == "lit", "a cold WayLamp doesn't open travel (%s)" % main.player.last_touch)
	# Undo that fight for the travel checks below.
	if hollow.guardian():
		hollow.guardian().queue_free()
	hollow.kindling = false
	# Lit as a save would have them (Progress.settle would also pay kindling wick and open a level-up card).
	Progress.settled[FogGrid.R_HOLLOW] = true
	Progress.settled[FogGrid.R_MARSH] = true
	_step = 1

func _wait(frames: int) -> void:
	_wait_until = frame + frames

func _menu_fonts_ok() -> bool:
	var ok := true
	var stack: Array = [menu.root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is Label or n is Button:
			ok = ok and [20, 30, 40, 60].has((n as Control).get_theme_font_size("font_size"))
	return ok

func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()

func _action(name: String) -> void:
	var ev := InputEventAction.new()
	ev.action = name
	ev.pressed = true
	Input.parse_input_event(ev)
	var up := InputEventAction.new()
	up.action = name
	up.pressed = false
	Input.parse_input_event(up)

func _closed_clean(label: String) -> void:
	check(not menu.is_open() and not Tuning.ui_open and not get_tree().paused and _focus() == null, label)

func _travel_steps() -> void:
	var hollow := _waylamp("hollow")
	var marsh := _waylamp("marsh")
	var ridge := _waylamp("ridge")
	var s := _step
	_step = s + 1   # advance first: a failed check never repeats a step
	match s:
		1:
			var lit: Array = menu.lit_waylamps()
			check(lit.size() == 2 and lit[0] == hollow and lit[1] == marsh, "lit WayLamps form the network: the Hollow and the Reedmarsh, not the cold Ridge")
			main.player.global_position = menu.arrive_pos(hollow)
			main.player.begin_interact()   # interact at a lit WayLamp
			check(menu.is_open() and main.player.last_touch == "held", "interacting with a lit WayLamp opens the travel list")
			var texts: Array = menu.buttons.map(func(b): return b.text)
			check(texts == ["WayLamp of the Hollow (you are here)", "WayLamp of the Reedmarsh", "Stay"], "it lists only lit WayLamps, marks where you are, and offers to stay (%s)" % str(texts))
			check(menu.buttons[0].disabled and menu.buttons[0].focus_mode == Control.FOCUS_NONE, "where you are can't be picked or focused")
			check(_focus() == menu.buttons[1], "focus is on the first place to go as it opens (gamepad and keyboard)")
			check(Tuning.ui_open and get_tree().paused, "the world waits while it is open")
			check(_menu_fonts_ok(), "Ark Pixel at 20, 30 or 40 only")
			_action("ui_down")
		2:
			check(_focus() == menu.buttons[2], "down moves focus to Stay (D-pad / arrows)")
			_action("ui_up")
		3:
			check(_focus() == menu.buttons[1], "and up moves it back, skipping nothing but the lamp you are at")
			_action("cancel")   # B / Q
		4:
			_closed_clean("B closes it cleanly: no focus left behind, the world runs again")
			check(Progress.input_blocked(), "and the button press doesn't fall through to the game")
			main.player.begin_interact()
		5:
			check(menu.is_open() and _focus() == menu.buttons[1] and not menu.buttons[1].is_queued_for_deletion(), "opened again: fresh buttons, focus on the new one (not a freed one)")
			_action("pause")   # Escape / Start
		6:
			_closed_clean("Escape / Start closes it too")
			var pause := main.get_node("PauseMenu")
			check(not pause.is_open(), "and doesn't open the pause menu behind it")
			# Gamepad: A on the focused WayLamp travels.
			main.player.flasks = 1
			main.player.warmth = 37.0
			main.player.begin_interact()
			_action("interact")
		7:
			check(menu.travelling and not menu.is_open() and menu.fade.visible, "A on a WayLamp travels: a short fade starts")
			_wait(int((menu.FADE_OUT + menu.FADE_IN) * 60.0) + 6)
		8:
			check(main.player.global_position.distance_to(marsh.global_position) <= 64.0, "the keeper is at the Reedmarsh's WayLamp (%.0f px away)" % main.player.global_position.distance_to(marsh.global_position))
			check(main.player.flasks == 1 and main.player.warmth < Tuning.warmth_max, "fast travel doesn't refill flasks or warmth (%.1f)" % main.player.warmth)
			check(not menu.travelling and not menu.fade.visible, "the fade is done")
			_closed_clean("and the game is back in play, no focus held")
			check(main.player.nearest_target() == marsh, "standing in reach of the WayLamp you came to")
			# Mouse: a click on a button travels back.
			main.player.begin_interact()
		9:
			var back: Button = menu.buttons[0]
			check(back.text == "WayLamp of the Hollow" and menu.buttons[1].disabled, "from the marsh the list turns around: the Hollow to go to, the marsh is here")
			_mouse_target = back
			_click(back)
		10:
			check(menu.travelling or main.player.global_position.distance_to(hollow.global_position) <= 64.0, "a mouse click on a WayLamp travels")
			_wait(int((menu.FADE_OUT + menu.FADE_IN) * 60.0) + 6)
		11:
			check(main.player.global_position.distance_to(hollow.global_position) <= 64.0, "back at the Hollow's WayLamp")
			_closed_clean("closed cleanly after the mouse too")
			_blocked()
		12:
			_save_round_trip()
		13:
			_reload_check()
		14:
			_reload_result()
			print("RESULT fails=%d" % fails)
			SaveGame.delete_save()
			get_tree().quit(1 if fails else 0)

## A real left click in the middle of a button.
func _click(b: Button) -> void:
	var at := b.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = at
	move.global_position = at
	get_viewport().push_input(move, true)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		get_viewport().push_input(ev, true)

func _blocked() -> void:
	var hollow := _waylamp("hollow")
	var keeper: Node2D = main.player
	var wp = get_tree().get_first_node_in_group("world_prompt")
	# Hunted: a Wickling chasing the keeper.
	var w := Wickling.new()
	w.position = keeper.global_position + Vector2(160, 0)
	main.get_node("FogLayer/Wicklings").add_child(w)
	w.state = Wickling.State.CHASE
	check(menu.block_reason() == menu.BLOCK_HUNTED, "a Wickling chasing the keeper blocks travel")
	keeper.begin_interact()
	check(not menu.is_open() and keeper.last_touch == "travel_blocked", "interact then opens nothing")
	var lines: Array = wp.lines_for(hollow)
	check(lines.any(func(ln): return ln[1] == menu.BLOCK_HUNTED), "and the WayLamp says why (%s)" % str(lines))
	w.state = Wickling.State.WANDER
	check(menu.block_reason() == "", "a Wickling that only wanders nearby doesn't")
	w.position = keeper.global_position + Vector2(Tuning.travel_hunt_radius + 200.0, 0)
	w.state = Wickling.State.CHASE
	check(menu.block_reason() == "", "nor one hunting far away (past %.0f tiles)" % tiles(Tuning.travel_hunt_radius))
	w.queue_free()
	# An awake Clinker close by.
	var c := Clinker.new()
	c.position = keeper.global_position + Vector2(200, 0)
	main.get_node("FogLayer/Wicklings").add_child(c)
	c.awake = true
	check(menu.block_reason() == menu.BLOCK_HUNTED, "an awake Clinker close by blocks travel")
	c.queue_free()
	# A WayLamp kindling, anywhere.
	var ridge := _waylamp("ridge")
	ridge.kindling = true
	check(menu.block_reason() == menu.BLOCK_KINDLING and not menu.open(hollow), "a kindling WayLamp blocks travel")
	ridge.kindling = false
	# A guardian fight.
	var boss := Ashbrood.new()
	boss.position = ridge.global_position
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	main.get_node("FogLayer/Wicklings").add_child(boss)
	check(menu.block_reason() == menu.BLOCK_GUARDIAN and not menu.open(hollow), "a guardian fight blocks travel")
	boss.free()
	check(menu.block_reason() == "" and not menu.is_open() and not Tuning.ui_open, "and nothing is left open after the refusals")

# --- 6. Saves ---------------------------------------------------------------------------------------

func _save_round_trip() -> void:
	check(SaveGame.save(main), "saved")
	var f := FileAccess.open(SaveGame.path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	var settled: Array = data["progress"]["settled"].map(func(x): return int(x))
	check(settled.has(FogGrid.R_HOLLOW) and settled.has(FogGrid.R_MARSH) and not settled.has(FogGrid.R_RIDGE) and int(data["version"]) == SaveGame.VERSION,
		"the save keeps which WayLamps are lit (Progress.settled), same version %d" % SaveGame.VERSION)
	check(data["progress"]["cleared"].has(ClimbStones.ID), "and that the old climb's stones are down")
	Progress.settled = {}
	check(menu.lit_waylamps().is_empty(), "(lit WayLamps forgotten in memory)")
	check(SaveGame.load_into(main), "loaded")
	check(menu.lit_waylamps().size() == 2, "the travel network comes back from the save")

## A new world from the save: the stones open on load. Then an older save, from before the loop.
func _reload_check() -> void:
	main.queue_free()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _reload_result() -> void:
	menu = get_tree().get_first_node_in_group("travel_menu")
	main.climb_stones._process(0.0)
	check(main.loaded_save and main.climb_stones.is_open and main.fog.terrain_of(main.climb_stones.tiles[0]) == FogGrid.T_GROUND, "a reloaded world has the old climb open")
	check(menu.lit_waylamps().size() == 2, "and both lit WayLamps to travel between")
	# An older save (before the loop): no stones entry. It still loads, with the stones down.
	var f := FileAccess.open(SaveGame.path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	f.close()
	data["progress"]["cleared"].erase(ClimbStones.ID)
	var w := FileAccess.open(SaveGame.path, FileAccess.WRITE)
	w.store_string(JSON.stringify(data))
	w.close()
	var fresh: Node = load("res://scenes/main/main.tscn").instantiate()
	main.queue_free()
	main = fresh
	add_child(main)
	main.climb_stones._process(0.0)
	check(main.loaded_save and not main.climb_stones.is_open and main.fog.terrain_of(main.climb_stones.tiles[0]) == FogGrid.T_ROCK, "an older save loads too (no version bump), with the stones still down")
