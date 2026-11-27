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

func press() -> bool:
	if not can_fire() or FireBolts.inst == null:
		return false
	spend()
	combat.update_aim(Vector2.ZERO, true)
	var dir: Vector2 = combat.assisted(combat.aim, Tuning.kl_lance_range)
	var from := muzzle(dir)
	FireBolts.inst.fire_lance(from, dir)
	FireFx.cast_flare(from, dir, true)
	Sfx.play("ui_tick", -12.0, 0.2)
	var k := keeper()
	if k and k.has_method("shake"):
		k.shake(Tuning.kl_shake_lance_cast)   # a little recoil
	return true
