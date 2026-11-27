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
