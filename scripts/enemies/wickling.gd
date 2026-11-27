class_name Wickling
extends Node2D
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
var hp := 0.0
var target: Node2D = null
var bold := false
var elite := false              # PROTOTYPE: a bigger, shelled Wickling
var shell := 0.0                # only a beam (the keeper's or a mirror's) wears it down
var _knock_v := Vector2.ZERO
var _knock_t := 0.0
var _clink := 0.0               # > 0: something just glanced off the shell
var _flee_t := 0.0
var _wander_to := Vector2.ZERO
var _t := 0.0
var _burning := 0.0
var _fading := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("wickling")
	z_index = 7
	hp = Tuning.kl_elite_hp if elite else Tuning.wick_hp
	if elite:
		shell = Tuning.kl_elite_shell
	rng.randomize()
	_t = rng.randf() * 10.0
	_pick_wander()

# --- Senses ------------------------------------------------------------------

func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

## 0 outside any lantern light, up to 1 at a lantern's centre (mirror glows don't count).
func lantern_level_at(p: Vector2) -> float:
	var best := 0.0
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.kind == "mirror":
			continue
		var r: float = l.get_light_radius()
		if r <= 0.0:
			continue
		best = maxf(best, 1.0 - l.global_position.distance_to(p) / r)
	return best

## Lights strong enough to push a Wickling back: burning lanterns that aren't dying, and lit WayLamps.
func _healthy_lights() -> Array:
	var out := []
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.kind != "mirror" and l.is_lit() and not l.is_dying():
			out.append(l)
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.is_lit():
			out.append(w)
	return out

## How deep a point sits in healthy light (0 outside). Optionally ignoring one light.
func healthy_level_at(p: Vector2, ignore: Node = null) -> float:
	var best := 0.0
	for l in _healthy_lights():
		if l == ignore:
			continue
		var r: float = l.get_light_radius()
		if r > 0.0:
			best = maxf(best, 1.0 - l.global_position.distance_to(p) / r)
	return best

## The way out of healthy light from a point (zero when outside it).
func repel_at(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for l in _healthy_lights():
		var r: float = l.get_light_radius()
		if r <= 0.0:
			continue
		var v: Vector2 = p - l.global_position
		var d := v.length()
		if d < r:
			push += (v / maxf(d, 0.001)) * (1.0 - d / r + 0.2)
	return push

## How deep a point sits in any mirror beam (0 outside). Wicklings can't sense beams coming.
func beam_level_at(p: Vector2) -> float:
	var best := 0.0
	for m in get_tree().get_nodes_in_group("mirror"):
		best = maxf(best, m.beam_level_at(p))
	return best

## Overall light at a point: lantern light, or a beam (which counts as harsh as a core).
func light_level_at(p: Vector2) -> float:
	return maxf(lantern_level_at(p), beam_level_at(p) * 0.8)

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
	for l in get_tree().get_nodes_in_group("lantern"):
		var d: float = l.global_position.distance_to(global_position)
		if d >= bd:
			continue
		if l.kind == "mirror":
			if l.is_lit() and healthy_level_at(l.global_position) <= 0.0:
				best = l
				bd = d
		elif l.is_dying() and healthy_level_at(l.global_position, l) <= 0.0:
			best = l
			bd = d
	return best

# --- Damage --------------------------------------------------------------------

func body_radius() -> float:
	return 16.0 if elite else 10.0

## Damage from a source: "beam" (the keeper's beam or a mirror beam), "burst", "core", "ward" or "".
## A shell takes beam damage first and turns everything else aside.
func hurt(amount: float, scare: bool = true, source: String = "") -> void:
	if shell > 0.0:
		if source != "beam":
			_clink = 0.2
			return
		shell -= amount
		_burning = 0.3
		if shell > 0.0:
			return
		amount = -shell
		shell = 0.0
		Sfx.play("ui_tick", -6.0, 0.5)   # the shell cracks
	hp -= amount
	_burning = 0.3
	if scare and not elite:
		state = State.FLEE
		_flee_t = 2.0
	if hp <= 0.0:
		_die()

## Thrown back (by the burst): moves over a short moment instead of teleporting.
func knock(v: Vector2) -> void:
	var weight := 0.5 if elite else 1.0
	_knock_v = v * weight / 0.2
	_knock_t = 0.2

## Burned away: leave an ember worth a little fuel.
func _die() -> void:
	if is_queued_for_deletion():
		return
	Sfx.play("relight", -14.0, 0.2)
	# Drops land on the fog layer (our parent) so they glow through the dark.
	var e := Ember.new()
	e.position = global_position
	get_parent().add_child(e)
	if randf() < Tuning.wick_scrap_chance:
		var s := Ember.new()
		s.kind = "scrap"
		s.position = global_position + Vector2(14, 6)
		get_parent().add_child(s)
	queue_free()

## Shoved by the keeper's ward.
func push(v: Vector2) -> void:
	global_position += v

# --- Brain -------------------------------------------------------------------

func _pick_wander() -> void:
	_wander_to = global_position + Vector2(rng.randf_range(-120, 120), rng.randf_range(-120, 120))

func _process(delta: float) -> void:
	_t += delta
	_burning = maxf(0.0, _burning - delta)
	# A held region is no place for it: it fades away (no drops).
	var fog := _fog()
	if fog and Progress.is_settled(fog.region_at(global_position)):
		_fading += delta
		modulate.a = clampf(1.0 - _fading / 1.2, 0.0, 1.0)
		if _fading >= 1.2:
			queue_free()
		return
	var here := lantern_level_at(global_position)
	# The bright core of a lantern burns it; a mirror beam burns it fast.
	var burn := 0.0
	if here > Tuning.wick_core:
		burn += Tuning.wick_light_burn
	var smothering: bool = state == State.SNUFF and target != null and is_instance_valid(target) and target is Lantern and target.kind == "mirror"
	if beam_level_at(global_position) > 0.0 and not smothering:
		burn += Tuning.wick_beam_burn   # (one clinging to a mirror drinks the beam instead)
	if burn > 0.0:
		var beam_part := burn - (Tuning.wick_light_burn if here > Tuning.wick_core else 0.0)
		var core_part := burn - beam_part
		if beam_part > 0.0:
			hurt(beam_part * delta, false, "beam")
		if core_part > 0.0:
			hurt(core_part * delta, false, "core")
		if not is_instance_valid(self) or is_queued_for_deletion():
			return
	_clink = maxf(0.0, _clink - delta)
	if _knock_t > 0.0:
		_knock_t -= delta
		global_position += _knock_v * delta
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
					player.chill(Tuning.warmth_drain_per_sec * (Tuning.kl_elite_chill_mult if elite else 1.0) * delta)
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
	if not bold and state != State.FLEE:
		if healthy_level_at(global_position) > 0.0:
			# Pushed back out of healthy light, into the dark.
			step = repel_at(global_position).normalized() * Tuning.wick_repel_speed * delta
		elif healthy_level_at(global_position + step) > 0.0:
			step = Vector2.ZERO   # hover at the edge of the light
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
		if shell > 0.0:
			# A pale, cracked shell around it; it thins as the beam wears it down.
			var k := clampf(shell / Tuning.kl_elite_shell, 0.0, 1.0)
			draw_arc(Vector2(0, -2), 22.0, 0.0, TAU, 28, Color(0.64, 0.74, 0.83, 0.35 + 0.5 * k), 2.0 + 3.0 * k)
		if _clink > 0.0:
			draw_arc(Vector2(0, -2), 25.0, -0.6, 0.6, 8, Color(1, 1, 1, _clink * 4.0), 2.0)
