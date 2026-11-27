extends Node2D
## PROTOTYPE (Keeper's Light): names and health bars over foes, on the fog layer so they read in the dark.
## A bar shows over a foe that was hurt in the last few seconds, and always over the big ones
## (shelled, Clinker, nest) when you're near. The shell is its own pale bar above the red one.
## The Ashbrood gets the boss bar instead (boss_bar.gd).

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
	if f.since_hurt < SHOW_AFTER_HURT:
		return true
	var big: bool = f.shell_max > 0.0 or f is Clinker or f is WickNest
	return big and player != null and player.global_position.distance_to(f.global_position) < NEAR

func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for f in get_tree().get_nodes_in_group("foe"):
		if not (f is Foe) or not wants_bar(f, player):
			continue
		var w := 40.0 if f.body_radius() < 14.0 else 64.0
		var top: Vector2 = f.global_position + Vector2(-w / 2.0, -f.body_radius() - 26.0)
		# Health (red), then shell (pale blue) just above it.
		draw_rect(Rect2(top, Vector2(w, 5)), Color(0, 0, 0, 0.75))
		draw_rect(Rect2(top, Vector2(w * clampf(f.hp / f.hp_max, 0.0, 1.0), 5)), Color(0.9, 0.3, 0.25))
		if f.shell_max > 0.0:
			draw_rect(Rect2(top - Vector2(0, 6), Vector2(w, 4)), Color(0, 0, 0, 0.75))
			draw_rect(Rect2(top - Vector2(0, 6), Vector2(w * clampf(f.shell / f.shell_max, 0.0, 1.0), 4)), Color(0.7, 0.82, 0.95))
		var label: String = f.bar_name()
		if label != "":
			var tw := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
			var at := Vector2(f.global_position.x - tw / 2.0, top.y - (10.0 if f.shell_max > 0.0 else 4.0))
			draw_string(FONT, at + Vector2(1, 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(0, 0, 0, 0.8))
			# Dimmed when it is too far below the keeper to pay full wick.
			var col: Color = UiStyle.CREAM if Progress.wick_gap_mult(f.level) >= 1.0 else Color(0.62, 0.6, 0.56)
			draw_string(FONT, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, col)
