class_name Foe
extends Node2D
## PROTOTYPE (Keeper's Light). Anything of the dark that the keeper's light can burn: Wicklings,
## Spitwicks, Clinkers, nests and the Ashbrood. All of them are in the group "foe", which is what
## the beam and the burst look through.
## Shared here: hp and shell, how a hit lands, being thrown back or stunned, a shell growing back,
## what is left behind, and the light senses.
## M1a: every foe carries a small hurtbox (an Area2D on HURT_LAYER) so the keeper's fire can find it with
## shape queries (brief §7). The shell rule is GAME_PLAN §4.5 (shell_factor). Big hits freeze the foe for a
## moment (per-target hit-stop, instead of freezing the whole game). Summoned foes drop nothing.

const HURT_LAYER := 1 << 4      # physics layer 5: foe hurtboxes, found by the keeper's fire

var hp := 0.0
var hp_max := 0.0               # set from hp the first time it ticks (for health bars)
var foe_name := ""              # shown over its health bar
var since_hurt := 99.0          # seconds since anything hurt it (bars show for a while after)
var _flash := 0.0               # > 0: flashes white (a hit landed)
var _beam_flash_cd := 0.0
var shell := 0.0                # only a beam (the keeper's or a mirror's) wears it down
var shell_max := 0.0
var shell_regrows := false      # an unbroken shell grows back once it has been out of every beam for a while
var foe_id := ""                # fixed foes (the Clinker, nests): marked in Progress.cleared when burned away
var pack_id := ""               # fixed pack membership, used to keep a beaten pack beaten
var pack_slot := -1             # which member of its pack it is (EnemyPack keeps beaten members dead after a faint)
var wick_value := 1             # base wick; what a kill pays is scaled by level and the level gap (Progress.kill_wick)
var level := 1                  # foe level: set by its pack, nest or tuning.gd; hatched and called ones take their maker's
var summoned := false           # hatched by a nest or called by a guardian (pays like any other foe of its level)
var knock_weight := 1.0         # how far the burst throws it (1 = the full distance)
var _knock_v := Vector2.ZERO
var _knock_t := 0.0
var _clink := 0.0               # > 0: something just glanced off the shell
var _impact_t := 0.0
var _burning := 0.0             # > 0: light just burned it
var _linger_t := 0.0
var _stun_t := 0.0
var _hitstop_t := 0.0           # > 0: frozen by a big hit (counts as stunned)
var _ignite_t := 0.0            # > 0: set alight (Hearth ring): burns at _ignite_dps
var _ignite_dps := 0.0
var _num_acc := 0.0             # damage from steady sources (beam, burning) waiting to show as one number
var _num_t := 0.0
var _oil_step_given := false    # mid-boss and guardian: this phase's oil has dropped
var oil_step := false           # drops 1 oil when its health falls past Tuning.kl_boss_oil_step (Clinker, Ashbrood)
var hurtbox: Area2D
var _since_beam := 99.0         # seconds since anything that wears a shell last touched it
var _fading := 0.0
var _dead := false

func _enter_tree() -> void:
	add_to_group("foe")

## Foe scaling (M1b, GAME_PLAN §4.6): health and shell grow kl_foe_hp_per_level (12%) a level over 1.
func level_mult() -> float:
	return 1.0 + Tuning.kl_foe_hp_per_level * float(maxi(1, level) - 1)

var _scaled := false

## Foe damage by level (M1c damage fix): its hits, spit and touch grow kl_foe_dmg_per_level (8%) a level over 1.
func dmg_level_mult() -> float:
	return 1.0 + Tuning.kl_foe_dmg_per_level * float(maxi(1, level) - 1)

## Scales the health and shell its _ready() set from tuning.gd by its level, once. Runs after the kind's own
## _ready() (a script's NOTIFICATION_READY comes after _ready), so the level set by its pack, nest or tuning
## counts. Guardians that refill their health per phase use level_mult() themselves.
func _apply_level_scaling() -> void:
	if _scaled:
		return
	_scaled = true
	var m := level_mult()
	hp *= m
	shell *= m
	shell_max *= m
	if hp_max > 0.0:
		hp_max = hp

## The hurtbox is made once the foe is ready (body_radius() may depend on fields set before add_child).
func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		_apply_level_scaling()
	if what == NOTIFICATION_READY and hurtbox == null:
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		hurtbox.monitoring = false
		hurtbox.monitorable = true
		hurtbox.collision_layer = HURT_LAYER
		hurtbox.collision_mask = 0
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = body_radius()
		shape.shape = circle
		hurtbox.add_child(shape)
		add_child(hurtbox)

# --- Senses ------------------------------------------------------------------

var _player_ref: Node2D
var _fog_ref: FogGrid

func _player() -> Node2D:
	if _player_ref == null or not is_instance_valid(_player_ref) or not _player_ref.is_in_group("player"):
		_player_ref = get_tree().get_first_node_in_group("player") as Node2D
	return _player_ref

func _fog() -> FogGrid:
	if _fog_ref == null or not is_instance_valid(_fog_ref):
		_fog_ref = get_tree().get_first_node_in_group("fog_grid") as FogGrid
	return _fog_ref

## 0 outside any lantern light, up to 1 at a lantern's centre (mirror glows don't count).
func lantern_level_at(p: Vector2) -> float:
	LightSense.refresh(get_tree())
	var best := 0.0
	for i in LightSense.radius.size():
		var r := LightSense.radius[i]
		if r <= 0.0:
			continue
		best = maxf(best, 1.0 - LightSense.pos[i].distance_to(p) / r)
	return best

## Lights strong enough to push small dark back: lit lanterns that keep small dark out, and lit WayLamps.
func _healthy_lights() -> Array:
	LightSense.refresh(get_tree())
	var out := []
	for i in LightSense.nodes.size():
		if LightSense.healthy[i] == 1:
			out.append(LightSense.nodes[i])
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.is_lit():
			out.append(w)
	return out

## How deep a point sits in healthy light (0 outside). Optionally ignoring one light.
func healthy_level_at(p: Vector2, ignore: Node = null) -> float:
	LightSense.refresh(get_tree())
	return LightSense.healthy_at(p, ignore)

## The way out of healthy light from a point (zero when outside it).
func repel_at(p: Vector2) -> Vector2:
	LightSense.refresh(get_tree())
	var push := Vector2.ZERO
	for i in LightSense.nodes.size():
		if LightSense.healthy[i] == 0:
			continue
		push += _repel_one(p, LightSense.pos[i], LightSense.radius[i])
	for w in LightSense.waylamps:
		if is_instance_valid(w) and w.is_lit():
			push += _repel_one(p, w.global_position, w.get_light_radius())
	return push

func _repel_one(p: Vector2, c: Vector2, r: float) -> Vector2:
	if r <= 0.0:
		return Vector2.ZERO
	var v: Vector2 = p - c
	var d := v.length()
	if d < r:
		return (v / maxf(d, 0.001)) * (1.0 - d / r + 0.2)
	return Vector2.ZERO

## How deep a point sits in any mirror beam (0 outside). The dark can't sense beams coming.
func beam_level_at(p: Vector2) -> float:
	LightSense.refresh(get_tree())
	var best := 0.0
	for m in LightSense.mirrors:
		if is_instance_valid(m) and m.is_inside_tree():
			best = maxf(best, m.beam_level_at(p))
	return best

## Overall light at a point: lantern light, or a beam (which counts as harsh as a core).
func light_level_at(p: Vector2) -> float:
	return maxf(lantern_level_at(p), beam_level_at(p) * 0.8)

## A step that keeps small dark out of healthy light: pushed back out if it is inside, stopped at the edge.
func step_outside_light(step: Vector2, delta: float) -> Vector2:
	if healthy_level_at(global_position) > 0.0:
		return repel_at(global_position).normalized() * Tuning.wick_repel_speed * delta
	if healthy_level_at(global_position + step) > 0.0:
		return Vector2.ZERO
	return step

# --- Light states (M1c, PLAN_LANTERNS §2.1) ---------------------------------------------
## DARK: outside every light (takes x kl_dark_dmg_mult; its shell can't break). DIM: only in the keeper's hand-lamp
## light (as before). LIT (exposed): in a lamp's light (x kl_lit_dmg_mult; shells wear x kl_lit_shell_mult). A foe
## stays exposed kl_exposed_linger after it leaves light. Nests skip the rule (only cores hurt them).
enum { DARK, DIM, LIT }
## Steady lamp damage skips the light rule (core burns stay at 2 hp/s): lamp cores, the brave ones' light burn
## and mirror beams.
const LIGHT_EXEMPT := ["core", "light", "mirror"]

var light_state := DIM
var light_from := Vector2.INF   # where the light that exposes it comes from (its warm rim faces it)
var _exposed_t := 0.0
var _was_exposed := false
var _light_frame := -1          # the frame its light state was last worked out (performance: hits reuse it)
var _light_epoch := -1
var _dark_tipped := false      # this foe has asked for the "dark" tip once (Story shows it once anyway)
var _light_acc := 0.0           # time since its light state was last worked out in tick_foe
const LIGHT_EVERY := 3          # performance: tick_foe works its light out every 3rd frame (staggered per foe)

## Nests skip the whole rule.
func light_exempt() -> bool:
	return false

## The Ashbrood: dim counts as dark (kl_ashbrood_needs_light).
func needs_light() -> bool:
	return false

## Works out its light state (once a frame in tick_foe; again on each hit, with no time passing).
func update_light_state(delta: float) -> int:
	_light_frame = Engine.get_process_frames()
	_light_epoch = LightSense._epoch
	if light_exempt():
		light_state = DIM
		return light_state
	LightSense.refresh(get_tree())
	var src := extra_light_source()
	if src == Vector2.INF:
		src = LightSense.lit_source(global_position)
	if src != Vector2.INF:
		_exposed_t = Tuning.kl_exposed_linger
		light_from = src
		if not _was_exposed:
			_was_exposed = true
			Telegraph.play_slot("foe", "exposed")
	else:
		_exposed_t = maxf(0.0, _exposed_t - delta)
	if _exposed_t > 0.0:
		light_state = LIT
		return light_state
	_was_exposed = false
	var k := _player()
	if k and k.has_method("get_light_radius") and k.global_position.distance_to(global_position) <= k.get_light_radius():
		light_state = DIM
	else:
		light_state = DARK
	return light_state

## Its light state now: the one tick_foe worked out this frame, else worked out again (performance, M1c review:
## burning ground and steady sources hit every foe every frame). A lamp lit, snuffed or flaring (LightSense.bump)
## makes it work it out again.
func light_now() -> int:
	if Engine.get_process_frames() - _light_frame >= LIGHT_EVERY or _light_epoch != LightSense._epoch:
		update_light_state(0.0)
	return light_state

## Light that exposes this foe besides lamps (the Ashbrood's stirred ember), or Vector2.INF.
func extra_light_source() -> Vector2:
	return Vector2.INF

func is_exposed() -> bool:
	return light_state == LIT

## The state that sets its numbers: for the Ashbrood, dim is dark.
func effective_light() -> int:
	if light_exempt():
		return DIM
	if light_state == DIM and needs_light() and Tuning.kl_ashbrood_needs_light:
		return DARK
	return light_state

## What a hit from `source` does to its health in its light now.
func light_dmg_mult(source: String, st: int = -1) -> float:
	if light_exempt() or source in LIGHT_EXEMPT:
		return 1.0
	match effective_light() if st < 0 else st:
		DARK:
			return Tuning.kl_dark_dmg_mult
		LIT:
			return Tuning.kl_lit_dmg_mult
	return 1.0

## How fast its shell wears in its light now.
func light_shell_mult(source: String, st: int = -1) -> float:
	if light_exempt() or source in LIGHT_EXEMPT:
		return 1.0
	return Tuning.kl_lit_shell_mult if (effective_light() if st < 0 else st) == LIT else 1.0

## The lowest its shell can wear to now: kl_dark_shell_floor in the dark (it can't break), else 0.
func shell_floor(source: String, st: int = -1) -> float:
	if light_exempt() or source in LIGHT_EXEMPT or shell_max <= 0.0:
		return 0.0
	return minf(Tuning.kl_dark_shell_floor, shell_max) if (effective_light() if st < 0 else st) == DARK else 0.0

## The body tint for its light (copied onto owner art): dark is cold and dim, eyes and rim only; lit and dim are
## full colour (lit adds a warm rim, drawn by FoeBars).
func light_tint() -> Color:
	if effective_light() == DARK and not light_exempt():
		return Color(0.36, 0.42, 0.58)
	return Color.WHITE

# --- Damage --------------------------------------------------------------------

func body_radius() -> float:
	return 10.0

func is_stunned() -> bool:
	return _stun_t > 0.0 or _hitstop_t > 0.0

## A big hit: frozen for a moment (it can't move or act), flashing. Only this foe, not the whole game.
func hit_stop(seconds: float) -> void:
	_hitstop_t = maxf(_hitstop_t, seconds)

## Set alight: burns for a while (it glances off a shell like any fire that isn't a hit).
func ignite(dps: float, seconds: float) -> void:
	_ignite_dps = maxf(_ignite_dps if _ignite_t > 0.0 else 0.0, dps)
	_ignite_t = maxf(_ignite_t, seconds)

## How much of a hit wears a shell (GAME_PLAN §4.5). Full: the Beam (yours or a mirror's) and Lance.
## Half: Lampfire's hit. None (it glances off): Fireglobe, Hearth ring, splash, burning ground, lamp cores.
static func shell_factor(source: String) -> float:
	match source:
		"beam", "lance", "mirror", "chain":
			return 1.0
		"lampfire":
			return 0.5
	return 0.0

## Sources that come in a steady stream: their damage numbers are summed and shown a few times a second.
const STEADY := ["beam", "burn", "ground", "core", "light", "linger", "mirror", "chain_burn"]

## Damage from a source: "lampfire", "lance", "splash", "fireglobe", "ground" (burning ground), "ring" (Hearth
## ring), "burn", "beam" (the keeper's beam or a mirror beam), "burst", "core", "light", "ward" or "".
## A shell takes what shell_factor allows first and turns the rest aside.
## M1c: its light state sets the numbers (light_dmg_mult, light_shell_mult, shell_floor), applied last, once.
func hurt(amount: float, scare: bool = true, source: String = "") -> void:
	if _dead:
		return
	# The light rule, worked out once a hit (performance: no helper calls on the hot path).
	var ruled := not (source in LIGHT_EXEMPT) and not light_exempt()
	var st := DIM
	if ruled:
		if Engine.get_process_frames() - _light_frame >= LIGHT_EVERY or _light_epoch != LightSense._epoch:
			update_light_state(0.0)
		st = light_state
		if st == DIM and Tuning.kl_ashbrood_needs_light and needs_light():
			st = DARK
	since_hurt = 0.0
	var flash := 0.1
	if source in STEADY:
		flash = 0.0
		if _beam_flash_cd <= 0.0:
			flash = 0.06
			_beam_flash_cd = 0.16
	_flash = maxf(_flash, flash)
	if source == "beam":
		if Progress.has_combat_upgrade("tight_focus") and shell > 0.0:
			amount *= Tuning.kl_focus_shell_mult
		if Progress.has_combat_upgrade("lingering_burn"):
			_linger_t = Tuning.kl_linger_duration
	var wear := shell_factor(source)
	if wear > 0.0:
		_since_beam = 0.0
	if st == DARK and ruled and not _dark_tipped:
		_dark_tipped = true
		Story.tip("dark")   # "In the dark they shrug off your fire. Bring light to them." (DRAFT)
	if shell > 0.0:
		if wear > 0.0:
			Story.tip("shell")   # the first fire that wears a shell (onboarding: the Post Lamp's guard)
		else:
			_glance()
			return
		var floor := minf(Tuning.kl_dark_shell_floor, shell_max) if st == DARK and ruled else 0.0
		if floor > 0.0 and shell <= floor + 0.0001:
			_glance()   # in the dark a worn shell holds: it clinks
			return
		var smult := Tuning.kl_lit_shell_mult if st == LIT and ruled else 1.0
		var worn := amount * wear * smult
		if floor > 0.0 and shell - worn < floor:
			worn = shell - floor
			_number(worn, source, true)
			shell = floor
			_burning = 0.3
			_glance()
			return
		_number(minf(worn, shell), source, true)
		shell -= worn
		_burning = 0.3
		if shell > 0.0:
			return
		amount = -shell / (wear * smult)   # what got through the shell goes on to its health
		shell = 0.0
		_on_shell_cracked()
		if amount <= 0.0:
			return
	if ruled:
		if st == DARK:
			amount *= Tuning.kl_dark_dmg_mult
		elif st == LIT:
			amount *= Tuning.kl_lit_dmg_mult
	_burning = 0.3
	_number(amount, source, false)
	_on_hurt(scare, source)
	if not (source in STEADY) and _impact_t <= 0.0:
		Sfx.play("ui_tick", -20.0, 0.12)
		_impact_t = 0.3
	_lose_hp(amount)

## Something glanced off: the clink (built).
func _glance() -> void:
	_clink = 0.2
	if _impact_t <= 0.0:
		Sfx.play("ui_tick", -18.0, 0.1)
		_impact_t = 0.3

## Every loss of health goes through here (hits, burns, lingering burn), so a boss's oil step can't be skipped.
func _lose_hp(amount: float) -> void:
	if hp_max <= 0.0:
		hp_max = hp   # hurt before its first tick
	hp -= amount
	_check_oil_step()
	if hp <= 0.0:
		_die()

## A damage number over the foe (DamageNumbers): at once for a hit, summed for steady damage.
func _number(amount: float, source: String, on_shell: bool) -> void:
	if amount <= 0.0 or not is_inside_tree():
		return
	if source in STEADY:
		_num_acc += amount
		return
	DamageNumbers.add(global_position + Vector2(0, -body_radius() - 10.0), amount, "shell" if on_shell else ("small" if source == "splash" else "hit"))

## Mid-boss and guardian: 1 oil as health falls past the oil step (once a phase; GAME_PLAN §5). A hit that
## takes it from above the step straight to 0 still drops it.
func _check_oil_step() -> void:
	if not oil_step or _oil_step_given or hp_max <= 0.0 or hp > hp_max * Tuning.kl_boss_oil_step:
		return
	_oil_step_given = true
	drop_oil(global_position + Vector2(0, body_radius() + 6.0))

## For each kind of foe: what a hit does besides the damage.
func _on_hurt(_scare: bool, _source: String) -> void:
	pass

func _on_shell_cracked() -> void:
	Sfx.play("ui_tick", -6.0, 0.5)

## Thrown back (by the burst): moves over a short moment instead of teleporting.
func knock(v: Vector2) -> void:
	var boost := Tuning.kl_heavy_flare_knock_mult if Progress.has_combat_upgrade("heavy_flare") else 1.0
	_knock_v = v * knock_weight * boost / 0.2
	_knock_t = 0.2

func stun(seconds: float) -> void:
	_stun_t = maxf(_stun_t, seconds)

## Timers every foe shares, the throw-back, and the shell growing back. Call first in _process.
func tick_foe(delta: float) -> void:
	if hp_max <= 0.0:
		hp_max = hp
	since_hurt += delta
	_flash = maxf(0.0, _flash - delta)
	_beam_flash_cd = maxf(0.0, _beam_flash_cd - delta)
	_hitstop_t = maxf(0.0, _hitstop_t - delta)
	_light_acc += delta
	if (Engine.get_process_frames() + get_instance_id()) % LIGHT_EVERY == 0 or _light_epoch != LightSense._epoch:
		update_light_state(_light_acc)
		_light_acc = 0.0
	# The white hit flash (built), held through a hit-stop; dimmer with "reduce flashes". Else its light's tint (M1c).
	self_modulate = Color.WHITE.lerp(Color(2.6, 2.4, 2.0), Settings.flash_mult()) if (_flash > 0.0 or _hitstop_t > 0.0) else light_tint()
	_burning = maxf(0.0, _burning - delta)
	_impact_t = maxf(0.0, _impact_t - delta)
	_clink = maxf(0.0, _clink - delta)
	_stun_t = maxf(0.0, _stun_t - delta)
	_since_beam += delta
	_num_t -= delta
	if _num_t <= 0.0:
		_num_t = 0.4
		if _num_acc >= 0.5:
			DamageNumbers.add(global_position + Vector2(0, -body_radius() - 10.0), _num_acc, "steady")
			_num_acc = 0.0
	if _ignite_t > 0.0 and not _dead:
		_ignite_t = maxf(0.0, _ignite_t - delta)
		hurt(_ignite_dps * delta, false, "burn")
		if _dead or is_queued_for_deletion():
			return
	if _linger_t > 0.0 and not _dead:
		_linger_t = maxf(0.0, _linger_t - delta)
		_num_acc += Tuning.kl_linger_dps * delta
		_lose_hp(Tuning.kl_linger_dps * delta)
		if _dead or is_queued_for_deletion():
			return
	if _knock_t > 0.0 and _hitstop_t <= 0.0:
		_knock_t -= delta
		global_position += _knock_v * delta
	if shell_regrows and shell > 0.0 and shell < shell_max and _since_beam >= Tuning.kl_shell_regrow_wait:
		shell = minf(shell_max, shell + Tuning.kl_shell_regrow_per_sec * delta)
	if _dead or is_queued_for_deletion():
		return
	# A lantern's bright core: what it does to this foe is the lantern's call (Lantern.core_dps_for; elites and
	# guardians don't care about lanterns at all, owner 2026-11-27). Only Wicklings can drink a mirror beam.
	LightSense.refresh(get_tree())
	var core_lamp := LightSense.core_lantern_at(global_position)
	if core_lamp:
		var core_dps: float = core_lamp.core_dps_for(self)
		if core_dps > 0.0:
			hurt(core_dps * delta, false, "core")
	if _dead or is_queued_for_deletion():
		return
	if not (self is Wickling):
		LightSense.refresh(get_tree())
		for mirror in LightSense.mirrors:
			if not is_instance_valid(mirror) or not mirror.is_inside_tree():
				continue
			var beam_strength: float = mirror.beam_level_at(global_position)
			if beam_strength > 0.0:
				hurt(Tuning.wick_beam_burn * beam_strength * delta, false, "mirror")
				break

## A held region is no place for the dark: it fades away, leaving nothing. True while it is fading.
func fade_if_held(delta: float) -> bool:
	var fog := _fog()
	if fog == null or not Progress.is_settled(fog.region_at(global_position)):
		return false
	_fading += delta
	modulate.a = clampf(1.0 - _fading / 1.2, 0.0, 1.0)
	if _fading >= 1.2:
		if foe_id != "":
			Progress.cleared[foe_id] = true
		queue_free()
	return true

## Burned away: leave something behind.
func _die() -> void:
	if _dead or is_queued_for_deletion():
		return
	_dead = true
	Sfx.play("relight", -14.0, 0.2)
	var keeper := _player()
	var big := hp_max >= Tuning.kl_elite_hp or shell_max > 0.0
	if keeper and keeper.has_method("shake"):
		keeper.shake(Tuning.kl_shake_kill_big if big else Tuning.kl_shake_kill)
	# Per-target hit-stop (GAME_PLAN §15): a big kill freezes the keeper for a moment, never the whole game
	# (the old global Engine.time_scale freeze would stutter at Lampfire's rate).
	if keeper and big and keeper.has_method("hit_stop"):
		keeper.hit_stop(Tuning.kl_hitstop)
	if keeper and Progress.has_combat_upgrade("kindled_kills"):
		keeper.lamp_charge = minf(Progress.charge_max(), keeper.lamp_charge + Tuning.kl_kindled_kill_charge)
	if is_inside_tree():
		FireFx.kill_burst(global_position, body_radius(), big)
		FoeSprite.leave_remnant(self)   # owner art: its death strip plays where it fell
	if foe_id != "":
		if Progress.cleared.has(foe_id):
			queue_free()
			return
		Progress.cleared[foe_id] = true
	var earned := wick_earned()
	var reduced := Progress.wick_gap_mult(level) < 1.0
	Progress.add_wick_f(earned)
	if earned >= 0.05 and get_parent():
		# The wick popup: gold at full value, dim grey when the level gap cut it.
		var txt := ("+%d wick" % roundi(earned)) if earned >= 0.95 else ("+%.1f wick" % earned)
		FloatText.spawn(get_parent(), global_position + Vector2(0, -26), txt, Color(0.62, 0.6, 0.56, 0.75) if reduced else Color(1.0, 0.82, 0.4))
	if Progress.has_combat_upgrade("catching"):
		var closest: Foe = null
		var closest_d := 61.0
		for other in get_tree().get_nodes_in_group("foe"):
			if other == self or other.is_queued_for_deletion():
				continue
			var d := global_position.distance_to(other.global_position)
			if d < closest_d:
				closest_d = d
				closest = other
		if closest:
			closest.hurt(Tuning.kl_catch_damage, false, "burn")
	_drop()
	queue_free()

## Wick this kill pays (level-gap pass, DESIGN §9): base wick grown by the foe's level, times the level-gap factor.
## Hatched, called and re-fought foes pay the same way; the gap is what stops farming.
func wick_earned() -> float:
	return Progress.kill_wick(wick_value, level)

## Name over the health bar, with the level: "Wickling Lv 2".
func bar_name() -> String:
	return "%s Lv %d" % [foe_name, level] if foe_name != "" else ""

## What it leaves: sometimes a bit of scrap (M1b: no more fuel embers; the ember's glow and magnet carry scrap
## and oil now). Lamp oil: a cleared pack's last foe always drops 1, an elite sometimes (GAME_PLAN §5).
## Summoned foes (nest hatchlings, a guardian's adds) drop nothing at all (GAME_PLAN §10, M10); they still pay wick.
func _drop() -> void:
	if summoned:
		return
	drop_scrap(Tuning.wick_scrap_chance)
	drop_pack_oil()

## Oil from a pack's last foe, and sometimes from an elite.
func drop_pack_oil() -> void:
	if summoned:
		return
	if pack_id != "" and is_last_of_pack():
		drop_oil(global_position + Vector2(-14, 8))
	if self is Wickling and self.elite and randf() < Tuning.kl_elite_oil_chance:
		drop_oil(global_position + Vector2(10, 12))

## True when no other member of its fixed pack is still alive.
func is_last_of_pack() -> bool:
	for f in get_tree().get_nodes_in_group("foe"):
		if f != self and f.pack_id == pack_id and not f._dead and not f.is_queued_for_deletion():
			return false
	return true

## A lamp-oil drop (an Ember of kind "oil"): walk over it to fill a flask.
func drop_oil(at: Vector2) -> void:
	if get_parent() == null:
		return
	var e := Ember.new()
	e.kind = "oil"
	e.position = walkable_near(at)
	get_parent().add_child(e)

## Drops land on the fog layer (our parent) so they glow through the dark.
func drop_scrap(scrap_chance: float) -> void:
	if randf() < scrap_chance:
		var s := Ember.new()
		s.kind = "scrap"
		s.position = walkable_near(global_position + Vector2(14, 6))
		get_parent().add_child(s)

## The dark floats over rock; its drops land on the nearest ground the keeper can walk on.
func walkable_near(p: Vector2) -> Vector2:
	var fog := _fog()
	if fog == null:
		return p
	var t := fog.tile_of(p)
	if fog.in_bounds(t) and fog.solid[fog.idx(t)] == 0:
		return p
	for r in range(1, 8):
		var best := Vector2.INF
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var q := t + Vector2i(dx, dy)
				if fog.in_bounds(q) and fog.solid[fog.idx(q)] == 0:
					var c := fog.tile_center(q)
					if best == Vector2.INF or c.distance_to(p) < best.distance_to(p):
						best = c
		if best != Vector2.INF:
			return best
	return p

## The pale shell ring, thinning as the beam wears it down, and the glint when something glances off.
func draw_shell(center: Vector2, radius: float) -> void:
	if shell > 0.0 and shell_max > 0.0:
		var k := clampf(shell / shell_max, 0.0, 1.0)
		draw_arc(center, radius, 0.0, TAU, 28, Color(0.64, 0.74, 0.83, 0.35 + 0.5 * k), 2.0 + 3.0 * k)
	if _clink > 0.0:
		draw_arc(center, radius + 3.0, -0.6, 0.6, 8, Color(1, 1, 1, _clink * 4.0), 2.0)
