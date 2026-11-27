class_name SpitProjectile
extends Node2D
## Slow, readable cold spit. It travels through lantern light but a dash avoids the hit.

var direction := Vector2.RIGHT
var _life := 0.0

func _ready() -> void:
	_life = Tuning.kl_spit_life
	z_index = 11

func _process(delta: float) -> void:
	_life -= delta
	global_position += direction * Tuning.kl_spit_speed * delta
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p and not p.combat.is_dashing() and p.global_position.distance_to(global_position) <= Tuning.kl_spit_hit_radius + 8.0:
		p.chill(Tuning.kl_spit_warmth)
		p.lamp_charge = maxf(0.0, p.lamp_charge - Tuning.kl_spit_charge)
		queue_free()
	elif _life <= 0.0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha := clampf(_life / Tuning.kl_spit_life, 0.0, 1.0)
	draw_circle(Vector2.ZERO, Tuning.kl_spit_hit_radius, Color(0.55, 0.75, 0.96, 0.3 * alpha))
	draw_circle(Vector2.ZERO, 5.0, Color(0.74, 0.88, 1.0, 0.9 * alpha))
