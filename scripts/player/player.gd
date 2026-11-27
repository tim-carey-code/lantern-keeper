extends CharacterBody2D
## The keeper (grey-box circle). Moves, carries the hand lamp, gathers,
## builds, refuels and picks up lanterns. Keyboard/mouse and gamepad.

@export var speed := 160.0
const REACH := 52.0   # px to interact with a lantern or resource

var lamp: PointLight2D
var lamp_charge := 1.0          # 0 = ember, 1 = full hand lamp
var fuel_poured := 0.0
var last_feed := ""          # what happened the last time you fed a WayLamp (for prompts and tests)
var warmth := 100.0            # PROTOTYPE: the keeper's "health". Never kills; fainting sends you home.
var warding := false
var _ward_grow := 0.0          # 0..1, how far the glow has swelled
var _since_ward := 99.0        # seconds since the ward was last used
var faints := 0
var _gather_target: ResourceNode = null
var _gather_acc := 0.0
var _facing_left := false
var _dir_row := 0          # Puny sheet row: 0 S, 1 SE, 2 E, 3 NE, 4 N, 5 NW, 6 W, 7 SW
var _idle_t := 0.0
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
	var r := lerpf(Tuning.hand_lamp_ember_radius, Tuning.hand_lamp_max_radius, lamp_charge)
	return maxf(r, Tuning.ward_radius * _ward_grow)   # the ward also pushes the fog back

func in_lantern_light() -> bool:
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.is_lit() and w.global_position.distance_to(global_position) < w.get_light_radius() * 0.85:
			return true
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.is_lit() and l.global_position.distance_to(global_position) < l.get_light_radius() * 0.85:
			return true
	return false

func update_hand_lamp(delta: float) -> void:
	if in_lantern_light():
		lamp_charge = minf(1.0, lamp_charge + Tuning.hand_lamp_recharge_per_sec * delta)
	else:
		lamp_charge = maxf(0.0, lamp_charge - Tuning.hand_lamp_drain_per_sec * delta)
		# Auto top-up from carried fuel keeps the lamp alive on long walks, but never feeds the ward.
		if lamp_charge < 0.25 and _since_ward > 4.0 and Inventory.spend("fuel", 1):
			lamp_charge = minf(1.0, lamp_charge + Tuning.hand_lamp_charge_per_fuel)

# --- Frame -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	update_hand_lamp(delta)
	_update_warmth(delta)
	lamp.texture_scale = LightTex.scale_for(get_light_radius())
	lamp.energy = lerpf(0.35, 0.6, lamp_charge)
	queue_redraw()
	if Tuning.ui_open:
		velocity = Vector2.ZERO
		_gather_target = null
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	update_ward(delta, Input.is_action_pressed("flare"))
	var fog := _fog()
	var slow := 1.0
	if fog and dir != Vector2.ZERO:
		slow = lerpf(1.0, Tuning.fog_slow_min, fog.density_at(global_position + dir * 24.0))
	if fog and fog.terrain_at(global_position) == FogGrid.T_MARSH:
		slow *= 0.85   # wading through the marsh
	if warding:
		slow *= Tuning.ward_walk_mult
	velocity = dir * speed * slow
	move_and_slide()
	_footsteps(dir, _physics_delta(), fog)
	if fog:
		position = position.clamp(Vector2.ZERO, fog.world_size())
	if Progress.input_blocked():
		_gather_target = null
		return
	if Input.is_action_just_pressed("place_lantern"):
		var near := nearest_target()
		if near is Lantern and near.kind == "mirror":
			near.turn(-1)   # X / Space next to a mirror turns it left
			Sfx.play("ui_tick", -10.0)
		else:
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
	if dir != Vector2.ZERO:
		var oct := posmod(int(round(dir.angle() / (PI / 4.0))), 8)   # 0 E, 1 SE, 2 S ...
		_dir_row = posmod(2 - oct, 8)
	_idle_t += delta
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

# --- Warding glow, warmth, fainting --------------------------------------

## Hold to swell the hand lamp into a warding glow. Spends lamp charge, not fuel.
func update_ward(delta: float, held: bool) -> void:
	warding = held and lamp_charge > Tuning.ward_min_charge
	_since_ward = 0.0 if warding else _since_ward + delta
	_ward_grow = move_toward(_ward_grow, 1.0 if warding else 0.0, delta * (5.0 if warding else 3.0))
	if warding:
		lamp_charge = maxf(0.0, lamp_charge - Tuning.ward_drain_per_sec * delta)
		apply_ward(delta)

## Burns and pushes back every Wickling inside the glow (including ones right on top of you).
func apply_ward(delta: float) -> int:
	var hit := 0
	var r := Tuning.ward_radius * maxf(_ward_grow, 0.35)
	for w in get_tree().get_nodes_in_group("wickling"):
		var v: Vector2 = w.global_position - global_position
		if v.length() <= r:
			w.hurt(Tuning.ward_dps * delta, false)
			if is_instance_valid(w) and not w.is_queued_for_deletion():
				w.push((v.normalized() if v.length() > 0.5 else Vector2.RIGHT) * Tuning.ward_push * delta)
			hit += 1
	return hit

func chill(amount: float) -> void:
	warmth = maxf(0.0, warmth - amount)
	if warmth <= 0.0:
		faint()

func _update_warmth(delta: float) -> void:
	if in_lantern_light():
		warmth = minf(Tuning.warmth_max, warmth + Tuning.warmth_regen_per_sec * delta)

## Out of warmth: drop part of what you carry where you fell, wake at the nearest lit lantern (or the hut).
func faint() -> void:
	faints += 1
	var main := get_tree().get_first_node_in_group("main")
	for kind in ["fuel", "scrap"]:
		var lost := int(floor(Inventory.get_count(kind) * Tuning.faint_drop))
		if lost > 0 and main:
			Inventory.spend(kind, lost)
			main.drop_pile(kind, global_position + Vector2(randf_range(-12, 12), randf_range(-12, 12)), lost)
	var home: Vector2 = main.start if main else global_position
	var best := INF
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.is_lit():
			var d: float = l.global_position.distance_to(global_position)
			if d < best:
				best = d
				home = l.global_position + Vector2(0, 24)
	global_position = home
	reset_physics_interpolation()
	warmth = Tuning.warmth_max * 0.6
	for w in get_tree().get_nodes_in_group("wickling"):
		w.state = Wickling.State.FLEE
		w._flee_t = 3.0
	Progress.note_opened.emit("You faint...", "The cold takes you. You wake by the warmth of a lantern.\nSome of what you carried lies where you fell.")

# --- Interact: refuel or gather -------------------------------------------

## Nearest lantern, gatherable resource or revealed landmark within reach (or null).
func nearest_target() -> Node2D:
	var best: Node2D = null
	var best_d := REACH
	for w in get_tree().get_nodes_in_group("waylamp"):
		var dw: float = w.global_position.distance_to(global_position)
		if dw < maxf(best_d, 64.0):
			best = w
			best_d = dw
	for m in get_tree().get_nodes_in_group("landmark"):
		if not (m is Landmark) or not m.is_revealed():
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
	if t is WayLamp:
		last_feed = t.feed()
	elif t is Landmark:
		t.activate()
	elif t is Lantern:
		if t.kind == "mirror":
			t.turn()
			Sfx.play("ui_tick", -10.0)
		else:
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
		Sfx.play("gather_fuel" if target.kind == "fuel" else "gather_scrap", -12.0)

## Pours carried fuel into a lantern (relights it if cold). Returns units used.
func refuel(l: Lantern) -> int:
	var missing := l.max_fuel() - l.fuel   # a Reservoir's tank is bigger than a Post Lamp's
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
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.global_position.distance_to(p) < Tuning.waylamp_clear_radius:
			return "too close to the WayLamp"
	var k := Progress.selected
	if Inventory.get_count("scrap") < Lantern.cost(k) or Inventory.get_count("glass") < Lantern.glass_cost(k):
		return "needs " + Lantern.cost_text(k)
	return ""

func can_place(p: Vector2) -> bool:
	return place_block_reason(p) == ""

func try_place() -> Lantern:
	var p := place_pos()
	if not can_place(p):
		Sfx.play("ui_error", -16.0)
		return null
	Inventory.spend("scrap", Lantern.cost(Progress.selected))
	Inventory.spend("glass", Lantern.glass_cost(Progress.selected))
	var lamp_node := Lantern.new()
	lamp_node.kind = Progress.selected
	lamp_node.position = p   # lantern root sits at the origin
	get_tree().get_first_node_in_group("lantern_root").add_child(lamp_node)
	Sfx.play("place_lantern", -8.0)
	Story.note_built(lamp_node.kind)
	return lamp_node

## Refunds part of the scrap plus the fuel left in the tank.
func pick_up_nearest() -> void:
	var l := nearest_lantern()
	if l == null:
		return
	Inventory.add("scrap", floori(Lantern.cost(l.kind) * Tuning.pickup_refund))
	Inventory.add("glass", floori(Lantern.glass_cost(l.kind) * Tuning.pickup_refund))
	if l.needs_fuel():
		Inventory.add("fuel", floori(l.fuel / Tuning.fuel_per_unit))
	Sfx.play("pickup_lantern", -10.0)
	l.remove_from_group("lantern")
	l.remove_from_group("light_source")
	l.queue_free()

# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	# Puny Characters: columns 0-1 idle, 2-3 walk.
	var frame := 2 + int(_walk_t / 0.16) % 2 if _walk_t > 0.0 else int(_idle_t / 0.6) % 2
	var f := Art.KEEPER_FRAME
	draw_texture_rect_region(Art.KEEPER_SHEET, Rect2(-f, -f - 10, f * 2, f * 2), Rect2(frame * f, _dir_row * f, f, f))
	var fog := _fog()
	if fog == null:
		return
	# Warding glow ring.
	if _ward_grow > 0.01:
		var r := Tuning.ward_radius * _ward_grow
		draw_circle(Vector2(0, -6), r, Color(1.0, 0.85, 0.5, 0.08 * _ward_grow))
		draw_arc(Vector2(0, -6), r, 0.0, TAU, 48, Color(1.0, 0.88, 0.6, 0.55 * _ward_grow), 2.0)
	# Placement ghost: the tile and the radius a new lantern would light.
	var p := place_pos()
	var ok := can_place(p)
	var lp := to_local(p)
	var col := Color(0.6, 1.0, 0.6, 0.6) if ok else Color(1.0, 0.45, 0.4, 0.45)
	draw_rect(Rect2(lp - Vector2(16, 16), Vector2(32, 32)), col, false, 1.5)
	if ok:
		var preview := Tuning.lantern_max_radius
		match Progress.selected:
			"reservoir":
				preview = Tuning.reservoir_radius
			"hooded":
				preview = Tuning.hooded_radius
			"mirror":
				preview = 24.0
		draw_arc(lp, preview, 0.0, TAU, 72, Color(col, 0.35), 1.5)
	# Gathering progress ring.
	if is_gathering():
		var t := to_local(_gather_target.global_position)
		draw_arc(t, 18.0, -PI / 2.0, -PI / 2.0 + TAU * (_gather_acc / Tuning.gather_interval), 24, Color(1, 0.85, 0.5, 0.9), 2.0)
