extends Node
## WayLamps (M1b, GAME_PLAN §6, §12): lit by touch, no fuel. The Hollow's wakes the Ashbrood, which broods over
## the WayLamp's last ember; its kill takes the ember back (it rises into the lamp as it lights) and holds the
## Hollow. The others are hold fights until their guardians come (M5-M6): kindle under attack, then the region is
## held. Healthy light pushes Wicklings back; nothing is drained. Held regions and lit old lamps survive a save. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_waylamps.tscn

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var spawner: Node
var hud: Node
var wp: Node
var hollow: WayLamp
var marsh: WayLamp
var swarm: Array = []
var ridge_lamp: Lantern
var w_repel: Wickling
var w_fade: Wickling
var brood: Ashbrood
var embers_before := 0

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
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when a note pauses the world
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
	SaveGame.path = "user://test_waylamps_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	Tuning.waylamp_kindle_sec = 3.0   # keep the test short
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	Progress.unlock("post")

func _waylamp(id: String) -> WayLamp:
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.id == id:
			return w
	return null

func _lamp(p: Vector2) -> Lantern:
	var l := Lantern.new()
	l.kind = "post"
	l.position = fog.tile_center(fog.tile_of(p))
	main.get_node("Lanterns").add_child(l)
	return l

## The first open ground or boardwalk tile of a region that passes a test.
func _spot(region_id: int, pred: Callable) -> Vector2:
	for y in fog.rows:
		for x in fog.cols:
			var t := Vector2i(x, y)
			var i := fog.idx(t)
			if fog.solid[i] == 1 or fog.region[i] != region_id:
				continue
			var ter := fog.terrain_of(t)
			if ter != FogGrid.T_GROUND and ter != FogGrid.T_BOARDWALK:
				continue
			var p := fog.tile_center(t)
			if pred.call(p):
				return p
	return Vector2.INF

func _bold() -> Array:
	return get_tree().get_nodes_in_group("wickling").filter(func(w): return w.bold and not w.is_queued_for_deletion())

func _old_lamp(at: Vector2) -> Lantern:
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.global_position.distance_to(at) < 8.0:
			return l
	return null

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			spawner = main.get_node("FogLayer/Wicklings")
			hud = main.get_node("HUD")
			wp = main.get_node("FogLayer/WorldPrompt")
			InputHint.pad = false
			main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			# One WayLamp per region, standing in its region.
			var ids := {}
			var placed_ok := true
			for w in get_tree().get_nodes_in_group("waylamp"):
				ids[w.id] = true
				if fog.region_at(w.global_position) != w.region_id:
					placed_ok = false
			check(ids.size() == 3 and ids.has("hollow") and ids.has("marsh") and ids.has("ridge"), "three WayLamps: Hollow, Reedmarsh, Ridge (%s)" % str(ids.keys()))
			check(placed_ok, "each WayLamp stands in its own region")
			hollow = _waylamp("hollow")
			marsh = _waylamp("marsh")
			check(hollow.guardian_fight and not marsh.guardian_fight, "the Hollow's WayLamp has a guardian; the others are hold fights for now")
			check(not hollow.is_lit() and not hollow.kindling, "a WayLamp starts cold")
			check(fog.tile_of(hollow.global_position).distance_to(fog.tile_of(main.start)) > 20.0, "the Hollow's WayLamp is well away from the hut (%.0f tiles)" % fog.tile_of(hollow.global_position).distance_to(fog.tile_of(main.start)))
			check(wp.lines_for(hollow)[0][1] == "Look closer", "the first prompt is 'Look closer'")
			player.global_position = hollow.global_position + Vector2(0, 30)
			check(hollow.touch() == "read" and get_tree().paused, "the first touch reads it (and pauses the world)")
			var reader = main.get_node("NoteReader")
			check(reader.is_open() and not hollow.note_text().to_lower().contains("fuel") and hollow.note_text().contains(WayLamp.NOTE_TOUCH), "its note says to touch your flame to it, and nothing about fuel")
			reader.close()
			check(Progress.notes_read.has("waylamp_hollow") and Story.tips_seen.has("waylamp_seen"), "it is remembered as read, with a tip")
			check(wp.lines_for(hollow) == [[InputHint.key("interact"), "Light it"]], "then the prompt says Light it (%s)" % str(wp.lines_for(hollow)))
			check(not hollow.kindling and not hollow.is_lit(), "reading it doesn't light it")
			# A hold fight: the Reedmarsh's WayLamp, lit by touch.
			Progress.notes_read["waylamp_marsh"] = true
			player.global_position = marsh.global_position + Vector2(0, 30)
			player.begin_interact()
			check(player.last_touch == "lit" and marsh.kindling, "a touch lights a WayLamp: it starts to kindle (no fuel)")
		4:
			swarm = _bold()
			check(swarm.size() == Tuning.waylamp_swarm and swarm.all(func(w): return w.target == marsh), "kindling draws a bold swarm to it (%d)" % swarm.size())
			check(marsh.touch() == "kindling", "touching it while it kindles does nothing more")
			var items: Array = hud.status_items()
			check(items.any(func(it): return String(it[1]).begins_with("Kindling")), "the HUD counts a hold fight down")
			check(Story.tips_seen.has("kindle_attack"), "with a tip")
			# Two of the swarm reach it; the others are already gone.
			swarm[0].global_position = marsh.global_position + Vector2(8, 0)
			swarm[1].global_position = marsh.global_position + Vector2(-8, 0)
			for i in range(2, swarm.size()):
				swarm[i].queue_free()
			marsh.kindle_t = 1.0
		40:
			check(marsh.kindling and marsh.kindle_t < 1.0, "Wicklings on a kindling WayLamp undo it (kindled %.2f s, was 1.00)" % marsh.kindle_t)
			check(is_instance_valid(swarm[0]) and swarm[0].state == Wickling.State.SNUFF, "a bold Wickling sits on it")
			for w in get_tree().get_nodes_in_group("wickling"):
				w.queue_free()
			# No building right up against it, so no lantern's bright core can guard it for you.
			var blocked_by_waylamp := false
			var hc := fog.tile_of(marsh.global_position)
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					if player.place_block_reason(fog.tile_center(hc + Vector2i(dx, dy))) == "too close to the WayLamp":
						blocked_by_waylamp = true
			check(blocked_by_waylamp, "no building right next to a WayLamp")
		260:
			check(Progress.is_settled(FogGrid.R_MARSH) and marsh.is_lit() and not marsh.kindling, "kept clear, it catches: the Reedmarsh is held")
			check(marsh.get_light_radius() == Tuning.waylamp_radius, "a lit WayLamp throws a wide light")
			for i in 40:
				fog.step(0.1)
			var other_lit := 0
			var hc := fog.tile_of(marsh.global_position)
			var reach := int(Tuning.waylamp_radius / FogGrid.TILE)
			for y in range(hc.y - reach, hc.y + reach + 1):
				for x in range(hc.x - reach, hc.x + reach + 1):
					var t := Vector2i(x, y)
					if not fog.in_bounds(t) or fog.region[fog.idx(t)] in [0, FogGrid.R_MARSH] or fog._light[fog.idx(t)] <= 0.0:
						continue
					other_lit += 1
			check(other_lit == 0, "a WayLamp's light only clears its own region (%d tiles elsewhere)" % other_lit)
			var lit_lines: Array = wp.lines_for(marsh)
			check(marsh.touch() == "held" and lit_lines.any(func(ln): return String(ln[1]).contains("held")), "and says its region is held")
			check(lit_lines.any(func(ln): return String(ln[1]) == "Rest or travel" or String(ln[1]).begins_with("Can't travel")), "and offers rest and travel, or says why not (%s)" % str(lit_lines))
			check(hud.banner.text == "The Reedmarsh is held", "a banner says so (%s)" % hud.banner.text)
			check(hud.tip.text == hud.HELD_TIP or hud._tips.has(hud.HELD_TIP), "and a queued line says what held means")
			check(not hud.HELD_TIP.contains("burn"), "which no longer talks about lamps burning down")
			check(Story.entries.has(14), "the journal gets 'The marsh WayLamp'")
			# Nothing new comes into a held region.
			var into_held := 0
			for i in 25:
				var w = spawner.spawn_near_player()
				if w != null:
					if Progress.is_settled(fog.region_at(w.global_position)):
						into_held += 1
					w.queue_free()
			check(into_held == 0, "Wicklings never spawn in a held region")
			embers_before = get_tree().get_nodes_in_group("ember").filter(func(e): return e.global_position.distance_to(marsh.global_position) < 400.0).size()
			w_fade = spawner.spawn_at(marsh.global_position + Vector2(0, 120))
			# The Hollow: a touch wakes the Ashbrood, which broods over the WayLamp's last ember.
			player.global_position = hollow.global_position + Vector2(0, 30)
			player.begin_interact()
			check(player.last_touch == "lit" and hollow.kindling and hollow.guardian_awake(), "a touch on the Hollow's WayLamp wakes its guardian")
			brood = hollow.guardian()
			check(brood != null and brood.level == Tuning.kl_ashbrood_level and brood.waylamp == hollow, "the Ashbrood, Lv %d" % Tuning.kl_ashbrood_level)
			check(not hud.status_items().any(func(it): return String(it[1]).begins_with("Kindling")), "a guardian fight has no kindling countdown")
			check(wp.lines_for(hollow) == [["", "Something broods over its last ember"]], "the prompt says what broods there (%s)" % str(wp.lines_for(hollow)))
			player.global_position = hollow.global_position + Vector2(0, 400)   # out of its reach
		262:
			var embers := get_tree().get_nodes_in_group("waylamp_ember")
			check(embers.size() == 1 and hollow.ember_showing() and hollow.ember_rise() == 0.0, "a small ember glows in the WayLamp's cold bowl under it")
			check(embers.size() == 1 and embers[0].get_parent() == spawner, "drawn over the fog, by the lamp (not by the creature)")
			# M1c (test_fights has the rest): one ember, at its feet on the sprite's own; no quest arrow; the rim lamp.
			check(WayLamp.EMBER_BOWL == Ashbrood.EMBER_AT, "M1c: the ember lies at the Ashbrood's feet, on the sprite's own bowl ember (one ember)")
			check(main.get_node("FogLayer/GoalPointer").target_pos() == null, "M1c: the quest arrow hides while the Ashbrood fights")
			var rim := _old_lamp(main.rim_lamp_pos)
			check(rim != null and rim.old and rim.global_position.distance_to(hollow.global_position) < Tuning.lantern_max_radius, "M1c: an old lamp on the bowl's rim, its light reaching the bowl")
			# Kill both phases.
			brood.end_phase_pause()
			brood.shell = 0.0
			brood.hurt(brood.hp + 1.0, false, "lance")
			brood.end_phase_pause()
			brood.shell = 0.0
			brood.hurt(brood.hp + 1.0, false, "lance")
		264:
			check(not is_instance_valid(brood) or brood.is_queued_for_deletion(), "the Ashbrood dies in its second phase")
			check(Progress.is_settled(FogGrid.R_HOLLOW) and hollow.is_lit(), "its kill holds the Hollow")
			check(hollow.ember_rise_t > 0.0 and get_tree().get_nodes_in_group("waylamp_ember").size() == 1, "the WayLamp takes its ember back: it rises into the lamp")
		300:
			check(hollow.ember_rise() > 0.3 and hollow.ember_rise() < 1.0, "the ember is still rising (%.2f)" % hollow.ember_rise())
		360:
			check(hollow.ember_rise_t <= 0.0 and get_tree().get_nodes_in_group("waylamp_ember").is_empty() and hollow.is_lit(), "then the lamp is lit and the ember is gone into it")
			check(Story.entries.has(13) and not Story.ENTRIES[13][1].contains("held the WayLamp"), "the journal gets 'The first WayLamp', about the ember")
			check(not is_instance_valid(w_fade) and get_tree().get_nodes_in_group("ember").filter(func(e): return e.global_position.distance_to(marsh.global_position) < 400.0).size() == embers_before, "a Wickling in a held region fades away (no drops)")
			# Healthy light pushes a timid Wickling back (on the Ridge, not held).
			var a := _spot(FogGrid.R_RIDGE, func(p: Vector2) -> bool: return p.distance_to(_waylamp("ridge").global_position) > 900.0)
			check(a != Vector2.INF, "found a Ridge spot for the light check")
			ridge_lamp = _lamp(a)
			var r: float = ridge_lamp.get_light_radius()
			w_repel = spawner.spawn_at(ridge_lamp.global_position + Vector2(r * 0.5, 0))   # inside, but outside the core
			w_repel.timid = true
		450:
			check(is_instance_valid(w_repel) and w_repel.healthy_level_at(w_repel.global_position) < 0.03, "healthy light pushes a Wickling back out into the dark (%.2f)" % (w_repel.healthy_level_at(w_repel.global_position) if is_instance_valid(w_repel) else -1.0))
			check(ridge_lamp.is_lit() and is_equal_approx(ridge_lamp.get_light_radius(), Tuning.lantern_max_radius), "and the lamp is untouched: nothing drains it")
			# Save: held regions, the old lamps' lit state.
			var hut := _old_lamp(main.start_lantern_pos)
			hut.light_by_touch()
			check(SaveGame.save(main), "save with two held regions")
			Progress.settled = {}
			Story.reset()
			main.queue_free()
		454:
			main = load("res://scenes/main/main.tscn").instantiate()
			add_child(main)
		458:
			fog = main.fog
			check(Progress.is_settled(FogGrid.R_HOLLOW) and _waylamp("hollow").is_lit() and Progress.is_settled(FogGrid.R_MARSH), "the held Hollow and Reedmarsh come back after loading")
			check(not Progress.is_settled(FogGrid.R_RIDGE) and not _waylamp("ridge").kindling, "the Ridge stays unheld")
			var hut := _old_lamp(main.start_lantern_pos)
			var waypost := _old_lamp(main.waypost_lantern_pos)
			check(hut != null and hut.old and hut.is_lit(), "a lit old lamp stays lit")
			check(waypost != null and waypost.old and waypost.can_light_by_touch(), "an old lamp not yet lit stays cold, still lit by touch")
			SaveGame.delete_save()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
