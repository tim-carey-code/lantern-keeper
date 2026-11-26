class_name FogGrid
extends Node2D
## Per-tile terrain, region, fog density (0 = clear, 1 = full fog), creep-back and memory.
## Light sources are nodes in group "light_source" with get_light_radius() -> float.
## Lives on its own CanvasLayer so the scene darkness does not tint it:
## never-seen fog is near black, seen-before fog is a dim blue haze with outlines.

const TILE := 32
const TICK := 0.1                  # simulation step (s)
const REMEMBER_BELOW := 0.3        # a tile this clear counts as "seen"
const PLACE_MAX_DENSITY := 0.6     # lanterns need lit or edge-of-light ground

# Terrain
const T_GROUND := 0
const T_ROCK := 1
const T_MARSH := 2       # soft: walkable, can't build
const T_BOARDWALK := 3   # buildable path through the marsh

const REGION_NAMES := ["", "The Hollow", "The Reedmarsh"]
const R_HOLLOW := 1
const R_MARSH := 2

const UNSEEN := Color(0.02, 0.025, 0.04)
const SEEN := Color(0.09, 0.11, 0.15)
const SEEN_OUTLINE := Color(0.32, 0.38, 0.5)

@export var cols := 112
@export var rows := 64

var density := PackedFloat32Array()
var remembered := PackedByteArray()
var solid := PackedByteArray()     # 1 = rock: no walking, no building
var terrain := PackedByteArray()
var region := PackedByteArray()
var _light := PackedFloat32Array()
var _acc := 0.0

func _ready() -> void:
	add_to_group("fog_grid")
	var n := cols * rows
	# Packed arrays are values, so resize each one directly.
	density.resize(n)
	density.fill(1.0)
	_light.resize(n)
	remembered.resize(n)
	remembered.fill(0)
	solid.resize(n)
	solid.fill(0)
	terrain.resize(n)
	terrain.fill(FogGrid.T_GROUND)
	region.resize(n)
	region.fill(0)

# --- Geometry ----------------------------------------------------------------

func world_size() -> Vector2:
	return Vector2(cols * TILE, rows * TILE)

func tile_of(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))

func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + TILE / 2.0, t.y * TILE + TILE / 2.0)

func in_bounds(t: Vector2i) -> bool:
	return t.x >= 0 and t.y >= 0 and t.x < cols and t.y < rows

func idx(t: Vector2i) -> int:
	return t.y * cols + t.x

func set_tile(t: Vector2i, terrain_type: int, region_id: int) -> void:
	if not in_bounds(t):
		return
	var i := idx(t)
	terrain[i] = terrain_type
	solid[i] = 1 if terrain_type == T_ROCK else 0
	region[i] = region_id

func terrain_of(t: Vector2i) -> int:
	return terrain[idx(t)] if in_bounds(t) else T_ROCK

func density_at(p: Vector2) -> float:
	var t := tile_of(p)
	return density[idx(t)] if in_bounds(t) else 1.0

func is_solid_at(p: Vector2) -> bool:
	var t := tile_of(p)
	return solid[idx(t)] == 1 if in_bounds(t) else true

func terrain_at(p: Vector2) -> int:
	return terrain_of(tile_of(p))

func region_at(p: Vector2) -> int:
	var t := tile_of(p)
	return region[idx(t)] if in_bounds(t) else 0

## "" if the ground itself allows a lantern, otherwise why not.
func build_block(p: Vector2) -> String:
	if is_solid_at(p):
		return "rock"
	if terrain_at(p) == T_MARSH:
		return "soft ground (build on boardwalks or islands)"
	return ""

func revealed_fraction(region_id: int = -1) -> float:
	var open := 0
	var seen := 0
	for i in solid.size():
		if solid[i] == 1 or (region_id >= 0 and region[i] != region_id):
			continue
		open += 1
		if remembered[i] == 1:
			seen += 1
	return float(seen) / float(open) if open > 0 else 0.0

# --- Simulation --------------------------------------------------------------

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

	var wind := get_tree().get_first_node_in_group("wind") as Wind
	var gust := Tuning.wind_creep_mult if wind != null and wind.is_gusting() else 1.0
	var creep_by_region := [Tuning.fog_creep_per_sec, Tuning.fog_creep_per_sec, Tuning.fog_creep_per_sec * Tuning.marsh_creep_mult]
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
			var creep: float = creep_by_region[mini(region[i], creep_by_region.size() - 1)] * gust
			var v := density[i] + (creep * spread * (1.0 - s) - clear * s) * dt
			v = clampf(v, 0.0, 1.0)
			next[i] = v
			if v < REMEMBER_BELOW and remembered[i] == 0:
				remembered[i] = 1
				if region[i] > 0 and region[i] < REGION_NAMES.size():
					Progress.reveal_region(region[i], REGION_NAMES[region[i]])
	density = next

# --- Drawing (only what the camera can see) ---------------------------------

func _visible_tiles() -> Rect2i:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return Rect2i(0, 0, cols, rows)
	var half := get_viewport().get_visible_rect().size / cam.zoom / 2.0
	var c := cam.get_screen_center_position()
	var t0 := tile_of(c - half) - Vector2i(4, 4)
	var t1 := tile_of(c + half) + Vector2i(4, 4)
	t0 = t0.clamp(Vector2i.ZERO, Vector2i(cols - 1, rows - 1))
	t1 = t1.clamp(Vector2i.ZERO, Vector2i(cols - 1, rows - 1))
	return Rect2i(t0, t1 - t0 + Vector2i.ONE)

func _draw() -> void:
	var view := _visible_tiles()
	for y in range(view.position.y, view.end.y):
		for x in range(view.position.x, view.end.x):
			var i := y * cols + x
			var v := density[i]
			if v <= 0.02:
				continue
			var rect := Rect2(x * TILE, y * TILE, TILE, TILE)
			if remembered[i] == 1:
				draw_rect(rect, Color(SEEN, v * 0.8))
				if v > 0.5 and solid[i] == 0:
					draw_rect(rect.grow(-4), Color(SEEN_OUTLINE, 0.35 * v), false, 1.0)
			else:
				draw_rect(rect, Color(UNSEEN, v))
