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
	SaveGame.path = "user://test_flasks_save.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	frame += 1
	if frame == 2:
		await _run_checks()

func _oil_count() -> int:
	return get_tree().get_nodes_in_group("ember").filter(func(e): return e.kind == "oil").size()

func _run_checks() -> void:
	var p = main.player
	check(p.flasks == 3, "starts with three oil flasks")
	# The regen table is measured in the same lit spot, with Hunt switched both ways.
	var lantern: Lantern = main.get_node("Lanterns").get_child(0)
	lantern.fuel = Tuning.lantern_max_fuel
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
	boss.hp_max = Tuning.kl_ashbrood_hp; boss.hp = Tuning.kl_ashbrood_hp; boss.shell = 0.0
	boss.hurt(Tuning.kl_ashbrood_hp * 0.51, false, "lance")
	await get_tree().process_frame
	check(_oil_count() == oils + 3, "Ashbrood phase 1 drops oil below half health")
	boss.hurt(Tuning.kl_ashbrood_hp, false, "lance")
	check(boss.phase == 2, "Ashbrood reaches its second phase")
	boss.shell = 0.0
	boss.hurt(Tuning.kl_ashbrood_hp * 0.51, false, "lance")
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
	var level_up = main.get_node("HUD").level_up_screen
	if level_up.root.visible:
		level_up._choose(level_up._offer[0].id)
	await get_tree().process_frame
	var can_open: bool = travel.open(wl)
	check(can_open, "the lit WayLamp offers Rest when the area is quiet")
	travel._rest()
	check(p.flasks == 3 and p.warmth == Tuning.warmth_max, "Rest refills flasks and warmth")
	print("RESULT fails=%d" % fails)
	get_tree().quit(1 if fails else 0)
