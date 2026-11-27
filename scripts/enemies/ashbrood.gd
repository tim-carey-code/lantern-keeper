class_name Ashbrood
extends Foe
## The Hollow's WayLamp guardian. A two-phase fight: the bowl, then the planted lamps.

var waylamp: WayLamp
var phase := 1
var _puff_t := 2.0
var _puff_tell := 0.0
var _wave_t := 3.0
var _dive_t := 2.0
var _dive_tell := 0.0
var _sit_t := 0.0
var _target_lamp: Lantern
var _pulse := 0.0

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

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	_pulse += delta
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
	_puff_t -= delta
	if _puff_tell > 0.0:
		_puff_tell -= delta
		if _puff_tell <= 0.0:
			if player.global_position.distance_to(global_position) <= Tuning.kl_ashbrood_puff_radius:
				player.chill(Tuning.kl_ashbrood_puff_warmth)
				player.lamp_charge = minf(player.lamp_charge, Tuning.kl_ashbrood_puff_charge)
			_puff_t = Tuning.kl_ashbrood_puff_period
	elif _puff_t <= 0.0:
		_puff_tell = Tuning.kl_ashbrood_puff_tell
	_wave_t -= delta
	if _wave_t <= 0.0:
		_wave_t = Tuning.kl_ashbrood_wave_period
		for i in Tuning.kl_ashbrood_wave_count:
			var w := Wickling.new()
			w.bold = true
			w.summoned = true
			w.level = Tuning.kl_ashbrood_add_level
			w.position = global_position + Vector2.from_angle(i * TAU / 3.0) * 52.0
			get_parent().add_child(w)

func _process_dive(delta: float, player: Node2D) -> void:
	if _sit_t > 0.0:
		_sit_t = maxf(0.0, _sit_t - delta)
		return
	if _dive_tell > 0.0:
		_dive_tell -= delta
		if _dive_tell <= 0.0:
			_do_dive(player)
		return
	_dive_t -= delta
	if _dive_t <= 0.0:
		_target_lamp = _nearest_lit_lamp()
		_dive_tell = Tuning.kl_ashbrood_dive_tell
		if _target_lamp:
			_roll_dir = (_target_lamp.global_position - global_position).normalized()
		else:
			_roll_dir = (player.global_position - global_position).normalized()

var _roll_dir := Vector2.RIGHT

func _nearest_lit_lamp() -> Lantern:
	var p := _player()
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

func _do_dive(player: Node2D) -> void:
	if is_instance_valid(_target_lamp):
		global_position = _target_lamp.global_position + Vector2(0, -12)
		_target_lamp.fuel = 0.0
		_sit_t = Tuning.kl_ashbrood_sit_sec
		if player.global_position.distance_to(global_position) < Tuning.kl_ashbrood_roll_radius:
			player.chill(Tuning.kl_ashbrood_dive_warmth)
	else:
		global_position += _roll_dir * Tuning.kl_ashbrood_dive_dist
		if player.global_position.distance_to(global_position) < Tuning.kl_ashbrood_hit_radius:
			player.chill(Tuning.kl_ashbrood_dive_warmth)
		_sit_t = Tuning.kl_ashbrood_sit_sec
	_dive_t = Tuning.kl_ashbrood_dive_period

func body_radius() -> float:
	return 32.0

func _die() -> void:
	if phase == 1:
		phase = 2
		hp = Tuning.kl_ashbrood_hp
		hp_max = hp
		shell = Tuning.kl_ashbrood_shell
		shell_max = shell
		_since_beam = 0.0
		_oil_step_given = false   # the next phase drops its own oil at its half
		_puff_t = 99.0
		_dive_t = 2.0
		Sfx.play("unlock", -4.0)
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud._show_toast("The Ashbrood leaves the bowl.", 3.0)
		return
	if waylamp:
		Progress.settle(waylamp.region_id, FogGrid.REGION_NAMES[waylamp.region_id])
	super._die()

func _draw() -> void:
	var color := Color(0.22, 0.28, 0.37) if phase == 1 else Color(0.28, 0.33, 0.42)
	draw_colored_polygon(PackedVector2Array([Vector2(-29, 15), Vector2(-27, -4), Vector2(-17, -20), Vector2(0, -27), Vector2(19, -20), Vector2(29, -3), Vector2(25, 16), Vector2(9, 25), Vector2(-14, 22)]), color)
	draw_circle(Vector2(-10, -7), 4.0, Color(0.74, 0.86, 0.97, 0.9))
	draw_circle(Vector2(10, -7), 4.0, Color(0.74, 0.86, 0.97, 0.9))
	draw_shell(Vector2.ZERO, 38.0)
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 32, Color(1.0, 0.72, 0.4, 0.9), 3.0)
	if _puff_tell > 0.0:
		var k := 1.0 - _puff_tell / Tuning.kl_ashbrood_puff_tell
		draw_arc(Vector2.ZERO, Tuning.kl_ashbrood_puff_radius * k, 0, TAU, 48, Color(0.68, 0.82, 0.94, 0.75 * (1.0 - k)), 3.0)
	if _dive_tell > 0.0:
		draw_line(Vector2.ZERO, _roll_dir * 240.0, Color(0.66, 0.8, 0.94, 0.6), 4.0)
	draw_arc(Vector2(0, 38), 10.0, -PI / 2.0, -PI / 2.0 + TAU * float(phase) / 2.0, 20, Color(0.75, 0.84, 0.96, 0.8), 3.0)
