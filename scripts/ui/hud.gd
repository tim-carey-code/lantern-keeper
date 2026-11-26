extends CanvasLayer
## HUD: carried resources, hand lamp, wind, what is nearby, why you can't build,
## controls, plus a region-name banner and unlock messages that fade.

var label: Label
var banner: Label
var toast: Label
var _banner_t := 0.0
var _toast_t := 0.0

func _ready() -> void:
	layer = 5
	label = _make_label(16, Vector2(16, 12))
	banner = _make_label(40, Vector2.ZERO)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.position = Vector2(0, 150)
	banner.size = Vector2(1280, 60)
	banner.modulate.a = 0.0
	toast = _make_label(18, Vector2.ZERO)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.position = Vector2(0, 640)
	toast.size = Vector2(1280, 40)
	toast.modulate.a = 0.0
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
		toast.text = "New lantern unlocked: %s" % Lantern.display(k)
		_toast_t = 5.0)

func _show_toast(text: String, secs: float) -> void:
	toast.text = text
	_toast_t = secs

func _make_label(font_size: int, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	add_child(l)
	return l

func _fade(l: Label, t: float) -> void:
	# Fade in over 0.8 s, hold, fade out over the last 1.2 s.
	l.modulate.a = clampf(minf(t / 1.2, 1.0), 0.0, 1.0) if t > 0.0 else 0.0

func _process(delta: float) -> void:
	_banner_t = maxf(0.0, _banner_t - delta)
	_toast_t = maxf(0.0, _toast_t - delta)
	_fade(banner, _banner_t)
	_fade(toast, _toast_t)
	var lamps := get_tree().get_nodes_in_group("lantern")
	var lit := lamps.filter(func(l): return l.is_lit()).size()
	var fog := get_tree().get_first_node_in_group("fog_grid") as FogGrid
	var player = get_tree().get_first_node_in_group("player")
	var wind := get_tree().get_first_node_in_group("wind") as Wind
	if player == null or fog == null:
		return
	var lim := Inventory.carry_limit
	var lines: Array[String] = []
	lines.append("Fuel %d/%d    Scrap %d/%d    Hand lamp %d%%" % [
		Inventory.get_count("fuel"), lim, Inventory.get_count("scrap"), lim, roundi(player.lamp_charge * 100.0)])
	var where: int = fog.region_at(player.global_position)
	var region_name: String = FogGrid.REGION_NAMES[where] if where < FogGrid.REGION_NAMES.size() else ""
	lines.append("Lanterns lit %d/%d    %s seen %d%%" % [lit, lamps.size(), region_name, roundi(fog.revealed_fraction(where) * 100.0)])
	var markers = get_tree().get_first_node_in_group("lantern_markers")
	if markers:
		var need: Array = markers.needs_attention()
		var cold := need.filter(func(l): return not l.is_lit()).size()
		var low := need.size() - cold
		if need.size() > 0:
			lines.append("Needs fuel: %d cold, %d low (follow the arrows)" % [cold, low])
	if wind and wind.status_text() != "":
		lines.append(wind.status_text())
	var t = player.nearest_target()
	if t is Landmark:
		lines.append("%s: [E / A] %s" % [t.display_name(), "read again" if t.is_read() else "look closer"])
	elif t is Lantern:
		var state := "%d%% fuel" % roundi(t.fuel_frac() * 100.0) if t.is_lit() else "cold"
		var shelter := ""
		if wind and wind.state != Wind.State.CALM:
			shelter = ", sheltered" if t.is_sheltered_from(wind.direction) else ", exposed"
		lines.append("%s (%s%s): [E / A] refuel   [Q / B] pick up" % [Lantern.display(t.kind), state, shelter])
	elif t is ResourceNode:
		var verb := "gathering..." if player.is_gathering() else "hold [E / A] to gather"
		lines.append("%s, %d left: %s" % [t.display_name(), t.amount, verb])
	var reason: String = player.place_block_reason(player.place_pos())
	if reason != "" and reason != "too close to a lantern":
		lines.append("Build here: %s" % reason)
	lines.append("[Space / X] build %s (%d scrap)   [Tab / Y] lanterns   [M / LB] map   [F1 / Select] tuning" % [
		Lantern.display(Progress.selected), Lantern.cost(Progress.selected)])
	label.text = "\n".join(lines)
