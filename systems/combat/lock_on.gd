class_name LockOn
extends RefCounted
## The target lock (M1c, docs/replan/PLAN_LANTERNS.md §6; owner-approved 2026-11-27). Owned by KeeperCombat.
## Pad: the lock button (R3 by default; Settings.lock_button) toggles a lock on the best foe near your aim. A flick
## of the right stick (past kl_lock_flick and back within kl_lock_flick_time) switches to the nearest foe in that
## direction; holding the stick longer than kl_lock_steer_time steers freely while the lock waits (the marker at
## half strength), and letting go returns the aim to the lock. When the target dies the lock moves to the nearest
## foe within kl_lock_chain_radius (Settings.lock_chain), else it breaks.
## Keyboard and mouse: middle mouse toggles the same lock (the wheel moves it around you), and a "sticky click":
## press left or right mouse with the cursor on a foe and the fire follows it while the button is held.
## Breaks (§6.4): out of range (kl_lock_break_range, or off screen) for kl_lock_break_time; rock in the way for
## kl_lock_los_grace; deep fog for kl_lock_fog_grace; the button again; a menu; a faint; fast travel; the target
## fading in held ground. Being in the dark never breaks a lock.
## The marker (warm corner brackets, #ffd27a) is drawn by the Telegraph node, above the fog (§6.3).

static var current: LockOn         # the keeper's lock (the marker and the bars read it)

const MARKER := Color(1.0, 0.824, 0.478)   # #ffd27a

var combat                          # the KeeperCombat that owns it
var target: Foe = null
var sticky := false                 # the target came from a sticky click (K&M; ends when the button is let go)
var steering := false               # the stick (or the mouse) steers; the lock waits
var started_t := 0.0                # s since the lock started (the brackets snap in over 0.1 s)
var last_event := ""                # what happened last: locked, none, switched, moved_on, broke_<why> (tests)
var breaks := 0
var grace := false                  # a break timer is running (the brackets open by 2 px)
var broke_at := Vector2.INF         # where the last break happened (the marker fades there for 0.2 s)
var broke_r := 0.0
var broke_t := 0.0
var _push_t := 0.0                  # how long the right stick has been pushed
var _peak := 0.0
var _peak_dir := Vector2.ZERO
var _far_t := 0.0
var _los_t := 0.0
var _los_check := 0.0
var _los_blocked := false
var _fog_t := 0.0
var _auto_t := 0.0
var _mouse_t := 99.0                # s since the mouse last moved (it steers a full lock while it moves)
var _last_mouse := Vector2.INF
var _prev_pos := Vector2.INF
var velocity := Vector2.ZERO        # the target's speed, for leading shots

func _init(c = null) -> void:
	combat = c

func keeper() -> Node2D:
	return combat.keeper() if combat else null

func tree() -> SceneTree:
	var k := keeper()
	return k.get_tree() if k and k.is_inside_tree() else null

func has_target() -> bool:
	return target != null and is_instance_valid(target) and not target.is_queued_for_deletion()

## True when the fire should go at the lock now (a target, and nothing steering).
func aiming() -> bool:
	return has_target() and not steering

# --- Picking -----------------------------------------------------------------------------------------------

## Can the lock take this foe? Nests can't be locked (only cores hurt them); nor anything dead, fading or (to
## start a lock) in fog above kl_lock_fog_max.
func lockable(f: Node, starting: bool = true) -> bool:
	if not (f is Foe) or f is WickNest or f._dead or f.is_queued_for_deletion() or f._fading > 0.0:
		return false
	if f is Wickling and f.is_fading_in():
		return false
	if starting:
		var fog := _fog()
		if fog and fog.density_at(f.global_position) > Tuning.kl_lock_fog_max:
			return false
	return true

func _fog() -> FogGrid:
	var t := tree()
	return t.get_first_node_in_group("fog_grid") as FogGrid if t else null

## The best foe from `origin` toward `dir`: within kl_lock_range and kl_lock_cone_deg / 2 of `dir`, the smallest
## angle plus distance / kl_lock_range, foes hunting you first. With nothing in the cone, the nearest in range.
## `exclude`: leave this one out (switching).
func pick(origin: Vector2, dir: Vector2, exclude: Node = null) -> Foe:
	var t := tree()
	if t == null:
		return null
	var best: Foe = null
	var best_s := INF
	var near: Foe = null
	var near_s := INF
	var half := deg_to_rad(Tuning.kl_lock_cone_deg) * 0.5
	var d0 := dir.normalized() if dir.length() > 0.001 else Vector2.RIGHT
	for f in t.get_nodes_in_group("foe"):
		if f == exclude or not lockable(f):
			continue
		var v: Vector2 = f.global_position - origin
		var d := v.length()
		if d > Tuning.kl_lock_range:
			continue
		var hunt_bonus := -10.0 if Hunt.is_hunting(f) else 0.0
		var ns := d / Tuning.kl_lock_range + hunt_bonus
		if ns < near_s:
			near_s = ns
			near = f
		var ang := absf(d0.angle_to(v)) if d > 0.5 else 0.0
		if ang > half:
			continue
		var s := ang + d / Tuning.kl_lock_range + hunt_bonus
		if s < best_s:
			best_s = s
			best = f
	return best if best else near

## Auto mode (§6.8): the nearest foe hunting the keeper within kl_lock_range, wherever it is (no cone), or null.
func nearest_hunter() -> Foe:
	var k := keeper()
	var t := tree()
	if k == null or t == null:
		return null
	var best: Foe = null
	var best_d := Tuning.kl_lock_range
	for f in t.get_nodes_in_group("foe"):
		if not Hunt.is_hunting(f) or not lockable(f):
			continue
		var d: float = k.global_position.distance_to(f.global_position)
		if d <= best_d:
			best_d = d
			best = f
	return best

## Starts a lock toward `dir` (the stick if pushed, else your facing or the cursor). False with nothing to lock.
func acquire(dir: Vector2) -> bool:
	var k := keeper()
	if k == null:
		return false
	var f := pick(k.global_position, dir)
	if f == null:
		last_event = "none"
		Sfx.play("ui_tick", -20.0, 0.05, 0.6)   # a soft "no target" tick
		return false
	_set_target(f)
	sticky = false
	last_event = "locked"
	Sfx.play("ui_tick", -14.0, 0.05, 1.4)   # sound slot lock_on (the owner's job; a Kenney stand-in)
	Story.tip("lock")
	return true

func _set_target(f: Foe) -> void:
	target = f
	started_t = 0.0
	_far_t = 0.0
	_los_t = 0.0
	_fog_t = 0.0
	_los_check = 0.0
	_los_blocked = false
	_prev_pos = f.global_position
	velocity = Vector2.ZERO
	broke_t = 0.0

## The lock button: lock, or let go.
func toggle(dir: Vector2) -> void:
	if Settings.lock_mode == "off":
		return
	if has_target() and not sticky:
		release("button")
	else:
		acquire(dir)

## Ends the lock (the marker opens and fades where it was).
func release(why: String = "button") -> void:
	if target == null:
		return
	if is_instance_valid(target):
		broke_at = target.global_position
		broke_r = target.body_radius()
		broke_t = 0.2
	target = null
	sticky = false
	steering = false
	grace = false
	breaks += 1
	last_event = "broke_" + why

## Moves the lock to the nearest foe within 60 degrees of `dir`, measured from the current target. None: it stays.
func switch_toward(dir: Vector2) -> bool:
	if not has_target():
		return false
	var from := target.global_position
	var best: Foe = null
	var best_d := INF
	var t := tree()
	for f in t.get_nodes_in_group("foe"):
		if f == target or not lockable(f):
			continue
		var v: Vector2 = f.global_position - from
		if v.length() < 1.0 or absf(dir.angle_to(v)) > deg_to_rad(60.0):
			continue
		if keeper().global_position.distance_to(f.global_position) > Tuning.kl_lock_range:
			continue
		if v.length() < best_d:
			best_d = v.length()
			best = f
	if best == null:
		return false
	_set_target(best)
	last_event = "switched"
	Sfx.play("ui_tick", -16.0, 0.05, 1.6)
	return true

## The mouse wheel (K&M): the next foe clockwise (+1) or anticlockwise (-1) around the keeper.
func cycle(step: int) -> bool:
	var k := keeper()
	if k == null:
		return false
	var cands: Array = []
	for f in tree().get_nodes_in_group("foe"):
		if lockable(f) and k.global_position.distance_to(f.global_position) <= Tuning.kl_lock_range:
			cands.append(f)
	if cands.is_empty():
		return false
	cands.sort_custom(func(a: Foe, b: Foe) -> bool: return (a.global_position - k.global_position).angle() < (b.global_position - k.global_position).angle())
	var i := cands.find(target) if has_target() else -1
	var n := cands.size()
	var j := posmod(i + step, n) if i >= 0 else (0 if step > 0 else n - 1)
	_set_target(cands[j])
	sticky = false
	last_event = "switched"
	return true

## K&M sticky click: a fire button pressed with the cursor within kl_sticky_click_radius of a foe's body.
func sticky_begin(cursor: Vector2) -> bool:
	if not Settings.sticky_click or Settings.lock_mode == "off":
		return false   # its own option, and off with the lock (M1c review)
	if has_target() and not sticky:
		return false   # a full lock is already on
	var t := tree()
	if t == null:
		return false
	var best: Foe = null
	var best_d := INF
	for f in t.get_nodes_in_group("foe"):
		if not lockable(f, false):
			continue
		var d: float = cursor.distance_to(f.global_position) - f.body_radius()
		if d <= Tuning.kl_sticky_click_radius and d < best_d:
			best_d = d
			best = f
	if best == null:
		return false
	_set_target(best)
	sticky = true
	last_event = "sticky"
	return true

func sticky_end() -> void:
	if sticky and has_target():
		target = null
		sticky = false
		last_event = "sticky_end"

# --- Each frame --------------------------------------------------------------------------------------------

## stick: the right stick now (pad). pressed: the lock button this frame. mouse_moved: the cursor moved (K&M).
func tick(delta: float, stick: Vector2, pressed: bool, mouse_pos: Vector2 = Vector2.INF) -> void:
	started_t += delta
	broke_t = maxf(0.0, broke_t - delta)
	if Tuning.ui_open:
		if has_target():
			release("menu")   # a lock never leaks out of a menu
		return
	if pressed:
		toggle(stick if stick.length() > Tuning.kl_stick_aim_min else combat.facing_or_aim())
	# The stick: a quick flick switches; a longer push steers.
	var len := stick.length()
	if len >= Tuning.kl_stick_aim_min:
		_push_t += delta
		if len > _peak:
			_peak = len
			_peak_dir = stick.normalized()
	else:
		if _push_t > 0.0 and _push_t <= Tuning.kl_lock_flick_time and _peak >= Tuning.kl_lock_flick and has_target():
			switch_toward(_peak_dir)
		_push_t = 0.0
		_peak = 0.0
	# The mouse steers a full lock while it moves.
	if mouse_pos != Vector2.INF:
		if _last_mouse != Vector2.INF and mouse_pos.distance_to(_last_mouse) > 2.0:
			_mouse_t = 0.0
		else:
			_mouse_t += delta
		_last_mouse = mouse_pos
	steering = has_target() and not sticky and (_push_t > Tuning.kl_lock_steer_time or (not InputHint.pad and _mouse_t < Tuning.kl_lock_steer_time))
	# Auto mode: no lock, so take the nearest foe hunting you.
	if Settings.lock_mode == "auto" and not has_target():
		_auto_t -= delta
		if _auto_t <= 0.0:
			_auto_t = 0.2
			var f := nearest_hunter()
			if f:
				_set_target(f)
				last_event = "auto"
	if target != null:
		_check_breaks(delta)
	if has_target():
		var p := target.global_position
		if _prev_pos != Vector2.INF and delta > 0.0:
			velocity = velocity.lerp((p - _prev_pos) / delta, 0.35)
		_prev_pos = p

func _check_breaks(delta: float) -> void:
	# Death (or freed): move on to the nearest foe near it, hunting first, else break.
	if not has_target() or target._dead:
		var at := _prev_pos
		var r := target.body_radius() if is_instance_valid(target) else 10.0
		target = null
		if sticky:
			sticky = false
			last_event = "sticky_end"
			return
		if Settings.lock_chain:
			var next := _nearest_to(at)
			if next:
				_set_target(next)
				last_event = "moved_on"
				return
		broke_at = at
		broke_r = r
		broke_t = 0.2
		breaks += 1
		last_event = "broke_death"
		return
	if target._fading > 0.0:
		release("held")
		return
	if sticky:
		return   # a sticky click lasts while its button is held
	var k := keeper()
	var p := target.global_position
	grace = false
	# Range, or off screen.
	var far := k.global_position.distance_to(p) > Tuning.kl_lock_break_range
	var view := Telegraph.view_rect(k)
	if view.size != Vector2.ZERO and not view.grow(32.0).has_point(p):
		far = true
	_far_t = _far_t + delta if far else 0.0
	if far:
		grace = true
	if _far_t >= Tuning.kl_lock_break_time:
		release("range")
		return
	# Rock in the way (sampled every 16 px, ten times a second).
	_los_check -= delta
	if _los_check <= 0.0:
		_los_check = 0.1
		_los_blocked = blocked(k.global_position, p)
	_los_t = _los_t + delta if _los_blocked else 0.0
	if _los_blocked:
		grace = true
	if _los_t >= Tuning.kl_lock_los_grace:
		release("rock")
		return
	# Deep fog.
	var fog := _fog()
	var deep := fog != null and fog.density_at(p) > Tuning.kl_lock_fog_max
	_fog_t = _fog_t + delta if deep else 0.0
	if deep:
		grace = true
	if _fog_t >= Tuning.kl_lock_fog_grace:
		release("fog")

## Rock between two points (FogGrid.is_solid_at every 16 px).
func blocked(a: Vector2, b: Vector2) -> bool:
	var fog := _fog()
	if fog == null:
		return false
	var d := a.distance_to(b)
	var n := int(d / 16.0)
	for i in range(1, n):
		if fog.is_solid_at(a.lerp(b, float(i) / float(n))):
			return true
	return false

func _nearest_to(at: Vector2) -> Foe:
	var t := tree()
	var best: Foe = null
	var best_s := INF
	for f in t.get_nodes_in_group("foe"):
		if not lockable(f):
			continue
		var d: float = f.global_position.distance_to(at)
		if d > Tuning.kl_lock_chain_radius:
			continue
		var s := d - (10000.0 if Hunt.is_hunting(f) else 0.0)
		if s < best_s:
			best_s = s
			best = f
	return best

# --- Aim -----------------------------------------------------------------------------------------------------

## Where to aim to hit the target with a shot of `speed` px/s from `origin`: its position plus its speed times
## the flight time, the lead capped at kl_lock_lead_max. speed 0: no lead.
func led_position(origin: Vector2, speed: float) -> Vector2:
	if not has_target():
		return Vector2.INF
	var p := target.global_position
	if speed <= 0.0:
		return p
	var t := origin.distance_to(p) / speed
	return p + (velocity * t).limit_length(Tuning.kl_lock_lead_max)

## The Fireglobe's landing on the target: led by half its flight, kl_lock_globe_min to kl_fireglobe_max out.
func globe_position(origin: Vector2) -> Vector2:
	if not has_target():
		return Vector2.INF
	var p := target.global_position + (velocity * Tuning.kl_fireglobe_flight * 0.5).limit_length(Tuning.kl_lock_lead_max)
	var v := p - origin
	var d := clampf(v.length(), Tuning.kl_lock_globe_min, Tuning.kl_fireglobe_max)
	return origin + (v.normalized() if v.length() > 0.001 else combat.aim) * d

# --- The marker (drawn by Telegraph, on the fog layer above fog and foes) --------------------------------------

## The marker now: {} when none, else {"center", "half" (bracket half size), "arm", "width", "alpha", "open",
## "lit"}. It never flashes. Public for tests.
func marker() -> Dictionary:
	var big := 1.5 if Settings.lock_large else 1.0
	if has_target():
		var snap := clampf(started_t / 0.1, 0.0, 1.0)
		var half := (target.body_radius() + 6.0) * big + 8.0 * (1.0 - snap)
		return {"center": target.global_position, "half": half, "arm": 6.0 * big, "width": 3.0 if Settings.lock_large else 2.0,
			"alpha": 0.5 if steering else 1.0, "open": 2.0 if grace else 0.0, "lit": target.is_exposed(), "color": MARKER}
	if broke_t > 0.0 and broke_at != Vector2.INF:
		var k := 1.0 - broke_t / 0.2
		return {"center": broke_at, "half": (broke_r + 6.0) * big + 6.0 * k, "arm": 6.0 * big, "width": 2.0, "alpha": 1.0 - k,
			"open": 2.0 + 6.0 * k, "lit": false, "color": MARKER}
	return {}

static func draw_marker(canvas: CanvasItem, m: Dictionary) -> void:
	if m.is_empty():
		return
	var c: Vector2 = m["center"]
	var h: float = m["half"] + m["open"]
	var arm: float = m["arm"]
	var w: float = m["width"]
	var col: Color = Color(m["color"], m["alpha"])
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner := c + Vector2(sx * h, sy * h)
			canvas.draw_line(corner, corner - Vector2(sx * arm, 0), col, w)
			canvas.draw_line(corner, corner - Vector2(0, sy * arm), col, w)
	if m["lit"]:
		# A short warm bar under the brackets while the target is lit: your shots land at full strength.
		canvas.draw_line(c + Vector2(-h * 0.5, h + 5.0), c + Vector2(h * 0.5, h + 5.0), Color(m["color"], m["alpha"] * 0.9), w)
