extends CanvasLayer
## Prototype level-up choice: pauses the world and remains keyboard/gamepad navigable.

const OPTIONS := [
	{"id":"lingering_burn", "title":"Lingering burn", "body":"Things touched by your beam keep burning for 2 seconds."},
	{"id":"catching", "title":"Catching", "body":"A kill catches the nearest foe within 60 px."},
	{"id":"tight_focus", "title":"Tight focus", "body":"Your beam wears shells 30% faster."},
	{"id":"long_throw", "title":"Long throw", "body":"Your beam reaches 310 px."},
	{"id":"second_step", "title":"Second step", "body":"Dash twice before its cooldown."},
	{"id":"heavy_flare", "title":"Heavy flare", "body":"Your burst throws foes farther and stuns them."},
	{"id":"deep_tank", "title":"Deep tank", "body":"Your beam costs 20% less lamp charge."},
	{"id":"quick_fill", "title":"Quick fill", "body":"Lantern light refills your charge 50% faster."},
]

var root: Control
var cards: HBoxContainer
var note: Label
var _queue := 0
var _offer: Array[Dictionary] = []

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	Progress.level_up.connect(_on_level_up)
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.02, 0.82)
	dim.size = root.size
	root.add_child(dim)
	var frame := PanelContainer.new()
	frame.position = Vector2(160, 190)
	frame.custom_minimum_size = Vector2(960, 340)
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD, UiStyle.NAVY, 2, 18))
	root.add_child(frame)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	frame.add_child(col)
	var title := UiStyle.label(40, UiStyle.GOLD)
	title.text = "Trim the wick"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	note = UiStyle.label(20, UiStyle.PALE)
	note.text = "Choose one."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(note)
	cards = HBoxContainer.new()
	cards.add_theme_constant_override("separation", 14)
	col.add_child(cards)

func _on_level_up(_new_level: int) -> void:
	_queue += 1
	call_deferred("_present_next")

func _present_next() -> void:
	if _queue <= 0 or root.visible:
		return
	_queue -= 1
	_offer.clear()
	var pool: Array[Dictionary] = []
	for option in OPTIONS:
		if not Progress.has_combat_upgrade(option.id):
			pool.append(option)
	pool.shuffle()
	for i in mini(3, pool.size()):
		_offer.append(pool[i])
	if _offer.is_empty():
		Progress.choose_combat_upgrade("level_cap")
		_present_next()
		return
	for child in cards.get_children():
		cards.remove_child(child)   # out of the row now, so focus lands on the new cards
		child.queue_free()
	for i in _offer.size():
		var option: Dictionary = _offer[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(285, 190)
		button.text = "%s\n\n%s" % [option.title, option.body]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_choose.bind(option.id))
		cards.add_child(button)
	root.visible = true
	Tuning.ui_open = true
	get_tree().paused = true
	(cards.get_child(0) as Button).grab_focus()

func _input(event: InputEvent) -> void:
	if not root.visible or not event.is_action_pressed("interact"):
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus is Button:
		get_viewport().set_input_as_handled()
		(focus as Button).pressed.emit()

func _choose(id: String) -> void:
	get_viewport().set_input_as_handled()
	Progress.choose_combat_upgrade(id)
	root.visible = false
	if Progress.pending_level_ups > 0 or _queue > 0:
		call_deferred("_present_next")
	else:
		Tuning.ui_open = false
		get_tree().paused = false
		Progress.block_input()
		if _queue > 0:
			call_deferred("_present_next")
