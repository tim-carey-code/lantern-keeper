class_name ChainSeam
extends Node2D
## The Lance's chain (M1c combo, PLAN_LANTERNS §3): a jagged warm arc from flame to flame, then a burning seam on
## the ground that burns foes on the line kl_chain_burn_dps for kl_chain_burn_time (fire that isn't a hit glances
## off a shell, like burning ground).

var a := Vector2.ZERO
var b := Vector2.ZERO
var ground_a := Vector2.ZERO   # the lamps' feet: the seam burns on the ground between them
var ground_b := Vector2.ZERO
var age := 0.0
var life := -1.0               # s it burns (-1: kl_chain_burn_time); M2 Lance "Burning line" sets its own
var dps := -1.0                # (-1: kl_chain_burn_dps)
var arc := true                # the bright arc between two flames (a chain); a Burning line has none
var _seed := 0.0

func _ready() -> void:
	z_index = 12
	_seed = randf() * 10.0
	if life < 0.0:
		life = Tuning.kl_chain_burn_time
	if dps < 0.0:
		dps = Tuning.kl_chain_burn_dps
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

func _physics_process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	for f in get_tree().get_nodes_in_group("foe"):
		if not (f is Foe) or f._dead or f.is_queued_for_deletion():
			continue
		var q := Geometry2D.get_closest_point_to_segment(f.global_position, ground_a, ground_b)
		if q.distance_to(f.global_position) <= Tuning.kl_chain_width * 0.5 + f.body_radius():
			f.hurt(dps * Progress.dmg_mult() * delta, false, "ground")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var life_s := maxf(life, 0.01)
	var k := clampf(age / life_s, 0.0, 1.0)
	var fm := maxf(Settings.flash_mult(), 0.6)
	# The arc: bright for its first 0.25 s, jagged, warm.
	if arc and age < 0.25:
		var pts := PackedVector2Array()
		var n := 10
		var d := (b - a)
		var side := d.orthogonal().normalized()
		for i in n + 1:
			var t := float(i) / float(n)
			var j := 0.0 if i == 0 or i == n else sin(_seed + i * 2.7 + age * 60.0) * 7.0
			pts.append(a + d * t + side * j)
		draw_polyline(pts, Color(1.0, 0.8, 0.45, 0.6 * fm), 6.0)
		draw_polyline(pts, Color(1.0, 0.97, 0.85, 0.95), 2.0)
	# The burning seam on the ground (from the lamps' feet).
	var g0 := ground_a
	var g1 := ground_b
	draw_line(g0, g1, Color(0.35, 0.15, 0.05, 0.5 * (1.0 - k)), 8.0)
	draw_line(g0, g1, Color(1.0, 0.6, 0.25, 0.55 * (1.0 - k) * fm), 3.0)
