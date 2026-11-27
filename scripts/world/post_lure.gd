class_name PostLure
extends Node2D
## Red pulse visible through fog, marking the cold keeper's post in the Hollow.

var _t := 0.0

func _process(delta: float) -> void:
	visible = not Progress.notes_read.has("crook_post")
	_t += delta
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 2.0)
	draw_circle(Vector2(9, -28), 8.0 + 4.0 * pulse, Color(0.86, 0.28, 0.34, 0.1 + pulse * 0.12))
	draw_circle(Vector2(9, -28), 3.0, Color(0.96, 0.39, 0.43, 0.85))
	draw_arc(Vector2(9, -28), 12.0 + pulse * 6.0, 0.0, TAU, 24, Color(0.96, 0.39, 0.43, 0.6 - pulse * 0.3), 2.0)
