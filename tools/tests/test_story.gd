extends Node
## Story and guidance: goals, pointer, journal, opening, tips, saving. Run:
##   timeout 120 godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_story.tscn

var main: Node
var frame := 0
var fails := 0
var lamp: Lantern
var ptr: Node

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
	Story.skip_opening = true
	Tuning.wick_enabled = false
	SaveGame.path = "user://test_story_save.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _landmark(id: String) -> Landmark:
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == id:
			return m
	return null

func _read(id: String) -> void:
	_landmark(id).activate()
	if id == "ledger":
		check(get_tree().paused, "reading a note pauses the world (no Wickling can hurt you)")
	main.get_node("NoteReader").close()
	if id == "ledger":
		check(not get_tree().paused, "closing the note resumes the world")

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			lamp = main.get_node("Lanterns").get_child(0)
			ptr = main.get_node("FogLayer/GoalPointer")
			main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			Story.update(main)
			check(Story.current == "gather_fuel", "first goal: take fuel from the woodpile (%s)" % Story.current)
			check(ptr.target_pos() != null, "the pointer points at the woodpile")
			check(Story.tips_seen.has("cold_lantern"), "the cold old lantern brings up the first tip")
			Inventory.counts["fuel"] = 2
			Story.update(main)
			check(Story.done.has("gather_fuel") and Story.current == "relight_first", "carrying fuel moves on to: relight the old lantern")
			check(ptr.target_pos() == main.start_lantern_pos, "the pointer moves to the old lantern")
			main.player.position = lamp.global_position + Vector2(0, 20)
			main.player.refuel(lamp)
			Story.update(main)
			check(Story.done.has("relight_first") and Story.entries.has(1), "relighting it completes the goal and writes 'Arrival'")
			check(Story.current == "read_ledger", "next: read the ledger")
			_read("ledger")
			Story.update(main)
			check(Story.done.has("read_ledger") and Story.entries.has(2), "reading the ledger writes the second entry")
			Story.note_built("post")
			_read("stone_way")
			Story.update(main)
			check(Story.current == "enter_marsh", "after building a lamp and reading the stone: go into the marsh (%s)" % Story.current)
			check(ptr.target_pos() != null, "the pointer is still on in the Hollow")
			# Walk into the marsh.
			main.player.global_position = main.fog.tile_center(Vector2i(60, 68))
			Story.update(main)
			check(Story.visited.has(FogGrid.R_MARSH) and Story.done.has("enter_marsh"), "entering the marsh completes the goal")
			check(ptr.target_pos() == null, "the pointer turns off once you reach the marsh (auto)")
			Story.pointer_mode = "on"
			check(ptr.target_pos() != null, "and can be turned back on")
			Story.pointer_mode = "auto"
			# Skipping ahead: reading the pumphouse also clears the chalk goal.
			_read("frames_east")
			_read("pumphouse")
			Story.update(main)
			check(Story.done.has("chalk_lake") and Story.done.has("pumphouse") and Story.current == "build_reservoir", "finishing a goal early skips to the next unfinished one (%s)" % Story.current)
			# The lantern list and the map pause too.
			var bm = main.get_node("BuildMenu")
			bm.open()
			check(get_tree().paused, "the lantern list pauses the world")
			bm.close()
			var mp = main.get_node("MapScreen")
			mp.toggle()
			check(get_tree().paused, "the map pauses the world")
			mp.toggle()
			check(not get_tree().paused, "closing them resumes")
			# Journal.
			var j = main.get_node("Journal")
			j.toggle()
			check(j.is_open() and get_tree().paused, "the journal opens and pauses the world")
			check(j.body.text.contains("Build a Reservoir Lamp"), "the journal shows the current goal")
			j.page = 1
			j.refresh()
			check(j.body.text.contains("To whoever reads this") and j.body.text.contains("The ledger"), "the journal keeps the letter and the story so far")
			j.page = 2
			j.refresh()
			check(j.body.text.contains("Gone east to the marsh"), "the journal keeps every note read, to read again")
			j.toggle()
			check(not j.is_open() and not get_tree().paused, "the journal closes")
			# The new HUD: prompts over things, the right button for the device, goal banner, chips.
			var wp = main.get_node("FogLayer/WorldPrompt")
			InputHint.pad = false
			var lamp_lines: Array = wp.lines_for(lamp)
			check(lamp_lines[0][0] == "E" and String(lamp_lines[0][1]).begins_with("Refuel"), "a lantern shows '[E] Refuel' on keyboard (%s)" % str(lamp_lines))
			InputHint.pad = true
			check(wp.lines_for(lamp)[0][0] == "A" and wp.lines_for(lamp)[1][0] == "B", "and '[A] Refuel  [B] Pick up' on a controller")
			check(wp.lines_for(_landmark("ledger"))[0][1] == "Read again", "a read note says 'Read again'")
			InputHint.pad = false
			var hud = main.get_node("HUD")
			hud._process(0.016)
			check(hud.goal_panel.visible and hud.goal_label.text == Story.goal_text(Story.current), "the goal banner shows the current goal")
			check(hud.counts["fuel"].text == str(Inventory.get_count("fuel")), "the resource panel shows what you carry")
			# Opening and name entry.
			var o = main.get_node("Opening")
			o.start()
			check(o.is_open() and get_tree().paused, "the opening shows and pauses the world")
			o._next()
			o.name_box.text = "  Tess "
			o._next()
			o._next()
			check(not o.is_open() and not get_tree().paused and Story.player_name == "Tess", "the opening takes a name and starts the game (%s)" % Story.player_name)
			# Save and load keep the story.
			check(SaveGame.save(main), "save with story progress")
			var before_done := Story.done.size()
			Story.reset()
			main.queue_free()
		6:
			main = load("res://scenes/main/main.tscn").instantiate()
			add_child(main)
			check(Story.player_name == "Tess", "the keeper's name comes back")
			check(Story.done.has("pumphouse") and Story.entries.has(4), "finished goals and journal entries come back")
			check(Story.visited.has(FogGrid.R_MARSH) and Story.tips_seen.has("cold_lantern"), "where you've been and tips already seen come back")
		10:
			Story.update(main)
			check(Story.current == "build_reservoir", "the current goal is picked up again (%s)" % Story.current)
			check(main.get_node("FogLayer/GoalPointer").target_pos() == null, "the pointer stays off after the marsh")
			SaveGame.delete_save()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
