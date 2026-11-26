extends Node2D
## M1 grey-box valley: flat ground, scattered stones, one old lantern by the start.

@onready var fog: FogGrid = $FogGrid
var _stones: Array = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var size := fog.world_size()
	for i in 260:
		_stones.append([Vector2(rng.randf() * size.x, rng.randf() * size.y),
			rng.randf_range(4.0, 14.0), rng.randf_range(0.0, 0.45)])
	var cam: Camera2D = $Player/Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(size.x)
	cam.limit_bottom = int(size.y)
	$Player.position = size / 2.0
	var first := PostLamp.new()
	first.position = fog.tile_center(fog.tile_of(size / 2.0 + Vector2(96, 0)))
	$Lanterns.add_child(first)

func _draw() -> void:
	var size := fog.world_size()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.24, 0.29, 0.21))
	for s in _stones:
		draw_circle(s[0], s[1], Color(0.55, 0.55, 0.5).darkened(s[2]))
