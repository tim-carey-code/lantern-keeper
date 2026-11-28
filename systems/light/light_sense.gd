class_name LightSense
extends RefCounted
## Performance: what the dark senses of lantern light, worked out once per frame and shared by
## every foe (each foe used to ask every lantern for its radius several times a frame).
## Lanterns process before the foes (they come first in the scene tree), so the snapshot a foe
## sees is the same state it saw before. It is rebuilt every frame, and at once when a lantern
## is added, removed, picked up or refuelled (bump()). WayLamps are few: they are read live.

static var _frame := -1
static var _epoch := 0
static var _built_epoch := -1
## Every non-mirror lantern: node, position, light radius (0 when cold), and whether it is healthy
## (lit and not dying).
static var nodes: Array = []
static var pos := PackedVector2Array()
static var radius := PackedFloat32Array()
static var lit := PackedByteArray()
static var healthy := PackedByteArray()
static var dying := PackedByteArray()
## Every WayLamp and every mirror (their lit state is read live: it can change mid-frame).
static var waylamps: Array = []
static var mirrors: Array = []
## Worked out at most once a frame, the first time a Wickling looks for prey (readability step, performance):
## prey[i] = 1 when lantern i is dying and no other healthy light covers it.
static var prey := PackedByteArray()
static var _prey_frame := -1
static var _prey_epoch := -1

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
	dying.clear()
	waylamps = tree.get_nodes_in_group("waylamp")
	mirrors = tree.get_nodes_in_group("mirror")
	for l in tree.get_nodes_in_group("lantern"):
		if l.kind == "mirror":
			continue
		var is_lit: bool = l.is_lit()
		var is_dying: bool = l.is_dying()
		nodes.append(l)
		pos.append(l.global_position)
		radius.append(l.get_light_radius())
		lit.append(1 if is_lit else 0)
		dying.append(1 if is_dying else 0)
		healthy.append(1 if is_lit and not is_dying else 0)

## How deep a point sits in healthy light: burning lanterns that aren't dying, and lit WayLamps (0 outside).
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

## Dying lanterns no other healthy light covers (what a Wickling may drain), once a frame for every Wickling.
static func prey_flags(tree: SceneTree) -> PackedByteArray:
	refresh(tree)
	var f := Engine.get_process_frames()
	if f == _prey_frame and _prey_epoch == _built_epoch and prey.size() == nodes.size():
		return prey
	_prey_frame = f
	_prey_epoch = _built_epoch
	prey.resize(nodes.size())
	for i in nodes.size():
		prey[i] = 1 if dying[i] == 1 and healthy_at(pos[i], nodes[i]) <= 0.0 else 0
	return prey
