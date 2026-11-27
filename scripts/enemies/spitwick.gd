class_name Spitwick
extends Foe
## Ranged Hollow foe. It keeps its distance and sends a slow, visible spit across lantern light.

var _shot_t := 1.2
var _tell_t := 0.0
var _move_dir := Vector2.ZERO

func _ready() -> void:
	foe_name = "Spitwick"
	hp = Tuning.kl_spitwick_hp
	wick_value = Tuning.kl_spitwick_wick
	z_index = 8

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	if fade_if_held(delta):
		return
	var p := _player()
	if p == null or is_stunned():
		queue_redraw()
		return
	var v := p.global_position - global_position
	var dist := v.length()
	var dir := v.normalized() if dist > 0.1 else Vector2.ZERO
	if _tell_t > 0.0:
		_tell_t = maxf(0.0, _tell_t - delta)
		if _tell_t <= 0.0:
			_fire_spit(p.global_position)
	elif _shot_t > 0.0:
		_shot_t -= delta
		if _shot_t <= 0.0 and dist <= Tuning.kl_spit_max_range:
			_tell_t = Tuning.kl_spit_tell
			_move_dir = dir
	else:
		_shot_t = Tuning.kl_spit_period
	if _tell_t <= 0.0:
		if dist < Tuning.kl_spit_keep_min:
			global_position -= dir * minf(Tuning.kl_spit_keep_min - dist, Tuning.kl_spit_retreat_speed * delta)
		elif dist > Tuning.kl_spit_keep_max:
			global_position += dir * minf(dist - Tuning.kl_spit_keep_max, Tuning.kl_spit_keep_speed * delta)
	queue_redraw()

func _fire_spit(target: Vector2) -> void:
	var shot := SpitProjectile.new()
	shot.position = global_position
	shot.direction = (target - global_position).normalized()
	get_parent().add_child(shot)

func body_radius() -> float:
	return 9.0

func _draw() -> void:
	var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.008)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 4), Vector2(-5, -7), Vector2(0, -11), Vector2(5, -7), Vector2(8, 4), Vector2(0, 10)]), Color(0.19, 0.29, 0.42, 0.95))
	draw_circle(Vector2(-3, -3), 1.7, Color(0.72, 0.84, 0.96, pulse))
	draw_circle(Vector2(3, -3), 1.7, Color(0.72, 0.84, 0.96, pulse))
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(1.0, 0.72, 0.4, 0.9), 2.0)
	if _tell_t > 0.0:
		var p := _player()
		if p:
			draw_line(Vector2.ZERO, to_local(p.global_position), Color(0.6, 0.8, 1.0, 0.45), 2.0)
			draw_circle(to_local(p.global_position), 7.0, Color(0.6, 0.8, 1.0, 0.22))
