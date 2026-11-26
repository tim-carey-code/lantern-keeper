extends CanvasLayer
## Shows a landmark's text. The keeper stops while it is open.
## E / A, Q / B or Esc / Start closes it.

var panel: PanelContainer
var title_label: Label
var body_label: Label

func _ready() -> void:
	layer = 8
	panel = PanelContainer.new()
	panel.position = Vector2(240, 220)
	panel.custom_minimum_size = Vector2(800, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.08, 0.95)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 22)
	box.add_child(title_label)
	body_label = Label.new()
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(780, 0)
	box.add_child(body_label)
	panel.visible = false
	Progress.note_opened.connect(_open)

func is_open() -> bool:
	return panel.visible

func _open(title: String, text: String) -> void:
	title_label.text = title
	body_label.text = text + "\n\n[E / A] close"
	panel.visible = true
	Tuning.ui_open = true

func close() -> void:
	panel.visible = false
	Tuning.ui_open = false
	Progress.block_input()

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
