class_name Spitwick
extends Foe
## Ranged Hollow foe. It keeps its distance and sends a slow, visible spit across lantern light.
## Readability step (ART_DIRECTION §4.3 rows 4-5): a kl_spit_tell wind-up (its throat sac swells) with an aim
## marker (Telegraph AIM: the spit's path at its full width) that follows you, then locks for the last
## kl_spit_aim_lock seconds. It never starts a wind-up off-screen: it creeps closer first.

var _shot_t := 1.2
var _tell: Telegraph.Tell
var _recover_t := 0.0
var _art: FoeSprite
const ART_FOOT := 12.0   # the owner strip's foot (16 x 32, foot anchor) at the bottom of the code shape

func _ready() -> void:
	foe_name = "Spitwick"
	hp = Tuning.kl_spitwick_hp
	wick_value = Tuning.kl_spitwick_wick
	z_index = 8
	_art = FoeSprite.attach(self, "spitwick")
	if _art:
		_art.position = Vector2(0, ART_FOOT)

func _exit_tree() -> void:
	if _tell:
		_tell.finish()

## The wind-up in progress (tests and captures), or null.
func tell() -> Telegraph.Tell:
	return _tell

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	if fade_if_held(delta):
		return
	_recover_t = maxf(0.0, _recover_t - delta)
	var p := _player()
	if p == null or is_stunned():
		queue_redraw()
		return
	var v := p.global_position - global_position
	var dist := v.length()
	var dir := v.normalized() if dist > 0.1 else Vector2.ZERO
	if _tell:
		_tell.tick(delta)
		if not _tell.locked():
			_tell.center = global_position
			_tell.to = p.global_position   # the aim follows you until it locks
		if _tell.done():
			_fire_spit(_tell.center, _tell.to)
			Telegraph.play_slot("spitwick", "release")
			_tell.finish()
			_tell = null
			_recover_t = 0.3
			_shot_t = Tuning.kl_spit_period
	elif _shot_t > 0.0:
		_shot_t -= delta
	elif dist <= Tuning.kl_spit_max_range and Telegraph.on_screen(self, global_position, Tuning.kl_spit_onscreen_margin):
		_begin_tell(p)
	elif dist > 0.1:
		# Ready, but off-screen or too far: it creeps closer first (no shot from where you can't see it).
		global_position += dir * minf(dist, Tuning.kl_spit_keep_speed * delta)
	if _tell == null:
		if dist < Tuning.kl_spit_keep_min:
			global_position -= dir * minf(Tuning.kl_spit_keep_min - dist, Tuning.kl_spit_retreat_speed * delta)
		elif dist > Tuning.kl_spit_keep_max:
			global_position += dir * minf(dist - Tuning.kl_spit_keep_max, Tuning.kl_spit_keep_speed * delta)
	if _art:
		_art.play_anim("windup" if _tell else ("recover" if _recover_t > 0.0 else "idle"), _tell.duration if _tell else 0.0)
		if absf(v.x) > 2.0:
			_art.flip_h = v.x < 0.0   # drawn facing right: it faces the keeper
	queue_redraw()

func _begin_tell(p: Node2D) -> void:
	_tell = Telegraph.begin(self, Telegraph.AIM, "spitwick", Tuning.kl_spit_tell)
	_tell.to = p.global_position
	_tell.radius = Tuning.kl_spit_hit_radius + Telegraph.KEEPER_RADIUS
	_tell.reach = Tuning.kl_spit_speed * Tuning.kl_spit_life
	_tell.lock_time = Tuning.kl_spit_aim_lock
	Telegraph.arm(_tell, get_tree())

func _fire_spit(from: Vector2, target: Vector2) -> void:
	var shot := SpitProjectile.new()
	shot.position = from
	shot.direction = (target - from).normalized()
	get_parent().add_child(shot)

func body_radius() -> float:
	return 9.0

func _draw() -> void:
	if _art and _art.showing():
		if _burning > 0.0:
			draw_arc(Vector2(0, -8), 12.0, 0.0, TAU, 24, Color(1.0, 0.72, 0.4, 0.9), 2.0)
		return
	var pulse := 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.008)
	var k := _tell.progress() if _tell else 0.0
	# Wind-up: the head tilts back and the throat sac swells to the brightest cold thing nearby.
	var tilt := -3.0 * k
	draw_colored_polygon(PackedVector2Array([Vector2(-8, 4), Vector2(-5, -7), Vector2(0, -11 + tilt), Vector2(5, -7), Vector2(8, 4), Vector2(0, 10)]), Color(0.19, 0.29, 0.42, 0.95))
	var sac := Telegraph.COLD_DEEP.lerp(Telegraph.COLD, k)
	if _recover_t > 0.0:
		sac = Color(0.2, 0.27, 0.38)   # empty and dim: the open window
	draw_circle(Vector2(0, 3), 2.5 + 3.0 * k, Color(sac, 0.85))
	draw_circle(Vector2(-3, -3 + tilt * 0.5), 1.7, Color(0.72, 0.84, 0.96, pulse))
	draw_circle(Vector2(3, -3 + tilt * 0.5), 1.7, Color(0.72, 0.84, 0.96, pulse))
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, Color(1.0, 0.72, 0.4, 0.9), 2.0)
