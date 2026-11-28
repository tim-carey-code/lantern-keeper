extends Node
## M1c light states (docs/replan/PLAN_LANTERNS.md §2.1): dark (outside every light: x0.7, a shell can't break),
## dim (only the keeper's hand lamp: x1.0, as before), lit (a lamp's light: x1.3, shells wear x1.5). The linger;
## dim follows the hand lamp's charge; nests and steady lamp damage are exempt; the Ashbrood needs light. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_light_states.tscn

var main: Node
var fails := 0
var player: Node
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
		await get_tree().process_frame

func clear_foes() -> void:
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_pack"):
		s.queue_free()

func add_foe(f: Node2D, at: Vector2) -> Node2D:
	f.position = at
	spawner.add_child(f)
	return f

func lamp_at(p: Vector2) -> Lantern:
	var l := Lantern.new()
	l.kind = "post"
	l.position = p
	main.get_node("Lanterns").add_child(l)
	LightSense.bump()
	return l

## An open spot far from the hut, rock-free around it, for the light checks.
func open_spot() -> Vector2:
	var c := fog.tile_of(main.start + Vector2(-700, 300))
	for r in 30:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := c + Vector2i(dx, dy)
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
	return main.start + Vector2(-700, 300)

func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	player = main.player
	spawner = main.get_node("FogLayer/Wicklings")
	fog = main.fog
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	clear_foes()
	for l in get_tree().get_nodes_in_group("lantern"):
		l.cold = true
	LightSense.bump()
	spot = open_spot()
	player.global_position = spot + Vector2(0, 600)   # far off: its hand lamp reaches nothing here
	player.lamp_charge = 1.0
	await wait(0.1)
	await _state_checks()
	await _number_checks()
	await _shell_checks()
	await _exempt_checks()
	await _ashbrood_checks()
	await _look_checks()
	print("RESULT fails=%d" % fails)
	Art._ph.clear()
	get_tree().quit(1 if fails else 0)

func _state_checks() -> void:
	check(is_equal_approx(Tuning.kl_dark_dmg_mult, 0.7) and is_equal_approx(Tuning.kl_lit_dmg_mult, 1.3) and is_equal_approx(Tuning.kl_lit_shell_mult, 1.5) and is_equal_approx(Tuning.kl_dark_shell_floor, 1.0), "the approved numbers: dark x0.7, lit x1.3, lit shells x1.5, the dark floor 1")
	var w: Wickling = add_foe(Wickling.new(), spot)
	w.timid = false
	await wait(0.05)
	w.global_position = spot
	check(w.update_light_state(0.0) == Foe.DARK, "outside every light: dark")
	# The hand lamp: dim inside its radius.
	player.global_position = spot + Vector2(60, 0)
	check(w.update_light_state(0.0) == Foe.DIM, "inside only the hand lamp's light: dim")
	# Dim follows charge: at no charge the hand lamp is 44 px, so 60 px out is dark again.
	player.lamp_charge = 0.0
	check(player.get_light_radius() < 60.0 and w.update_light_state(0.0) == Foe.DARK, "the hand lamp's dim reach shrinks with its charge (%.0f px)" % player.get_light_radius())
	player.lamp_charge = 1.0
	player.global_position = spot + Vector2(0, 600)
	# A lamp: lit.
	var lamp := lamp_at(spot + Vector2(150, 0))
	await wait(0.02)
	check(w.update_light_state(0.0) == Foe.LIT and w.is_exposed(), "inside a lamp's light: lit (exposed)")
	check(w.light_from.distance_to(lamp.global_position) < 40.0, "and it knows where the light comes from (its rim faces it)")
	# The linger: it stays exposed 0.5 s after the lamp goes out.
	lamp.snuff(30.0)
	LightSense.bump()
	await wait(0.25)
	check(w.light_state == Foe.LIT, "out of the light it stays exposed for a moment (the linger)")
	await wait(0.4)
	check(w.light_state == Foe.DARK, "then it is dark again after %.1f s" % Tuning.kl_exposed_linger)
	lamp.queue_free()
	# The keeper's own fire never exposes: a lit WayLamp and a mirror beam do (WayLamps: while held).
	w.queue_free()
	await wait(0.05)

## The numbers on one Lampfire-sized hit (2 x the keeper's level: Lv 1).
func _number_checks() -> void:
	Progress.level = 1
	var dark: Wickling = add_foe(Wickling.new(), spot)
	var lit: Wickling = add_foe(Wickling.new(), spot + Vector2(0, 60))
	await wait(0.05)
	dark.global_position = spot
	lit.global_position = spot + Vector2(0, 60)
	var lamp := lamp_at(spot + Vector2(-20, 200))
	await wait(0.05)
	dark.global_position = spot + Vector2(500, 0)
	dark._exposed_t = 0.0   # it stood in the lamp's light a moment ago: no linger for this check
	player.global_position = spot + Vector2(500, 600)
	dark.update_light_state(0.0)
	lit.update_light_state(0.0)
	check(dark.light_state == Foe.DARK and lit.light_state == Foe.LIT, "one dark foe, one lit foe")
	var h0 := dark.hp
	dark.hurt(2.0, false, "lampfire")
	check(is_equal_approx(h0 - dark.hp, 1.4), "in the dark a 2-damage hit does 1.4 (%.2f)" % (h0 - dark.hp))
	var h1 := lit.hp
	lit.hurt(2.0, false, "lampfire")
	check(is_equal_approx(h1 - lit.hp, 2.6), "lit, it does 2.6 (%.2f)" % (h1 - lit.hp))
	# Dim: x1.0.
	player.global_position = dark.global_position + Vector2(40, 0)
	var h2 := dark.hp
	dark.hurt(1.0, false, "lampfire")
	check(dark.light_state == Foe.DIM and is_equal_approx(h2 - dark.hp, 1.0), "dim, it does what it always did (%.2f)" % (h2 - dark.hp))
	player.global_position = spot + Vector2(500, 600)
	# Time to kill, plan §2.1: a Lv 1 Wickling (3 hp) takes 3 hits in the dark, 2 lit.
	var a: Wickling = add_foe(Wickling.new(), spot + Vector2(500, 80))
	var b: Wickling = add_foe(Wickling.new(), spot + Vector2(0, 30))
	await wait(0.05)
	a.global_position = spot + Vector2(500, 80)
	b.global_position = spot + Vector2(0, 30)
	var na := 0
	while is_instance_valid(a) and not a._dead and na < 10:
		a.hurt(Tuning.kl_lampfire_dmg * Progress.dmg_mult(), false, "lampfire")
		na += 1
	var nb := 0
	while is_instance_valid(b) and not b._dead and nb < 10:
		b.hurt(Tuning.kl_lampfire_dmg * Progress.dmg_mult(), false, "lampfire")
		nb += 1
	check(na == 3 and nb == 2, "a Lv 1 Wickling: 3 Lampfire hits in the dark, 2 lit (%d, %d; plan §2.1)" % [na, nb])
	lamp.queue_free()
	clear_foes()
	await wait(0.05)

func _shell_checks() -> void:
	# The crook's guard: a Lv 2 shelled Wickling. In the dark its shell holds at the floor and clinks.
	Progress.level = 2
	var g: Wickling = Wickling.new()
	g.elite = true
	g.level = 2
	add_foe(g, spot + Vector2(400, 0))
	await wait(0.05)
	g.global_position = spot + Vector2(400, 0)
	var shell0 := g.shell
	var hp0 := g.hp
	for i in 30:
		g.hurt(Tuning.kl_lampfire_dmg * Progress.dmg_mult(), false, "lampfire")
	check(is_equal_approx(g.shell, Tuning.kl_dark_shell_floor) and is_equal_approx(g.hp, hp0), "in the dark its shell wears to %.1f and holds: it can't be killed (shell %.2f, was %.2f)" % [Tuning.kl_dark_shell_floor, g.shell, shell0])
	check(g._clink > 0.0, "a hit on the held shell clinks")
	for i in 5:
		g.hurt(Tuning.kl_lance_dmg * Progress.dmg_mult(), false, "lance")
	check(is_equal_approx(g.shell, Tuning.kl_dark_shell_floor), "not even Lance breaks it in the dark")
	# Dim (close in): it breaks as before. The plan: about 11 Lampfire hits for the whole guard, dim.
	g.shell = g.shell_max
	player.global_position = g.global_position + Vector2(50, 0)
	var dim_hits := 0
	while is_instance_valid(g) and not g._dead and dim_hits < 40:
		g.hurt(Tuning.kl_lampfire_dmg * Progress.dmg_mult(), false, "lampfire")
		dim_hits += 1
	check(dim_hits >= 9 and dim_hits <= 13, "close in (dim) the crook's guard falls to Lampfire: %d hits, about 3.5 s (plan §2.1: 11)" % dim_hits)
	# Lit: the shell wears x1.5 (3 hits), then 4 hits (plan: about 2.4 s).
	var h: Wickling = Wickling.new()
	h.elite = true
	h.level = 2
	add_foe(h, spot + Vector2(0, 40))
	var lamp := lamp_at(spot + Vector2(-20, 200))
	player.global_position = spot + Vector2(500, 600)
	await wait(0.05)
	h.global_position = spot + Vector2(0, 40)
	var shell_hits := 0
	while h.shell > 0.0 and shell_hits < 20:
		h.hurt(Tuning.kl_lampfire_dmg * Progress.dmg_mult(), false, "lampfire")
		shell_hits += 1
	var hp_hits := 0
	while is_instance_valid(h) and not h._dead and hp_hits < 20:
		h.hurt(Tuning.kl_lampfire_dmg * Progress.dmg_mult(), false, "lampfire")
		hp_hits += 1
	check(shell_hits == 3, "lit, Lampfire breaks its shell in 3 hits (x%.1f wear) (%d)" % [Tuning.kl_lit_shell_mult, shell_hits])
	check(hp_hits <= 4, "then 4 hits or fewer finish it (%d; plan §2.1: about 2.4 s in all)" % hp_hits)
	check((shell_hits + hp_hits) * Tuning.kl_lampfire_period <= 2.6, "lit, the whole guard takes %.2f s of Lampfire" % ((shell_hits + hp_hits) * Tuning.kl_lampfire_period))
	lamp.queue_free()
	Progress.level = 1
	clear_foes()
	await wait(0.05)

func _exempt_checks() -> void:
	# Lamp cores keep their 2 hp/s on small foes (steady lamp damage skips the rule).
	var w: Wickling = add_foe(Wickling.new(), spot)
	await wait(0.05)
	w.global_position = spot
	var h := w.hp
	w.hurt(1.0, false, "core")
	check(is_equal_approx(h - w.hp, 1.0), "a lamp's core burn skips the light rule (%.2f)" % (h - w.hp))
	h = w.hp
	w.hurt(0.5, false, "mirror")
	check(is_equal_approx(h - w.hp, 0.5), "and so does a mirror beam")
	# Nests skip the whole rule.
	var n := WickNest.new()
	add_foe(n, spot + Vector2(300, 300))
	await wait(0.05)
	check(n.light_exempt() and n.update_light_state(0.0) == Foe.DIM and n.light_dmg_mult("core") == 1.0, "nests are exempt (only cores hurt them)")
	var nh := n.hp
	n.hurt(2.0, false, "core")
	check(is_equal_approx(nh - n.hp, 2.0), "a core still burns a nest at full strength in the dark (%.2f)" % (nh - n.hp))
	# The first dark hit shows the tip.
	check(Story.tips_seen.has("dark") and Story.TIPS["dark"] == "In the dark they shrug off your fire. Bring light to them.", "the first dark hit shows the tip (DRAFT)")
	clear_foes()
	await wait(0.05)

func _ashbrood_checks() -> void:
	var b := Ashbrood.new()
	add_foe(b, spot)
	b.set_process(false)
	await wait(0.05)
	b.global_position = spot
	b.end_phase_pause()
	b.shell = 0.0
	# Dim counts as dark for it.
	player.global_position = spot + Vector2(40, 0)
	var h := b.hp
	b.hurt(10.0, false, "lance")
	check(b.update_light_state(0.0) == Foe.DIM and b.effective_light() == Foe.DARK, "for the Ashbrood, dim counts as dark")
	check(is_equal_approx(b.hp, h) and b._clink > 0.0 and b.dark_hint(), "in the dark every hit glances off (clink), and the boss bar says why")
	var bar = main.get_node("BossBar") if main.has_node("BossBar") else null
	check(bar == null or bar.DARK_HINT == "It shrugs off fire in the dark. Bring a lamp.", "its hint: \"It shrugs off fire in the dark. Bring a lamp.\" (DRAFT)")
	var lamp := lamp_at(spot + Vector2(-180, 0))
	await wait(0.02)
	b.hurt(10.0, false, "lance")
	check(b.is_exposed() and is_equal_approx(h - b.hp, 10.0 * Tuning.kl_lit_dmg_mult), "in a lamp's light it is hurt, x1.3 (%.1f)" % (h - b.hp))
	lamp.queue_free()
	# Elites and guardians still ignore light for movement and cores.
	check(lamp.core_dps_for(b) == 0.0, "cores still don't burn it")
	b.queue_free()
	player.global_position = spot + Vector2(0, 600)
	await wait(0.1)

func _look_checks() -> void:
	var d: Wickling = add_foe(Wickling.new(), spot + Vector2(300, 0))
	var l: Wickling = add_foe(Wickling.new(), spot + Vector2(0, 20))
	var lamp := lamp_at(spot + Vector2(-20, 200))
	await wait(0.1)
	d.global_position = spot + Vector2(300, 0)
	l.global_position = spot + Vector2(0, 20)
	await wait(0.05)
	check(d.light_tint().v < 0.7 and d.self_modulate.v < 0.7, "a dark foe is drawn dim and cold (eyes and rim read; tint %s)" % str(d.light_tint()))
	check(l.light_tint() == Color.WHITE, "a lit foe shows its full colours (and a warm rim: FoeBars)")
	var bars = main.get_node("FogLayer/FoeBars") if main.has_node("FogLayer/FoeBars") else null
	check(bars != null, "the foe bars draw the light cues")
	lamp.queue_free()
	clear_foes()
	await wait(0.05)
