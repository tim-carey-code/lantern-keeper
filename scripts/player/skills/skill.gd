class_name Skill
extends RefCounted
## A skill on the keeper's action bar (M1a, GAME_PLAN §4.1; one script per skill, §16).
## Slot rule (§3): slot 1 (RT / left click) is always Lampfire; slots 2 and 3 (RB, LB / right click, Q) take
## aimed skills; slot 4 (Y / F) takes self-cast skills only. Lamp charge is the cost; every number is in
## Tuning (kl_*). Titles and blurbs are DRAFT player-facing text (docs/replan/M1A_BUILD_NOTES.md).

enum Kind { BASIC, AIMED, SELF }

var id := ""
var cd := 0.0                    # seconds of cooldown left
var combat                       # the KeeperCombat that owns it (untyped: skills call into it)

func title() -> String:
	return id

func blurb() -> String:
	return ""

func kind() -> int:
	return Kind.AIMED

## True for skills that act while their button is held (Lampfire, the Beam).
func held() -> bool:
	return false

## Lamp charge per use (per second for a channel).
func cost() -> float:
	return 0.0

func cooldown() -> float:
	return 0.0

## Short facts for the Skills list, e.g. "0.3 charge, 5 s cooldown".
func facts() -> String:
	var bits: Array[String] = []
	if cost() > 0.0:
		bits.append(num(cost()) + (" charge a second" if held() else " charge"))
	else:
		bits.append("free")
	if cooldown() > 0.0:
		bits.append(num(cooldown()) + " s cooldown")
	return ", ".join(bits)

## A tuning number for text: "5", "0.3", "0.35".
static func num(x: float) -> String:
	if is_equal_approx(x, roundf(x)):
		return str(roundi(x))
	return str(snappedf(x, 0.01))

func keeper() -> Node:
	return combat.keeper() if combat else null

func tick(delta: float) -> void:
	cd = maxf(0.0, cd - delta)

## The bar greys the slot when this is true.
func short_of_charge() -> bool:
	var k := keeper()
	return k != null and cost() > 0.0 and k.lamp_charge < cost()

func can_fire() -> bool:
	return cd <= 0.0 and not short_of_charge()

## Pays the cost and starts the cooldown.
func spend() -> void:
	var k := keeper()
	if k:
		k.lamp_charge = maxf(0.0, k.lamp_charge - cost())
	cd = cooldown()

## A one-shot skill fires on the press. Returns true if it fired.
func press() -> bool:
	return false

## A held skill hears its button every physics frame.
func hold(_delta: float, _down: bool) -> void:
	pass

## Where a bolt leaves the hand lamp.
func muzzle(dir: Vector2) -> Vector2:
	return keeper().global_position + Vector2(0, -10) + dir * 12.0
