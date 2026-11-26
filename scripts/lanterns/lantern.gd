class_name Lantern
extends Node2D
## A lantern of any type. Burns fuel; radius shrinks with fuel; goes cold when
## empty (keeps its frame, relights with fuel only). Wind gusts hit exposed ones.
##   post:      the basic lamp.
##   reservoir: big tank, wide dim light, slowly tops up other lanterns in its light.

const NAMES := {"post": "Post Lamp", "reservoir": "Reservoir Lamp", "hooded": "Hooded Lamp", "mirror": "Mirror Post"}

var kind := "post"
var fuel := -1.0          # -1 = start with a full tank
var light: PointLight2D

static func cost(k: String) -> int:
	return Tuning.reservoir_cost_scrap if k == "reservoir" else Tuning.post_lamp_cost_scrap

static func display(k: String) -> String:
	return NAMES.get(k, "???")

static func blurb(k: String) -> String:
	match k:
		"post":
			return "Burns fuel. Light shrinks as it runs low."
		"reservoir":
			return "Big tank, wide dim light. Slowly refuels other lanterns in its light."
	return ""

func _ready() -> void:
	add_to_group("light_source")
	add_to_group("lantern")
	z_index = 20
	if fuel < 0.0:
		fuel = max_fuel()
	light = PointLight2D.new()
	light.texture = LightTex.radial()
	light.color = Color(0.9, 0.86, 0.62) if kind == "reservoir" else Color(1.0, 0.78, 0.45)
	add_child(light)

# --- Stats -------------------------------------------------------------------

func max_fuel() -> float:
	return Tuning.reservoir_max_fuel if kind == "reservoir" else Tuning.lantern_max_fuel

func base_radius() -> float:
	return Tuning.reservoir_radius if kind == "reservoir" else Tuning.lantern_max_radius

func min_frac() -> float:
	return Tuning.reservoir_min_radius_frac if kind == "reservoir" else Tuning.lantern_min_radius_frac

func base_burn() -> float:
	return Tuning.reservoir_burn_per_sec if kind == "reservoir" else Tuning.lantern_burn_per_sec

func is_lit() -> bool:
	return fuel > 0.0

func fuel_frac() -> float:
	return clampf(fuel / max_fuel(), 0.0, 1.0)

# --- Wind --------------------------------------------------------------------

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func _wind() -> Wind:
	return get_tree().get_first_node_in_group("wind") as Wind

## Sheltered if rock (or the map edge) is 1-2 tiles upwind.
func is_sheltered_from(dir: Vector2i) -> bool:
	var fog := _fog()
	if fog == null:
		return false
	var t := fog.tile_of(global_position)
	for k in range(1, 3):
		var u := t - dir * k
		if not fog.in_bounds(u) or fog.solid[u.y * fog.cols + u.x] == 1:
			return true
	return false

func in_gust() -> bool:
	var w := _wind()
	return w != null and w.is_gusting() and not is_sheltered_from(w.direction)

func burn_rate() -> float:
	return base_burn() * (Tuning.wind_burn_mult if in_gust() else 1.0)

func get_light_radius() -> float:
	if fuel <= 0.0:
		return 0.0
	var r := base_radius() * lerpf(min_frac(), 1.0, fuel_frac())
	if in_gust():
		r *= Tuning.wind_radius_mult
	return r

# --- Fuel --------------------------------------------------------------------

func refuel(amount: float) -> float:
	var before := fuel
	fuel = minf(fuel + amount, max_fuel())
	return fuel - before

func _process(delta: float) -> void:
	if fuel > 0.0:
		fuel = maxf(0.0, fuel - burn_rate() * delta)
	if kind == "reservoir" and fuel > 0.0:
		_feed(delta)
	var r := get_light_radius()
	light.enabled = r > 0.0
	if r > 0.0:
		light.texture_scale = LightTex.scale_for(r)
		var flicker := 0.15 if in_gust() else 0.06
		var base := 0.8 if kind == "reservoir" else 1.2
		light.energy = base + sin(Time.get_ticks_msec() * 0.011 + get_instance_id() % 97) * flicker
	queue_redraw()

## Reservoir: share fuel with other (non-reservoir) lanterns inside its light, lit or cold.
func _feed(delta: float) -> void:
	var r := get_light_radius()
	for l in get_tree().get_nodes_in_group("lantern"):
		if l == self or l.kind == "reservoir":
			continue
		if l.global_position.distance_to(global_position) > r:
			continue
		var give := minf(minf(Tuning.reservoir_feed_per_sec * delta, l.max_fuel() - l.fuel), fuel)
		if give <= 0.0:
			continue
		l.fuel += give
		fuel -= give

func _draw() -> void:
	var wood := Color(0.4, 0.34, 0.28)
	var gust := in_gust()
	var lean := Vector2.ZERO
	if gust:
		var w := _wind()
		lean = Vector2(w.direction) * (3.0 + sin(Time.get_ticks_msec() * 0.03) * 1.5)
	if kind == "reservoir":
		draw_line(Vector2(-6, 8), Vector2(-6, -10), wood, 3.0)
		draw_line(Vector2(6, 8), Vector2(6, -10), wood, 3.0)
		draw_rect(Rect2(-10, -26, 20, 16), Color(0.42, 0.46, 0.48))
		draw_rect(Rect2(-10, -26 + 16 * (1.0 - fuel_frac()), 20, 16 * fuel_frac()), Color(0.55, 0.45, 0.25, 0.8))
		if is_lit():
			draw_circle(Vector2(0, -30) + lean, 3.5, Color(0.95, 0.9, 0.65))
	else:
		draw_line(Vector2(0, 8), Vector2(0, -12), wood, 3.0)
		draw_rect(Rect2(-6, -24, 12, 12), Color(0.5, 0.44, 0.36))
		if is_lit():
			draw_circle(Vector2(0, -18) + lean, 3.5, Color(1.0, 0.88, 0.55))
	draw_rect(Rect2(-12, 12, 24, 4), Color(0, 0, 0, 0.7))
	var bar := Color(1.0, 0.7, 0.3)
	if gust and int(Time.get_ticks_msec() / 250) % 2 == 0:
		bar = Color(1.0, 0.35, 0.25)   # flashing: burning fast in the wind
	draw_rect(Rect2(-12, 12, 24 * fuel_frac(), 4), bar)
