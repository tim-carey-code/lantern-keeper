class_name BurningGround
extends Area2D
## Fireglobe's burning ground (GAME_PLAN §4.1): a long-lived Area2D (brief §7) that burns every foe
## standing in it, Tuning.kl_fireglobe_burn_dps for kl_fireglobe_burn_time seconds. Fire that isn't a hit
## glances off a shell (§4.5). Draws a scorched decal with flickering flames, and lights the fog a little.

var radius := 90.0
var dps := 2.0
var life := 3.0
var age := 0.0
var _flames: Node2D
var _seed := 0.0

func _ready() -> void:
	add_to_group("burning_ground")
	add_to_group("light_source")
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = Foe.HURT_LAYER
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	z_index = 3
	_seed = randf() * 100.0
	_flames = Node2D.new()
	_flames.name = "Flames"
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_flames.material = mat
	_flames.z_index = 9      # 12: with the other fire, over the foes standing in it
	_flames.draw.connect(_draw_flames)
	add_child(_flames)

func get_light_radius() -> float:
	return radius * 0.6 * clampf(2.0 * (1.0 - age / life), 0.0, 1.0)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	for a in get_overlapping_areas():
		var f := a.get_parent() as Foe
		if f and not f._dead and not f.is_queued_for_deletion():
			f.hurt(dps * delta, false, "ground")

## Foes it is burning now (for tests).
func burning() -> Array:
	var out := []
	for a in get_overlapping_areas():
		if a.get_parent() is Foe:
			out.append(a.get_parent())
	return out

func _process(_delta: float) -> void:
	queue_redraw()
	_flames.queue_redraw()

func _draw() -> void:
	var k := clampf(1.0 - age / life, 0.0, 1.0)
	var fade := clampf(k * 3.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.08, 0.04, 0.02, 0.35 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.75, 0.32, 0.1, 0.5 * fade), 2.0)
	draw_circle(Vector2.ZERO, radius * 0.6, Color(0.2, 0.07, 0.02, 0.25 * fade))

func _draw_flames() -> void:
	var k := clampf(1.0 - age / life, 0.0, 1.0)
	var fade := clampf(k * 3.0, 0.0, 1.0) * maxf(Settings.flash_mult(), 0.6)
	var t := age * 7.0 + _seed
	_flames.draw_texture_rect(LightTex.radial(), Rect2(Vector2(-radius, -radius), Vector2(radius, radius) * 2.0), false, Color(1.0, 0.55, 0.2, 0.18 * fade))
	# Flame tongues on rings, each flickering on its own.
	for ring in 2:
		var n := 9 if ring == 0 else 6
		var rr := radius * (0.75 if ring == 0 else 0.38)
		for i in n:
			var ang := TAU * i / n + ring * 0.4 + sin(t * 0.13 + i) * 0.08
			var base := Vector2.from_angle(ang) * rr
			var h := 7.0 + 6.0 * (0.5 + 0.5 * sin(t + i * 1.7 + ring))
			var w := 3.5
			_flames.draw_colored_polygon(PackedVector2Array([base + Vector2(-w, 0), base + Vector2(0, -h), base + Vector2(w, 0)]), Color(1.0, 0.55, 0.18, 0.75 * fade))
			_flames.draw_colored_polygon(PackedVector2Array([base + Vector2(-w * 0.5, 0), base + Vector2(0, -h * 0.55), base + Vector2(w * 0.5, 0)]), Color(1.0, 0.88, 0.55, 0.85 * fade))
