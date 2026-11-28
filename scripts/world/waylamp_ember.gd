class_name WayLampEmber
extends Node2D
## The WayLamp's last ember (DECISIONS 2026-11-27, "the Ashbrood's ember"; code-drawn, no new art). A small amber
## glow low in the cold bowl while the Ashbrood broods over it: the lamp's light, not the creature's, so "amber is
## only the keeper's fire" still holds. When the Ashbrood dies the WayLamp takes it back: the ember rises into the
## lamp, swelling into its flame, with a ring as the lamp catches (WayLamp.EMBER_RISE_SEC). Then it goes.
## It lives on the fog layer (over the dark), at the WayLamp's position.

const AMBER := Color(1.0, 0.65, 0.26)      # #f5a742-ish: the keeper's fire
const CREAM := Color(1.0, 0.95, 0.76)

var waylamp: WayLamp
var _t := 0.0

func _ready() -> void:
	z_index = 12   # over the Ashbrood (9) and the fog, under the telegraph markers
	add_to_group("waylamp_ember")

func _process(delta: float) -> void:
	_t += delta
	if waylamp == null or not is_instance_valid(waylamp) or not waylamp.ember_showing():
		queue_free()
		return
	global_position = waylamp.global_position
	queue_redraw()

func _draw() -> void:
	if waylamp == null or not is_instance_valid(waylamp):
		return
	var k := waylamp.ember_rise() if waylamp.ember_rise_t > 0.0 else 0.0
	var e := 0.5 - 0.5 * cos(k * PI)   # eased rise
	var at := WayLamp.EMBER_BOWL.lerp(Vector2(0, WayLamp.LAMP_Y - 2.0), e)
	var flick := 0.5 + 0.5 * sin(_t * 7.3) * sin(_t * 3.1 + 1.0)
	if k <= 0.0:
		# Waiting in the cold bowl: small, low, breathing slowly. A wisp now and then.
		var breathe := 0.5 + 0.5 * sin(_t * 1.6)
		draw_circle(at, 11.0 + breathe * 3.0, Color(AMBER, 0.10 + 0.06 * breathe))
		draw_circle(at, 4.0 + breathe, Color(AMBER, 0.55 + 0.25 * flick))
		draw_circle(at, 2.0, Color(CREAM, 0.75 + 0.2 * flick))
		var w := fmod(_t * 0.6, 1.0)
		draw_rect(Rect2(at + Vector2(sin(_t * 2.0) * 2.0 - 1.0, -4.0 - w * 10.0), Vector2(2, 2)), Color(AMBER, 0.6 * (1.0 - w)))
		return
	# Rising: it swells into a flame as it climbs into the lamp, trailing sparks; a ring as the lamp catches.
	var size := lerpf(4.0, 9.0, e)
	draw_circle(at, size * 3.0, Color(AMBER, 0.12 + 0.18 * e))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-size * 0.7, size * 0.5), at + Vector2(0, -size * 1.6 - flick * 2.0), at + Vector2(size * 0.7, size * 0.5)]), Color(AMBER, 0.9))
	draw_circle(at, size * 0.6, Color(CREAM, 0.95))
	for i in 4:
		var s := fmod(_t * 1.8 + i * 0.25, 1.0)
		var p := WayLamp.EMBER_BOWL.lerp(at, s) + Vector2(sin(_t * 5.0 + i * 1.7) * 4.0, 0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), Color(AMBER, 0.8 * (1.0 - s)))
	if k > 0.75:
		var ring := (k - 0.75) / 0.25
		draw_arc(Vector2(0, WayLamp.LAMP_Y), 12.0 + ring * 34.0, 0.0, TAU, 40, Color(CREAM, 0.8 * (1.0 - ring)), 2.0)
