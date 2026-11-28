class_name LampfireSkill
extends Skill
## Lampfire, the basic attack (slot 1, held): a fireball of light, one every kl_lampfire_period while held.
## It bursts on impact with a 40 px splash, an impact flash and a light pop that clears fog (FireBolts).
## Free; each hit gives back a little charge. Aim assist on pad (KeeperCombat.assisted).

var _t := 0.0                    # time to the next bolt while held
var fired := 0                   # bolts thrown (tests)

func _init() -> void:
	id = "lampfire"

func title() -> String:
	return "Lampfire"

func blurb() -> String:
	return "Hold to throw fireballs of light. Each one bursts where it hits, and every hit gives back a little charge."

func kind() -> int:
	return Kind.BASIC

func held() -> bool:
	return true

func cooldown() -> float:
	return 0.0

func facts() -> String:
	return "free, a bolt every %s s, +%s charge a hit" % [num(Tuning.kl_lampfire_period), num(Tuning.kl_lampfire_charge)]

func hold(delta: float, down: bool) -> void:
	_t = maxf(0.0, _t - delta)
	if down and _t <= 0.0:
		fire()
		_t = maxf(0.01, Tuning.kl_lampfire_period)

## Throws one bolt along the (assisted) aim. Public for tests and the bench.
## M2 picks: Twin (two bolts in a V, each x kl_twin_mult), Comet (every kl_comet_every-th bolt is big).
func fire() -> void:
	var bolts := FireBolts.inst
	if bolts == null:
		return
	combat.update_aim(Vector2.ZERO, true)
	var dir: Vector2 = combat.assisted(combat.aim, Tuning.kl_lampfire_range)
	var from := muzzle(dir)
	fired += 1
	var big := Progress.has_pick("comet") and Tuning.kl_comet_every > 0 and fired % Tuning.kl_comet_every == 0
	if Progress.has_pick("twin"):
		for side in [-1.0, 1.0]:
			var b: FireBolts.Bolt = bolts.fire_lampfire(from, dir.rotated(deg_to_rad(Tuning.kl_twin_spread_deg) * side))
			b.mult = Tuning.kl_twin_mult
			b.big = big
	else:
		var b: FireBolts.Bolt = bolts.fire_lampfire(from, dir)
		b.big = big
	FireFx.cast_flare(from, dir)
	combat.cast_cue("throw", dir)
	Sfx.play("ui_tick", -24.0, 0.3)
