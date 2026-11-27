class_name HearthRingSkill
extends Skill
## Hearth ring (optional, self-cast: slot 4 only): the old burst, reworked. A ring of flame around the keeper
## that sets foes alight and pushes them a little. 2 damage and 1 dps for 2 s, 120 px, push 60 px, 4 s cooldown,
## 0.2 charge (kl_burst_*). No shell damage. The old burst cards (Heavy flare, Spill) still apply.

var last_hits := 0

func _init() -> void:
	id = "hearth_ring"

func title() -> String:
	return "Hearth ring"

func blurb() -> String:
	return "A ring of flame around you. It sets foes alight and pushes them back a little."

func kind() -> int:
	return Kind.SELF

func cost() -> float:
	return Tuning.kl_burst_cost

func cooldown() -> float:
	return Tuning.kl_spill_cd if Progress.has_combat_upgrade("spill") else Tuning.kl_burst_cd

func press() -> bool:
	return ring() >= 0

## The ring. Returns how many it hit, or -1 if it couldn't fire (cooldown or too little charge).
func ring() -> int:
	if not can_fire():
		return -1
	spend()
	var k := keeper()
	var center: Vector2 = k.global_position
	if k.has_method("shake"):
		k.shake(Tuning.kl_shake_ring)
	Sfx.play("relight", -8.0, 0.3)
	FireFx.blast(center + Vector2(0, -6), Tuning.kl_burst_radius, 0.3)
	var found: Array = FireBolts.inst.area(center, Tuning.kl_burst_radius) if FireBolts.inst else []
	var hit := 0
	for w in found:
		var v: Vector2 = w.global_position - center
		w.hurt(Tuning.kl_burst_dmg, true, "ring")
		if is_instance_valid(w) and not w.is_queued_for_deletion() and not w._dead:
			w.ignite(Tuning.kl_burst_burn_dps, Tuning.kl_burst_burn_time)
			w.knock((v.normalized() if v.length() > 0.5 else Vector2.RIGHT) * Tuning.kl_burst_knock)
			if Progress.has_combat_upgrade("heavy_flare"):
				w.stun(Tuning.kl_heavy_flare_stun)
		hit += 1
	if hit > 0 and Progress.has_combat_upgrade("spill"):
		k.lamp_charge = minf(1.0, k.lamp_charge + Tuning.kl_spill_charge * hit)
	last_hits = hit
	combat._burst_fx = 0.3
	return hit
