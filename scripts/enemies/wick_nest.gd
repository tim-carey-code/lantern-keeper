class_name WickNest
extends Foe
## Fixed Hollow lure. Its cold glows show through fog. Only the bright core of a built lantern burns it.

var _hatch_t := 10.0
var _pulse := 0.0

func _ready() -> void:
	foe_name = "Wick nest"
	hp = Tuning.kl_nest_hp
	if foe_id == "":
		foe_id = "nest_hollow"
	wick_value = Tuning.kl_nest_wick
	z_index = 6

func hurt(amount: float, scare: bool = true, source: String = "") -> void:
	if source != "core":
		return
	super.hurt(amount, scare, source)

func _process(delta: float) -> void:
	tick_foe(delta)
	if is_queued_for_deletion():
		return
	if fade_if_held(delta):
		return
	_pulse += delta
	var player := _player()
	if player and player.global_position.distance_to(global_position) <= Tuning.kl_nest_wake_radius and not Progress.cleared.has(foe_id):
		_hatch_t -= delta
		if _hatch_t <= 0.0:
			_hatch_t = Tuning.kl_nest_hatch_sec
			if get_tree().get_nodes_in_group("wickling").size() >= Tuning.wick_max:
				queue_redraw()
				return
			for i in Tuning.kl_nest_hatch_count:
				var w := Wickling.new()
				w.summoned = true
				w.position = global_position + Vector2.from_angle(i * TAU / 3) * 24.0
				get_parent().add_child(w)
	queue_redraw()

func body_radius() -> float:
	return 16.0

func _draw() -> void:
	var p := 0.6 + 0.4 * sin(_pulse * 2.1)
	draw_colored_polygon(PackedVector2Array([Vector2(-18, 10), Vector2(-15, -2), Vector2(-7, -10), Vector2(4, -13), Vector2(15, -5), Vector2(18, 9), Vector2(7, 13), Vector2(-7, 14)]), Color(0.13, 0.22, 0.34, 0.98))
	draw_circle(Vector2(0, 0), 7.0 + p * 2.0, Color(0.48, 0.72, 0.92, 0.4))
	draw_circle(Vector2(-4, -2), 2.0, Color(0.78, 0.9, 1.0, p))
	draw_circle(Vector2(4, -2), 2.0, Color(0.78, 0.9, 1.0, p))
	if _burning > 0.0:
		draw_arc(Vector2.ZERO, 20.0, 0.0, TAU, 24, Color(1.0, 0.72, 0.4, 0.9), 2.5)
	if _hatch_t < 1.0:
		draw_arc(Vector2.ZERO, 25.0, -PI / 2.0, -PI / 2.0 + TAU * (1.0 - _hatch_t), 24, Color(0.62, 0.82, 1.0, 0.85), 2.0)
