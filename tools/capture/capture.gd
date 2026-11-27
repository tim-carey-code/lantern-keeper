extends Node
## Visual check without a screen: loads the game, sets up a view, runs a few
## seconds, and lets Godot's movie writer record frames. Run on a virtual display:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --audio-driver Dummy \
##     --write-movie ~/.cache/openclaw/project-scratch/shots/frame.png --fixed-fps 30 \
##     res://tools/capture/capture.tscn -- start
## Views (after "--"): lanterns, start, marsh, cold, edge, wick, drops, ridge, map, journal, opening, opening_name, opening_letter, waylamp_kindle, waylamp_held, upgrade, kl_combat, pause. The last frame is the one to look at.
## README views (staged, pop-ups hidden; rendered by tools/capture/readme_shots.sh): readme_hollow, readme_ward,
## readme_marsh, readme_ridge, readme_map, readme_lanterns, readme_relight (an animation: use every frame).

var main: Node
var frame := 0
var view := "start"
var end_frame := 45

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames while the opening/journal pauses the world
	# Ignore any real controller on this PC.
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		view = args[0]
	Story.skip_opening = not view.begins_with("opening")
	if view == "readme_relight":
		end_frame = 110
	SaveGame.path = "user://test_ignore_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _lantern(p: Vector2, kind: String = "post", fuel: float = -1.0) -> Lantern:
	var l := Lantern.new()
	l.kind = kind
	l.fuel = fuel
	l.position = main.fog.tile_center(main.fog.tile_of(p))
	main.get_node("Lanterns").add_child(l)
	return l

func _process(_delta: float) -> void:
	frame += 1
	if frame == 2:
		var wind: Wind = main.get_node("Wind")
		wind.force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
		var s: Vector2 = main.start
		match view:
			"marsh":
				var pump: Vector2 = main.fog.tile_center(Vector2i(100, 68))
				main.player.position = pump + Vector2(-40, 40)
				_lantern(main.fog.tile_center(Vector2i(92, 68)))
				_lantern(main.fog.tile_center(Vector2i(97, 68)), "reservoir")
				_lantern(main.fog.tile_center(Vector2i(88, 72)))
			"cold":
				_lantern(s + Vector2(-160, 64), "post", 0.0)
				_lantern(s + Vector2(200, 120), "post", 10.0)
				main.player.position = s + Vector2(-40, 60)
			"edge":
				main.player.position = main.fog.tile_center(Vector2i(8, 68))
				_lantern(main.fog.tile_center(Vector2i(9, 66)))
			"wick":
				var l := _lantern(s + Vector2(-200, 40))
				var sp = main.get_node("FogLayer/Wicklings")
				for a in [0.3, 2.2, 4.0]:
					var w = sp.spawn_at(l.global_position + Vector2.from_angle(a) * l.get_light_radius() * 0.9)
					w.target = l
					w.state = Wickling.State.SEEK_LANTERN
				var c = sp.spawn_at(s + Vector2(170, -60))
				main.player.position = s + Vector2(110, -20)
				Inventory.counts["fuel"] = 5
			"drops":
				main.player.position = s + Vector2(0, 260)
				var sp2 = main.get_node("FogLayer/Wicklings")
				Tuning.wick_scrap_chance = 1.0
				for off in [Vector2(-90, 0), Vector2(90, 30)]:
					var w2 = sp2.spawn_at(main.player.position + off)
					w2.hurt(99.0)
			"ridge":
				var f: FogGrid = main.fog
				var c := f.tile_center(Vector2i(34, 17))
				main.player.position = c + Vector2(-40, 40)
				var src := _lantern(c + Vector2(-160, 0), "hooded")
				var m := _lantern(c + Vector2(-60, 0), "mirror")
				m.mirror_dir = 0
				_lantern(c + Vector2(40, 96))
				Progress.unlock("hooded")
				Progress.unlock("mirror")
			"waylamp_kindle", "waylamp_held":
				var wl: WayLamp = null
				for w in get_tree().get_nodes_in_group("waylamp"):
					if w.id == "hollow":
						wl = w
				Progress.notes_read["waylamp_hollow"] = true
				_lantern(wl.global_position + Vector2(-176, 30))
				if view == "waylamp_held":
					_lantern(wl.global_position + Vector2(-300, 220))
					_lantern(wl.global_position + Vector2(-60, 330))
					main.player.position = wl.global_position + Vector2(-50, 70)
				else:
					main.player.position = wl.global_position + Vector2(46, 44)
					Progress.waylamp_fuel["hollow"] = Tuning.waylamp_fuel_need
					wl.start_kindling()
					wl.kindle_t = Tuning.waylamp_kindle_sec * 0.45
					var k := 0
					for w in get_tree().get_nodes_in_group("wickling"):
						w.global_position = wl.global_position + Vector2.from_angle(0.6 + k * 1.7) * (40.0 + 34.0 * k)
						k += 1
			"readme_hollow", "readme_ward", "readme_marsh", "readme_ridge", "readme_map", "readme_lanterns", "readme_relight":
				_readme_setup()
			"upgrade":
				for m in get_tree().get_nodes_in_group("landmark"):
					if m.id == "satchel_hollow":
						_lantern(m.global_position + Vector2(120, 40))
						main.player.position = m.global_position + Vector2(30, 20)
					if m.id == "lampglass_hollow":
						_lantern(m.global_position + Vector2(-90, -30))
			"kl_combat":
				_lantern(s + Vector2(-260, 60))
				main.player.position = s + Vector2(-420, 120)
				var sp3 = main.get_node("FogLayer/Wicklings")
				var e = sp3.spawn_at(main.player.position + Vector2(170, -30), true)
				e.state = Wickling.State.CHASE
				for off in [Vector2(120, 50), Vector2(200, 70), Vector2(-90, 40)]:
					var w4 = sp3.spawn_at(main.player.position + off)
					w4.state = Wickling.State.CHASE
				main.player.combat.aim_override = Vector2(170, -20)
			"map":
				_lantern(s + Vector2(-160, 64))
				for i in 60:
					main.fog.step(0.1)
			"start_nohud":
				_lantern(s + Vector2(-140, 90))
				_lantern(s + Vector2(60, 150))
				main.player.position = s + Vector2(-20, 30)
			_:
				_lantern(s + Vector2(-140, 90))
				_lantern(s + Vector2(60, 150))
				main.player.position = s + Vector2(-20, 30)
		if view != "readme_relight":
			for i in 30:
				main.fog.step(0.1)   # let the light push the fog back before the shot
	if frame == 4 and view == "waylamp_held":
		Progress.settle(FogGrid.R_HOLLOW, "The Hollow")   # after the Hollow's own banner
		for i in 30:
			main.fog.step(0.1)
	if frame >= 30 and view in ["wick", "waylamp_kindle"]:
		main.player.update_ward(1.0 / 30.0, true)
	if view == "kl_combat" and frame == 8:
		Input.action_press("beam")
	if view == "kl_combat" and frame == 36:
		main.player.combat.burst()
	if frame == 6 and view == "map":
		main.get_node("MapScreen").toggle()
	if frame == 6 and view == "pause":
		main.get_node("PauseMenu").open()
	# Opening views: step through to the page we want to see.
	if view == "opening_name" and frame == 5:
		main.get_node("Opening")._next()
		main.get_node("Opening").name_box.text = "Tess"
	if view == "opening_letter" and frame == 5:
		var o = main.get_node("Opening")
		o._next()
		o.name_box.text = "Tess"
		o._next()
	if view == "journal" and frame == 30:
		Story.player_name = "Tess"
		Inventory.counts["fuel"] = 2
		Story.update(main)
		for id in ["ledger", "stone_way"]:
			for m in get_tree().get_nodes_in_group("landmark"):
				if m.id == id:
					Progress.notes_read[id] = true
		Story.update(main)
		main.get_node("Journal").toggle()
		main.get_node("Journal").page = 1
		main.get_node("Journal").refresh()
	if view in ["lanterns", "readme_lanterns"] and frame == 30:
		for k in ["reservoir", "hooded"]:
			Progress.unlock(k)
		Inventory.counts["scrap"] = 6
		Inventory.counts["glass"] = 1
		Progress.selected = "reservoir"
		main.get_node("BuildMenu").open()
	if view == "start_nohud" and frame == 3:
		main.get_node("HUD").visible = false
	if view.begins_with("readme") and frame >= 3:
		var hud = main.get_node("HUD")
		hud.banner.visible = false   # no region banners, toasts or tips in README shots
		hud.toast.visible = false
		hud.tip.visible = false
		if view != "readme_hollow":
			main.get_node("FogLayer/WorldPrompt").visible = false
	if view == "readme_ward" and frame >= 30:
		main.player.update_ward(1.0 / 30.0, true)
	if view == "readme_map" and frame == 6:
		main.get_node("MapScreen").toggle()
	if view == "readme_relight" and frame == 30:
		main.player.refuel(main.get_node("Lanterns").get_child(0))
	if frame >= end_frame:
		get_tree().quit()

## Marks every goal before this one done, so the HUD shows a goal that fits the shot.
func _goals_done_until(goal_id: String) -> void:
	for g in Story.GOALS:
		if g["id"] == goal_id:
			break
		Story.done[g["id"]] = true
	Story.update(main)

## Staged scenes for the README screenshots.
func _readme_setup() -> void:
	var f: FogGrid = main.fog
	var s: Vector2 = main.start
	var sp = main.get_node("FogLayer/Wicklings")
	var old: Lantern = main.get_node("Lanterns").get_child(0)
	Story.player_name = "Tess"
	for k in Story.TIPS:
		Story.tips_seen[k] = true
	if view != "readme_hollow":
		Story.pointer_mode = "off"
	match view:
		"readme_hollow":
			old.fuel = Tuning.lantern_max_fuel
			_lantern(s + Vector2(-250, 150))
			_lantern(s + Vector2(230, 230))
			_lantern(s + Vector2(-20, 300))
			Inventory.counts["fuel"] = 12
			Inventory.counts["scrap"] = 7
			Progress.notes_read["ledger"] = true
			Story.note_built("post")
			Inventory.counts["fuel"] = 12
			main.player.position = s + Vector2(70, 120)
			for p in [s + Vector2(-560, 260), s + Vector2(540, 60), s + Vector2(330, 540)]:
				sp.spawn_at(p)
			Story.update(main)
		"readme_ward":
			old.fuel = Tuning.lantern_max_fuel
			_lantern(s + Vector2(-240, 90))
			main.player.position = s + Vector2(60, 230)
			for off in [Vector2(80, -30), Vector2(-70, 40), Vector2(60, 75), Vector2(-20, -85)]:
				var w = sp.spawn_at(main.player.position + off)
				w.state = Wickling.State.CHASE
			Inventory.counts["fuel"] = 4
			Inventory.counts["scrap"] = 3
			_goals_done_until("build_post")
		"readme_marsh":
			for t in [Vector2i(80, 68), Vector2i(86, 68), Vector2i(92, 68), Vector2i(88, 73)]:
				_lantern(f.tile_center(t))
			_lantern(f.tile_center(Vector2i(97, 68)), "reservoir")
			Progress.unlock("reservoir")
			old.fuel = Tuning.lantern_max_fuel
			main.player.position = f.tile_center(Vector2i(89, 68))
			Inventory.counts["fuel"] = 9
			Inventory.counts["scrap"] = 4
			_goals_done_until("climb_north")   # the pump is awake, so the Reservoir Lamp is unlocked
		"readme_ridge":
			var c := f.tile_center(Vector2i(34, 17))
			main.player.position = c + Vector2(-20, 60)
			_lantern(c + Vector2(-160, 0), "hooded")
			var m := _lantern(c + Vector2(-60, 0), "mirror")
			m.mirror_dir = 0
			var m2 := _lantern(c + Vector2(230, 0), "mirror")
			m2.mirror_dir = 2
			_lantern(c + Vector2(60, 120), "hooded")
			Progress.unlock("reservoir")
			Progress.unlock("hooded")
			Progress.unlock("mirror")
			Inventory.counts["glass"] = 3
			Inventory.counts["scrap"] = 6
			old.fuel = Tuning.lantern_max_fuel
			_goals_done_until("descend")
		"readme_map":
			for i in f.remembered.size():
				var reg: int = f.region[i]
				if reg == FogGrid.R_HOLLOW or reg == FogGrid.R_MARSH or (reg == FogGrid.R_RIDGE and i / f.cols > 18):
					f.remembered[i] = 1
					f.density[i] = minf(f.density[i], 0.7)
			old.fuel = Tuning.lantern_max_fuel
			for t in [Vector2i(36, 66), Vector2i(44, 68), Vector2i(52, 67), Vector2i(60, 68), Vector2i(70, 68), Vector2i(80, 68), Vector2i(92, 68), Vector2i(24, 52), Vector2i(30, 30)]:
				_lantern(f.tile_center(t))
			_lantern(f.tile_center(Vector2i(97, 68)), "reservoir")
			_lantern(f.tile_center(Vector2i(86, 76)), "post", 12.0)
			_lantern(f.tile_center(Vector2i(40, 26)), "post", 0.0)
			for r in [FogGrid.R_HOLLOW, FogGrid.R_MARSH, FogGrid.R_RIDGE]:
				Progress.reveal_region(r, FogGrid.REGION_NAMES[r])
			main.player.position = f.tile_center(Vector2i(60, 68))
		"readme_lanterns":
			old.fuel = Tuning.lantern_max_fuel
			_lantern(s + Vector2(-140, 90))
			_lantern(s + Vector2(60, 150))
			main.player.position = s + Vector2(-20, 30)
			_goals_done_until("build_post")
		"readme_relight":
			main.player.position = old.global_position + Vector2(-34, 44)
			Inventory.counts["fuel"] = 10
