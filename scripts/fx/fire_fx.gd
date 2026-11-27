class_name FireFx
extends Node2D
## The fire's feedback (GAME_PLAN §15, brief §4), drawn by one node with an additive material (no
## PointLight2D): cast flares at the lamp, impact flashes, sparks, rings, light pops that clear fog, and
## kill bursts. A child draws the scorch marks with a normal blend, under the foes, where they linger.
## Light pops are also fog lights (group "light_points") and clear fog at once (FogGrid.clear_burst).
## "Reduce flashes" (Settings) dims every flash and pop.

static var inst: FireFx

const MAX_FX := 96
const MAX_SCORCH := 40

# Each effect: [kind, pos, radius, age, life, color, vel]
enum { FLASH, RING, SPARK, POP }
var _fx: Array = []
var _scorch: Array = []   # [pos, radius, age, life]
var under: Node2D

func _enter_tree() -> void:
	inst = self
	add_to_group("light_points")

func _exit_tree() -> void:
	if inst == self:
		inst = null

func _ready() -> void:
	z_index = 12
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	under = Node2D.new()
	under.name = "Scorch"
	under.z_index = -9     # 3 on the fog layer: over the ground and fog, under the foes
	under.use_parent_material = false
	under.material = CanvasItemMaterial.new()
	under.draw.connect(_draw_scorch)
	add_child(under)
	set_process(false)

# --- Spawning (static helpers: nothing happens if there is no FireFx in the scene) ---------------

static func cast_flare(at: Vector2, dir: Vector2, big: bool = false) -> void:
	if inst:
		inst._add(FLASH, at + dir * 6.0, 14.0 if big else 9.0, 0.08, Color(1.0, 0.86, 0.55))

## A bolt hits: a white-gold flash, sparks back along its path, and (for Lampfire) a light pop.
static func impact(at: Vector2, dir: Vector2, radius: float, pop: bool = true) -> void:
	if inst == null:
		return
	inst._add(FLASH, at, radius * 0.7, 0.12, Color(1.0, 0.95, 0.78))
	for i in 5:
		var v := (-dir).rotated(randf_range(-1.1, 1.1)) * randf_range(60.0, 170.0)
		inst._add(SPARK, at, 2.0, randf_range(0.18, 0.32), Color(1.0, 0.75, 0.38), v)
	if pop:
		inst.light_pop(at, Tuning.kl_lampfire_pop, Tuning.kl_lampfire_pop_clear)
	inst._scorch_at(at, radius * 0.45, 3.0)

## A blast (Fireglobe, Hearth ring): a ring flung outwards and a broad flash.
static func blast(at: Vector2, radius: float, clear: float = 0.0) -> void:
	if inst == null:
		return
	inst._add(FLASH, at, radius * 0.6, 0.16, Color(1.0, 0.85, 0.55))
	inst._add(RING, at, radius, 0.3, Color(1.0, 0.82, 0.5))
	for i in 10:
		var v := Vector2.from_angle(randf() * TAU) * randf_range(90.0, 220.0)
		inst._add(SPARK, at, 2.5, randf_range(0.22, 0.4), Color(1.0, 0.7, 0.32), v)
	if clear > 0.0:
		inst.light_pop(at, radius * 1.2, clear)

## A kill: a pale burst where it was (bigger for elites and bosses).
static func kill_burst(at: Vector2, radius: float, big: bool) -> void:
	if inst == null:
		return
	inst._add(FLASH, at, radius * (1.6 if big else 1.2), 0.14 if big else 0.1, Color(0.92, 0.95, 1.0))
	if big:
		inst._add(RING, at, radius * 2.5, 0.3, Color(0.8, 0.88, 1.0))
	for i in (8 if big else 4):
		var v := Vector2.from_angle(randf() * TAU) * randf_range(50.0, 140.0)
		inst._add(SPARK, at, 2.0, randf_range(0.2, 0.35), Color(0.78, 0.88, 1.0), v)
	inst._scorch_at(at, radius * 0.8, 5.0)

## A brief light that clears fog: drawn as a soft glow and lit in the fog for a moment.
func light_pop(at: Vector2, radius: float, clear: float) -> void:
	_add(POP, at, radius, 0.35, Color(1.0, 0.85, 0.55))
	var fog := get_tree().get_first_node_in_group("fog_grid") as FogGrid if is_inside_tree() else null
	if fog and clear > 0.0:
		fog.clear_burst(at, radius, clear)

func _add(kind: int, at: Vector2, radius: float, life: float, color: Color, vel: Vector2 = Vector2.ZERO) -> void:
	if _fx.size() >= MAX_FX:
		_fx.pop_front()
	_fx.append([kind, at, radius, 0.0, life, color, vel])
	set_process(true)

func _scorch_at(at: Vector2, radius: float, life: float) -> void:
	if _scorch.size() >= MAX_SCORCH:
		_scorch.pop_front()
	_scorch.append([at, radius, 0.0, life])
	set_process(true)

func count() -> int:
	return _fx.size()

## Fog lights for the pops still glowing.
func light_points() -> PackedVector3Array:
	var out := PackedVector3Array()
	for e in _fx:
		if e[0] == POP and e[3] < e[4]:
			out.append(Vector3(e[1].x, e[1].y, e[2] * (1.0 - e[3] / e[4])))
	return out

func _process(delta: float) -> void:
	var i := 0
	while i < _fx.size():
		var e: Array = _fx[i]
		e[3] += delta
		if e[0] == SPARK:
			e[1] += e[6] * delta
			e[6] *= 0.9
		if e[3] >= e[4]:
			_fx.remove_at(i)
		else:
			i += 1
	i = 0
	while i < _scorch.size():
		_scorch[i][2] += delta
		if _scorch[i][2] >= _scorch[i][3]:
			_scorch.remove_at(i)
		else:
			i += 1
	queue_redraw()
	under.queue_redraw()
	if _fx.is_empty() and _scorch.is_empty():
		set_process(false)

func _draw() -> void:
	var fm := Settings.flash_mult()
	var glow := LightTex.radial()
	for e in _fx:
		var t: float = e[3] / e[4]
		var col: Color = e[5]
		match e[0]:
			FLASH:
				var r: float = e[2] * (0.6 + 0.6 * t)
				draw_circle(e[1], r, Color(col, (1.0 - t) * 0.55 * fm))
				draw_circle(e[1], r * 0.45, Color(1, 1, 1, (1.0 - t) * 0.8 * fm))
			RING:
				var rr: float = e[2] * (0.35 + 0.65 * t)
				draw_arc(e[1], rr, 0.0, TAU, 48, Color(col, (1.0 - t) * 0.85 * maxf(fm, 0.5)), 3.0 + 3.0 * (1.0 - t))
			SPARK:
				draw_rect(Rect2(e[1] - Vector2(1, 1), Vector2(2, 2) * e[2]), Color(col, 1.0 - t))
			POP:
				var pr: float = e[2] * (0.7 + 0.3 * t)
				draw_texture_rect(glow, Rect2(e[1] - Vector2(pr, pr), Vector2(pr, pr) * 2.0), false, Color(col, (1.0 - t) * 0.35 * fm))

func _draw_scorch() -> void:
	for s in _scorch:
		var at: Vector2 = s[0]
		var r: float = s[1]
		var age: float = s[2]
		var k: float = 1.0 - age / float(s[3])
		var a := clampf(k * 2.0, 0.0, 1.0)
		under.draw_circle(at, r, Color(0.06, 0.04, 0.03, 0.45 * a))
		under.draw_arc(at, r, 0.0, TAU, 20, Color(0.55, 0.25, 0.1, 0.35 * a), 1.5)
		# A few embers that blink out as it cools.
		for j in 3:
			var off := Vector2.from_angle(j * 2.1 + r) * r * 0.55
			if fmod(age * 3.0 + j, 1.0) < 0.6 * k:
				under.draw_rect(Rect2(at + off, Vector2(2, 2)), Color(1.0, 0.6, 0.25, a))
