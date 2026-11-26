extends Node2D
## Visible wind: short pale streaks blowing across the screen in the wind's direction.
## A few faint ones while a gust is building, many bright ones during the gust.
## Lives on the fog layer so the scene darkness doesn't hide it.

const MAX := 90

var _streaks: Array = []   # [position, length, speed, alpha]
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	z_index = 5

func _wind() -> Wind:
	return get_tree().get_first_node_in_group("wind") as Wind

func _view() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var size := get_viewport().get_visible_rect().size
	if cam == null:
		return Rect2(Vector2.ZERO, size)
	var half := size / cam.zoom / 2.0
	return Rect2(cam.get_screen_center_position() - half, half * 2.0)

func active_count() -> int:
	return _streaks.size()

func _process(delta: float) -> void:
	var wind := _wind()
	var level := wind.gust_level() if wind else 0.0
	var want := int(MAX * level)
	var view := _view()
	var dir := Vector2(wind.direction) if wind else Vector2.RIGHT
	while _streaks.size() < want:
		_streaks.append([Vector2(rng.randf_range(view.position.x, view.end.x), rng.randf_range(view.position.y, view.end.y)),
			rng.randf_range(18.0, 46.0), rng.randf_range(380.0, 620.0), rng.randf_range(0.15, 0.45)])
	if _streaks.size() > want:
		_streaks.resize(want)
	var grown := view.grow(80.0)
	for s in _streaks:
		s[0] += dir * s[2] * delta
		if not grown.has_point(s[0]):
			# Re-enter from the upwind edge.
			s[0] = Vector2(rng.randf_range(view.position.x, view.end.x), rng.randf_range(view.position.y, view.end.y)) - dir * view.size * 0.6
	queue_redraw()

func _draw() -> void:
	var wind := _wind()
	if wind == null:
		return
	var dir := Vector2(wind.direction)
	for s in _streaks:
		draw_line(s[0], s[0] - dir * s[1], Color(0.82, 0.86, 0.95, s[3]), 1.5)
