extends Node
## M1c target lock (docs/replan/PLAN_LANTERNS.md §6): the cone pick, hunting foes first, the flick and the steer,
## each break, moving on after a kill, the lead, the Fireglobe's clamps, the assist off while locked, the sticky
## click, Auto mode, Y with an aimed skill, and the marker. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_lock.tscn

var main: Node
var fails := 0
var player: Node
var combat: KeeperCombat
var lock: LockOn
var spawner: Node
var fog: FogGrid
var spot := Vector2.ZERO

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	strip_real_input()
	Story.skip_opening = true
	SaveGame.path = "user://test_ignore_save.json"
	SaveGame.delete_save()
	Settings.path = "user://test_ignore_settings.cfg"
	Settings.use_defaults()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	_run()

func wait(sec: float) -> void:
	for i in maxi(1, roundi(sec * 60.0)):
		await get_tree().physics_frame

func clear() -> void:
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_pack"):
		s.queue_free()
	lock.release("test")

## A foe that stays put (process off) unless asked.
func foe(at: Vector2, hp := 50.0, moving := false) -> Wickling:
	var w := Wickling.new()
	w.position = at
	spawner.add_child(w)
	w.hp = hp
	w.hp_max = hp
	w.set_process(moving)
	return w

func stick(v: Vector2) -> void:
	for a in ["aim_left", "aim_right", "aim_up", "aim_down"]:
		Input.action_release(a)
	if v.x > 0.0:
		Input.action_press("aim_right", v.x)
	elif v.x < 0.0:
		Input.action_press("aim_left", -v.x)
	if v.y > 0.0:
		Input.action_press("aim_down", v.y)
	elif v.y < 0.0:
		Input.action_press("aim_up", -v.y)

func open_spot() -> Vector2:
	var c := fog.tile_of(main.start + Vector2(-700, 300))
	for r in 30:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := c + Vector2i(dx, dy)
				var ok := true
				for oy in range(-14, 15):
					for ox in range(-14, 15):
						var q := t + Vector2i(ox, oy)
						if not fog.in_bounds(q) or fog.solid[fog.idx(q)] == 1:
							ok = false
							break
					if not ok:
						break
				if ok:
					return fog.tile_center(t)
	return main.start + Vector2(-700, 300)

func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	player = main.player
	combat = player.combat
	lock = combat.lock
	spawner = main.get_node("FogLayer/Wicklings")
	fog = main.fog
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	InputHint.pad = true
	Progress._input_block_until = 0
	clear()
	spot = open_spot()
	player.global_position = spot
	player.reset_physics_interpolation()
	# Clear the fog around the spot so the lock's fog rule doesn't get in the way (it is checked on its own).
	for i in fog.density.size():
		fog.density[i] = 0.0
	fog.mark_all_dirty()
	await wait(0.1)
	check(InputMap.has_action("lock_on") and LockOn.current == lock, "the lock_on action exists and the keeper's lock is the one the marker draws")
	await _pick_checks()
	await _flick_steer_checks()
	await _aim_checks()
	await _break_checks()
	await _chain_checks()
	await _sticky_auto_checks()
	await _y_checks()
	await _marker_checks()
	stick(Vector2.ZERO)
	print("RESULT fails=%d" % fails)
	Art._ph.clear()
	get_tree().quit(1 if fails else 0)

func _pick_checks() -> void:
	clear()
	await wait(0.05)
	var near_cone := foe(spot + Vector2.RIGHT.rotated(deg_to_rad(20)) * 200.0)
	var off_cone := foe(spot + Vector2.RIGHT.rotated(deg_to_rad(60)) * 120.0)
	await wait(0.05)
	check(lock.pick(spot, Vector2.RIGHT) == near_cone, "it picks the foe in the %.0f-degree cone around the aim, not a nearer one outside it" % Tuning.kl_lock_cone_deg)
	var got := lock.pick(spot, Vector2.DOWN)
	check(got == off_cone, "with the cone empty it takes the nearest foe in range (%s at %s)" % [str(got), str(got.global_position - spot) if got else ""])
	var hunter := foe(spot + Vector2.RIGHT.rotated(deg_to_rad(-25)) * 330.0)
	hunter.state = Wickling.State.CHASE
	check(lock.pick(spot, Vector2.RIGHT) == hunter, "a foe hunting you comes first")
	var nest := WickNest.new()
	nest.position = spot + Vector2(80, 0)
	spawner.add_child(nest)
	await wait(0.05)
	check(not lock.lockable(nest), "nests can't be locked")
	check(lock.pick(spot, Vector2.RIGHT) != nest, "so the pick skips them")
	# Fog: can't start a lock on a foe in fog above 0.8.
	var t := fog.tile_of(hunter.global_position)
	fog.density[fog.idx(t)] = 0.95
	check(not lock.lockable(hunter), "a foe in deep fog (%.2f) can't be locked" % fog.density[fog.idx(t)])
	fog.density[fog.idx(t)] = 0.0
	# Start and stop.
	check(lock.acquire(Vector2.RIGHT) and lock.target == hunter and lock.last_event == "locked", "the lock button locks the best foe")
	check(combat.facing_or_aim() != Vector2.ZERO, "with the stick at rest it looks where the keeper faces")
	lock.toggle(Vector2.RIGHT)
	check(not lock.has_target() and lock.last_event == "broke_button", "pressed again, the lock ends at once")
	clear()
	await wait(0.05)
	check(not lock.acquire(Vector2.RIGHT) and lock.last_event == "none", "with nothing in range: no lock (a soft tick)")
	# Off mode: the button does nothing.
	foe(spot + Vector2(100, 0))
	await wait(0.05)
	Settings.lock_mode = "off"
	lock.toggle(Vector2.RIGHT)
	check(not lock.has_target(), "with the option off, the button does nothing")
	Settings.lock_mode = "toggle"
	clear()
	await wait(0.05)

func _flick_steer_checks() -> void:
	var a := foe(spot + Vector2(200, 0))
	var up := foe(spot + Vector2(200, -150))
	var down := foe(spot + Vector2(200, 160))
	await wait(0.05)
	lock.acquire(Vector2.RIGHT)
	check(lock.target == a, "locked the foe ahead")
	# A flick up: past 0.8 and back within 0.25 s.
	stick(Vector2(0, -0.95))
	await wait(0.1)
	stick(Vector2.ZERO)
	await wait(0.05)
	check(lock.target == up and lock.last_event == "switched", "a flick of the stick switches to the foe that way")
	stick(Vector2(0, 0.95))
	await wait(0.1)
	stick(Vector2.ZERO)
	await wait(0.05)
	check(lock.target == a or lock.target == down, "a flick down moves the lock back down (%s)" % ("a" if lock.target == a else "down"))
	lock._set_target(a)
	# A flick with nothing that way: it stays.
	stick(Vector2(-0.95, 0))
	await wait(0.1)
	stick(Vector2.ZERO)
	await wait(0.05)
	check(lock.target == a, "a flick toward nothing leaves the lock where it is")
	# A slow push past the flick threshold doesn't switch: holding the stick steers.
	stick(Vector2(0, -0.9))
	await wait(0.4)
	check(lock.steering and lock.has_target() and lock.target == a, "holding the stick longer than %.2f s steers; the lock waits" % Tuning.kl_lock_steer_time)
	check(combat.aim.y < -0.9, "and the aim follows the stick")
	check(lock.marker()["alpha"] == 0.5, "the marker shows at half strength while steering")
	stick(Vector2.ZERO)
	await wait(0.05)
	check(not lock.steering and lock.target == a, "letting go returns the aim to the lock (no switch after a long push)")
	check(combat.aim.dot((a.global_position - (player.global_position + Vector2(0, -10))).normalized()) > 0.99, "the aim is back on the target")
	clear()
	await wait(0.05)

func _aim_checks() -> void:
	var t := foe(spot + Vector2(240, 0))
	var side := foe(spot + Vector2(200, 30))
	await wait(0.05)
	lock.acquire(Vector2.RIGHT)
	lock._set_target(t)
	await wait(0.05)
	var origin: Vector2 = player.global_position + Vector2(0, -10)
	check(combat.aim.dot((t.global_position - origin).normalized()) > 0.999, "with a lock, the aim goes at the target")
	check(combat.assisted(Vector2.RIGHT.rotated(0.1), 300.0) == Vector2.RIGHT.rotated(0.1), "the aim assist is off while locked (the lock is exact)")
	# Lead: a target moving across leads the shot, capped at 48 px.
	lock.velocity = Vector2(0, 400)
	var led := lock.led_position(origin, Tuning.kl_lampfire_speed)
	check(led.distance_to(t.global_position) <= Tuning.kl_lock_lead_max + 0.01 and led.y > t.global_position.y + 10.0, "a moving target is led by its speed x flight time, at most %.0f px (%.1f)" % [Tuning.kl_lock_lead_max, led.distance_to(t.global_position)])
	lock.velocity = Vector2.ZERO
	# The Fireglobe: on the target, 60 to 280 px out.
	t.global_position = player.global_position + Vector2(30, 0)
	var g := combat.globe_target()
	check(absf(g.distance_to(player.global_position) - Tuning.kl_lock_globe_min) < 1.0, "a Fireglobe at a close lock lands %.0f px out at least (%.0f)" % [Tuning.kl_lock_globe_min, g.distance_to(player.global_position)])
	t.global_position = player.global_position + Vector2(390, 0)
	g = combat.globe_target()
	check(absf(g.distance_to(player.global_position) - Tuning.kl_fireglobe_max) < 1.0, "and %.0f px at most (%.0f)" % [Tuning.kl_fireglobe_max, g.distance_to(player.global_position)])
	t.global_position = player.global_position + Vector2(200, 0)
	g = combat.globe_target()
	check(g.distance_to(t.global_position) < 2.0, "at 200 px it lands on the target")
	# Lance with a lock: it flies at the target.
	Progress.level = 2
	Progress._grant_level_skills()
	combat.skill("lance").cd = 0.0
	player.lamp_charge = 1.0
	var before := FireBolts.inst.in_flight(FireBolts.LANCE)
	check(combat.skill("lance").press(), "Lance fires with a lock")
	var lb: FireBolts.Bolt = null
	for b in FireBolts.inst.bolts:
		if b.alive and b.kind == FireBolts.LANCE:
			lb = b
	check(lb != null and lb.dir.dot((t.global_position - lb.pos).normalized()) > 0.99 and FireBolts.inst.in_flight(FireBolts.LANCE) > before, "at the target")
	Progress.level = 1
	clear()
	await wait(0.2)

func _break_checks() -> void:
	# Range: past 480 px for 0.5 s.
	var t := foe(spot + Vector2(200, 0))
	await wait(0.05)
	lock.acquire(Vector2.RIGHT)
	t.global_position = player.global_position + Vector2(Tuning.kl_lock_break_range + 20.0, 0)
	await wait(0.2)
	check(lock.has_target() and lock.grace and lock.marker()["open"] == 2.0, "out of range, a grace timer runs first (the brackets open by 2 px)")
	await wait(0.45)
	check(not lock.has_target() and lock.last_event == "broke_range", "then past %.0f px for %.1f s it breaks" % [Tuning.kl_lock_break_range, Tuning.kl_lock_break_time])
	check(not lock.marker().is_empty() and lock.broke_t > 0.0, "and the brackets open and fade where it was")
	# Rock in the way for 0.75 s.
	t.global_position = player.global_position + Vector2(200, 0)
	await wait(0.3)
	lock.acquire(Vector2.RIGHT)
	var rock := fog.idx(fog.tile_of(player.global_position + Vector2(100, -5)))
	fog.solid[rock] = 1
	await wait(0.5)
	check(lock.has_target(), "rock in the way: it holds for a moment")
	await wait(0.45)
	check(not lock.has_target() and lock.last_event == "broke_rock", "and breaks after %.2f s behind rock" % Tuning.kl_lock_los_grace)
	fog.solid[rock] = 0
	# Deep fog: it holds 1.5 s.
	await wait(0.1)
	lock.acquire(Vector2.RIGHT)
	var fi := fog.idx(fog.tile_of(t.global_position))
	fog.density[fi] = 0.95
	await wait(1.0)
	check(lock.has_target(), "in deep fog it holds a while (your bolts light it)")
	fog.density[fi] = 0.95
	await wait(0.7)
	check(not lock.has_target() and lock.last_event == "broke_fog", "then breaks after %.1f s" % Tuning.kl_lock_fog_grace)
	fog.density[fi] = 0.0
	# The dark never breaks a lock.
	await wait(0.1)
	lock.acquire(Vector2.RIGHT)
	await wait(0.3)
	check(lock.has_target() and t.effective_light() != Foe.LIT, "being in the dark never breaks a lock")
	# A menu.
	Tuning.ui_open = true
	await wait(0.05)
	Tuning.ui_open = false
	check(not lock.has_target() and lock.last_event == "broke_menu", "a menu opening ends it: it never leaks out of a menu")
	await wait(0.05)
	lock.acquire(Vector2.RIGHT)
	Progress.block_input(100)
	await wait(0.02)
	check(not lock.has_target(), "and so does the menu guard after a menu closes")
	Progress._input_block_until = 0
	# A faint.
	lock.acquire(Vector2.RIGHT)
	player.faint()
	check(not lock.has_target() and lock.last_event == "broke_faint", "a faint ends it")
	var reader = main.get_node("NoteReader")
	if reader.is_open():
		reader.close()
	Progress._input_block_until = 0
	player.global_position = spot
	player.reset_physics_interpolation()
	player.warmth = Tuning.warmth_max
	clear()
	await wait(0.1)

func _chain_checks() -> void:
	var a := foe(spot + Vector2(200, 0), 3.0)
	var b := foe(spot + Vector2(200, 100), 50.0)
	var far := foe(spot + Vector2(200, -300), 50.0)
	await wait(0.05)
	lock.acquire(Vector2.RIGHT)
	lock._set_target(a)
	a.hurt(99.0, false, "lance")
	await wait(0.05)
	check(lock.target == b and lock.last_event == "moved_on", "its target dies: the lock moves to the nearest foe within %.0f px" % Tuning.kl_lock_chain_radius)
	Settings.lock_chain = false
	b.hurt(999.0, false, "lance")
	await wait(0.05)
	check(not lock.has_target() and lock.last_event == "broke_death", "with the option off it breaks instead")
	Settings.lock_chain = true
	lock._set_target(far)
	far.hurt(999.0, false, "lance")
	await wait(0.05)
	check(not lock.has_target(), "with nothing near the dead one, it breaks")
	clear()
	await wait(0.05)

func _sticky_auto_checks() -> void:
	var t := foe(spot + Vector2(160, 40))
	await wait(0.05)
	check(lock.sticky_begin(t.global_position + Vector2(t.body_radius() + 20.0, 0)) and lock.target == t and lock.sticky, "K&M sticky click: a press within %.0f px of a foe's body follows it" % Tuning.kl_sticky_click_radius)
	check(lock.aiming(), "while the button is held the fire follows it")
	lock.sticky_end()
	check(not lock.has_target(), "letting go ends it")
	check(not lock.sticky_begin(t.global_position + Vector2(t.body_radius() + 40.0, 0)), "a press farther from any foe is a plain shot")
	Settings.sticky_click = false
	check(not lock.sticky_begin(t.global_position), "the sticky click has its own option, off")
	Settings.sticky_click = true
	Settings.lock_mode = "off"
	check(not lock.sticky_begin(t.global_position), "and it is off with the lock set to Off")
	Settings.lock_mode = "toggle"
	# Auto mode: no lock, so the nearest hunting foe is taken, even behind you (outside the cone), over an idle one ahead.
	var idle := foe(spot + Vector2(120, 0))
	t.global_position = spot + Vector2(-200, 0)
	combat._face = Vector2.RIGHT
	Settings.lock_mode = "auto"
	t.state = Wickling.State.CHASE
	await wait(0.3)
	check(lock.target == t and lock.last_event == "auto", "Auto mode locks the nearest foe hunting you, even behind you (not the idle one ahead)")
	idle.queue_free()
	Settings.lock_mode = "toggle"
	clear()
	await wait(0.05)

func _y_checks() -> void:
	Progress.level = 2
	Progress._grant_level_skills()
	check(Progress.bind("skill_4", "lance") == "", "Lance can go on Y")
	var t := foe(spot + Vector2.RIGHT.rotated(deg_to_rad(20)) * 220.0)
	await wait(0.05)
	combat.skill("lance").cd = 0.0
	player.lamp_charge = 1.0
	combat._face = Vector2.RIGHT
	combat.tick(1.0 / 60.0, Vector2.ZERO, {}, {"skill_4": true})
	var lb: FireBolts.Bolt = null
	for b in FireBolts.inst.bolts:
		if b.alive and b.kind == FireBolts.LANCE:
			lb = b
	check(lb != null and lb.dir.dot((t.global_position - lb.pos).normalized()) > 0.98, "Y with an aimed skill and no lock fires at the best foe within %.0f degrees" % Tuning.kl_y_autotarget_deg)
	# Not at a foe behind rock or in deep fog (the lock's rules).
	var rock := fog.idx(fog.tile_of(player.global_position + (t.global_position - player.global_position) * 0.5))
	fog.solid[rock] = 1
	check(combat.y_target() == null, "Y's auto-target skips a foe behind rock")
	fog.solid[rock] = 0
	var fi := fog.idx(fog.tile_of(t.global_position))
	fog.density[fi] = 0.95
	check(combat.y_target() == null, "and one in deep fog")
	fog.density[fi] = 0.0
	check(combat.y_target() == t, "and takes it again in the clear")
	await wait(0.6)
	t.global_position = spot + Vector2.RIGHT.rotated(deg_to_rad(70)) * 220.0
	combat.skill("lance").cd = 0.0
	combat._face = Vector2.RIGHT
	combat.tick(1.0 / 60.0, Vector2.ZERO, {}, {"skill_4": true})
	lb = null
	for b in FireBolts.inst.bolts:
		if b.alive and b.kind == FireBolts.LANCE:
			lb = b
	check(lb != null and lb.dir.dot(Vector2.RIGHT) > 0.98, "with none there it fires straight along the aim")
	Progress.bind("skill_4", "")
	Progress.bind("skill_3", "lance")
	Progress.level = 1
	clear()
	await wait(0.6)

func _marker_checks() -> void:
	var t := foe(spot + Vector2(200, 0))
	await wait(0.05)
	lock.acquire(Vector2.RIGHT)
	var m := lock.marker()
	check(m["color"] == LockOn.MARKER and m["color"].r > m["color"].b, "the marker is warm #ffd27a, never a foe's cold colour")
	check(m["color"] != Telegraph.COLD and m["color"] != Telegraph.COLD_DEEP, "and never the telegraph blue")
	await wait(0.2)
	var m1 := lock.marker()
	await wait(0.07)
	var m2 := lock.marker()
	check(m1["alpha"] == 1.0 and m2["alpha"] == 1.0 and m1["half"] == m2["half"], "it never flashes or pulses")
	check(is_equal_approx(m1["half"], t.body_radius() + 6.0) and m1["arm"] == 6.0 and m1["width"] == 2.0, "corner brackets body + 6 px, 6 px arms, 2 px")
	Settings.lock_large = true
	check(is_equal_approx(lock.marker()["half"], (t.body_radius() + 6.0) * 1.5) and lock.marker()["width"] == 3.0, "the Large option draws them x1.5 and 3 px")
	Settings.lock_large = false
	check(Telegraph.inst != null and Telegraph.inst.z_index == 13, "drawn by the telegraph node on the fog layer (z 13), above fog and foes")
	var lamp := Lantern.new()
	lamp.kind = "post"
	lamp.position = t.global_position + Vector2(-100, 0)
	main.get_node("Lanterns").add_child(lamp)
	LightSense.bump()
	await wait(0.1)
	t.update_light_state(0.0)   # its process is off in this test (a foe in play works it out every frame)
	check(lock.marker()["lit"], "a short warm bar shows while the target is lit")
	lamp.queue_free()
	clear()
	await wait(0.05)
