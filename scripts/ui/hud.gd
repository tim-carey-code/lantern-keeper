extends CanvasLayer
## HUD (owner-approved mockup, 2026-11-26):
##   top left   one panel: fuel / scrap / glass with icons, hand-lamp and warmth meters
##   top centre the current goal in a banner
##   top right  status chips, only while something needs you (wind, cold lanterns, cold keeper)
##   bottom     a quiet key reminder that fades after a minute; tips and toasts in panels
## What you can do with the thing in front of you is shown over it (see world_prompt.gd).

const KEY_HINT_SECS := 60.0

var banner: Label
var toast: Label
var tip: Label
var goal_panel: PanelContainer
var goal_label: Label
var counts := {}          # kind -> Label
var glass_row: Control
var lamp_bar: ProgressBar
var warm_bar: ProgressBar
var chips: VBoxContainer
var keys: Label
var _banner_t := 0.0
var _toast_t := 0.0
var _tip_t := 0.0
var _tips: Array[String] = []
var _goal_flash := 0.0
var _status: Array = []   # [[icon, text, color], ...] currently shown
var _keys_t := KEY_HINT_SECS

func _ready() -> void:
	layer = 5
	_build_resource_panel()
	_build_goal_banner()
	chips = VBoxContainer.new()
	chips.position = Vector2(1280 - 16 - 300, 16)
	chips.custom_minimum_size = Vector2(300, 0)
	chips.add_theme_constant_override("separation", 6)
	add_child(chips)
	banner = _centered_label(64, 150)
	toast = _boxed_label(28, 630, UiStyle.CREAM)
	tip = _boxed_label(22, 580, UiStyle.PALE)
	keys = UiStyle.label(20, Color(0.43, 0.56, 0.7))
	keys.position = Vector2(18, 690)
	add_child(keys)
	InputHint.device_changed.connect(func(_pad: bool) -> void: _keys_t = 10.0)
	_connect_events()

# --- Building the widgets --------------------------------------------------------

func _build_resource_panel() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD))
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	for kind in ["fuel", "scrap", "glass"]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		item.add_child(UiStyle.icon_rect("icon_" + kind))
		var l := UiStyle.label(30)
		l.custom_minimum_size = Vector2(40, 0)
		item.add_child(l)
		counts[kind] = l
		row.add_child(item)
		if kind == "glass":
			glass_row = item
	lamp_bar = _meter(col, "icon_lamp", UiStyle.AMBER)
	warm_bar = _meter(col, "icon_warmth", Color(0.85, 0.89, 0.94))

func _meter(parent: Control, icon_name: String, fill: Color) -> ProgressBar:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	row.add_child(UiStyle.icon_rect(icon_name, 24))
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = 1.0
	var styles := UiStyle.bar(fill)
	bar.add_theme_stylebox_override("background", styles[0])
	bar.add_theme_stylebox_override("fill", styles[1])
	row.add_child(bar)
	return bar

func _build_goal_banner() -> void:
	goal_panel = PanelContainer.new()
	goal_panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.AMBER, UiStyle.NAVY, 1, 8))
	add_child(goal_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	goal_panel.add_child(row)
	row.add_child(UiStyle.icon_rect("icon_goal", 20))
	goal_label = UiStyle.label(26, UiStyle.GOLD)
	row.add_child(goal_label)

func _centered_label(size: int, y: float) -> Label:
	var l := UiStyle.label(size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(1280, size + 10)
	l.modulate.a = 0.0
	add_child(l)
	return l

## A centered line of text on its own dark panel (tips, toasts).
func _boxed_label(size: int, y: float, color: Color) -> Label:
	var holder := CenterContainer.new()
	holder.position = Vector2(0, y)
	holder.size = Vector2(1280, size + 24)
	add_child(holder)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(Color(0, 0, 0, 0), Color(0.03, 0.04, 0.07, 0.8), 0, 8))
	holder.add_child(panel)
	var l := UiStyle.label(size, color)
	panel.add_child(l)
	holder.modulate.a = 0.0
	l.set_meta("holder", holder)
	return l

# --- Events -----------------------------------------------------------------------

func _connect_events() -> void:
	Story.tip_shown.connect(func(t: String) -> void: _tips.append(t))
	Story.goal_completed.connect(func(_id: String, text: String) -> void:
		_show_toast("Done: " + text, 3.5)
		Sfx.play("unlock", -14.0))
	Story.goal_changed.connect(func(_id: String, _text: String) -> void: _goal_flash = 2.0)
	Story.entry_added.connect(func(title: String) -> void: _tips.push_front("New journal entry: %s   [%s]" % [title, InputHint.key("journal")]))
	Progress.region_revealed.connect(func(n: String) -> void:
		banner.text = n
		_banner_t = 4.0)
	var wind := get_tree().get_first_node_in_group("wind") as Wind
	if wind:
		wind.state_changed.connect(func(s) -> void:
			if s == Wind.State.WARNING:
				_show_toast("The wind is rising from the %s..." % wind.from_name(), 4.0)
			elif s == Wind.State.GUST:
				_show_toast("Gust from the %s! Exposed lanterns burn faster." % wind.from_name(), 5.0))
	Progress.landmark_spotted.connect(func(title: String) -> void:
		_show_toast("Something catches the light: %s" % title, 4.0))
	Progress.lantern_unlocked.connect(func(k: String) -> void:
		_show_toast("New lantern unlocked: %s   [%s]" % [Lantern.display(k), InputHint.key("build_menu")], 5.0)
		Sfx.play("unlock", -6.0))

func _show_toast(text: String, secs: float) -> void:
	toast.text = text
	_toast_t = secs

func _fade(c: CanvasItem, t: float) -> void:
	c.modulate.a = clampf(minf(t / 1.2, 1.0), 0.0, 1.0) if t > 0.0 else 0.0

# --- Every frame ------------------------------------------------------------------

## What needs the keeper right now: [[icon, text, color], ...]. Public for tests.
func status_items() -> Array:
	var out := []
	var wind := get_tree().get_first_node_in_group("wind") as Wind
	if wind and wind.state == Wind.State.WARNING:
		out.append(["icon_wind", "Wind rising (%s)" % wind.from_name(), UiStyle.PALE])
	elif wind and wind.state == Wind.State.GUST:
		out.append(["icon_wind", "Gust from the %s" % wind.from_name(), UiStyle.WARN])
	var markers = get_tree().get_first_node_in_group("lantern_markers")
	if markers:
		var need: Array = markers.needs_attention()
		var cold := need.filter(func(l): return not l.is_lit()).size()
		var low := need.size() - cold
		if cold > 0:
			out.append(["icon_cold", "%d lantern%s gone cold" % [cold, "" if cold == 1 else "s"], UiStyle.WARN])
		if low > 0:
			out.append(["icon_fuel", "%d lantern%s low on fuel" % [low, "" if low == 1 else "s"], UiStyle.GOLD])
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.warmth < Tuning.warmth_max * 0.35:
			out.append(["icon_warmth", "You're getting cold", UiStyle.WARN])
		if player.lamp_charge <= Tuning.ward_min_charge:
			out.append(["icon_lamp", "Hand lamp is an ember", UiStyle.PALE])
	return out

func _rebuild_chips(items: Array) -> void:
	for c in chips.get_children():
		c.queue_free()
	for it in items:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiStyle.panel(Color(0, 0, 0, 0), UiStyle.NAVY, 0, 6))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		p.add_child(row)
		row.add_child(UiStyle.icon_rect(it[0], 22))
		var l := UiStyle.label(22, it[2])
		l.text = it[1]
		row.add_child(l)
		chips.add_child(p)

func _process(delta: float) -> void:
	_banner_t = maxf(0.0, _banner_t - delta)
	_toast_t = maxf(0.0, _toast_t - delta)
	_fade(banner, _banner_t)
	_fade(toast.get_meta("holder"), _toast_t)
	_tip_t = maxf(0.0, _tip_t - delta)
	if _tip_t <= 0.0 and not _tips.is_empty():
		tip.text = _tips.pop_front()
		_tip_t = 6.0
	_fade(tip.get_meta("holder"), _tip_t)
	# Goal banner, centred; glows for a moment when the goal changes.
	_goal_flash = maxf(0.0, _goal_flash - delta)
	goal_panel.visible = Story.current != ""
	goal_label.text = Story.goal_text(Story.current)
	goal_panel.reset_size()
	goal_panel.position = Vector2((1280 - goal_panel.size.x) / 2.0, 16)
	goal_panel.modulate = Color(1, 1, 1).lerp(Color(1.35, 1.2, 0.9), clampf(_goal_flash, 0.0, 1.0))
	# Resources and meters.
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	for kind in counts:
		var n := Inventory.get_count(kind)
		counts[kind].text = str(n)
		counts[kind].add_theme_color_override("font_color", UiStyle.GOLD if n >= Inventory.carry_limit else UiStyle.CREAM)
	glass_row.visible = Inventory.get_count("glass") > 0 or Progress.regions_seen.has(FogGrid.R_RIDGE)
	lamp_bar.value = player.lamp_charge
	warm_bar.value = player.warmth / Tuning.warmth_max
	# Status chips: rebuilt only when what they say changes.
	var items := status_items()
	if str(items) != str(_status):
		_status = items
		_rebuild_chips(items)
	# Key reminder: fades after the first minute (and briefly returns when you switch device).
	_keys_t = maxf(0.0, _keys_t - delta)
	keys.text = "%s journal    %s map    %s lanterns    %s pause" % [InputHint.key("journal"), InputHint.key("map"), InputHint.key("build_menu"), InputHint.key("pause")]
	keys.modulate.a = clampf(_keys_t / 3.0, 0.0, 0.8)
