class_name Ember
extends Node2D
## What a burned Wickling leaves behind. Walk over it to collect fuel. Fades after a while.

var life := 0.0
var light: PointLight2D

func _ready() -> void:
	add_to_group("ember")
	z_index = 15
	life = Tuning.ember_life
	light = PointLight2D.new()
	light.texture = LightTex.radial()
	light.texture_scale = LightTex.scale_for(40.0)
	light.color = Color(1.0, 0.7, 0.35)
	light.energy = 0.6
	add_child(light)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.global_position.distance_to(global_position) < 24.0:
		if Inventory.add("fuel", Tuning.ember_fuel) > 0:
			Sfx.play("gather_fuel", -10.0)
			queue_free()
			return
	light.energy = 0.45 + 0.2 * sin(Time.get_ticks_msec() * 0.008)
	queue_redraw()

func _draw() -> void:
	var fade := clampf(life / 5.0, 0.0, 1.0)
	var bob := sin(Time.get_ticks_msec() * 0.004) * 2.0
	draw_rect(Rect2(-3, -3 + bob, 6, 6), Color(1.0, 0.82, 0.48, fade))
	draw_rect(Rect2(-1, -1 + bob, 2, 2), Color(1.0, 0.95, 0.76, fade))
