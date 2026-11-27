class_name WickDrop
extends Node2D
## The keeper's unspent wick waits at the place they fainted.

var amount := 0
var _pulse := 0.0

func _ready() -> void:
	add_to_group("wick_drop")
	z_index = 12

func _process(delta: float) -> void:
	_pulse += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(global_position) <= Tuning.kl_wick_drop_radius:
		Progress.add_wick(amount)
		Sfx.play("unlock", -12.0)
		queue_free()
	queue_redraw()

func _draw() -> void:
	var p := 0.5 + 0.5 * sin(_pulse * 3.0)
	draw_arc(Vector2.ZERO, 9.0 + p * 3.0, 0, TAU, 24, Color(0.61, 0.79, 0.95, 0.45 + p * 0.4), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -7), Vector2(5, 0), Vector2(0, 7), Vector2(-5, 0)]), Color(0.78, 0.89, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(12, -8), str(amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.78, 0.89, 1.0))
