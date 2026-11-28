class_name Ashbrood
extends Foe
## The Hollow's WayLamp guardian. A three-phase fight (M2): the bowl, then the lamps, then "last of the brood".
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
## M1b: it is Lv kl_ashbrood_level (5) and each phase's health and shell grow with it (Foe.level_mult). After a
## faint it starts its current phase again (restart_phase). It broods over the WayLamp's last ember (DECISIONS
## 2026-11-27): the WayLamp draws the ember, and takes it back when the Ashbrood dies.
## M1c (PLAN_LANTERNS §2.1, §8 item 3; owner playtest "it just sits there"):
##   - it is hurt only when lit (needs_light: dim counts as dark). In the dark every hit glances off (the clink),
##     and the boss bar says "It shrugs off fire in the dark. Bring a lamp." (DRAFT);
##   - phase 1, in the bowl, it covers the ember. Light it with a lamp whose light reaches the bowl (the old rim
##     lamp, kl_rim_lamp_dist out, lit by touch, can always do it), or throw a Fireglobe into the bowl: the ember
##     flares (kl_ember_flare_radius) and exposes it for kl_ember_flare_time, at most once per kl_ember_flare_cd;
##   - phase 1 fights back: ash bolts (a fan of kl_ashbrood_bolt_count, each with its own aim marker) every
##     kl_ashbrood_bolt_period; a wing sweep (a circle, a chill and a shove) when you stand close; the puff, which
##     now also snuffs every lamp inside its circle for kl_ashbrood_puff_snuff; the adds. It never waits longer
##     than kl_ashbrood_idle_max without starting a wind-up;
##   - phase 2: dives every kl_ashbrood_dive_period after a sit, at the nearest lit lamp in its arena (the rim lamp
##     counts). With no lit lamp it dives at you and recovers in kl_ashbrood_dark_sit, then throws ash bolts (review
##     fix: never a long sit in the dark, where it can't be hurt). During its sit it smothers that lamp, which stays lit (the punish window); then the lamp is out
##     for kl_snuff_sec.
## M2 (owner, M1c playtest: "phase 2 is still a bit boring and there definitely needs to be more moves"):
##   - phase 2 alternates its dive with a new move each time, never the same new move twice in a row: the **ash
##     wave** (a 60 px lane from it through you, kl_ashbrood_wave_tell, then a wall of ash runs it), the **low pass**
##     (a lane past you; it flies it and leaves kl_ashbrood_strafe_embers cold embers that chill whoever stands in
##     them), and every kl_ashbrood_call_period it **calls Wicklings from the dark** (spawn glows on your side);
##   - phase 3, **last of the brood** (ART_DIRECTION §2.5, GAME_PLAN §8.2): faster (x kl_ashbrood_p3_mult), cracked
##     wings, and every move is a combo: it **returns to the bowl** and settles over the last ember (which now shows
##     through its cracked wings and lights it: the no-soft-lock window, no lamp needed), then puffs; it **dives and
##     sends a wave** from where it lands; it **makes a low pass and throws ash bolts** from the far end. Each cycle
##     has all three, the two combos in a random order.
## Every new wind-up uses the shared Telegraph in the cold colour (lanes, circles, spawn glows); a dash avoids each.

const BOWL_RADIUS := 64.0        # px: a Fireglobe landing this close to the WayLamp lands in the bowl
const ARENA := 520.0             # px from the WayLamp: lamps it dives at (it doesn't fly off across the valley)
## Where the last ember lies, at its feet in the bowl (the sprite's own small bowl ember is here: one ember).
const EMBER_AT := Vector2(4, 12)

var waylamp: WayLamp
var phase := 1
var _puff_t := 2.0
var _wave_t := 3.0
var _dive_t := 2.0               # s before the next move may start (phases 2-3; the next dive in M1c)
var _bolt_t := 1.2
var _sweep_cd := 0.0
var _idle_t := 0.0               # s since its last wind-up began (it never waits past kl_ashbrood_idle_max)
var _sit_t := 0.0
var _target_lamp: Lantern
var _pulse := 0.0
var _roll_dir := Vector2.RIGHT
var _puff: Telegraph.Tell        # the ash puff's wind-up
var _adds: Telegraph.Tell        # the call for adds (spawn glows)
var _dive: Telegraph.Tell        # the dive's landing circle (kept through the flight; finished on landing)
var _bolts: Array = []           # the ash bolts' aim markers (one per bolt)
var _sweep: Telegraph.Tell       # the wing sweep's circle
var _fly_t := 0.0                # > 0: in the air, diving
var _fly_from := Vector2.ZERO
var _phase_t := 0.0              # > 0: rising out of the bowl between phases (no attacks, no damage)
var _ash_t := 0.0                # > 0: the ash ring left by a puff
var _ember_t := 0.0              # > 0: the ember is stirred (a Fireglobe in the bowl): it is exposed
var _ember_cd := 0.0
var _dark_hint_t := 0.0          # > 0: a hit just glanced off in the dark (the boss bar says why)
var _dark_sit := false           # this sit is in the dark (no lit lamp under it): short, then ash bolts
var dark_sits := 0               # dark landings so far (tests)
var attacks := 0                 # wind-ups started (tests)
var last_attack := ""            # what it started last: puff, adds, bolts, sweep, dive (tests)
var _art: FoeSprite              # owner art (assets/art/creatures/ashbrood/), when it exists
# M2: phase 2's new moves and phase 3.
var _plan: Array[String] = []    # moves queued next (phase 3's combos)

var _move := ""                  # the move under way in phases 2-3: dive, return, wave, strafe
var _last_new := ""              # phase 2: the new move used last (wave or strafe), so the next one differs
var _since_dive := 1             # phase 2: new moves since the last dive (1: a dive comes next)
var _wave: Telegraph.Tell        # the ash wave's lane
var _front_t := 0.0              # > 0: the wave front running its lane (the look)
var _front_from := Vector2.ZERO
var _front_to := Vector2.ZERO
var _strafe: Telegraph.Tell      # the low pass's lane
var _strafe_t := 0.0             # > 0: flying the pass
var _strafe_from := Vector2.ZERO
var _strafe_to := Vector2.ZERO
var _embers_left := 0
var _recover_t := 0.0            # > 0: hanging after a wave or a pass
var _call: Telegraph.Tell        # phase 2: Wicklings called from the dark (spawn glows)
var _call_t := 6.0
var history: Array = []          # [phase, move] for every wind-up started (tests: variety, every move seen)
var embers_dropped := 0          # cold embers left by passes (tests)
const ART_FOOT := 28.0           # the 48 x 48 strip's foot (foot anchor), a little under the code body's bottom

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
	_art = FoeSprite.attach(self, "ashbrood")
	if _art:
		_art.position = Vector2(0, ART_FOOT)

func _exit_tree() -> void:
	_finish_all()
	_release_lamp(false)

func _finish_all() -> void:
	for t in [_puff, _adds, _dive, _sweep, _wave, _strafe, _call]:
		if t:
			t.finish()
	for t in _bolts:
		t.finish()
	_bolts.clear()

## Wind-ups in progress (tests and captures).
func puff_tell() -> Telegraph.Tell:
	return _puff

func adds_tell() -> Telegraph.Tell:
	return _adds

func dive_tell() -> Telegraph.Tell:
	return _dive

func sweep_tell() -> Telegraph.Tell:
	return _sweep

func bolt_tells() -> Array:
	return _bolts

func wave_tell() -> Telegraph.Tell:
	return _wave

func strafe_tell() -> Telegraph.Tell:
	return _strafe

func call_tell() -> Telegraph.Tell:
	return _call

func is_strafing() -> bool:
	return _strafe_t > 0.0

## The move under way in phases 2-3 ("" between moves).
func current_move() -> String:
	return _move

## Phase 3 speeds every wind-up and wait up (never under kl_tell_min: Telegraph.begin clamps it).
func _m() -> float:
	return Tuning.kl_ashbrood_p3_mult if phase >= 3 else 1.0

func is_flying() -> bool:
	return _fly_t > 0.0

func is_sitting() -> bool:
	return _sit_t > 0.0

func in_phase_pause() -> bool:
	return _phase_t > 0.0

## Sitting after a dive that found no lit lamp (short: kl_ashbrood_dark_sit, then it throws ash bolts).
func is_dark_sitting() -> bool:
	return _sit_t > 0.0 and _dark_sit

func smothered_lamp() -> Lantern:
	return _target_lamp if _sit_t > 0.0 and is_instance_valid(_target_lamp) else null

## Any wind-up in progress (or a dive in the air): it is doing something.
func busy() -> bool:
	return _puff != null or _adds != null or _dive != null or _sweep != null or not _bolts.is_empty() or _fly_t > 0.0 \
		or _wave != null or _strafe != null or _strafe_t > 0.0 or _call != null or _recover_t > 0.0

## Ends the rise between phases at once (tests that hurt it with its process off).
func end_phase_pause() -> void:
	_phase_t = 0.0

# --- Light (M1c) ---------------------------------------------------------------------------------------------

func needs_light() -> bool:
	return Tuning.kl_ashbrood_needs_light

## The stirred ember lights it while it broods in the bowl. Phase 3 (M2): its wings are cracked and the last ember
## shows through them, so over the bowl it is always lit (the window that needs no lamp at all).
func extra_light_source() -> Vector2:
	if waylamp and (_ember_t > 0.0 or phase >= 3) and global_position.distance_to(waylamp.global_position) <= Tuning.kl_ember_flare_radius:
		return waylamp.global_position + EMBER_AT
	return Vector2.INF

func ember_stirred() -> bool:
	return _ember_t > 0.0

func ember_ready() -> bool:
	return phase == 1 and _ember_cd <= 0.0 and _phase_t <= 0.0

## A Fireglobe in the bowl (FireBolts): the ember flares and exposes it. False on cooldown or in phase 2.
func stir_ember() -> bool:
	if not ember_ready():
		return false
	_ember_t = Tuning.kl_ember_flare_time
	_ember_cd = Tuning.kl_ember_flare_cd
	update_light_state(0.0)
	Sfx.play("relight", -6.0, 0.1, 1.2)
	return true

## The boss bar's dark hint shows for a while after a hit glanced off in the dark.
func dark_hint() -> bool:
	return _dark_hint_t > 0.0

func hurt(amount: float, scare: bool = true, source: String = "") -> void:
	if _phase_t > 0.0:
		return   # rising out of the bowl: it can't be hurt
	light_now()
	if needs_light() and effective_light() != LIT and not (source in LIGHT_EXEMPT):
		since_hurt = 0.0
		_dark_hint_t = 3.0
		_glance()   # in the dark every hit glances off
		return
	super.hurt(amount, scare, source)

func _lose_hp(amount: float) -> void:
	if _phase_t > 0.0:
		return
	super._lose_hp(amount)

# --- Each frame ----------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	_pulse += delta
	_ash_t = maxf(0.0, _ash_t - delta)
	_ember_t = maxf(0.0, _ember_t - delta)
	_ember_cd = maxf(0.0, _ember_cd - delta)
	_dark_hint_t = maxf(0.0, _dark_hint_t - delta)
	_sweep_cd = maxf(0.0, _sweep_cd - delta)
	if _phase_t > 0.0:
		_phase_t = maxf(0.0, _phase_t - delta)
		_update_art()
		queue_redraw()
		return
	var player := _player()
	if player == null or is_stunned():
		_update_art()
		queue_redraw()
		return
	if not busy() and _sit_t <= 0.0:
		_idle_t += delta
	if phase == 1:
		_process_bowl(delta, player)
	else:
		_tick_puff(delta, player)
		_process_dive(delta, player)
		_tick_call(delta, player)
	_tick_bolts(delta, player)
	_tick_sweep(delta, player)
	_front_t = maxf(0.0, _front_t - delta)
	_update_art()
	queue_redraw()

func _began(what: String) -> void:
	attacks += 1
	last_attack = what
	_idle_t = 0.0
	history.append([phase, what])

## Owner art: the strip for what it is doing. Phase 1, in the bowl: idle (over the ember), the puff's wind-up
## and release (M1c: the ash bolts reuse them), the wing sweep (the dive's crouch, then the release). Rising between
## phases: phase_rise. Phase 2, out of the bowl: the dive's wind-up (crouched), the flight, the slump after landing
## (recover: the open window), and between dives its risen pose (phase_rise), since its idle strip is drawn in the
## bowl.
func _update_art() -> void:
	if _art == null:
		return
	var anim := "idle"
	var secs := 0.0
	var lift := 0.0
	if _phase_t > 0.0:
		anim = "phase_rise"
		var k := 1.0 - _phase_t / maxf(Tuning.kl_ashbrood_phase_pause, 0.01)
		lift = -sin(k * PI) * 14.0
	elif phase == 1:
		if _puff:
			anim = "windup_puff"
			secs = _puff.duration
		elif _sweep:
			anim = "windup_dive"
			secs = _sweep.duration
		elif not _bolts.is_empty():
			anim = "windup_puff"
			secs = (_bolts[0] as Telegraph.Tell).duration
		elif _ash_t > 0.0:
			anim = "attack_puff"
	else:
		var in_bowl := waylamp != null and global_position.distance_to(waylamp.global_position) < 8.0
		if _fly_t > 0.0 or _strafe_t > 0.0:
			anim = "attack_dive"
		elif _sit_t > 0.0:
			anim = "idle" if (_move == "return" and in_bowl) else "recover"   # phase 3: back over the ember, wings low
		elif _dive or _strafe:
			anim = "windup_dive"
			secs = (_dive if _dive else _strafe).duration
		elif _wave or _puff:
			anim = "windup_puff"
			secs = (_wave if _wave else _puff).duration
		elif _front_t > 0.0 or _ash_t > 0.0:
			anim = "attack_puff"
		elif _recover_t > 0.0:
			anim = "recover"
		else:
			anim = "phase_rise"
		if _strafe_t > 0.0:
			_roll_dir = (_strafe_to - _strafe_from).normalized()
		if absf(_roll_dir.x) > 0.05:
			_art.flip_h = _roll_dir.x < 0.0   # drawn facing right: it faces where it dives
	_art.play_anim(anim, secs)
	_art.position = Vector2(0, ART_FOOT + lift)

## The ash puff's wind-up and strike (phase 1 on its period; phase 3 after it settles over the ember).
func _tick_puff(delta: float, player: Node2D) -> void:
	if _puff == null:
		return
	_puff.tick(delta)
	_puff.center = global_position
	if _puff.done():
		var hit: bool = _puff.contains(player.global_position) and not player.combat.is_dashing()
		_puff_snuff()
		Telegraph.play_slot("ashbrood_puff", "release")
		_puff.finish()
		_puff = null
		_ash_t = 0.4
		_puff_t = Tuning.kl_ashbrood_puff_period
		if hit:
			player.lamp_charge = minf(player.lamp_charge, Tuning.kl_ashbrood_puff_charge)
			player.chill(Tuning.kl_ashbrood_puff_warmth * dmg_level_mult())   # last: a faint comes after this frame
		if phase >= 2:
			_after("puff")

func _start_puff() -> void:
	_puff = Telegraph.begin(self, Telegraph.CIRCLE, "ashbrood_puff", Tuning.kl_ashbrood_puff_tell * _m())
	_puff.boss = true
	_puff.radius = Tuning.kl_ashbrood_puff_radius
	Telegraph.arm(_puff, get_tree())
	_began("puff")

func _process_bowl(delta: float, player: Node2D) -> void:
	if _puff:
		_tick_puff(delta, player)
	elif _sweep == null:
		_puff_t -= delta
		if _puff_t <= 0.0:
			_start_puff()
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
			_began("adds")
	# The wing sweep when you stand close (not while it puffs).
	var d := player.global_position.distance_to(global_position)
	if _sweep == null and _puff == null and _sweep_cd <= 0.0 and d <= Tuning.kl_ashbrood_sweep_radius + 24.0:
		_start_sweep()
	# Ash bolts at you on their period, and whenever it has waited too long.
	_bolt_t -= delta
	if _bolts.is_empty() and _puff == null and _sweep == null and (_bolt_t <= 0.0 or _idle_t >= Tuning.kl_ashbrood_idle_max):
		_start_bolts(player)

## The puff snuffs every lamp inside its circle (M1c), the rim lamp included if it stood that close.
func _puff_snuff() -> void:
	if Tuning.kl_ashbrood_puff_snuff <= 0.0:
		return
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.kind != "mirror" and l.is_lit() and l.global_position.distance_to(global_position) <= Tuning.kl_ashbrood_puff_radius:
			l.snuff(Tuning.kl_ashbrood_puff_snuff)

func _start_sweep() -> void:
	_sweep = Telegraph.begin(self, Telegraph.CIRCLE, "ashbrood_sweep", Tuning.kl_ashbrood_sweep_tell)
	_sweep.boss = true
	_sweep.radius = Tuning.kl_ashbrood_sweep_radius
	Telegraph.arm(_sweep, get_tree())
	_sweep_cd = Tuning.kl_ashbrood_sweep_cd
	_began("sweep")

func _tick_sweep(delta: float, player: Node2D) -> void:
	if _sweep == null:
		return
	_sweep.tick(delta)
	_sweep.center = global_position
	if not _sweep.done():
		return
	var hit: bool = _sweep.contains(player.global_position) and not player.combat.is_dashing()
	Telegraph.play_slot("ashbrood_puff", "release")
	_sweep.finish()
	_sweep = null
	_ash_t = 0.3
	if hit:
		player.knockback(player.global_position - global_position, Tuning.kl_ashbrood_sweep_knock)
		player.chill(Tuning.kl_ashbrood_sweep_warmth * dmg_level_mult())

## A fan of ash bolts at the keeper: each bolt has its own aim marker (the marker is the hitbox), and the
## warning-gap rule spaces them out, so they come one after another.
func _start_bolts(player: Node2D) -> void:
	_bolt_t = Tuning.kl_ashbrood_bolt_period
	if player.global_position.distance_to(global_position) > Tuning.kl_ashbrood_bolt_range + 200.0:
		return
	var n := maxi(1, Tuning.kl_ashbrood_bolt_count)
	var base := (player.global_position - global_position).angle()
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * deg_to_rad(Tuning.kl_ashbrood_bolt_spread_deg)
		var t := Telegraph.begin(self, Telegraph.AIM, "ashbrood_bolt", Tuning.kl_ashbrood_bolt_tell * _m())
		t.boss = true
		t.radius = Tuning.kl_spit_hit_radius + Telegraph.KEEPER_RADIUS
		t.reach = Tuning.kl_ashbrood_bolt_range
		t.set_meta("off", off)
		t.to = global_position + Vector2.from_angle(base + off) * minf(Tuning.kl_ashbrood_bolt_range, player.global_position.distance_to(global_position))
		Telegraph.arm(t, get_tree(), i == 0)
		_bolts.append(t)
	_began("bolts")

func _tick_bolts(delta: float, player: Node2D) -> void:
	var i := 0
	while i < _bolts.size():
		var t: Telegraph.Tell = _bolts[i]
		t.tick(delta)
		t.center = global_position
		if not t.locked():
			var base := (player.global_position - global_position).angle() + float(t.get_meta("off", 0.0))
			t.to = global_position + Vector2.from_angle(base) * minf(Tuning.kl_ashbrood_bolt_range, maxf(60.0, player.global_position.distance_to(global_position)))
		if t.done():
			var shot := SpitProjectile.new()
			shot.position = global_position
			shot.direction = (t.to - t.center).normalized()
			shot.speed = Tuning.kl_ashbrood_bolt_speed
			shot.warmth = Tuning.kl_ashbrood_bolt_warmth
			shot.life = Tuning.kl_ashbrood_bolt_range / maxf(Tuning.kl_ashbrood_bolt_speed, 1.0)
			shot.dmg_mult = dmg_level_mult()
			shot.subject = "ashbrood_bolt"
			get_parent().add_child(shot)
			Telegraph.play_slot("ashbrood_bolt", "release")
			_ash_t = maxf(_ash_t, 0.2)
			t.finish()
			_bolts.remove_at(i)
		else:
			i += 1

# --- Phases 2 and 3: the move scheduler (M2) -----------------------------------------------------------------

func _process_dive(delta: float, player: Node2D) -> void:
	if _fly_t > 0.0:
		_fly_t = maxf(0.0, _fly_t - delta)
		var k := 1.0 - _fly_t / maxf(Tuning.kl_ashbrood_dive_travel, 0.01)
		global_position = _fly_from.lerp(_dive.center, k)
		if _fly_t <= 0.0:
			_land(player)
		return
	if _strafe_t > 0.0:
		_fly_strafe(delta)
		return
	if _sit_t > 0.0:
		_sit_t = maxf(0.0, _sit_t - delta)
		if _sit_t <= 0.0:
			_release_lamp(true)   # the sit ends: the lamp it smothered goes out
			var was_dark := _dark_sit
			_dark_sit = false
			if was_dark:
				_start_bolts(player)   # a dark landing: it shakes off the ash and throws bolts at once
			_after("return_sit" if _move == "return" else "sit")
		return
	if _dive:
		_dive.tick(delta)
		if is_instance_valid(_target_lamp):
			_target_lamp.threatened = 0.2   # the lamp flickers while the dive winds up
		if _dive.done():
			_fly_from = global_position
			_fly_t = maxf(Tuning.kl_ashbrood_dive_travel, 0.01)
		return
	if _wave:
		_tick_wave(delta, player)
		return
	if _strafe:
		_tick_strafe_tell(delta, player)
		return
	if _recover_t > 0.0:
		_recover_t = maxf(0.0, _recover_t - delta)
		return
	if _puff:
		return
	_dive_t -= delta
	if _dive_t <= 0.0 and _bolts.is_empty():
		_start_move(_next_move(), player)
	elif _bolts.is_empty() and _idle_t >= Tuning.kl_ashbrood_idle_max:
		_start_bolts(player)   # waiting between moves too long: ash bolts

## What comes next. Phase 2: a dive, then a new move (the wave or the pass, never the same one twice running), then a
## dive again. Phase 3: cycles of [return to the bowl, then the two combos in a random order]; each combo's second
## part is queued as its first ends (_after).
func _next_move() -> String:
	if not _plan.is_empty():
		return _plan.pop_front()
	if phase == 2:
		if _since_dive >= 1:
			return "dive"
		var pick := "wave" if _last_new == "strafe" else ("strafe" if _last_new == "wave" else ("wave" if randf() < 0.5 else "strafe"))
		return pick
	var combos: Array[String] = ["dive", "strafe"]
	combos.shuffle()
	_plan.assign(combos)
	return "return"

## Sets the move off (or queues it). Unknown or impossible moves fall back to a dive.
func _start_move(what: String, player: Node2D) -> void:
	match what:
		"dive":
			_move = "dive"
			_since_dive = 0
			_start_dive(player)
		"return":
			_move = "return"
			_start_return()
		"wave":
			_move = "wave"
			_since_dive += 1
			_last_new = "wave"
			_start_wave(player)
		"strafe":
			_move = "strafe"
			_since_dive += 1
			_last_new = "strafe"
			_start_strafe(player)
		"puff":
			_start_puff()
		"bolts":
			_start_bolts(player)
			_dive_t = Tuning.kl_ashbrood_combo_gap
		_:
			_start_dive(player)

## A move ended: what follows and how soon. Phase 3 chains combos: a sit on a lamp sends a wave, a pass ends in ash
## bolts, settling over the ember ends in a puff.
func _after(what: String) -> void:
	_dive_t = Tuning.kl_ashbrood_dive_period * _m()
	if phase >= 3:
		_dive_t = Tuning.kl_ashbrood_combo_gap
		match what:
			"sit":
				_plan.push_front("wave")
			"strafe":
				_plan.push_front("bolts")
			"return_sit":
				_plan.push_front("puff")
	elif what == "wave" or what == "strafe":
		_dive_t = 0.2   # phase 2: the dive comes soon after a new move (it recovers first)
	_move = ""

func _start_dive(player: Node2D) -> void:
	_target_lamp = _nearest_lit_lamp()
	var land: Vector2
	if _target_lamp:
		land = _target_lamp.global_position + Vector2(0, -12)
		_roll_dir = (land - global_position).normalized()
	else:
		_roll_dir = (player.global_position - global_position).normalized()
		land = global_position + _roll_dir * Tuning.kl_ashbrood_dive_dist
	_dive = Telegraph.begin(self, Telegraph.CIRCLE, "ashbrood_dive", Tuning.kl_ashbrood_dive_tell * _m())
	_dive.boss = true
	_dive.center = land
	_dive.radius = Tuning.kl_ashbrood_hit_radius
	Telegraph.arm(_dive, get_tree())
	_began("dive")

## Phase 3: it flies back to the bowl, a landing circle on the WayLamp, and settles over the last ember.
func _start_return() -> void:
	_target_lamp = null
	var land: Vector2 = waylamp.global_position if waylamp else global_position
	_roll_dir = (land - global_position).normalized() if land.distance_to(global_position) > 1.0 else Vector2.RIGHT
	_dive = Telegraph.begin(self, Telegraph.CIRCLE, "ashbrood_dive", Tuning.kl_ashbrood_dive_tell * _m())
	_dive.boss = true
	_dive.center = land
	_dive.radius = Tuning.kl_ashbrood_hit_radius
	Telegraph.arm(_dive, get_tree())
	_began("return")

## The dive lands: it smothers the lamp under it for its sit (still lit: hit it now), and the landing circle chills
## a keeper who isn't dashing. Phase 3's return settles over the ember instead (lit by it).
func _land(player: Node2D) -> void:
	global_position = _dive.center
	var hit: bool = _dive.contains(player.global_position) and not player.combat.is_dashing()
	if _move != "return" and is_instance_valid(_target_lamp) and _target_lamp.is_lit():
		_target_lamp.smother_by = self
	Telegraph.play_slot("ashbrood_dive", "impact")
	_dive.finish()
	_dive = null
	_ash_t = 0.3
	if _move == "return":
		_dark_sit = false
		_sit_t = Tuning.kl_ashbrood_brood_sit
		update_light_state(0.0)
	else:
		# Review fix (M1c): only a sit on a lit lamp is the long punish window. With no lit lamp under it (the rim lamp
		# still out after the last smother) it can't be hurt, so it recovers fast and throws ash bolts.
		_dark_sit = not (is_instance_valid(_target_lamp) and _target_lamp.smother_by == self)
		if _dark_sit:
			dark_sits += 1
		var lit_sit := Tuning.kl_ashbrood_p3_sit if phase >= 3 else Tuning.kl_ashbrood_sit_sec
		_sit_t = Tuning.kl_ashbrood_dark_sit * _m() if _dark_sit else lit_sit
	_dive_t = Tuning.kl_ashbrood_dive_period
	if hit:
		player.chill(Tuning.kl_ashbrood_dive_warmth * dmg_level_mult())   # last: the faint runs after this frame

## The ash wave: a lane from it through the keeper, kl_ashbrood_ash_wave_len long and 2 x kl_ashbrood_ash_wave_half
## wide; it follows the keeper until the commit, then a wall of ash runs the lane (the lane is the hit).
func _start_wave(player: Node2D) -> void:
	_wave = Telegraph.begin(self, Telegraph.LANE, "ashbrood_wave", Tuning.kl_ashbrood_wave_tell * _m())
	_wave.boss = true
	_wave.radius = Tuning.kl_ashbrood_ash_wave_half
	_aim_lane(_wave, player.global_position, Tuning.kl_ashbrood_ash_wave_len)
	Telegraph.arm(_wave, get_tree())
	_began("wave")

func _aim_lane(t: Telegraph.Tell, at: Vector2, length: float) -> void:
	t.center = global_position
	var v := at - global_position
	var d := v.normalized() if v.length() > 1.0 else _roll_dir
	t.to = global_position + d * _clear_length(global_position, d, length)

## How far a lane can run from `from` along `d` before rock or the arena's edge (at least 120 px).
func _clear_length(from: Vector2, d: Vector2, length: float) -> float:
	var fog := _fog()
	var home := waylamp.global_position if waylamp else from
	var l := length
	while l > 120.0:
		var end := from + d * l
		if (fog == null or not fog.is_solid_at(end)) and end.distance_to(home) <= ARENA:
			break
		l -= 20.0
	return l

func _tick_wave(delta: float, player: Node2D) -> void:
	_wave.tick(delta)
	if not _wave.locked():
		_aim_lane(_wave, player.global_position, Tuning.kl_ashbrood_ash_wave_len)
	if not _wave.done():
		return
	var hit: bool = _wave.contains(player.global_position) and not player.combat.is_dashing()
	_front_from = _wave.center
	_front_to = _wave.to
	_front_t = Tuning.kl_ashbrood_ash_wave_travel
	Telegraph.play_slot("ashbrood_wave", "release")
	_wave.finish()
	_wave = null
	_ash_t = 0.3
	_recover_t = Tuning.kl_ashbrood_recover * _m()
	_after("wave")
	if hit:
		player.knockback((_front_to - _front_from), Tuning.kl_ashbrood_ash_wave_knock)
		player.chill(Tuning.kl_ashbrood_ash_wave_warmth * dmg_level_mult())

## The low pass: a lane past the keeper; at the commit it flies it in kl_ashbrood_strafe_travel, hitting whoever is
## in the lane, and drops cold embers along it.
func _start_strafe(player: Node2D) -> void:
	_strafe = Telegraph.begin(self, Telegraph.LANE, "ashbrood_strafe", Tuning.kl_ashbrood_strafe_tell * _m())
	_strafe.boss = true
	_strafe.radius = Tuning.kl_ashbrood_strafe_half
	_aim_lane(_strafe, player.global_position, Tuning.kl_ashbrood_strafe_len)
	Telegraph.arm(_strafe, get_tree())
	_began("strafe")

func _tick_strafe_tell(delta: float, player: Node2D) -> void:
	_strafe.tick(delta)
	if not _strafe.locked():
		_aim_lane(_strafe, player.global_position, Tuning.kl_ashbrood_strafe_len)
	if not _strafe.done():
		return
	var hit: bool = _strafe.contains(player.global_position) and not player.combat.is_dashing()
	_strafe_from = _strafe.center
	_strafe_to = _strafe.to
	_strafe_t = maxf(Tuning.kl_ashbrood_strafe_travel, 0.05)
	_embers_left = Tuning.kl_ashbrood_strafe_embers
	_roll_dir = (_strafe_to - _strafe_from).normalized()
	Telegraph.play_slot("ashbrood_dive", "impact")
	_strafe.finish()
	_strafe = null
	if hit:
		player.knockback((_strafe_to - _strafe_from).orthogonal() * (1.0 if (player.global_position - _strafe_from).cross(_strafe_to - _strafe_from) < 0.0 else -1.0), 60.0)
		player.chill(Tuning.kl_ashbrood_strafe_warmth * dmg_level_mult())

func _fly_strafe(delta: float) -> void:
	_strafe_t = maxf(0.0, _strafe_t - delta)
	var k := 1.0 - _strafe_t / maxf(Tuning.kl_ashbrood_strafe_travel, 0.05)
	global_position = _strafe_from.lerp(_strafe_to, k)
	# Cold embers at even steps along the pass (the first one past its start).
	var n := maxi(1, Tuning.kl_ashbrood_strafe_embers)
	var dropped := n - _embers_left
	if _embers_left > 0 and k >= (float(dropped) + 0.5) / float(n):
		_embers_left -= 1
		var e := ColdEmber.new()
		e.position = _strafe_from.lerp(_strafe_to, (float(dropped) + 0.5) / float(n))
		get_parent().add_child(e)
		embers_dropped += 1
	if _strafe_t <= 0.0:
		_ash_t = 0.3
		_recover_t = Tuning.kl_ashbrood_recover * _m()
		_after("strafe")

## Phase 2: Wicklings called from the dark, kl_ashbrood_call_dist from the bowl on the keeper's side, after spawn
## glows (a cue, not a hit). Not while plenty of its brood are still about.
func _tick_call(delta: float, player: Node2D) -> void:
	if phase != 2:
		return
	if _call:
		_call.tick(delta)
		if _call.done():
			for p in _call.points:
				var w := Wickling.new()
				w.bold = true
				w.summoned = true
				w.level = Tuning.kl_ashbrood_add_level
				w.position = p
				w.fade_in()
				get_parent().add_child(w)
			_call.finish()
			_call = null
		return
	_call_t -= delta
	if _call_t > 0.0:
		return
	_call_t = Tuning.kl_ashbrood_call_period
	var about := 0
	for f in get_tree().get_nodes_in_group("wickling"):
		if f.summoned and not f._dead:
			about += 1
	if about >= 3:
		return
	var home := waylamp.global_position if waylamp else global_position
	var side := (player.global_position - home).angle()
	_call = Telegraph.begin(self, Telegraph.SPAWN, "ashbrood_adds", Tuning.kl_ashbrood_add_tell, false)
	_call.radius = 14.0
	for i in Tuning.kl_ashbrood_call_count:
		var a := side + (float(i) - float(Tuning.kl_ashbrood_call_count - 1) * 0.5) * 0.7
		_call.points.append(walkable_near(home + Vector2.from_angle(a) * Tuning.kl_ashbrood_call_dist))
	Telegraph.arm(_call, get_tree())
	_began("call")

## Lets go of the lamp it sat on: snuffed for kl_snuff_sec (snuff = true), or just let go (a faint, its death).
func _release_lamp(snuff: bool) -> void:
	if is_instance_valid(_target_lamp) and _target_lamp.smother_by == self:
		_target_lamp.smother_by = null
		if snuff:
			_target_lamp.snuff(Tuning.kl_snuff_sec)

func _nearest_lit_lamp() -> Lantern:
	var best: Lantern = null
	var best_d := INF
	var home := waylamp.global_position if waylamp else global_position
	for lamp in get_tree().get_nodes_in_group("lantern"):
		if not lamp.is_lit() or lamp.kind == "mirror" or (waylamp and lamp.global_position.distance_to(home) > ARENA):
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
	var base := Tuning.kl_ashbrood_hp
	if phase == 2:
		base = Tuning.kl_ashbrood_hp2
	elif phase >= 3:
		base = Tuning.kl_ashbrood_hp3
	return base * level_mult()

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
	_finish_all()
	_release_lamp(false)
	_puff = null
	_adds = null
	_dive = null
	_sweep = null
	_fly_t = 0.0
	_sit_t = 0.0
	_dark_sit = false
	_phase_t = 0.0
	_ember_t = 0.0
	_ember_cd = 0.0
	_idle_t = 0.0
	_puff_t = 2.0 if phase == 1 else 99.0
	_wave_t = 3.0
	_dive_t = 2.0
	_bolt_t = 1.2
	_sweep_cd = 0.0
	_wave = null
	_strafe = null
	_call = null
	_strafe_t = 0.0
	_front_t = 0.0
	_recover_t = 0.0
	_plan.clear()
	_move = ""
	_dive_t = 1.0
	_since_dive = 1
	_call_t = 6.0
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
		_dive_t = 1.0   # it dives soon after it rises
		_idle_t = 0.0
		_ember_t = 0.0
		_finish_all()
		_puff = null
		_adds = null
		_sweep = null
		_phase_t = Tuning.kl_ashbrood_phase_pause   # it rises out of the bowl: no attacks, no damage
		Telegraph.play_slot("ashbrood_phase", "windup")
		Sfx.play("unlock", -4.0)
		_dive_t = 1.0
		_since_dive = 1
		_plan.clear()
		_move = ""
		var hud := get_tree().get_first_node_in_group("hud")
		if hud:
			hud._show_toast("The Ashbrood leaves the bowl.", 3.0)
		return
	if phase == 2:
		# Phase 3, "last of the brood" (M2): it rises again, wings cracked, and goes back to guard its ember.
		phase = 3
		_release_lamp(false)
		hp = phase_hp()
		hp_max = hp
		shell = phase_shell()
		shell_max = shell
		_since_beam = 0.0
		_oil_step_given = false
		_idle_t = 0.0
		_finish_all()
		_puff = null
		_dive = null
		_wave = null
		_strafe = null
		_call = null
		_bolts.clear()
		_fly_t = 0.0
		_strafe_t = 0.0
		_sit_t = 0.0
		_dark_sit = false
		_recover_t = 0.0
		_plan.clear()
		_move = ""
		_dive_t = 0.4
		_phase_t = Tuning.kl_ashbrood_phase_pause
		Telegraph.play_slot("ashbrood_phase", "windup")
		Sfx.play("unlock", -2.0, 0.0, 0.8)
		var hud3 := get_tree().get_first_node_in_group("hud")
		if hud3:
			hud3._show_toast("The last of the brood. Its wings crack: the ember shows through.", 3.5)   # DRAFT (STORY §17)
		return
	_release_lamp(false)
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
	elif _sweep:
		squash = 1.0 + 0.2 * _sweep.progress()   # wings spread wide
	elif _dive:
		squash = 1.0 - 0.12 * _dive.progress()   # it crouches, wings back
	if _adds:
		eye_y = -11.0   # head up: calling its brood
	if not (_art and _art.showing()):
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
	# The wing sweep: wings flung wide (cold), over the circle the Telegraph draws.
	if _sweep:
		var k := _sweep.progress()
		for side in [-1.0, 1.0]:
			draw_line(Vector2(side * 20.0, -6.0), Vector2(side * (34.0 + 40.0 * k), -14.0 + 10.0 * k), Color(Telegraph.COLD, 0.7), 3.0)
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
	# The pass: an ash streak behind it, low.
	if _strafe_t > 0.0:
		var back2 := to_local(_strafe_from).limit_length(110.0)
		draw_line(Vector2.ZERO, back2, Color(0.4, 0.48, 0.6, 0.5), 14.0)
		draw_line(Vector2.ZERO, back2 * 0.6, Color(0.6, 0.7, 0.82, 0.6), 6.0)
	# The ash wave's front running its lane (cold ash, as wide as the lane).
	if _front_t > 0.0:
		var k2 := 1.0 - _front_t / maxf(Tuning.kl_ashbrood_ash_wave_travel, 0.01)
		var a := to_local(_front_from)
		var b := to_local(_front_to)
		var d2 := (b - a).normalized()
		var at := a.lerp(b, k2)
		var side := d2.orthogonal() * Tuning.kl_ashbrood_ash_wave_half
		draw_line(at - side, at + side, Color(0.62, 0.7, 0.8, 0.85), 10.0)
		draw_line(at - side - d2 * 14.0, at + side - d2 * 14.0, Color(0.4, 0.48, 0.6, 0.5), 16.0)
		draw_line(a, at, Color(0.36, 0.42, 0.52, 0.25), Tuning.kl_ashbrood_ash_wave_half * 2.0)
	# Phase 3: cracked wings (pale cold cracks; over the bowl the ember's warm glow shows through them).
	if phase >= 3 and _phase_t <= 0.0:
		var over := extra_light_source() != Vector2.INF
		var cc := Color(1.0, 0.72, 0.38, 0.75) if over else Color(0.74, 0.84, 0.95, 0.7)
		var j := sin(_pulse * 31.0) * 1.2   # frantic: it never quite settles
		for side2 in [-1.0, 1.0]:
			draw_polyline(PackedVector2Array([Vector2(side2 * 8.0, -16.0 + j), Vector2(side2 * 16.0, -6.0), Vector2(side2 * 12.0, 2.0), Vector2(side2 * 22.0, 10.0 + j)]), cc, 1.5)
			draw_polyline(PackedVector2Array([Vector2(side2 * 18.0, -14.0), Vector2(side2 * 24.0, -4.0 + j)]), cc, 1.0)
	draw_arc(Vector2(0, 38), 10.0, -PI / 2.0, -PI / 2.0 + TAU * float(phase) / 3.0, 20, Color(0.75, 0.84, 0.96, 0.8), 3.0)
