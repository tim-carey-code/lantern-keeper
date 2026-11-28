extends CanvasLayer
## Pause menu: Esc / Start. Resume, Save, New game (press twice to confirm), Save and quit.
## Works with a controller (D-pad + A) and with the mouse. Pauses the world while open.
## M1a options (GAME_PLAN §14, brief §4): a screen-shake slider, "reduce flashes", and the optional Lampfire
## auto-fire on the right stick. They are saved for this PC in user://settings.cfg (Settings), not in a slot.
## M1c (PLAN_LANTERNS §6.8): "Target lock options" swaps the controls list for the lock's options (mode, moving on
## after a kill, the lock button, the marker size, the aim assist), each a button that cycles its value.

var root: Control
var buttons: Array[Button] = []
var info: Label
var controls: Label
var shake_slider: HSlider
var shake_label: Label
var flashes_check: CheckButton
var autofire_check: CheckButton
var lock_box: VBoxContainer
var lock_buttons := {}          # option -> Button
var _confirm_new := false

const SHAKE_TEXT := "Screen shake: %d%%"
const FLASHES_TEXT := "Reduce flashes"
const AUTOFIRE_TEXT := "Lampfire fires when you push the right stick"

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.02, 0.8)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	var frame := PanelContainer.new()
	frame.position = Vector2(60, 110)   # room for both columns with the larger font
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD, UiStyle.NAVY, 2, 20))
	root.add_child(frame)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 48)
	frame.add_child(cols)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380, 0)
	box.add_theme_constant_override("separation", 10)
	cols.add_child(box)
	var right := VBoxContainer.new()
	cols.add_child(right)
	var ctitle := UiStyle.label(30, UiStyle.GOLD)
	ctitle.text = "Controls"
	right.add_child(ctitle)
	controls = UiStyle.label(20, UiStyle.PALE)
	right.add_child(controls)
	lock_box = VBoxContainer.new()
	lock_box.add_theme_constant_override("separation", 6)
	lock_box.visible = false
	right.add_child(lock_box)
	for opt in ["mode", "chain", "button", "marker", "assist"]:
		var lb := Button.new()
		lb.pressed.connect(_cycle_lock.bind(opt))
		lock_box.add_child(lb)
		lock_buttons[opt] = lb
	var otitle := UiStyle.label(30, UiStyle.GOLD)
	otitle.text = "Options"
	right.add_child(otitle)
	shake_label = UiStyle.label(20, UiStyle.CREAM)
	right.add_child(shake_label)
	shake_slider = HSlider.new()
	shake_slider.min_value = 0.0
	shake_slider.max_value = 100.0
	shake_slider.step = 10.0
	shake_slider.custom_minimum_size = Vector2(320, 24)
	shake_slider.value_changed.connect(_on_shake)
	right.add_child(shake_slider)
	flashes_check = CheckButton.new()
	flashes_check.text = FLASHES_TEXT
	flashes_check.toggled.connect(func(on: bool) -> void:
		Settings.reduce_flashes = on
		Settings.save())
	right.add_child(flashes_check)
	autofire_check = CheckButton.new()
	autofire_check.text = AUTOFIRE_TEXT
	autofire_check.toggled.connect(func(on: bool) -> void:
		Settings.autofire = on
		Settings.save())
	right.add_child(autofire_check)
	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	for item in [["Resume", _resume], ["Save", _save], ["New game", _new_game], ["Save and quit", _quit], ["Goal pointer", _cycle_pointer], ["Target lock options", _toggle_lock_options], ["Show tips again", _reset_tips], ["Save slots", _to_slots]]:
		var b := Button.new()
		b.text = item[0]
		b.pressed.connect(item[1])
		box.add_child(b)
		buttons.append(b)
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(380, 0)   # wrap long lines instead of widening the menu
	box.add_child(info)
	root.visible = false

func is_open() -> bool:
	return root.visible

func open() -> void:
	root.visible = true
	Tuning.ui_open = true
	get_tree().paused = true
	_confirm_new = false
	buttons[2].text = "New game"
	info.text = "Last save: " + _last_save_text()
	controls.text = InputHint.controls_text()
	shake_slider.set_value_no_signal(roundf(Settings.shake * 100.0))
	shake_label.text = SHAKE_TEXT % roundi(Settings.shake * 100.0)
	flashes_check.set_pressed_no_signal(Settings.reduce_flashes)
	autofire_check.set_pressed_no_signal(Settings.autofire)
	_pointer_label()
	controls.visible = true
	lock_box.visible = false
	_lock_labels()
	buttons[0].grab_focus()
	Sfx.play("ui_open", -14.0)

func close() -> void:
	root.visible = false
	Tuning.ui_open = false
	get_tree().paused = false
	get_viewport().gui_release_focus()
	Progress.block_input()
	Sfx.play("ui_close", -14.0)

## The controller's A button (our "interact") presses the focused button. Godot's built-in
## ui_accept doesn't include A in this project, so menus could be scrolled but not chosen.
func _input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("interact") and not event.is_action_pressed("ui_accept"):
		var f := get_viewport().gui_get_focus_owner()
		if f is CheckButton:
			get_viewport().set_input_as_handled()
			(f as CheckButton).button_pressed = not (f as CheckButton).button_pressed
		elif f is Button:
			# Mark it handled first: the button may reload the whole scene (New game), and then
			# this menu is no longer in the tree (that error froze the game in the debugger).
			get_viewport().set_input_as_handled()
			(f as Button).pressed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if root.visible:
			close()
		elif not Tuning.ui_open:
			open()
		get_viewport().set_input_as_handled()
	elif root.visible and event.is_action_pressed("cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_shake(v: float) -> void:
	Settings.shake = clampf(v / 100.0, 0.0, 1.0)
	shake_label.text = SHAKE_TEXT % roundi(v)
	Settings.save()

func _main() -> Node:
	return get_tree().get_first_node_in_group("main")

func _last_save_text() -> String:
	if not SaveGame.has_save():
		return "none yet"
	var t := FileAccess.get_modified_time(SaveGame.path)
	return Time.get_datetime_string_from_unix_time(t, true) + " (autosaves every minute)"

func _resume() -> void:
	close()

func _save() -> void:
	if _main() and SaveGame.save(_main()):
		info.text = "Saved."
		Sfx.play("unlock", -12.0)

func _new_game() -> void:
	if not _confirm_new:
		_confirm_new = true
		buttons[2].text = "New game? Press again"
		info.text = "This deletes your save."
		return
	SaveGame.delete_save()
	SaveGame.skip_load_once = true
	get_tree().paused = false
	Tuning.ui_open = false
	get_tree().reload_current_scene()

const POINTER_NAMES := {"auto": "Goal pointer: auto (Hollow only)", "on": "Goal pointer: always on", "off": "Goal pointer: off"}

func _pointer_label() -> void:
	buttons[4].text = POINTER_NAMES.get(Story.pointer_mode, "Goal pointer")

func _cycle_pointer() -> void:
	var order := ["auto", "on", "off"]
	Story.pointer_mode = order[(order.find(Story.pointer_mode) + 1) % order.size()]
	_pointer_label()

# --- Target lock options (M1c; DRAFT names, STORY §16) ---------------------------------------------------------

const LOCK_MODE_NAMES := {"toggle": "Target lock: press to lock", "auto": "Target lock: auto", "off": "Target lock: off"}
const LOCK_CHAIN_NAMES := {true: "Next foe after a kill: on", false: "Next foe after a kill: off"}
const LOCK_MARKER_NAMES := {false: "Lock marker: normal", true: "Lock marker: large"}
const LOCK_BUTTON_TEXT := "Lock button: %s"
const AIM_ASSIST_TEXT := "Aim assist: %s"

func _lock_labels() -> void:
	lock_buttons["mode"].text = LOCK_MODE_NAMES.get(Settings.lock_mode, "Target lock")
	lock_buttons["chain"].text = LOCK_CHAIN_NAMES.get(Settings.lock_chain, "Next foe after a kill")
	lock_buttons["button"].text = LOCK_BUTTON_TEXT % Settings.lock_button_label()
	lock_buttons["marker"].text = LOCK_MARKER_NAMES.get(Settings.lock_large, "Lock marker")
	lock_buttons["assist"].text = AIM_ASSIST_TEXT % ("off" if Settings.aim_assist <= 0.0 else "%d degrees" % roundi(Settings.aim_assist))

## Shows the lock options in place of the controls list (and back).
func _toggle_lock_options() -> void:
	lock_box.visible = not lock_box.visible
	controls.visible = not lock_box.visible
	_lock_labels()
	if lock_box.visible:
		lock_buttons["mode"].grab_focus()

func _cycle_lock(opt: String) -> void:
	match opt:
		"mode":
			Settings.lock_mode = Settings.next_in(Settings.LOCK_MODES, Settings.lock_mode)
		"chain":
			Settings.lock_chain = not Settings.lock_chain
		"button":
			Settings.lock_button = Settings.next_in(Settings.LOCK_BUTTONS, Settings.lock_button)
		"marker":
			Settings.lock_large = not Settings.lock_large
		"assist":
			Settings.aim_assist = Settings.next_in(Settings.AIM_ASSISTS, Settings.aim_assist)
	Settings.apply_controls()
	Settings.save()
	_lock_labels()

func _reset_tips() -> void:
	Story.tips_seen = {}
	info.text = "Tips will show again."

func _quit() -> void:
	if _main():
		SaveGame.save(_main())
	get_tree().quit()

## Save, then go back to the save-slot screen.
func _to_slots() -> void:
	if _main():
		SaveGame.save(_main())
	get_tree().paused = false
	Tuning.ui_open = false
	get_tree().change_scene_to_file("res://scenes/menu/slots.tscn")
