extends Node
## M1a input guards: closing each in-game menu with B never drinks, and D-pad map/lamp
## actions stay out of the world while a menu is open.
## The B checks are end to end: a test-only key stands in for the pad's B (bound to both "cancel" and "flask", as
## B is), its press goes through Input like a real one, the menu closes in its own handler, and the keeper's own
## _physics_process reads the flask in that same frame. The flask count must not change; once the menu guard's
## block runs out, the same press drinks exactly once. (If the flask were read above the guard, it would drink.)
## Run: godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_input.tscn
const TEST_B := KEY_F13   # bound only in this test
var main: Node
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
	# The pad's B, as one key: it closes menus ("cancel") and drinks ("flask").
	for action in ["cancel", "flask"]:
		var b := InputEventKey.new()
		b.physical_keycode = TEST_B
		b.keycode = TEST_B
		InputMap.action_add_event(action, b)
	Story.skip_opening = true
	Settings.path = "user://test_input_settings.cfg"   # never the owner's settings
	Settings.use_defaults()
	SaveGame.path = "user://test_input_save.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await _run()
	SaveGame.delete_save()
	print("RESULT fails=%d" % fails)
	get_tree().quit(1 if fails else 0)

func _key(code: Key, pressed: bool) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	return e

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func _run() -> void:
	await _frames(3)
	var p = main.player
	InputHint.pad = true
	check(not _dpad_moves, "D-pad is not bound to movement")
	check(_map_up and _lamp_left and _lamp_right, "D-pad up maps the map and left/right map the lamp controls")
	check(InputMap.has_action("flask"), "flask action is configured")
	check(Settings.tool_run() and not Settings.autofire and Settings.shake == 1.0 and not Settings.reduce_flashes, "a test run uses the default settings, never the owner's settings.cfg")
	check(InputHint.PAD["cancel"] == "B" and InputHint.PAD["flask"] == "B", "on a pad, B both closes menus and drinks")
	var map_screen = main.get_node("MapScreen")
	var build = main.get_node("BuildMenu")
	var journal = main.get_node("Journal")
	var note = main.get_node("NoteReader")
	var pause = main.get_node("PauseMenu")
	var skills = main.get_node("SkillsList")
	var travel = main.get_node("TravelMenu")
	var lamps := get_tree().get_nodes_in_group("waylamp")
	var opened := 0
	# Each menu opens for real, gets the D-pad checks, then is closed by B with the drink check.
	journal.toggle(); opened += await _exercise_menu(p, journal, "Journal")
	map_screen.toggle(); opened += await _exercise_menu(p, map_screen, "Map")
	Progress.note_opened.emit("test", "test"); opened += await _exercise_menu(p, note, "NoteReader")
	pause.open(); opened += await _exercise_menu(p, pause, "PauseMenu")
	build.open(); opened += await _exercise_menu(p, build, "BuildMenu")
	skills.open(); opened += await _exercise_menu(p, skills, "SkillsList")
	if not lamps.is_empty() and travel.open(lamps[0]):
		opened += await _exercise_menu(p, travel, "TravelMenu")
	else:
		check(false, "TravelMenu opens")
	check(opened == 7, "all seven closeable in-game menus opened and closed through their B route (%d)" % opened)
	# The level-up cards are the eighth menu: chosen with A rather than cancelled with B.
	var level_up = main.get_node("HUD").level_up_screen
	var ups_before: Array[String] = Progress.combat_upgrades.duplicate()
	Progress.level_up.emit(2)
	await get_tree().process_frame
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
	# B while the cards are up: no drink (the menu is open), and the cards stay.
	_ready_to_drink(p)
	Input.parse_input_event(_key(TEST_B, true))
	await _frames(2)
	Input.parse_input_event(_key(TEST_B, false))
	await _frames(1)
	check(level_up.root.visible and p.flasks == 3 and p.drinks == _drinks0, "level-up: B while the cards are up never drinks")
	# A chooses a card and closes it; B pressed in the same frame must not drink.
	await _close_and_drink(p, level_up, "Level-up", true)
	Progress.combat_upgrades = ups_before
	# Aim hold: when the right stick is released while firing, its last aim survives.
	InputHint.pad = true   # the stand-in B key made the last device the keyboard
	var c = p.combat
	Input.action_press("aim_right"); c.update_aim(Vector2.ZERO, true)
	Input.action_release("aim_right")
	var before: Vector2 = c.aim
	c.update_aim(Vector2.ZERO, true)
	check(c.aim.distance_to(before) < 0.001, "aim hold keeps the last right-stick aim while firing")
	await _flask_lockout(p)
	await _lock_checks(p)

var _drinks0 := 0

## M1c: the lock button (R3 on a pad, middle mouse on K&M) is read after the menu guard like every combat input;
## the option moves it to Y, L3 or a back paddle and takes that button off what used it; Y takes an aimed skill.
func _lock_checks(p: Node) -> void:
	var ev: Array = ProjectSettings.get_setting("input/lock_on")["events"]
	var r3 := ev.any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_RIGHT_STICK)
	var mid := ev.any(func(e): return e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_MIDDLE)
	check(r3 and mid, "lock_on is R3 on a pad and middle mouse on K&M (tools/setup_input.gd)")
	var wheel: Array = ProjectSettings.get_setting("input/lock_next")["events"]
	check(wheel.any(func(e): return e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_WHEEL_DOWN), "the mouse wheel moves the lock")
	InputHint.pad = true
	check(InputHint.PAD["lock_on"] == "R3" and InputHint.key("lock_on") == "R3", "the prompt names R3 on a pad")
	var w := Wickling.new()
	w.position = p.global_position + Vector2(120, 0)
	main.get_node("FogLayer/Wicklings").add_child(w)
	w.set_process(false)
	var fog: FogGrid = main.fog
	fog.density[fog.idx(fog.tile_of(w.position))] = 0.0   # in clear air (a lock can't start in deep fog)
	await _frames(2)
	# The menu guard: a lock press right after a menu closes does nothing.
	Progress.block_input(5000)
	Input.action_press("lock_on")
	await _frames(2)
	Input.action_release("lock_on")
	await _frames(1)
	check(not p.combat.lock.has_target(), "a lock press right after a menu closes is swallowed (the menu guard)")
	Progress._input_block_until = 0
	Input.action_press("lock_on")
	await _frames(2)
	Input.action_release("lock_on")
	await _frames(1)
	check(p.combat.lock.has_target() and p.combat.lock.target == w, "with no menu, the lock button locks the foe")
	# A menu opening ends the lock.
	main.get_node("PauseMenu").open()
	await _frames(1)
	main.get_node("PauseMenu").close()
	await _frames(2)
	check(not p.combat.lock.has_target(), "opening a menu ends the lock")
	Progress._input_block_until = 0
	# The lock button option.
	Settings.lock_button = "y"
	Settings.apply_controls()
	InputHint.pad = true
	var lock_y := InputMap.action_get_events("lock_on").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_Y)
	var skill_y := InputMap.action_get_events("skill_4").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_Y)
	var skill_r3 := InputMap.action_get_events("skill_4").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_RIGHT_STICK)
	check(lock_y and not skill_y and InputHint.key("lock_on") == "Y", "the lock moved to Y: Y locks, and slot 4 gives Y up")
	check(skill_r3 and InputHint.short("skill_4") == "R3" and InputHint.key("skill_4") == "R3", "and slot 4 moves to R3, and the bar says so")
	Settings.lock_button = "r3"
	Settings.apply_controls()
	skill_y = InputMap.action_get_events("skill_4").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_Y)
	var lock_r3 := InputMap.action_get_events("lock_on").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_RIGHT_STICK)
	skill_r3 = InputMap.action_get_events("skill_4").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_RIGHT_STICK)
	check(skill_y and lock_r3 and not skill_r3 and InputHint.short("skill_4") == "Y", "back on R3: slot 4 has Y again")
	check(not Settings.LOCK_BUTTONS.has("paddle"), "no lock button a standard pad lacks (no back paddle)")
	check(InputMap.action_get_events("lock_on").any(func(e): return e is InputEventMouseButton), "middle mouse always locks")
	# Y may hold an aimed skill (PLAN_LANTERNS §6.6).
	check(Progress.bind_reason("skill_4", "fireglobe") == "", "Y takes an aimed skill")
	for action in InputMap.get_actions():   # apply_controls put pad buttons back: strip them again
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)
	w.queue_free()
	await _frames(1)

func _ready_to_drink(p: Node) -> void:
	p.flasks = 3; p.flask_lock = 0.0; p.warmth = 20.0
	_drinks0 = p.drinks

func _is_open(menu: Node) -> bool:
	if menu.has_method("is_open"):
		return menu.is_open()
	return menu.root.visible

## In one frame: the closing press (B, or A for the level-up cards) and a real B go through Input; the menu closes
## in its handler and the keeper's _physics_process reads the flask after it. Then, once the guard's block runs
## out, the same B drinks once.
func _close_and_drink(p: Node, menu: Node, label: String, with_a := false) -> void:
	_ready_to_drink(p)
	if with_a:
		Input.parse_input_event(_event("interact"))
	Input.parse_input_event(_key(TEST_B, true))
	await _frames(1)
	var closed := not _is_open(menu)
	var blocked: bool = Progress.input_blocked()
	await _frames(2)
	check(closed and blocked and not Tuning.ui_open and not get_tree().paused, "%s closes with %s, and the guard blocks combat input" % [label, "A" if with_a else "B"])
	check(p.flasks == 3 and p.drinks == _drinks0, "%s: the press that closes it never drinks (flasks %d)" % [label, p.flasks])
	if with_a:
		var up := _event("interact"); up.pressed = false
		Input.parse_input_event(up)
	Input.parse_input_event(_key(TEST_B, false))
	var waited := 0
	while Progress.input_blocked() and waited < 5000:
		await _frames(1)
		waited += 1
	await _frames(1)
	check(p.flasks == 3, "%s: still no drink when the block runs out with B up" % label)
	Input.parse_input_event(_key(TEST_B, true))
	await _frames(2)
	Input.parse_input_event(_key(TEST_B, false))
	await _frames(2)
	check(p.flasks == 2 and p.drinks == _drinks0 + 1, "%s: after the block, B drinks once (flasks %d)" % [label, p.flasks])
	get_tree().paused = false; Tuning.ui_open = false; Progress._input_block_until = 0

func _exercise_menu(p: Node, menu: Node, label: String) -> int:
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
	await _close_and_drink(p, menu, label)
	return 1

## The flask's lockout ends: a second drink is refused inside kl_flask_lockout and taken after it.
func _flask_lockout(p: Node) -> void:
	Progress._input_block_until = 0
	_ready_to_drink(p)
	Input.parse_input_event(_key(TEST_B, true))
	await _frames(2)
	Input.parse_input_event(_key(TEST_B, false))
	await _frames(1)
	check(p.flasks == 2 and p.flask_lock > 0.0, "a drink starts the %s s lockout" % str(Tuning.kl_flask_lockout))
	Input.parse_input_event(_key(TEST_B, true))
	await _frames(2)
	Input.parse_input_event(_key(TEST_B, false))
	await _frames(1)
	check(p.flasks == 2, "B inside the lockout doesn't drink")
	await _frames(int(Tuning.kl_flask_lockout * 60.0) + 2)
	check(p.flask_lock == 0.0, "the lockout ends after %s s" % str(Tuning.kl_flask_lockout))
	Input.parse_input_event(_key(TEST_B, true))
	await _frames(2)
	Input.parse_input_event(_key(TEST_B, false))
	await _frames(1)
	check(p.flasks == 1 and p.drinks == _drinks0 + 2, "and then B drinks again (flasks %d)" % p.flasks)
