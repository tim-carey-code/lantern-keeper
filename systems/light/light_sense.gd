class_name LightSense
extends RefCounted
## Performance: what the dark senses of lantern light, worked out once per frame and shared by
## every foe (each foe used to ask every lantern for its radius several times a frame).
## Lanterns process before the foes (they come first in the scene tree), so the snapshot a foe
## sees is the same state it saw before. It is rebuilt every frame, and at once when a lantern
## is added, removed, picked up, lit, snuffed or relit (bump()). WayLamps are few: they are read live.
## What each lantern does comes from its own Effects section (Lantern: core_frac, repels_small_dark); this file
## only caches it. M1b: lamps never dim or die, so there is no "dying" any more.

static var _frame := -1
static var _epoch := 0
static var _built_epoch := -1
## Every non-mirror lantern: node, position, light radius (0 when not lit), whether it is lit, whether it keeps
## small dark out (lit and repels_small_dark), and its bright core's radius (0 = no core).
static var nodes: Array = []
static var pos := PackedVector2Array()
static var radius := PackedFloat32Array()
static var lit := PackedByteArray()
static var healthy := PackedByteArray()
static var core := PackedFloat32Array()
## Every WayLamp and every mirror (their lit state is read live: it can change mid-frame).
static var waylamps: Array = []
static var mirrors: Array = []
## Performance (M1c review): lit lanterns bucketed in a coarse grid (cells as big as the widest light), so a foe's
## light state only looks at the lamps in its own and the neighbouring cells.
static var _cell := 256.0
static var _grid := {}

## Something changed that the snapshot must see straight away.
static func bump() -> void:
	_epoch += 1

## Rebuilds the snapshot if this frame doesn't have one yet.
static func refresh(tree: SceneTree) -> void:
	var f := Engine.get_process_frames()
	if f == _frame and _epoch == _built_epoch:
		return
	_frame = f
	_built_epoch = _epoch
	nodes.clear()
	pos.clear()
	radius.clear()
	lit.clear()
	healthy.clear()
	core.clear()
	_grid.clear()
	waylamps = tree.get_nodes_in_group("waylamp")
	mirrors = tree.get_nodes_in_group("mirror")
	for l in tree.get_nodes_in_group("lantern"):
		if l.kind == "mirror":
			continue
		var is_lit: bool = l.is_lit()
		var r: float = l.get_light_radius()
		nodes.append(l)
		pos.append(l.global_position)
		radius.append(r)
		lit.append(1 if is_lit else 0)
		healthy.append(1 if is_lit and l.repels_small_dark() else 0)
		core.append(r * l.core_frac() if is_lit else 0.0)
	var widest := 64.0
	for r in radius:
		widest = maxf(widest, r)
	_cell = widest
	for i in nodes.size():
		if radius[i] > 0.0:
			var c := Vector2i(floori(pos[i].x / _cell), floori(pos[i].y / _cell))
			if not _grid.has(c):
				_grid[c] = PackedInt32Array()
			_grid[c].append(i)

## How deep a point sits in healthy light: lit lanterns that keep small dark out, and lit WayLamps (0 outside).
## `ignore` leaves one light out. Call refresh() first.
static func healthy_at(p: Vector2, ignore: Object = null) -> float:
	var best := 0.0
	for i in nodes.size():
		if healthy[i] == 0 or nodes[i] == ignore:
			continue
		var r := radius[i]
		if r > 0.0:
			best = maxf(best, 1.0 - pos[i].distance_to(p) / r)
	for w in waylamps:
		if w == ignore or not is_instance_valid(w) or not w.is_lit():
			continue
		var r: float = w.get_light_radius()
		if r > 0.0:
			best = maxf(best, 1.0 - w.global_position.distance_to(p) / r)
	return best

## M1c light states (PLAN_LANTERNS §2.1): where the lamp light covering a point comes from, or Vector2.INF when
## no lamp light covers it. Lamp light is a lit lantern (planted or old, flaring or not), a lit WayLamp or a mirror
## beam. The keeper's hand lamp is not lamp light (it makes "dim"), nor are bolt lights, pops and burning ground.
## Call refresh() first.
static func lit_source(p: Vector2) -> Vector2:
	var best := Vector2.INF
	var best_k := 0.0
	var c := Vector2i(floori(p.x / _cell), floori(p.y / _cell))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell = _grid.get(c + Vector2i(dx, dy))
			if cell == null:
				continue
			for i in cell:
				var r := radius[i]
				var d2 := pos[i].distance_squared_to(p)
				if d2 < r * r:
					var k := 1.0 - sqrt(d2) / r
					if k > best_k:
						best_k = k
						best = pos[i] + Vector2(0, Lantern.LAMP_Y * 0.5)
	if best != Vector2.INF:
		return best
	for w in waylamps:
		if is_instance_valid(w) and w.is_lit():
			var r: float = w.get_light_radius()
			if w.global_position.distance_to(p) < r:
				return w.global_position + Vector2(0, WayLamp.LAMP_Y)
	for m in mirrors:
		if is_instance_valid(m) and m.is_inside_tree() and m.beam_level_at(p) > 0.0:
			var seg: Array = m.beam_segment()
			return Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1]) if seg.size() == 2 else m.global_position
	return Vector2.INF

## The first lit lantern whose bright core covers a point, or null (call refresh() first).
static func core_lantern_at(p: Vector2) -> Node:
	for i in nodes.size():
		if core[i] > 0.0 and pos[i].distance_to(p) < core[i]:
			return nodes[i]
	return null
