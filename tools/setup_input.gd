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

func _init() -> void:
	var actions := {
		"move_left": [key(KEY_A), key(KEY_LEFT), pad_axis(JOY_AXIS_LEFT_X, -1.0), pad_button(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [key(KEY_D), key(KEY_RIGHT), pad_axis(JOY_AXIS_LEFT_X, 1.0), pad_button(JOY_BUTTON_DPAD_RIGHT)],
		"move_up": [key(KEY_W), key(KEY_UP), pad_axis(JOY_AXIS_LEFT_Y, -1.0), pad_button(JOY_BUTTON_DPAD_UP)],
		"move_down": [key(KEY_S), key(KEY_DOWN), pad_axis(JOY_AXIS_LEFT_Y, 1.0), pad_button(JOY_BUTTON_DPAD_DOWN)],
		# Gamepad face buttons use positional names: A = bottom, B = right, X = left, Y = top.
		"interact": [key(KEY_E), pad_button(JOY_BUTTON_A)],          # gather / refuel / relight
		"place_lantern": [key(KEY_SPACE), mouse(MOUSE_BUTTON_LEFT), pad_button(JOY_BUTTON_X)],
		"cancel": [key(KEY_Q), mouse(MOUSE_BUTTON_RIGHT), pad_button(JOY_BUTTON_B)],
		"build_menu": [key(KEY_TAB), pad_button(JOY_BUTTON_Y)],
		"pause": [key(KEY_ESCAPE), pad_button(JOY_BUTTON_START)],
		"map": [key(KEY_M), pad_button(JOY_BUTTON_LEFT_SHOULDER)],
		"flare": [key(KEY_F), pad_button(JOY_BUTTON_RIGHT_SHOULDER), pad_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],   # hold: warding glow
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
	var err := ProjectSettings.save()
	print("setup_input: saved %d actions, err=%d" % [actions.size(), err])
	quit(0 if err == OK else 1)
