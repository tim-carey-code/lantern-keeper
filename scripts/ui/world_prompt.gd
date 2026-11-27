extends Node2D
## Prompts drawn over the thing in front of the keeper (instead of HUD text):
##   "[A] Read", "[A] Refuel  62%", "[A] Turn", "[A] Hold to gather  3 left", plus "[B] Pick up".
## Under the placement outline: what the selected lantern costs, or why you can't build there.
## Lives on the fog layer so it stays readable in the dark.

const FONT := preload("res://assets/fonts/kenney_pixel.ttf")
const SIZE := 16

func _ready() -> void:
	z_index = 10
	add_to_group("world_prompt")

func _player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	queue_redraw()

## The lines shown over the current target: [[button, text], ...]. Public for tests.
func lines_for(t: Node) -> Array:
	var player = _player()
	if t is Landmark and t.upgrade != "":
		return [[InputHint.key("interact"), "Look again" if t.is_taken() else "Take"]]
	if t is Landmark:
		return [[InputHint.key("interact"), "Read again" if t.is_read() else "Read"]]
	if t is Lantern and t.kind == "mirror":
		var state := "smothered!" if t.is_smothered() else ("" if t.is_lit() else "dark: needs a lantern's light")
		var out := [[InputHint.key("interact"), "Turn right"], [InputHint.key("place_lantern"), "Turn left"], [InputHint.key("cancel"), "Pick up"]]
		if state != "":
			out.push_front(["", state])
		return out
	if t is Lantern:
		var state := "%d%%" % roundi(t.fuel_frac() * 100.0) if t.is_lit() else "cold"
		var extra := ""
		if t.wind_proof():
			extra = "  wind-proof"
		elif t.in_ridge_wind() or t.in_gust():
			extra = "  in the wind"
		return [[InputHint.key("interact"), "Refuel  " + state + extra], [InputHint.key("cancel"), "Pick up"]]
	if t is ResourceNode:
		var verb := "Gathering..." if player.is_gathering() else "Hold to gather"
		return [[InputHint.key("interact"), "%s  %d left" % [verb, t.amount]]]
	return []

func _draw() -> void:
	var player = _player()
	if player == null or Tuning.ui_open:
		return
	var t = player.nearest_target()
	if t:
		var top: float = -64.0 if t is Lantern else (-74.0 if (t is Landmark and t.look in ["pumphouse", "workshop", "station"]) else -48.0)
		_draw_lines(t.global_position + Vector2(0, top), lines_for(t))
		return
	# Nothing to use: say what building here would do.
	var p: Vector2 = player.place_pos()
	var reason: String = player.place_block_reason(p)
	if reason == "too close to a lantern":
		return
	var k := Progress.selected
	if reason == "":
		_draw_lines(p + Vector2(0, 34), [[InputHint.key("place_lantern"), "%s  %s" % [Lantern.display(k), Lantern.cost_text(k)]]], 0.75)
	else:
		_draw_lines(p + Vector2(0, 34), [["", "Can't build: " + reason]], 0.6, UiStyle.WARN)

## A small dark box per line, with the button in a gold key cap, centred on `at` (bottom edge).
func _draw_lines(at: Vector2, lines: Array, alpha: float = 1.0, color: Color = UiStyle.CREAM) -> void:
	var y := at.y - lines.size() * 22.0
	for ln in lines:
		var key: String = ln[0]
		var text: String = ln[1]
		var key_w := 0.0
		if key != "":
			key_w = FONT.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x + 10.0
		var text_w := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x
		var w := key_w + text_w + 14.0 + (6.0 if key != "" else 0.0)
		var x := at.x - w / 2.0
		draw_rect(Rect2(x, y, w, 20), Color(0.043, 0.055, 0.1, 0.88 * alpha))
		draw_rect(Rect2(x, y, w, 20), Color(UiStyle.GOLD, 0.6 * alpha), false, 1.0)
		var cx := x + 7.0
		if key != "":
			draw_rect(Rect2(cx, y + 3, key_w, 14), Color(UiStyle.GOLD, alpha))
			draw_string(FONT, Vector2(cx + 5.0, y + 15), key, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(0.043, 0.055, 0.1, alpha))
			cx += key_w + 6.0
		draw_string(FONT, Vector2(cx, y + 15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, Color(color, alpha))
		y += 22.0
