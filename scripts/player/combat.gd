class_name KeeperCombat
extends Node2D
## PROTOTYPE (Keeper's Light): the keeper's light as a weapon. A child of the player.
##   Beam  (hold left click / RT): a focused beam along your aim. Burns what it touches and is the
##         only thing that cracks a shell. Drains lamp charge while held; you walk slower.
##   Burst (tap F / RB): a flash around you that burns and throws back everything close. Cooldown.
##   Dash  (tap Shift / LT): a quick dash; nothing can chill you while you dash. Cooldown.
## Lamp charge is the stamina for all three, and it is also how far your hand lamp lights.
## Aim: the mouse when you last used mouse and keyboard, else the right stick, else where you face.

var beaming := false
var aim := Vector2.RIGHT          # unit vector the beam points along
var aim_override := Vector2.ZERO  # tests and captures can fix the aim
var burst_cd := 0.0
var dash_cd := 0.0
var dash_t := 0.0                 # > 0 while dashing
var dash_dir := Vector2.ZERO
var _burst_fx := 0.0              # > 0 while the burst ring is showing
var _face := Vector2.RIGHT
const BEAM_SND := "res://assets/audio/sfx/beam_loop.ogg"
const BEAM_DB := -9.0
var beam_snd: AudioStreamPlayer   # the beam's looping hiss and crackle, faded in and out

func _ready() -> void:
	add_to_group("beam_source")
	z_index = 9
	var loop := load(BEAM_SND) as AudioStreamOggVorbis
	loop.loop = true
	beam_snd = AudioStreamPlayer.new()
	beam_snd.stream = loop
	beam_snd.bus = "SFX"
	beam_snd.volume_db = -60.0
	add_child(beam_snd)

func keeper() -> Node2D:
	return get_parent() as Node2D

## Where the beam would point now.
func update_aim(move_dir: Vector2) -> void:
	if move_dir.length() > 0.1:
		_face = move_dir.normalized()
	if aim_override != Vector2.ZERO:
		aim = aim_override.normalized()
		return
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick.length() > 0.3:
		aim = stick.normalized()
	elif not InputHint.pad and get_viewport() != null:
		var to_mouse := get_global_mouse_position() - keeper().global_position
		if to_mouse.length() > 4.0:
			aim = to_mouse.normalized()
	else:
		aim = _face

## Start and end of the beam in world space (empty when not beaming). FogGrid lights it like a mirror beam.
func beam_segment() -> Array:
	if not beaming:
		return []
	var from := keeper().global_position + Vector2(0, -10)
	return [from, from + aim * Tuning.kl_beam_len]

func is_dashing() -> bool:
	return dash_t > 0.0

## Called by the keeper every physics frame with what the player is pressing.
func tick(delta: float, move_dir: Vector2, beam_held: bool, burst_pressed: bool, dash_pressed: bool) -> void:
	var k = keeper()
	update_aim(move_dir)
	burst_cd = maxf(0.0, burst_cd - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	dash_t = maxf(0.0, dash_t - delta)
	_burst_fx = maxf(0.0, _burst_fx - delta)
	beaming = beam_held and k.lamp_charge > Tuning.kl_min_charge
	if beam_held or burst_pressed or dash_pressed:
		k._since_ward = 0.0   # carried fuel never tops the lamp up mid-fight (only once you've stopped)
	if beaming:
		k.lamp_charge = maxf(0.0, k.lamp_charge - Tuning.kl_beam_cost * delta)
		burn_along_beam(delta)
	_beam_sound(delta)
	if burst_pressed:
		burst()
	if dash_pressed:
		dash(move_dir)
	queue_redraw()

## The beam's loop fades in while it fires and out when it stops (no click on release).
func _beam_sound(delta: float) -> void:
	if beaming:
		if not beam_snd.playing:
			beam_snd.play()
		beam_snd.volume_db = move_toward(beam_snd.volume_db, BEAM_DB, 240.0 * delta)
	elif beam_snd.playing:
		beam_snd.volume_db = move_toward(beam_snd.volume_db, -60.0, 180.0 * delta)
		if beam_snd.volume_db <= -59.0:
			beam_snd.stop()

## Burns everything inside the beam. Returns how many it touched.
func burn_along_beam(delta: float) -> int:
	var seg := beam_segment()
	if seg.is_empty():
		return 0
	var hit := 0
	for w in get_tree().get_nodes_in_group("wickling"):
		var c: Vector2 = Geometry2D.get_closest_point_to_segment(w.global_position, seg[0], seg[1])
		if c.distance_to(w.global_position) <= Tuning.kl_beam_half_width + w.body_radius():
			w.hurt(Tuning.kl_beam_dps * delta, false, "beam")
			hit += 1
	return hit

## The flash. Returns how many it hit, or -1 if it couldn't fire (cooldown or too little charge).
func burst() -> int:
	var k = keeper()
	if burst_cd > 0.0 or k.lamp_charge < Tuning.kl_burst_cost:
		return -1
	k.lamp_charge -= Tuning.kl_burst_cost
	burst_cd = Tuning.kl_burst_cd
	_burst_fx = 0.3
	Sfx.play("relight", -8.0, 0.3)
	var hit := 0
	for w in get_tree().get_nodes_in_group("wickling"):
		var v: Vector2 = w.global_position - k.global_position
		if v.length() <= Tuning.kl_burst_radius + w.body_radius():
			w.hurt(Tuning.kl_burst_dmg, true, "burst")
			if is_instance_valid(w) and not w.is_queued_for_deletion():
				w.knock((v.normalized() if v.length() > 0.5 else Vector2.RIGHT) * Tuning.kl_burst_knock)
			hit += 1
	return hit

## A quick dash. Returns false if it couldn't (cooldown or too little charge).
func dash(move_dir: Vector2) -> bool:
	var k = keeper()
	if dash_cd > 0.0 or k.lamp_charge < Tuning.kl_dash_cost:
		return false
	k.lamp_charge -= Tuning.kl_dash_cost
	dash_cd = Tuning.kl_dash_cd
	dash_t = Tuning.kl_dash_time
	dash_dir = move_dir.normalized() if move_dir.length() > 0.1 else aim
	return true

## How fast the keeper moves while dashing (distance spread over the dash time).
func dash_velocity() -> Vector2:
	return dash_dir * (Tuning.kl_dash_dist / Tuning.kl_dash_time)

func _draw() -> void:
	var k = keeper()
	if k == null:
		return
	# The beam: a warm core inside a soft glow.
	if beaming:
		var from := Vector2(0, -10)
		var to := from + aim * Tuning.kl_beam_len
		var flick := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.03)
		draw_line(from, to, Color(1.0, 0.85, 0.5, 0.18 * flick), Tuning.kl_beam_half_width * 2.0)
		draw_line(from, to, Color(1.0, 0.92, 0.7, 0.45 * flick), Tuning.kl_beam_half_width)
		draw_line(from, to, Color(1.0, 1.0, 0.92, 0.9), 3.0)
	# The burst: a ring flung outwards.
	if _burst_fx > 0.0:
		var t := 1.0 - _burst_fx / 0.3
		draw_arc(Vector2(0, -6), Tuning.kl_burst_radius * (0.4 + 0.6 * t), 0.0, TAU, 48, Color(1.0, 0.9, 0.6, 0.8 * (1.0 - t)), 4.0)
		draw_circle(Vector2(0, -6), Tuning.kl_burst_radius * (0.4 + 0.6 * t), Color(1.0, 0.85, 0.5, 0.12 * (1.0 - t)))
	# Cooldowns as two small arcs under the keeper (burst gold, dash blue), only while recharging.
	if burst_cd > 0.0:
		draw_arc(Vector2(-8, 14), 5.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - burst_cd / Tuning.kl_burst_cd), 12, Color(1.0, 0.8, 0.4, 0.9), 2.0)
	if dash_cd > 0.0:
		draw_arc(Vector2(8, 14), 5.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - dash_cd / Tuning.kl_dash_cd), 12, Color(0.64, 0.74, 0.83, 0.9), 2.0)
	# A faint aim line when not beaming, so you can see where the beam will go.
	if not beaming and k.lamp_charge > Tuning.kl_min_charge:
		draw_line(Vector2(0, -10) + aim * 18.0, Vector2(0, -10) + aim * 34.0, Color(1.0, 0.9, 0.6, 0.35), 2.0)
