class_name LanceSkill
extends Skill
## Lance (slot 3 from level 2): a fast piercing bolt, the shell-breaker. 5 damage that wears shells fully,
## through 3 foes, 700 px/s, 360 px. 0.2 charge, 0.5 s cooldown. Aim assist on pad.

func _init() -> void:
	id = "lance"

func title() -> String:
	return "Lance"

func blurb() -> String:
	return "A fast bolt that passes through three foes. It breaks shells."

func cost() -> float:
	return Tuning.kl_lance_cost

func cooldown() -> float:
	return Tuning.kl_lance_cd

var charge_t := 0.0              # Held lance (M2): how long the button has been held
var _was_down := false

## Held lance makes it a held skill: hold kl_held_lance_time, let go, and it flies at double damage through
## everything. A shorter press fires a normal Lance on release.
func held() -> bool:
	return Progress.has_pick("held_lance")

func charged() -> bool:
	return charge_t >= Tuning.kl_held_lance_time

func hold(delta: float, down: bool) -> void:
	if down:
		if not _was_down:
			charge_t = 0.0
		if can_fire():
			charge_t += delta
	elif _was_down:
		var full := charged()
		charge_t = 0.0
		_was_down = false
		_fire(full)
		return
	_was_down = down

func press() -> bool:
	return _fire(false)

func _fire(full: bool) -> bool:
	if not can_fire() or FireBolts.inst == null:
		return false
	spend()
	combat.update_aim(Vector2.ZERO, true)
	var dir: Vector2 = combat.assisted(combat.aim_for(Tuning.kl_lance_speed), Tuning.kl_lance_range)
	var from := muzzle(dir)
	FireBolts.inst.fire_lance(from, dir, full)
	FireFx.cast_flare(from, dir, true)
	combat.cast_cue("thrust", dir)
	Sfx.play("ui_tick", -12.0, 0.2)
	var k := keeper()
	if k and k.has_method("shake"):
		k.shake(Tuning.kl_shake_lance_cast)   # a little recoil
	return true
