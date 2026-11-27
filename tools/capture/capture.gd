extends Node
## Visual check without a screen: loads the game, sets up a view, runs a few
## seconds, and lets Godot's movie writer record frames. Run on a virtual display:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --audio-driver Dummy \
##     --write-movie ~/.cache/openclaw/project-scratch/shots/frame.png --fixed-fps 30 \
##     res://tools/capture/capture.tscn -- start
## Views (after "--"): lanterns, start, marsh, cold, edge, wick, drops, ridge, map, journal, opening, opening_name, opening_letter, waylamp_kindle, waylamp_held. The last frame is the one to look at.

var main: Node
var frame := 0
var view := "start"

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
		for i in 30:
			main.fog.step(0.1)   # let the light push the fog back before the shot
	if frame == 4 and view == "waylamp_held":
		Progress.settle(FogGrid.R_HOLLOW, "The Hollow")   # after the Hollow's own banner
		for i in 30:
			main.fog.step(0.1)
	if frame >= 30 and view in ["wick", "waylamp_kindle"]:
		main.player.update_ward(1.0 / 30.0, true)
	if frame == 6 and view == "map":
		main.get_node("MapScreen").toggle()
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
	if view == "lanterns" and frame == 30:
		for k in ["reservoir", "hooded"]:
			Progress.unlock(k)
		Inventory.counts["scrap"] = 6
		Inventory.counts["glass"] = 1
		Progress.selected = "reservoir"
		main.get_node("BuildMenu").open()
	if view == "start_nohud" and frame == 3:
		main.get_node("HUD").visible = false
	if frame >= 45:
		get_tree().quit()
