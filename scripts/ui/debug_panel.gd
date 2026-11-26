extends CanvasLayer
## Live tuning panel. F1 / gamepad Select toggles it. Works with mouse or
## gamepad (D-pad up/down picks a slider, left/right changes it).

const ROWS := [
	["lantern_burn_per_sec", "Burn rate (fuel/s)", 0.05, 5.0, 0.05],
	["lantern_max_radius", "Lantern radius (px)", 64.0, 512.0, 8.0],
	["lantern_min_radius_frac", "Radius when nearly empty", 0.1, 1.0, 0.05],
	["fog_creep_per_sec", "Fog creep (/s)", 0.0, 0.5, 0.01],
	["fog_clear_per_sec", "Fog clear (/s)", 0.1, 3.0, 0.05],
	["hand_lamp_radius", "Hand lamp radius (px)", 24.0, 256.0, 4.0],
]

var panel: PanelContainer
var first_slider: HSlider

func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.position = Vector2(16, 90)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Tuning  (F1 / Select to close)"
	box.add_child(title)
	for row in ROWS:
		var key: String = row[0]
		var label_text: String = row[1]
		var lbl := Label.new()
		var s := HSlider.new()
		s.min_value = row[2]
		s.max_value = row[3]
		s.step = row[4]
		s.custom_minimum_size = Vector2(280, 22)
		s.value = Tuning.get(key)
		lbl.text = "%s: %s" % [label_text, str(snappedf(Tuning.get(key), 0.001))]
		s.value_changed.connect(func(v: float) -> void:
			Tuning.set(key, v)
			lbl.text = "%s: %s" % [label_text, str(snappedf(v, 0.001))])
		box.add_child(lbl)
		box.add_child(s)
		if first_slider == null:
			first_slider = s
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		panel.visible = not panel.visible
		Tuning.ui_open = panel.visible
		if panel.visible:
			first_slider.grab_focus()
		else:
			get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()
