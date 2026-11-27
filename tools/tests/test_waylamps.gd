extends Node
## WayLamps and the new light rules (PROTOTYPE): reach, feed, kindle under attack, the region is
## held; healthy light pushes Wicklings back; only a dying lantern out on its own can be drained. Run:
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
var near: Lantern            # a Hollow lantern whose light reaches the Hollow's WayLamp
var old_lamp: Lantern        # the cold lantern by the hut
var swarm: Array = []
var marsh_a: Lantern         # healthy, in the marsh
var marsh_guarded: Lantern   # dying, but inside marsh_a's light
var marsh_alone: Lantern     # dying, out on its own
var w_repel: Wickling
var w_drain: Wickling
var w_guard: Wickling
var w_healthy: Wickling
var w_fade: Wickling
var embers_before := 0
var alone_before := 0.0
var guarded_before := 0.0
var healthy_before := 0.0

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

func _lamp(p: Vector2, fuel: float) -> Lantern:
	var l := Lantern.new()
	l.kind = "post"
	l.fuel = fuel
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
			Tuning.lantern_burn_per_sec = 0.0   # isolate Wickling drain
			old_lamp = main.get_node("Lanterns").get_child(0)
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
			hollow.guardian_fight = false  # exercise the legacy hold/swarm mechanics; boss behavior has its own prototype test
			check(not hollow.is_lit() and not hollow.kindling, "a WayLamp starts cold")
			check(fog.tile_of(hollow.global_position).distance_to(fog.tile_of(main.start)) > 20.0, "the Hollow's WayLamp is well away from the hut (%.0f tiles)" % fog.tile_of(hollow.global_position).distance_to(fog.tile_of(main.start)))
			check(wp.lines_for(hollow)[0][1] == "Look closer", "the first prompt is 'Look closer'")
			player.global_position = hollow.global_position + Vector2(0, 30)
			Inventory.counts["fuel"] = 20
			check(hollow.feed() == "read" and get_tree().paused, "the first interaction reads it (and pauses the world)")
			main.get_node("NoteReader").close()
			check(Progress.notes_read.has("waylamp_hollow") and Story.tips_seen.has("waylamp_seen"), "it is remembered as read, with a tip")
			check(String(wp.lines_for(hollow)[0][1]).begins_with("Feed fuel"), "then it offers to take fuel straight away: no lantern needed")
			var hp := hollow.global_position
			var spot := _spot(FogGrid.R_HOLLOW, func(p: Vector2) -> bool:
				var d := p.distance_to(hp)
				return d > Tuning.waylamp_clear_radius + 8.0 and d < 200.0 and p.y > hp.y)   # south of it, away from the Ridge
			check(spot != Vector2.INF, "found a spot to light it from")
			near = _lamp(spot, Tuning.lantern_max_fuel)
		4:
			check(String(wp.lines_for(hollow)[0][1]).begins_with("Feed fuel"), "then the prompt offers to feed it (%s)" % str(wp.lines_for(hollow)))
			Inventory.counts["fuel"] = 10
			check(hollow.feed() == "fed" and hollow.fuel_units() == 10 and Inventory.get_count("fuel") == 0, "feeding pours in what you carry (10 / %d)" % Tuning.waylamp_fuel_need)
			check(hollow.feed() == "no_fuel", "with nothing carried, nothing to pour")
			check(not hollow.kindling, "half fed, it waits (fuel stays in it)")
			Inventory.counts["fuel"] = 20
			check(hollow.feed() == "fed" and hollow.fuel_units() == Tuning.waylamp_fuel_need and Inventory.get_count("fuel") == 15, "it only takes what it still needs")
			check(hollow.kindling, "full, it starts to kindle")
			swarm = _bold()
			check(swarm.size() == Tuning.waylamp_swarm and swarm.all(func(w): return w.target == hollow), "kindling draws a bold swarm to it (%d)" % swarm.size())
			check(hollow.feed() == "kindling", "feeding while it kindles does nothing more")
			var items: Array = hud.status_items()
			check(items.any(func(it): return String(it[1]).begins_with("Kindling")), "the HUD counts the kindling down")
			check(Story.tips_seen.has("kindle_attack"), "with a tip: ward them off")
			# Two of the swarm reach it; the others are already gone.
			swarm[0].global_position = hollow.global_position + Vector2(8, 0)
			swarm[1].global_position = hollow.global_position + Vector2(-8, 0)
			for i in range(2, swarm.size()):
				swarm[i].queue_free()
			hollow.kindle_t = 1.0
		40:
			check(hollow.kindling and hollow.kindle_t < 1.0, "Wicklings on a kindling WayLamp undo it (kindled %.2f s, was 1.00)" % hollow.kindle_t)
			check(is_instance_valid(swarm[0]) and swarm[0].state == Wickling.State.SNUFF, "a bold Wickling sits on it, ignoring the lantern's push")
			for w in get_tree().get_nodes_in_group("wickling"):
				w.queue_free()   # (the ward's own test lives in test_threats)
			near.fuel = 50.0
			# No building right up against it, so no lantern's bright core can guard it for you.
			var blocked_by_waylamp := false
			var hc := fog.tile_of(hollow.global_position)
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					if player.place_block_reason(fog.tile_center(hc + Vector2i(dx, dy))) == "too close to the WayLamp":
						blocked_by_waylamp = true
			check(blocked_by_waylamp, "no building right next to a WayLamp")
		260:
			check(Progress.is_settled(FogGrid.R_HOLLOW) and hollow.is_lit() and not hollow.kindling, "kept clear, it catches: the Hollow is held")
			check(near.fuel == near.max_fuel() and old_lamp.is_lit(), "every lantern in the region is refilled, even cold ones")
			Tuning.lantern_burn_per_sec = 0.5
			check(near.is_held() and near.burn_rate() == 0.0, "held lanterns don't burn down")
			check(hollow.get_light_radius() == Tuning.waylamp_radius, "a lit WayLamp throws a wide light")
			for i in 40:
				fog.step(0.1)
			var other_lit := 0
			var hc := fog.tile_of(hollow.global_position)
			var reach := int(Tuning.waylamp_radius / FogGrid.TILE)
			for y in range(hc.y - reach, hc.y + reach + 1):
				for x in range(hc.x - reach, hc.x + reach + 1):
					var t := Vector2i(x, y)
					if not fog.in_bounds(t) or fog.region[fog.idx(t)] in [0, FogGrid.R_HOLLOW] or fog._light[fog.idx(t)] <= 0.0:
						continue
					var by_lantern := false
					for l in get_tree().get_nodes_in_group("lantern"):
						if fog.tile_center(t).distance_to(l.global_position) < l.get_light_radius() + FogGrid.TILE:
							by_lantern = true
					if not by_lantern:
						other_lit += 1
			check(other_lit == 0, "a WayLamp's light only clears its own region (%d tiles elsewhere)" % other_lit)
			var lit_lines: Array = wp.lines_for(hollow)
			check(hollow.feed() == "held" and lit_lines.any(func(ln): return String(ln[1]).contains("held")), "and says its region is held")
			check(lit_lines.any(func(ln): return String(ln[1]) == "Travel" or String(ln[1]).begins_with("Can't travel")), "and offers fast travel, or says why not (%s)" % str(lit_lines))
			check(hud.banner.text == "The Hollow is held", "a banner says so (%s)" % hud.banner.text)
			var held_msg := "The WayLamp took. Its lanterns won't burn down now, and nothing comes here."
			check(hud.tip.text == held_msg or hud._tips.has(held_msg), "and a queued line explains what held means (not overwritten by the goal toast)")
			check(Story.entries.has(13), "the journal gets 'The first WayLamp'")
			near.fuel = 10.0   # even low, a held lantern needs nothing
			check(not main.get_node("FogLayer/LanternMarkers").needs_attention().has(near), "held lanterns never need you, so no edge marker")
			near.fuel = near.max_fuel()
			# Nothing new comes into a held region.
			var into_held := 0
			for i in 25:
				var w = spawner.spawn_near_player()
				if w != null:
					if Progress.is_settled(fog.region_at(w.global_position)):
						into_held += 1
					w.queue_free()
			check(into_held == 0, "Wicklings never spawn in a held region")
			embers_before = get_tree().get_nodes_in_group("ember").size()
			w_fade = spawner.spawn_at(hollow.global_position + Vector2(0, 120))
			# The marsh is not held: set up the light rules there.
			var a := _spot(FogGrid.R_MARSH, func(p: Vector2) -> bool:
				return p.distance_to(hollow.global_position) > 900.0)
			marsh_a = _lamp(a, Tuning.lantern_max_fuel)
			var g := _spot(FogGrid.R_MARSH, func(p: Vector2) -> bool:
				var d := p.distance_to(a)
				return d > 90.0 and d < 130.0)
			marsh_guarded = _lamp(g, 20.0)
			var lone := _spot(FogGrid.R_MARSH, func(p: Vector2) -> bool:
				return p.distance_to(a) > 700.0 and p.distance_to(hollow.global_position) > 900.0)
			marsh_alone = _lamp(lone, 20.0)
			check(a != Vector2.INF and g != Vector2.INF and lone != Vector2.INF, "found marsh spots for the light checks")
			player.global_position = hollow.global_position + Vector2(0, 40)   # safe, far from the marsh
		262:
			check(marsh_guarded.is_dying() and marsh_alone.is_dying() and not marsh_a.is_dying(), "under a quarter of its tank a lantern is dying")
			check(not marsh_a.is_held() and marsh_a.burn_rate() > 0.0, "lanterns in a region that isn't held still burn")
			Tuning.lantern_burn_per_sec = 0.0
			var r: float = marsh_a.get_light_radius()
			w_repel = spawner.spawn_at(marsh_a.global_position + Vector2(r * 0.5, 0))   # inside, but outside the core
			w_repel.timid = true   # (about half are; this check is about the timid ones)
			w_healthy = spawner.spawn_at(marsh_a.global_position + Vector2(0, -r * 0.9))
			w_healthy.target = marsh_a
			w_healthy.state = Wickling.State.SEEK_LANTERN
			var rd: float = marsh_alone.get_light_radius()
			w_drain = spawner.spawn_at(marsh_alone.global_position + Vector2(0, rd * 0.85))
			w_drain.target = marsh_alone
			w_drain.state = Wickling.State.SEEK_LANTERN
			var out := (marsh_guarded.global_position - marsh_a.global_position).normalized()
			w_guard = spawner.spawn_at(marsh_a.global_position + out * (r + 20.0))
			check(w_guard._find_prey(4000.0) != marsh_guarded, "a dying lantern inside healthy light isn't prey")
			w_guard.target = marsh_guarded
			w_guard.state = Wickling.State.SEEK_LANTERN
			alone_before = marsh_alone.fuel
			guarded_before = marsh_guarded.fuel
			healthy_before = marsh_a.fuel
		352:
			check(not is_instance_valid(w_fade) and get_tree().get_nodes_in_group("ember").size() == embers_before, "a Wickling in a held region fades away (no drops)")
			check(is_instance_valid(w_repel) and w_repel.healthy_level_at(w_repel.global_position) < 0.03, "healthy light pushes a Wickling back out into the dark (%.2f)" % (w_repel.healthy_level_at(w_repel.global_position) if is_instance_valid(w_repel) else -1.0))
			check(marsh_alone.fuel < alone_before - 4.0, "a dying lantern out on its own gets drained (%.0f -> %.0f)" % [alone_before, marsh_alone.fuel])
			check(marsh_guarded.fuel == guarded_before, "a dying lantern inside healthy light is safe (%.0f -> %.0f)" % [guarded_before, marsh_guarded.fuel])
			check(marsh_a.fuel == healthy_before, "a healthy lantern can't be drained (%.1f -> %.1f)" % [healthy_before, marsh_a.fuel])
			check(is_instance_valid(w_guard) and w_guard.target != marsh_guarded, "a Wickling gives up on a dying lantern that healthy light covers")
		420:
			check(is_instance_valid(w_repel) and w_repel.healthy_level_at(w_repel.global_position) < 0.03, "and it stays out at the edge")
			# Save: the held region and fuel fed to another WayLamp come back.
			Progress.notes_read["waylamp_marsh"] = true
			Progress.waylamp_fuel["marsh"] = 7
			check(SaveGame.save(main), "save with a held region")
			Progress.settled = {}
			Progress.waylamp_fuel = {}
			Story.reset()
			main.queue_free()
		424:
			main = load("res://scenes/main/main.tscn").instantiate()
			add_child(main)
		428:
			fog = main.fog
			check(Progress.is_settled(FogGrid.R_HOLLOW) and _waylamp("hollow").is_lit(), "the held Hollow comes back after loading")
			check(_waylamp("marsh").fuel_units() == 7 and not _waylamp("marsh").kindling, "fuel fed to an unfinished WayLamp comes back (%d)" % _waylamp("marsh").fuel_units())
			var held_lamps := get_tree().get_nodes_in_group("lantern").filter(func(l): return l.needs_fuel() and fog.region_at(l.global_position) == FogGrid.R_HOLLOW)
			check(held_lamps.size() >= 2 and held_lamps.all(func(l): return l.is_held()), "and its lanterns are still held (%d)" % held_lamps.size())
			check(not Progress.is_settled(FogGrid.R_MARSH), "other regions stay unheld")
			SaveGame.delete_save()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
