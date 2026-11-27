extends Node2D
## Keeps your lanterns findable (DESIGN 3.1 / 4: a cold lantern "keeps its frame").
## Drawn on the fog layer, above fog and darkness:
##   cold lantern      -> its frame outline plus a slow red-ish pulse
##   low on fuel (<25%) -> an amber pulse above it
##   off-screen cold/low -> an arrow at the screen edge pointing to it

const LOW := 0.25
const COLD_COL := Color(0.95, 0.45, 0.38)
const LOW_COL := Color(1.0, 0.75, 0.35)
const FRAME_COL := Color(0.7, 0.74, 0.82, 0.85)

func _ready() -> void:
	z_index = 6
	add_to_group("lantern_markers")

## Lanterns that need fuel: cold ones first, then low ones.
func needs_attention() -> Array:
	var cold := []
	var low := []
	for l in get_tree().get_nodes_in_group("lantern"):
		if not l.needs_fuel() or l.is_held():
			continue
		if not l.is_lit():
			cold.append(l)
		elif l.fuel_frac() < LOW:
			low.append(l)
	return cold + low

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
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.005)
	var view := _view()
	var inner := view.grow(-28.0)
	var tips: Array[Vector2] = []
	for l in needs_attention():
		var p: Vector2 = l.global_position
		var cold: bool = not l.is_lit()
		var col := COLD_COL if cold else LOW_COL
		if view.has_point(p):
			if cold:
				# The frame stays visible through fog and darkness.
				var file: String = {"reservoir": "reservoir_lamp_cold.png", "hooded": "hooded_lamp_cold.png"}.get(l.kind, "post_lamp_cold.png")
				Art.sprite(self, Art.placeholder(file), p + Vector2(0, 16), FRAME_COL)
				draw_arc(p + Vector2(0, -8), 16.0 + pulse * 6.0, 0.0, TAU, 28, Color(col, 0.75 - pulse * 0.5), 2.0)
			else:
				draw_arc(p + Vector2(0, -18), 9.0 + pulse * 4.0, 0.0, TAU, 20, Color(col, 0.8 - pulse * 0.5), 1.5)
		else:
			# Arrow on the screen edge, pointing toward the lantern.
			var c := view.get_center()
			var dir := (p - c).normalized()
			var t := INF
			if dir.x != 0.0:
				t = minf(t, ((inner.end.x if dir.x > 0 else inner.position.x) - c.x) / dir.x)
			if dir.y != 0.0:
				t = minf(t, ((inner.end.y if dir.y > 0 else inner.position.y) - c.y) / dir.y)
			var tip := c + dir * t
			# Spread arrows that would land on the same spot along the screen edge.
			var tries := 0
			while tries < 8 and tips.any(func(q): return q.distance_to(tip) < 16.0):
				tip += dir.orthogonal() * 16.0
				tries += 1
			tips.append(tip)
			var side := dir.orthogonal() * 7.0
			draw_colored_polygon(PackedVector2Array([tip + dir * 10.0, tip - dir * 6.0 + side, tip - dir * 6.0 - side]), Color(col, 0.55 + pulse * 0.4))
