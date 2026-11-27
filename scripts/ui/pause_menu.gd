extends CanvasLayer
## Pause menu: Esc / Start. Resume, Save, New game (press twice to confirm), Save and quit.
## Works with a controller (D-pad + A) and with the mouse. Pauses the world while open.

var root: Control
var buttons: Array[Button] = []
var info: Label
var controls: Label
var _confirm_new := false

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
	frame.position = Vector2(150, 150)
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD, UiStyle.NAVY, 2, 20))
	root.add_child(frame)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 48)
	frame.add_child(cols)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(340, 0)
	box.add_theme_constant_override("separation", 10)
	cols.add_child(box)
	var right := VBoxContainer.new()
	cols.add_child(right)
	var ctitle := UiStyle.label(30, UiStyle.GOLD)
	ctitle.text = "Controls"
	right.add_child(ctitle)
	controls = UiStyle.label(20, UiStyle.PALE)
	right.add_child(controls)
	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)
	for item in [["Resume", _resume], ["Save", _save], ["New game", _new_game], ["Save and quit", _quit], ["Goal pointer", _cycle_pointer], ["Show tips again", _reset_tips], ["Save slots", _to_slots]]:
		var b := Button.new()
		b.text = item[0]
		b.pressed.connect(item[1])
		box.add_child(b)
		buttons.append(b)
	info = Label.new()
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
	_pointer_label()
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
		if f is Button:
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
