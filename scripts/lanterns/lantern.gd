class_name Lantern
extends Node2D
## A lantern of any type (M1b, GAME_PLAN §6: no more tending). Lamps never burn down, never dim and need no fuel.
## A lantern is lit unless:
##   - it is an old cold lamp (`old` and `cold`: the hut lamp and the north path's lamp) that the keeper has not
##     lit yet by touch (A / E), or
##   - something snuffed it for a while (`snuff()`: the Ashbrood's dive, Tuning.kl_snuff_sec); it relights itself.
## Kinds:
##   post:      the basic lamp.
##   reservoir: a wide dim light (its new job, forcing things up out of water, comes in M5).
##   hooded:    a smaller light (its new job, the only lamp a gust can't snuff, comes in M6).
##   mirror:    when it sits in another lantern's light (or in another mirror's beam) it throws a long, narrow
##              beam in one of 8 directions. Interact to turn it. Beams are blocked by rock.
##
## Everything a lit lantern DOES to the world is in the "Effects" section below, and only there: its light radius,
## the bright core that burns small foes and nests, whether small dark is kept out (timid) or burns after a while
## (brave), and where it refills the keeper. Fog clearing follows the light radius. Foes (through LightSense), the keeper and
## the fog read these methods; they don't know about kinds. New lantern mechanics go in that section.

const NAMES := {"post": "Post Lamp", "reservoir": "Reservoir Lamp", "hooded": "Hooded Lamp", "mirror": "Mirror Post"}
const DIRS := [Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1), Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1)]
## Lamp box height above the tile centre, so the light glows from the lamp, not the base.
const LAMP_Y := -34.0
## The Post Lamp is a shepherd's crook: its lamp hangs to the right of the post.
const CROOK_LAMP := Vector2(9, -19)

var kind := "post"
var old := false          # one of the valley's old lamps (placed by the world, not built): can't be picked up
var cold := false         # an old lamp not yet lit by touch (only old lamps start cold)
var snuff_t := 0.0        # > 0: snuffed (the Ashbrood's dive); it relights by itself when this runs out
var mirror_dir := 0       # mirror only: index into DIRS
var catching := false     # mirror only: set each fog tick by FogGrid
var smother_t := 0.0      # mirror only: seconds of smothering left (a Wickling keeps topping it up)
var threatened := 0.0     # > 0: the Ashbrood is winding up a dive at this lamp (it flickers)
var light: PointLight2D
var beam_light: PointLight2D
# M1c combos (PLAN_LANTERNS §3): a lamp's flame flares (a Fireglobe), feeds (the Beam) and gulps (catch, chain).
var flare_t := 0.0        # > 0: flaring (its light x kl_flare_light_mult, settling back over kl_flare_time)
var flare_cd := 0.0       # > 0: it can't flare again yet (a small ember on the post shows it)
var feed_t := 0.0         # > 0: the Beam is feeding it (light x kl_feed_light_mult, core x kl_feed_core_mult)
var gulp_t := 0.0         # > 0: its flame just took a bolt or a chain (the flame swells)
var smother_by: Node = null   # the Ashbrood sitting on it (M1c: it stays lit during the sit, then goes out)

static func cost(k: String) -> int:
	match k:
		"reservoir":
			return Tuning.reservoir_cost_scrap
		"hooded":
			return Tuning.hooded_cost_scrap
		"mirror":
			return Tuning.mirror_cost_scrap
	return Tuning.post_lamp_cost_scrap

static func cost_text(k: String) -> String:
	return "%d scrap" % cost(k)

static func display(k: String) -> String:
	return NAMES.get(k, "???")

## DRAFT (M1b): the lantern list's line for each kind (STORY §15).
static func blurb(k: String) -> String:
	match k:
		"post":
			return "A steady light. Its bright core burns small foes and nests."
		"reservoir":
			return "A wide, dim light with no core."
		"hooded":
			return "A smaller light behind a hood."
		"mirror":
			return "Place it in another lantern's light and it throws a long beam. [E / A] turns it."
	return ""

func _enter_tree() -> void:
	LightSense.bump()

func _exit_tree() -> void:
	LightSense.bump()

func _ready() -> void:
	add_to_group("light_source")
	add_to_group("lantern")
	if kind == "mirror":
		add_to_group("mirror")
	if not old:
		cold = false   # only the valley's old lamps can start cold
	z_index = 20
	light = PointLight2D.new()
	light.texture = LightTex.radial()
	light.color = Color(0.9, 0.86, 0.62) if kind == "reservoir" else Color(1.0, 0.78, 0.45)
	light.position = Vector2(0, -44 if kind == "reservoir" else LAMP_Y)
	if kind == "post":
		light.position = CROOK_LAMP
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

# --- State -----------------------------------------------------------------------

## Lit = shining (or, for a mirror, catching light).
func is_lit() -> bool:
	if kind == "mirror":
		return catching
	return not cold and snuff_t <= 0.0

func is_snuffed() -> bool:
	return snuff_t > 0.0

## An old cold lamp the keeper can light by touch.
func can_light_by_touch() -> bool:
	return old and cold

## The keeper's touch lights an old cold lamp (A / E). True if it lit.
func light_by_touch() -> bool:
	if not can_light_by_touch():
		return false
	cold = false
	LightSense.bump()
	queue_redraw()
	return true

## Snuffed for a while (the Ashbrood's dive); it relights itself.
func snuff(seconds: float) -> void:
	if kind == "mirror":
		return
	snuff_t = maxf(snuff_t, seconds)
	LightSense.bump()
	queue_redraw()

## Planted lamps can be picked up; the valley's old lamps can't.
func can_pick_up() -> bool:
	return not old

# --- Flames and combos (M1c) -------------------------------------------------------------------------------

## A flame the keeper's fire combos with: a lit lamp that isn't a mirror (planted, or a lit old lamp). WayLamps
## are not Lanterns, so they never combo.
func has_flame() -> bool:
	return kind != "mirror" and is_lit()

## Where its flame is in the world (the lamp head: the crook's lamp on a Post Lamp).
func flame_pos() -> Vector2:
	match kind:
		"post":
			return global_position + CROOK_LAMP
		"reservoir":
			return global_position + Vector2(0, -44)
	return global_position + Vector2(0, LAMP_Y)

## The nearest flame within `reach` of a point, or null. Every lit lamp in the group "lantern".
static func flame_near(p: Vector2, reach: float, exclude: Array = []) -> Lantern:
	LightSense.refresh(Engine.get_main_loop() as SceneTree)
	var best: Lantern = null
	var best_d := reach
	for l in LightSense.nodes:
		if not is_instance_valid(l) or l in exclude or not l.has_flame():
			continue
		var d: float = l.flame_pos().distance_to(p)
		if d <= best_d:
			best_d = d
			best = l
	return best

func can_flare() -> bool:
	return has_flame() and flare_cd <= 0.0

## A Fireglobe on its flame: it flares (light x kl_flare_light_mult, settling back over kl_flare_time). False on
## cooldown (the globe bursts as normal).
func flare() -> bool:
	if not can_flare():
		return false
	flare_t = Tuning.kl_flare_time
	flare_cd = Tuning.kl_flare_lamp_cd
	gulp_t = 0.3
	LightSense.bump()
	return true

func is_flaring() -> bool:
	return flare_t > 0.0

## The Beam touching its flame (called every frame it touches).
func feed() -> void:
	if has_flame():
		feed_t = 0.1

func is_fed() -> bool:
	return feed_t > 0.0

## A bolt caught at its flame, or a chain arced through it: the flame swells for a moment.
func gulp() -> void:
	gulp_t = 0.25

## How much its light is grown now (a flare settling back, the Beam feeding it).
func light_mult() -> float:
	var m := 1.0
	if flare_t > 0.0:
		m = maxf(m, 1.0 + (Tuning.kl_flare_light_mult - 1.0) * clampf(flare_t / maxf(Tuning.kl_flare_time, 0.01), 0.0, 1.0))
	if feed_t > 0.0:
		m = maxf(m, Tuning.kl_feed_light_mult)
	return m

# --- Effects (everything a lit lantern does; the one place to change or add lantern mechanics) ---------------

## Full light radius while lit, by kind.
func base_radius() -> float:
	match kind:
		"reservoir":
			return Tuning.reservoir_radius
		"hooded":
			return Tuning.hooded_radius
		"mirror":
			return Tuning.mirror_glow_radius
	return Tuning.lantern_max_radius

## How far its light reaches now (0 when not lit). Lamps never dim (M1b).
func get_light_radius() -> float:
	return base_radius() * light_mult() if is_lit() else 0.0

## The bright core's share of the light (from the centre): small foes burn there, and only a core burns a nest.
## 0 = no core. Mirrors have none (their beam burns instead).
func core_frac() -> float:
	return 0.0 if kind == "mirror" else 1.0 - Tuning.wick_core

## Damage a second its bright core does to a foe standing in it (0 = the core ignores it). Elites, the Clinker
## and the Ashbrood don't care about lanterns at all (owner, 2026-11-27).
func core_dps_for(foe: Node) -> float:
	if core_frac() <= 0.0:
		return 0.0
	if (foe is Wickling and foe.elite) or foe is Clinker or foe is Ashbrood:
		return 0.0
	var dps := Tuning.kl_nest_core_dps if foe is WickNest else Tuning.wick_light_burn
	if Progress.has_line("hot_core"):
		dps *= Tuning.kl_hot_core_mult
	if feed_t > 0.0:
		dps *= Tuning.kl_feed_core_mult
	return dps

## Small dark is kept out of this light: timid Wicklings stay out, brave ones burn after a while
## (Tuning.kl_light_tolerance). Every lit lamp does this; mirrors' glows don't (their beams burn instead).
func repels_small_dark() -> bool:
	return kind != "mirror"

## The keeper refills here (charge and, out of a fight, warmth; GAME_PLAN §5): within this share of the radius.
func refill_frac() -> float:
	return 0.85

## Fog: every lit light clears fog out to get_light_radius() (FogGrid reads the group "light_source").

# --- Mirror beam ----------------------------------------------------------------

func beam_dir() -> Vector2:
	return DIRS[mirror_dir].normalized()

## Turn the mirror one step: +1 clockwise (right), -1 counter-clockwise (left).
func turn(step: int = 1) -> void:
	mirror_dir = posmod(mirror_dir + step, DIRS.size())
	queue_redraw()

func is_smothered() -> bool:
	return kind == "mirror" and smother_t > 0.0

func smother() -> void:
	smother_t = 0.25

var _fog_ref: FogGrid
var _seg_pos := Vector2.INF       # beam_segment cache key: position, direction and beam length
var _seg_dir := -1
var _seg_len := -1.0
var _seg: Array = []

func _fog() -> FogGrid:
	if _fog_ref == null or not is_instance_valid(_fog_ref):
		_fog_ref = get_tree().get_first_node_in_group("fog_grid") as FogGrid
	return _fog_ref

## The beam segment [from, to], clipped at the first rock tile. Empty if not catching.
func beam_segment() -> Array:
	if kind != "mirror" or not catching:
		return []
	var fog := _fog()
	var from := global_position
	if from == _seg_pos and mirror_dir == _seg_dir and Tuning.mirror_beam_length == _seg_len and fog != null:
		return _seg
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
		_seg_pos = from
		_seg_dir = mirror_dir
		_seg_len = Tuning.mirror_beam_length
		_seg = [from, from + dir * length]
		return _seg
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

# --- Frame -----------------------------------------------------------------------

func _process(delta: float) -> void:
	smother_t = maxf(0.0, smother_t - delta)
	threatened = maxf(0.0, threatened - delta)
	flare_t = maxf(0.0, flare_t - delta)
	flare_cd = maxf(0.0, flare_cd - delta)
	feed_t = maxf(0.0, feed_t - delta)
	gulp_t = maxf(0.0, gulp_t - delta)
	if snuff_t > 0.0:
		snuff_t = maxf(0.0, snuff_t - delta)
		if snuff_t <= 0.0:
			LightSense.bump()   # it relights: the foes' snapshot must see it at once
	var r := get_light_radius()
	light.enabled = r > 0.0
	if r > 0.0:
		light.texture_scale = LightTex.scale_for(r)
		var flicker := 0.06
		if threatened > 0.0:
			flicker = 0.45   # a dive is coming for it
		var base := 0.6 if kind == "reservoir" else 0.85
		light.energy = base + sin(Time.get_ticks_msec() * 0.011 + get_instance_id() % 97) * flicker
	if beam_light:
		var seg := beam_segment()
		beam_light.enabled = not seg.is_empty()
		if beam_light.enabled:
			beam_light.rotation = beam_dir().angle()
			beam_light.texture_scale = maxf(seg[0].distance_to(seg[1]), 8.0) / 256.0
	_redraw_if_changed()

var _look := -1

## Redraw only when what is drawn changes (performance): it lights or goes out, a mirror turns. Smother wisps and a
## snuffed lamp's smoke animate, so they redraw every frame.
func _redraw_if_changed() -> void:
	if is_smothered() or is_snuffed() or flare_t > 0.0 or flare_cd > 0.0 or feed_t > 0.0 or gulp_t > 0.0 or (smother_by != null and is_instance_valid(smother_by)):
		_look = -1
		queue_redraw()
		return
	var look := int(is_lit()) | (mirror_dir << 2)
	if look != _look:
		_look = look
		queue_redraw()

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
	if kind == "mirror" and is_smothered():
		# Dark wisps over a smothered mirror.
		var tt := Time.get_ticks_msec() * 0.006
		for i in 3:
			draw_circle(Vector2(sin(tt + i * 2.1) * 6.0, LAMP_Y + cos(tt * 1.3 + i) * 4.0), 6.0, Color(0.03, 0.035, 0.06, 0.8))
	if kind == "mirror":
		# Which way it points.
		var d := beam_dir()
		var c := Vector2(0, LAMP_Y)
		draw_line(c, c + d * 18.0, Color(1.0, 0.92, 0.7, 0.9 if lit else 0.45), 2.0)
		draw_circle(c + d * 18.0, 2.5, Color(1.0, 0.92, 0.7, 0.9 if lit else 0.45))
		return
	if lit and kind != "mirror":
		var fl := CROOK_LAMP if kind == "post" else Vector2(0, -44 if kind == "reservoir" else LAMP_Y)
		# The combos' looks (warm only): the flame leaps on a flare, stretches while the Beam feeds it, swells on a gulp.
		if flare_t > 0.0:
			var k := clampf(flare_t / maxf(Tuning.kl_flare_time, 0.01), 0.0, 1.0)
			draw_circle(fl, 8.0 + 10.0 * k, Color(1.0, 0.7, 0.3, 0.35 * k))
			draw_colored_polygon(PackedVector2Array([fl + Vector2(-5, 3), fl + Vector2(0, -12 - 10 * k), fl + Vector2(5, 3)]), Color(1.0, 0.82, 0.45, 0.9))
		if feed_t > 0.0:
			draw_colored_polygon(PackedVector2Array([fl + Vector2(-4, 3), fl + Vector2(0, -16), fl + Vector2(4, 3)]), Color(1.0, 0.9, 0.6, 0.85))
		if gulp_t > 0.0:
			draw_circle(fl, 6.0 + 20.0 * gulp_t, Color(1.0, 0.85, 0.5, 0.6 * gulp_t / 0.25))
		if flare_cd > 0.0:
			# A small ember on the post shows the flare cooldown.
			draw_circle(Vector2(0, 2), 2.5, Color(1.0, 0.55, 0.2, 0.5 + 0.4 * flare_cd / maxf(Tuning.kl_flare_lamp_cd, 0.01)))
		if smother_by != null and is_instance_valid(smother_by):
			# Smothered by the Ashbrood's sit: dark wings over a flame that still burns (hit it now).
			var tt := Time.get_ticks_msec() * 0.005
			for i in 3:
				draw_circle(fl + Vector2(sin(tt + i * 2.1) * 7.0, cos(tt * 1.3 + i) * 4.0 - 4.0), 5.0, Color(0.03, 0.035, 0.06, 0.55))
	if is_snuffed():
		# Snuffed: a thin curl of smoke, and a small ring that fills as it comes back.
		var lamp := CROOK_LAMP if kind == "post" else Vector2(0, LAMP_Y)
		var tt := Time.get_ticks_msec() * 0.003
		for i in 3:
			var k := fmod(tt + i * 0.33, 1.0)
			draw_circle(lamp + Vector2(sin(tt * 3.0 + i) * 3.0, -k * 18.0), 2.0 + k * 2.0, Color(0.55, 0.6, 0.68, 0.5 * (1.0 - k)))
		var back := 1.0 - snuff_t / maxf(Tuning.kl_snuff_sec, 0.01)
		draw_arc(lamp, 9.0, -PI / 2.0, -PI / 2.0 + TAU * back, 20, Color(1.0, 0.82, 0.48, 0.7), 2.0)
