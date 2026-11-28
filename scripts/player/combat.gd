class_name KeeperCombat
extends Node2D
## The keeper's fire (M1a, "Fire in the Hollow"; GAME_PLAN §3, §4). A child of the player.
## The action bar (Progress.bar) puts a skill on each slot:
##   slot 1  RT / left click (hold)  Lampfire, always: fireballs of light that burst on impact
##   slot 2  RB / right click        an aimed skill (Fireglobe by default)
##   slot 3  LB / Q                  an aimed skill (the Beam at level 1, then Lance)
##   slot 4  Y / F                   any skill (M1c, PLAN_LANTERNS §6.6): an aimed skill on Y fires at the lock, else at
##                                   the best foe within kl_y_autotarget_deg of the aim, else straight
##   Lock    R3 / middle mouse       the target lock (LockOn; §6): fire goes at the locked foe, led by its speed
##   Dash    LT / Space or Shift     a quick dash; nothing can chill you while you dash. Cooldown.
## One script per skill in scripts/player/skills/; bolts and globes in flight live in FireBolts.
## Lamp charge is the stamina, and it is also how far your hand lamp lights.
## Aim: the mouse when you last used mouse and keyboard, else the right stick, else where you face.
## On a pad, while slot 1, 2 or 3 is held, a released right stick keeps its last aim (Tuning.kl_aim_hold), so
## drinking (B) mid-stream doesn't swing your fire; Lampfire and Lance get a gentle aim assist (kl_aim_assist_deg).

const SKILL_SCRIPTS := {
	"lampfire": preload("res://scripts/player/skills/lampfire.gd"),
	"fireglobe": preload("res://scripts/player/skills/fireglobe.gd"),
	"lance": preload("res://scripts/player/skills/lance.gd"),
	"beam": preload("res://scripts/player/skills/beam.gd"),
	"hearth_ring": preload("res://scripts/player/skills/hearth_ring.gd"),
}

var skills := {}                  # id -> Skill
var beaming := false
var aim := Vector2.RIGHT          # unit vector the fire points along
var aim_override := Vector2.ZERO  # tests and captures can fix the aim (its length, if over 1 px, is the Fireglobe's reach)
var stick_tilt := 1.0             # 0..1: how far the right stick was pushed (the Fireglobe's reach on a pad)
var dash_cd := 0.0
var dash_charges := 1
var dash_t := 0.0                 # > 0 while dashing
var dash_dir := Vector2.ZERO
var _burst_fx := 0.0              # > 0 while the Hearth ring is showing
var _face := Vector2.RIGHT
var _stick_aim := false           # the aim came from the right stick (the aim hold keeps it)
var _stick_len := 0.0
# The keeper's own feedback (readability step): KeeperFx and the keeper's pose read these.
var cast_t := 0.0                 # > 0: the lamp-thrust cue after a cast
var cast_kind := ""               # "throw" (Lampfire), "lob" (Fireglobe), "thrust" (Lance)
var cast_dir := Vector2.RIGHT
var dashes := 0                   # dashes started (KeeperFx starts a smear on each)
var dash_from := Vector2.ZERO
var lock: LockOn                  # the target lock (M1c)
var aim_once := Vector2.ZERO      # a one-shot aim for the next skill press (Y's auto-target on a pad)
var globe_once := Vector2.INF     # ...and where a Fireglobe thrown with it lands
var _delta := 1.0 / 60.0

## A cast: the keeper thrusts the lamp along `dir` for kl_fx_cast_time (Puny frames and a lamp flare).
func cast_cue(kind: String, dir: Vector2) -> void:
	cast_t = Tuning.kl_fx_cast_time
	cast_kind = kind
	cast_dir = dir.normalized() if dir.length() > 0.001 else aim

## The old burst's cooldown, kept for tools and tests that set it (it is Hearth ring's).
var burst_cd: float:
	get:
		return skills["hearth_ring"].cd
	set(v):
		skills["hearth_ring"].cd = v

func _init() -> void:
	lock = LockOn.new(self)
	for id in SKILL_SCRIPTS:
		var s: Skill = SKILL_SCRIPTS[id].new()
		s.combat = self
		skills[id] = s

func _ready() -> void:
	add_to_group("beam_source")
	z_index = 9
	LockOn.current = lock

func _exit_tree() -> void:
	if LockOn.current == lock:
		LockOn.current = null

## Where a new lock looks: the stick if pushed (or the cursor), else where the keeper faces.
func facing_or_aim() -> Vector2:
	if not InputHint.pad or _stick_len > Tuning.kl_stick_aim_min:
		return aim
	return _face

func keeper() -> Node2D:
	return get_parent() as Node2D

func skill(id: String) -> Skill:
	return skills.get(id)

## The skill on a bar slot ("skill_1".."skill_4"), or null when it is empty.
func slot_skill(slot: String) -> Skill:
	return skills.get(Progress.bar.get(slot, ""))

# --- Aim -----------------------------------------------------------------------------------------------

## Where the fire would point now. fire_held: slot 1, 2 or 3 is held (the aim hold).
func update_aim(move_dir: Vector2, fire_held: bool = false) -> void:
	if move_dir.length() > 0.1:
		_face = move_dir.normalized()
	if aim_once != Vector2.ZERO:
		aim = aim_once.normalized()
		return
	if aim_override != Vector2.ZERO and not lock.aiming():
		aim = aim_override.normalized()
		return
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	_stick_len = stick.length()
	if lock.aiming():
		# The lock (M1c): aim at the target, led by its speed (Lampfire's flight). The aim hold has nothing to do.
		var want := aim_for(Tuning.kl_lampfire_speed)
		if beaming:
			# The Beam sweeps onto the lock at up to kl_lock_beam_turn degrees a second instead of snapping.
			var turn := deg_to_rad(Tuning.kl_lock_beam_turn) * _delta
			aim = aim.rotated(clampf(aim.angle_to(want), -turn, turn))
		else:
			aim = want
		_stick_aim = false
		return
	if _stick_len > Tuning.kl_stick_aim_min:
		aim = stick.normalized()
		stick_tilt = clampf((_stick_len - Tuning.kl_stick_aim_min) / maxf(0.01, Tuning.kl_stick_tilt_full - Tuning.kl_stick_aim_min), 0.0, 1.0)
		_stick_aim = true
	elif InputHint.pad and fire_held and Tuning.kl_aim_hold and _stick_aim:
		pass   # the aim hold: a released stick keeps its last aim while a fire button is down
	elif not InputHint.pad and get_viewport() != null:
		_stick_aim = false
		var to_mouse := get_global_mouse_position() - keeper().global_position
		if to_mouse.length() > 4.0:
			aim = to_mouse.normalized()
	else:
		_stick_aim = false
		aim = _face

## The aim for a shot of `speed` px/s: at the locked foe, led (M1c), else the aim as it is.
func aim_for(speed: float) -> Vector2:
	if aim_once != Vector2.ZERO:
		return aim_once.normalized()
	if not lock.aiming():
		return aim
	var origin := keeper().global_position + Vector2(0, -10)
	var v := lock.led_position(origin, speed) - origin
	return v.normalized() if v.length() > 0.5 else aim

## Aim assist on a pad (Lampfire and Lance): a gentle pull onto a foe within kl_aim_assist_deg of the aim.
## Off while locked (the lock is already exact); on while steering.
func assisted(dir: Vector2, reach: float) -> Vector2:
	if lock.aiming() or aim_once != Vector2.ZERO:
		return dir
	if not InputHint.pad or Tuning.kl_aim_assist_deg <= 0.0:
		return dir
	var origin := keeper().global_position + Vector2(0, -10)
	var best := Vector2.ZERO
	var best_ang := deg_to_rad(Tuning.kl_aim_assist_deg)
	for f in get_tree().get_nodes_in_group("foe"):
		if f is WickNest or f._dead or f.is_queued_for_deletion():
			continue
		var v: Vector2 = f.global_position - origin
		var d := v.length()
		if d < 1.0 or d > reach + f.body_radius():
			continue
		var ang := absf(dir.angle_to(v))
		if ang < best_ang:
			best_ang = ang
			best = v
	return best.normalized() if best != Vector2.ZERO else dir

## Where a Fireglobe thrown now lands: 120-280 px along the aim (stick tilt on a pad, the cursor's distance
## with a mouse), pulled back off rock.
## M1c: on the locked foe (LockOn.globe_position), and a landing within kl_flare_reach of a lamp's flame snaps onto
## the flame (so a flare is easy on a pad).
func globe_target() -> Vector2:
	return snap_to_flame(_globe_landing())

func _globe_landing() -> Vector2:
	var origin := keeper().global_position
	var fog := get_tree().get_first_node_in_group("fog_grid") as FogGrid
	var locked := Vector2.INF
	if globe_once != Vector2.INF:
		locked = globe_once
	elif lock.aiming():
		locked = lock.globe_position(origin)
	if locked != Vector2.INF:
		var v := locked - origin
		var dir := v.normalized() if v.length() > 0.001 else aim
		var dd := clampf(v.length(), Tuning.kl_lock_globe_min, Tuning.kl_fireglobe_max)
		if fog:
			while dd > 16.0 and fog.is_solid_at(origin + dir * dd):
				dd -= 16.0
		return origin + dir * dd
	var dist := Tuning.kl_fireglobe_max
	if aim_override != Vector2.ZERO:
		dist = aim_override.length() if aim_override.length() > 1.0 else Tuning.kl_fireglobe_max
	elif InputHint.pad:
		dist = lerpf(Tuning.kl_fireglobe_min, Tuning.kl_fireglobe_max, stick_tilt)
	elif get_viewport() != null:
		dist = (get_global_mouse_position() - origin).length()
	dist = clampf(dist, Tuning.kl_fireglobe_min, Tuning.kl_fireglobe_max)
	if fog:
		while dist > 16.0 and fog.is_solid_at(origin + aim * dist):
			dist -= 16.0
	return origin + aim * dist

## The flare snap: a point within kl_flare_reach of a flame (a planted lamp or a lit old lamp) moves onto it.
static func snap_to_flame(p: Vector2) -> Vector2:
	var f := Lantern.flame_near(p, Tuning.kl_flare_reach)
	return f.flame_pos() if f else p

## Y's auto-target on a pad (M1c, §6.6): the best foe within kl_y_autotarget_deg of the aim (or facing), or null.
func y_target() -> Foe:
	var origin := keeper().global_position
	var dir := facing_or_aim()
	var best: Foe = null
	var best_s := INF
	for f in get_tree().get_nodes_in_group("foe"):
		if not lock.lockable(f, true):   # the lock's rules: not in deep fog (M1c review)
			continue
		var v: Vector2 = f.global_position - origin
		var d := v.length()
		if d > Tuning.kl_lock_range or d < 1.0:
			continue
		var ang := absf(dir.angle_to(v))
		if ang > deg_to_rad(Tuning.kl_y_autotarget_deg):
			continue
		if lock.blocked(origin, f.global_position):
			continue   # ...and not behind rock
		var s := ang + d / Tuning.kl_lock_range
		if s < best_s:
			best_s = s
			best = f
	return best

# --- Each frame ----------------------------------------------------------------------------------------

## Called by the keeper every physics frame with what the player is pressing (after the menu guard: a press that
## closed a menu never reaches here). held / pressed map "skill_1".."skill_4" to true.
func tick(delta: float, move_dir: Vector2, held: Dictionary = {}, pressed: Dictionary = {}, dash_pressed: bool = false) -> void:
	var k = keeper()
	_delta = delta
	var fire_held: bool = held.get("skill_1", false) or held.get("skill_2", false) or held.get("skill_3", false)
	# The target lock first (M1c): it decides where the aim goes. A menu (the input guard) ends it.
	if Progress.input_blocked() and lock.has_target():
		lock.release("menu")
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down") if aim_override == Vector2.ZERO else Vector2.ZERO
	var mouse := get_global_mouse_position() if (not InputHint.pad and get_viewport() != null) else Vector2.INF
	if not InputHint.pad and mouse != Vector2.INF and (pressed.get("skill_1", false) or pressed.get("skill_2", false)):
		lock.sticky_begin(mouse)   # sticky click: the fire follows the foe under the cursor while the button is held
	if lock.sticky and not (held.get("skill_1", false) or held.get("skill_2", false)):
		lock.sticky_end()
	lock.tick(delta, stick, pressed.get("lock_on", false), mouse)
	if pressed.get("lock_next", false):
		lock.cycle(1)
	elif pressed.get("lock_prev", false):
		lock.cycle(-1)
	update_aim(move_dir, fire_held)
	var down := held
	if Settings.autofire and InputHint.pad and aim_override == Vector2.ZERO and (_stick_len > Tuning.kl_autofire_stick or (lock.aiming() and (not held.is_empty() or _stick_len > Tuning.kl_stick_aim_min))):
		down = held.duplicate()
		down["skill_1"] = true   # the auto-fire option: Lampfire streams while the right stick is pushed far (or at a lock)
	for s in skills.values():
		s.tick(delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	if Progress.has_combat_upgrade("second_step") and dash_cd <= 0.0 and dash_charges == 0:
		dash_charges = 2
	dash_t = maxf(0.0, dash_t - delta)
	cast_t = maxf(0.0, cast_t - delta)
	_burst_fx = maxf(0.0, _burst_fx - delta)
	var beam_on_bar := false
	for slot in Progress.SLOTS:
		var s := slot_skill(slot)
		if s == null:
			continue
		if s.held():
			s.hold(delta, down.get(slot, false))
			if s is BeamSkill:
				beam_on_bar = true
		elif pressed.get(slot, false):
			if slot == "skill_4" and s.kind() != Skill.Kind.SELF and InputHint.pad and not lock.aiming():
				# Y with an aimed skill and no lock: at the best foe within 30 degrees, else straight along the aim.
				var f := y_target()
				if f:
					var origin: Vector2 = k.global_position + Vector2(0, -10)
					aim_once = (f.global_position - origin).normalized()
					globe_once = f.global_position
			s.press()
			aim_once = Vector2.ZERO
			globe_once = Vector2.INF
	if not beam_on_bar:
		beaming = false
	if dash_pressed:
		dash(move_dir)
	queue_redraw()

# --- The Beam (kept here: FogGrid lights it as a "beam_source") -----------------------------------------

## Start and end of the beam in world space (empty when not beaming). FogGrid lights it like a mirror beam.
func beam_segment() -> Array:
	if not beaming:
		return []
	var from := keeper().global_position + Vector2(0, -10)
	return [from, from + aim * beam_len()]

func beam_len() -> float:
	return Tuning.kl_long_throw_len if Progress.has_combat_upgrade("long_throw") else Tuning.kl_beam_len

## Burns everything inside the beam. Returns how many it touched.
func burn_along_beam(delta: float) -> int:
	var seg := beam_segment()
	if seg.is_empty():
		return 0
	var hit := 0
	# Feed (M1c combo, while the Beam is kept): a flame the Beam touches burns brighter (Lantern.feed).
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.has_flame():
			var fp: Vector2 = l.flame_pos()
			if Geometry2D.get_closest_point_to_segment(fp, seg[0], seg[1]).distance_to(fp) <= Tuning.kl_beam_half_width + 8.0:
				l.feed()
	for w in get_tree().get_nodes_in_group("foe"):
		var c: Vector2 = Geometry2D.get_closest_point_to_segment(w.global_position, seg[0], seg[1])
		if c.distance_to(w.global_position) <= Tuning.kl_beam_half_width + w.body_radius():
			w.hurt(Tuning.kl_beam_dps * Progress.dmg_mult() * delta, false, "beam")
			hit += 1
	return hit

func is_dashing() -> bool:
	return dash_t > 0.0

## The old burst, now Hearth ring. Returns how many it hit, or -1 if it couldn't fire. Tools and tests call it
## directly (whether or not it is on the bar).
func burst() -> int:
	return skills["hearth_ring"].ring()

## The burst's cooldown, after "Spill".
func burst_cooldown() -> float:
	return skills["hearth_ring"].cooldown()

## A quick dash. Returns false if it couldn't (cooldown or too little charge).
func dash(move_dir: Vector2) -> bool:
	var k = keeper()
	var double_step := Progress.has_combat_upgrade("second_step")
	if (dash_cd > 0.0 or (double_step and dash_charges <= 0)) or k.lamp_charge < Tuning.kl_dash_cost:
		return false
	k.lamp_charge -= Tuning.kl_dash_cost
	if double_step:
		dash_charges -= 1
		dash_cd = Tuning.kl_dash_cd if dash_charges == 0 else 0.0
	else:
		dash_cd = Tuning.kl_dash_cd
	dash_t = Tuning.kl_dash_time
	dash_dir = move_dir.normalized() if move_dir.length() > 0.1 else aim
	dashes += 1
	dash_from = k.global_position
	return true

## How fast the keeper moves while dashing (distance spread over the dash time).
func dash_velocity() -> Vector2:
	return dash_dir * (Tuning.kl_dash_dist / Tuning.kl_dash_time)

func _draw() -> void:
	var k = keeper()
	if k == null:
		return
	# The beam: a warm core inside a soft glow.
	if beaming:
		var from := Vector2(0, -10)
		var to := from + aim * beam_len()
		var flick := 0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.03)
		draw_line(from, to, Color(1.0, 0.85, 0.5, 0.18 * flick), Tuning.kl_beam_half_width * 2.0)
		draw_line(from, to, Color(1.0, 0.92, 0.7, 0.45 * flick), Tuning.kl_beam_half_width)
		draw_line(from, to, Color(1.0, 1.0, 0.92, 0.9), 3.0)
	# Hearth ring: a ring of flame flung outwards.
	if _burst_fx > 0.0:
		var t := 1.0 - _burst_fx / 0.3
		var fm := Settings.flash_mult()
		draw_arc(Vector2(0, -6), Tuning.kl_burst_radius * (0.4 + 0.6 * t), 0.0, TAU, 48, Color(1.0, 0.7, 0.35, 0.8 * (1.0 - t)), 5.0)
		draw_circle(Vector2(0, -6), Tuning.kl_burst_radius * (0.4 + 0.6 * t), Color(1.0, 0.6, 0.3, 0.14 * (1.0 - t) * fm))
	# A faint aim mark, so you can see where your fire will go.
	if not beaming:
		draw_line(Vector2(0, -10) + aim * 18.0, Vector2(0, -10) + aim * 34.0, Color(1.0, 0.9, 0.6, 0.35), 2.0)
