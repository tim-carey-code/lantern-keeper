extends Node2D
## PROTOTYPE (Keeper's Light): names and health bars over foes, on the fog layer so they read in the dark.
## A bar shows over a foe that was hurt in the last few seconds, and always over the big ones
## (shelled, Clinker, nest) when you're near. The shell is its own pale bar above the red one.
## The Ashbrood gets the boss bar instead (boss_bar.gd).
## M1c light states (PLAN_LANTERNS §2.1): a foe in the dark has its bar dimmed and, on a shell bar, a dark notch at
## the floor its shell can't wear past; a lit (exposed) foe gets a 1 px warm rim on the side facing the lamp and
## pale cracks on its shell. The locked foe's bar always shows, with warm corner ticks.

const FONT := preload("res://assets/fonts/ark_pixel_10px_proportional_latin.ttf")
const SIZE := 20
const SHOW_AFTER_HURT := 4.0
const NEAR := 420.0

func _ready() -> void:
	z_index = 11

func _process(_delta: float) -> void:
	queue_redraw()

func wants_bar(f: Foe, player: Node2D) -> bool:
	if f is Ashbrood or f.hp_max <= 0.0 or f.is_queued_for_deletion():
		return false
	if LockOn.current and LockOn.current.has_target() and LockOn.current.target == f:
		return true
	if f.since_hurt < SHOW_AFTER_HURT:
		return true
	var big: bool = f.shell_max > 0.0 or f is Clinker or f is WickNest
	return big and player != null and player.global_position.distance_to(f.global_position) < NEAR

## The lit and dark cues (M1c): a warm rim on the side facing the lamp, and pale cracks on a lit shell.
func _draw_light_cues(f: Foe) -> void:
	if f.light_exempt() or f._dead or f.is_queued_for_deletion() or not f.is_exposed() or f.light_from == Vector2.INF:
		return
	var c: Vector2 = f.global_position
	var r: float = f.body_radius() + 1.5
	var a := (f.light_from - c).angle()
	draw_arc(c, r, a - 0.9, a + 0.9, 12, Color(1.0, 0.78, 0.42, 0.85), 1.0)
	if f.shell > 0.0:
		var cr := Color(0.92, 0.95, 1.0, 0.8)
		draw_polyline(PackedVector2Array([c + Vector2(-r * 0.5, -r * 0.6), c + Vector2(-r * 0.2, -r * 0.2), c + Vector2(-r * 0.35, r * 0.2)]), cr, 1.0)
		draw_polyline(PackedVector2Array([c + Vector2(r * 0.45, -r * 0.4), c + Vector2(r * 0.15, 0.0), c + Vector2(r * 0.3, r * 0.4)]), cr, 1.0)

func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var locked: Foe = LockOn.current.target if LockOn.current and LockOn.current.has_target() else null
	for f in get_tree().get_nodes_in_group("foe"):
		if not (f is Foe):
			continue
		_draw_light_cues(f)
		if not wants_bar(f, player):
			continue
		var w := 40.0 if f.body_radius() < 14.0 else 64.0
		var top: Vector2 = f.global_position + Vector2(-w / 2.0, -f.body_radius() - 26.0)
		var dark: bool = f.effective_light() == Foe.DARK and not f.light_exempt()
		var dim_a := 0.45 if dark else 1.0   # in the dark the bar is dimmed
		# Health (red), then shell (pale blue) just above it.
		draw_rect(Rect2(top, Vector2(w, 5)), Color(0, 0, 0, 0.75))
		draw_rect(Rect2(top, Vector2(w * clampf(f.hp / f.hp_max, 0.0, 1.0), 5)), Color(0.9, 0.3, 0.25, dim_a))
		if f.shell_max > 0.0:
			draw_rect(Rect2(top - Vector2(0, 6), Vector2(w, 4)), Color(0, 0, 0, 0.75))
			draw_rect(Rect2(top - Vector2(0, 6), Vector2(w * clampf(f.shell / f.shell_max, 0.0, 1.0), 4)), Color(0.7, 0.82, 0.95, dim_a))
			if dark:
				# The floor its shell holds at in the dark: a dark notch.
				var fx: float = top.x + w * clampf(minf(Tuning.kl_dark_shell_floor, f.shell_max) / f.shell_max, 0.0, 1.0)
				draw_rect(Rect2(Vector2(fx - 1.0, top.y - 8.0), Vector2(2, 8)), Color(0.04, 0.05, 0.09, 1.0))
		if f == locked:
			for sx in [-1.0, 1.0]:
				var cx: float = f.global_position.x + sx * (w / 2.0 + 4.0)
				draw_line(Vector2(cx, top.y - 8.0), Vector2(cx, top.y + 7.0), LockOn.MARKER, 2.0)
		var label: String = f.bar_name()
		if label != "":
			var tw := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
			var at := Vector2(f.global_position.x - tw / 2.0, top.y - (10.0 if f.shell_max > 0.0 else 4.0))
			draw_string(FONT, at + Vector2(1, 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(0, 0, 0, 0.8))
			# Dimmed when it is too far below the keeper to pay full wick.
			var col: Color = UiStyle.CREAM if Progress.wick_gap_mult(f.level) >= 1.0 else Color(0.62, 0.6, 0.56)
			draw_string(FONT, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, col)
			# M2: an elite's affixes on a line above its name (GAME_PLAN §14), in the cold tell colour.
			var aff: String = f.affix_line()
			if aff != "":
				var aw := FONT.get_string_size(aff, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
				var ap := Vector2(f.global_position.x - aw / 2.0, at.y - float(SIZE) - 2.0)
				draw_string(FONT, ap + Vector2(1, 1), aff, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(0, 0, 0, 0.8))
				draw_string(FONT, ap, aff, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Telegraph.COLD)
