extends CanvasLayer
## HUD (owner-approved mockup, 2026-11-26):
##   top left   one panel: fuel / scrap / glass with icons, hand-lamp and warmth meters
##   top centre the current goal in a banner
##   top right  status chips, only while something needs you (wind, cold lanterns, cold keeper)
##   bottom     the action bar with warmth and charge above it (M1a, action_bar.gd); a quiet key reminder
##              that fades after a minute; tips and toasts in panels above the bar
## What you can do with the thing in front of you is shown over it (see world_prompt.gd).

const KEY_HINT_SECS := 60.0
# M1a texts (DRAFT, docs/replan/M1A_BUILD_NOTES.md).
const LANCE_TOAST := "Lance takes %s. %s is in your Skills (%s)."
const LANCE_TOAST_PLAIN := "Lance takes %s."
const REST_TOAST := "You rest by the WayLamp. Your flasks and warmth are full."
const HUNTED_CHIP := "Something hunts you: light won't warm you"
const LEVEL_UP_SCRIPT := preload("res://scripts/ui/level_up.gd")

var banner: Label
var toast: Label
var tip: Label
var goal_panel: PanelContainer
var goal_label: Label
var counts := {}          # kind -> Label
var glass_row: Control
var action_bar: ActionBar
var wick_bar: ProgressBar
var wick_level: Label
var wick_count: Label          # "12/24": wick toward the next level
var wick_row: HBoxContainer
var _level_flash_pending := false
var level_up_screen: Node
var chips: VBoxContainer
var keys: Label
var building: Label
var building_pic: TextureRect
var _banner_t := 0.0
var _toast_t := 0.0
var _tip_t := 0.0
var _tips: Array[String] = []
var _goal_flash := 0.0
var _status: Array = []   # [[icon, text, color], ...] currently shown
var _keys_t := KEY_HINT_SECS

func _ready() -> void:
	Progress.level_up.connect(func(_lv: int): _level_flash_pending = true)
	add_to_group("hud")
	layer = 5
	_build_resource_panel()
	_build_goal_banner()
	level_up_screen = LEVEL_UP_SCRIPT.new()
	add_child(level_up_screen)
	chips = VBoxContainer.new()
	# Pinned to the top-right corner and growing leftwards, so a long chip never runs off screen.
	chips.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	chips.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	chips.offset_left = -316
	chips.offset_right = -16
	chips.offset_top = 84   # below the goal banner, which can be wide with long goals
	chips.custom_minimum_size = Vector2(300, 0)
	chips.add_theme_constant_override("separation", 6)
	add_child(chips)
	banner = _centered_label(60, 150)
	toast = _boxed_label(30, 470, UiStyle.CREAM)
	tip = _boxed_label(20, 424, UiStyle.PALE)
	keys = UiStyle.label(20, Color(0.43, 0.56, 0.7))
	keys.position = Vector2(18, 632)
	add_child(keys)
	action_bar = ActionBar.new()
	action_bar.name = "ActionBar"
	add_child(action_bar)
	Progress.skill_learned.connect(_on_skill_learned)
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
	# Warmth and lamp charge moved to the action bar (M1a, GAME_PLAN §14).
	# Level and wick (balance pass): "Lv 3", a bar toward the next level, and the count.
	wick_row = HBoxContainer.new()
	wick_row.add_theme_constant_override("separation", 8)
	col.add_child(wick_row)
	wick_level = UiStyle.label(20, UiStyle.GOLD)
	wick_level.custom_minimum_size = Vector2(52, 0)
	wick_row.add_child(wick_level)
	wick_bar = ProgressBar.new()
	wick_bar.custom_minimum_size = Vector2(120, 14)
	wick_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wick_bar.show_percentage = false
	wick_bar.max_value = 1.0
	var wick_styles := UiStyle.bar(Color(0.56, 0.7, 0.82))
	wick_bar.add_theme_stylebox_override("background", wick_styles[0])
	wick_bar.add_theme_stylebox_override("fill", wick_styles[1])
	wick_row.add_child(wick_bar)
	wick_count = UiStyle.label(20, UiStyle.PALE)
	wick_count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wick_row.add_child(wick_count)
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", 8)
	col.add_child(b)
	building_pic = TextureRect.new()
	building_pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	building_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	building_pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	building_pic.custom_minimum_size = Vector2(24, 32)
	b.add_child(building_pic)
	building = UiStyle.label(20, UiStyle.PALE)
	building.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_child(building)

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
	goal_label = UiStyle.label(30, UiStyle.GOLD)
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
	Progress.region_settled.connect(func(_r: int, n: String) -> void:
		banner.text = "%s is held" % n
		_banner_t = 5.0
		# On the tip line (queued), so the goal's "Done:" toast that comes with it doesn't replace it.
		_tips.push_front("The WayLamp took. Its lanterns won't burn down now, and nothing comes here."))
	Progress.landmark_spotted.connect(func(title: String) -> void:
		_show_toast("Something catches the light: %s" % title, 4.0))
	Progress.lantern_unlocked.connect(func(k: String) -> void:
		_show_toast("New lantern unlocked: %s   [%s]" % [Lantern.display(k), InputHint.key("build_menu")], 5.0)
		Sfx.play("unlock", -6.0))

## Level 2: Lance takes slot 3, and the toast says where the skill it replaced went (GAME_PLAN §4.1).
func _on_skill_learned(id: String) -> void:
	if id != "lance":
		return
	var gone := Progress.last_displaced
	var player = get_tree().get_first_node_in_group("player")
	var gone_title := ""
	if gone != "" and player:
		var s: Skill = player.combat.skill(gone)
		gone_title = s.title() if s else gone
	if gone_title != "":
		_show_toast(LANCE_TOAST % [InputHint.key("skill_3"), gone_title, InputHint.key("skills")], 6.0)
	else:
		_show_toast(LANCE_TOAST_PLAIN % InputHint.key("skill_3"), 5.0)
	Sfx.play_ui("unlock", -8.0)

func show_rest() -> void:
	_show_toast(REST_TOAST, 4.0)

func _show_toast(text: String, secs: float) -> void:
	toast.text = text
	_toast_t = secs

func _fade(c: CanvasItem, t: float) -> void:
	c.modulate.a = clampf(minf(t / 1.2, 1.0), 0.0, 1.0) if t > 0.0 else 0.0

# --- Every frame ------------------------------------------------------------------

## What needs the keeper right now: [[icon, text, color], ...]. Public for tests.
func status_items() -> Array:
	var out := []
	# Wind only matters when it reaches your lanterns: say how many it is hitting.
	var wind := get_tree().get_first_node_in_group("wind") as Wind
	if wind and wind.state != Wind.State.CALM:
		var hit := 0
		for l in get_tree().get_nodes_in_group("lantern"):
			if l.is_lit() and l.needs_fuel() and not l.is_held() and not l.wind_proof() and not l.is_sheltered_from(wind.direction):
				hit += 1
		if hit > 0:
			var what := "Gust" if wind.state == Wind.State.GUST else "Wind rising"
			out.append(["icon_wind", "%s: %d lantern%s exposed" % [what, hit, "" if hit == 1 else "s"], UiStyle.WARN if wind.state == Wind.State.GUST else UiStyle.PALE])
	var smothered := 0
	for m in get_tree().get_nodes_in_group("mirror"):
		if m.is_smothered():
			smothered += 1
	if smothered > 0:
		out.append(["icon_cold", "%d mirror%s smothered" % [smothered, "" if smothered == 1 else "s"], UiStyle.WARN])
	var markers = get_tree().get_first_node_in_group("lantern_markers")
	if markers:
		var need: Array = markers.needs_attention()
		var cold := need.filter(func(l): return not l.is_lit()).size()
		var low := need.size() - cold
		if cold > 0:
			out.append(["icon_cold", "%d lantern%s gone cold" % [cold, "" if cold == 1 else "s"], UiStyle.WARN])
		if low > 0:
			out.append(["icon_fuel", "%d lantern%s dying (under a quarter)" % [low, "" if low == 1 else "s"], UiStyle.WARN])
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.kindling:
			out.append(["icon_goal", "Kindling: %ds. Keep the dark off it" % ceili(w.seconds_left()), UiStyle.GOLD])
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.hunted:
			out.append(["icon_cold", HUNTED_CHIP, UiStyle.WARN])
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
		var l := UiStyle.label(20, it[2])
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
	var sel := Progress.selected
	building.text = "%s   [%s] switch" % [Lantern.display(sel), InputHint.key("build_menu")]
	building_pic.texture = Art.placeholder({"post": "post_lamp_lit.png", "reservoir": "reservoir_lamp_lit.png", "hooded": "hooded_lamp_lit.png", "mirror": "mirror_post_lit.png"}.get(sel, "post_lamp_lit.png"))
	_update_wick()
	# Status chips: rebuilt only when what they say changes.
	var items := status_items()
	if str(items) != str(_status):
		_status = items
		_rebuild_chips(items)
	# Key reminder: fades after the first minute (and briefly returns when you switch device).
	_keys_t = maxf(0.0, _keys_t - delta)
	if InputHint.pad:
		keys.text = "View journal    Start pause\nD-pad up map    down skills\nD-pad left / right lamps"
	else:
		keys.text = "%s journal    %s map\n%s lamps    %s skills\n%s pause" % [InputHint.key("journal"), InputHint.key("map"), InputHint.key("build_menu"), InputHint.key("skills"), InputHint.key("pause")]
	keys.modulate.a = clampf(_keys_t / 3.0, 0.0, 0.8)

## The level, the bar toward the next level and the count; a short gold flash when the level goes up.
func _update_wick() -> void:
	wick_level.text = "Lv %d" % Progress.level
	if Progress.at_level_cap():
		wick_bar.value = 1.0
		wick_count.text = "max"
	else:
		wick_bar.value = float(Progress.wick) / float(maxi(1, Progress.wick_needed()))
		wick_count.text = "%d/%d" % [Progress.wick, Progress.wick_needed()]
	wick_bar.tooltip_text = "Wick: %s" % wick_count.text
	# Only a real level-up flashes (not loading a save); this runs once the choice closes.
	if _level_flash_pending:
		_level_flash_pending = false
		wick_row.modulate = Color(2.0, 1.7, 1.0)
		var tw := wick_row.create_tween()
		tw.tween_property(wick_row, "modulate", Color.WHITE, 1.2)
