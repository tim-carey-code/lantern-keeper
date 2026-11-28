class_name FireBolts
extends Node2D
## The keeper's fire in flight (M1a, GAME_PLAN §4.1, §15; brief §7): Lampfire bolts, Lance bolts and lobbed
## Fireglobes. One node holds them all as pooled entries (a spent bolt is reused, never freed), moves them in
## _physics_process, and draws them in one pass with an additive material (no PointLight2D).
## Hits: a shape cast along each tick's motion against the foes' hurtboxes (Foe.HURT_LAYER); blasts and
## splash: one intersect_shape at the point of impact. Walls: rock tiles (FogGrid.is_solid_at) stop bolts.
## While they fly, bolts and globes light the fog around them (group "light_points").
## M1c combos at a lamp's flame (PLAN_LANTERNS §3; Lantern.has_flame): Lampfire **catches** (once a bolt: +1 damage
## and two side bolts), a Fireglobe **flares** the lamp it snaps onto (16 in 160 px, burning ground, the lamp's
## light x1.5), and a Lance **chains** two flames up to 420 px apart with no rock between (6 to everything on the
## line, full shell wear, then a burning seam). A globe in the Ashbrood's bowl stirs the ember.

static var inst: FireBolts

enum { LAMPFIRE, LANCE, GLOBE }

const TRAIL := 6                 # trail points kept per bolt (one per physics tick)


class Bolt:
	var kind := 0
	var alive := false
	var pos := Vector2.ZERO
	var dir := Vector2.RIGHT
	var speed := 0.0
	var travelled := 0.0
	var reach := 0.0
	var radius := 6.0
	var pierce := 1
	var hit_ids := {}
	var trail := PackedVector2Array()
	var age := 0.0
	var from := Vector2.ZERO
	var to := Vector2.ZERO
	var flight := 0.6
	var dmg := -1.0              # Lampfire: the hit's damage before the keeper's level (-1: kl_lampfire_dmg)
	var caught := false          # Lampfire: caught at a flame (once a bolt)
	var no_catch := false        # a catch's side bolts can't catch again
	var flames: Array = []       # Lance: the flames it has passed (a chain arcs between each new one and the last)
	# M2 picks (SkillTree): what this bolt carries.
	var mult := 1.0              # damage x (Twin, Skip, Forked, Comet)
	var big := false             # Lampfire Comet: double damage and splash
	var spark := false           # Scatter's sparks and other side bolts: no picks of their own
	var passes := 0              # Lampfire Needle: foes it passes before it bursts
	var skips := 0               # Lampfire Skip: jumps left
	var child := false           # Lance: a fork or a breaking bolt (no forks, returns or breaks of its own)
	var returning := false       # Lance Returning: on its way back
	var start := Vector2.ZERO    # where it was fired (Burning line)
	var charged := false         # Held lance
	var delay := 0.0             # a globe that waits before it flies (Second globe)
	var small := false           # a small globe (Second globe, Cluster, Skipping globe): no picks of its own
	var g_mult := 1.0            # a globe's damage x
	var g_radius := 0.0          # a globe's radius (0: kl_fireglobe_radius)

var bolts: Array[Bolt] = []
var hits := 0                    # foes hit so far (tests)
var catches := 0                 # combos so far (tests): bolts caught, lamps flared, chains arced
var flares := 0
var chains := 0
var embers := 0
var beacons := 0                 # Fireglobe Beacon lights left (tests)
var _query: PhysicsShapeQueryParameters2D
var _circle: CircleShape2D
var _glow: Texture2D

func _enter_tree() -> void:
	inst = self
	add_to_group("fire_bolts")
	add_to_group("light_points")

func _exit_tree() -> void:
	if inst == self:
		inst = null

func _ready() -> void:
	z_index = 12
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	_glow = LightTex.radial()
	_circle = CircleShape2D.new()
	_query = PhysicsShapeQueryParameters2D.new()
	_query.shape = _circle
	_query.collide_with_areas = true
	_query.collide_with_bodies = false
	_query.collision_mask = Foe.HURT_LAYER

# --- Firing ------------------------------------------------------------------------------------------

func _take() -> Bolt:
	for b in bolts:
		if not b.alive:
			return b
	var nb := Bolt.new()
	bolts.append(nb)
	return nb

func _launch(kind: int, from: Vector2, dir: Vector2, speed: float, reach: float, radius: float, pierce: int) -> Bolt:
	var b := _take()
	b.kind = kind
	b.alive = true
	b.pos = from
	b.dir = dir.normalized()
	b.speed = speed
	b.travelled = 0.0
	b.reach = reach
	b.radius = radius
	b.pierce = pierce
	b.hit_ids.clear()
	b.dmg = -1.0
	b.caught = false
	b.no_catch = false
	b.flames = []
	b.mult = 1.0
	b.big = false
	b.spark = false
	b.passes = 0
	b.skips = 0
	b.child = false
	b.returning = false
	b.start = from
	b.charged = false
	b.delay = 0.0
	b.small = false
	b.g_mult = 1.0
	b.g_radius = 0.0
	b.trail.clear()
	b.trail.append(from)
	b.age = 0.0
	return b

## A Lampfire bolt from the keeper, with the keeper's Lampfire picks (Needle, Skip). Side bolts use _side_bolt.
func fire_lampfire(from: Vector2, dir: Vector2) -> Bolt:
	var b := _launch(LAMPFIRE, from, dir, Tuning.kl_lampfire_speed, Tuning.kl_lampfire_range, Tuning.kl_lampfire_hit_radius, 1)
	if Progress.has_pick("needle"):
		b.passes = 1
	if Progress.has_pick("skip"):
		b.skips = 1
	return b

## A Lampfire bolt with no picks of its own (catch splits, Scatter sparks, Skip jumps, Breaking, Sunburst, Recoil).
func _side_bolt(from: Vector2, dir: Vector2, reach: float, dmg: float) -> Bolt:
	var b := _launch(LAMPFIRE, from, dir, Tuning.kl_lampfire_speed, reach, Tuning.kl_lampfire_hit_radius, 1)
	b.dmg = dmg
	b.no_catch = true
	b.caught = true
	b.spark = true
	return b

## Public for picks outside this file (Sunburst, Recoil): side bolts of a normal hit's damage.
func fire_side_bolt(from: Vector2, dir: Vector2) -> Bolt:
	return _side_bolt(from, dir, Tuning.kl_lampfire_range, Tuning.kl_lampfire_dmg)

func fire_lance(from: Vector2, dir: Vector2, charged: bool = false) -> Bolt:
	var b := _launch(LANCE, from, dir, Tuning.kl_lance_speed, Tuning.kl_lance_range, Tuning.kl_lance_hit_radius, Tuning.kl_lance_pierce)
	if charged:
		b.charged = true
		b.mult = Tuning.kl_held_lance_mult
		b.pierce = 999
	return b

## A Fireglobe from the keeper, with the keeper's Fireglobe picks (Second globe follows it).
func throw_globe(from: Vector2, to: Vector2) -> Bolt:
	var b := _globe(from, to, Tuning.kl_fireglobe_flight)
	if Progress.has_pick("second_globe"):
		var s := _globe(from, to + (to - from).normalized().orthogonal() * 18.0, Tuning.kl_fireglobe_flight)
		s.small = true
		s.delay = Tuning.kl_second_globe_delay
		s.g_mult = Tuning.kl_second_globe_mult
		s.g_radius = Tuning.kl_fireglobe_radius * Tuning.kl_second_globe_mult
	return b

func _globe(from: Vector2, to: Vector2, flight: float) -> Bolt:
	var b := _launch(GLOBE, from, to - from, 0.0, 0.0, 8.0, 0)
	b.from = from
	b.to = to
	b.flight = maxf(0.05, flight)
	return b

## How many are in the air (of one kind, or all).
func in_flight(kind: int = -1) -> int:
	var n := 0
	for b in bolts:
		if b.alive and (kind < 0 or b.kind == kind):
			n += 1
	return n

## Where the Fireglobes in the air will land (for the ground markers and tests).
func globe_targets() -> Array:
	var out := []
	for b in bolts:
		if b.alive and b.kind == GLOBE:
			out.append(b.to)
	return out

func light_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for b in bolts:
		if b.alive:
			out.append(Vector3(b.pos.x, b.pos.y, Tuning.kl_bolt_light))
	return out

# --- Flight ------------------------------------------------------------------------------------------

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func _keeper() -> Node:
	return get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	var any := false
	_combo_live = false
	for b in bolts:
		if b.alive and b.kind != GLOBE:
			_combo_live = true
			break
	if _combo_live:
		_gather_flames()
		_combo_live = not _flames.is_empty()
	for b in bolts:
		if not b.alive:
			continue
		any = true
		b.age += delta
		if b.kind == GLOBE:
			_step_globe(b)
		else:
			_step_bolt(b, delta)
	if any:
		queue_redraw()

func _step_bolt(b: Bolt, delta: float) -> void:
	var step := b.dir * b.speed * delta
	var left := b.reach - b.travelled
	if step.length() > left:
		step = b.dir * left
	if _combo_live:
		# The catch distance (owner, M1c playtest: standing at your own lamp made every bolt catch): a bolt catches only
		# once it has flown past the keeper's own reach, kl_catch_min_travel.
		if b.kind == LAMPFIRE and not b.caught and not b.no_catch and b.travelled + step.length() >= Tuning.kl_catch_min_travel:
			_try_catch(b, step)
		elif b.kind == LANCE:
			_try_chain(b, step)
	# Foes along this tick's motion, nearest first.
	var found := sweep(b.pos, step, b.radius)
	for f in found:
		if b.hit_ids.has(f.get_instance_id()):
			continue
		b.hit_ids[f.get_instance_id()] = true
		var at: Vector2 = b.pos + b.dir * maxf(0.0, (f.global_position - b.pos).dot(b.dir) - f.body_radius() * 0.5)
		if b.kind == LAMPFIRE:
			if b.passes > 0:
				b.passes -= 1   # Needle: the hit lands, no burst, and it flies on
				_needle_pass(f, at, b)
				continue
			_lampfire_hit(f, at, b.dir, b.dmg, b)
			_end(b, at)
			return
		_lance_hit(f, at, b.dir, b)
		b.pierce -= 1
		if b.pierce <= 0:
			_lance_end(b, at)
			_end(b, at)
			return
	var next := b.pos + step
	var fog := _fog()
	if fog and fog.is_solid_at(next):
		if b.kind == LAMPFIRE:
			_lampfire_hit(null, b.pos, b.dir, b.dmg, b)   # it bursts on the rock, and its splash still lands
		else:
			FireFx.impact(b.pos, b.dir, 10.0, false)
			_lance_end(b, b.pos)
		_end(b, b.pos)
		return
	b.pos = next
	b.travelled += step.length()
	b.trail.append(b.pos)
	if b.trail.size() > TRAIL:
		b.trail.remove_at(0)
	if b.travelled >= b.reach - 0.01:
		if b.kind == LANCE and not b.child and not b.returning and Progress.has_pick("returning"):
			_lance_turn(b)   # Returning: back through the foes, toward the keeper
			return
		FireFx.impact(b.pos, b.dir, 6.0, false)   # it fizzles at the end of its reach: no burst
		if b.kind == LANCE:
			_lance_end(b, b.pos)
		_end(b, b.pos)

func _end(b: Bolt, _at: Vector2) -> void:
	b.alive = false
	b.trail.clear()

func _step_globe(b: Bolt) -> void:
	if b.delay > 0.0:
		b.delay -= get_physics_process_delta_time()
		b.age = 0.0
		return
	var k := clampf(b.age / b.flight, 0.0, 1.0)
	b.pos = b.from.lerp(b.to, k) + Vector2(0, -sin(k * PI) * Tuning.kl_fireglobe_arc)
	b.trail.append(b.pos)
	if b.trail.size() > TRAIL:
		b.trail.remove_at(0)
	if k >= 1.0:
		b.alive = false
		b.trail.clear()
		if b.small:
			_small_burst(b.to, b.g_mult, b.g_radius)
		else:
			_globe_burst(b.to, (b.to - b.from).normalized() if b.to != b.from else Vector2.RIGHT)

# --- Hits ----------------------------------------------------------------------------------------------

## Foes whose hurtbox a circle of `radius` touches as it moves from `from` by `motion`, nearest first.
func sweep(from: Vector2, motion: Vector2, radius: float) -> Array:
	if not is_inside_tree():
		return []
	_circle.radius = radius
	_query.transform = Transform2D(0.0, from)
	_query.motion = motion
	var res := get_world_2d().direct_space_state.intersect_shape(_query, 32)
	var out := []
	for r in res:
		var col = r.get("collider")
		var f = col.get_parent() if col else null
		if f is Foe and not f._dead and not f.is_queued_for_deletion():
			out.append(f)
	if out.size() > 1:
		var d := motion.normalized() if motion.length() > 0.001 else Vector2.RIGHT
		out.sort_custom(func(a: Foe, c: Foe) -> bool: return (a.global_position - from).dot(d) < (c.global_position - from).dot(d))
	return out

## Every foe inside a circle (instant AoE: one shape query, brief §7).
func area(center: Vector2, radius: float) -> Array:
	return sweep(center, Vector2.ZERO, radius)

## Lampfire: 2 on the foe it hits (half of it wears a shell), 1 to everything else within 40 px (never a shell),
## a light pop that clears fog, and charge back for the keeper.
## M2 picks: Lingering burn (the foe burns), Scatter (sparks), Skip (it jumps on), Comet (big: x2 and twice the splash).
func _lampfire_hit(f: Foe, at: Vector2, dir: Vector2, dmg: float = -1.0, b: Bolt = null) -> void:
	var k := _keeper()
	var m := b.mult if b else 1.0
	var splash := Tuning.kl_lampfire_splash
	if b and b.big:
		m *= Tuning.kl_comet_mult
		splash *= Tuning.kl_comet_mult
	if f:
		hits += 1
		f.hurt((Tuning.kl_lampfire_dmg if dmg < 0.0 else dmg) * m * Progress.dmg_mult(), false, "lampfire")
		if k and not (f is WickNest):
			k.lamp_charge = minf(Progress.charge_max(), k.lamp_charge + Tuning.kl_lampfire_charge)
		if Progress.has_pick("lingering_burn") and is_instance_valid(f) and not f._dead:
			f.ignite(Tuning.kl_pick_burn_dps * Progress.dmg_mult(), Tuning.kl_pick_burn_time)
	for o in area(at, splash):
		if o != f:
			o.hurt(Tuning.kl_lampfire_splash_dmg * (Tuning.kl_comet_mult if b and b.big else 1.0) * Progress.dmg_mult(), false, "splash")
	FireFx.impact(at, dir, splash)
	Sfx.play("ui_tick", -22.0, 0.25)
	if b == null or b.spark:
		return
	if Progress.has_pick("scatter"):
		for i in Tuning.kl_scatter_count:
			var a := dir.angle() + PI + (float(i) - float(Tuning.kl_scatter_count - 1) * 0.5) * 1.1
			var sp := _side_bolt(at, Vector2.from_angle(a), Tuning.kl_scatter_range, Tuning.kl_scatter_dmg)
			sp.hit_ids = b.hit_ids.duplicate()   # the sparks fly off the foe the bolt hit, not back into it
	if b.skips > 0 and f:
		var next := _nearest_foe(at, Tuning.kl_skip_range, b.hit_ids, f)
		if next:
			var sb := _side_bolt(at, (next.global_position - at).normalized(), Tuning.kl_skip_range + 20.0, Tuning.kl_lampfire_dmg * Tuning.kl_skip_mult)
			sb.hit_ids = b.hit_ids.duplicate()
			sb.mult = m / (Tuning.kl_comet_mult if b.big else 1.0)

## Needle: the first foe takes the hit (no splash, no burst), and the bolt flies on to burst on the next.
func _needle_pass(f: Foe, at: Vector2, b: Bolt) -> void:
	hits += 1
	f.hurt((Tuning.kl_lampfire_dmg if b.dmg < 0.0 else b.dmg) * b.mult * (Tuning.kl_comet_mult if b.big else 1.0) * Progress.dmg_mult(), false, "lampfire")
	var k := _keeper()
	if k and not (f is WickNest):
		k.lamp_charge = minf(Progress.charge_max(), k.lamp_charge + Tuning.kl_lampfire_charge)
	if Progress.has_pick("lingering_burn") and is_instance_valid(f) and not f._dead:
		f.ignite(Tuning.kl_pick_burn_dps * Progress.dmg_mult(), Tuning.kl_pick_burn_time)
	FireFx.impact(at, b.dir, 8.0, false)

## The nearest living foe within `radius` of a point, skipping ones in `skip` (instance ids) and `not_this`.
func _nearest_foe(at: Vector2, radius: float, skip: Dictionary = {}, not_this: Node = null) -> Foe:
	var best: Foe = null
	var best_d := radius
	for o in area(at, radius):
		if o == not_this or skip.has(o.get_instance_id()) or o is WickNest:
			continue
		var d: float = o.global_position.distance_to(at)
		if d <= best_d:
			best_d = d
			best = o
	return best

## Lance: full damage, wears shells fully, freezes what it hits for a moment.
## M2 picks: Brand (marks the foe for +50% on the next hit), Forked (two more at the first hit), Shatter (in Foe.hurt).
func _lance_hit(f: Foe, at: Vector2, dir: Vector2, b: Bolt = null) -> void:
	hits += 1
	var m := b.mult if b else 1.0
	f.hurt(Tuning.kl_lance_dmg * m * Progress.dmg_mult(), false, "lance")
	if Progress.has_pick("brand") and is_instance_valid(f) and not f._dead:
		Foe.branded = f
	if b and not b.child and Progress.has_pick("forked") and b.hit_ids.size() == 1:
		for side in [-1.0, 1.0]:
			var fb := _launch(LANCE, at, dir.rotated(deg_to_rad(Tuning.kl_fork_spread_deg) * side), Tuning.kl_lance_speed, Tuning.kl_fork_range, Tuning.kl_lance_hit_radius, 1)
			fb.child = true
			fb.mult = Tuning.kl_fork_mult
			fb.hit_ids = b.hit_ids.duplicate()
	if Tuning.kl_lance_dmg >= Tuning.kl_hitstop_big and is_instance_valid(f) and not f._dead:
		f.hit_stop(Tuning.kl_hitstop)
	FireFx.impact(at, dir, 14.0, false)
	var k := _keeper()
	if k and k.has_method("shake"):
		k.shake(Tuning.kl_shake_lance_hit)
	Sfx.play("ui_tick", -14.0, 0.3)

## Returning: at the end of its flight the Lance turns back toward the keeper, through foes again.
func _lance_turn(b: Bolt) -> void:
	var k := _keeper()
	var home: Vector2 = (k.global_position + Vector2(0, -10)) if k else b.start
	var v := home - b.pos
	b.returning = true
	b.dir = v.normalized() if v.length() > 1.0 else -b.dir
	b.travelled = 0.0
	b.reach = maxf(40.0, v.length())
	b.hit_ids.clear()
	b.pierce = maxi(b.pierce, Tuning.kl_lance_pierce)
	b.flames = []
	FireFx.impact(b.pos, -b.dir, 8.0, false)

## The Lance's flight ends (its reach, its last pierce, or rock): Burning line and Breaking.
func _lance_end(b: Bolt, at: Vector2) -> void:
	if b.child:
		return
	if Progress.has_pick("burning_line") and b.start.distance_to(at) > 8.0:
		var seam := ChainSeam.new()
		seam.a = b.start
		seam.b = at
		seam.ground_a = b.start + Vector2(0, 10)
		seam.ground_b = at + Vector2(0, 10)
		seam.life = Tuning.kl_burning_line_time
		seam.dps = Tuning.kl_burning_line_dps
		seam.arc = false
		get_parent().add_child(seam)
	if Progress.has_pick("breaking"):
		for i in Tuning.kl_breaking_count:
			var off := (float(i) - float(Tuning.kl_breaking_count - 1) * 0.5) * deg_to_rad(Tuning.kl_breaking_spread_deg)
			var sb := _side_bolt(at, b.dir.rotated(off), Tuning.kl_lampfire_range * 0.6, Tuning.kl_lampfire_dmg)
			sb.hit_ids = b.hit_ids.duplicate()

## Shatter (Foe.hurt calls it): a shell a Lance broke bursts for kl_shatter_dmg around the foe (not the foe itself).
func shatter(at: Vector2, from: Foe) -> void:
	for o in area(at, Tuning.kl_shatter_radius):
		if o != from:
			o.hurt(Tuning.kl_shatter_dmg * Progress.dmg_mult(), false, "splash")
	FireFx.blast(at, Tuning.kl_shatter_radius, 0.15)
	Sfx.play("ui_tick", -10.0, 0.3, 0.8)

# --- Combos (M1c) ---------------------------------------------------------------------------------------

## The point on this tick's motion closest to a flame within `reach` of it, or null.
## Performance (M1c review): the flames are gathered once a physics tick (and again when a lamp lights, goes out or
## flares), and each bolt first skips every flame farther than its step plus the reach.
var _flames := PackedVector2Array()
var _flame_lamps: Array = []
var _flames_frame := -1
var _flames_epoch := -1
var _combo_live := false         # a bolt is flying and some lamp has a flame (gathered once a tick)
var _flame_grid := {}            # 128 px cells -> flame indices
const FLAME_CELL := 128.0        # bigger than a tick's step (12 px) plus a reach (28 px) on each side

func _gather_flames() -> void:
	var f := Engine.get_physics_frames()
	if f == _flames_frame and LightSense._epoch == _flames_epoch:
		return
	LightSense.refresh(get_tree())
	_flames_frame = f
	_flames_epoch = LightSense._epoch
	_flames.clear()
	_flame_lamps.clear()
	_flame_grid.clear()
	for l in LightSense.nodes:
		if is_instance_valid(l) and l.has_flame():
			var fp: Vector2 = l.flame_pos()
			var c := Vector2i(floori(fp.x / FLAME_CELL), floori(fp.y / FLAME_CELL))
			if not _flame_grid.has(c):
				_flame_grid[c] = PackedInt32Array()
			_flame_grid[c].append(_flames.size())
			_flames.append(fp)
			_flame_lamps.append(l)

func _flame_on(from: Vector2, step: Vector2, reach: float, exclude: Array = []) -> Lantern:
	_gather_flames()
	if _flames.is_empty():
		return null
	var best: Lantern = null
	var best_d := reach
	var mid := from + step * 0.5
	var cull := step.length() * 0.5 + reach
	cull *= cull
	var c := Vector2i(floori(mid.x / FLAME_CELL), floori(mid.y / FLAME_CELL))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell = _flame_grid.get(c + Vector2i(dx, dy))
			if cell == null:
				continue
			for i in cell:
				var fp: Vector2 = _flames[i]
				if fp.distance_squared_to(mid) > cull:
					continue
				var l: Lantern = _flame_lamps[i]
				if not is_instance_valid(l) or l in exclude:
					continue
				var d := Geometry2D.get_closest_point_to_segment(fp, from, from + step).distance_to(fp)
				if d <= best_d:
					best_d = d
					best = l
	return best

## Catch: a Lampfire bolt passing within kl_catch_reach of a flame catches (once): +kl_catch_dmg_add, and it throws
## kl_catch_split side bolts at +-kl_catch_spread_deg (each kl_catch_split_dmg, a fresh kl_catch_split_range).
func _try_catch(b: Bolt, step: Vector2) -> void:
	var l := _flame_on(b.pos, step, Tuning.kl_catch_reach)
	if l == null:
		return
	b.caught = true
	b.dmg = Tuning.kl_lampfire_dmg + Tuning.kl_catch_dmg_add
	catches += 1
	l.gulp()
	var at := l.flame_pos()
	var n := Tuning.kl_catch_split
	for i in n:
		var side := -1.0 if i % 2 == 0 else 1.0
		var step_i := float(i / 2 + 1)
		var sb := _side_bolt(at, b.dir.rotated(deg_to_rad(Tuning.kl_catch_spread_deg) * side * step_i), Tuning.kl_catch_split_range, Tuning.kl_catch_split_dmg)
		sb.spark = false   # the splits keep the keeper's Lampfire picks (Lingering burn, Scatter), not the catch
	FireFx.impact(at, b.dir, 18.0, false)
	Sfx.play("ui_tick", -16.0, 0.2, 1.3)

## Chain: a Lance passing a flame; at its second flame (up to kl_chain_max_gap from the last, no rock between)
## fire arcs between them: kl_chain_dmg to every foe within kl_chain_width of the line (full shell wear), then the
## line burns. A third lamp in line chains on from the second.
func _try_chain(b: Bolt, step: Vector2) -> void:
	var l := _flame_on(b.pos, step, Tuning.kl_chain_reach, b.flames)
	if l == null:
		return
	if not b.flames.is_empty():
		var last: Lantern = b.flames[-1]
		if is_instance_valid(last):
			chain(last, l)
	b.flames.append(l)

## Arcs fire between two lamps' flames, if they are close enough and no rock is between. Returns foes hit, or -1.
func chain(a: Lantern, c: Lantern) -> int:
	var p0 := a.flame_pos()
	var p1 := c.flame_pos()
	if p0.distance_to(p1) > Tuning.kl_chain_max_gap or _rock_between(a.global_position, c.global_position):
		return -1
	var g0 := a.global_position
	var g1 := c.global_position
	var n := 0
	for f in get_tree().get_nodes_in_group("foe"):
		if not (f is Foe) or f._dead or f.is_queued_for_deletion():
			continue
		var q := Geometry2D.get_closest_point_to_segment(f.global_position, g0, g1)
		if q.distance_to(f.global_position) <= Tuning.kl_chain_width + f.body_radius():
			f.hurt(Tuning.kl_chain_dmg * Progress.dmg_mult(), false, "chain")
			n += 1
	hits += n
	chains += 1
	a.gulp()
	c.gulp()
	var seam := ChainSeam.new()
	seam.a = p0
	seam.b = p1
	seam.ground_a = g0
	seam.ground_b = g1
	get_parent().add_child(seam)
	var k := _keeper()
	if k and k.has_method("shake"):
		k.shake(Tuning.kl_shake_chain)
	Sfx.play("relight", -10.0, 0.2, 1.4)
	return n

func _rock_between(a: Vector2, c: Vector2) -> bool:
	var fog := _fog()
	if fog == null:
		return false
	var steps := int(a.distance_to(c) / 16.0)
	for i in range(1, steps):
		if fog.is_solid_at(a.lerp(c, float(i) / float(steps))):
			return true
	return false

## Fireglobe lands: 8 in 90 px (no shells), then burning ground; camera trauma, a ring flash, a big pop.
## M1c: on a flame it flares the lamp instead (a lamp on its flare cooldown: the normal burst); in the Ashbrood's
## bowl it stirs the ember.
func _globe_burst(at: Vector2, dir: Vector2 = Vector2.RIGHT) -> int:
	var lamp := Lantern.flame_near(at, Tuning.kl_flare_reach)
	if lamp and lamp.can_flare():
		return _flare_burst(lamp)
	_globe_picks(at, dir)
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.guardian_awake() and at.distance_to(w.global_position) <= Ashbrood.BOWL_RADIUS:
			var g = w.guardian()
			if g and g.stir_ember():
				embers += 1
	if Progress.has_pick("fire_line"):
		# Fire line: the globe lands as a line of small bursts across the aim, instead of one big one.
		var side := dir.orthogonal()
		var c := Tuning.kl_fire_line_count
		var n_line := 0
		for i in c:
			var p := at + side * (float(i) - float(c - 1) * 0.5) * Tuning.kl_fire_line_gap
			n_line += _small_burst(p, Tuning.kl_fire_line_mult, Tuning.kl_fire_line_radius, true)
		var kk := _keeper()
		if kk and kk.has_method("shake"):
			kk.shake(Tuning.kl_shake_globe)
		return n_line
	if Progress.has_pick("undertow"):
		# Undertow: foes near the blast are pulled in before it bursts.
		for f in area(at, Tuning.kl_fireglobe_radius * Tuning.kl_undertow_reach):
			var v: Vector2 = at - f.global_position
			if v.length() > 4.0:
				f.knock(v.normalized() * minf(Tuning.kl_undertow_pull, v.length()))
	var n := 0
	for f in area(at, Tuning.kl_fireglobe_radius):
		f.hurt(Tuning.kl_fireglobe_dmg * Progress.dmg_mult(), false, "fireglobe")
		if Tuning.kl_fireglobe_dmg >= Tuning.kl_hitstop_big and is_instance_valid(f) and not f._dead:
			f.hit_stop(Tuning.kl_hitstop)
		n += 1
	hits += n
	_ground(at, Tuning.kl_fireglobe_radius, Tuning.kl_fireglobe_burn_time)
	FireFx.blast(at, Tuning.kl_fireglobe_radius, Tuning.kl_fireglobe_pop_clear)
	var k := _keeper()
	if k and k.has_method("shake"):
		k.shake(Tuning.kl_shake_globe)
		if n > 0 and k.has_method("hit_stop"):
			k.hit_stop(Tuning.kl_hitstop)
	Sfx.play("relight", -6.0, 0.25)
	return n

## Burning ground with the keeper's Slick pick.
func _ground(at: Vector2, radius: float, life: float, dps: float = -1.0) -> BurningGround:
	var g := BurningGround.new()
	g.radius = radius
	g.dps = Tuning.kl_fireglobe_burn_dps if dps < 0.0 else dps
	g.life = life
	g.slick = Progress.has_pick("slick")
	g.position = at
	get_parent().add_child(g)
	return g

## Picks that add to a full globe's landing: Skipping globe (a hop on), Cluster (4 small globes), Beacon (light).
func _globe_picks(at: Vector2, dir: Vector2) -> void:
	if Progress.has_pick("skipping_globe"):
		var s := _globe(at, at + dir * Tuning.kl_skip_globe_dist, Tuning.kl_skip_globe_flight)
		s.small = true
		s.g_mult = Tuning.kl_skip_globe_mult
		s.g_radius = Tuning.kl_fireglobe_radius * Tuning.kl_skip_globe_mult
	if Progress.has_pick("cluster"):
		for i in Tuning.kl_cluster_count:
			var a := dir.angle() + TAU * float(i) / float(maxi(1, Tuning.kl_cluster_count)) + PI / 4.0
			var c := _globe(at, at + Vector2.from_angle(a) * Tuning.kl_cluster_dist, 0.3)
			c.small = true
			c.g_mult = Tuning.kl_cluster_dmg / maxf(Tuning.kl_fireglobe_dmg, 0.01)
			c.g_radius = Tuning.kl_cluster_radius
	if Progress.has_pick("beacon"):
		var l := KeeperLight.new()
		l.kind = "beacon"
		l.radius = Tuning.kl_beacon_radius
		l.life = Tuning.kl_beacon_time
		l.position = at
		get_parent().add_child(l)
		beacons += 1

## A small globe's burst (Second globe, Skipping globe, Cluster, Fire line): damage x mult in radius, short ground.
func _small_burst(at: Vector2, mult: float, radius: float, ground: bool = true) -> int:
	var r := radius if radius > 0.0 else Tuning.kl_fireglobe_radius
	var n := 0
	for f in area(at, r):
		f.hurt(Tuning.kl_fireglobe_dmg * mult * Progress.dmg_mult(), false, "fireglobe")
		n += 1
	hits += n
	if ground:
		_ground(at, r, Tuning.kl_fireglobe_burn_time * 0.66)
	FireFx.blast(at, r, Tuning.kl_fireglobe_pop_clear * 0.5)
	Sfx.play("relight", -12.0, 0.25, 1.2)
	return n

## Flare: the lamp flares (16 in 160 px, no shell wear; burning ground in 140 px; its light x1.5 for 3 s).
func _flare_burst(lamp: Lantern) -> int:
	lamp.flare()
	flares += 1
	var at := lamp.flame_pos()
	var ground_at := lamp.global_position
	var n := 0
	for f in area(ground_at, Tuning.kl_flare_radius):
		f.hurt(Tuning.kl_flare_dmg * Progress.dmg_mult(), false, "fireglobe")
		if is_instance_valid(f) and not f._dead:
			f.hit_stop(Tuning.kl_hitstop)
		n += 1
	hits += n
	var g := BurningGround.new()
	g.radius = Tuning.kl_flare_ground_radius
	g.dps = Tuning.kl_fireglobe_burn_dps
	g.life = Tuning.kl_flare_time
	g.position = ground_at
	get_parent().add_child(g)
	FireFx.blast(at, Tuning.kl_flare_radius, Tuning.kl_fireglobe_pop_clear)
	var k := _keeper()
	if k and k.has_method("shake"):
		k.shake(Tuning.kl_shake_flare)
		if n > 0 and k.has_method("hit_stop"):
			k.hit_stop(Tuning.kl_hitstop)
	Sfx.play("relight", -3.0, 0.2, 0.8)
	return n

# --- Drawing -------------------------------------------------------------------------------------------

func _process(_delta: float) -> void:
	if in_flight() > 0:
		queue_redraw()

func _draw() -> void:
	var fm := maxf(Settings.flash_mult(), 0.6)
	for b in bolts:
		if not b.alive:
			continue
		match b.kind:
			LAMPFIRE:
				if b.big:
					_draw_bolt(b, Color(1.0, 0.78, 0.36), 24.0, 7.0, fm)   # Comet: a big bolt
				elif b.caught and not b.no_catch:
					_draw_bolt(b, Color(1.0, 0.82, 0.42), 20.0, 5.5, fm)   # caught: it swells and brightens
				else:
					_draw_bolt(b, Color(1.0, 0.72, 0.32), 14.0 if not b.no_catch else 10.0, 4.0 if not b.no_catch else 3.0, fm)
			LANCE:
				_draw_bolt(b, Color(1.0, 0.95, 0.75), 11.0, 3.0, fm)
			GLOBE:
				if b.delay <= 0.0:
					_draw_globe(b, fm)

func _draw_bolt(b: Bolt, col: Color, glow: float, core: float, fm: float) -> void:
	var n := b.trail.size()
	for i in range(n - 1):
		var k := float(i + 1) / float(n)
		draw_line(b.trail[i], b.trail[i + 1], Color(col, 0.55 * k * fm), core * 2.0 * k)
	if b.kind == LANCE:
		draw_line(b.pos - b.dir * 16.0, b.pos + b.dir * 6.0, Color(1, 1, 1, 0.9), 3.0)
	draw_texture_rect(_glow, Rect2(b.pos - Vector2(glow, glow), Vector2(glow, glow) * 2.0), false, Color(col, 0.7 * fm))
	draw_circle(b.pos, core, Color(1.0, 0.95, 0.8, 0.95))

func _draw_globe(b: Bolt, fm: float) -> void:
	var k := clampf(b.age / b.flight, 0.0, 1.0)
	# The ground marker: where it lands and how wide it burns, closing in as it falls.
	var r := b.g_radius if b.g_radius > 0.0 else Tuning.kl_fireglobe_radius
	draw_arc(b.to, r, 0.0, TAU, 40, Color(1.0, 0.6, 0.25, 0.25 + 0.35 * k), 2.0)
	draw_arc(b.to, r * (1.0 - 0.75 * k), 0.0, TAU, 32, Color(1.0, 0.8, 0.45, 0.6), 2.0)
	draw_circle(b.to, 3.0, Color(1.0, 0.85, 0.5, 0.8))
	# Its shadow on the ground under it, then the globe in the air with a short trail.
	var ground := b.from.lerp(b.to, k)
	draw_circle(ground, 6.0, Color(0.4, 0.2, 0.1, 0.3))
	var n := b.trail.size()
	for i in range(n - 1):
		var t := float(i + 1) / float(n)
		draw_line(b.trail[i], b.trail[i + 1], Color(1.0, 0.6, 0.25, 0.5 * t * fm), 8.0 * t)
	var flick := 1.0 + 0.12 * sin(b.age * 40.0)
	draw_texture_rect(_glow, Rect2(b.pos - Vector2(26, 26) * flick, Vector2(52, 52) * flick), false, Color(1.0, 0.6, 0.25, 0.75 * fm))
	draw_circle(b.pos, 8.0, Color(1.0, 0.78, 0.4, 0.95))
	draw_circle(b.pos, 4.0, Color(1.0, 0.97, 0.85, 1.0))
