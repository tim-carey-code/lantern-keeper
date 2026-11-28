class_name Wickling
extends Foe
## A small shadow from the Soul of the Wick. It never kills anyone.
## Healthy light pushes it back into the dark (PROTOTYPE, WayLamps). It goes after what is weak:
##   - a mirror out in the dark: it clings to it and smothers it (drinking any beam that reaches it)
##   - a WayLamp while it kindles: it sits on it and undoes the kindling
##   - the keeper, when they wander into the dark: its touch drains warmth
## A lantern's bright core and mirror beams burn it. (M1b: lamps never die, so it no longer drains them.)
## "Bold" Wicklings (the swarm drawn by a kindling WayLamp) ignore the push of healthy light.
## Inside a held region (its WayLamp lit) it fades away.
## Lives on the fog layer so it is visible as a silhouette in the dark.
## Readability step (ART_DIRECTION §4.3 rows 1-3): its eyes flare for kl_notice_time when it starts hunting you;
## on reaching you it stretches two tendrils for kl_wick_latch_tell (kl_elite_latch_tell for an elite) before
## the drain starts, and the keeper shows a frost edge while it drains. Hatched and called ones fade in
## (kl_hatch_fade) and can't touch you meanwhile. The bold swarm's rim is the cold #a3bcd4, with a faster wobble.

enum State { WANDER, SEEK_LANTERN, SNUFF, CHASE, FLEE }

var state := State.WANDER
var target: Node2D = null
var bold := false
var elite := false              # PROTOTYPE: a bigger, shelled Wickling (hp, shell and the rest live in Foe)
var _flee_t := 0.0
var waiting_for_keeper := false   # it was chasing the keeper, who stepped into light: it waits at the edge (counts as hunting, Hunt)
var _wander_to := Vector2.ZERO
var _t := 0.0
var rng := RandomNumberGenerator.new()

var timid := true                # afraid of lantern light (about half are); the rest walk in but burn there
var _in_light := 0.0             # seconds a brave one has stood in healthy light
var _latch: Telegraph.Tell       # reaching for the keeper (before the drain)
var latched := false             # its touch is draining the keeper
var _notice_t := 0.0             # > 0: eyes flaring (it just noticed you)
var _fade_t := 0.0               # > 0: fading in after a hatch or a call (harmless)
var _fade_max := 0.0
var _art: FoeSprite

## Hatched or called: it fades in, harmless, for kl_hatch_fade. Call before adding it to the tree.
func fade_in() -> void:
	_fade_t = Tuning.kl_hatch_fade
	_fade_max = _fade_t
	if _fade_t > 0.0:
		modulate.a = 0.0

func is_fading_in() -> bool:
	return _fade_t > 0.0

## Its reach before the drain (tests and captures), or null.
func latch_tell() -> Telegraph.Tell:
	return _latch

func _exit_tree() -> void:
	if _latch:
		_latch.finish()

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
	_art = FoeSprite.attach(self, "wickling", "elite" if elite else ("timid" if timid else "brave"))

# --- Senses (the light senses are in Foe) --------------------------------------

## What it would go after, nearest first: kindling WayLamps, mirrors out in the dark.
func _find_prey(max_dist: float) -> Node2D:
	var best: Node2D = null
	var bd := max_dist
	LightSense.refresh(get_tree())
	for w in LightSense.waylamps:
		if not is_instance_valid(w):
			continue
		var d: float = w.global_position.distance_to(global_position)
		if w.kindling and d < bd:
			best = w
			bd = d
	# M1b: lamps never die, so nothing is drained; Wicklings hunt the keeper (GAME_PLAN §6).
	for l in LightSense.mirrors:
		if not is_instance_valid(l):
			continue
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
	_notice_t = maxf(0.0, _notice_t - delta)
	if _fade_t > 0.0:
		_fade_t = maxf(0.0, _fade_t - delta)
		modulate.a = 1.0 - _fade_t / maxf(_fade_max, 0.001)
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
			if player == null or player.in_light_cached() or player.global_position.distance_to(global_position) > Tuning.wick_sense * 1.4:
				state = State.WANDER
				waiting_for_keeper = player != null and player.in_light_cached() and player.global_position.distance_to(global_position) <= Tuning.travel_hunt_radius
			else:
				goal = player.global_position
				if player.global_position.distance_to(global_position) < 12.0 + body_radius() and _fade_t <= 0.0:
					_touch(player, delta)
				else:
					_let_go()
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
			# Nothing else to go after (M1b: lamps can't be drained).
			target = null
			state = State.WANDER
		_:
			if waiting_for_keeper and (player == null or not player.in_light_cached() or player.global_position.distance_to(global_position) > Tuning.travel_hunt_radius):
				waiting_for_keeper = false
			if (_wander_to - global_position).length() < 8.0 or int(_t * 10) % 40 == 0:
				_pick_wander()
			goal = _wander_to
			speed *= 0.5
			# Look for prey.
			if player and not player.in_light_cached() and player.global_position.distance_to(global_position) < Tuning.wick_sense:
				state = State.CHASE
				_notice_t = Tuning.kl_notice_time   # eyes flare: it has seen you
				Telegraph.play_slot("wickling", "notice")
			else:
				var prey := _find_prey(Tuning.wick_sense * 1.5)
				if prey:
					target = prey
					state = State.SEEK_LANTERN
	if state != State.WANDER:
		waiting_for_keeper = false
	if state != State.CHASE:
		_let_go()
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
	if _art:
		_update_art(step)
	queue_redraw()

## Owner art (assets/art/creatures/wickling/): the strip for what it is doing now. An elite whose shell broke
## shows the shell-less body ("elite_broken") once its crack has played.
func _update_art(step: Vector2) -> void:
	if elite and shell <= 0.0 and not _art.holding():
		_art.set_variant("elite_broken")
	var anim := "move" if step.length() > 0.01 else "idle"
	if _fade_t > 0.0:
		anim = "spawn"
	elif _latch:
		anim = "windup"
	elif latched:
		anim = "attack"
	elif _notice_t > 0.0:
		anim = "notice"
	elif state == State.FLEE:
		anim = "flee"
	_art.play_anim(anim)
	if absf(step.x) > 0.05:
		_art.flip_h = step.x < 0.0   # drawn facing right

func _on_shell_cracked() -> void:
	super._on_shell_cracked()
	if _art:
		_art.play_once("crack")

## Touching the keeper: first it reaches (a short wind-up), then its touch drains warmth, and the keeper shows a
## frost edge. The touch is a drain, not a hit, so it needs no minimum warning (ART_DIRECTION §4.4 rule 1).
func _touch(player: Node2D, delta: float) -> void:
	if not latched:
		if _latch == null:
			_latch = Telegraph.begin(self, Telegraph.REACH, "wickling", Tuning.kl_elite_latch_tell if elite else Tuning.kl_wick_latch_tell, false)
			Telegraph.arm(_latch, get_tree())
		_latch.center = global_position
		_latch.to = player.global_position
		_latch.tick(delta)
		if not _latch.done():
			return
		_latch.finish()
		_latch = null
		latched = true
	var lee := Tuning.kl_lee_mult if Progress.has_combat_upgrade("lee") else 1.0
	player.chill(Tuning.warmth_drain_per_sec * (Tuning.kl_elite_chill_mult if elite else 1.0) * lee * delta)
	if "frost_t" in player and not player.combat.is_dashing():
		player.frost_t = 0.15

## Out of reach (or no longer hunting): the reach and the drain stop.
func _let_go() -> void:
	latched = false
	if _latch:
		_latch.finish()
		_latch = null

func _draw() -> void:
	var art := _art != null and _art.showing()
	if elite:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.6, 1.6))
	var wob := sin(_t * 5.0) * 1.5
	if not art:
		var body := Color(0.03, 0.035, 0.06, 0.92)
		# Smoky body: a few overlapping blobs.
		draw_circle(Vector2(0, wob), 10.0, body)
		draw_circle(Vector2(-6, 6 + wob * 0.5), 6.0, body)
		draw_circle(Vector2(6, 7 - wob * 0.5), 5.0, body)
		draw_circle(Vector2(sin(_t * 3.0) * 3.0, 14), 3.5, Color(body, 0.6))
	if _burning > 0.0:
		draw_arc(Vector2(0, wob), 11.0, 0.0, TAU, 20, Color(1.0, 0.65, 0.3, 0.9), 1.5)
	# A faint rim so they read against dark fog. The bold swarm's is the brighter cold #a3bcd4, wobbling faster
	# (it was an off-palette red that read as warm: ART_DIRECTION §1.4 rule 3); it stays over owner art too, so
	# the Ashbrood's adds still read as the bold swarm.
	if bold:
		draw_arc(Vector2(0, wob), 11.5, 0.0, TAU, 24, Color(Telegraph.COLD, 0.6 + 0.25 * sin(_t * 11.0)), 1.5)
	elif not art:
		draw_arc(Vector2(0, wob), 11.5, 0.0, TAU, 24, Color(Color(0.55, 0.68, 0.85), 0.35 + 0.15 * sin(_t * 4.0)), 1.0)
	if art and _notice_t > 0.0:
		# The notice flare over owner art too (its notice strip widens the eyes; this arc is the tell).
		draw_arc(Vector2(0, wob - 2), 9.0, PI * 1.1, PI * 1.9, 12, Color(Telegraph.COLD, _notice_t / maxf(Tuning.kl_notice_time, 0.01)), 1.5)
	if not art:
		# Pale eyes (brighter when hunting you; they flare for a moment when it notices you).
		var eye := Color(0.75, 0.84, 0.92) if state != State.CHASE else Color(1.0, 1.0, 1.0)
		var grow := 2.0 * (_notice_t / maxf(Tuning.kl_notice_time, 0.01))
		draw_rect(Rect2(-6 - grow * 0.5, -4 + wob - grow * 0.5, 4 + grow, 4 + grow), eye)
		draw_rect(Rect2(2 - grow * 0.5, -4 + wob - grow * 0.5, 4 + grow, 4 + grow), eye)
		if _notice_t > 0.0:
			draw_arc(Vector2(0, wob - 2), 9.0, PI * 1.1, PI * 1.9, 12, Color(Telegraph.COLD, _notice_t / maxf(Tuning.kl_notice_time, 0.01)), 1.5)
	# Health shows as how solid it looks once hurt.
	if hp < Tuning.wick_hp:
		draw_arc(Vector2(0, wob), 14.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(hp / Tuning.wick_hp, 0.0, 1.0), 20, Color(1.0, 0.7, 0.35, 0.8), 2.0)
	# A thin tendril to what it is draining (a lamp), or to the keeper once latched.
	if state == State.SNUFF and target and is_instance_valid(target):
		var lamp_y := -60.0 if target is WayLamp else -34.0
		draw_line(Vector2.ZERO, to_local(target.global_position + Vector2(0, lamp_y)), Color(0.05, 0.06, 0.1, 0.7), 2.0)
	if latched:
		var pl := _player()
		if pl:
			var to := to_local(pl.global_position) / (1.6 if elite else 1.0)
			draw_line(Vector2.ZERO, to, Color(0.05, 0.06, 0.1, 0.8), 3.0)
			draw_line(Vector2.ZERO, to, Color(Telegraph.COLD, 0.5), 1.0)
	if elite:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_shell(Vector2(0, -2), 22.0)   # a pale, cracked shell; it thins as the beam wears it down
		# Its plates glint when it is close to you.
		var pk := _player()
		if pk and shell > 0.0 and pk.global_position.distance_to(global_position) < 48.0 + body_radius():
			var g := 0.5 + 0.5 * sin(_t * 14.0)
			draw_line(Vector2(-10, -16), Vector2(-6, -20), Color(1, 1, 1, g), 1.5)
			draw_line(Vector2(9, -12), Vector2(13, -16), Color(1, 1, 1, 1.0 - g), 1.5)
