class_name Landmark
extends Node2D
## Something the light reveals that tells a piece of the valley's story.
## Interact to read it. Some landmarks unlock a lantern type (the pumphouse).

const REVEAL_BELOW := 0.35

var id := ""
var title := ""
var text := ""
var look := "stone"        # stone, ledger, frames, chalk, pumphouse
var unlock_kind := ""

func _ready() -> void:
	add_to_group("landmark")
	z_index = 15

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func is_revealed() -> bool:
	var fog := _fog()
	return fog != null and fog.density_at(global_position) < REVEAL_BELOW

func is_read() -> bool:
	return Progress.notes_read.has(id)

func display_name() -> String:
	return title

func activate() -> void:
	Progress.notes_read[id] = true
	var body := text
	if unlock_kind != "" and not Progress.is_unlocked(unlock_kind):
		Progress.unlock(unlock_kind)
		body += "\n\nNew lantern: %s. Pick it in the lantern list (Tab / Y)." % Lantern.display(unlock_kind)
	Progress.note_opened.emit(title, body)
	queue_redraw()

func _process(_delta: float) -> void:
	var v := is_revealed()
	if v != visible:
		visible = v
		queue_redraw()

func _draw() -> void:
	match look:
		"ledger":
			draw_line(Vector2(0, 8), Vector2(0, -4), Color(0.35, 0.28, 0.22), 3.0)
			draw_rect(Rect2(-9, -12, 18, 8), Color(0.55, 0.38, 0.22))
			draw_line(Vector2(0, -12), Vector2(0, -4), Color(0.85, 0.8, 0.7), 1.0)
		"frames":
			for i in 3:
				var x := -14 + i * 14
				draw_line(Vector2(x, 8), Vector2(x, -10), Color(0.35, 0.3, 0.26), 2.0)
				draw_rect(Rect2(x, -16, 8, 6), Color(0.45, 0.42, 0.38))   # all turned east
		"chalk":
			draw_rect(Rect2(-20, -18, 40, 22), Color(0.48, 0.48, 0.46))
			draw_circle(Vector2(-9, -9), 5.0, Color(0.95, 0.95, 0.9))
			draw_circle(Vector2(9, -9), 5.0, Color(0.12, 0.12, 0.12))
		"pumphouse":
			draw_rect(Rect2(-24, -30, 48, 36), Color(0.36, 0.34, 0.3))
			draw_colored_polygon(PackedVector2Array([Vector2(-28, -30), Vector2(0, -46), Vector2(28, -30)]), Color(0.28, 0.24, 0.2))
			draw_arc(Vector2(30, -8), 10.0, 0.0, TAU, 20, Color(0.5, 0.45, 0.38), 3.0)
		_:
			draw_colored_polygon(PackedVector2Array([Vector2(-8, 8), Vector2(-6, -14), Vector2(6, -16), Vector2(8, 8)]), Color(0.5, 0.5, 0.52))
			draw_line(Vector2(-3, -6), Vector2(3, -6), Color(0.25, 0.25, 0.28), 1.0)
	if not is_read():
		draw_circle(Vector2(0, -36 if look == "pumphouse" else -24) + Vector2(0, -16 if look == "pumphouse" else 0), 3.0, Color(1.0, 0.85, 0.4))
