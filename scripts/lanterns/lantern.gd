class_name Lantern
extends Node2D
## A lantern of any type. Burns fuel; radius shrinks with fuel; goes cold when
## empty (keeps its frame, relights with fuel only). Wind hits exposed ones.
##   post:      the basic lamp.
##   reservoir: big tank, wide dim light, slowly tops up other lanterns in its light.
##   hooded:    smaller light, but wind never touches it.
##   mirror:    burns no fuel. When it sits in another lantern's light (or in another
##              mirror's beam) it throws a long, narrow beam in one of 8 directions.
##              Interact to turn it. Beams are blocked by rock.

const NAMES := {"post": "Post Lamp", "reservoir": "Reservoir Lamp", "hooded": "Hooded Lamp", "mirror": "Mirror Post"}
const DIRS := [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]
const PREVAILING := Vector2i.RIGHT   # the Ridge wind blows from the west
## Lamp box height above the tile centre, so the light glows from the lamp, not the base.
const LAMP_Y := -34.0

var kind := "post"
var fuel := -1.0          # -1 = start with a full tank
var mirror_dir := 0       # mirror only: index into DIRS
var catching := false     # mirror only: set each fog tick by FogGrid
var light: PointLight2D
var beam_light: PointLight2D

static func cost(k: String) -> int:
	match k:
		"reservoir":
			return Tuning.reservoir_cost_scrap
		"hooded":
			return Tuning.hooded_cost_scrap
		"mirror":
			return Tuning.mirror_cost_scrap
	return Tuning.post_lamp_cost_scrap

static func glass_cost(k: String) -> int:
	match k:
		"hooded":
			return Tuning.hooded_cost_glass
		"mirror":
			return Tuning.mirror_cost_glass
	return 0

static func cost_text(k: String) -> String:
	var g := glass_cost(k)
	return "%d scrap" % cost(k) + (" + %d glass" % g if g > 0 else "")

static func display(k: String) -> String:
	return NAMES.get(k, "???")

static func blurb(k: String) -> String:
	match k:
		"post":
			return "Burns fuel. Light shrinks as it runs low."
		"reservoir":
			return "Big tank, wide dim light. Slowly refuels other lanterns in its light."
		"hooded":
			return "Smaller light, but wind never touches it."
		"mirror":
			return "No fuel. Place it in another lantern's light and it throws a long beam. [E / A] turns it."
	return ""

func _ready() -> void:
	add_to_group("light_source")
	add_to_group("lantern")
	if kind == "mirror":
		add_to_group("mirror")
	z_index = 20
	if fuel < 0.0:
		fuel = max_fuel()
	light = PointLight2D.new()
	light.texture = LightTex.radial()
	light.color = Color(0.9, 0.86, 0.62) if kind == "reservoir" else Color(1.0, 0.78, 0.45)
	light.position = Vector2(0, -44 if kind == "reservoir" else LAMP_Y)
	add_child(light)
	if kind == "mirror":
		beam_light = PointLight2D.new()
		beam_light.texture = LightTex.beam_strip()
		beam_light.offset = Vector2(128, 0)
		beam_light.color = Color(1.0, 0.9, 0.65)
		beam_light.energy = 0.9
		beam_light.position = Vector2(0, LAMP_Y)
		beam_light.enabled = false
		add_child(beam_light)

# --- Stats -------------------------------------------------------------------

func max_fuel() -> float:
	match kind:
		"reservoir":
			return Tuning.reservoir_max_fuel
		"mirror":
			return 1.0
	return Tuning.lantern_max_fuel

func base_radius() -> float:
	match kind:
		"reservoir":
			return Tuning.reservoir_radius
		"hooded":
			return Tuning.hooded_radius
		"mirror":
			return Tuning.mirror_glow_radius
	return Tuning.lantern_max_radius

func min_frac() -> float:
	return Tuning.reservoir_min_radius_frac if kind == "reservoir" else Tuning.lantern_min_radius_frac

func base_burn() -> float:
	match kind:
		"reservoir":
			return Tuning.reservoir_burn_per_sec
		"mirror":
			return 0.0
	return Tuning.lantern_burn_per_sec

func needs_fuel() -> bool:
	return kind != "mirror"

## Lit = burning (or, for a mirror, catching light).
func is_lit() -> bool:
	return catching if kind == "mirror" else fuel > 0.0

func fuel_frac() -> float:
	if kind == "mirror":
		return 1.0
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

func wind_proof() -> bool:
	return kind == "hooded" or kind == "mirror"

func in_gust() -> bool:
	if wind_proof():
		return false
	var w := _wind()
	return w != null and w.is_gusting() and not is_sheltered_from(w.direction)

## The Windward Ridge has a constant west wind on top of the gusts.
func in_ridge_wind() -> bool:
	if wind_proof():
		return false
	var fog := _fog()
	return fog != null and fog.region_at(global_position) == FogGrid.R_RIDGE and not is_sheltered_from(PREVAILING)

func burn_rate() -> float:
	var f := 1.0
	if in_ridge_wind():
		f *= Tuning.ridge_burn_mult
	if in_gust():
		f *= Tuning.wind_burn_mult
	return base_burn() * f

func get_light_radius() -> float:
	if not is_lit():
		return 0.0
	var r := base_radius() * (lerpf(min_frac(), 1.0, fuel_frac()) if needs_fuel() else 1.0)
	if in_ridge_wind():
		r *= Tuning.ridge_radius_mult
	if in_gust():
		r *= Tuning.wind_radius_mult
	return r

# --- Mirror beam ----------------------------------------------------------------

func beam_dir() -> Vector2:
	return DIRS[mirror_dir].normalized()

func turn() -> void:
	mirror_dir = (mirror_dir + 1) % DIRS.size()
	queue_redraw()

## The beam segment [from, to], clipped at the first rock tile. Empty if not catching.
func beam_segment() -> Array:
	if kind != "mirror" or not catching:
		return []
	var fog := _fog()
	var from := global_position
	var dir := beam_dir()
	var length := Tuning.mirror_beam_length
	if fog:
		var step := 8.0
		var d := step
		while d <= length:
			if fog.is_solid_at(from + dir * d):
				length = d - step
				break
			d += step
	return [from, from + dir * length]

## How brightly a point sits in this mirror's beam (0 outside).
func beam_level_at(p: Vector2) -> float:
	var seg := beam_segment()
	if seg.is_empty():
		return 0.0
	var closest := Geometry2D.get_closest_point_to_segment(p, seg[0], seg[1])
	var off := closest.distance_to(p)
	if off > Tuning.mirror_beam_width * 0.5:
		return 0.0
	return 1.0 - off / (Tuning.mirror_beam_width * 0.5) * 0.4

# --- Fuel --------------------------------------------------------------------

func refuel(amount: float) -> float:
	if not needs_fuel():
		return 0.0
	var before := fuel
	fuel = minf(fuel + amount, max_fuel())
	return fuel - before

func _process(delta: float) -> void:
	if fuel > 0.0 and needs_fuel():
		fuel = maxf(0.0, fuel - burn_rate() * delta)
	if kind == "reservoir" and fuel > 0.0:
		_feed(delta)
	var r := get_light_radius()
	light.enabled = r > 0.0
	if r > 0.0:
		light.texture_scale = LightTex.scale_for(r)
		var flicker := 0.15 if (in_gust() or in_ridge_wind()) else 0.06
		var base := 0.6 if kind == "reservoir" else 0.85
		light.energy = base + sin(Time.get_ticks_msec() * 0.011 + get_instance_id() % 97) * flicker
	if beam_light:
		var seg := beam_segment()
		beam_light.enabled = not seg.is_empty()
		if beam_light.enabled:
			beam_light.rotation = beam_dir().angle()
			beam_light.texture_scale = maxf(seg[0].distance_to(seg[1]), 8.0) / 256.0
	queue_redraw()

## Reservoir: share fuel with other fuel-burning lanterns inside its light, lit or cold.
func _feed(delta: float) -> void:
	var r := get_light_radius()
	for l in get_tree().get_nodes_in_group("lantern"):
		if l == self or l.kind == "reservoir" or not l.needs_fuel():
			continue
		if l.global_position.distance_to(global_position) > r:
			continue
		var give := minf(minf(Tuning.reservoir_feed_per_sec * delta, l.max_fuel() - l.fuel), fuel)
		if give <= 0.0:
			continue
		l.fuel += give
		fuel -= give

func _draw() -> void:
	var lit := is_lit()
	var file := ""
	match kind:
		"reservoir":
			file = "reservoir_lamp_" + ("lit.png" if lit else "cold.png")
		"hooded":
			file = "hooded_lamp_" + ("lit.png" if lit else "cold.png")
		"mirror":
			file = "mirror_post_" + ("lit.png" if lit else "dark.png")
		_:
			file = "post_lamp_" + ("lit.png" if lit else "cold.png")
	Art.sprite(self, Art.placeholder(file), Vector2(0, 16))
	if kind == "mirror":
		# Which way it points.
		var d := beam_dir()
		var c := Vector2(0, LAMP_Y)
		draw_line(c, c + d * 18.0, Color(1.0, 0.92, 0.7, 0.9 if lit else 0.45), 2.0)
		draw_circle(c + d * 18.0, 2.5, Color(1.0, 0.92, 0.7, 0.9 if lit else 0.45))
		return
	var bar := Color(1.0, 0.7, 0.3)
	if (in_gust() or in_ridge_wind()) and int(Time.get_ticks_msec() / 250) % 2 == 0:
		bar = Color(1.0, 0.35, 0.25)   # flashing: burning fast in the wind
	draw_rect(Rect2(-12, 19, 24, 4), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(-12, 19, 24 * fuel_frac(), 4), bar)
