extends Node2D
## The cold-frame lure (M1b, GAME_PLAN §6): an old lamp not yet lit by touch (the hut's, the north path's) keeps its
## frame through fog and darkness, with a slow red-amber pulse. Nothing else goes cold any more, so the old cold
## and low lantern markers, the edge arrows and the HUD chips are gone.
## Drawn on the fog layer, above fog and darkness.

const COLD_COL := Color(0.95, 0.45, 0.38)
const FRAME_COL := Color(0.7, 0.74, 0.82, 0.85)

func _ready() -> void:
	z_index = 6
	add_to_group("lantern_markers")

## Old lamps still to light, in the order the keeper meets them: the north path's lamp waits until the ledger
## by the hut is read (one cold lamp to look at by the hut).
func unlit_old_lamps() -> Array:
	var out := []
	for l in get_tree().get_nodes_in_group("lantern"):
		if not l.can_light_by_touch():
			continue
		if not Story.done.has("read_ledger") and _is_waypost(l):
			continue
		out.append(l)
	return out

func _is_waypost(l: Node) -> bool:
	var main := get_tree().get_first_node_in_group("main")
	return main != null and "waypost_lantern_pos" in main and l.global_position.distance_to(main.waypost_lantern_pos) < 8.0

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
	var view := _view().grow(64.0)
	for l in unlit_old_lamps():
		var p: Vector2 = l.global_position
		if not view.has_point(p):
			continue
		Art.sprite(self, Art.placeholder("post_lamp_cold.png"), p + Vector2(0, 16), FRAME_COL)
		draw_arc(p + Vector2(0, -8), 16.0 + pulse * 6.0, 0.0, TAU, 28, Color(COLD_COL, 0.75 - pulse * 0.5), 2.0)
