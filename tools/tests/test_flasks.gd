extends Node
## M1a flask, regen, oil-drop and Rest checks. Uses only a disposable test save.
var main: Node
var frame := 0
var fails := 0

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok: fails += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion: InputMap.action_erase_event(action, e)
	Tuning.wick_enabled = false
	Story.skip_opening = true
	# M1c: this test predates the light states and lamp slots (test_light_states, test_combos and test_core's slot
	# checks cover those). The light rule and the slot limit are off here, so its sums stay as they were.
	Tuning.kl_dark_dmg_mult = 1.0
	Tuning.kl_lit_dmg_mult = 1.0
	Tuning.kl_lit_shell_mult = 1.0
	Tuning.kl_dark_shell_floor = 0.0
	Tuning.kl_ashbrood_needs_light = false
	Tuning.kl_lamp_slots_base = 6
	Tuning.kl_lamp_replant_cd = 0.0
	Settings.path = "user://test_flasks_settings.cfg"   # never the owner's settings
	Settings.use_defaults()
	SaveGame.path = "user://test_flasks_save.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	frame += 1
	if frame == 2:
		await _run_checks()

## A boss's oil step can't be skipped: one hit from full to nothing, the lingering burn and being set alight all
## cross the half-health line through the same check, and each crossing drops exactly one oil.
func _boss_oil_every_way(p: Node, spawner: Node) -> void:
	var at: Vector2 = p.global_position + Vector2(700, 0)
	# One big hit that crosses the step and kills.
	var a := _test_clinker(spawner, at)
	var oils := _oil_count()
	a.hurt(Tuning.kl_clinker_hp * 3.0, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 1, "one hit from full health to nothing still drops the boss oil (%d)" % (_oil_count() - oils))
	# One big hit past the step (not a kill), then more hits: one oil, once.
	var b := _test_clinker(spawner, at + Vector2(0, 80))
	oils = _oil_count()
	b.hurt(Tuning.kl_clinker_hp * 0.9, false, "lance")
	b.hurt(1.0, false, "lance")
	b.hurt(1.0, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 1, "a big hit past half drops it once, and later hits don't again (%d)" % (_oil_count() - oils))
	b.queue_free()
	# The lingering burn (it used to take health without the check).
	var c := _test_clinker(spawner, at + Vector2(0, 160))
	c.hp = c.hp_max * Tuning.kl_boss_oil_step + 0.05
	oils = _oil_count()
	c._linger_t = 1.0
	c.tick_foe(0.5)
	await get_tree().process_frame
	check(c.hp < c.hp_max * Tuning.kl_boss_oil_step and _oil_count() == oils + 1, "the lingering burn crossing half drops the oil (%d)" % (_oil_count() - oils))
	c.queue_free()
	# Set alight (Hearth ring's burn).
	var d := _test_clinker(spawner, at + Vector2(0, 240))
	d.hp = d.hp_max * Tuning.kl_boss_oil_step + 0.05
	oils = _oil_count()
	d.ignite(2.0, 2.0)
	d.tick_foe(0.5)
	await get_tree().process_frame
	check(d.hp < d.hp_max * Tuning.kl_boss_oil_step and _oil_count() == oils + 1, "burning crossing half drops the oil (%d)" % (_oil_count() - oils))
	d.queue_free()
	# A boss hurt before its first tick (hp_max not set yet) still counts from its full health.
	var e := Clinker.new()
	e.process_mode = Node.PROCESS_MODE_DISABLED
	e.position = at + Vector2(0, 320)
	spawner.add_child(e)
	e.shell = 0.0
	e.hp_max = 0.0
	oils = _oil_count()
	e.hurt(e.hp * 0.6, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 1, "a boss hit before its first frame still drops the oil at half")
	e.queue_free()
	# The Ashbrood: one hit through all of phase 1 drops phase 1's oil, and phase 2 has its own.
	var boss := Ashbrood.new()
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.position = at + Vector2(120, 0)
	spawner.add_child(boss)
	boss.hp_max = boss.phase_hp(); boss.hp = boss.phase_hp(); boss.shell = 0.0   # M1b: a phase grows with its level
	oils = _oil_count()
	boss.hurt(boss.phase_hp() * 2.0, false, "lance")
	await get_tree().process_frame
	check(boss.phase == 2 and _oil_count() == oils + 1, "one hit through a whole Ashbrood phase still drops that phase's oil")
	boss.end_phase_pause()   # it rises out of the bowl first (readability step); its process is off here
	boss.shell = 0.0
	boss.hurt(boss.phase_hp() * 0.6, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 2, "and the next phase drops its own")
	boss.queue_free()
	await get_tree().process_frame

func _test_clinker(spawner: Node, at: Vector2) -> Clinker:
	var k := Clinker.new()
	k.process_mode = Node.PROCESS_MODE_DISABLED
	k.position = at
	spawner.add_child(k)
	k.hp_max = Tuning.kl_clinker_hp; k.hp = Tuning.kl_clinker_hp; k.shell = 0.0
	return k

func _oil_count() -> int:
	return get_tree().get_nodes_in_group("ember").filter(func(e): return e.kind == "oil").size()

func _run_checks() -> void:
	var p = main.player
	check(p.flasks == 3, "starts with three oil flasks")
	# The regen table is measured in the same lit spot, with Hunt switched both ways.
	var lantern: Lantern = main.get_node("Lanterns").get_child(0)
	lantern.light_by_touch()   # the hut's old lamp, lit by touch (M1b)
	p.global_position = lantern.global_position
	var spawner = main.get_node("FogLayer/Wicklings")
	var nearby_hunter := Wickling.new()
	nearby_hunter.state = Wickling.State.CHASE
	nearby_hunter.position = p.global_position + Vector2(200, 0)
	spawner.add_child(nearby_hunter)
	p.lamp_charge = 0.0; p.warmth = 20.0
	p._physics_process(1.0)
	check(p.hunted and is_equal_approx(p.lamp_charge, Tuning.kl_charge_regen + Tuning.kl_light_charge_hunted), "within travel_hunt_radius, lamp light adds only 0.1 charge/s while hunted")
	check(is_equal_approx(p.warmth, 20.0), "hunted warmth stays cold in light")
	nearby_hunter.state = Wickling.State.WANDER
	p.lamp_charge = 0.0; p.warmth = 20.0
	p._physics_process(1.0)
	check(not p.hunted and is_equal_approx(p.lamp_charge, Tuning.kl_charge_regen + Tuning.hand_lamp_recharge_per_sec), "out of a fight, light uses the normal charge recharge")
	check(p.warmth > 20.0, "warmth comes back in light only when not hunted")
	nearby_hunter.queue_free()
	p.global_position = main.start + Vector2(800, 0)
	p.warmth = 20.0; p.lamp_charge = 0.1
	check(p.drink(), "a flask can be used")
	check(p.flasks == 2 and is_equal_approx(p.warmth, 60.0) and is_equal_approx(p.lamp_charge, 0.5), "drinking heals 40% and gives 0.4 charge")
	check(not p.drink(), "the one-second lockout blocks another drink")
	check(p.add_flask(8) == 1 and p.flasks == 3, "oil pickups stop at the flask cap")
	# A cleared pack gives oil on its last living member, not its first.
	var first: Wickling = spawner.spawn_at(p.global_position + Vector2(400, 0))
	var last: Wickling = spawner.spawn_at(p.global_position + Vector2(440, 0))
	first.pack_id = "test_oil_pack"; last.pack_id = "test_oil_pack"
	var oils := _oil_count()
	first.hurt(99.0, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils, "a pack member before the last drops no oil")
	last.hurt(99.0, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 1, "the last living foe in a pack drops one oil flask")
	# Guaranteed elite oil proves the chance hook; summoned foes must drop nothing.
	var old_chance: float = Tuning.kl_elite_oil_chance
	Tuning.kl_elite_oil_chance = 1.0
	var elite: Wickling = spawner.spawn_at(p.global_position + Vector2(480, 0), true)
	elite.shell = 0.0
	elite.hurt(999.0, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 2, "an elite can drop oil")
	var summoned := Wickling.new()
	summoned.summoned = true; summoned.hp = 1.0
	summoned.position = p.global_position + Vector2(500, 0)
	spawner.add_child(summoned)
	var drops_before: int = get_tree().get_nodes_in_group("ember").size()
	summoned.hurt(99.0, false, "lance")
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group("ember").size() == drops_before, "a summoned or hatched foe leaves no drops")
	Tuning.kl_elite_oil_chance = old_chance
	# The Ashbrood gives one oil flask at half health in each built phase.
	var boss := Ashbrood.new()
	boss.process_mode = Node.PROCESS_MODE_DISABLED
	boss.position = p.global_position + Vector2(540, 0)
	spawner.add_child(boss)
	boss.hp_max = boss.phase_hp(); boss.hp = boss.phase_hp(); boss.shell = 0.0   # M1b: a phase grows with its level
	boss.hurt(boss.phase_hp() * 0.51, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 3, "Ashbrood phase 1 drops oil below half health")
	boss.hurt(boss.phase_hp(), false, "lance")
	check(boss.phase == 2, "Ashbrood reaches its second phase")
	boss.end_phase_pause()
	boss.shell = 0.0
	boss.hurt(boss.phase_hp() * 0.51, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 4, "Ashbrood phase 2 drops oil below half health")
	boss.queue_free()
	var clinker := Clinker.new()
	clinker.process_mode = Node.PROCESS_MODE_DISABLED
	clinker.position = p.global_position + Vector2(600, 0)
	spawner.add_child(clinker)
	clinker.hp_max = Tuning.kl_clinker_hp; clinker.hp = Tuning.kl_clinker_hp; clinker.shell = 0.0
	clinker.hurt(Tuning.kl_clinker_hp * 0.51, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 5, "Clinker drops oil at its health step")
	clinker.queue_free()
	await _boss_oil_every_way(p, spawner)
	# Rest must refuse hunters and refill through the lit WayLamp's menu otherwise.
	var wl: WayLamp = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0]
	Progress.settled[wl.region_id] = true
	p.global_position = wl.global_position + Vector2(0, 48)
	p.flasks = 0; p.warmth = 10.0
	var hunter := Wickling.new()
	hunter.position = p.global_position + Vector2(40, 0)
	hunter.state = Wickling.State.CHASE
	spawner.add_child(hunter)
	var travel = main.get_node("TravelMenu")
	check(p.rest() != "" and p.flasks == 0 and not travel.open(wl), "Rest is refused while hunted")
	hunter.queue_free()
	await get_tree().process_frame
	p.hunted = false
	for i in 12:   # M2: level-ups no longer open a screen; let the boss kills above settle
		await get_tree().process_frame
	var can_open: bool = travel.open(wl)
	check(can_open, "the lit WayLamp offers Rest when the area is quiet")
	travel._rest()
	check(p.flasks == 3 and p.warmth == Tuning.warmth_max, "Rest refills flasks and warmth")
	print("RESULT fails=%d" % fails)
	get_tree().quit(1 if fails else 0)
