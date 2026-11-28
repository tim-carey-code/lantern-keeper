class_name KeeperLight
extends Node2D
## M2 picks that touch lamps (PLAN_LANTERNS §8, "Where parts 3 and 4 slot in"): a small light the keeper's fire
## leaves behind that **counts as lit** for the light rule (PLAN_LANTERNS §2.1), like a lamp's light:
##   - Fireglobe *Beacon*: where the globe lands stays lit for kl_beacon_time, kl_beacon_radius out;
##   - the dash's *Ember rest*: an ember where the dash ends, kl_ember_rest_time, kl_ember_rest_radius out.
## It has no flame (no catch, flare or chain: the keeper's own fire can't combo with itself), doesn't keep small
## dark out and has no core. It clears fog (group "light_source"). LightSense reads it (lit_source).
## *Lightless* elites are never lit by it (Foe.lightless).

var radius := 100.0
var life := 6.0
var age := 0.0
var kind := "beacon"             # "beacon" or "ember_rest" (the look)

func _enter_tree() -> void:
	add_to_group("keeper_light")
	add_to_group("light_source")
	LightSense.bump()

func _exit_tree() -> void:
	LightSense.bump()

func _ready() -> void:
	z_index = 3
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

## Light radius now (fades out over its last 0.5 s, for the fog). The light rule uses `radius` while it lives.
func get_light_radius() -> float:
	return radius * clampf((life - age) / 0.5, 0.0, 1.0)

func is_lit() -> bool:
	return age < life

func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var k := clampf((life - age) / 0.5, 0.0, 1.0)
	var fm := maxf(Settings.flash_mult(), 0.6)
	var flick := 1.0 + 0.06 * sin(age * 23.0)
	# A warm pool of light (amber: the keeper's fire), its edge drawn so the lit area reads.
	draw_texture_rect(LightTex.radial(), Rect2(-Vector2(radius, radius) * flick, Vector2(radius, radius) * 2.0 * flick), false, Color(1.0, 0.7, 0.35, 0.22 * k * fm))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(1.0, 0.72, 0.38, 0.22 * k), 1.5)
	var core := 5.0 if kind == "beacon" else 3.5
	draw_circle(Vector2(0, -4), core * flick, Color(1.0, 0.85, 0.5, 0.9 * k))
	draw_circle(Vector2(0, -4), core * 0.5, Color(1.0, 0.97, 0.85, k))
