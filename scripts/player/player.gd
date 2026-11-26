extends CharacterBody2D
## The keeper (grey-box circle). Moves, carries the hand lamp, gathers,
## builds, refuels and picks up lanterns. Keyboard/mouse and gamepad.

@export var speed := 160.0
const REACH := 52.0   # px to interact with a lantern or resource

var lamp: PointLight2D
var lamp_charge := 1.0          # 0 = ember, 1 = full hand lamp
var fuel_poured := 0.0
var _gather_target: ResourceNode = null
var _gather_acc := 0.0
var _facing_left := false
var _step_t := 0.0
var _walk_t := 0.0

func _ready() -> void:
	add_to_group("light_source")
	add_to_group("player")
	z_index = 20
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	lamp = PointLight2D.new()
	lamp.texture = LightTex.radial()
	lamp.color = Color(1.0, 0.86, 0.62)
	lamp.position = Vector2(10, -14)   # held in the keeper's hand
	add_child(lamp)

# --- Hand lamp -------------------------------------------------------------

func get_light_radius() -> float:
	return lerpf(Tuning.hand_lamp_ember_radius, Tuning.hand_lamp_max_radius, lamp_charge)

func in_lantern_light() -> bool:
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.is_lit() and l.global_position.distance_to(global_position) < l.get_light_radius() * 0.85:
			return true
	return false

func update_hand_lamp(delta: float) -> void:
	if in_lantern_light():
		lamp_charge = minf(1.0, lamp_charge + Tuning.hand_lamp_recharge_per_sec * delta)
	else:
		lamp_charge = maxf(0.0, lamp_charge - Tuning.hand_lamp_drain_per_sec * delta)
		if lamp_charge < 0.25 and Inventory.spend("fuel", 1):
			lamp_charge = minf(1.0, lamp_charge + Tuning.hand_lamp_charge_per_fuel)

# --- Frame -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	update_hand_lamp(delta)
	lamp.texture_scale = LightTex.scale_for(get_light_radius())
	lamp.energy = lerpf(0.35, 0.6, lamp_charge)
	queue_redraw()
	if Tuning.ui_open:
		velocity = Vector2.ZERO
		_gather_target = null
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var fog := _fog()
	var slow := 1.0
	if fog and dir != Vector2.ZERO:
		slow = lerpf(1.0, Tuning.fog_slow_min, fog.density_at(global_position + dir * 24.0))
	if fog and fog.terrain_at(global_position) == FogGrid.T_MARSH:
		slow *= 0.85   # wading through the marsh
	velocity = dir * speed * slow
	move_and_slide()
	_footsteps(dir, _physics_delta(), fog)
	if fog:
		position = position.clamp(Vector2.ZERO, fog.world_size())
	if Progress.input_blocked():
		_gather_target = null
		return
	if Input.is_action_just_pressed("place_lantern"):
		try_place()
	elif Input.is_action_just_pressed("cancel"):
		pick_up_nearest()
	elif Input.is_action_just_pressed("interact"):
		begin_interact()
	if Input.is_action_pressed("interact"):
		continue_gather(delta)
	else:
		_gather_target = null

func _physics_delta() -> float:
	return get_physics_process_delta_time()

func _footsteps(dir: Vector2, delta: float, fog: FogGrid) -> void:
	if dir.x != 0.0:
		_facing_left = dir.x < 0.0
	if dir == Vector2.ZERO:
		_step_t = 0.0
		_walk_t = 0.0
		return
	_walk_t += delta
	_step_t -= delta
	if _step_t <= 0.0:
		_step_t = 0.36
		var surface := "step_grass"
		if fog:
			match fog.terrain_at(global_position):
				FogGrid.T_BOARDWALK:
					surface = "step_wood"
				FogGrid.T_MARSH:
					surface = "step_marsh"
		Sfx.play(surface, -20.0, 0.1)

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

# --- Interact: refuel or gather -------------------------------------------

## Nearest lantern, gatherable resource or revealed landmark within reach (or null).
func nearest_target() -> Node2D:
	var best: Node2D = null
	var best_d := REACH
	for m in get_tree().get_nodes_in_group("landmark"):
		if not m.is_revealed():
			continue
		var d: float = m.global_position.distance_to(global_position)
		if d < best_d:
			best = m
			best_d = d
	for l in get_tree().get_nodes_in_group("lantern"):
		var d: float = l.global_position.distance_to(global_position)
		if d < best_d:
			best = l
			best_d = d
	for r in get_tree().get_nodes_in_group("resource"):
		if not r.can_gather():
			continue
		var d: float = r.global_position.distance_to(global_position)
		if d < best_d:
			best = r
			best_d = d
	return best

func nearest_lantern() -> Lantern:
	var best: Lantern = null
	var best_d := REACH
	for l in get_tree().get_nodes_in_group("lantern"):
		var d: float = l.global_position.distance_to(global_position)
		if d < best_d:
			best = l
			best_d = d
	return best

func is_gathering() -> bool:
	return _gather_target != null and is_instance_valid(_gather_target)

func begin_interact() -> void:
	var t := nearest_target()
	if t is Landmark:
		t.activate()
	elif t is Lantern:
		refuel(t)
	elif t is ResourceNode:
		_gather_target = t
		_gather_acc = 0.0

func continue_gather(delta: float) -> void:
	if not is_gathering():
		return
	var target := _gather_target
	if not target.can_gather() or target.global_position.distance_to(global_position) > REACH:
		_gather_target = null
		return
	_gather_acc += delta
	while _gather_acc >= Tuning.gather_interval:
		_gather_acc -= Tuning.gather_interval
		if Inventory.space(target.kind) <= 0 or not target.can_gather():
			_gather_target = null
			return
		target.take()
		Inventory.add(target.kind, 1)
		Sfx.play("gather_scrap" if target.kind == "scrap" else "gather_fuel", -12.0)

## Pours carried fuel into a lantern (relights it if cold). Returns units used.
func refuel(l: Lantern) -> int:
	var missing := Tuning.lantern_max_fuel - l.fuel
	var units := mini(ceili(missing / Tuning.fuel_per_unit), Inventory.get_count("fuel"))
	if units <= 0:
		return 0
	var was_cold := not l.is_lit()
	Inventory.spend("fuel", units)
	fuel_poured += l.refuel(units * Tuning.fuel_per_unit)
	Sfx.play("refuel", -10.0)
	if was_cold:
		Sfx.play("relight", -12.0)
	return units

# --- Build / pick up -------------------------------------------------------

func place_pos() -> Vector2:
	var fog := _fog()
	return fog.tile_center(fog.tile_of(global_position))

## "" if the selected lantern can be built at p, otherwise a short reason.
func place_block_reason(p: Vector2) -> String:
	var fog := _fog()
	if fog == null:
		return "no map"
	var ground := fog.build_block(p)
	if ground != "":
		return ground
	if fog.density_at(p) > FogGrid.PLACE_MAX_DENSITY:
		return "too dark"
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.global_position.distance_to(p) < FogGrid.TILE * 1.5:
			return "too close to a lantern"
	var cost := Lantern.cost(Progress.selected)
	if Inventory.get_count("scrap") < cost:
		return "needs %d scrap" % cost
	return ""

func can_place(p: Vector2) -> bool:
	return place_block_reason(p) == ""

func try_place() -> Lantern:
	var p := place_pos()
	if not can_place(p):
		Sfx.play("ui_error", -16.0)
		return null
	Inventory.spend("scrap", Lantern.cost(Progress.selected))
	var lamp_node := Lantern.new()
	lamp_node.kind = Progress.selected
	lamp_node.position = p   # lantern root sits at the origin
	get_tree().get_first_node_in_group("lantern_root").add_child(lamp_node)
	Sfx.play("place_lantern", -8.0)
	return lamp_node

## Refunds part of the scrap plus the fuel left in the tank.
func pick_up_nearest() -> void:
	var l := nearest_lantern()
	if l == null:
		return
	Inventory.add("scrap", floori(Lantern.cost(l.kind) * Tuning.pickup_refund))
	Inventory.add("fuel", floori(l.fuel / Tuning.fuel_per_unit))
	Sfx.play("pickup_lantern", -10.0)
	l.remove_from_group("lantern")
	l.remove_from_group("light_source")
	l.queue_free()

# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	var bob := -2.0 if int(_walk_t / 0.18) % 2 == 1 else 0.0
	Art.cell_at_foot(self, Art.DUNGEON, Art.KEEPER, Vector2(0, 10 + bob), Color.WHITE, _facing_left)
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
		var preview := Tuning.reservoir_radius if Progress.selected == "reservoir" else Tuning.lantern_max_radius
		draw_arc(lp, preview, 0.0, TAU, 72, Color(col, 0.35), 1.5)
	# Gathering progress ring.
	if is_gathering():
		var t := to_local(_gather_target.global_position)
		draw_arc(t, 18.0, -PI / 2.0, -PI / 2.0 + TAU * (_gather_acc / Tuning.gather_interval), 24, Color(1, 0.85, 0.5, 0.9), 2.0)
