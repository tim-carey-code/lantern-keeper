extends CanvasLayer
## Pause menu: Esc / Start. Resume, Save, New game (press twice to confirm), Save and quit.
## Works with a controller (D-pad + A) and with the mouse. Pauses the world while open.

var root: Control
var buttons: Array[Button] = []
var info: Label
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
	var box := VBoxContainer.new()
	box.position = Vector2(520, 230)
	box.custom_minimum_size = Vector2(240, 0)
	box.add_theme_constant_override("separation", 10)
	root.add_child(box)
	var title := Label.new()
	title.text = "Paused"
	title.add_theme_font_size_override("font_size", 48)
	box.add_child(title)
	for item in [["Resume", _resume], ["Save", _save], ["New game", _new_game], ["Save and quit", _quit]]:
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
	buttons[0].grab_focus()
	Sfx.play("ui_open", -14.0)

func close() -> void:
	root.visible = false
	Tuning.ui_open = false
	get_tree().paused = false
	get_viewport().gui_release_focus()
	Progress.block_input()
	Sfx.play("ui_close", -14.0)

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

func _quit() -> void:
	if _main():
		SaveGame.save(_main())
	get_tree().quit()
