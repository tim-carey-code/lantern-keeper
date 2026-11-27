extends Node
## M1a input guards: closing each in-game menu with B never drinks, and D-pad map/lamp
## actions stay out of the world while a menu is open.
var main: Node
var frame := 0
var fails := 0
var _dpad_moves := false
var _map_up := false
var _lamp_left := false
var _lamp_right := false

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok: fails += 1

func _event(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	e.strength = 1.0
	return e

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Record production bindings, then remove connected physical-device input for deterministic runs.
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton and e.button_index >= JOY_BUTTON_DPAD_UP and e.button_index <= JOY_BUTTON_DPAD_RIGHT:
				if action in ["move_left", "move_right", "move_up", "move_down"]: _dpad_moves = true
				if action == "map" and e.button_index == JOY_BUTTON_DPAD_UP: _map_up = true
				if action == "lamp_prev" and e.button_index == JOY_BUTTON_DPAD_LEFT: _lamp_left = true
				if action == "build_menu" and e.button_index == JOY_BUTTON_DPAD_RIGHT: _lamp_right = true
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion: InputMap.action_erase_event(action, e)
	Story.skip_opening = true
	SaveGame.path = "user://test_input_save.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	frame += 1
	if frame != 2: return
	var p = main.player
	InputHint.pad = true
	check(not _dpad_moves, "D-pad is not bound to movement")
	check(_map_up and _lamp_left and _lamp_right, "D-pad up maps the map and left/right map the lamp controls")
	check(InputMap.has_action("flask"), "flask action is configured")
	var map_screen = main.get_node("MapScreen")
	var build = main.get_node("BuildMenu")
	var journal = main.get_node("Journal")
	var note = main.get_node("NoteReader")
	var pause = main.get_node("PauseMenu")
	var skills = main.get_node("SkillsList")
	var travel = main.get_node("TravelMenu")
	var opened := 0
	# Each pair opens its real menu and routes a B/cancel event through that menu's handler.
	journal.toggle(); opened += _exercise_menu(p, journal, "_unhandled_input", "Journal")
	map_screen.toggle(); opened += _exercise_menu(p, map_screen, "_unhandled_input", "Map")
	Progress.note_opened.emit("test", "test"); opened += _exercise_menu(p, note, "_unhandled_input", "NoteReader")
	pause.open(); opened += _exercise_menu(p, pause, "_unhandled_input", "PauseMenu")
	build.open(); opened += _exercise_menu(p, build, "_unhandled_input", "BuildMenu")
	skills.open(); opened += _exercise_menu(p, skills, "_input", "SkillsList")
	var lamps := get_tree().get_nodes_in_group("waylamp")
	if not lamps.is_empty() and travel.open(lamps[0]):
		opened += _exercise_menu(p, travel, "_input", "TravelMenu")
	check(opened == 7, "all seven closeable in-game menus opened and closed through their B route (%d)" % opened)
	# The level-up card is the eighth menu; it is chosen rather than cancelled with B.
	var level_up = main.get_node("HUD").level_up_screen
	Progress.level_up.emit(2)
	await get_tree().process_frame
	check(level_up.root.visible, "the level-up menu opens")
	var level_pos: Vector2 = p.global_position
	map_screen._unhandled_input(_event("map"))
	build._unhandled_input(_event("lamp_prev"))
	build._unhandled_input(_event("build_menu"))
	main.get_node("SkillsList")._unhandled_input(_event("skills"))
	Input.action_press("move_right")
	p._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	check(level_up.root.visible and not map_screen.is_open() and p.global_position.distance_to(level_pos) < 0.01, "level-up keeps D-pad map/lamp actions and movement inside the menu")
	p.flasks = 3; p.flask_lock = 0.0; p.warmth = 20.0
	check(not p._handle_flask_input(true, Tuning.ui_open) and p.flasks == 3, "level-up menu blocks the flask read")
	level_up._choose(level_up._offer[0].id)
	await get_tree().process_frame
	# Aim hold: when the right stick is released while firing, its last aim survives.
	var c = p.combat
	Input.action_press("aim_right"); c.update_aim(Vector2.ZERO, true)
	Input.action_release("aim_right")
	var before: Vector2 = c.aim
	c.update_aim(Vector2.ZERO, true)
	check(c.aim.distance_to(before) < 0.001, "aim hold keeps the last right-stick aim while firing")
	print("RESULT fails=%d" % fails)
	get_tree().quit(1 if fails else 0)

func _exercise_menu(p: Node, menu: Node, handler: String, label: String) -> int:
	if not menu.is_open():
		check(false, "%s opens" % label)
		return 0
	var start: Vector2 = p.global_position
	var map = main.get_node("MapScreen")
	var build = main.get_node("BuildMenu")
	var selected := Progress.selected
	if label != "Map":
		var build_was_open: bool = build.is_open()
		map._unhandled_input(_event("map"))
		build._unhandled_input(_event("lamp_prev"))
		build._unhandled_input(_event("build_menu"))
		check(menu.is_open() and not map.is_open() and build.is_open() == build_was_open, "%s keeps D-pad map/lamp actions inside the menu" % label)
		check(Progress.selected == selected, "%s D-pad doesn't change the lamp selection" % label)
	Input.action_press("move_right")
	p._physics_process(1.0 / 60.0)
	Input.action_release("move_right")
	check(p.global_position.distance_to(start) < 0.01, "%s doesn't move the keeper" % label)
	menu.call(handler, _event("cancel"))
	check(not menu.is_open(), "%s closes with B" % label)
	p.flasks = 3; p.flask_lock = 0.0; p.warmth = 20.0
	var blocked: bool = Progress.input_blocked()
	check(blocked and not p._handle_flask_input(true, blocked), "%s closing B/flask press never drinks" % label)
	get_tree().paused = false; Tuning.ui_open = false; Progress._input_block_until = 0
	return 1
