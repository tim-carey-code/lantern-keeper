class_name DamageNumbers
extends Node2D
## Damage numbers (GAME_PLAN §14, brief §4): pop, then drift up and fade. One node draws them all, so a
## stream of Lampfire hits costs no new nodes. Lives on the fog layer, over the dark.
## Colours: cream for a hit, pale blue for damage to a shell, dim for splash, amber for steady burning.

const FONT := preload("res://assets/fonts/ark_pixel_10px_proportional_latin.ttf")
const LIFE := 0.75
const MAX := 48                  # oldest go first past this

static var inst: DamageNumbers

var _pos := PackedVector2Array()
var _val := PackedFloat32Array()
var _age := PackedFloat32Array()
var _col: Array[Color] = []
var _drift := PackedFloat32Array()

func _enter_tree() -> void:
	inst = self
	z_index = 14

func _exit_tree() -> void:
	if inst == self:
		inst = null

## Adds a number at a world position. kind: "hit", "shell", "small", "steady".
static func add(at: Vector2, amount: float, kind: String = "hit") -> void:
	if inst == null or amount <= 0.0:
		return
	inst._add(at, amount, kind)

func _add(at: Vector2, amount: float, kind: String) -> void:
	if _pos.size() >= MAX:
		_pos.remove_at(0)
		_val.remove_at(0)
		_age.remove_at(0)
		_col.remove_at(0)
		_drift.remove_at(0)
	var c := UiStyle.CREAM
	match kind:
		"shell":
			c = UiStyle.PALE
		"small":
			c = Color(0.85, 0.78, 0.62)
		"steady":
			c = UiStyle.AMBER
	_pos.append(at + Vector2(randf_range(-6.0, 6.0), 0.0))
	_val.append(amount)
	_age.append(0.0)
	_col.append(c)
	_drift.append(randf_range(-10.0, 10.0))
	set_process(true)

func count() -> int:
	return _pos.size()

func _ready() -> void:
	set_process(false)

func _process(delta: float) -> void:
	var i := 0
	while i < _age.size():
		_age[i] += delta
		if _age[i] >= LIFE:
			_pos.remove_at(i)
			_val.remove_at(i)
			_age.remove_at(i)
			_col.remove_at(i)
			_drift.remove_at(i)
		else:
			i += 1
	queue_redraw()
	if _pos.is_empty():
		set_process(false)

func _draw() -> void:
	for i in _pos.size():
		var t := _age[i] / LIFE
		var a := clampf(1.0 - (t - 0.5) * 2.0, 0.0, 1.0)
		var size := 30 if t < 0.12 else 20   # the pop, then the drift
		var p := _pos[i] + Vector2(_drift[i] * t, -28.0 * t)
		var v := _val[i]
		var txt := str(roundi(v)) if v >= 0.95 else ("%.1f" % v)
		var w := FONT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(FONT, p + Vector2(-w / 2.0 + 2.0, 2.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, a * 0.85))
		draw_string(FONT, p + Vector2(-w / 2.0, 0.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(_col[i], a))
