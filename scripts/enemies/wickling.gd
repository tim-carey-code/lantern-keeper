class_name Wickling
extends Foe
## A small shadow from the Soul of the Wick. It never kills anyone.
## Healthy light pushes it back into the dark (PROTOTYPE, WayLamps). It goes after what is weak:
##   - a dying lantern (under Tuning.dying_frac of its tank) that no healthy light protects: it drains it
##   - a mirror out in the dark: it clings to it and smothers it (drinking any beam that reaches it)
##   - a WayLamp while it kindles: it sits on it and undoes the kindling
##   - the keeper, when they wander into the dark: its touch drains warmth
## A lantern's bright core and mirror beams burn it; so does the keeper's ward.
## "Bold" Wicklings (the swarm drawn by a kindling WayLamp) ignore the push of healthy light.
## Inside a held region (its WayLamp lit) it fades away.
## Lives on the fog layer so it is visible as a silhouette in the dark.

enum State { WANDER, SEEK_LANTERN, SNUFF, CHASE, FLEE }

var state := State.WANDER
var target: Node2D = null
var bold := false
var elite := false              # PROTOTYPE: a bigger, shelled Wickling (hp, shell and the rest live in Foe)
var _flee_t := 0.0
var _wander_to := Vector2.ZERO
var _t := 0.0
var rng := RandomNumberGenerator.new()

var timid := true                # afraid of lantern light (about half are); the rest walk in but burn there
var _in_light := 0.0             # seconds a brave one has stood in healthy light

func _ready() -> void:
	foe_name = "Shelled Wickling" if elite else "Wickling"
	timid = not elite and randf() < Tuning.kl_timid_share
	add_to_group("wickling")
	add_to_group("foe")
	z_index = 7
	hp = Tuning.kl_elite_hp if elite else Tuning.wick_hp
	wick_value = Tuning.kl_elite_wick if elite else Tuning.kl_wickling_wick
	if elite:
		shell = Tuning.kl_elite_shell
		shell_max = shell
		knock_weight = 0.5
	rng.randomize()
	_t = rng.randf() * 10.0
	_pick_wander()

# --- Senses (the light senses are in Foe) --------------------------------------

## What it would go after, nearest first: kindling WayLamps, unprotected dying lanterns,
## mirrors out in the dark.
func _find_prey(max_dist: float) -> Node2D:
	var best: Node2D = null
	var bd := max_dist
	for w in get_tree().get_nodes_in_group("waylamp"):
		var d: float = w.global_position.distance_to(global_position)
		if w.kindling and d < bd:
			best = w
			bd = d
	LightSense.refresh(get_tree())
	for i in LightSense.nodes.size():   # dying lanterns (the snapshot has every non-mirror lantern)
		var d := LightSense.pos[i].distance_to(global_position)
		if d < bd and LightSense.dying[i] == 1 and healthy_level_at(LightSense.pos[i], LightSense.nodes[i]) <= 0.0:
			best = LightSense.nodes[i]
			bd = d
	for l in get_tree().get_nodes_in_group("mirror"):
		var d: float = l.global_position.distance_to(global_position)
		if d < bd and l.is_in_group("lantern") and l.is_lit() and healthy_level_at(l.global_position) <= 0.0:
			best = l
			bd = d
	return best

# --- Damage --------------------------------------------------------------------

func body_radius() -> float:
	return 16.0 if elite else 10.0

## A hit scares a small one off for a moment (the hit itself is in Foe.hurt).
func _on_hurt(scare: bool, _source: String) -> void:
	if scare and not elite:
		state = State.FLEE
		_flee_t = 2.0

## Shoved by the keeper's ward.
func push(v: Vector2) -> void:
	global_position += v

# --- Brain -------------------------------------------------------------------

func _pick_wander() -> void:
	_wander_to = global_position + Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120))

func _process(delta: float) -> void:
	_t += delta
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	# A held region is no place for it: it fades away (no drops).
	if fade_if_held(delta):
		return
	var here := lantern_level_at(global_position)
	# A Wickling clinging to a mirror can drink its beam instead of being burned by it.
	var smothering: bool = state == State.SNUFF and target != null and is_instance_valid(target) and target is Lantern and target.kind == "mirror"
	if beam_level_at(global_position) > 0.0 and not smothering:
		hurt(Tuning.wick_beam_burn * delta, false, "beam")
		if is_queued_for_deletion():
			return
	var player := _player()
	var speed := (Tuning.kl_elite_speed if elite else Tuning.wick_speed) * (1.25 if bold else 1.0)
	var goal := global_position
	# A bold Wickling goes back to normal once its WayLamp is no longer kindling.
	if bold and (target == null or not is_instance_valid(target) or not (target is WayLamp) or not target.kindling):
		bold = false
	match state:
		State.FLEE:
			_flee_t -= delta
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
				if player.global_position.distance_to(global_position) < 12.0 + body_radius():
					var lee := Tuning.kl_lee_mult if Progress.has_combat_upgrade("lee") else 1.0
					player.chill(Tuning.warmth_drain_per_sec * (Tuning.kl_elite_chill_mult if elite else 1.0) * lee * delta)
		State.SEEK_LANTERN, State.SNUFF when target != null and is_instance_valid(target) and target is WayLamp:
			# A kindling WayLamp: sit on it and drink the new flame.
			if not target.kindling:
				target = null
				state = State.WANDER
			elif target.global_position.distance_to(global_position) < 30.0:
				state = State.SNUFF
				target.sap(Tuning.waylamp_sap_per_wick * delta)
				goal = target.global_position
			else:
				state = State.SEEK_LANTERN
				goal = target.global_position
		State.SEEK_LANTERN, State.SNUFF when target != null and is_instance_valid(target) and target is Lantern and target.kind == "mirror":
			# Mirrors have no fuel: cling to one and smother it until burned off.
			var dist := target.global_position.distance_to(global_position)
			if dist < 16.0:
				state = State.SNUFF
				target.smother()
				goal = target.global_position
			else:
				state = State.SEEK_LANTERN
				goal = target.global_position
		State.SEEK_LANTERN, State.SNUFF:
			# A dying lantern: drain it from the rim. Once it is healthy again (refuelled), or a healthy
			# light now covers it, leave it.
			if target == null or not is_instance_valid(target) or not target.is_lit() or not target.is_dying() \
					or healthy_level_at(target.global_position, target) > 0.0:
				target = null
				state = State.WANDER
			else:
				var to := target.global_position - global_position
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
				var prey := _find_prey(Tuning.wick_sense * 1.5)
				if prey:
					target = prey
					state = State.SEEK_LANTERN
	var step := (goal - global_position).limit_length(speed * delta)
	if is_stunned():
		step = Vector2.ZERO
	elif not bold and not elite and state != State.FLEE:
		if timid:
			step = step_outside_light(step, delta)   # pushed back out of healthy light, or hovering at its edge
		elif healthy_level_at(global_position) > 0.0:
			# A brave one walks into the light, but it can't stay: after a while it burns and runs.
			_in_light += delta
			if _in_light >= Tuning.kl_light_tolerance:
				hurt(Tuning.kl_light_burn_dps * delta, false, "light")
				state = State.FLEE
				_flee_t = 1.5
		else:
			_in_light = maxf(0.0, _in_light - delta)
	global_position += step
	queue_redraw()

func _draw() -> void:
	if elite:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.6, 1.6))
	var wob := sin(_t * 5.0) * 1.5
	var body := Color(0.03, 0.035, 0.06, 0.92)
	# Smoky body: a few overlapping blobs.
	draw_circle(Vector2(0, wob), 10.0, body)
	draw_circle(Vector2(-6, 6 + wob * 0.5), 6.0, body)
	draw_circle(Vector2(6, 7 - wob * 0.5), 5.0, body)
	draw_circle(Vector2(sin(_t * 3.0) * 3.0, 14), 3.5, Color(body, 0.6))
	if _burning > 0.0:
		draw_arc(Vector2(0, wob), 11.0, 0.0, TAU, 20, Color(1.0, 0.65, 0.3, 0.9), 1.5)
	# A faint rim so they read against dark fog (reddish for the bold swarm).
	var rim := Color(0.9, 0.45, 0.4) if bold else Color(0.55, 0.68, 0.85)
	draw_arc(Vector2(0, wob), 11.5, 0.0, TAU, 24, Color(rim, 0.35 + 0.15 * sin(_t * 4.0)), 1.0)
	# Pale eyes (brighter when hunting you).
	var eye := Color(0.75, 0.84, 0.92) if state != State.CHASE else Color(1.0, 1.0, 1.0)
	draw_rect(Rect2(-6, -4 + wob, 4, 4), eye)
	draw_rect(Rect2(2, -4 + wob, 4, 4), eye)
	# Health shows as how solid it looks once hurt.
	if hp < Tuning.wick_hp:
		draw_arc(Vector2(0, wob), 14.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(hp / Tuning.wick_hp, 0.0, 1.0), 20, Color(1.0, 0.7, 0.35, 0.8), 2.0)
	# A thin tendril to what it is draining.
	if state == State.SNUFF and target and is_instance_valid(target):
		var lamp_y := -60.0 if target is WayLamp else -34.0
		draw_line(Vector2.ZERO, to_local(target.global_position + Vector2(0, lamp_y)), Color(0.05, 0.06, 0.1, 0.7), 2.0)
	if elite:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_shell(Vector2(0, -2), 22.0)   # a pale, cracked shell; it thins as the beam wears it down
