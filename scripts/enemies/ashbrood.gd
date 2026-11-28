class_name Ashbrood
extends Foe
## The Hollow's WayLamp guardian. A two-phase fight: the bowl, then the planted lamps.
## Readability step (ART_DIRECTION §4.3 rows 9-14), every wind-up through the shared Telegraph:
##   - the ash puff: its kl_ashbrood_puff_radius circle at full size from the first frame, filling in over
##     kl_ashbrood_puff_tell; a dash avoids its chill and its charge drain;
##   - adds: cold glows where they will rise, kl_ashbrood_add_tell before they come (they fade in, harmless, for
##     kl_hatch_fade);
##   - the dive: a landing circle (kl_ashbrood_hit_radius, the one radius it hits with, lamp or no lamp), its path,
##     an edge arrow when the landing point is off-screen, the target lamp flickering; then a visible flight of
##     kl_ashbrood_dive_travel, not a jump;
##   - it sits for kl_ashbrood_sit_sec after a dive, slumped with its eyes dim (the open window);
##   - between phases it rises out of the bowl for kl_ashbrood_phase_pause: no attacks, no damage.
## M1b: it is Lv kl_ashbrood_level (5) and each phase's health and shell grow with it (Foe.level_mult). Its dive
## snuffs the lamp it lands on for kl_snuff_sec; the lamp relights itself. After a faint it starts its current
## phase again (restart_phase). It broods over the WayLamp's last ember (DECISIONS 2026-11-27): the WayLamp
## draws the ember, and takes it back when the Ashbrood dies.

var waylamp: WayLamp
var phase := 1
var _puff_t := 2.0
var _wave_t := 3.0
var _dive_t := 2.0
var _sit_t := 0.0
var _target_lamp: Lantern
var _pulse := 0.0
var _roll_dir := Vector2.RIGHT
var _puff: Telegraph.Tell        # the ash puff's wind-up
var _adds: Telegraph.Tell        # the call for adds (spawn glows)
var _dive: Telegraph.Tell        # the dive's landing circle (kept through the flight; finished on landing)
var _fly_t := 0.0                # > 0: in the air, diving
var _fly_from := Vector2.ZERO
var _phase_t := 0.0              # > 0: rising out of the bowl between phases (no attacks, no damage)
var _ash_t := 0.0                # > 0: the ash ring left by a puff

func _ready() -> void:
	foe_name = "The Ashbrood"
	hp = Tuning.kl_ashbrood_hp
	shell = Tuning.kl_ashbrood_shell
	shell_max = shell
	shell_regrows = true
	foe_id = "ashbrood_hollow"
	wick_value = Tuning.kl_ashbrood_wick
	level = Tuning.kl_ashbrood_level
	knock_weight = 0.15
	oil_step = true   # 1 lamp oil at the half of each phase (Tuning.kl_boss_oil_step; GAME_PLAN §5)
	z_index = 9

func _exit_tree() -> void:
	for t in [_puff, _adds, _dive]:
		if t:
			t.finish()

## Wind-ups in progress (tests and captures).
func puff_tell() -> Telegraph.Tell:
	return _puff

func adds_tell() -> Telegraph.Tell:
	return _adds

func dive_tell() -> Telegraph.Tell:
	return _dive

func is_flying() -> bool:
	return _fly_t > 0.0

func is_sitting() -> bool:
	return _sit_t > 0.0

func in_phase_pause() -> bool:
	return _phase_t > 0.0

## Ends the rise between phases at once (tests that hurt it with its process off).
func end_phase_pause() -> void:
	_phase_t = 0.0

func hurt(amount: float, scare: bool = true, source: String = "") -> void:
	if _phase_t > 0.0:
		return   # rising out of the bowl: it can't be hurt
	super.hurt(amount, scare, source)

func _lose_hp(amount: float) -> void:
	if _phase_t > 0.0:
		return
	super._lose_hp(amount)

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	_pulse += delta
	_ash_t = maxf(0.0, _ash_t - delta)
	if _phase_t > 0.0:
		_phase_t = maxf(0.0, _phase_t - delta)
		queue_redraw()
		return
	var player := _player()
	if player == null or is_stunned():
		queue_redraw()
		return
	if phase == 1:
		_process_bowl(delta, player)
	else:
		_process_dive(delta, player)
	queue_redraw()

func _process_bowl(delta: float, player: Node2D) -> void:
	if _puff:
		_puff.tick(delta)
		_puff.center = global_position
		if _puff.done():
			if _puff.contains(player.global_position) and not player.combat.is_dashing():
				player.chill(Tuning.kl_ashbrood_puff_warmth)
				player.lamp_charge = minf(player.lamp_charge, Tuning.kl_ashbrood_puff_charge)
			Telegraph.play_slot("ashbrood_puff", "release")
			_puff.finish()
			_puff = null
			_ash_t = 0.4
			_puff_t = Tuning.kl_ashbrood_puff_period
	else:
		_puff_t -= delta
		if _puff_t <= 0.0:
			_puff = Telegraph.begin(self, Telegraph.CIRCLE, "ashbrood_puff", Tuning.kl_ashbrood_puff_tell)
			_puff.boss = true
			_puff.radius = Tuning.kl_ashbrood_puff_radius
			Telegraph.arm(_puff, get_tree())
	if _adds:
		_adds.tick(delta)
		if _adds.done():
			for p in _adds.points:
				var w := Wickling.new()
				w.bold = true
				w.summoned = true
				w.level = Tuning.kl_ashbrood_add_level
				w.position = p
				w.fade_in()
				get_parent().add_child(w)
			_adds.finish()
			_adds = null
	else:
		_wave_t -= delta
		if _wave_t <= 0.0:
			_wave_t = Tuning.kl_ashbrood_wave_period
			_adds = Telegraph.begin(self, Telegraph.SPAWN, "ashbrood_adds", Tuning.kl_ashbrood_add_tell, false)
			_adds.radius = 14.0
			for i in Tuning.kl_ashbrood_wave_count:
				_adds.points.append(global_position + Vector2.from_angle(i * TAU / 3.0) * 52.0)
			Telegraph.arm(_adds, get_tree())

func _process_dive(delta: float, player: Node2D) -> void:
	if _fly_t > 0.0:
		_fly_t = maxf(0.0, _fly_t - delta)
		var k := 1.0 - _fly_t / maxf(Tuning.kl_ashbrood_dive_travel, 0.01)
		global_position = _fly_from.lerp(_dive.center, k)
		if _fly_t <= 0.0:
			_land(player)
		return
	if _sit_t > 0.0:
		_sit_t = maxf(0.0, _sit_t - delta)
		return
	if _dive:
		_dive.tick(delta)
		if is_instance_valid(_target_lamp):
			_target_lamp.threatened = 0.2   # the lamp flickers while the dive winds up
		if _dive.done():
			_fly_from = global_position
			_fly_t = maxf(Tuning.kl_ashbrood_dive_travel, 0.01)
		return
	_dive_t -= delta
	if _dive_t <= 0.0:
		_target_lamp = _nearest_lit_lamp()
		var land: Vector2
		if _target_lamp:
			land = _target_lamp.global_position + Vector2(0, -12)
			_roll_dir = (land - global_position).normalized()
		else:
			_roll_dir = (player.global_position - global_position).normalized()
			land = global_position + _roll_dir * Tuning.kl_ashbrood_dive_dist
		_dive = Telegraph.begin(self, Telegraph.CIRCLE, "ashbrood_dive", Tuning.kl_ashbrood_dive_tell)
		_dive.boss = true
		_dive.center = land
		_dive.radius = Tuning.kl_ashbrood_hit_radius
		Telegraph.arm(_dive, get_tree())

## The dive lands: the lamp under it is snuffed for a while, and the landing circle chills a keeper who isn't
## dashing.
func _land(player: Node2D) -> void:
	global_position = _dive.center
	if is_instance_valid(_target_lamp):
		_target_lamp.snuff(Tuning.kl_snuff_sec)
	if _dive.contains(player.global_position) and not player.combat.is_dashing():
		player.chill(Tuning.kl_ashbrood_dive_warmth)
	Telegraph.play_slot("ashbrood_dive", "impact")
	_dive.finish()
	_dive = null
	_ash_t = 0.3
	_sit_t = Tuning.kl_ashbrood_sit_sec
	_dive_t = Tuning.kl_ashbrood_dive_period

func _nearest_lit_lamp() -> Lantern:
	var best: Lantern = null
	var best_d := INF
	for lamp in get_tree().get_nodes_in_group("lantern"):
		if not lamp.is_lit() or lamp.kind == "mirror":
			continue
		var d := global_position.distance_to(lamp.global_position)
		if d < best_d:
			best = lamp
			best_d = d
	return best

func body_radius() -> float:
	return 32.0

## Health and shell at the start of a phase, grown by its level.
func phase_hp() -> float:
	return Tuning.kl_ashbrood_hp * level_mult()

func phase_shell() -> float:
	return Tuning.kl_ashbrood_shell * level_mult()

## The faint rule (GAME_PLAN §12): back to the start of the phase it reached, shell regrown, its timers and
## wind-ups reset, its oil step armed again (the phase's oil drops again on each try), back over its bowl.
## Its adds are cleared by the keeper's faint (summoned foes go).
func restart_phase() -> void:
	if _dead or is_queued_for_deletion():
		return
	hp = phase_hp()
	hp_max = hp
	shell = phase_shell()
	shell_max = shell
	_since_beam = 0.0
	_oil_step_given = false
	_ignite_t = 0.0
	_linger_t = 0.0
	for t in [_puff, _adds, _dive]:
		if t:
			t.finish()
	_puff = null
	_adds = null
	_dive = null
	_fly_t = 0.0
	_sit_t = 0.0
	_phase_t = 0.0
	_puff_t = 2.0 if phase == 1 else 99.0
	_wave_t = 3.0
	_dive_t = 2.0
	if waylamp:
		global_position = waylamp.global_position

func _die() -> void:
	if phase == 1:
		phase = 2
		hp = phase_hp()
		hp_max = hp
		shell = phase_shell()
		shell_max = shell
		_since_beam = 0.0
		_oil_step_given = false   # the next phase drops its own oil at its half
		_puff_t = 99.0
		_dive_t = 2.0
		for t in [_puff, _adds]:
			if t:
				t.finish()
		_puff = null
		_adds = null
		_phase_t = Tuning.kl_ashbrood_phase_pause   # it rises out of the bowl: no attacks, no damage
		Telegraph.play_slot("ashbrood_phase", "windup")
		Sfx.play("unlock", -4.0)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud._show_toast("The Ashbrood leaves the bowl.", 3.0)
		return
	if waylamp:
		waylamp.take_back_ember()   # the ember rises into the lamp as it lights (DECISIONS 2026-11-27)
		Progress.settle(waylamp.region_id, FogGrid.REGION_NAMES[waylamp.region_id])
	super._die()

func _draw() -> void:
	var color := Color(0.22, 0.28, 0.37) if phase == 1 else Color(0.28, 0.33, 0.42)
	var lift := 0.0
	var squash := 1.0
	var eye_a := 0.9
	var eye_y := -7.0
	if _phase_t > 0.0:
		# Rising out of the bowl: it lifts and swells, wings spread.
		var k := 1.0 - _phase_t / maxf(Tuning.kl_ashbrood_phase_pause, 0.01)
		lift = -sin(k * PI) * 14.0
		squash = 1.0 + 0.12 * sin(k * PI)
	elif _sit_t > 0.0:
		squash = 0.85   # slumped, eyes dim: hit it now
		eye_a = 0.35
		eye_y = -3.0
	elif _puff:
		squash = 1.0 + 0.15 * _puff.progress()   # it inhales
	elif _dive:
		squash = 1.0 - 0.12 * _dive.progress()   # it crouches, wings back
	if _adds:
		eye_y = -11.0   # head up: calling its brood
	draw_set_transform(Vector2(0, lift), 0.0, Vector2(squash, 2.0 - squash))
	draw_colored_polygon(PackedVector2Array([Vector2(-29, 15), Vector2(-27, -4), Vector2(-17, -20), Vector2(0, -27), Vector2(19, -20), Vector2(29, -3), Vector2(25, 16), Vector2(9, 25), Vector2(-14, 22)]), color)
	draw_circle(Vector2(-10, eye_y), 4.0, Color(0.74, 0.86, 0.97, eye_a))
	draw_circle(Vector2(10, eye_y), 4.0, Color(0.74, 0.86, 0.97, eye_a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _sit_t <= 0.0:
		draw_shell(Vector2.ZERO, 38.0)
	elif shell > 0.0:
		draw_arc(Vector2.ZERO, 38.0, 0.0, TAU, 28, Color(0.64, 0.74, 0.83, 0.25), 2.0)   # its shell glow lower
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 32, Color(1.0, 0.72, 0.4, 0.9), 3.0)
	# The dive's path to its landing circle (the circle itself is the Telegraph marker).
	if _dive and _fly_t <= 0.0:
		var to := to_local(_dive.center)
		var len := to.length()
		var d := to / maxf(len, 0.001)
		var s := 40.0
		while s < len - Tuning.kl_ashbrood_hit_radius:
			draw_line(d * s, d * minf(s + 12.0, len), Color(Telegraph.COLD, 0.55), 2.0)
			s += 22.0
	# The flight: an ash streak behind it.
	if _fly_t > 0.0:
		var back := to_local(_fly_from).limit_length(90.0)
		draw_line(Vector2.ZERO, back, Color(0.4, 0.48, 0.6, 0.5), 18.0)
		draw_line(Vector2.ZERO, back * 0.6, Color(0.6, 0.7, 0.82, 0.6), 8.0)
	# The ash ring a puff or a landing leaves.
	if _ash_t > 0.0:
		var k := 1.0 - _ash_t / 0.4
		var r := (Tuning.kl_ashbrood_puff_radius if phase == 1 else Tuning.kl_ashbrood_hit_radius) * (0.7 + 0.3 * k)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(0.55, 0.62, 0.72, 0.6 * (1.0 - k)), 6.0)
	draw_arc(Vector2(0, 38), 10.0, -PI / 2.0, -PI / 2.0 + TAU * float(phase) / 2.0, 20, Color(0.75, 0.84, 0.96, 0.8), 3.0)
