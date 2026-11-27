extends Node2D
## Soft amber pointer toward the current goal: an arrow at the screen edge when the
## target is off-screen, a gentle bobbing chevron above it when it is on-screen.
## On in the Hollow, off once you reach the Reedmarsh (unless turned on in the pause menu).

const COL := Color(1.0, 0.82, 0.45)

func _ready() -> void:
	z_index = 9
	add_to_group("goal_pointer")

func _main() -> Node:
	return get_tree().get_first_node_in_group("main")

## World position of the current goal's target, or null if it has none / pointer is off.
func target_pos() -> Variant:
	var main := _main()
	if main == null or not Story.pointer_on() or Story.current == "":
		return null
	var key := Story.goal_target(Story.current)
	match key:
		"":
			return null
		"woodpile":
			for r in get_tree().get_nodes_in_group("resource"):
				if r.always_regrow:
					return r.global_position
			return null
		"start_lantern":
			return main.start_lantern_pos
		"passage":
			return main.fog.tile_center(Vector2i(44, 68))
		"marsh_entry":
			return main.fog.tile_center(Vector2i(54, 68))
	if key.begins_with("waylamp_"):
		for w in get_tree().get_nodes_in_group("waylamp"):
			if "waylamp_" + w.id == key:
				return w.global_position
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == key:
			return m.global_position
	return null

func _view() -> Rect2:
	var cam := get_viewport().get_camera_2d()
	var size := get_viewport().get_visible_rect().size
	if cam == null:
		return Rect2(Vector2.ZERO, size)
	var half := size / cam.zoom / 2.0
	return Rect2(cam.get_screen_center_position() - half, half * 2.0)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t = target_pos()
	if t == null:
		return
	var p: Vector2 = t
	var view := _view()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
	if view.grow(-40.0).has_point(p):
		# On screen: a chevron bobbing above the target.
		var top := p + Vector2(0, -58 - pulse * 6.0)
		draw_colored_polygon(PackedVector2Array([top + Vector2(-8, -6), top + Vector2(8, -6), top + Vector2(0, 4)]), Color(COL, 0.85))
		return
	# Off screen: an arrow on the edge pointing toward it, with a small diamond behind it.
	var c := view.get_center()
	var dir := (p - c).normalized()
	var inner := view.grow(-46.0)
	var k := INF
	if dir.x != 0.0:
		k = minf(k, ((inner.end.x if dir.x > 0 else inner.position.x) - c.x) / dir.x)
	if dir.y != 0.0:
		k = minf(k, ((inner.end.y if dir.y > 0 else inner.position.y) - c.y) / dir.y)
	var tip := c + dir * k
	var side := dir.orthogonal() * 10.0
	draw_colored_polygon(PackedVector2Array([tip + dir * 16.0, tip - dir * 6.0 + side, tip - dir * 6.0 - side]), Color(COL, 0.7 + pulse * 0.3))
	var back := tip - dir * 18.0
	draw_colored_polygon(PackedVector2Array([back + Vector2(0, -5), back + Vector2(5, 0), back + Vector2(0, 5), back + Vector2(-5, 0)]), Color(COL, 0.6))
