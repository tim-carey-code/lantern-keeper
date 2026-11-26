extends Node2D
## M2 grey-box: Region 1, The Hollow. A bowl of open ground ringed by rock,
## the keeper's hut in the middle, an old lantern, a woodpile, dead trees and ruins.

const HOLLOW_SEED := 11
const FUEL_SPOTS := 30
const SCRAP_SPOTS := 14

@onready var fog: FogGrid = $FogLayer/FogGrid
@onready var player: CharacterBody2D = $Player

var start := Vector2.ZERO
var _stones: Array = []

func _ready() -> void:
	Inventory.reset()
	var size := fog.world_size()
	start = fog.tile_center(fog.tile_of(size / 2.0))
	_carve_hollow()
	_build_rock_collision()
	var cam: Camera2D = $Player/Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(size.x)
	cam.limit_bottom = int(size.y)
	player.position = start
	_add_lantern(start + Vector2(96, 0))
	# Near the hut: a woodpile that always regrows (no soft-lock) and a little scrap.
	_add_resource("fuel", start + Vector2(-64, 32), 3, 5, 10.0, true)
	_add_resource("scrap", start + Vector2(32, -64), 6, 6, 60.0, false)
	_scatter()

# --- Map -------------------------------------------------------------------

func _carve_hollow() -> void:
	var rx := fog.cols * 0.44
	var ry := fog.rows * 0.42
	var cx := fog.cols / 2.0
	var cy := fog.rows / 2.0
	for y in fog.rows:
		for x in fog.cols:
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			var ang := atan2(ny, nx)
			var wobble := 0.07 * sin(ang * 5.0 + 1.3) + 0.04 * sin(ang * 11.0)
			if nx * nx + ny * ny > pow(1.0 + wobble, 2.0):
				fog.solid[y * fog.cols + x] = 1

func _build_rock_collision() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	for y in fog.rows:
		var x := 0
		while x < fog.cols:
			if fog.solid[y * fog.cols + x] == 0:
				x += 1
				continue
			var x0 := x
			while x < fog.cols and fog.solid[y * fog.cols + x] == 1:
				x += 1
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2((x - x0) * FogGrid.TILE, FogGrid.TILE)
			shape.shape = rect
			shape.position = Vector2((x0 + x) * FogGrid.TILE / 2.0, (y + 0.5) * FogGrid.TILE)
			body.add_child(shape)

func _open_spot(p: Vector2) -> bool:
	# Open ground with at least one tile of open ground around it.
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if fog.is_solid_at(p + Vector2(ox, oy) * FogGrid.TILE):
				return false
	return true

func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = HOLLOW_SEED
	var taken: Array[Vector2] = [start]
	for n in get_tree().get_nodes_in_group("resource"):
		taken.append(n.global_position)
	var want := {"fuel": FUEL_SPOTS, "scrap": SCRAP_SPOTS}
	for kind in want:
		var placed := 0
		var tries := 0
		while placed < want[kind] and tries < 4000:
			tries += 1
			var t := Vector2i(rng.randi_range(0, fog.cols - 1), rng.randi_range(0, fog.rows - 1))
			var p := fog.tile_center(t)
			if not _open_spot(p) or p.distance_to(start) < 160.0:
				continue
			var too_close := false
			for q in taken:
				if q.distance_to(p) < 72.0:
					too_close = true
					break
			if too_close:
				continue
			taken.append(p)
			if kind == "fuel":
				_add_resource("fuel", p, rng.randi_range(4, 8), 8, 60.0, false)
			else:
				_add_resource("scrap", p, rng.randi_range(3, 6), 6, 90.0, false)
			placed += 1
	for i in 260:
		var p := Vector2(rng.randf() * fog.world_size().x, rng.randf() * fog.world_size().y)
		if not fog.is_solid_at(p):
			_stones.append([p, rng.randf_range(3.0, 10.0), rng.randf_range(0.0, 0.45)])
	queue_redraw()

func _add_lantern(p: Vector2) -> PostLamp:
	var l := PostLamp.new()
	l.position = fog.tile_center(fog.tile_of(p))
	$Lanterns.add_child(l)
	return l

func _add_resource(kind: String, p: Vector2, amount: int, max_amount: int, regrow: float, always: bool) -> ResourceNode:
	var r := ResourceNode.new()
	r.kind = kind
	r.amount = amount
	r.max_amount = max_amount
	r.regrow_sec = regrow
	r.always_regrow = always
	r.position = fog.tile_center(fog.tile_of(p))
	$Resources.add_child(r)
	return r

func _draw() -> void:
	var t := FogGrid.TILE
	for y in fog.rows:
		for x in fog.cols:
			var rock := fog.solid[y * fog.cols + x] == 1
			var c := Color(0.2, 0.2, 0.22) if rock else Color(0.24, 0.29, 0.21)
			draw_rect(Rect2(x * t, y * t, t, t), c)
	for s in _stones:
		draw_circle(s[0], s[1], Color(0.55, 0.55, 0.5).darkened(s[2]))
	# The keeper's hut.
	var h := start + Vector2(-20, -70)
	draw_rect(Rect2(h, Vector2(40, 28)), Color(0.4, 0.3, 0.22))
	draw_colored_polygon(PackedVector2Array([h + Vector2(-6, 0), h + Vector2(20, -18), h + Vector2(46, 0)]), Color(0.3, 0.2, 0.15))
	draw_rect(Rect2(h + Vector2(15, 12), Vector2(10, 16)), Color(0.85, 0.65, 0.35))
