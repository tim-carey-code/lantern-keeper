extends Node2D
## M0 test scene: a dark field with scattered stones so you can see the
## hand lamp light moving. Replaced by the real valley in M1.

const FIELD := Rect2(-800, -800, 2880, 2320)

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 120:
		var stone := Polygon2D.new()
		var r := rng.randf_range(6.0, 18.0)
		stone.polygon = PackedVector2Array([Vector2(-r, 0), Vector2(0, -r * 0.7), Vector2(r, 0), Vector2(0, r * 0.7)])
		stone.color = Color(0.55, 0.55, 0.5).darkened(rng.randf_range(0.0, 0.4))
		stone.position = Vector2(rng.randf_range(FIELD.position.x, FIELD.end.x), rng.randf_range(FIELD.position.y, FIELD.end.y))
		add_child(stone)

func _draw() -> void:
	draw_rect(FIELD, Color(0.25, 0.3, 0.22))
