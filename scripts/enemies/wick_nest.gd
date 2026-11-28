class_name WickNest
extends Foe
## Fixed Hollow lure. Its cold glows show through fog. Only the bright core of a built lantern burns it.
## Readability step (ART_DIRECTION §4.3 row 6): for the last kl_nest_hatch_tell seconds before a hatch its ring
## fills, its pods swell, cold glows show where the hatchlings will rise (Telegraph SPAWN) and its wind-up sound
## plays. Hatchlings fade in for kl_hatch_fade and can't touch you meanwhile.

var _hatch_t := 10.0
var _pulse := 0.0
var _tell: Telegraph.Tell

func _ready() -> void:
	foe_name = "Wick nest"
	hp = Tuning.kl_nest_hp
	if foe_id == "":
		foe_id = "nest_hollow"
	wick_value = Tuning.kl_nest_wick
	z_index = 6

func _exit_tree() -> void:
	if _tell:
		_tell.finish()

## The hatch's warning in progress (tests and captures), or null.
func tell() -> Telegraph.Tell:
	return _tell

## Seconds to the next hatch while the keeper is near (tests and captures can set it).
func time_to_hatch() -> float:
	return _hatch_t

func set_time_to_hatch(t: float) -> void:
	_hatch_t = t

func hurt(amount: float, scare: bool = true, source: String = "") -> void:
	if source != "core":
		return
	super.hurt(amount, scare, source)

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	if fade_if_held(delta):
		return
	_pulse += delta
	var player := _player()
	if player and player.global_position.distance_to(global_position) <= Tuning.kl_nest_wake_radius and not Progress.cleared.has(foe_id):
		_hatch_t -= delta
		if _tell == null and _hatch_t <= Tuning.kl_nest_hatch_tell and _hatch_t > 0.0:
			_tell = Telegraph.begin(self, Telegraph.SPAWN, "nest", Tuning.kl_nest_hatch_tell, false)
			_tell.radius = 10.0
			for i in Tuning.kl_nest_hatch_count:
				_tell.points.append(_hatch_point(i))
			Telegraph.arm(_tell, get_tree())
		if _tell:
			_tell.t = _tell.duration - maxf(_hatch_t, 0.0)
		if _hatch_t <= 0.0:
			_hatch_t = Tuning.kl_nest_hatch_sec
			if _tell:
				_tell.finish()
				_tell = null
			if get_tree().get_nodes_in_group("wickling").size() >= Tuning.wick_max:
				queue_redraw()
				return
			for i in Tuning.kl_nest_hatch_count:
				var w := Wickling.new()
				w.summoned = true
				w.level = level   # hatchlings are the nest's level: the level gap, not a flat 0, stops farming
				w.position = _hatch_point(i)
				w.fade_in()
				get_parent().add_child(w)
	queue_redraw()

func _hatch_point(i: int) -> Vector2:
	return global_position + Vector2.from_angle(i * TAU / 3) * 24.0

func body_radius() -> float:
	return 16.0

func _draw() -> void:
	var p := 0.6 + 0.4 * sin(_pulse * 2.1)
	var k := _tell.progress() if _tell else 0.0
	var swell := 1.0 + 0.12 * k + 0.04 * sin(_pulse * 18.0) * k   # pods bulge before a hatch
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(swell, swell))
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 10), Vector2(-15, -2), Vector2(-7, -10), Vector2(4, -13), Vector2(15, -5), Vector2(18, 9), Vector2(7, 13), Vector2(-7, 14)]), Color(0.13, 0.22, 0.34, 0.98))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_circle(Vector2(0, 0), 7.0 + p * 2.0 + 3.0 * k, Color(0.48, 0.72, 0.92, 0.4 + 0.3 * k))
	draw_circle(Vector2(-4, -2), 2.0, Color(0.78, 0.9, 1.0, p))
	draw_circle(Vector2(4, -2), 2.0, Color(0.78, 0.9, 1.0, p))
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(1.0, 0.72, 0.4, 0.9), 2.5)
	if _tell:
		# The hatch ring, filling over kl_nest_hatch_tell (it was a fixed 1 s).
		draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 24, Color(Telegraph.COLD, 0.35), 1.5)
		draw_arc(Vector2.ZERO, 25.0, -PI / 2.0, -PI / 2.0 + TAU * k, 24, Color(0.62, 0.82, 1.0, 0.9), 2.5)
