class_name Foe
extends Node2D
## PROTOTYPE (Keeper's Light). Anything of the dark that the keeper's light can burn: Wicklings,
## Spitwicks, Clinkers, nests and the Ashbrood. All of them are in the group "foe", which is what
## the beam and the burst look through.
## Shared here: hp and shell, how a hit lands, being thrown back or stunned, a shell growing back,
## what is left behind, and the light senses.

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
var wick_value := 1
var summoned := false           # hatched by a nest or called by a guardian: worth Tuning.kl_wick_summoned
var wick_key := ""              # pack members: wick is paid once per member, even if a faint brings the pack back
var knock_weight := 1.0         # how far the burst throws it (1 = the full distance)
var _knock_v := Vector2.ZERO
var _knock_t := 0.0
var _clink := 0.0               # > 0: something just glanced off the shell
var _impact_t := 0.0
var _burning := 0.0             # > 0: light just burned it
var _linger_t := 0.0
var _stun_t := 0.0
var _since_beam := 99.0         # seconds since a beam last touched it
var _fading := 0.0
var _dead := false

func _enter_tree() -> void:
	add_to_group("foe")

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

## Lights strong enough to push small dark back: burning lanterns that aren't dying, and lit WayLamps.
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
	var best := 0.0
	for i in LightSense.nodes.size():
		if LightSense.healthy[i] == 0 or LightSense.nodes[i] == ignore:
			continue
		var r := LightSense.radius[i]
		if r > 0.0:
			best = maxf(best, 1.0 - LightSense.pos[i].distance_to(p) / r)
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w == ignore or not w.is_lit():
			continue
		var r: float = w.get_light_radius()
		if r > 0.0:
			best = maxf(best, 1.0 - w.global_position.distance_to(p) / r)
	return best

## The way out of healthy light from a point (zero when outside it).
func repel_at(p: Vector2) -> Vector2:
	LightSense.refresh(get_tree())
	var push := Vector2.ZERO
	for i in LightSense.nodes.size():
		if LightSense.healthy[i] == 0:
			continue
		push += _repel_one(p, LightSense.pos[i], LightSense.radius[i])
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.is_lit():
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
	var best := 0.0
	for m in get_tree().get_nodes_in_group("mirror"):
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

# --- Damage --------------------------------------------------------------------

func body_radius() -> float:
	return 10.0

func is_stunned() -> bool:
	return _stun_t > 0.0

## Damage from a source: "beam" (the keeper's beam or a mirror beam), "burst", "core", "ward" or "".
## A shell takes beam damage first and turns everything else aside.
func hurt(amount: float, scare: bool = true, source: String = "") -> void:
	if _dead:
		return
	since_hurt = 0.0
	if source == "beam":
		if _beam_flash_cd <= 0.0:
			_flash = 0.06
			_beam_flash_cd = 0.16
	else:
		_flash = 0.1
	if source == "beam":
		_since_beam = 0.0
		if Progress.has_combat_upgrade("tight_focus") and shell > 0.0:
			amount *= Tuning.kl_focus_shell_mult
		if Progress.has_combat_upgrade("lingering_burn"):
			_linger_t = Tuning.kl_linger_duration
	if shell > 0.0:
		if source != "beam":
			_clink = 0.2
			if _impact_t <= 0.0:
				Sfx.play("ui_tick", -18.0, 0.1)
				_impact_t = 0.3
			return
		shell -= amount
		_burning = 0.3
		if shell > 0.0:
			return
		amount = -shell
		shell = 0.0
		_on_shell_cracked()
	hp -= amount
	_burning = 0.3
	_on_hurt(scare, source)
	if source != "beam" and _impact_t <= 0.0:
		Sfx.play("ui_tick", -20.0, 0.12)
		_impact_t = 0.3
	if hp <= 0.0:
		_die()

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
	self_modulate = Color(2.6, 2.4, 2.0) if _flash > 0.0 else Color.WHITE
	_burning = maxf(0.0, _burning - delta)
	_impact_t = maxf(0.0, _impact_t - delta)
	_clink = maxf(0.0, _clink - delta)
	_stun_t = maxf(0.0, _stun_t - delta)
	_since_beam += delta
	if _linger_t > 0.0 and not _dead:
		_linger_t = maxf(0.0, _linger_t - delta)
		hp -= Tuning.kl_linger_dps * delta
		if hp <= 0.0:
			_die()
			return
	if _knock_t > 0.0:
		_knock_t -= delta
		global_position += _knock_v * delta
	if shell_regrows and shell > 0.0 and shell < shell_max and _since_beam >= Tuning.kl_shell_regrow_wait:
		shell = minf(shell_max, shell + Tuning.kl_shell_regrow_per_sec * delta)
	if _dead or is_queued_for_deletion():
		return
	# Every ordinary foe is burned by a lantern's bright core; only Wicklings can drink a mirror beam.
	# Elites and guardians don't care about lanterns at all (owner, 2026-11-27).
	var ignores_lanterns: bool = (self is Wickling and self.elite) or self is Clinker or self is Ashbrood
	if not ignores_lanterns:
		LightSense.refresh(get_tree())
		for i in LightSense.nodes.size():
			if LightSense.lit[i] == 0:
				continue
			var radius := LightSense.radius[i]
			if radius > 0.0 and global_position.distance_to(LightSense.pos[i]) < radius * (1.0 - Tuning.wick_core):
				var core_dps := Tuning.kl_nest_core_dps if self is WickNest else Tuning.wick_light_burn
				if Progress.has_combat_upgrade("hot_core"):
					core_dps *= Tuning.kl_hot_core_mult
				hurt(core_dps * delta, false, "core")
				break
	if _dead or is_queued_for_deletion():
		return
	if not (self is Wickling):
		for mirror in get_tree().get_nodes_in_group("mirror"):
			var beam_strength: float = mirror.beam_level_at(global_position)
			if beam_strength > 0.0:
				hurt(Tuning.wick_beam_burn * beam_strength * delta, false, "beam")
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
	if keeper and keeper.has_method("shake"):
		keeper.shake(0.25)
	if keeper and Progress.has_combat_upgrade("kindled_kills"):
		keeper.lamp_charge = minf(1.0, keeper.lamp_charge + Tuning.kl_kindled_kill_charge)
	Engine.time_scale = 0.08
	get_tree().create_timer(0.045, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	if foe_id != "":
		if Progress.cleared.has(foe_id):
			queue_free()
			return
		Progress.cleared[foe_id] = true
	Progress.add_wick(wick_earned())
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

## Wick this kill pays (balance pass): summoned Wicklings pay little or nothing, and a pack member pays once.
func wick_earned() -> int:
	if summoned:
		return Tuning.kl_wick_summoned
	if wick_key != "":
		if Progress.cleared.has(wick_key):
			return 0
		Progress.cleared[wick_key] = true
	return wick_value

## What it leaves: by default one ember worth a little fuel, and sometimes a bit of scrap.
func _drop() -> void:
	drop_embers(1, Tuning.wick_scrap_chance)

## Drops land on the fog layer (our parent) so they glow through the dark.
func drop_embers(embers: int, scrap_chance: float) -> void:
	for i in embers:
		var e := Ember.new()
		e.position = walkable_near(global_position + (Vector2.ZERO if i == 0 else Vector2.from_angle(i * 2.4) * 14.0))
		get_parent().add_child(e)
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
