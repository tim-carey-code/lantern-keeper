class_name FogGrid
extends Node2D
## Per-tile terrain, region, fog density (0 = clear, 1 = full fog), creep-back and memory.
## Light sources are nodes in group "light_source" with get_light_radius() -> float.
## Lives on its own CanvasLayer so the scene darkness does not tint it:
## never-seen fog is near black, seen-before fog is a dim blue haze with outlines.

const TILE := 32
const TICK := 0.1                  # simulation step (s)
const REMEMBER_BELOW := 0.3        # a tile this clear counts as "seen"
const PLACE_MAX_DENSITY := 0.6     # (no longer used for building: lanterns can go anywhere you can stand, owner 2026-11-27)

# Terrain
const T_GROUND := 0
const T_ROCK := 1
const T_MARSH := 2       # soft: walkable, can't build
const T_BOARDWALK := 3   # buildable path through the marsh

const REGION_NAMES := ["", "The Hollow", "The Reedmarsh", "The Windward Ridge"]
const R_HOLLOW := 1
const R_MARSH := 2
const R_RIDGE := 3

const UNSEEN := Color(0.02, 0.025, 0.04)
const SEEN := Color(0.09, 0.11, 0.15)
const SEEN_OUTLINE := Color(0.32, 0.38, 0.5)
const UNSEEN_RGB := [int(UNSEEN.r * 255), int(UNSEEN.g * 255), int(UNSEEN.b * 255)]
const SEEN_RGB := [int(SEEN.r * 255), int(SEEN.g * 255), int(SEEN.b * 255)]

@export var cols := 224
@export var rows := 200

var density := PackedFloat32Array()
var remembered := PackedByteArray()
var solid := PackedByteArray()     # 1 = rock: no walking, no building
var terrain := PackedByteArray()
var region := PackedByteArray()
var _light := PackedFloat32Array()
var _acc := 0.0
# Sparse update (performance): only tiles that can change are stepped. A tile at full fog with no
# light on it stays at full fog, so the step skips it. _active holds every tile below full fog;
# lit tiles join it each tick. Anything that writes density wholesale (a save) calls mark_all_dirty().
var _active := PackedInt32Array()
var _in_active := PackedByteArray()
var _lit := PackedInt32Array()          # tiles with _light > 0 (cleared at the start of the next step)
var _all_dirty := true
var _changed := PackedInt32Array()      # tiles stepped since the last texture update
var _tex_full := true

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
	_in_active.resize(n)
	_in_active.fill(0)

## Density or memory was replaced wholesale (a save loaded): rescan and redraw every tile once.
func mark_all_dirty() -> void:
	_all_dirty = true
	_tex_full = true

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
	for i in _lit:
		_light[i] = 0.0
	_lit.clear()
	for src in get_tree().get_nodes_in_group("light_source"):
		var r: float = src.get_light_radius()
		if r <= 0.0:
			continue
		var c: Vector2 = src.global_position
		# A WayLamp holds back the fog of its own region only (it must not light the next one for free).
		var only: int = (src as WayLamp).region_id if src is WayLamp else 0
		var t0 := tile_of(c - Vector2(r, r))
		var t1 := tile_of(c + Vector2(r, r))
		for y in range(maxi(t0.y, 0), mini(t1.y, rows - 1) + 1):
			for x in range(maxi(t0.x, 0), mini(t1.x, cols - 1) + 1):
				if only > 0 and region[y * cols + x] != only:
					continue
				var d := tile_center(Vector2i(x, y)).distance_to(c)
				if d < r:
					# Strong plateau in the middle, soft edge near the rim.
					var s := clampf((1.0 - d / r) * 1.6, 0.0, 1.0)
					var i := y * cols + x
					if s > _light[i]:
						if _light[i] == 0.0:
							_lit.append(i)
						_light[i] = s

	_update_mirrors()
	for m in get_tree().get_nodes_in_group("mirror") + get_tree().get_nodes_in_group("beam_source"):
		var seg: Array = m.beam_segment()
		if seg.is_empty():
			continue
		var length: float = seg[0].distance_to(seg[1])
		var dir: Vector2 = (seg[1] - seg[0]).normalized()
		var half := Tuning.mirror_beam_width * 0.5
		var d := 0.0
		while d <= length:
			var p: Vector2 = seg[0] + dir * d
			var t0 := tile_of(p - Vector2(half, half))
			var t1 := tile_of(p + Vector2(half, half))
			for y in range(maxi(t0.y, 0), mini(t1.y, rows - 1) + 1):
				for x in range(maxi(t0.x, 0), mini(t1.x, cols - 1) + 1):
					var c := tile_center(Vector2i(x, y))
					var off := Geometry2D.get_closest_point_to_segment(c, seg[0], seg[1]).distance_to(c)
					if off <= half:
						var i := y * cols + x
						if _light[i] == 0.0:
							_lit.append(i)
						_light[i] = 1.0
			d += TILE * 0.5

	var wind := get_tree().get_first_node_in_group("wind") as Wind
	var gust := Tuning.wind_creep_mult if wind != null and wind.is_gusting() else 1.0
	var creep_by_region := [Tuning.fog_creep_per_sec, Tuning.fog_creep_per_sec, Tuning.fog_creep_per_sec * Tuning.marsh_creep_mult, Tuning.fog_creep_per_sec]
	var clear := Tuning.fog_clear_per_sec
	if _all_dirty:
		_all_dirty = false
		_active.clear()
		_in_active.fill(0)
		for i in density.size():
			if density[i] < 1.0:
				_active.append(i)
				_in_active[i] = 1
	for i in _lit:
		if _in_active[i] == 0:
			_in_active[i] = 1
			_active.append(i)
	# New values are worked out from the old ones first (neighbours read the old fog), then written.
	var next := PackedFloat32Array()
	next.resize(_active.size())
	var k := 0
	for i in _active:
		var x := i % cols
		var y := i / cols
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
		next[k] = clampf(v, 0.0, 1.0)
		k += 1
	var still := PackedInt32Array()
	k = 0
	for i in _active:
		var v := next[k]
		k += 1
		density[i] = v
		_changed.append(i)
		if v < 1.0:
			still.append(i)
		else:
			_in_active[i] = 0
		if v < REMEMBER_BELOW and remembered[i] == 0:
			remembered[i] = 1
			if region[i] > 0 and region[i] < REGION_NAMES.size():
				Progress.reveal_region(region[i], REGION_NAMES[region[i]])
	_active = still

## A mirror catches light when it stands well inside a burning lantern's light, or in
## another catching mirror's beam. Repeats so chains of mirrors pass light along.
func _update_mirrors() -> void:
	var mirrors := get_tree().get_nodes_in_group("mirror")
	if mirrors.is_empty():
		return
	for m in mirrors:
		m.catching = false
	var burning := []
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.kind != "mirror" and l.is_lit():
			burning.append(l)
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.is_lit():
			burning.append(w)
	for pass_i in mirrors.size() + 1:
		var changed := false
		for m in mirrors:
			if m.catching or m.is_smothered():
				continue
			var lit := false
			for l in burning:
				if l.global_position.distance_to(m.global_position) <= l.get_light_radius() * Tuning.mirror_catch:
					lit = true
					break
			if not lit:
				for other in mirrors:
					if other != m and other.catching and other.beam_level_at(m.global_position) > 0.0:
						lit = true
						break
			if lit:
				m.catching = true
				changed = true
		if not changed:
			break

# --- Drawing ------------------------------------------------------------------
# One pixel per tile in a small image, stretched over the world with linear
# filtering, so fog edges blend smoothly instead of showing 32 px squares.

var _img: Image
var _tex: ImageTexture
var _pixels := PackedByteArray()

func _ensure_texture() -> void:
	if _tex != null:
		return
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_pixels.resize(cols * rows * 4)
	_img = Image.create_from_data(cols, rows, false, Image.FORMAT_RGBA8, _pixels)
	_tex = ImageTexture.create_from_image(_img)

func _rebuild_texture() -> void:
	_ensure_texture()
	if _tex_full:
		_tex_full = false
		_changed.clear()
		for i in density.size():
			_paint(i)
	else:
		for i in _changed:
			_paint(i)
		_changed.clear()
	_img.set_data(cols, rows, false, Image.FORMAT_RGBA8, _pixels)
	_tex.update(_img)

func _paint(i: int) -> void:
	var o := i * 4
	if remembered[i] == 1:
		_pixels[o] = SEEN_RGB[0]
		_pixels[o + 1] = SEEN_RGB[1]
		_pixels[o + 2] = SEEN_RGB[2]
		_pixels[o + 3] = int(clampf(density[i] * 0.8, 0.0, 1.0) * 255.0)
	else:
		_pixels[o] = UNSEEN_RGB[0]
		_pixels[o + 1] = UNSEEN_RGB[1]
		_pixels[o + 2] = UNSEEN_RGB[2]
		_pixels[o + 3] = int(clampf(density[i], 0.0, 1.0) * 255.0)

func _draw() -> void:
	_rebuild_texture()
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, world_size()), false)
