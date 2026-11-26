class_name Wickling
extends Node2D
## PROTOTYPE. A small shadow from the Soul of the Wick. It drifts out of the fog,
## creeps to the rim of a lantern's light and drains its fuel, or chills the keeper
## if they wander into the dark. Light is its enemy: the bright core of a lantern
## burns it, and the keeper's flare destroys it. It never kills anyone.
## Lives on the fog layer so it is visible as a silhouette in the dark.

enum State { WANDER, SEEK_LANTERN, SNUFF, CHASE, FLEE }

var state := State.WANDER
var hp := 0.0
var target: Node2D = null
var _flee_t := 0.0
var _wander_to := Vector2.ZERO
var _t := 0.0
var _burning := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("wickling")
	z_index = 7
	hp = Tuning.wick_hp
	rng.randomize()
	_t = rng.randf() * 10.0
	_pick_wander()

# --- Senses ------------------------------------------------------------------

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

## 0 outside any lantern light, up to 1 at a lantern's centre.
func light_level_at(p: Vector2) -> float:
	var best := 0.0
	for l in get_tree().get_nodes_in_group("lantern"):
		var r: float = l.get_light_radius()
		if r <= 0.0:
			continue
		best = maxf(best, 1.0 - l.global_position.distance_to(p) / r)
	return best

func _nearest_lit_lantern(max_dist: float) -> Node2D:
	var best: Node2D = null
	var bd := max_dist
	for l in get_tree().get_nodes_in_group("lantern"):
		if not l.is_lit():
			continue
		var d: float = l.global_position.distance_to(global_position)
		if d < bd:
			best = l
			bd = d
	return best

# --- Damage --------------------------------------------------------------------

func hurt(amount: float, scare: bool = true) -> void:
	hp -= amount
	_burning = 0.3
	if scare:
		state = State.FLEE
		_flee_t = 2.0
	if hp <= 0.0:
		Sfx.play("relight", -14.0, 0.2)
		queue_free()

# --- Brain -------------------------------------------------------------------

func _pick_wander() -> void:
	_wander_to = global_position + Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120))

func _process(delta: float) -> void:
	_t += delta
	_burning = maxf(0.0, _burning - delta)
	var here := light_level_at(global_position)
	# The bright core of a lantern burns it.
	if here > Tuning.wick_core:
		hp -= Tuning.wick_light_burn * delta
		_burning = 0.2
		if hp <= 0.0:
			queue_free()
			return
	var player := _player()
	var speed := Tuning.wick_speed
	var goal := global_position
	match state:
		State.FLEE:
			_flee_t -= delta
			# Away from the light / the keeper.
			var away := (global_position - (player.global_position if player else global_position)).normalized()
			goal = global_position + away * 100.0
			speed *= 1.6
			if _flee_t <= 0.0:
				state = State.WANDER
		State.CHASE:
			if player == null or player.in_lantern_light() or player.global_position.distance_to(global_position) > Tuning.wick_sense * 1.4:
				state = State.WANDER
			else:
				goal = player.global_position
				if player.global_position.distance_to(global_position) < 22.0:
					player.chill(Tuning.warmth_drain_per_sec * delta)
		State.SEEK_LANTERN, State.SNUFF:
			if target == null or not is_instance_valid(target) or not target.is_lit():
				target = null
				state = State.WANDER
			else:
				var to := target.global_position - global_position
				# Stop at the rim, where the light is still weak enough to bear.
				if here >= Tuning.wick_rim:
					state = State.SNUFF
					target.fuel = maxf(0.0, target.fuel - Tuning.wick_drain_per_sec * delta)
					goal = global_position
				else:
					state = State.SEEK_LANTERN
					goal = target.global_position
				if to.length() < 1.0:
					goal = global_position
		_:
			if (_wander_to - global_position).length() < 8.0 or int(_t * 10) % 40 == 0:
				_pick_wander()
			goal = _wander_to
			speed *= 0.5
			# Look for prey.
			if player and not player.in_lantern_light() and player.global_position.distance_to(global_position) < Tuning.wick_sense:
				state = State.CHASE
			else:
				var l := _nearest_lit_lantern(Tuning.wick_sense * 1.5)
				if l:
					target = l
					state = State.SEEK_LANTERN
	var step := (goal - global_position).limit_length(speed * delta)
	# Never walk into the bright core on purpose.
	if state != State.FLEE and light_level_at(global_position + step) > Tuning.wick_core and here <= Tuning.wick_core:
		step = Vector2.ZERO
	global_position += step
	queue_redraw()

func _draw() -> void:
	var wob := sin(_t * 5.0) * 1.5
	var body := Color(0.03, 0.035, 0.06, 0.92)
	# Smoky body: a few overlapping blobs.
	draw_circle(Vector2(0, wob), 10.0, body)
	draw_circle(Vector2(-6, 6 + wob * 0.5), 6.0, body)
	draw_circle(Vector2(6, 7 - wob * 0.5), 5.0, body)
	draw_circle(Vector2(sin(_t * 3.0) * 3.0, 14), 3.5, Color(body, 0.6))
	if _burning > 0.0:
		draw_arc(Vector2(0, wob), 11.0, 0.0, TAU, 20, Color(1.0, 0.65, 0.3, 0.9), 1.5)
	# A faint cold rim so they read against dark fog.
	draw_arc(Vector2(0, wob), 11.5, 0.0, TAU, 24, Color(0.55, 0.68, 0.85, 0.35 + 0.15 * sin(_t * 4.0)), 1.0)
	# Pale eyes (brighter when hunting you).
	var eye := Color(0.75, 0.84, 0.92) if state != State.CHASE else Color(1.0, 1.0, 1.0)
	draw_rect(Rect2(-6, -4 + wob, 4, 4), eye)
	draw_rect(Rect2(2, -4 + wob, 4, 4), eye)
	# Health shows as how solid it looks once hurt.
	if hp < Tuning.wick_hp:
		draw_arc(Vector2(0, wob), 14.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(hp / Tuning.wick_hp, 0.0, 1.0), 20, Color(1.0, 0.7, 0.35, 0.8), 2.0)
	# A thin tendril to the lantern it is draining.
	if state == State.SNUFF and target and is_instance_valid(target):
		draw_line(Vector2.ZERO, to_local(target.global_position + Vector2(0, -34)), Color(0.05, 0.06, 0.1, 0.7), 2.0)
