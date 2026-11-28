class_name ActionBar
extends Control
## The action bar and the keeper's two bars (M1a, GAME_PLAN §3, §14), code-built in the UiStyle look.
## Bottom centre, laid out like the pad: LT (dash) and LB on the left, Y in the middle, RB and RT on the right,
## then the lamp-oil flask with its pips. Each slot shows the button for the device used last (InputHint),
## a dark radial sweep while it cools down (with seconds when more than 3 are left), and greys out when you are
## short of charge. Above it: warmth and lamp charge, with a tick on the charge bar for each skill's cost.
## Icons are drawn by code (no new art files). Ark Pixel at 20 only.

const FONT := preload("res://assets/fonts/ark_pixel_10px_proportional_latin.ttf")
const SLOT := 48.0
const GAP := 10.0
const ORDER := ["dash", "skill_3", "skill_4", "skill_2", "skill_1", "flask"]
const BOTTOM := 30.0           # px from the screen's bottom edge to the slots' bottom (room for the key caps)

var player: Node
var _pip_flash := 0.0
var _last_flasks := -1
var _flash_slot := {}          # slot -> s left of the "ready again" glint

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(1280, 720)
	position = Vector2.ZERO

## Slot rectangles by name (public for tests and captures).
func slot_rects() -> Dictionary:
	var total := ORDER.size() * SLOT + (ORDER.size() - 1) * GAP + 12.0
	var x := (1280.0 - total) / 2.0
	var y := 720.0 - BOTTOM - SLOT
	var out := {}
	for i in ORDER.size():
		if ORDER[i] == "flask":
			x += 12.0   # the flask sits a little apart, at the right end
		out[ORDER[i]] = Rect2(x, y, SLOT, SLOT)
		x += SLOT + GAP
	return out

func bars_rect() -> Rect2:
	var r := slot_rects()
	var left: Rect2 = r["dash"]
	var right: Rect2 = r["flask"]
	return Rect2(left.position.x, left.position.y - 34.0, right.end.x - left.position.x, 28.0)

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player:
		if _last_flasks >= 0 and player.flasks > _last_flasks:
			_pip_flash = 0.7   # a flask came back: its pip flashes
		_last_flasks = player.flasks
	_pip_flash = maxf(0.0, _pip_flash - delta)
	for k in _flash_slot.keys():
		_flash_slot[k] -= delta
		if _flash_slot[k] <= 0.0:
			_flash_slot.erase(k)
	queue_redraw()

## What one slot shows: {id, title, cd, cd_max, short, key}. Public for tests.
func slot_state(slot: String) -> Dictionary:
	var out := {"id": "", "cd": 0.0, "cd_max": 0.0, "short": false, "key": InputHint.short(slot)}
	if player == null:
		return out
	var c: KeeperCombat = player.combat
	match slot:
		"dash":
			out["id"] = "dash"
			out["cd"] = c.dash_cd
			out["cd_max"] = Tuning.kl_dash_cd
			out["short"] = player.lamp_charge < Tuning.kl_dash_cost
		"flask":
			out["id"] = "flask"
			out["cd"] = player.flask_lock
			out["cd_max"] = Tuning.kl_flask_lockout
			out["short"] = player.flasks <= 0
		_:
			var s := c.slot_skill(slot)
			if s:
				out["id"] = s.id
				out["cd"] = s.cd
				out["cd_max"] = s.cooldown()
				out["short"] = s.short_of_charge()
	return out

func _draw() -> void:
	if player == null:
		return
	_draw_bars()
	var rects := slot_rects()
	for slot in ORDER:
		_draw_slot(rects[slot], slot_state(slot), slot)

func _draw_bars() -> void:
	var r := bars_rect()
	var w := r.size.x - 22.0
	var x := r.position.x + 22.0
	# Warmth (health) on top, charge below, each with its icon.
	var warm: float = clampf(player.warmth / Tuning.warmth_max, 0.0, 1.0)
	var charge: float = clampf(player.lamp_charge / Progress.charge_max(), 0.0, 1.0)
	draw_texture_rect(UiStyle.icon("icon_warmth"), Rect2(r.position.x, r.position.y - 2.0, 16, 16), false)
	draw_texture_rect(UiStyle.icon("icon_lamp"), Rect2(r.position.x, r.position.y + 14.0, 16, 16), false)
	draw_rect(Rect2(x, r.position.y, w, 10), Color(0.043, 0.055, 0.1, 0.92))
	draw_rect(Rect2(x, r.position.y, w * warm, 10), UiStyle.WARN if warm < 0.35 else Color(0.85, 0.89, 0.94))
	draw_rect(Rect2(x, r.position.y + 16.0, w, 10), Color(0.043, 0.055, 0.1, 0.92))
	draw_rect(Rect2(x, r.position.y + 16.0, w * charge, 10), UiStyle.AMBER)
	# A tick on the charge bar at each bar skill's cost: you can see at a glance what you can afford.
	for slot in ["skill_2", "skill_3", "skill_4"]:
		var s: Skill = player.combat.slot_skill(slot)
		if s and s.cost() > 0.0 and not s.held():
			var tx := x + w * clampf(s.cost() / Progress.charge_max(), 0.0, 1.0)
			draw_rect(Rect2(tx - 1.0, r.position.y + 13.0, 2.0, 16.0), Color(UiStyle.CREAM, 0.85 if charge >= s.cost() else 0.45))

func _draw_slot(rect: Rect2, st: Dictionary, slot: String) -> void:
	var id: String = st["id"]
	var short: bool = st["short"]
	var cd: float = st["cd"]
	var cd_max: float = st["cd_max"]
	var border := UiStyle.GOLD if slot == "skill_1" else Color(0.43, 0.56, 0.7, 0.9)
	if id == "":
		border = Color(0.29, 0.42, 0.58, 0.5)
	draw_style_box(UiStyle.panel(border, Color(0.043, 0.055, 0.1, 0.92), 2, 0), rect)
	var c := rect.get_center()
	var dim := short or id == ""
	var tint := Color(0.42, 0.45, 0.52, 0.9) if dim else Color.WHITE
	if id != "":
		_draw_icon(id, c, tint)
	else:
		draw_line(c + Vector2(-8, 0), c + Vector2(8, 0), Color(0.43, 0.56, 0.7, 0.6), 2.0)
	# Cooldown: a dark radial sweep that shrinks clockwise as it comes back.
	if cd > 0.0 and cd_max > 0.0:
		var frac := clampf(cd / cd_max, 0.0, 1.0)
		var pts := PackedVector2Array([c])
		var steps := 24
		for i in steps + 1:
			var a := -PI / 2.0 + TAU * (1.0 - frac) + TAU * frac * float(i) / steps
			var p := c + Vector2.from_angle(a) * SLOT
			pts.append(Vector2(clampf(p.x, rect.position.x + 2, rect.end.x - 2), clampf(p.y, rect.position.y + 2, rect.end.y - 2)))
		draw_colored_polygon(pts, Color(0.0, 0.0, 0.02, 0.62))
		if cd > 3.0:
			var txt := str(ceili(cd))
			var tw := FONT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(FONT, c + Vector2(-tw / 2.0 + 1.0, 8.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, 0.9))
			draw_string(FONT, c + Vector2(-tw / 2.0, 7.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UiStyle.CREAM)
	if short and id != "" and id != "flask":
		draw_rect(Rect2(rect.position + Vector2(2, 2), rect.size - Vector2(4, 4)), Color(0.05, 0.06, 0.1, 0.35))
	# The flask's pips: one per charge, gold when full; one flashes when it comes back.
	if slot == "flask":
		var n: int = player.flask_max()
		var pw := 6.0
		var px := c.x - (n * pw + (n - 1) * 3.0) / 2.0
		for i in n:
			var full: bool = i < player.flasks
			var col := UiStyle.GOLD if full else Color(0.2, 0.24, 0.32)
			if full and i == player.flasks - 1 and _pip_flash > 0.0:
				col = Color(1.6, 1.4, 1.0).lerp(UiStyle.GOLD, 1.0 - _pip_flash / 0.7)
			draw_rect(Rect2(px + i * (pw + 3.0), rect.end.y - 9.0, pw, 5.0), col)
	# The button for the device used last, in a gold key cap under the slot.
	var key: String = st["key"]
	var kw := FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 10.0
	var cap := Rect2(c.x - kw / 2.0, rect.end.y + 2.0, kw, 22.0)
	draw_rect(cap, Color(UiStyle.GOLD, 0.95 if id != "" else 0.5))
	draw_string(FONT, Vector2(cap.position.x + 5.0, cap.position.y + 1.0 + FONT.get_ascent(20)), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.043, 0.055, 0.1))

## Small code-drawn icons, about 32 px across, centred on c.
func _draw_icon(id: String, c: Vector2, tint: Color) -> void:
	var fire := Color(1.0, 0.65, 0.26) * tint
	var hot := Color(1.0, 0.92, 0.7) * tint
	var pale := Color(0.64, 0.74, 0.83) * tint
	match id:
		"lampfire":
			for i in 3:
				draw_line(c + Vector2(-14 + i * 2, 8 - i * 6), c + Vector2(-2, 2 - i * 2), Color(fire, 0.5), 2.0)
			draw_circle(c + Vector2(4, -3), 8.0, fire)
			draw_circle(c + Vector2(5, -4), 4.0, hot)
		"fireglobe":
			for i in 5:
				var t := float(i) / 4.0
				draw_circle(c + Vector2(-14 + 20 * t, 10 - sin(t * PI) * 16.0), 1.5, Color(fire, 0.7))
			draw_arc(c + Vector2(8, 10), 8.0, 0.0, TAU, 16, Color(fire, 0.6), 1.5)
			draw_circle(c + Vector2(6, -8), 7.0, fire)
			draw_circle(c + Vector2(6, -8), 3.5, hot)
		"lance":
			draw_line(c + Vector2(-14, 12), c + Vector2(12, -12), Color(fire, 0.6), 4.0)
			draw_line(c + Vector2(-12, 10), c + Vector2(13, -13), hot, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(15, -15), c + Vector2(6, -11), c + Vector2(11, -6)]), hot)
		"beam":
			draw_line(c + Vector2(-15, 10), c + Vector2(15, -10), Color(fire, 0.35), 10.0)
			draw_line(c + Vector2(-15, 10), c + Vector2(15, -10), hot, 3.0)
			draw_circle(c + Vector2(-14, 10), 4.0, hot)
		"hearth_ring":
			draw_arc(c, 11.0, 0.0, TAU, 24, fire, 3.0)
			for i in 6:
				var p := c + Vector2.from_angle(i * TAU / 6.0 - PI / 2.0) * 11.0
				draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 1), p + Vector2(0, -6), p + Vector2(3, 1)]), hot)
		"dash":
			for i in 3:
				var x := -12.0 + i * 8.0
				draw_line(c + Vector2(x, -9), c + Vector2(x + 7, 0), pale, 3.0)
				draw_line(c + Vector2(x + 7, 0), c + Vector2(x, 9), pale, 3.0)
		"flask":
			var body := Color(0.96, 0.65, 0.26) * tint
			draw_rect(Rect2(c + Vector2(-3, -15), Vector2(6, 4)), Color(0.61, 0.29, 0.13) * tint)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -11), c + Vector2(4, -11), c + Vector2(9, -4), c + Vector2(9, 5), c + Vector2(-9, 5), c + Vector2(-9, -4)]), body)
			draw_rect(Rect2(c + Vector2(-7, -1), Vector2(14, 5)), Color(1.0, 0.82, 0.48) * tint)
			draw_rect(Rect2(c + Vector2(-6, -6), Vector2(3, 3)), Color(1.0, 0.95, 0.76) * tint)
