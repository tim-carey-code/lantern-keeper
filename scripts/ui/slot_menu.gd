extends Control
## The save-slot screen, shown when the game starts. Three slots: a filled one continues, an empty
## one starts a new game. Each filled slot can be deleted (press Delete twice).
## Works with keyboard, mouse and gamepad (A / E / Enter presses the focused button).

const MAIN := "res://scenes/main/main.tscn"

var slot_buttons: Array[Button] = []
var delete_buttons: Array[Button] = []
var _confirm_delete := 0
var info: Label

func _ready() -> void:
	size = Vector2(1280, 720)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.045)
	bg.size = size
	add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(340, 110)
	box.custom_minimum_size = Vector2(600, 0)
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := UiStyle.label(60, UiStyle.GOLD)
	title.text = "Lantern Keeper"
	box.add_child(title)
	var sub := UiStyle.label(20, UiStyle.PALE)
	sub.text = "Choose a save"
	box.add_child(sub)
	for n in range(1, SaveGame.SLOTS + 1):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var b := Button.new()
		b.custom_minimum_size = Vector2(480, 56)
		b.pressed.connect(_choose.bind(n))
		row.add_child(b)
		var d := Button.new()
		d.custom_minimum_size = Vector2(110, 56)
		d.text = "Delete"
		d.pressed.connect(_delete.bind(n))
		row.add_child(d)
		box.add_child(row)
		slot_buttons.append(b)
		delete_buttons.append(d)
	info = UiStyle.label(20, UiStyle.PALE)
	box.add_child(info)
	refresh()
	slot_buttons[0].grab_focus.call_deferred()

## One line per slot: who, where, how long.
func slot_text(n: int) -> String:
	var s := SaveGame.slot_info(n)
	if s.is_empty():
		return "Slot %d   New game" % n
	var mins := int(s["time"] / 60.0)
	var t := "%dh %02dm" % [mins / 60, mins % 60] if mins >= 60 else "%dm" % mins
	var who: String = s["name"] if s["name"] != "" else "Keeper"
	return "Slot %d   %s   %s   %s%s" % [n, who, s["region"], t, "   (old save)" if s["old"] else ""]

func refresh() -> void:
	for i in slot_buttons.size():
		var n := i + 1
		slot_buttons[i].text = slot_text(n)
		delete_buttons[i].visible = not SaveGame.slot_info(n).is_empty()
		delete_buttons[i].text = "Sure?" if _confirm_delete == n else "Delete"

func _choose(n: int) -> void:
	SaveGame.use_slot(n)
	SaveGame.skip_load_once = SaveGame.slot_info(n).is_empty()   # an empty slot starts fresh
	get_tree().change_scene_to_file(MAIN)

func _delete(n: int) -> void:
	if _confirm_delete != n:
		_confirm_delete = n
		info.text = "Press Delete again to erase slot %d." % n
		refresh()
		return
	SaveGame.delete_slot(n)
	_confirm_delete = 0
	info.text = "Slot %d erased." % n
	refresh()
	slot_buttons[n - 1].grab_focus()

## The controller's A (our "interact") presses the focused button, as in the pause menu.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_action_pressed("ui_accept"):
		var f := get_viewport().gui_get_focus_owner()
		if f is Button:
			get_viewport().set_input_as_handled()
			(f as Button).pressed.emit()
