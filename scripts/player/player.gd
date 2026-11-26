extends CharacterBody2D
## The keeper (grey-box circle). Moves, carries the hand lamp, places,
## refuels and picks up lanterns. Keyboard/mouse and gamepad.

@export var speed := 160.0
const REACH := 56.0   # px to refuel / pick up a lantern

var lamp: PointLight2D
var fuel_poured := 0.0

func _ready() -> void:
	add_to_group("light_source")
	add_to_group("player")
	z_index = 20
	lamp = PointLight2D.new()
	lamp.texture = LightTex.radial()
	lamp.color = Color(1.0, 0.86, 0.62)
	lamp.energy = 0.9
	add_child(lamp)

func get_light_radius() -> float:
	return Tuning.hand_lamp_radius

func _physics_process(_delta: float) -> void:
	lamp.texture_scale = LightTex.scale_for(Tuning.hand_lamp_radius)
	queue_redraw()
	if Tuning.ui_open:
		velocity = Vector2.ZERO
		return
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
	move_and_slide()
	var fog := _fog()
	if fog:
		position = position.clamp(Vector2.ZERO, fog.world_size())
	if Input.is_action_just_pressed("place_lantern"):
		try_place()
	elif Input.is_action_just_pressed("interact"):
		refuel_nearest()
	elif Input.is_action_just_pressed("cancel"):
		pick_up_nearest()

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func place_pos() -> Vector2:
	var fog := _fog()
	return fog.tile_center(fog.tile_of(global_position))

func can_place(p: Vector2) -> bool:
	var fog := _fog()
	if fog == null or fog.density_at(p) > FogGrid.PLACE_MAX_DENSITY:
		return false
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.global_position.distance_to(p) < FogGrid.TILE * 1.5:
			return false
	return true

func nearest_lantern() -> PostLamp:
	var best: PostLamp = null
	var best_d := REACH
	for l in get_tree().get_nodes_in_group("lantern"):
		var d: float = l.global_position.distance_to(global_position)
		if d < best_d:
			best = l
			best_d = d
	return best

func try_place() -> PostLamp:
	var p := place_pos()
	if not can_place(p):
		return null
	var lamp_node := PostLamp.new()
	lamp_node.position = p   # lantern root sits at the origin
	get_tree().get_first_node_in_group("lantern_root").add_child(lamp_node)
	return lamp_node

func refuel_nearest() -> void:
	var n := nearest_lantern()
	if n:
		fuel_poured += n.refuel(Tuning.refuel_amount)

func pick_up_nearest() -> void:
	var n := nearest_lantern()
	if n:
		n.queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 9.0, Color(0.92, 0.88, 0.75))
	var fog := _fog()
	if fog == null:
		return
	# Placement ghost: the tile and the radius a new lantern would light.
	var p := place_pos()
	var ok := can_place(p)
	var lp := to_local(p)
	var col := Color(0.6, 1.0, 0.6, 0.6) if ok else Color(1.0, 0.45, 0.4, 0.45)
	draw_rect(Rect2(lp - Vector2(16, 16), Vector2(32, 32)), col, false, 1.5)
	if ok:
		draw_arc(lp, Tuning.lantern_max_radius, 0.0, TAU, 72, Color(col, 0.35), 1.5)
