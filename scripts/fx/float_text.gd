class_name FloatText
extends Node2D
## A short "+1 scrap" style label that rises and fades. Unaffected by the scene darkness
## when spawned on the fog layer.

const FONT := preload("res://assets/fonts/ark_pixel_10px_proportional_latin.ttf")

var text := ""
var color := Color.WHITE
var _t := 0.0

static func spawn(parent: Node, pos: Vector2, msg: String, col: Color) -> void:
	if parent == null:
		return
	var f := FloatText.new()
	f.text = msg
	f.color = col
	f.position = pos
	f.z_index = 9
	parent.add_child(f)

func _process(delta: float) -> void:
	_t += delta
	position.y -= 24.0 * delta
	if _t > 0.9:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var a := clampf(1.0 - _t / 0.9, 0.0, 1.0)
	draw_string(FONT, Vector2(-20, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, a * 0.8))
	draw_string(FONT, Vector2(-21, -1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(color, a))
