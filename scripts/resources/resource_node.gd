class_name ResourceNode
extends Node2D
## A gatherable spot: a dead tree (fuel/resin) or a ruin pile (scrap).
## Only visible and gatherable on lit ground. Regrows slowly while lit.
## The hut woodpile (always_regrow) regrows even in the dark, so the game can never soft-lock.

const REVEAL_BELOW := 0.35

var kind := "fuel"
var amount := 4
var max_amount := 6
var regrow_sec := 60.0
var always_regrow := false
var _regrow_acc := 0.0

func _ready() -> void:
	add_to_group("resource")
	z_index = 15

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func is_revealed() -> bool:
	var fog := _fog()
	return fog != null and fog.density_at(global_position) < REVEAL_BELOW

func can_gather() -> bool:
	return amount > 0 and is_revealed()

func take() -> bool:
	if amount <= 0:
		return false
	amount -= 1
	queue_redraw()
	return true

func display_name() -> String:
	if always_regrow:
		return "Woodpile"
	return "Dead tree (resin)" if kind == "fuel" else "Ruin (scrap)"

func _process(delta: float) -> void:
	visible = is_revealed()
	if amount >= max_amount:
		_regrow_acc = 0.0
		return
	if always_regrow or is_revealed():
		_regrow_acc += delta
		if _regrow_acc >= regrow_sec:
			_regrow_acc = 0.0
			amount += 1
			queue_redraw()

func _draw() -> void:
	var fade := 1.0 if amount > 0 else 0.4
	if always_regrow:
		for i in 3:
			draw_rect(Rect2(-14, 4 - i * 6, 28, 5), Color(0.45, 0.32, 0.2, fade))
		for i in amount:
			draw_circle(Vector2(-10 + i * 5, -14), 2.0, Color(1.0, 0.7, 0.3))
	elif kind == "fuel":
		var bark := Color(0.38, 0.3, 0.24, fade)
		draw_line(Vector2(0, 10), Vector2(0, -20), bark, 4.0)
		draw_line(Vector2(0, -8), Vector2(-10, -16), bark, 2.0)
		draw_line(Vector2(0, -12), Vector2(9, -22), bark, 2.0)
		for i in amount:
			draw_circle(Vector2(-6 + (i % 4) * 4, 6 - (i / 4) * 5), 2.0, Color(1.0, 0.7, 0.3))
	else:
		var metal := Color(0.55, 0.58, 0.62, fade)
		draw_colored_polygon(PackedVector2Array([Vector2(-12, 8), Vector2(-4, -6), Vector2(6, -2), Vector2(12, 8)]), metal)
		for i in amount:
			draw_rect(Rect2(-10 + (i % 4) * 6, -12 - (i / 4) * 5, 4, 3), Color(0.75, 0.78, 0.82))
