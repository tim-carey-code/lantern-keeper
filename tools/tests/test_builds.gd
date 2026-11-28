extends Node
## M2 "Builds" (GAME_PLAN §4.2): every branch pick changes how its skill behaves. One check (or a few) per pick, for
## Lampfire, Fireglobe, Lance, the dash, the Beam and Hearth ring; the picks that touch lamps (Fireglobe Beacon and
## the dash's Ember rest count as lit, PLAN_LANTERNS §8); every pick number is in the tuning panel. The rules
## (points, tiers, respec, saving) are in test_skills. The light rule is off here except where a check needs it.
## Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_builds.tscn

var main: Node
var fails := 0
var player: Node
var c: KeeperCombat
var spawner: Node
var fog: FogGrid
var bolts: FireBolts
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
	Tuning.wick_enabled = false
	Tuning.kl_dark_dmg_mult = 1.0
	Tuning.kl_lit_dmg_mult = 1.0
	Tuning.kl_lit_shell_mult = 1.0
	Tuning.kl_dark_shell_floor = 0.0
	Tuning.kl_lamp_slots_base = 6
	SaveGame.path = "user://test_ignore_save.json"
	SaveGame.delete_save()
	Settings.path = "user://test_ignore_settings.cfg"
	Settings.use_defaults()
	InputHint.pad = false
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	_run()

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func clear() -> void:
	for f in get_tree().get_nodes_in_group("foe"):
		f.remove_from_group("foe")   # gone at once: nothing below sees a foe from the check before
		f.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_pack"):
		s.queue_free()
	for g in get_tree().get_nodes_in_group("burning_ground"):
		g.queue_free()
	for g in get_tree().get_nodes_in_group("keeper_light"):
		g.queue_free()
	for n in get_tree().get_nodes_in_group("cold_ember"):
		n.queue_free()
	for b in bolts.bolts:
		b.alive = false
	for n in main.get_node("FogLayer").get_children():
		if n is ChainSeam:
			n.queue_free()
	Foe.branded = null
	LightSense.bump()

## Only these picks (the rules don't apply: a level-12 keeper past the Ashbrood).
func give(ids: Array) -> void:
	Progress.level = 12
	Progress.cleared["ashbrood_hollow"] = true
	var kept := Progress.set_picks(ids)
	if kept.size() != ids.size():
		check(false, "the test could take its picks %s (kept %s)" % [str(ids), str(kept)])

func reset_keeper() -> void:
	player.global_position = spot
	player.reset_physics_interpolation()
	player.lamp_charge = 1.0
	player.warmth = Tuning.warmth_max
	for s in c.skills.values():
		s.cd = 0.0
	c.dash_cd = 0.0
	c.dash_t = 0.0
	c.dash_charges = 1
	c.aim_override = Vector2.RIGHT

## A dummy: a slow Wickling with lots of health that stays put (its process is off); shell optional.
func dummy(at: Vector2, hp := 100.0, shell := 0.0) -> Wickling:
	var w := Wickling.new()
	w.elite = true
	w.position = at
	spawner.add_child(w)
	w.shell = shell
	w.shell_max = shell
	w.hp = hp
	w.hp_max = hp
	w.set_process(false)
	return w

func lampfire_bolts(spark: int = -1) -> Array:
	return bolts.bolts.filter(func(b): return b.alive and b.kind == FireBolts.LAMPFIRE and (spark < 0 or b.spark == (spark == 1)))

func open_spot() -> Vector2:
	var t0 := fog.tile_of(main.start + Vector2(-700, 300))
	for r in 30:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := t0 + Vector2i(dx, dy)
				var ok := true
				for oy in range(-12, 13):
					for ox in range(-12, 13):
						var q := t + Vector2i(ox, oy)
						if not fog.in_bounds(q) or fog.solid[fog.idx(q)] == 1:
							ok = false
							break
					if not ok:
						break
				if ok:
					return fog.tile_center(t)
	return main.start

func _run() -> void:
	await frames(3)
	player = main.player
	c = player.combat
	spawner = main.get_node("FogLayer/Wicklings")
	fog = main.fog
	bolts = FireBolts.inst
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	for l in get_tree().get_nodes_in_group("lantern"):
		l.remove_from_group("lantern")
		l.queue_free()
	clear()
	spot = open_spot()
	await frames(2)
	await _lampfire()
	await _fireglobe()
	await _lance()
	await _dash()
	await _beam()
	await _ring()
	_table()
	give([])
	print("RESULT fails=%d" % fails)
	Art._ph.clear()
	get_tree().quit(1 if fails else 0)

# --- Lampfire --------------------------------------------------------------------------------------------

func _lampfire() -> void:
	var lf: LampfireSkill = c.skill("lampfire")
	# Lingering burn.
	clear(); reset_keeper(); give(["lingering_burn"])
	var d := dummy(spot + Vector2(80, -10))
	lf.fire()
	await frames(20)
	check(d._ignite_t > 0.0 and is_equal_approx(d._ignite_dps, Tuning.kl_pick_burn_dps * Progress.dmg_mult()), "Lingering burn: a foe the bolt hits burns (%.1f s at %.1f a second)" % [d._ignite_t, d._ignite_dps])
	# Scatter.
	clear(); reset_keeper(); give(["scatter"])
	d = dummy(spot + Vector2(80, -10))
	lf.fire()
	var sparks := 0
	for i in 30:
		await frames(1)
		sparks = maxi(sparks, lampfire_bolts(1).size())
	check(sparks == Tuning.kl_scatter_count, "Scatter: the burst throws %d sparks (%d)" % [Tuning.kl_scatter_count, sparks])
	# Twin.
	clear(); reset_keeper(); give(["twin"])
	lf.fire()
	var tw := lampfire_bolts(0)
	check(tw.size() == 2 and tw.all(func(b): return is_equal_approx(b.mult, Tuning.kl_twin_mult)) and absf(tw[0].dir.angle_to(tw[1].dir)) > deg_to_rad(Tuning.kl_twin_spread_deg), "Twin: two bolts in a V, each x%.2f" % Tuning.kl_twin_mult)
	# Skip.
	clear(); reset_keeper(); give(["skip"])
	var a := dummy(spot + Vector2(80, -10))
	var b := dummy(spot + Vector2(80, 60))
	lf.fire()
	await frames(40)
	check(a.hp < 100.0 and b.hp < 100.0 - Tuning.kl_lampfire_splash_dmg * Progress.dmg_mult() - 0.01, "Skip: a bolt that hits jumps on to the next foe (%.1f, %.1f)" % [a.hp, b.hp])
	# Needle.
	clear(); reset_keeper(); give(["needle"])
	a = dummy(spot + Vector2(70, -10))
	b = dummy(spot + Vector2(150, -10))
	lf.fire()
	var passed := false
	for i in 40:
		await frames(1)
		if a.hp < 100.0 and lampfire_bolts(0).size() == 1:
			passed = true
	check(passed and a.hp < 100.0 and b.hp < 100.0, "Needle: it passes the first foe (hit) and bursts on the second (%.1f, %.1f)" % [a.hp, b.hp])
	# Comet.
	clear(); reset_keeper(); give(["comet"])
	lf.fired = 0
	var big := 0
	for i in Tuning.kl_comet_every:
		lf.fire()
		for bb in lampfire_bolts(0):
			if bb.big:
				big += 1
		for bb in bolts.bolts:
			bb.alive = false
	check(big == 1, "Comet: every %dth bolt is big (%d of %d)" % [Tuning.kl_comet_every, big, Tuning.kl_comet_every])
	# Catching.
	clear(); reset_keeper(); give(["catching"])
	a = dummy(spot + Vector2(80, -10), 1.0)
	b = dummy(spot + Vector2(120, -10))
	a.hurt(5.0, false, "lance")
	check(b._ignite_t > 0.0, "Catching: a kill sets the nearest foe within %.0f px alight" % Tuning.kl_catching_radius)
	clear()
	await frames(2)

# --- Fireglobe -------------------------------------------------------------------------------------------

func _globes() -> Array:
	return bolts.bolts.filter(func(b): return b.alive and b.kind == FireBolts.GLOBE)

func _land_one(to: Vector2) -> void:
	bolts.throw_globe(spot + Vector2(0, -10), to)
	await frames(int(Tuning.kl_fireglobe_flight * 60.0) + 2)

func _fireglobe() -> void:
	var to := spot + Vector2(180, 0)
	clear(); reset_keeper(); give(["skipping_globe"])
	await _land_one(to)
	var g := _globes()
	check(g.size() == 1 and g[0].small and g[0].to.distance_to(to) > Tuning.kl_skip_globe_dist * 0.9, "Skipping globe: it hops on and bursts again (%d in the air)" % g.size())
	clear(); reset_keeper(); give(["slick"])
	var w := dummy(to + Vector2(10, 0))
	await _land_one(to)
	await frames(3)
	var grounds := get_tree().get_nodes_in_group("burning_ground")
	check(grounds.size() == 1 and grounds[0].slick and w.speed_mult() < 1.0 - Tuning.kl_slick_slow + 0.01, "Slick: its burning ground slows foes (x%.2f)" % w.speed_mult())
	clear(); reset_keeper(); give(["second_globe"])
	bolts.throw_globe(spot + Vector2(0, -10), to)
	g = _globes()
	check(g.size() == 2 and g.filter(func(x): return x.small and x.delay > 0.0).size() == 1, "Second globe: a smaller one follows it down")
	await frames(int((Tuning.kl_fireglobe_flight + Tuning.kl_second_globe_delay) * 60.0) + 4)
	check(get_tree().get_nodes_in_group("burning_ground").size() == 2, "and both burst")
	clear(); reset_keeper(); give(["fire_line"])
	await _land_one(to)
	await frames(2)
	check(get_tree().get_nodes_in_group("burning_ground").size() == Tuning.kl_fire_line_count, "Fire line: it lands as %d bursts across the aim" % Tuning.kl_fire_line_count)
	clear(); reset_keeper(); give(["cluster"])
	await _land_one(to)
	g = _globes()
	check(g.size() == Tuning.kl_cluster_count and g.all(func(x): return x.small), "Cluster: it bursts into %d small globes (%d)" % [Tuning.kl_cluster_count, g.size()])
	clear(); reset_keeper(); give(["beacon"])
	w = dummy(to + Vector2(60, 0))
	w.update_light_state(0.0)
	var was_lit := w.is_exposed()
	await _land_one(to)
	await frames(2)
	var lights := get_tree().get_nodes_in_group("keeper_light")
	w.update_light_state(0.0)
	check(not was_lit and lights.size() == 1 and w.is_exposed(), "Beacon: where it lands stays lit; a foe in it is lit (PLAN_LANTERNS §8)")
	w.lightless = true
	w._exposed_t = 0.0
	w.update_light_state(0.0)
	check(not w.is_exposed(), "but not a Lightless elite")
	clear(); reset_keeper(); give(["undertow"])
	w = dummy(to + Vector2(Tuning.kl_fireglobe_radius + 30.0, 0))
	await _land_one(to)
	check(w._knock_t > 0.0 and w._knock_v.x < 0.0, "Undertow: the blast pulls foes in first")
	clear()
	await frames(2)

# --- Lance ---------------------------------------------------------------------------------------------

func _lance_bolts() -> Array:
	return bolts.bolts.filter(func(b): return b.alive and b.kind == FireBolts.LANCE)

func _lance() -> void:
	var ln: LanceSkill = c.skill("lance")
	Progress.lance_given = true
	clear(); reset_keeper(); give(["burning_line"])
	ln.press()
	await frames(50)
	var seams := main.get_node("FogLayer").get_children().filter(func(n): return n is ChainSeam and not n.arc)
	check(seams.size() == 1, "Burning line: it leaves fire along its path")
	clear(); reset_keeper(); give(["brand"])
	var d := dummy(spot + Vector2(80, -10))
	ln.press()
	await frames(10)
	check(Foe.branded == d, "Brand: the foe it strikes is marked")
	var h := d.hp
	d.hurt(2.0, false, "lampfire")
	check(is_equal_approx(h - d.hp, 2.0 * Tuning.kl_brand_mult) and Foe.branded == null, "and the next hit on it does +50%%, once (%.1f)" % (h - d.hp))
	clear(); reset_keeper(); give(["returning"])
	ln.press()
	await frames(int(Tuning.kl_lance_range / Tuning.kl_lance_speed * 60.0) + 3)
	var lb := _lance_bolts()
	check(lb.size() == 1 and lb[0].returning, "Returning: at the end of its flight it flies back")
	clear(); reset_keeper(); give(["forked"])
	d = dummy(spot + Vector2(80, -10))
	ln.press()
	var forks := 0
	for i in 15:
		await frames(1)
		forks = maxi(forks, _lance_bolts().filter(func(b): return b.child).size())
	check(forks == 2, "Forked: it splits in two at the first hit (%d)" % forks)
	clear(); reset_keeper(); give(["breaking"])
	ln.press()
	var brk := 0
	for i in 50:
		await frames(1)
		brk = maxi(brk, lampfire_bolts(1).size())
	check(brk == Tuning.kl_breaking_count, "Breaking: at its end it bursts into %d Lampfire bolts (%d)" % [Tuning.kl_breaking_count, brk])
	clear(); reset_keeper(); give(["held_lance"])
	check(ln.held(), "Held lance: Lance becomes a held skill")
	for i in int(Tuning.kl_held_lance_time * 60.0) + 4:
		ln.hold(1.0 / 60.0, true)
	check(ln.charged(), "held %.1f s, it is charged" % Tuning.kl_held_lance_time)
	ln.hold(1.0 / 60.0, false)
	lb = _lance_bolts()
	check(lb.size() == 1 and lb[0].charged and lb[0].pierce > 100 and is_equal_approx(lb[0].mult, Tuning.kl_held_lance_mult), "let go: double damage, through everything")
	clear(); reset_keeper()
	ln.hold(1.0 / 60.0, true)
	ln.hold(1.0 / 60.0, false)
	lb = _lance_bolts()
	check(lb.size() == 1 and not lb[0].charged, "a short press throws a normal Lance")
	clear(); reset_keeper(); give(["shatter"])
	d = dummy(spot + Vector2(80, -10), 100.0, 2.0)
	var e := dummy(spot + Vector2(80, 30))
	ln.press()
	await frames(10)
	check(d.shell <= 0.0 and e.hp <= 100.0 - Tuning.kl_shatter_dmg * Progress.dmg_mult() + 0.01, "Shatter: a shell it breaks bursts, hurting what's around (%.1f)" % e.hp)
	clear()
	await frames(2)

# --- The dash ------------------------------------------------------------------------------------------

func _dash_once(dir: Vector2) -> void:
	c.dash(dir)
	for i in int(Tuning.kl_dash_time * 60.0) + 3:
		player.global_position += c.dash_velocity() / 60.0
		c.dash_t = maxf(0.0, c.dash_t - 1.0 / 60.0)
		c.dash_tick()
		await frames(1)

func _dash() -> void:
	clear(); reset_keeper(); give(["second_step"])
	c.dash_charges = 2
	check(c.dash(Vector2.RIGHT) and c.dash(Vector2.RIGHT) and not c.dash(Vector2.RIGHT), "Second step: two dashes, then the cooldown")
	clear(); reset_keeper(); give(["cinder_trail"])
	await _dash_once(Vector2.RIGHT)
	check(get_tree().get_nodes_in_group("burning_ground").size() >= 3, "Cinder trail: burning ground along the dash (%d)" % get_tree().get_nodes_in_group("burning_ground").size())
	clear(); reset_keeper(); give(["phase"])
	var d := dummy(spot + Vector2(60, 0))
	await _dash_once(Vector2.RIGHT)
	check(d._stun_t > 0.0, "Phase: a foe you dash through is stunned")
	clear(); reset_keeper(); give(["flame_step"])
	d = dummy(spot + Vector2(Tuning.kl_dash_dist + 30.0, 0))
	await _dash_once(Vector2.RIGHT)
	check(d.hp < 100.0 and d._ignite_t > 0.0, "Flame step: a ring of fire where the dash ends")
	clear(); reset_keeper(); give(["ember_rest"])
	d = dummy(spot + Vector2(Tuning.kl_dash_dist + 40.0, 0))
	await _dash_once(Vector2.RIGHT)
	await frames(1)
	var lights := get_tree().get_nodes_in_group("keeper_light")
	d.update_light_state(0.0)
	check(lights.size() == 1 and lights[0].kind == "ember_rest" and d.is_exposed(), "Ember rest: an ember where the dash ends; a foe by it is lit")
	clear(); reset_keeper(); give(["blink"])
	var p0: Vector2 = player.global_position
	c.dash(Vector2.RIGHT)
	check(absf(player.global_position.distance_to(p0) - Tuning.kl_blink_dist) < 1.0 and c.dash_velocity() == Vector2.ZERO and c.is_dashing(), "Blink: an instant %.0f px step, with the dash's guard" % Tuning.kl_blink_dist)
	clear(); reset_keeper(); give(["recoil"])
	c.aim_override = Vector2.RIGHT
	c.update_aim(Vector2.ZERO)
	var r0 := c.recoils
	c.dash(Vector2.LEFT)
	check(c.recoils == r0 + 1 and lampfire_bolts(1).size() == Tuning.kl_recoil_count, "Recoil: dashing away from your aim throws %d bolts forward" % Tuning.kl_recoil_count)
	clear(); reset_keeper()
	c.dash(Vector2.RIGHT)
	check(lampfire_bolts().is_empty(), "a dash along the aim throws none")
	clear()
	await frames(2)

# --- The Beam (optional) -------------------------------------------------------------------------------

func _beam() -> void:
	var bm: BeamSkill = c.skill("beam")
	clear(); reset_keeper(); give([])
	var base_cost := bm.cost()
	check(is_equal_approx(c.beam_len(), Tuning.kl_beam_len), "the Beam reaches %.0f px" % Tuning.kl_beam_len)
	give(["long_throw"])
	check(is_equal_approx(c.beam_len(), Tuning.kl_long_throw_len), "Long throw: %.0f px" % Tuning.kl_long_throw_len)
	give(["deep_tank"])
	check(is_equal_approx(bm.cost(), base_cost * Tuning.kl_deep_tank_mult), "Deep tank: it costs 20%% less")
	give(["tight_focus"])
	var d := dummy(spot + Vector2(60, 0), 100.0, 10.0)
	d.hurt(1.0, false, "beam")
	check(is_equal_approx(10.0 - d.shell, Tuning.kl_focus_shell_mult), "Tight focus: shells wear 30%% faster (%.2f)" % (10.0 - d.shell))
	clear(); reset_keeper(); give(["steady_hand"])
	check(Progress.has_pick("steady_hand"), "Steady hand: walk at %.0f%% while beaming (player.gd reads it)" % (Tuning.kl_steady_hand_walk * 100.0))
	give(["prism"])
	c.beaming = true
	c.aim = Vector2.RIGHT
	check(c.beam_segments().size() == 3, "Prism: three thin beams")
	clear(); reset_keeper(); give(["searing"])
	c.beaming = true
	c.aim = Vector2.RIGHT
	d = dummy(spot + Vector2(80, -10), 1000.0)
	var h0 := d.hp
	for i in 6:
		c.burn_along_beam(1.0 / 60.0)
	var early := (h0 - d.hp) / 6.0
	for i in 100:
		c.burn_along_beam(1.0 / 60.0)
	var h1 := d.hp
	for i in 6:
		c.burn_along_beam(1.0 / 60.0)
	var late := (h1 - d.hp) / 6.0
	check(late > early * (1.0 + Tuning.kl_searing_max * 0.9), "Searing: held on one foe it burns up to 50%% hotter (%.3f -> %.3f a frame)" % [early, late])
	clear(); reset_keeper(); give(["stoking"])
	c.beaming = true
	c.aim = Vector2.RIGHT
	d = dummy(spot + Vector2(80, -10), 1000.0)
	c.skill("fireglobe").cd = 4.0
	for i in 60:
		c.burn_along_beam(1.0 / 60.0)
	check(c.skill("fireglobe").cd < 4.0 - Tuning.kl_stoking_cut * 0.9, "Stoking: a second on a foe takes %.0f s off Fireglobe's cooldown (%.2f left)" % [Tuning.kl_stoking_cut, c.skill("fireglobe").cd])
	c.beaming = false
	clear()
	await frames(2)

# --- Hearth ring (optional) ----------------------------------------------------------------------------

func _ring() -> void:
	var hr: HearthRingSkill = c.skill("hearth_ring")
	clear(); reset_keeper(); give(["heavy_ring"])
	var d := dummy(spot + Vector2(60, 0))
	hr.ring()
	check(d._stun_t >= Tuning.kl_heavy_flare_stun - 0.01 and d._knock_v.length() * 0.2 >= Tuning.kl_heavy_ring_push * d.knock_weight - 1.0, "Heavy ring: it throws foes %.0f px and stuns them" % Tuning.kl_heavy_ring_push)
	clear(); reset_keeper(); give(["lasting_ring"])
	hr.ring()
	await frames(1)
	check(get_tree().get_nodes_in_group("burning_ground").size() == 1, "Lasting ring: the ground it sweeps keeps burning")
	clear(); reset_keeper(); give(["spill"])
	check(is_equal_approx(hr.cooldown(), Tuning.kl_spill_cd), "Spill: a %.1f s cooldown" % Tuning.kl_spill_cd)
	clear(); reset_keeper(); give(["warm_ring"])
	player.warmth = 50.0
	dummy(spot + Vector2(60, 0))
	dummy(spot + Vector2(-60, 0))
	hr.ring()
	check(is_equal_approx(player.warmth, 50.0 + 2.0 * Tuning.kl_warm_ring_warmth), "Warm ring: warmth back per foe hit (%.0f)" % player.warmth)
	clear(); reset_keeper(); give(["sunburst"])
	hr.ring()
	check(lampfire_bolts(1).size() == Tuning.kl_sunburst_count, "Sunburst: %d Lampfire bolts all around" % Tuning.kl_sunburst_count)
	clear(); reset_keeper(); give(["crackle"])
	d = dummy(spot + Vector2(60, 0), 100.0, 5.0)
	hr.ring()
	check(is_equal_approx(d.shell, 5.0 - Tuning.kl_crackle_shell), "Crackle: it strips %.0f shell (%.1f left)" % [Tuning.kl_crackle_shell, d.shell])
	clear(); reset_keeper(); give(["rising_ring"])
	d = dummy(spot + Vector2(180, 0))
	hr.ring()
	check(is_equal_approx(d.hp, 100.0), "Rising ring: a foe at 180 px is out of the first ring")
	for i in int(Tuning.kl_rising_ring_time * 60.0) + 2:
		hr.tick(1.0 / 60.0)
	check(d.hp < 100.0, "and the second ring reaches it")
	clear()
	await frames(2)

func _table() -> void:
	var rows := {}
	for r in load("res://scripts/ui/debug_panel.gd").ROWS:
		rows[r[0]] = true
	var missing := []
	for k in ["kl_points_per_level", "kl_tier2_level", "kl_respec_radius", "kl_catch_min_travel", "kl_twin_mult", "kl_skip_range",
			"kl_comet_every", "kl_slick_slow", "kl_beacon_time", "kl_beacon_radius", "kl_brand_mult", "kl_held_lance_time",
			"kl_ember_rest_time", "kl_ember_rest_radius", "kl_blink_dist", "kl_prism_mult", "kl_rising_ring_radius", "kl_affix_swift",
			"kl_lightless_snuff", "kl_ashbrood_hp2", "kl_ashbrood_hp3", "kl_ashbrood_wave_tell", "kl_ashbrood_strafe_tell"]:
		if not rows.has(k):
			missing.append(k)
	check(missing.is_empty(), "the pick, affix and Ashbrood numbers are in the tuning panel (missing %s)" % str(missing))
	var n := 0
	for s in SkillTree.ORDER:
		for t in 3:
			n += SkillTree.tier_picks(s, t).size()
	check(n == 42 and SkillTree.all_picks().size() == 42, "six trees, three tiers each: %d picks" % n)
	var cards_ok := true
	for card in SkillTree.CARD_TO_PICK:
		if not SkillTree.exists(SkillTree.CARD_TO_PICK[card]):
			cards_ok = false
	check(cards_ok and SkillTree.info("catching").skill == "lampfire" and SkillTree.info("spill").skill == "hearth_ring" and SkillTree.info("steady_hand").skill == "beam", "every old card has a home (GAME_PLAN §4.3)")
