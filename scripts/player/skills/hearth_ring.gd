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
	return Tuning.kl_spill_cd if Progress.has_pick("spill") else Tuning.kl_burst_cd

func press() -> bool:
	return ring() >= 0

var rising_t := -1.0             # Rising ring (M2): > -1 while the second ring rolls out
var _rising_at := Vector2.ZERO
var _rising_hit := {}

## The ring. Returns how many it hit, or -1 if it couldn't fire (cooldown or too little charge).
## M2 picks: Heavy ring (push kl_heavy_ring_push and stun), Lasting ring (its ground burns), Spill (cooldown and
## charge), Warm ring (warmth per foe), Sunburst (8 Lampfire bolts), Crackle (strips shell), Rising ring (a second
## ring rolls out to kl_rising_ring_radius).
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
	var heavy := Progress.has_pick("heavy_ring")
	for w in found:
		var v: Vector2 = w.global_position - center
		if Progress.has_pick("crackle") and w.shell > 0.0:
			w.shell = maxf(w.shell_floor("lance"), w.shell - Tuning.kl_crackle_shell)   # Crackle: stripped off (not past the dark's floor)
			w._clink = 0.2
			SkillTree.mark("crackle")
			if w.shell <= 0.0:
				w._on_shell_cracked()
		w.hurt(Tuning.kl_burst_dmg * Progress.dmg_mult(), true, "ring")
		if is_instance_valid(w) and not w.is_queued_for_deletion() and not w._dead:
			w.ignite(Tuning.kl_burst_burn_dps * Progress.dmg_mult(), Tuning.kl_burst_burn_time)
			w.knock((v.normalized() if v.length() > 0.5 else Vector2.RIGHT) * (Tuning.kl_heavy_ring_push if heavy else Tuning.kl_burst_knock))
			if heavy:
				w.stun(Tuning.kl_heavy_flare_stun)
				SkillTree.mark("heavy_ring")
		hit += 1
	if hit > 0 and Progress.has_pick("spill"):
		SkillTree.mark("spill")
		k.lamp_charge = minf(Progress.charge_max(), k.lamp_charge + Tuning.kl_spill_charge * hit)
	if hit > 0 and Progress.has_pick("warm_ring"):
		SkillTree.mark("warm_ring")
		k.warmth = minf(Tuning.warmth_max, k.warmth + Tuning.kl_warm_ring_warmth * hit)
	if Progress.has_pick("lasting_ring") and FireBolts.inst:
		SkillTree.mark("lasting_ring")
		FireBolts.inst._ground(center, Tuning.kl_burst_radius, Tuning.kl_lasting_ring_time, Tuning.kl_lasting_ring_dps)
	if Progress.has_pick("sunburst") and FireBolts.inst:
		SkillTree.mark("sunburst")
		for i in Tuning.kl_sunburst_count:
			var a := TAU * float(i) / float(maxi(1, Tuning.kl_sunburst_count))
			FireBolts.inst.fire_side_bolt(center + Vector2(0, -10) + Vector2.from_angle(a) * 14.0, Vector2.from_angle(a))
	if Progress.has_pick("rising_ring"):
		rising_t = 0.0
		_rising_at = center
		_rising_hit = {}
		for w in found:
			_rising_hit[w.get_instance_id()] = true
	last_hits = hit
	combat._burst_fx = 0.3
	return hit

## The Rising ring rolls out from kl_burst_radius to kl_rising_ring_radius over kl_rising_ring_time, hitting each
## foe it passes once.
func tick(delta: float) -> void:
	super.tick(delta)
	if rising_t < 0.0 or FireBolts.inst == null:
		return
	rising_t += delta
	var r := rising_radius()
	for w in FireBolts.inst.area(_rising_at, r):
		if _rising_hit.has(w.get_instance_id()):
			continue
		_rising_hit[w.get_instance_id()] = true
		SkillTree.mark("rising_ring")
		w.hurt(Tuning.kl_rising_ring_dmg * Progress.dmg_mult(), true, "ring")
		if is_instance_valid(w) and not w._dead:
			w.ignite(Tuning.kl_burst_burn_dps * Progress.dmg_mult(), Tuning.kl_burst_burn_time)
	if rising_t >= Tuning.kl_rising_ring_time:
		rising_t = -1.0

func rising_radius() -> float:
	var k := clampf(rising_t / maxf(Tuning.kl_rising_ring_time, 0.01), 0.0, 1.0)
	return lerpf(Tuning.kl_burst_radius, Tuning.kl_rising_ring_radius, k)

func rising_center() -> Vector2:
	return _rising_at
