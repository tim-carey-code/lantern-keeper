extends CanvasLayer
## Live tuning panel. F1 / gamepad Select toggles it. Works with mouse or
## gamepad (D-pad up/down picks a slider, left/right changes it).

const ROWS := [
	["lantern_burn_per_sec", "Burn rate (fuel/s)", 0.05, 5.0, 0.05],
	["lantern_max_radius", "Lantern radius (px)", 64.0, 512.0, 8.0],
	["lantern_min_radius_frac", "Radius when nearly empty", 0.1, 1.0, 0.05],
	["fuel_per_unit", "Lantern fuel per carried fuel", 1.0, 50.0, 1.0],
	["gather_interval", "Gather time per unit (s)", 0.05, 2.0, 0.05],
	["fog_creep_per_sec", "Fog creep (/s)", 0.0, 0.5, 0.01],
	["fog_clear_per_sec", "Fog clear (/s)", 0.1, 3.0, 0.05],
	["fog_slow_min", "Walk speed in full fog", 0.2, 1.0, 0.05],
	["hand_lamp_max_radius", "Hand lamp radius (px)", 48.0, 256.0, 4.0],
	["hand_lamp_drain_per_sec", "Hand lamp drain (/s)", 0.0, 0.2, 0.005],
	["marsh_creep_mult", "Marsh fog creep x", 1.0, 4.0, 0.1],
	["reservoir_feed_per_sec", "Reservoir feed (fuel/s)", 0.0, 3.0, 0.1],
	["wind_burn_mult", "Gust burn x (exposed)", 1.0, 5.0, 0.25],
	["wick_spawn_sec", "Wickling spawn every (s)", 4.0, 60.0, 1.0],
	["wick_speed", "Wickling speed", 20.0, 160.0, 5.0],
	["wick_drain_per_sec", "Wickling drain (fuel/s)", 0.0, 15.0, 0.5],
	["warmth_drain_per_sec", "Warmth loss on touch (/s)", 0.0, 100.0, 5.0],
	["beam_dps", "Beam damage (hp/s)", 0.2, 6.0, 0.1],
	["beam_length", "Beam length (px)", 80.0, 400.0, 10.0],
	["beam_sec_per_fuel", "Beam seconds per fuel", 0.3, 5.0, 0.1],
]

var panel: PanelContainer
var first_slider: HSlider

func _ready() -> void:
	layer = 10
	panel = PanelContainer.new()
	panel.position = Vector2(16, 200)   # below the HUD text
	panel.add_theme_stylebox_override("panel", _bg())
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 500)
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(340, 0)
	scroll.add_child(box)
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

static func _bg() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.08, 0.92)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	return sb

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		panel.visible = not panel.visible
		Tuning.ui_open = panel.visible
		if panel.visible:
			first_slider.grab_focus()
		else:
			get_viewport().gui_release_focus()
		get_viewport().set_input_as_handled()
