class_name Clinker
extends Foe
## Heavy Hollow elite. Its shell regrows until cracked; the roll has a ground tell.

var _roll_t := 0.0
var _rolling_t := 0.0
var _roll_dir := Vector2.RIGHT
var _roll_hit := false
var _cooldown := 1.0

func _ready() -> void:
	foe_name = "Clinker"
	hp = Tuning.kl_clinker_hp
	shell = Tuning.kl_clinker_shell
	shell_max = shell
	shell_regrows = true
	foe_id = "clinker_hollow_post"
	wick_value = Tuning.kl_clinker_wick
	knock_weight = 0.35
	z_index = 8

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	if fade_if_held(delta):
		return
	var p := _player()
	if p == null:
		queue_redraw()
		return
	var to_player := p.global_position - global_position
	if _rolling_t > 0.0:
		var step := minf(Tuning.kl_clinker_roll_speed * delta, _rolling_t * Tuning.kl_clinker_roll_speed)
		global_position += _roll_dir * step
		_rolling_t -= delta
		if not _roll_hit and p.global_position.distance_to(global_position) < Tuning.kl_clinker_hit_range and not p.combat.is_dashing():
			_roll_hit = true
			p.chill(Tuning.kl_clinker_hit_warmth)
			p.set("velocity", p.get("velocity") + _roll_dir * Tuning.kl_clinker_roll_speed * 0.18)
	else:
		_cooldown = maxf(0.0, _cooldown - delta)
		if _roll_t > 0.0:
			_roll_t -= delta
			if _roll_t <= 0.0:
				_rolling_t = Tuning.kl_clinker_roll_dist / Tuning.kl_clinker_roll_speed
		elif not is_stunned() and to_player.length() < Tuning.kl_clinker_target_range and _cooldown <= 0.0:
			_roll_dir = to_player.normalized()
			_roll_hit = false
			_roll_t = Tuning.kl_clinker_roll_tell
			_cooldown = Tuning.kl_clinker_roll_cooldown
		elif not is_stunned() and to_player.length() > Tuning.kl_clinker_stop_range:
			global_position += to_player.normalized() * minf(Tuning.kl_clinker_speed * delta, to_player.length() - Tuning.kl_clinker_stop_range)
	queue_redraw()

func body_radius() -> float:
	return 25.0

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-24, 10), Vector2(-19, -6), Vector2(-10, -16), Vector2(8, -19), Vector2(22, -8), Vector2(24, 9), Vector2(10, 17), Vector2(-12, 16)]), Color(0.15, 0.2, 0.28))
	for i in 4:
		var x := -12.0 + i * 8.0
		draw_line(Vector2(x, -9), Vector2(x + 3.0, 3), Color(0.4, 0.65, 0.82, 0.7), 2.0)
	draw_circle(Vector2(-6, -9), 2.5, Color(0.75, 0.86, 0.96))
	draw_circle(Vector2(6, -9), 2.5, Color(0.75, 0.86, 0.96))
	draw_shell(Vector2.ZERO, 30.0)
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(1.0, 0.72, 0.4, 0.9), 3.0)
	if _roll_t > 0.0:
		draw_line(Vector2.ZERO, _roll_dir * Tuning.kl_clinker_roll_dist, Color(0.64, 0.78, 0.9, 0.5), 3.0)
		draw_arc(_roll_dir * 56.0, 38.0, 0.0, TAU, 28, Color(0.64, 0.78, 0.9, 0.3), 2.0)
