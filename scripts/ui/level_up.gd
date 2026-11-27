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
	{"id":"kindled_kills", "title":"Kindled kills", "body":"Every kill gives back 10% of your lamp charge."},
	# Balance pass (2026-11-27): one more from each line of PLAN §5.2, so every Hollow offer has three cards.
	{"id":"hot_core", "title":"Hot core", "body":"Your lanterns' cores burn twice as hard."},
	{"id":"steady_hand", "title":"Steady hand", "body":"You walk at 90% speed while beaming."},
	{"id":"lee", "title":"Lee", "body":"A Wickling's touch chills you 25% less."},
	{"id":"spill", "title":"Spill", "body":"Burst cooldown 2.2 s; each foe it hits gives back 3% lamp charge."},
]

var root: Control
var cards: HBoxContainer
var note: Label
var level_label: Label
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
	level_label = UiStyle.label(30, UiStyle.CREAM)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(level_label)
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
	Sfx.play_ui("unlock", -4.0)
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
	# Which level this card is for (with several queued, count up to the current one).
	level_label.text = "Level %d" % (Progress.level - _queue)
	root.visible = true
	_flash()
	Tuning.ui_open = true
	get_tree().paused = true
	(cards.get_child(0) as Button).grab_focus()

## A short warm flash as the screen opens.
func _flash() -> void:
	root.modulate = Color(1.8, 1.5, 1.0, 0.0)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(root, "modulate", Color(1.8, 1.5, 1.0, 1.0), 0.08)
	tw.tween_property(root, "modulate", Color.WHITE, 0.35)

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
