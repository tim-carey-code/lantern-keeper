class_name FogGrid
extends Node2D
## Per-tile fog density (0 = clear, 1 = full fog), creep-back, and memory.
## Light sources are nodes in group "light_source" with get_light_radius() -> float.

const TILE := 32
const TICK := 0.1                  # simulation step (s)
const REMEMBER_BELOW := 0.3        # a tile this clear counts as "seen"
const PLACE_MAX_DENSITY := 0.6     # lanterns need lit or edge-of-light ground

@export var cols := 64
@export var rows := 48

var density := PackedFloat32Array()
var remembered := PackedByteArray()
var _light := PackedFloat32Array()
var _acc := 0.0

func _ready() -> void:
	add_to_group("fog_grid")
	z_index = 10
	var n := cols * rows
	density.resize(n)
	density.fill(1.0)
	remembered.resize(n)
	remembered.fill(0)
	_light.resize(n)

func world_size() -> Vector2:
	return Vector2(cols * TILE, rows * TILE)

func tile_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))

func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + TILE / 2.0, t.y * TILE + TILE / 2.0)

func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < cols and t.y < rows

func density_at(p: Vector2) -> float:
	var t := tile_of(p)
	if not in_bounds(t):
		return 1.0
	return density[t.y * cols + t.x]

func revealed_fraction() -> float:
	return float(remembered.count(1)) / float(remembered.size())

func _process(delta: float) -> void:
	_acc += delta
	if _acc < TICK:
		return
	var dt := _acc
	_acc = 0.0
	step(dt)
	queue_redraw()

## Advance the fog simulation by dt seconds. Public so tests can call it.
func step(dt: float) -> void:
	_light.fill(0.0)
	for src in get_tree().get_nodes_in_group("light_source"):
		var r: float = src.get_light_radius()
		if r <= 0.0:
			continue
		var c: Vector2 = src.global_position
		var t0 := tile_of(c - Vector2(r, r))
		var t1 := tile_of(c + Vector2(r, r))
		for y in range(maxi(t0.y, 0), mini(t1.y, rows - 1) + 1):
			for x in range(maxi(t0.x, 0), mini(t1.x, cols - 1) + 1):
				var d := tile_center(Vector2i(x, y)).distance_to(c)
				if d < r:
					# Strong plateau in the middle, soft edge near the rim.
					var s := clampf((1.0 - d / r) * 1.6, 0.0, 1.0)
					var i := y * cols + x
					_light[i] = maxf(_light[i], s)

	var creep := Tuning.fog_creep_per_sec
	var clear := Tuning.fog_clear_per_sec
	var next := density.duplicate()
	for y in rows:
		for x in cols:
			var i := y * cols + x
			var s := _light[i]
			# Fog spreads from foggy neighbours: isolated lights get eaten at the edges.
			var foggy := 0
			foggy += 1 if (x == 0 or density[i - 1] > 0.5) else 0
			foggy += 1 if (x == cols - 1 or density[i + 1] > 0.5) else 0
			foggy += 1 if (y == 0 or density[i - cols] > 0.5) else 0
			foggy += 1 if (y == rows - 1 or density[i + cols] > 0.5) else 0
			var spread := 0.25 + 0.75 * foggy / 4.0
			var v := density[i] + (creep * spread * (1.0 - s) - clear * s) * dt
			v = clampf(v, 0.0, 1.0)
			next[i] = v
			if v < REMEMBER_BELOW:
				remembered[i] = 1
	density = next

func _draw() -> void:
	for y in rows:
		for x in cols:
			var i := y * cols + x
			var v := density[i]
			if v <= 0.02:
				continue
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			if remembered[i] == 1:
				# Seen before: fog never fully hides it again, and an outline stays.
				draw_rect(rect, Color(0.6, 0.64, 0.7, v * 0.8))
				if v > 0.6:
					draw_rect(rect.grow(-3), Color(0.75, 0.8, 0.9, 0.35), false, 1.0)
			else:
				draw_rect(rect, Color(0.6, 0.64, 0.7, v))
