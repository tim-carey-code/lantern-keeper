class_name SpitProjectile
extends Node2D
## Slow, readable cold spit. It travels through lantern light but a dash avoids the hit.
## Its reach (kl_spit_hit_radius + the keeper's body) is the half-width of the Spitwick's aim marker.

var direction := Vector2.RIGHT
var dmg_mult := 1.0            # its Spitwick's damage by level (M1c)
# M1c: the Ashbrood's ash bolts are the same shot with their own numbers (-1: the Spitwick's).
var speed := -1.0
var warmth := -1.0
var life := -1.0
var subject := "spitwick"
var _life := 0.0
var _splash := 0.0             # > 0: it hit something and is splashing

func _ready() -> void:
	_life = Tuning.kl_spit_life if life < 0.0 else life
	z_index = 11

func _process(delta: float) -> void:
	if _splash > 0.0:
		_splash -= delta
		if _splash <= 0.0:
			queue_free()
		queue_redraw()
		return
	_life -= delta
	global_position += direction * (Tuning.kl_spit_speed if speed < 0.0 else speed) * delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and not p.combat.is_dashing() and p.global_position.distance_to(global_position) <= Tuning.kl_spit_hit_radius + Telegraph.KEEPER_RADIUS:
		p.chill((Tuning.kl_spit_warmth if warmth < 0.0 else warmth) * dmg_mult)
		p.lamp_charge = maxf(0.0, p.lamp_charge - Tuning.kl_spit_charge)
		_splash = 0.15
	elif _life <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	if _splash > 0.0:
		var k := 1.0 - _splash / 0.15
		draw_arc(Vector2.ZERO, 6.0 + 14.0 * k, 0.0, TAU, 16, Color(Telegraph.COLD, 0.9 * (1.0 - k)), 2.0)
		return
	var alpha := clampf(_life / (Tuning.kl_spit_life if life < 0.0 else life), 0.0, 1.0)
	# A short cold trail behind it.
	for i in 3:
		draw_circle(-direction * (7.0 + i * 6.0), 4.0 - i, Color(Telegraph.COLD, 0.35 * alpha * (1.0 - i * 0.3)))
	draw_circle(Vector2.ZERO, Tuning.kl_spit_hit_radius, Color(0.55, 0.75, 0.96, 0.3 * alpha))
	draw_circle(Vector2.ZERO, 5.0, Color(0.74, 0.88, 1.0, 0.9 * alpha))
	draw_circle(Vector2.ZERO, 2.0, Color(1, 1, 1, alpha))
