extends CanvasLayer
## New-game opening: title card, then "your name, keeper", then H.'s letter.
## Pauses the world until it is done. A / E / Enter / click continues.

var root: Control
var label: Label
var hint: Label
var name_box: LineEdit
var step := -1
var _shown_at := 0

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.02, 1.0)
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	label = Label.new()
	label.position = Vector2(240, 150)
	label.size = Vector2(800, 400)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)
	name_box = LineEdit.new()
	name_box.position = Vector2(490, 360)
	name_box.custom_minimum_size = Vector2(300, 44)
	name_box.max_length = 16
	name_box.placeholder_text = "Keeper"
	name_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_box.text_submitted.connect(func(_t: String) -> void: _next())
	root.add_child(name_box)
	hint = Label.new()
	hint.position = Vector2(0, 640)
	hint.size = Vector2(1280, 40)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.modulate = Color(1, 1, 1, 0.6)
	root.add_child(hint)
	root.visible = false

func is_open() -> bool:
	return root.visible

func start() -> void:
	root.visible = true
	Tuning.ui_open = true
	get_tree().paused = true
	step = -1
	_next()

func _next() -> void:
	step += 1
	_shown_at = Time.get_ticks_msec()
	name_box.visible = false
	match step:
		0:
			label.add_theme_font_size_override("font_size", 32)
			label.text = "\n\n".join(Story.TITLE_CARD)
			hint.text = "[A / E / Enter] continue"
		1:
			label.add_theme_font_size_override("font_size", 32)
			label.text = "\n\nYour name, keeper?"
			name_box.visible = true
			name_box.text = Story.player_name
			name_box.grab_focus()
			hint.text = "Type a name, then [Enter] or [A].  Leave it empty to be called Keeper."
		2:
			Story.player_name = name_box.text.strip_edges()
			label.add_theme_font_size_override("font_size", 24)
			label.position = Vector2(290, 90)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			label.text = Story.LETTER
			hint.text = "[A / E / Enter] begin"
		_:
			finish()

func finish() -> void:
	root.visible = false
	Tuning.ui_open = false
	get_tree().paused = false
	get_viewport().gui_release_focus()
	Progress.block_input(300)

func _input(event: InputEvent) -> void:
	if not root.visible or Time.get_ticks_msec() - _shown_at < 250:
		return
	var joy_a: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A
	if step == 1:
		# Typing goes to the name box; only Enter (text_submitted) or the A button continue.
		if joy_a:
			_next()
			get_viewport().set_input_as_handled()
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if joy_a or click or event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_next()
		get_viewport().set_input_as_handled()
