class_name ColdEmber
extends Node2D
## A cold ember the Ashbrood leaves along its low pass (M2, phase 2 and 3). Cold blue ash, never amber (art §1.4:
## amber is only the keeper's fire, lamps and the ember). For kl_cold_ember_warm it only glows (the spawn-glow
## rule: it can't hurt you yet), then for the rest of kl_cold_ember_life it chills a keeper standing in it,
## kl_cold_ember_chill every kl_wick_chill_tick (a dash, as always, takes nothing). The circle drawn is the hitbox.
## A faint clears them (FaintRule: group "cold_ember").

var radius := 26.0
var life := 4.0
var age := 0.0
var _tick := 0.0
var chilled := 0.0               # warmth taken so far (tests)

func _ready() -> void:
	add_to_group("cold_ember")
	z_index = 4
	radius = Tuning.kl_cold_ember_radius
	life = Tuning.kl_cold_ember_life

func armed() -> bool:
	return age >= Tuning.kl_cold_ember_warm

func contains(p: Vector2) -> bool:
	return p.distance_to(global_position) <= radius

func _process(delta: float) -> void:
	age += delta
	if age >= life:
		queue_free()
		return
	_tick = maxf(0.0, _tick - delta)
	if armed() and _tick <= 0.0:
		var k := get_tree().get_first_node_in_group("player") as Node2D
		if k and contains(k.global_position) and not k.combat.is_dashing():
			_tick = maxf(0.05, Tuning.kl_wick_chill_tick)
			var amt := Tuning.kl_cold_ember_chill * (1.0 + Tuning.kl_foe_dmg_per_level * float(Tuning.kl_ashbrood_level - 1))
			k.chill(amt)
			chilled += amt
			if "frost_t" in k:
				k.frost_t = 0.15
	queue_redraw()

func _draw() -> void:
	var fade := clampf((life - age) / 0.6, 0.0, 1.0)
	if not armed():
		# The spawn glow: the edge at full size from the first frame, filling as it warms (telegraph rule 2).
		var k := clampf(age / maxf(Tuning.kl_cold_ember_warm, 0.01), 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(Telegraph.COLD, 0.7), 1.5)
		draw_circle(Vector2.ZERO, radius * k, Color(Telegraph.COLD_DEEP, 0.25))
		return
	var flick := 0.85 + 0.15 * sin(age * 9.0 + position.x)
	draw_circle(Vector2.ZERO, radius, Color(0.16, 0.22, 0.34, 0.45 * fade))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, Color(Telegraph.COLD, 0.55 * fade * flick), 2.0)
	for i in 5:
		var a := TAU * float(i) / 5.0 + age * 0.7
		draw_circle(Vector2.from_angle(a) * radius * 0.5, 2.5, Color(0.74, 0.84, 0.95, 0.7 * fade * flick))
