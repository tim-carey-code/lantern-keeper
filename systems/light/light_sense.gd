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

## The first lit lantern whose bright core covers a point, or null (call refresh() first).
static func core_lantern_at(p: Vector2) -> Node:
	for i in nodes.size():
		if core[i] > 0.0 and pos[i].distance_to(p) < core[i]:
			return nodes[i]
	return null
