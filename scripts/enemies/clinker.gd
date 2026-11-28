class_name Clinker
extends Foe
## Heavy Hollow elite. Its shell regrows until cracked; the roll has a ground tell.
## Readability step (ART_DIRECTION §4.3 rows 7-8): it uncurls for kl_clinker_wake_time when it wakes and can't
## roll until it is done; the roll's wind-up (kl_clinker_roll_tell) shows a full-width lane (Telegraph LANE,
## half-width kl_clinker_hit_range, the same reach the roll hits with) to the roll's end, filling outwards; after
## the roll it is dizzy for kl_clinker_recover (it can't move or roll: the open window).

var _rolling_t := 0.0
var _roll_dir := Vector2.RIGHT
var _roll_hit := false
var _cooldown := 1.0
var home := Vector2.ZERO        # its post: it sleeps here until you come close, and goes back if you leave
var awake := false
var _tell: Telegraph.Tell
var _wake_t := 0.0              # > 0: uncurling after waking
var _dizzy_t := 0.0             # > 0: dizzy after a roll
var _spin := 0.0
var _t := 0.0
var _art: FoeSprite              # owner art (assets/art/creatures/clinker/), when it exists
var _art_from := Vector2.ZERO    # where it stood a frame ago: it trundles when this moves
const ART_FOOT := 18.0           # the 32 x 32 strip's foot (foot anchor), at the bottom of the code body

func _ready() -> void:
	foe_name = "Clinker"
	hp = Tuning.kl_clinker_hp
	shell = Tuning.kl_clinker_shell
	shell_max = shell
	shell_regrows = true
	foe_id = "clinker_hollow_post"
	wick_value = Tuning.kl_clinker_wick
	level = Tuning.kl_clinker_level
	knock_weight = 0.35
	oil_step = true   # a mid-boss: 1 lamp oil at half health (GAME_PLAN §5)
	z_index = 8
	_art = FoeSprite.attach(self, "clinker")
	if _art:
		_art.position = Vector2(0, ART_FOOT)
		_art.play_anim("sleep")

func _exit_tree() -> void:
	if _tell:
		_tell.finish()

## The faint rule: back to the start of its (one) phase: full health, shell regrown, asleep on its post, its oil
## armed again.
func reset_for_faint() -> void:
	if _dead or is_queued_for_deletion():
		return
	hp = Tuning.kl_clinker_hp * level_mult()
	hp_max = hp
	shell = Tuning.kl_clinker_shell * level_mult()
	shell_max = shell
	_oil_step_given = false
	_ignite_t = 0.0
	_linger_t = 0.0
	if _tell:
		_tell.finish()
		_tell = null
	_rolling_t = 0.0
	_dizzy_t = 0.0
	_wake_t = 0.0
	_cooldown = 1.0
	awake = false
	if home != Vector2.ZERO:
		global_position = home

## The roll's wind-up in progress (tests and captures), or null.
func tell() -> Telegraph.Tell:
	return _tell

func is_rolling() -> bool:
	return _rolling_t > 0.0

func is_dizzy() -> bool:
	return _dizzy_t > 0.0

func is_waking() -> bool:
	return _wake_t > 0.0

func _process(delta: float) -> void:
	_step(delta)
	_update_art()

func _step(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	if fade_if_held(delta):
		return
	_t += delta
	var p := _player()
	if p == null or _hitstop_t > 0.0:   # a big hit freezes it, mid-roll too
		queue_redraw()
		return
	if home == Vector2.ZERO:
		home = global_position
	var from_home: float = p.global_position.distance_to(home)
	if not awake:
		if from_home > Tuning.kl_clinker_wake_radius:
			queue_redraw()
			return   # asleep on its post
		awake = true
		_wake_t = Tuning.kl_clinker_wake_time
		Telegraph.play_slot("clinker", "notice")
	elif from_home > Tuning.kl_clinker_leash and _rolling_t <= 0.0 and _tell == null:
		# You left: it trundles back to its post and settles (its shell regrows on its own).
		_dizzy_t = 0.0
		var back := home - global_position
		global_position += back.limit_length(Tuning.kl_clinker_speed * delta)
		if back.length() < 4.0:
			awake = false
		queue_redraw()
		return
	var to_player := p.global_position - global_position
	if _rolling_t > 0.0:
		var step := minf(Tuning.kl_clinker_roll_speed * delta, _rolling_t * Tuning.kl_clinker_roll_speed)
		global_position += _roll_dir * step
		_spin += step / 20.0
		_rolling_t -= delta
		if not _roll_hit and p.global_position.distance_to(global_position) < Tuning.kl_clinker_hit_range and not p.combat.is_dashing():
			_roll_hit = true
			p.chill(hit_warmth())
			# M1c: the roll throws the keeper out of its lane (forward and to the side they stood on).
			var side := _roll_dir.orthogonal()
			if side.dot(p.global_position - global_position) < 0.0:
				side = -side
			p.knockback(_roll_dir * 0.5 + side, Tuning.kl_clinker_knock)
		if _rolling_t <= 0.0:
			_dizzy_t = Tuning.kl_clinker_recover   # recover: dizzy, open to hits
	else:
		_cooldown = maxf(0.0, _cooldown - delta)
		_wake_t = maxf(0.0, _wake_t - delta)
		_dizzy_t = maxf(0.0, _dizzy_t - delta)
		if _tell:
			_tell.tick(delta)
			if not _tell.locked():
				_tell.center = global_position
				_tell.to = global_position + _roll_dir * Tuning.kl_clinker_roll_dist
			if _tell.done():
				global_position = _tell.center   # the roll starts where its lane does
				_tell.finish()
				_tell = null
				_rolling_t = Tuning.kl_clinker_roll_dist / Tuning.kl_clinker_roll_speed
				Telegraph.play_slot("clinker", "release")
		elif _wake_t > 0.0 or _dizzy_t > 0.0:
			pass   # uncurling, or dizzy: it can't move or roll
		elif not is_stunned() and to_player.length() < Tuning.kl_clinker_target_range and _cooldown <= 0.0:
			_roll_dir = to_player.normalized()   # the direction locks at the start (good: ART_DIRECTION §4.3 row 8)
			_roll_hit = false
			_tell = Telegraph.begin(self, Telegraph.LANE, "clinker", Tuning.kl_clinker_roll_tell)
			_tell.boss = true
			_tell.radius = Tuning.kl_clinker_hit_range
			_tell.to = global_position + _roll_dir * Tuning.kl_clinker_roll_dist
			Telegraph.arm(_tell, get_tree())
			Story.tip("dash")   # the first roll tell teaches the dash
			_cooldown = Tuning.kl_clinker_roll_cooldown
		elif not is_stunned() and to_player.length() > Tuning.kl_clinker_stop_range:
			global_position += to_player.normalized() * minf(Tuning.kl_clinker_speed * delta, to_player.length() - Tuning.kl_clinker_stop_range)
	queue_redraw()

## Owner art: the strip for what it is doing (after each step). Asleep on its post: sleep; waking: wake (stretched to
## kl_clinker_wake_time); the roll's wind-up: windup (the curl, stretched to the tell); rolling: roll (one full turn,
## looped, mirrored when it rolls left); dizzy after a roll: recover (stretched to kl_clinker_recover); moving:
## move (the trundle); else idle. The hurt flinch and the shell crack are one-shots (_on_hurt, _on_shell_cracked).
func _update_art() -> void:
	if _art == null:
		return
	var moved := global_position - _art_from
	_art_from = global_position
	var anim := "idle"
	var secs := 0.0
	if not awake:
		anim = "sleep"
	elif _rolling_t > 0.0:
		anim = "roll"
	elif _tell:
		anim = "windup"
		secs = _tell.duration
	elif _wake_t > 0.0:
		anim = "wake"
	elif _dizzy_t > 0.0:
		anim = "recover"
	elif moved.length() > 0.01:
		anim = "move"
	if _rolling_t > 0.0 or _tell:
		if absf(_roll_dir.x) > 0.05:
			_art.flip_h = _roll_dir.x < 0.0   # drawn facing right: it faces (and turns) the way it rolls
	elif anim == "move" and absf(moved.x) > 0.01:
		_art.flip_h = moved.x < 0.0
	_art.play_anim(anim, secs)
	_art.position = Vector2(sin(_t * 9.0) * 3.0 if _dizzy_t > 0.0 else 0.0, ART_FOOT)   # dizzy: it wobbles

## Owner art: a flinch for a real hit (not the beam's or a burn's steady damage), while it isn't curling or
## rolling (the shell ring and the roll stay the readable thing then).
func _on_hurt(_scare: bool, source: String) -> void:
	if _art and awake and not (source in STEADY) and _rolling_t <= 0.0 and _tell == null and not _art.holding():
		_art.play_once("hurt")

func _on_shell_cracked() -> void:
	super._on_shell_cracked()
	if _art and _rolling_t <= 0.0:
		_art.play_once("crack")

func body_radius() -> float:
	return 25.0

## Its roll's hit: the Hollow's hardest single hit (M1c damage fix), grown by its level.
func hit_warmth() -> float:
	return Tuning.kl_clinker_hit_warmth * dmg_level_mult()

func _draw() -> void:
	var curl := 0.0          # 0 resting, 1 curled into a ball
	if _tell:
		curl = _tell.progress()
	elif _rolling_t > 0.0:
		curl = 1.0
	var wob := sin(_t * 9.0) * 3.0 if _dizzy_t > 0.0 else 0.0
	if _art and _art.showing():
		_draw_overlays()
		return
	draw_set_transform(Vector2(wob, 0), _spin if _rolling_t > 0.0 else wob * 0.03, Vector2.ONE)
	var rest := [Vector2(-24, 10), Vector2(-19, -6), Vector2(-10, -16), Vector2(8, -19), Vector2(22, -8), Vector2(24, 9), Vector2(10, 17), Vector2(-12, 16)]
	var pts := PackedVector2Array()
	for i in rest.size():
		var ball := Vector2.from_angle(TAU * i / rest.size() + 2.4) * 21.0
		pts.append(rest[i].lerp(ball, curl))
	draw_colored_polygon(pts, Color(0.15, 0.2, 0.28))
	# Plates along its back close up as it curls.
	for i in 4:
		var x := -12.0 + i * 8.0 * (1.0 - curl * 0.4)
		draw_line(Vector2(x, -9), Vector2(x + 3.0, 3), Color(0.4, 0.65, 0.82, 0.7), 2.0)
	# Eyes: shut asleep, opening as it wakes, visible to the last frame of the curl.
	var open := 1.0
	if not awake:
		open = 0.15
	elif _wake_t > 0.0:
		open = 1.0 - _wake_t / maxf(Tuning.kl_clinker_wake_time, 0.01)
	var eye := Color(0.75, 0.86, 0.96)
	if _dizzy_t > 0.0:
		eye = Color(0.45, 0.55, 0.66)
	for ex in [-6.0, 6.0]:
		draw_rect(Rect2(ex - 2.5, -9.0 - 2.5 * open, 5.0, maxf(1.0, 5.0 * open)), eye)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_overlays()

## What stays code-drawn over the sprite too: the shell ring, the burning edge and the dizzy stars.
func _draw_overlays() -> void:
	draw_shell(Vector2.ZERO, 30.0)
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 32, Color(1.0, 0.72, 0.4, 0.9), 3.0)
	# Dizzy: three pale stars circling its head. This is the moment to hit it.
	if _dizzy_t > 0.0:
		for i in 3:
			var a := _t * 5.0 + TAU * i / 3.0
			var c := Vector2(cos(a) * 16.0, -30.0 + sin(a) * 5.0)
			draw_line(c - Vector2(3, 0), c + Vector2(3, 0), Telegraph.COLD, 1.5)
			draw_line(c - Vector2(0, 3), c + Vector2(0, 3), Telegraph.COLD, 1.5)
