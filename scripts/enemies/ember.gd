class_name Ember
extends Node2D
## What a burned Wickling leaves behind: a glowing ember (fuel) or, sometimes, a bit of
## scrap. Drawn on the fog layer so it glows through the dark instead of being dimmed
## like the ground. Pulls toward the keeper when close, then collects on touch.
## M1a: also lamp oil (kind "oil"), one flask charge, from a pack's last foe, elites and bosses.
## Oil doesn't fade, and while every flask is full it stays where it fell.

const MAGNET := 140.0     # px: starts drifting toward the keeper (vacuums up drops near you)
const COLLECT := 18.0     # px: collected

var kind := "fuel"        # "fuel" (ember) or "scrap"
var amount := 1
var life := 0.0
var _t := 0.0

func _ready() -> void:
	add_to_group("ember")
	z_index = 8
	life = Tuning.ember_life if kind != "oil" else 1.0e9
	_t = randf() * 10.0

func _process(delta: float) -> void:
	_t += delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and kind == "oil":
		var to_k := player.global_position - global_position
		var room: bool = player.flasks < player.flask_max()
		if to_k.length() < COLLECT and room:
			player.add_flask(1)
			Sfx.play("gather_fuel", -6.0)
			FloatText.spawn(get_parent(), global_position + Vector2(0, -18), "+1 lamp oil", UiStyle.AMBER)
			queue_free()
			return
		elif to_k.length() < MAGNET and room:
			global_position += to_k.normalized() * minf(220.0 * delta, to_k.length())
	elif player:
		var to := player.global_position - global_position
		if to.length() < COLLECT:
			var got := Inventory.add(kind, amount)
			if got > 0:
				Sfx.play("gather_fuel" if kind == "fuel" else "gather_scrap", -8.0)
				FloatText.spawn(get_parent(), global_position + Vector2(0, -18), "+%d %s" % [got, kind], Color(1.0, 0.85, 0.5) if kind == "fuel" else Color(0.75, 0.82, 0.92))
				queue_free()
				return
		elif to.length() < MAGNET and Inventory.space(kind) > 0:
			global_position += to.normalized() * minf(220.0 * delta, to.length())
	queue_redraw()

func _draw() -> void:
	var fade := clampf(life / 5.0, 0.0, 1.0)    # fades over its last 5 seconds
	var bob := sin(_t * 3.0) * 2.0
	var pulse := 0.5 + 0.5 * sin(_t * 5.0)
	if kind == "oil":
		# A small amber flask with a bright ring, so it reads as "lamp oil" from afar.
		draw_circle(Vector2(0, bob), 18.0, Color(1.0, 0.65, 0.26, 0.14))
		draw_arc(Vector2(0, bob), 11.0 + pulse * 5.0, 0.0, TAU, 24, Color(1.0, 0.82, 0.48, 0.8 - pulse * 0.5), 2.0)
		draw_rect(Rect2(-2, -11 + bob, 4, 3), Color(0.61, 0.29, 0.13))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, -8 + bob), Vector2(3, -8 + bob), Vector2(6, -3 + bob), Vector2(6, 5 + bob), Vector2(-6, 5 + bob), Vector2(-6, -3 + bob)]), Color(0.96, 0.65, 0.26))
		draw_rect(Rect2(-4, 0 + bob, 8, 4), Color(1.0, 0.82, 0.48))
		draw_rect(Rect2(-4, -3 + bob, 2, 2), Color(1.0, 0.95, 0.76))
	elif kind == "fuel":
		# Warm glow, a pulsing ring and a flickering flame, so it reads as "ember" from afar.
		draw_circle(Vector2(0, bob), 16.0, Color(1.0, 0.6, 0.2, 0.12 * fade))
		draw_arc(Vector2(0, bob), 10.0 + pulse * 5.0, 0.0, TAU, 24, Color(1.0, 0.7, 0.3, (0.7 - pulse * 0.5) * fade), 1.5)
		var flick := sin(_t * 17.0) * 1.0
		draw_colored_polygon(PackedVector2Array([Vector2(-5, 4 + bob), Vector2(-3, -3 + bob), Vector2(0 + flick, -10 + bob), Vector2(3, -3 + bob), Vector2(5, 4 + bob)]), Color(0.96, 0.47, 0.17, fade))
		draw_colored_polygon(PackedVector2Array([Vector2(-3, 4 + bob), Vector2(-1, -1 + bob), Vector2(0 + flick * 0.6, -6 + bob), Vector2(1, -1 + bob), Vector2(3, 4 + bob)]), Color(1.0, 0.82, 0.48, fade))
		draw_rect(Rect2(-1, 1 + bob, 2, 2), Color(1.0, 0.95, 0.76, fade))
		# A couple of rising sparks.
		for i in 2:
			var k := fmod(_t * 0.8 + i * 0.5, 1.0)
			draw_rect(Rect2(-3 + i * 5 + sin(_t * 4.0 + i) * 2.0, -8 - k * 14 + bob, 2, 2), Color(1.0, 0.8, 0.4, (1.0 - k) * fade))
	else:
		# Cool glint, a pulsing ring and a little heap of metal bits.
		draw_arc(Vector2(0, bob), 10.0 + pulse * 5.0, 0.0, TAU, 24, Color(0.64, 0.74, 0.83, (0.7 - pulse * 0.5) * fade), 1.5)
		draw_colored_polygon(PackedVector2Array([Vector2(-7, 4 + bob), Vector2(-4, -3 + bob), Vector2(2, -5 + bob), Vector2(7, 4 + bob)]), Color(0.29, 0.42, 0.58, fade))
		draw_rect(Rect2(-3, -2 + bob, 3, 2), Color(0.64, 0.74, 0.83, fade))
		draw_rect(Rect2(2, 0 + bob, 2, 2), Color(0.43, 0.56, 0.7, fade))
		if pulse > 0.85:
			draw_rect(Rect2(1, -6 + bob, 2, 2), Color(1, 1, 1, fade))   # glint
