class_name PostLamp
extends Node2D
## The basic lantern. Burns fuel; radius shrinks with fuel; goes cold when empty
## (keeps its frame, relights with fuel only).

var fuel := 0.0
var light: PointLight2D

func _ready() -> void:
	add_to_group("light_source")
	add_to_group("lantern")
	z_index = 20
	fuel = Tuning.lantern_max_fuel
	light = PointLight2D.new()
	light.texture = LightTex.radial()
	light.color = Color(1.0, 0.78, 0.45)
	light.energy = 1.2
	add_child(light)

func is_lit() -> bool:
	return fuel > 0.0

func fuel_frac() -> float:
	return clampf(fuel / Tuning.lantern_max_fuel, 0.0, 1.0)

func get_light_radius() -> float:
	if fuel <= 0.0:
		return 0.0
	return Tuning.lantern_max_radius * lerpf(Tuning.lantern_min_radius_frac, 1.0, fuel_frac())

func refuel(amount: float) -> float:
	var before := fuel
	fuel = minf(fuel + amount, Tuning.lantern_max_fuel)
	return fuel - before

func _process(delta: float) -> void:
	if fuel > 0.0:
		fuel = maxf(0.0, fuel - Tuning.lantern_burn_per_sec * delta)
	var r := get_light_radius()
	light.enabled = r > 0.0
	if r > 0.0:
		light.texture_scale = LightTex.scale_for(r)
		light.energy = 1.2 + sin(Time.get_ticks_msec() * 0.011 + get_instance_id() % 97) * 0.06
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(0, 8), Vector2(0, -12), Color(0.4, 0.34, 0.28), 3.0)
	draw_rect(Rect2(-6, -24, 12, 12), Color(0.5, 0.44, 0.36))
	if is_lit():
		draw_circle(Vector2(0, -18), 3.5, Color(1.0, 0.88, 0.55))
	draw_rect(Rect2(-12, 12, 24, 4), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-12, 12, 24 * fuel_frac(), 4), Color(1.0, 0.7, 0.3))
