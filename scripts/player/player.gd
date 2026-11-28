extends CharacterBody2D
## The keeper (grey-box circle). Moves, carries the hand lamp, gathers,
## builds, refuels and picks up lanterns. Keyboard/mouse and gamepad.
## M1a: throws fire (KeeperCombat), drinks lamp oil (B / R), rests at a lit WayLamp. Every combat input and the
## flask are read after the menu guard (Progress.input_blocked), so the B that closes a menu never drinks.
## Light and regen follow GAME_PLAN §5 (update_hand_lamp, _update_warmth).

@export var speed := 160.0
const REACH := 52.0   # px to interact with a lantern or resource
const HOLD_TO_GATHER := 0.3   # s: holding interact this long gathers the nearest resource (tap still refuels)

var lamp: PointLight2D
var lamp_charge := 1.0          # 0 = ember, 1 = full hand lamp
var fuel_poured := 0.0
var last_feed := ""          # what happened the last time you fed a WayLamp (for prompts and tests)
var warmth := 100.0            # PROTOTYPE: the keeper's "health". Never kills; fainting sends you home.
var warding := false
var combat: KeeperCombat        # PROTOTYPE: beam, burst and dash
var _ward_grow := 0.0          # 0..1, how far the glow has swelled
var _since_ward := 99.0        # seconds since the ward was last used
var faints := 0
var _gather_target: ResourceNode = null
var _gather_acc := 0.0
var _hold_t := 0.0             # how long interact has been held (holding gathers, even beside a lantern)
var build_hint_t := 0.0        # > 0: a failed build shows its outline and reason for a moment
var build_hint := ""
var _facing_left := false
var _dir_row := 0          # Puny sheet row: 0 S, 1 SE, 2 E, 3 NE, 4 N, 5 NW, 6 W, 7 SW
var _idle_t := 0.0
var _step_t := 0.0
var _walk_t := 0.0
var flasks := 3                # lamp-oil flask charges (GAME_PLAN §5)
var flask_lock := 0.0          # s before the next drink
var drinks := 0                # flasks drunk (tests)
var hunted := false            # something hunts the keeper (Hunt), worked out once a physics frame
var _hitstop_t := 0.0          # > 0: a big hit freezes the keeper for a moment
var _pick_t := 0.0             # how long interact has been held by a lantern (picks it up at Tuning.kl_pickup_hold)
# The keeper's own feedback (readability step; drawn here and by KeeperFx on the fog layer).
var drink_t := 0.0             # > 0: the warm glow of a flask rising up the coat
var hurt_t := 0.0              # > 0: a hit chilled the keeper (cold flash, flinch frames)
var frost_t := 0.0             # > 0: a Wickling's touch is draining the keeper (frost edge)
var _art: FoeSprite             # owner-drawn keeper poses (assets/art/keeper/), when they exist

func _ready() -> void:
	flasks = Tuning.kl_flask_max
	combat = KeeperCombat.new()
	add_child(combat)
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
	_art = FoeSprite.attach(self, "keeper")   # the placeholder swap hook: owner poses replace the Puny frames
	if _art:
		_art.position = Vector2(0, -10)


# --- Hand lamp -------------------------------------------------------------

func get_light_radius() -> float:
	var r := lerpf(Tuning.hand_lamp_ember_radius, Progress.lamp_max_radius(), lamp_charge)
	return maxf(r, Tuning.ward_radius * _ward_grow)   # the ward also pushes the fog back

func in_lantern_light() -> bool:
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.is_lit() and w.global_position.distance_to(global_position) < w.get_light_radius() * 0.85:
			return true
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.is_lit() and l.global_position.distance_to(global_position) < l.get_light_radius() * 0.85:
			return true
	return false

## in_lantern_light() for the foes (performance): every Wickling asks it every frame. Worked out once per
## frame and place (and again when a lantern is placed, picked up or refuelled: LightSense.bump()).
var _lit_key := []
var _lit_val := false
func in_light_cached() -> bool:
	var key := [Engine.get_process_frames(), Engine.get_physics_frames(), global_position, LightSense._epoch]
	if key != _lit_key:
		_lit_key = key
		_lit_val = in_lantern_light()
	return _lit_val

## Lamp charge (GAME_PLAN §5): +kl_charge_regen everywhere; in light +hand_lamp_recharge_per_sec out of a fight
## or +kl_light_charge_hunted while hunted; no charge from light while the Beam is on. (M1a cut the passive
## dimming in the dark and the top-up from carried fuel: the regen table replaces them.)
func update_hand_lamp(delta: float) -> void:
	var gain := Tuning.kl_charge_regen
	if in_lantern_light() and not warding and not (combat and combat.beaming):   # light weapons are never free
		gain += Tuning.kl_light_charge_hunted if hunted else Tuning.hand_lamp_recharge_per_sec
	lamp_charge = clampf(lamp_charge + gain * delta, 0.0, 1.0)

## Charge a second the keeper would gain here and now (for tests and the HUD).
func charge_rate() -> float:
	var gain := Tuning.kl_charge_regen
	if in_lantern_light() and not warding and not (combat and combat.beaming):
		gain += Tuning.kl_light_charge_hunted if hunted else Tuning.hand_lamp_recharge_per_sec
	return gain

# --- Lamp oil, rest -------------------------------------------------------

func flask_max() -> int:
	return Tuning.kl_flask_max

func add_flask(n: int = 1) -> int:
	var before := flasks
	flasks = mini(flask_max(), flasks + n)
	return flasks - before

## Drinks one flask: 40% of max warmth back at once and +0.4 charge, then a 1 s lockout. False if it can't.
func _handle_flask_input(pressed: bool, blocked: bool) -> bool:
	if blocked or not pressed:
		return false
	return drink()

func drink() -> bool:
	if flasks <= 0 or flask_lock > 0.0:
		if flasks <= 0:
			Sfx.play("ui_error", -16.0)
		return false
	flasks -= 1
	drinks += 1
	drink_t = Tuning.kl_fx_drink_time
	flask_lock = Tuning.kl_flask_lockout
	warmth = minf(Tuning.warmth_max, warmth + Tuning.warmth_max * Tuning.kl_flask_heal)
	lamp_charge = minf(1.0, lamp_charge + Tuning.kl_flask_charge)
	Sfx.play("refuel", -8.0, 0.1)
	var arena := get_tree().get_first_node_in_group("wickling_spawner")
	if arena:
		FloatText.spawn(arena, global_position + Vector2(0, -34), "+%d warmth" % roundi(Tuning.warmth_max * Tuning.kl_flask_heal), UiStyle.AMBER)
	return true

## Rest at a lit WayLamp (GAME_PLAN §5): flasks and warmth back to full. Refused while hunted. Arriving by
## fast travel doesn't rest. Returns "" on success, else why not.
func rest() -> String:
	hunted = Hunt.is_hunted(get_tree(), global_position)
	if hunted:
		return "Can't rest while something hunts you"
	flasks = flask_max()
	warmth = Tuning.warmth_max
	Sfx.play_ui("unlock", -10.0)
	return ""

## A big hit freezes the keeper for a moment (per-target hit-stop, GAME_PLAN §15).
func hit_stop(seconds: float) -> void:
	_hitstop_t = maxf(_hitstop_t, seconds)

# --- Frame -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	hunted = Hunt.is_hunted(get_tree(), global_position)
	flask_lock = maxf(0.0, flask_lock - delta)
	drink_t = maxf(0.0, drink_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	frost_t = maxf(0.0, frost_t - delta)
	update_hand_lamp(delta)
	_update_warmth(delta)
	lamp.texture_scale = LightTex.scale_for(get_light_radius())
	lamp.energy = lerpf(0.35, 0.6, lamp_charge)
	queue_redraw()
	if _art:
		_update_art()
	if Tuning.ui_open:
		velocity = Vector2.ZERO
		_gather_target = null
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# The menu guard comes first (GAME_PLAN §3, M6): for a moment after a menu closes, no combat input and no
	# flask, so the B (or click) that closed it never drinks or fires. Cooldowns and bolts in flight go on.
	var blocked := Progress.input_blocked()
	var held := {}
	var pressed := {}
	if not blocked:
		for slot in Progress.SLOTS:
			if Input.is_action_pressed(slot):
				held[slot] = true
			if Input.is_action_just_pressed(slot):
				pressed[slot] = true
		_handle_flask_input(Input.is_action_just_pressed("flask"), false)
	combat.tick(delta, dir, held, pressed, not blocked and Input.is_action_just_pressed("dash"))
	_hitstop_t = maxf(0.0, _hitstop_t - delta)
	var fog := _fog()
	var slow := 1.0
	if fog and dir != Vector2.ZERO:
		slow = lerpf(1.0, Tuning.fog_slow_min, fog.density_at(global_position + dir * 24.0))
	if fog and fog.terrain_at(global_position) == FogGrid.T_MARSH:
		slow *= 0.85   # wading through the marsh
	if warding:
		slow *= Tuning.ward_walk_mult
	if combat.beaming:
		slow *= Tuning.kl_steady_hand_walk if Progress.has_combat_upgrade("steady_hand") else Tuning.kl_beam_walk
	velocity = combat.dash_velocity() if combat.is_dashing() else dir * speed * slow
	if _hitstop_t > 0.0 and not combat.is_dashing():
		velocity = Vector2.ZERO
	move_and_slide()
	_footsteps(dir, _physics_delta(), fog)
	if fog:
		position = position.clamp(Vector2.ZERO, fog.world_size())
	if blocked:
		_gather_target = null
		return
	if Input.is_action_just_pressed("place_lantern"):
		var near := nearest_target()
		if near is Lantern and near.kind == "mirror":
			near.turn(-1)   # X / C next to a mirror turns it left
			Sfx.play("ui_tick", -10.0)
		else:
			try_place()
	elif Input.is_action_just_pressed("interact"):
		begin_interact()
	build_hint_t = maxf(0.0, build_hint_t - delta)
	if Input.is_action_pressed("interact"):
		_hold_t += delta
		if not is_gathering() and _hold_t >= HOLD_TO_GATHER:
			var r := nearest_resource()
			if r:
				_gather_target = r
				_gather_acc = 0.0
		continue_gather(delta)
		# Hold by a lantern (with nothing to gather in reach): pick it up (GAME_PLAN §3: right mouse is a skill now).
		if not is_gathering() and nearest_resource() == null and nearest_lantern() != null:
			_pick_t += delta
			if _pick_t >= Tuning.kl_pickup_hold:
				_pick_t = -1000.0   # one pick-up per hold
				pick_up_nearest()
		else:
			_pick_t = minf(_pick_t, 0.0)
	else:
		_hold_t = 0.0
		_pick_t = 0.0
		_gather_target = null

## 0..1 while interact is held by a lantern (the pick-up ring).
func pick_up_progress() -> float:
	return clampf(_pick_t / maxf(0.01, Tuning.kl_pickup_hold), 0.0, 1.0)

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
		lamp_charge = maxf(0.0, lamp_charge - Progress.ward_drain_per_sec() * delta)
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

var _shake := 0.0          # trauma, 0..1
var _shake_noise: FastNoiseLite
var _shake_t := 0.0

## Screen shake (GAME_PLAN §15: the trauma recipe, KidsCanCode, ported to Godot 4): events add trauma, it
## decays on its own, and the offset is kl_shake_px x trauma squared x smooth noise, times the player's
## screen-shake setting (Settings.shake, the pause menu's slider; 0 turns it off).
func shake(amount: float) -> void:
	_shake = clampf(_shake + amount, 0.0, 1.0)

func shake_offset() -> Vector2:
	if _shake <= 0.0 or Settings.shake <= 0.0:
		return Vector2.ZERO
	if _shake_noise == null:
		_shake_noise = FastNoiseLite.new()
		_shake_noise.seed = 7
		_shake_noise.frequency = 0.9
	var amt := _shake * _shake * Tuning.kl_shake_px * Settings.shake
	return Vector2(_shake_noise.get_noise_2d(_shake_t * 60.0, 0.0), _shake_noise.get_noise_2d(0.0, _shake_t * 60.0)) * 2.0 * amt

func _process(delta: float) -> void:
	var cam := get_node_or_null("Camera2D") as Camera2D
	if cam == null:
		return
	_shake = maxf(0.0, _shake - delta * Tuning.kl_trauma_decay)
	_shake_t += delta
	cam.offset = shake_offset()

func chill(amount: float) -> void:
	if combat and combat.is_dashing():
		return   # nothing can chill you mid-dash
	if amount >= 5.0:
		shake(0.45)   # a real hit (a spit, a roll), not the steady touch of a Wickling
		hurt_t = Tuning.kl_fx_hurt_time
	warmth = maxf(0.0, warmth - amount)
	if warmth <= 0.0:
		faint()

## Warmth comes back in light only when nothing hunts you (GAME_PLAN §5). In a fight, flasks heal.
func _update_warmth(delta: float) -> void:
	if not hunted and in_lantern_light():
		warmth = minf(Tuning.warmth_max, warmth + Tuning.kl_warmth_regen * delta)

## Out of warmth: drop part of what you carry where you fell, wake at the nearest lit lantern (or the hut).
func faint() -> void:
	faints += 1
	for pack_key in Progress.cleared.keys():
		if str(pack_key).begins_with("pack_"):
			Progress.cleared.erase(pack_key)
	var main := get_tree().get_first_node_in_group("main")
	if Progress.wick > 0:
		var drop := WickDrop.new()
		drop.amount = Progress.wick
		drop.position = global_position
		var arena := get_tree().get_first_node_in_group("wickling_spawner")
		if arena:
			arena.add_child(drop)
		Progress.wick = 0
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
		if not (m is Landmark) or not m.is_revealed() or m.scenery:
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

## Nearest resource you can gather within reach (or null), whatever else is closer.
func nearest_resource() -> ResourceNode:
	var best: ResourceNode = null
	var best_d := REACH
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
		if last_feed == "held":
			# A lit WayLamp: the fast-travel list (refused, with a sound, while something hunts you).
			var menu := get_tree().get_first_node_in_group("travel_menu")
			if menu and not menu.open(t):
				last_feed = "travel_blocked"
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
	for r in get_tree().get_nodes_in_group("resource"):
		if r.global_position.distance_to(p) < FogGrid.TILE * 0.75:
			return "on a resource"
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.global_position.distance_to(p) < FogGrid.TILE * 1.5:
			return "too close to a lantern"
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.global_position.distance_to(p) < Tuning.waylamp_clear_radius:
			return "too close to the WayLamp"
	var k := Progress.selected
	if not Progress.is_unlocked(k):
		return "not found yet"
	if Inventory.get_count("scrap") < Lantern.cost(k) or Inventory.get_count("glass") < Lantern.glass_cost(k):
		return "needs " + Lantern.cost_text(k)
	return ""

func can_place(p: Vector2) -> bool:
	return place_block_reason(p) == ""

func try_place() -> Lantern:
	var p := place_pos()
	if not can_place(p):
		Sfx.play("ui_error", -16.0)
		build_hint = place_block_reason(p)
		build_hint_t = 2.0   # show the outline and why, just for a moment
		return null
	build_hint_t = 0.0
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
	LightSense.bump()

# --- Drawing ---------------------------------------------------------------

## Puny Characters sheet columns the keeper uses: 0-1 idle, 2-3 walk; since the readability step also 12-14
## (an arm raised, then thrust forward: the casts), 19 (the white hit silhouette, tinted cold) and 20 (a flinch).
const PUNY_CAST_RAISE := 12
const PUNY_CAST_UP := 13
const PUNY_CAST_THRUST := 14
const PUNY_HIT := 19
const PUNY_FLINCH := 20

## The Puny frame (column, row, tint) the keeper shows now: a flinch, a cast, a dash, a walk or idle.
func pose() -> Array:
	var frame := 2 + int(_walk_t / 0.16) % 2 if _walk_t > 0.0 else int(_idle_t / 0.6) % 2
	var row := _dir_row
	var tint := Color.WHITE
	var cast_t: float = combat.cast_t if combat else 0.0
	if hurt_t > 0.0:
		var k := hurt_t / maxf(Tuning.kl_fx_hurt_time, 0.01)
		frame = PUNY_HIT if (k > 0.6 and not Settings.reduce_flashes) else PUNY_FLINCH
		# The cream hit silhouette times this reads as the cold #a3bcd4 (a plain #a3bcd4 tint turns it grey-green).
		tint = Color(0.64, 0.78, 1.0) if frame == PUNY_HIT else Color.WHITE.lerp(Telegraph.COLD, 0.6 * k)
	elif cast_t > 0.0:
		var k := 1.0 - cast_t / maxf(Tuning.kl_fx_cast_time, 0.01)
		match combat.cast_kind:
			"lob":
				frame = PUNY_CAST_RAISE if k < 0.5 else PUNY_CAST_UP
			_:
				frame = PUNY_CAST_UP if k < 0.35 else PUNY_CAST_THRUST
		row = dir_row_of(combat.cast_dir)
	elif combat and combat.is_dashing():
		frame = 3   # mid-stride, the smear and afterimages do the rest
	if frost_t > 0.0 and hurt_t <= 0.0:
		tint = Color.WHITE.lerp(Telegraph.COLD, 0.45)
	return [frame, row, tint]

## The Puny sheet row facing along a direction: 0 S, 1 SE, 2 E, 3 NE, 4 N, 5 NW, 6 W, 7 SW.
static func dir_row_of(dir: Vector2) -> int:
	var oct := posmod(int(round(dir.angle() / (PI / 4.0))), 8)   # 0 E, 1 SE, 2 S ...
	return posmod(2 - oct, 8)

## Owner poses (when assets/art/keeper/ has strips): the same choice as pose(), by animation name.
func _update_art() -> void:
	var anim := "move" if _walk_t > 0.0 else "idle"
	if hurt_t > 0.0:
		anim = "hurt"
	elif combat and combat.cast_t > 0.0:
		anim = {"throw": "cast", "lob": "lob", "thrust": "thrust"}.get(combat.cast_kind, "cast")
	elif combat and combat.is_dashing():
		anim = "dash"
	elif drink_t > 0.0:
		anim = "drink"
	_art.play_anim(anim)
	_art.flip_h = _facing_left

func _draw() -> void:
	if not (_art and _art.showing()):
		var ps := pose()
		var f := Art.KEEPER_FRAME
		draw_texture_rect_region(Art.KEEPER_SHEET, Rect2(-f, -f - 10, f * 2, f * 2), Rect2(int(ps[0]) * f, int(ps[1]) * f, f, f), ps[2])
	var fog := _fog()
	if fog == null:
		return
	# Warding glow ring.
	if _ward_grow > 0.01:
		var r := Tuning.ward_radius * _ward_grow
		draw_circle(Vector2(0, -6), r, Color(1.0, 0.85, 0.5, 0.08 * _ward_grow))
		draw_arc(Vector2(0, -6), r, 0.0, TAU, 48, Color(1.0, 0.88, 0.6, 0.55 * _ward_grow), 2.0)
	# Gathering progress ring.
	if is_gathering():
		var t := to_local(_gather_target.global_position)
		draw_arc(t, 18.0, -PI / 2.0, -PI / 2.0 + TAU * (_gather_acc / Tuning.gather_interval), 24, Color(1, 0.85, 0.5, 0.9), 2.0)
	# Picking up a lantern (hold interact): a ring fills over it.
	var pick := pick_up_progress()
	if pick > 0.05:
		var nl := nearest_lantern()
		if nl:
			draw_arc(to_local(nl.global_position) + Vector2(0, -20), 20.0, -PI / 2.0, -PI / 2.0 + TAU * pick, 28, Color(0.64, 0.74, 0.83, 0.95), 3.0)

	# Placement outline: only for a moment after a build that couldn't happen.
	if build_hint_t <= 0.0:
		return
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
