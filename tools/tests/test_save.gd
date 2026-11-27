extends Node
## Save/load round trip. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_save.tscn

var main: Node
var frame := 0
var fails := 0
var old_main_id := 0
var lamp_pos := Vector2.ZERO
var keeper_pos := Vector2.ZERO
var res_pos := Vector2.ZERO
var seen_before := 0

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _new_main() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	Progress.unlock("post")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when a note or menu pauses the world
	strip_real_input()
	Tuning.wick_enabled = false
	Story.skip_opening = true
	SaveGame.path = "user://test_save.json"
	SaveGame.delete_save()
	_new_main()

## The controller's A, as our "interact" action.
func _press_a() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			check(not main.loaded_save, "a fresh start has no save to load")
			var v4 := {"version": 4, "progress": {"level": 2}, "player": {"warmth": 73.0}}
			var v5: Dictionary = SaveGame.migrate_data(v4)
			check(v5.version == 5 and v5.progress.bar.skill_3 == "lance" and v5.progress.lance_given, "version 4 saves migrate to v5 with Lance on LB at level 2")
			check(v5.player.flasks == Tuning.kl_flask_max and v5.player.warmth == 73.0, "migration fills flasks and preserves the old keeper state")
		120:
			# Change everything a save should keep.
			var fog: FogGrid = main.fog
			lamp_pos = fog.tile_center(fog.tile_of(main.start + Vector2(-128, 96)))
			var l := Lantern.new()
			l.kind = "reservoir"
			l.position = lamp_pos
			l.fuel = 77.0
			main.get_node("Lanterns").add_child(l)
			Inventory.counts["fuel"] = 12
			Inventory.counts["scrap"] = 7
			Progress.unlock("reservoir")
			Progress.selected = "reservoir"
			Progress.wick = 7
			Progress.level = 2
			Progress.bar = {"skill_1": "lampfire", "skill_2": "fireglobe", "skill_3": "lance", "skill_4": ""}
			Progress.lance_given = true
			main.player.flasks = 2
			Progress.cleared["nest_hollow_1"] = true
			Progress.choose_combat_upgrade("long_throw")
			var wick_drop := WickDrop.new()
			wick_drop.amount = 4
			wick_drop.position = main.start + Vector2(160, 40)
			main.get_node("FogLayer/Wicklings").add_child(wick_drop)
			Progress.notes_read["ledger"] = true
			var r: ResourceNode = main.get_node("Resources").get_child(5)
			res_pos = r.position
			r.amount = 1
			main.drop_pile("scrap", main.start + Vector2(40, 40), 3)
			keeper_pos = main.start + Vector2(64, 32)
			main.player.global_position = keeper_pos
			main.player.warmth = 42.0
			main.player.lamp_charge = 0.5
			seen_before = fog.remembered.count(1)
			check(SaveGame.save(main), "saving writes the file")
			check(SaveGame.has_save(), "the save file exists")
		122:
			# Throw the world away and start again: it should come back from the save.
			main.queue_free()
			Inventory.reset()
			Progress.reset()
		124:
			_new_main()   # loads the save synchronously in _ready
			check(absf(main.player.warmth - 42.0) < 0.5 and absf(main.player.lamp_charge - 0.5) < 0.01, "warmth and hand lamp come back")
			check(main.player.flasks == 2 and Progress.bar.skill_3 == "lance", "the v5 action bar and flask count come back")
		128:
			check(main.loaded_save, "starting the game loads the save")
			var lamps := get_tree().get_nodes_in_group("lantern")
			var found = lamps.filter(func(x): return x.position == lamp_pos)
			check(lamps.size() == 3 and found.size() == 1, "lanterns come back: the two old lamps and the built one (%d)" % lamps.size())
			if found.size() == 1:
				check(found[0].kind == "reservoir" and absf(found[0].fuel - 77.0) < 2.0, "with their type and fuel (%.1f)" % found[0].fuel)
			check(Inventory.get_count("fuel") == 12 and Inventory.get_count("scrap") == 7, "inventory comes back")
			check(Progress.is_unlocked("reservoir") and Progress.selected == "reservoir", "unlocks and selected lantern come back")
			check(Progress.wick == 7 and Progress.level == 2 and Progress.cleared.has("nest_hollow_1"), "wick/level/cleared come back (%d/%d/%s)" % [Progress.wick, Progress.level, str(Progress.cleared)])
			check(Progress.has_combat_upgrade("long_throw"), "chosen combat upgrades come back")
			var wick_drops := get_tree().get_nodes_in_group("wick_drop")
			check(wick_drops.size() == 1 and wick_drops[0].amount == 4, "dropped wick comes back (%d)" % wick_drops.size())
			check(Progress.notes_read.has("ledger"), "notes read come back")
			var rs := get_tree().get_nodes_in_group("resource").filter(func(x): return x.position == res_pos)
			check(rs.size() == 1 and rs[0].amount == 1, "resource amounts come back")
			var piles := get_tree().get_nodes_in_group("resource").filter(func(x): return x.label == "Dropped scrap")
			check(piles.size() == 1 and piles[0].amount == 3, "dropped piles come back")
			check(main.player.global_position.distance_to(keeper_pos) < 2.0, "the keeper is where they were")
			check(main.fog.remembered.count(1) >= seen_before, "the map of what you've seen comes back")
			check(Progress.regions_seen.has(FogGrid.R_HOLLOW), "found regions come back")
			# Pause menu: the controller's A (our "interact") presses the focused button.
			var pm = main.get_node("PauseMenu")
			pm.open()
			check(pm.is_open() and get_tree().paused, "the pause menu opens and pauses the world")
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = true
			Input.parse_input_event(ev)
		130:
			var pm2 = main.get_node("PauseMenu")
			check(not pm2.is_open() and not get_tree().paused, "A / E chooses the focused option (Resume)")
			# New game with the controller: A on "New game", then A again. It reloads the game
			# scene, so make the game the current scene first (as when you play it).
			check(SaveGame.has_save(), "a save exists before the new game")
			main.reparent(get_tree().root)   # the current scene must be a child of the root
			get_tree().current_scene = main
			old_main_id = main.get_instance_id()
			pm2.open()
			pm2.buttons[2].grab_focus()
			_press_a()
		140:
			var pm3 = main.get_node("PauseMenu")
			check(pm3.buttons[2].text == "New game? Press again", "A on New game asks to confirm")
			_press_a()
		170:
			var cur := get_tree().current_scene
			check(cur != null and cur.get_instance_id() != old_main_id and cur.is_in_group("main"), "A again starts a new game: the game scene reloads")
			check(not get_tree().paused and not Tuning.ui_open, "the new game runs, unpaused")
			check(not SaveGame.has_save(), "new game deletes the save")
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
