extends Node
## Save/load round trip. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_save.tscn

var main: Node
var frame := 0
var fails := 0
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

func _ready() -> void:
	strip_real_input()
	Tuning.wick_enabled = false
	Story.skip_opening = true
	SaveGame.path = "user://test_save.json"
	SaveGame.delete_save()
	_new_main()

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			check(not main.loaded_save, "a fresh start has no save to load")
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
		128:
			check(main.loaded_save, "starting the game loads the save")
			var lamps := get_tree().get_nodes_in_group("lantern")
			var found = lamps.filter(func(x): return x.position == lamp_pos)
			check(lamps.size() == 2 and found.size() == 1, "lanterns come back (%d)" % lamps.size())
			if found.size() == 1:
				check(found[0].kind == "reservoir" and absf(found[0].fuel - 77.0) < 2.0, "with their type and fuel (%.1f)" % found[0].fuel)
			check(Inventory.get_count("fuel") == 12 and Inventory.get_count("scrap") == 7, "inventory comes back")
			check(Progress.is_unlocked("reservoir") and Progress.selected == "reservoir", "unlocks and selected lantern come back")
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
			# New game: delete and skip.
			SaveGame.delete_save()
			check(not SaveGame.has_save(), "new game deletes the save")
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
