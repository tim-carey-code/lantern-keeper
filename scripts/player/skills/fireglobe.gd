class_name FireglobeSkill
extends Skill
## Fireglobe (slot 2 by default): the big lobbed fireball. It arcs to where you aim, 120-280 px out (the right
## stick's tilt, or the cursor), with a ground marker for its 0.6 s flight, bursts (8 in 90 px, no shells) and
## leaves burning ground (2 dps for 3 s). 0.3 charge, 5 s cooldown.

func _init() -> void:
	id = "fireglobe"

func title() -> String:
	return "Fireglobe"

func blurb() -> String:
	return "A big fireball, lobbed where you aim. It bursts and leaves the ground burning."

func cost() -> float:
	return Tuning.kl_fireglobe_cost

func cooldown() -> float:
	return Tuning.kl_fireglobe_cd

func press() -> bool:
	if not can_fire() or FireBolts.inst == null:
		return false
	spend()
	var k := keeper()
	combat.update_aim(Vector2.ZERO, true)
	var to: Vector2 = combat.globe_target()
	var from: Vector2 = k.global_position + Vector2(0, -10)
	FireBolts.inst.throw_globe(from, to)
	FireFx.cast_flare(from, (to - from).normalized(), true)
	combat.cast_cue("lob", (to - from).normalized())
	Sfx.play("pickup_lantern", -10.0, 0.15)
	return true
