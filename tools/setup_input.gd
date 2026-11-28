extends SceneTree
## One-off tool: writes the input map into project.godot in Godot's own format.
## Run: godot --headless --path . --script res://tools/setup_input.gd
## Safe to re-run; it replaces these actions.

const DEADZONE := 0.25

func key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

func pad_button(b: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = b
	return e

func pad_axis(a: JoyAxis, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	return e

func mouse(b: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = b
	return e

## The map is GAME_PLAN §3 (approved 2026-11-27). The D-pad is not movement: it holds the map, the lamp
## kinds and the Skills list, which are read only while no menu is open (M1a input fixes).
func _init() -> void:
	var actions := {
		"move_left": [key(KEY_A), key(KEY_LEFT), pad_axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right": [key(KEY_D), key(KEY_RIGHT), pad_axis(JOY_AXIS_LEFT_X, 1.0)],
		"move_up": [key(KEY_W), key(KEY_UP), pad_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"move_down": [key(KEY_S), key(KEY_DOWN), pad_axis(JOY_AXIS_LEFT_Y, 1.0)],
		# Gamepad face buttons use positional names: A = bottom, B = right, X = left, Y = top.
		"interact": [key(KEY_E), pad_button(JOY_BUTTON_A)],          # read, light, take scrap, travel, rest; hold: pick up a lamp (M1b)
		"place_lantern": [key(KEY_C), pad_button(JOY_BUTTON_X)],     # plant a lamp; next to a mirror, turn it left
		"cancel": [pad_button(JOY_BUTTON_B)],                         # closes menus (Esc closes them too, as pause)
		"flask": [key(KEY_R), pad_button(JOY_BUTTON_B)],              # drink lamp oil; read after the menu guard
		"build_menu": [key(KEY_TAB), pad_button(JOY_BUTTON_DPAD_RIGHT)],   # tap: next lamp kind; hold: the lamp list
		"lamp_prev": [pad_button(JOY_BUTTON_DPAD_LEFT)],              # previous lamp kind
		"pause": [key(KEY_ESCAPE), pad_button(JOY_BUTTON_START)],
		"map": [key(KEY_M), pad_button(JOY_BUTTON_DPAD_UP)],
		"skills": [key(KEY_K), pad_button(JOY_BUTTON_DPAD_DOWN)],     # the Skills list
		# The action bar: slot 1 is always Lampfire (hold); 2 and 3 take aimed skills; 4 takes self-cast skills.
		"skill_1": [mouse(MOUSE_BUTTON_LEFT), pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"skill_2": [mouse(MOUSE_BUTTON_RIGHT), pad_button(JOY_BUTTON_RIGHT_SHOULDER)],
		"skill_3": [key(KEY_Q), pad_button(JOY_BUTTON_LEFT_SHOULDER)],
		"skill_4": [key(KEY_F), pad_button(JOY_BUTTON_Y)],
		"dash": [key(KEY_SPACE), key(KEY_SHIFT), pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)],
		"aim_left": [pad_axis(JOY_AXIS_RIGHT_X, -1.0)],
		"aim_right": [pad_axis(JOY_AXIS_RIGHT_X, 1.0)],
		"aim_up": [pad_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"aim_down": [pad_axis(JOY_AXIS_RIGHT_Y, 1.0)],
		"toggle_fullscreen": [key(KEY_F11)],
		"journal": [key(KEY_J), pad_button(JOY_BUTTON_BACK)],
		"select_1": [key(KEY_1)],
		"select_2": [key(KEY_2)],
		"select_3": [key(KEY_3)],
		"select_4": [key(KEY_4)],
		"debug_toggle": [key(KEY_F1), pad_button(JOY_BUTTON_LEFT_STICK)],    # live tuning panel (left stick click)
	}
	for name in actions:
		ProjectSettings.set_setting("input/" + name, {"deadzone": DEADZONE, "events": actions[name]})
	# Retired with M1a: the beam and the burst are skills on the bar now (skill_1..skill_4).
	for old in ["beam", "flare"]:
		if ProjectSettings.has_setting("input/" + old):
			ProjectSettings.set_setting("input/" + old, null)
	var err := ProjectSettings.save()
	print("setup_input: saved %d actions, err=%d" % [actions.size(), err])
	quit(0 if err == OK else 1)
