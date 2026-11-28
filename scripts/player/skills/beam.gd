class_name BeamSkill
extends Skill
## The Beam (optional; slot 3 at level 1 until Lance arrives): the built beam, channelled while held.
## 7.5 hp/s, 0.3 charge a second, 240 x 24 px, walk 70%. Wears shells fully. No charge from light while it
## is on (the base regen goes on). The old "Trim the wick" beam cards still apply (they move in M2).

func _init() -> void:
	id = "beam"

func title() -> String:
	return "The Beam"

func blurb() -> String:
	return "Hold for a steady beam. It burns all along its line and wears shells down, but you walk slower and light won't fill your lamp while it's on."

func held() -> bool:
	return true

func cost() -> float:
	var mult := 1.0
	if Progress.has_pick("deep_tank"):
		mult = Tuning.kl_deep_tank_mult
		SkillTree.mark("deep_tank")
	return Tuning.kl_beam_cost * mult

func short_of_charge() -> bool:
	var k := keeper()
	return k != null and k.lamp_charge <= Tuning.kl_min_charge

func hold(delta: float, down: bool) -> void:
	var k := keeper()
	combat.beaming = down and k != null and k.lamp_charge > Tuning.kl_min_charge
	if combat.beaming:
		k.lamp_charge = maxf(0.0, k.lamp_charge - cost() * delta)
		combat.burn_along_beam(delta)
