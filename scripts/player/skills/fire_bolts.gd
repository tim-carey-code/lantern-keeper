class_name FireBolts
extends Node2D
## The keeper's fire in flight (M1a, GAME_PLAN §4.1, §15; brief §7): Lampfire bolts, Lance bolts and lobbed
## Fireglobes. One node holds them all as pooled entries (a spent bolt is reused, never freed), moves them in
## _physics_process, and draws them in one pass with an additive material (no PointLight2D).
## Hits: a shape cast along each tick's motion against the foes' hurtboxes (Foe.HURT_LAYER); blasts and
## splash: one intersect_shape at the point of impact. Walls: rock tiles (FogGrid.is_solid_at) stop bolts.
## While they fly, bolts and globes light the fog around them (group "light_points").

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

var bolts: Array[Bolt] = []
var hits := 0                    # foes hit so far (tests)
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
	b.trail.clear()
	b.trail.append(from)
	b.age = 0.0
	return b

func fire_lampfire(from: Vector2, dir: Vector2) -> Bolt:
	return _launch(LAMPFIRE, from, dir, Tuning.kl_lampfire_speed, Tuning.kl_lampfire_range, Tuning.kl_lampfire_hit_radius, 1)

func fire_lance(from: Vector2, dir: Vector2) -> Bolt:
	return _launch(LANCE, from, dir, Tuning.kl_lance_speed, Tuning.kl_lance_range, Tuning.kl_lance_hit_radius, Tuning.kl_lance_pierce)

func throw_globe(from: Vector2, to: Vector2) -> Bolt:
	var b := _launch(GLOBE, from, to - from, 0.0, 0.0, 8.0, 0)
	b.from = from
	b.to = to
	b.flight = maxf(0.05, Tuning.kl_fireglobe_flight)
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
	# Foes along this tick's motion, nearest first.
	var found := sweep(b.pos, step, b.radius)
	for f in found:
		if b.hit_ids.has(f.get_instance_id()):
			continue
		b.hit_ids[f.get_instance_id()] = true
		var at: Vector2 = b.pos + b.dir * maxf(0.0, (f.global_position - b.pos).dot(b.dir) - f.body_radius() * 0.5)
		if b.kind == LAMPFIRE:
			_lampfire_hit(f, at, b.dir)
			_end(b, at)
			return
		_lance_hit(f, at, b.dir)
		b.pierce -= 1
		if b.pierce <= 0:
			_end(b, at)
			return
	var next := b.pos + step
	var fog := _fog()
	if fog and fog.is_solid_at(next):
		if b.kind == LAMPFIRE:
			_lampfire_hit(null, b.pos, b.dir)   # it bursts on the rock, and its splash still lands
		else:
			FireFx.impact(b.pos, b.dir, 10.0, false)
		_end(b, b.pos)
		return
	b.pos = next
	b.travelled += step.length()
	b.trail.append(b.pos)
	if b.trail.size() > TRAIL:
		b.trail.remove_at(0)
	if b.travelled >= b.reach - 0.01:
		FireFx.impact(b.pos, b.dir, 6.0, false)   # it fizzles at the end of its reach: no burst
		_end(b, b.pos)

func _end(b: Bolt, _at: Vector2) -> void:
	b.alive = false
	b.trail.clear()

func _step_globe(b: Bolt) -> void:
	var k := clampf(b.age / b.flight, 0.0, 1.0)
	b.pos = b.from.lerp(b.to, k) + Vector2(0, -sin(k * PI) * Tuning.kl_fireglobe_arc)
	b.trail.append(b.pos)
	if b.trail.size() > TRAIL:
		b.trail.remove_at(0)
	if k >= 1.0:
		_globe_burst(b.to)
		b.alive = false
		b.trail.clear()

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
func _lampfire_hit(f: Foe, at: Vector2, dir: Vector2) -> void:
	var k := _keeper()
	if f:
		hits += 1
		f.hurt(Tuning.kl_lampfire_dmg, false, "lampfire")
		if k and not (f is WickNest):
			k.lamp_charge = minf(1.0, k.lamp_charge + Tuning.kl_lampfire_charge)
	for o in area(at, Tuning.kl_lampfire_splash):
		if o != f:
			o.hurt(Tuning.kl_lampfire_splash_dmg, false, "splash")
	FireFx.impact(at, dir, Tuning.kl_lampfire_splash)
	Sfx.play("ui_tick", -22.0, 0.25)

## Lance: full damage, wears shells fully, freezes what it hits for a moment.
func _lance_hit(f: Foe, at: Vector2, dir: Vector2) -> void:
	hits += 1
	f.hurt(Tuning.kl_lance_dmg, false, "lance")
	if Tuning.kl_lance_dmg >= Tuning.kl_hitstop_big and is_instance_valid(f) and not f._dead:
		f.hit_stop(Tuning.kl_hitstop)
	FireFx.impact(at, dir, 14.0, false)
	var k := _keeper()
	if k and k.has_method("shake"):
		k.shake(0.2)
	Sfx.play("ui_tick", -14.0, 0.3)

## Fireglobe lands: 8 in 90 px (no shells), then burning ground; camera trauma, a ring flash, a big pop.
func _globe_burst(at: Vector2) -> int:
	var n := 0
	for f in area(at, Tuning.kl_fireglobe_radius):
		f.hurt(Tuning.kl_fireglobe_dmg, false, "fireglobe")
		if Tuning.kl_fireglobe_dmg >= Tuning.kl_hitstop_big and is_instance_valid(f) and not f._dead:
			f.hit_stop(Tuning.kl_hitstop)
		n += 1
	hits += n
	var g := BurningGround.new()
	g.radius = Tuning.kl_fireglobe_radius
	g.dps = Tuning.kl_fireglobe_burn_dps
	g.life = Tuning.kl_fireglobe_burn_time
	g.position = at
	get_parent().add_child(g)
	FireFx.blast(at, Tuning.kl_fireglobe_radius, Tuning.kl_fireglobe_pop_clear)
	var k := _keeper()
	if k and k.has_method("shake"):
		k.shake(0.55)
		if n > 0 and k.has_method("hit_stop"):
			k.hit_stop(Tuning.kl_hitstop)
	Sfx.play("relight", -6.0, 0.25)
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
				_draw_bolt(b, Color(1.0, 0.72, 0.32), 14.0, 4.0, fm)
			LANCE:
				_draw_bolt(b, Color(1.0, 0.95, 0.75), 11.0, 3.0, fm)
			GLOBE:
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
	var r := Tuning.kl_fireglobe_radius
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
