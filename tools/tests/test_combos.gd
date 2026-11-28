extends Node
## M1c combos (docs/replan/PLAN_LANTERNS.md §3): the keeper's fire with a lamp's flame. Lampfire catches (once a
## bolt), a Fireglobe snaps onto a flame and flares the lamp (with a cooldown), a Lance chains two flames (gap and
## rock rules), the Beam feeds a flame; the §3 sums. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_combos.tscn

var main: Node
var fails := 0
var player: Node
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
	SaveGame.path = "user://test_ignore_save.json"
	SaveGame.delete_save()
	Settings.path = "user://test_ignore_settings.cfg"
	Settings.use_defaults()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	_run()

func wait(sec: float) -> void:
	for i in maxi(1, roundi(sec * 60.0)):
		await get_tree().process_frame

func clear() -> void:
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_pack"):
		s.queue_free()
	for l in get_tree().get_nodes_in_group("lantern"):
		if not l.old:
			l.remove_from_group("lantern")
			l.queue_free()
	for g in get_tree().get_nodes_in_group("burning_ground"):
		g.queue_free()
	LightSense.bump()

func lamp_at(p: Vector2) -> Lantern:
	var l := Lantern.new()
	l.kind = "post"
	l.position = p
	main.get_node("Lanterns").add_child(l)
	LightSense.bump()
	return l

## A dummy: a shell-less, slow Wickling with lots of health that stays put (its process is off).
func dummy(at: Vector2, hp := 100.0) -> Wickling:
	var w := Wickling.new()
	w.elite = true
	w.position = at
	spawner.add_child(w)
	w.shell = 0.0
	w.shell_max = 0.0
	w.hp = hp
	w.hp_max = hp
	w.set_process(false)
	return w

func open_spot() -> Vector2:
	var c := fog.tile_of(main.start + Vector2(-700, 300))
	for r in 30:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := c + Vector2i(dx, dy)
				var ok := true
				for oy in range(-16, 17):
					for ox in range(-16, 17):
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
	spawner = main.get_node("FogLayer/Wicklings")
	fog = main.fog
	bolts = FireBolts.inst
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	clear()
	for l in get_tree().get_nodes_in_group("lantern"):
		l.cold = true
	spot = open_spot()
	player.global_position = spot + Vector2(0, 700)
	Progress.level = 1
	await wait(0.1)
	await _catch_checks()
	await _flare_checks()
	await _chain_checks()
	await _feed_checks()
	_sum_checks()
	print("RESULT fails=%d" % fails)
	Art._ph.clear()
	get_tree().quit(1 if fails else 0)

func _catch_checks() -> void:
	var lamp := lamp_at(spot)
	var fp := lamp.flame_pos()
	check(lamp.has_flame() and fp == spot + Lantern.CROOK_LAMP, "a planted Post Lamp's flame is its crook lamp")
	var d := dummy(fp + Vector2(160, 0))
	await wait(0.05)
	var hp0 := d.hp
	var c0 := bolts.catches
	bolts.fire_lampfire(fp - Vector2(120, 0), Vector2.RIGHT)
	await wait(0.6)
	check(bolts.catches == c0 + 1, "a Lampfire bolt through a flame catches")
	var want := (Tuning.kl_lampfire_dmg + Tuning.kl_catch_dmg_add) * Tuning.kl_lit_dmg_mult
	check(is_equal_approx(hp0 - d.hp, want), "and hits harder: (2 + 1) x1.3 lit = %.1f (%.2f)" % [want, hp0 - d.hp])
	check(lamp.gulp_t >= 0.0, "the flame gulps")
	await wait(0.5)   # the first catch's side bolts finish their flight
	# The side bolts: two at +-18 degrees, 2 damage, 240 px; they can't catch again.
	var side_a := dummy(fp + Vector2.RIGHT.rotated(deg_to_rad(Tuning.kl_catch_spread_deg)) * 140.0, 50.0)
	var side_b := dummy(fp + Vector2.RIGHT.rotated(-deg_to_rad(Tuning.kl_catch_spread_deg)) * 140.0, 50.0)
	await wait(0.05)
	var n_before := bolts.in_flight(FireBolts.LAMPFIRE)
	bolts.fire_lampfire(fp - Vector2(60, 0), Vector2.RIGHT)
	await wait(0.2)
	check(bolts.in_flight(FireBolts.LAMPFIRE) >= n_before + 2, "a catch throws %d side bolts (%d in the air)" % [Tuning.kl_catch_split, bolts.in_flight(FireBolts.LAMPFIRE)])
	await wait(0.5)
	check(side_a.hp < 50.0 and side_b.hp < 50.0, "they fan out at +-%.0f degrees and hit (%.1f, %.1f)" % [Tuning.kl_catch_spread_deg, 50.0 - side_a.hp, 50.0 - side_b.hp])
	var one := Tuning.kl_catch_split_dmg * Tuning.kl_lit_dmg_mult
	check(50.0 - side_a.hp >= one - 0.01 and 50.0 - side_a.hp <= one + Tuning.kl_lampfire_splash_dmg * Tuning.kl_lit_dmg_mult + 0.01, "each side bolt does %.0f (x1.3 lit), plus at most a splash (%.2f)" % [Tuning.kl_catch_split_dmg, 50.0 - side_a.hp])
	# Once a bolt: two lamps in a row catch it once.
	var lamp2 := lamp_at(spot + Vector2(0, 120))
	var fp2 := lamp2.flame_pos()
	var lamp3 := lamp_at(spot + Vector2(96, 120))
	await wait(0.05)
	var c1 := bolts.catches
	var b := bolts.fire_lampfire(fp2 - Vector2(60, 0), Vector2.RIGHT)
	await wait(0.2)
	check(bolts.catches == c1 + 1 and b.caught, "a bolt catches once, even past two flames (%d)" % (bolts.catches - c1))
	# A snuffed lamp has no flame.
	lamp3.snuff(10.0)
	check(not lamp3.has_flame(), "a snuffed lamp has no flame to catch on")
	clear()
	await wait(0.1)

func _flare_checks() -> void:
	var lamp := lamp_at(spot)
	await wait(0.05)
	# The snap: a landing within 40 px of the flame moves onto it.
	var near := lamp.flame_pos() + Vector2(30, 10)
	check(KeeperCombat.snap_to_flame(near) == lamp.flame_pos(), "a Fireglobe landing within %.0f px of a flame snaps onto it" % Tuning.kl_flare_reach)
	var far := lamp.flame_pos() + Vector2(60, 0)
	check(KeeperCombat.snap_to_flame(far) == far, "farther out it doesn't")
	player.global_position = spot + Vector2(-200, 0)
	player.combat.aim_override = Vector2(200, 0) + Lantern.CROOK_LAMP + Vector2(25, 0)
	player.combat.update_aim(Vector2.ZERO)
	check(player.combat.globe_target() == lamp.flame_pos(), "the keeper's globe target snaps too (the marker shows on the flame)")
	player.combat.aim_override = Vector2.ZERO
	player.global_position = spot + Vector2(0, 700)
	# The flare: 16 in 160 px, the lamp's light x1.5, burning ground; no shell wear.
	var d := dummy(spot + Vector2(150, 0))
	var outside := dummy(spot + Vector2(0, 200))
	var shelled := Wickling.new()
	shelled.elite = true
	shelled.position = spot + Vector2(-100, 0)
	spawner.add_child(shelled)
	shelled.set_process(false)
	await wait(0.05)
	var hp0 := d.hp
	var out0 := outside.hp
	var sh0 := shelled.shell
	var f0 := bolts.flares
	bolts.throw_globe(spot + Vector2(-200, 0), lamp.flame_pos())
	await wait(Tuning.kl_fireglobe_flight + 0.05)
	check(bolts.flares == f0 + 1 and lamp.is_flaring(), "a Fireglobe on a flame flares the lamp")
	var want := Tuning.kl_flare_dmg * Tuning.kl_lit_dmg_mult
	check(hp0 - d.hp >= want - 0.01 and hp0 - d.hp < want + 2.0, "16 (x1.3 lit) to a foe 150 px from the lamp (%.1f; the burning ground adds a little)" % (hp0 - d.hp))
	check(out0 - outside.hp < 0.01, "nothing past %.0f px (%.2f)" % [Tuning.kl_flare_radius, out0 - outside.hp])
	check(is_equal_approx(shelled.shell, sh0), "and no shell wear (plan §4.5 unchanged)")
	check(lamp.get_light_radius() > Tuning.lantern_max_radius * 1.4, "its light swells to x%.1f (%.0f px)" % [Tuning.kl_flare_light_mult, lamp.get_light_radius()])
	check(get_tree().get_nodes_in_group("burning_ground").any(func(g): return is_equal_approx(g.radius, Tuning.kl_flare_ground_radius)), "it leaves burning ground in %.0f px" % Tuning.kl_flare_ground_radius)
	await wait(Tuning.kl_flare_time + 0.1)
	check(not lamp.is_flaring() and is_equal_approx(lamp.get_light_radius(), Tuning.lantern_max_radius), "after %.0f s its light settles back" % Tuning.kl_flare_time)
	# On cooldown the globe bursts as normal.
	check(lamp.flare_cd > 0.0 and not lamp.can_flare(), "a lamp flares at most once per %.0f s" % Tuning.kl_flare_lamp_cd)
	var f1 := bolts.flares
	bolts.throw_globe(spot + Vector2(-200, 0), lamp.flame_pos())
	await wait(Tuning.kl_fireglobe_flight + 0.05)
	check(bolts.flares == f1, "on cooldown a globe on the flame bursts as normal")
	clear()
	await wait(0.1)

func _chain_checks() -> void:
	var a := lamp_at(spot)
	var c := lamp_at(spot + Vector2(320, 0))
	var on_line := dummy(spot + Vector2(160, 4))
	var off_line := dummy(spot + Vector2(160, 70))
	var sh := Wickling.new()
	sh.elite = true
	sh.position = spot + Vector2(220, 0)
	spawner.add_child(sh)
	sh.set_process(false)
	sh.hp = 100.0
	sh.hp_max = 100.0
	await wait(0.05)
	var hp0 := on_line.hp
	var off0 := off_line.hp
	var sh0 := sh.shell
	var ch0 := bolts.chains
	# A Lance along the two flames (it flies above the foes on the ground line, so it hits nothing itself).
	bolts.fire_lance(a.flame_pos() - Vector2(20, 0), Vector2.RIGHT)
	await wait(0.6)
	check(bolts.chains == ch0 + 1, "a Lance past two flames chains them")
	var want := Tuning.kl_chain_dmg * Tuning.kl_lit_dmg_mult
	check(hp0 - on_line.hp >= want - 0.01, "%.0f (x1.3 lit) to a foe on the line between the lamps (%.1f)" % [Tuning.kl_chain_dmg, hp0 - on_line.hp])
	check(off0 - off_line.hp < 0.01, "nothing to a foe well off the line")
	check(sh.shell < sh0 - 0.5, "the chain wears shells fully (%.1f -> %.1f)" % [sh0, sh.shell])
	check(get_tree().get_nodes_in_group("foe").size() > 0 and bolts.get_parent().get_children().any(func(n): return n is ChainSeam), "and the line burns (a seam)")
	await wait(Tuning.kl_chain_burn_time + 0.1)
	# Too far apart: no chain.
	clear()
	await wait(0.05)
	var a2 := lamp_at(spot)
	var c2 := lamp_at(spot + Vector2(Tuning.kl_chain_max_gap + 40.0, 0))
	await wait(0.05)
	check(bolts.chain(a2, c2) == -1, "lamps more than %.0f px apart don't chain" % Tuning.kl_chain_max_gap)
	# Rock between: no chain.
	var c3 := lamp_at(spot + Vector2(256, 0))
	await wait(0.05)
	check(bolts.chain(a2, c3) >= 0, "two lamps 256 px apart, nothing between: they chain")
	var mid := fog.tile_of(spot + Vector2(128, 0))
	var i := fog.idx(mid)
	fog.solid[i] = 1
	check(bolts.chain(a2, c3) == -1, "with rock between, they don't")
	fog.solid[i] = 0
	# A third lamp in line chains on.
	clear()
	await wait(0.05)
	var l1 := lamp_at(spot)
	var l2 := lamp_at(spot + Vector2(150, 0))
	var l3 := lamp_at(spot + Vector2(300, 0))
	await wait(0.05)
	var ch1 := bolts.chains
	bolts.fire_lance(l1.flame_pos() - Vector2(20, 0), Vector2.RIGHT)
	await wait(0.8)
	check(bolts.chains == ch1 + 2, "a third lamp in line chains on (%d chains)" % (bolts.chains - ch1))
	clear()
	await wait(0.1)

func _feed_checks() -> void:
	var lamp := lamp_at(spot)
	await wait(0.05)
	player.global_position = lamp.flame_pos() + Vector2(-120, 10)
	player.combat.aim_override = Vector2.RIGHT
	player.combat.aim = Vector2.RIGHT
	player.combat.beaming = true
	player.combat.burn_along_beam(1.0 / 60.0)
	check(lamp.is_fed(), "the Beam on a flame feeds it")
	check(is_equal_approx(lamp.get_light_radius(), Tuning.lantern_max_radius * Tuning.kl_feed_light_mult), "its light x%.1f while fed" % Tuning.kl_feed_light_mult)
	var w := Wickling.new()
	check(is_equal_approx(lamp.core_dps_for(w), Tuning.wick_light_burn * Tuning.kl_feed_core_mult), "and its core burns x%.0f" % Tuning.kl_feed_core_mult)
	w.free()
	player.combat.beaming = false
	player.combat.aim_override = Vector2.ZERO
	await wait(0.2)
	check(not lamp.is_fed(), "it stops when the Beam leaves")
	clear()
	await wait(0.05)

## The §3 sums at level 1 (before the lit x1.3).
func _sum_checks() -> void:
	check(is_equal_approx(Tuning.kl_lance_dmg + Tuning.kl_chain_dmg, 11.0), "a Lance down a two-lamp line: 5 + 6 = 11 on one foe")
	check(is_equal_approx((Tuning.kl_lance_dmg + Tuning.kl_chain_dmg) / Tuning.kl_lance_cost, 55.0), "55 per charge (the plan's 25 without the chain)")
	check(is_equal_approx(Tuning.kl_flare_dmg, 2.0 * Tuning.kl_fireglobe_dmg) and Tuning.kl_flare_radius > Tuning.kl_fireglobe_radius, "a flare: 16 in 160 px for the same 0.3 charge, against 8 in 90")
	check(is_equal_approx(Tuning.kl_lampfire_dmg + Tuning.kl_catch_dmg_add, 3.0) and is_equal_approx(Tuning.kl_lampfire_dmg + Tuning.kl_catch_dmg_add + Tuning.kl_catch_split * Tuning.kl_catch_split_dmg, 7.0), "a catch: 3 on one target, up to 7 a bolt on a pack")
