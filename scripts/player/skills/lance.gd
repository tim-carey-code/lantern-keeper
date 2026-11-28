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

var _last_frame := -1

func hold(delta: float, down: bool) -> void:
	# Review fix (M2): a charge doesn't survive a menu. If the world paused (a frame was skipped) or a menu just closed
	# (the input guard), the hold is dropped without firing, so a release inside the pack never throws a Lance.
	var f := Engine.get_physics_frames()
	var gap := _last_frame >= 0 and f - _last_frame > 2
	_last_frame = f
	if gap or Progress.input_blocked() or Tuning.ui_open:
		cancel_hold()
		return
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

## Drops a charge without firing (a menu, a faint).
func cancel_hold() -> void:
	charge_t = 0.0
	_was_down = false

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
