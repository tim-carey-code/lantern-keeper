extends Node
## M1a "Fire in the Hollow": the keeper's skills (GAME_PLAN §3, §4.1, §4.5, §4.6, §15). Replaces test_combat.
## Lampfire (stream, burst, splash, light pop, charge back, range, rock), Fireglobe (lob, marker, reach, blast,
## burning ground, cost, cooldown), Lance (level 2 on LB with a toast, pierce, shells), the Beam and Hearth ring
## (optional, the slot rule), the shell rule, the dash, pad aim assist and aim hold, the auto-fire option,
## per-target hit-stop, damage numbers, the time-to-kill sums against the plan's targets, every new number in the
## F1 panel, and the old combat checks (drops over rock, elites from the fog, lanterns and Wicklings). Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_skills.tscn

var main: Node
var fails := 0
var fog: FogGrid
var player: Node
var c: KeeperCombat
var spawner: Node
var spot := Vector2.ZERO

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

## Tests must not react to a real controller plugged into this PC (the owner may be playing).
func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	strip_real_input()
	Tuning.wick_enabled = false   # only the foes this test makes
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
	Settings.path = "user://test_skills_settings.cfg"   # never the owner's settings
	Settings.use_defaults()
	InputHint.pad = false
	SaveGame.path = "user://test_skills_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	await _run()
	SaveGame.delete_save()
	Art._ph.clear()
	print("RESULT fails=%d" % fails)
	get_tree().quit(1 if fails else 0)

func _action_press(action: String, strength: float = 1.0) -> void:
	var e := InputEventAction.new()
	e.action = action; e.pressed = true; e.strength = strength
	Input.parse_input_event(e)

func _action_release(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action; e.pressed = false; e.strength = 0.0
	Input.parse_input_event(e)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

## A test foe that stays where it is put (stunned), unless still is false.
func _w(p: Vector2, elite := false, still := true) -> Wickling:
	var w: Wickling = spawner.spawn_at(p, elite)
	if still:
		w.stun(999.0)
	return w

func _alive(f) -> bool:
	return is_instance_valid(f) and not f.is_queued_for_deletion() and not f._dead

func _clear() -> void:
	for f in get_tree().get_nodes_in_group("foe"):
		if f is Wickling or f is Spitwick:
			f.queue_free()
	for e in get_tree().get_nodes_in_group("ember"):
		e.queue_free()
	for g in get_tree().get_nodes_in_group("burning_ground"):
		g.queue_free()
	for b in FireBolts.inst.bolts:
		b.alive = false

func _reset_keeper() -> void:
	player.global_position = spot
	player.reset_physics_interpolation()
	player.lamp_charge = 1.0
	player.warmth = Tuning.warmth_max
	for s in c.skills.values():
		s.cd = 0.0
	c.dash_cd = 0.0
	c.aim_override = Vector2.RIGHT

func _run() -> void:
	await _frames(3)
	fog = main.fog
	player = main.player
	c = player.combat
	spawner = main.get_node("FogLayer/Wicklings")
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	spot = main.start + Vector2(-500, 0)   # out in the dark, away from every lantern
	_reset_keeper()
	await _frames(2)
	await _bar()
	await _lampfire()
	await _aim()
	await _shell_rule()
	await _fireglobe()
	await _lance()
	await _beam_and_ring()
	await _dash()
	await _juice()
	await _time_to_kill()
	_panel_rows()
	await _old_checks()

# --- The bar (GAME_PLAN §3, §4.1) ----------------------------------------------------------------------

func _bar() -> void:
	check(c != null and c.skills.size() == 5, "the keeper carries the M1a kit: Lampfire, Fireglobe, Lance, the Beam, Hearth ring")
	check(Progress.bar == Progress.default_bar(), "level 1's bar: slot 1 Lampfire, slot 2 Fireglobe, slot 3 the Beam, slot 4 empty (%s)" % str(Progress.bar))
	check(c.slot_skill("skill_1").id == "lampfire" and c.slot_skill("skill_2").id == "fireglobe" and c.slot_skill("skill_3").id == "beam" and c.slot_skill("skill_4") == null, "RT Lampfire, RB Fireglobe, LB the Beam, Y empty")
	check(not Progress.knows("lance"), "no Lance at level 1")
	check(Progress.bind("skill_1", "fireglobe") != "" and Progress.bind("skill_2", "lampfire") != "", "slot 1 is always Lampfire, and Lampfire stays there")
	check(Progress.bind("skill_4", "fireglobe") == "" and Progress.bind("skill_2", "hearth_ring") != "", "Y takes any skill (M1c: an aimed one fires at the lock); an aimed slot refuses Hearth ring")
	Progress.bind("skill_2", "fireglobe")   # back to the default bar
	Progress.bind("skill_4", "")
	check(Progress.bind("skill_3", "lance") != "", "Lance can't go on the bar before it is learned")
	check(Progress.bind("skill_4", "hearth_ring") == "" and c.slot_skill("skill_4").id == "hearth_ring", "Hearth ring goes on slot 4")
	check(Progress.bind("skill_2", "beam") == "" and Progress.bar["skill_3"] == "" and Progress.bar["skill_2"] == "beam", "binding a skill moves it: the Beam to slot 2 leaves slot 3 empty")
	Progress.bar = Progress.default_bar()

# --- Lampfire ------------------------------------------------------------------------------------------

func _lampfire() -> void:
	var bolts := FireBolts.inst
	var lf: LampfireSkill = c.skill("lampfire")
	_reset_keeper()
	player.lamp_charge = 0.5
	var w := _w(spot + Vector2(120, -10))
	lf.fire()
	check(bolts.in_flight(FireBolts.LAMPFIRE) == 1, "Lampfire throws a bolt")
	await _frames(6)
	var b: FireBolts.Bolt = null
	for x in bolts.bolts:
		if x.alive:
			b = x
	check(b != null and b.trail.size() > 2, "it has a trail")
	check(b != null and absf(b.travelled - Tuning.kl_lampfire_speed * 6.0 / 60.0) < 9.0, "it flies at %d px/s (%.0f px in 0.1 s)" % [int(Tuning.kl_lampfire_speed), b.travelled if b else -1.0])
	check(bolts.light_points().size() == 1, "and lights the fog around it while it flies")
	fog.step(0.1)
	check(b != null and fog._light[fog.idx(fog.tile_of(b.pos))] > 0.0, "the fog takes that light")
	await _frames(20)
	check(_alive(w) and is_equal_approx(w.hp, Tuning.wick_hp - Tuning.kl_lampfire_dmg), "a hit does %s (hp %.2f)" % [str(Tuning.kl_lampfire_dmg), w.hp])
	var want := 0.5 + Tuning.kl_lampfire_charge + Tuning.kl_charge_regen * 26.0 / 60.0
	check(absf(player.lamp_charge - want) < 0.01, "and gives back %s charge (%.3f, want %.3f)" % [str(Tuning.kl_lampfire_charge), player.lamp_charge, want])
	check(FireFx.inst.count() > 0 and DamageNumbers.inst.count() > 0, "an impact flash, sparks, a light pop and a damage number")
	lf.fire()
	await _frames(26)
	check(not _alive(w), "a Lv 1 Wickling dies to 2 Lampfire hits (GAME_PLAN §4.6)")
	_clear()
	# The burst's splash: 1 to others within 40 px of the impact, nothing beyond.
	var target := _w(spot + Vector2(140, -10))
	var near := _w(spot + Vector2(140, 18))
	var far := _w(spot + Vector2(140, 60))
	lf.fire()
	await _frames(30)
	check(is_equal_approx(target.hp, Tuning.wick_hp - Tuning.kl_lampfire_dmg), "the bolt hits the first foe on its line")
	check(_alive(near) and is_equal_approx(near.hp, Tuning.wick_hp - Tuning.kl_lampfire_splash_dmg), "its burst splashes %s on a foe within %d px (hp %.2f)" % [str(Tuning.kl_lampfire_splash_dmg), int(Tuning.kl_lampfire_splash), near.hp])
	check(is_equal_approx(far.hp, Tuning.wick_hp), "and nothing past the splash")
	_clear()
	# Reach: an empty line, it fizzles at the end of its range with no burst.
	_reset_keeper()
	c.aim_override = Vector2(0, -1)
	lf.fire()
	await _frames(30)
	check(bolts.in_flight(FireBolts.LAMPFIRE) == 1, "still flying at %d px" % int(Tuning.kl_lampfire_speed * 0.5))
	await _frames(14)
	check(bolts.in_flight(FireBolts.LAMPFIRE) == 0, "gone at the end of its %d px reach" % int(Tuning.kl_lampfire_range))
	# The light pop clears fog where it bursts.
	_reset_keeper()
	c.aim_override = Vector2.RIGHT
	var deep := _w(spot + Vector2(120, -10))
	var t := fog.tile_of(deep.global_position)
	var d := fog.density
	d[fog.idx(t)] = 1.0
	fog.density = d
	lf.fire()
	await _frames(40)
	check(fog.density[fog.idx(t)] < 1.0 - Tuning.kl_lampfire_pop_clear * 0.7, "the light pop clears fog where it bursts (%.2f)" % fog.density[fog.idx(t)])
	_clear()
	# Rock stops it, and it bursts there.
	var rock := _rock_edge()
	player.global_position = fog.tile_center(rock + Vector2i(3, 0))
	player.reset_physics_interpolation()
	c.aim_override = Vector2.LEFT
	lf.fire()
	await _frames(14)
	check(bolts.in_flight() == 0, "rock stops a bolt (it bursts on the rock)")
	_clear()
	# Held: one bolt every 0.35 s.
	_reset_keeper()
	c.aim_override = Vector2(0, 1)
	var before := lf.fired
	Input.action_press("skill_1")
	await _frames(63)
	Input.action_release("skill_1")
	var n := lf.fired - before
	check(n == 3 or n == 4, "holding slot 1 streams Lampfire, one bolt every %s s (%d in 1.05 s)" % [str(Tuning.kl_lampfire_period), n])
	check(is_equal_approx(lf.cost(), 0.0), "Lampfire is free")
	await _frames(40)
	_clear()

func _rock_edge() -> Vector2i:
	for y in range(fog.rows):
		for x in range(fog.cols):
			var q := Vector2i(x, y)
			if fog.solid[fog.idx(q)] == 1 and fog.in_bounds(q + Vector2i(4, 0)) and fog.region[fog.idx(q + Vector2i(1, 0))] == FogGrid.R_HOLLOW \
					and fog.solid[fog.idx(q + Vector2i(1, 0))] == 0 and fog.solid[fog.idx(q + Vector2i(2, 0))] == 0 and fog.solid[fog.idx(q + Vector2i(3, 0))] == 0 and fog.solid[fog.idx(q + Vector2i(4, 0))] == 0:
				return q
	return Vector2i(-1, -1)

# --- Aim: assist and hold (pad) ----------------------------------------------------------------------

func _aim() -> void:
	_reset_keeper()
	var near := _w(spot + Vector2(150, -10 + tan(deg_to_rad(8.0)) * 150.0))
	var wide := _w(spot + Vector2(150, -10 - tan(deg_to_rad(20.0)) * 150.0))
	InputHint.pad = true
	var a := c.assisted(Vector2.RIGHT, Tuning.kl_lampfire_range)
	check(absf(a.angle_to(near.global_position - (player.global_position + Vector2(0, -10)))) < 0.01, "on a pad, aim assist pulls Lampfire onto a foe within %d degrees" % int(Tuning.kl_aim_assist_deg))
	near.queue_free()
	await _frames(1)
	check(c.assisted(Vector2.RIGHT, Tuning.kl_lampfire_range) == Vector2.RIGHT, "but not onto one 20 degrees off")
	InputHint.pad = false
	check(c.assisted(Vector2.RIGHT, Tuning.kl_lampfire_range) == Vector2.RIGHT, "and never with a mouse")
	wide.queue_free()
	# Aim hold: while RT is held, a released right stick keeps its last aim.
	InputHint.pad = true
	c.aim_override = Vector2.ZERO
	Input.action_press("aim_up", 1.0)
	await _frames(2)
	check(c.aim.distance_to(Vector2.UP) < 0.01, "the right stick aims")
	Input.action_press("skill_1")
	await _frames(1)
	Input.action_release("aim_up")
	await _frames(3)
	check(c.aim.distance_to(Vector2.UP) < 0.01, "with RT held, letting go of the stick keeps the aim (aim hold)")
	Input.action_release("skill_1")
	await _frames(2)
	check(c.aim.distance_to(Vector2.UP) > 0.5, "let go of RT too and the aim goes back to where you face")
	# Owner check 3: pressing B mid-stream heals without changing the held aim. The press goes through the
	# keeper's own frame (player._physics_process), not a direct call.
	player.flasks = 3; player.flask_lock = 0.0; player.warmth = 50.0; player.lamp_charge = 0.2
	Progress._input_block_until = 0
	Input.action_press("aim_up", 1.0)
	Input.action_press("skill_1")
	await _frames(2)
	Input.action_release("aim_up")
	var lf_before: int = c.skill("lampfire").fired
	Input.action_press("flask")
	await _frames(2)
	Input.action_release("flask")
	check(player.flasks == 2 and player.drinks > 0 and player.warmth >= 85.0, "B drinks a flask while RT is held (flasks %d, warmth %.0f)" % [player.flasks, player.warmth])
	check(c.aim.distance_to(Vector2.UP) < 0.01, "drinking with B keeps the fire aimed up")
	await _frames(25)
	check(c.skill("lampfire").fired > lf_before, "and Lampfire keeps streaming through the drink")
	Input.action_release("skill_1")
	await _frames(2)
	Tuning.kl_aim_hold = false
	Input.action_press("aim_up", 1.0)
	Input.action_press("skill_1")
	await _frames(2)
	Input.action_release("aim_up")
	await _frames(2)
	check(c.aim.distance_to(Vector2.UP) > 0.5, "with the aim hold off (F1), it doesn't hold")
	Input.action_release("skill_1")
	Tuning.kl_aim_hold = true
	# The auto-fire option: Lampfire streams while the right stick is pushed past 0.8, with no RT.
	var lf: LampfireSkill = c.skill("lampfire")
	var before := lf.fired
	Input.action_press("aim_right", 0.9)
	await _frames(20)
	check(lf.fired == before, "the right stick alone doesn't fire (auto-fire is off by default)")
	Settings.autofire = true
	await _frames(20)
	check(lf.fired > before, "with the auto-fire option, pushing the stick past %s fires Lampfire" % str(Tuning.kl_autofire_stick))
	Input.action_release("aim_right")
	Input.action_press("aim_right", 0.6)
	before = lf.fired
	await _frames(25)
	check(lf.fired == before, "but not below it")
	Input.action_release("aim_right")
	Settings.autofire = false
	InputHint.pad = false
	await _frames(40)
	_clear()

# --- The shell rule (GAME_PLAN §4.5) -------------------------------------------------------------------

func _shell_rule() -> void:
	check(Foe.shell_factor("lance") == 1.0 and Foe.shell_factor("beam") == 1.0 and Foe.shell_factor("lampfire") == 0.5, "shells: full from Lance and the Beam, half from Lampfire's hit")
	check(Foe.shell_factor("splash") == 0.0 and Foe.shell_factor("fireglobe") == 0.0 and Foe.shell_factor("ground") == 0.0 and Foe.shell_factor("ring") == 0.0 and Foe.shell_factor("core") == 0.0, "none from splash, Fireglobe, burning ground, Hearth ring or lamp cores")
	var e := _w(spot + Vector2(80, 0), true)
	await _frames(1)
	for src in ["splash", "fireglobe", "ground", "ring", "burn", "core"]:
		e.hurt(3.0, false, src)
	check(e.shell == Tuning.kl_elite_shell and e.hp == Tuning.kl_elite_hp, "they glance off an elite's shell")
	e.hurt(Tuning.kl_lampfire_dmg, false, "lampfire")
	check(is_equal_approx(e.shell, Tuning.kl_elite_shell - Tuning.kl_lampfire_dmg * 0.5) and e.hp == Tuning.kl_elite_hp, "a Lampfire hit wears half its damage off the shell (%.1f)" % e.shell)
	e.hurt(Tuning.kl_lance_dmg, false, "lance")
	var through: float = Tuning.kl_lance_dmg - (Tuning.kl_elite_shell - Tuning.kl_lampfire_dmg * 0.5)
	check(e.shell == 0.0 and is_equal_approx(e.hp, Tuning.kl_elite_hp - through), "a Lance hit breaks it, and what is left goes through (hp %.1f)" % e.hp)
	e.queue_free()
	var f := _w(spot + Vector2(80, 40), true)
	await _frames(1)
	f.shell = 1.0
	f.hurt(4.0, false, "lampfire")
	check(f.shell == 0.0 and is_equal_approx(f.hp, Tuning.kl_elite_hp - 2.0), "half-rate fire that breaks a shell carries on at full rate (hp %.1f)" % f.hp)
	f.queue_free()
	await _frames(1)

# --- Fireglobe ----------------------------------------------------------------------------------------

func _fireglobe() -> void:
	_reset_keeper()
	var bolts := FireBolts.inst
	var fg: FireglobeSkill = c.skill("fireglobe")
	var bar: ActionBar = main.get_node("HUD").action_bar
	bar.player = player
	InputHint.pad = true
	check(bar.slot_state("skill_2").key == "RB", "the action bar follows the last-used pad")
	var key_event := InputEventKey.new()
	InputHint._input(key_event)
	check(bar.slot_state("skill_2").key == "RMB", "the action bar follows the last-used keyboard/mouse")
	InputHint.pad = true
	c.aim_override = Vector2(200, 0)
	var land: Vector2 = player.global_position + Vector2(200, 0)
	var inside := _w(land + Vector2(0, 60), true)
	inside.shell = 0.0   # an unshelled elite: 9 hp, to see the blast's 8
	var outside := _w(land + Vector2(0, 140))
	check(c.slot_skill("skill_2") == fg and fg.press(), "RB throws a Fireglobe")
	var globe_state: Dictionary = bar.slot_state("skill_2")
	check(globe_state.id == "fireglobe" and globe_state.cd > 3.0 and globe_state.cd_max == Tuning.kl_fireglobe_cd, "the action bar shows a cooldown sweep and seconds above 3 s")
	await _frames(1)
	var targets := bolts.globe_targets()
	check(targets.size() == 1 and targets[0].distance_to(land) < 2.0, "it is lobbed to where you aim, with a marker where it will land")
	check(absf(player.lamp_charge - (1.0 - Tuning.kl_fireglobe_cost)) < 0.01, "it costs %s charge" % str(Tuning.kl_fireglobe_cost))
	check(is_equal_approx(fg.cd, Tuning.kl_fireglobe_cd) or fg.cd > Tuning.kl_fireglobe_cd - 0.05, "and starts its %s s cooldown" % str(Tuning.kl_fireglobe_cd))
	check(not fg.press(), "it can't be thrown again while it cools down")
	await _frames(int(Tuning.kl_fireglobe_flight * 60.0) - 6)
	check(bolts.in_flight(FireBolts.GLOBE) == 1 and inside.hp == Tuning.kl_elite_hp, "still in the air near the end of its %s s flight" % str(Tuning.kl_fireglobe_flight))
	await _frames(8)
	check(bolts.in_flight(FireBolts.GLOBE) == 0, "it lands")
	check(_alive(inside) and inside.hp < Tuning.kl_elite_hp - Tuning.kl_fireglobe_dmg + 0.01 and inside.hp > 0.0, "the blast does %s to everything within %d px (hp %.2f)" % [str(Tuning.kl_fireglobe_dmg), int(Tuning.kl_fireglobe_radius), inside.hp])
	check(outside.hp == Tuning.wick_hp, "and nothing beyond")
	var grounds := get_tree().get_nodes_in_group("burning_ground")
	check(grounds.size() == 1 and grounds[0].global_position.distance_to(land) < 2.0, "it leaves burning ground")
	await _frames(40)
	check(not _alive(inside), "the burning ground burns what stands in it (%s hp/s)" % str(Tuning.kl_fireglobe_burn_dps))
	var stander := _w(land + Vector2(30, 0), true)
	stander.shell = 0.0
	await _frames(60)
	check(_alive(stander) and absf((Tuning.kl_elite_hp - stander.hp) - Tuning.kl_fireglobe_burn_dps) < 0.25, "about %s a second (%.2f in 1 s)" % [str(Tuning.kl_fireglobe_burn_dps), Tuning.kl_elite_hp - stander.hp])
	await _frames(int(Tuning.kl_fireglobe_burn_time * 60.0) - 100 + 12)
	check(get_tree().get_nodes_in_group("burning_ground").is_empty(), "the ground stops burning after %s s" % str(Tuning.kl_fireglobe_burn_time))
	_clear()
	# Reach: 120-280 px.
	_reset_keeper()
	c.aim_override = Vector2(40, 0)
	check(c.globe_target().distance_to(player.global_position) > Tuning.kl_fireglobe_min - 1.0, "it lands at least %d px out" % int(Tuning.kl_fireglobe_min))
	c.aim_override = Vector2(900, 0)
	check(absf(c.globe_target().distance_to(player.global_position) - Tuning.kl_fireglobe_max) < 1.0, "and at most %d px" % int(Tuning.kl_fireglobe_max))
	InputHint.pad = true
	c.aim_override = Vector2.ZERO
	Input.action_press("aim_right", 0.45)
	await _frames(2)
	var mid: float = c.globe_target().distance_to(player.global_position)
	Input.action_release("aim_right")
	Input.action_press("aim_right", 1.0)
	await _frames(2)
	var full: float = c.globe_target().distance_to(player.global_position)
	Input.action_release("aim_right")
	InputHint.pad = false
	check(mid < full - 60.0 and mid >= Tuning.kl_fireglobe_min, "on a pad, the stick's tilt sets how far it goes (%.0f px half-tilted, %.0f px full)" % [mid, full])
	# Short of charge: it won't throw, and the bar greys it.
	_reset_keeper()
	player.lamp_charge = Tuning.kl_fireglobe_cost - 0.05
	check(fg.short_of_charge() and bar.slot_state("skill_2").short and not fg.press(), "short of charge, the action-bar slot greys out and won't throw")
	await _frames(2)

# --- Lance and level 2 ---------------------------------------------------------------------------------

func _lance() -> void:
	_reset_keeper()
	var hud = main.get_node("HUD")
	Progress.add_wick(Progress.wick_needed())
	check(Progress.level == 2 and Progress.knows("lance"), "level 2 brings Lance")
	check(Progress.bar["skill_3"] == "lance" and Progress.slot_of("beam") == "", "Lance takes slot 3 (LB); the Beam is off the bar, one press away in the Skills list")
	check(hud.toast.text.contains("Lance takes") and hud.toast.text.contains("The Beam is in your Skills list (%s)" % InputHint.key("skills")), "a toast says so, with the Skills list's button (%s)" % hud.toast.text)
	check(Story.tips_seen.has("beam_off_bar"), "and the one-time Beam hint is marked seen, so it doesn't repeat the toast")
	await _frames(2)
	_close_cards()
	await _frames(2)
	Tuning.ui_open = false; get_tree().paused = false; Progress._input_block_until = 0
	var bolts := FireBolts.inst
	var ln: LanceSkill = c.skill("lance")
	var line := []
	for i in 4:
		line.append(_w(spot + Vector2(70 + i * 34, -10)))
	check(c.slot_skill("skill_3") == ln and ln.press(), "LB throws a Lance")
	await _frames(1)
	check(absf(player.lamp_charge - (1.0 - Tuning.kl_lance_cost)) < 0.01, "it costs %s charge" % str(Tuning.kl_lance_cost))
	check(not ln.press(), "and has a cooldown (%s s)" % str(Tuning.kl_lance_cd))
	await _frames(30)
	var dead := 0
	for w in line:
		if not _alive(w):
			dead += 1
	check(dead == Tuning.kl_lance_pierce and _alive(line[3]) and line[3].hp == Tuning.wick_hp, "it passes through %d foes and stops (%d burned, the 4th untouched)" % [Tuning.kl_lance_pierce, dead])
	_clear()
	await _frames(int(Tuning.kl_lance_cd * 60.0))
	var e := _w(spot + Vector2(120, -10), true)
	c.aim_override = Vector2.RIGHT
	check(ln.press(), "ready again after %s s" % str(Tuning.kl_lance_cd))
	var hit_t := 0
	for i in 20:
		await _frames(1)
		if e.shell < Tuning.kl_elite_shell:
			hit_t = i
			break
	check(e.shell == 0.0 and is_equal_approx(e.hp, Tuning.kl_elite_hp - (Tuning.kl_lance_dmg * Progress.dmg_mult() - Tuning.kl_elite_shell)), "Lance breaks a shell outright: the shell-breaker (hp %.1f; a level-%d keeper hits x%.1f, M1b)" % [e.hp, Progress.level, Progress.dmg_mult()])
	check(e._hitstop_t > 0.0 and e.is_stunned() and Engine.time_scale == 1.0, "a big hit freezes only its target for a moment, never the whole game")
	var speed_px := (120.0 - 12.0 - Tuning.kl_elite_hp) / maxf(1.0, float(hit_t + 1)) * 60.0
	check(speed_px > Tuning.kl_lance_speed * 0.6, "Lance is fast (about %d px/s)" % int(Tuning.kl_lance_speed))
	_clear()
	await _frames(2)

## Closes the level-up cards through the real choice, then takes the chosen upgrades back: the offer is shuffled,
## and a card such as Catching, Spill, Tight focus or Deep tank would change what later checks measure.
func _close_cards() -> void:
	var cards = main.get_node("HUD").level_up_screen
	var before: Array[String] = Progress.combat_upgrades.duplicate()
	while cards.root.visible:
		cards._choose(cards._offer[0].id)
	Progress.combat_upgrades = before

# --- The Beam and Hearth ring (optional) --------------------------------------------------------------

func _beam_and_ring() -> void:
	_reset_keeper()
	check(Progress.bind("skill_3", "beam") == "" and Progress.bar["skill_3"] == "beam", "one press in the Skills list puts the Beam back on LB")
	var e := _w(spot + Vector2(120, -10), true)
	_action_press("skill_3")
	await _frames(30)
	check(c.beaming, "holding LB beams")
	var worn := Tuning.kl_elite_shell - e.shell
	check(absf(worn - Tuning.kl_beam_dps * 0.5) < 0.6, "the Beam does %s hp/s and wears shells fully (%.2f in 0.5 s)" % [str(Tuning.kl_beam_dps), worn])
	var beam_charge_want := 1.0 - Tuning.kl_beam_cost * 0.5 + Tuning.kl_charge_regen * 0.5
	check(absf(player.lamp_charge - beam_charge_want) < 0.03, "it costs %s charge a second (%.3f, want %.3f)" % [str(Tuning.kl_beam_cost), player.lamp_charge, beam_charge_want])
	_action_release("skill_3")
	await _frames(2)
	check(not c.beaming, "let go and it stops")
	_clear()
	Progress.bind("skill_3", "lance")
	# Hearth ring, on Y.
	_reset_keeper()
	check(Progress.bind("skill_4", "hearth_ring") == "", "Hearth ring goes on Y")
	var near := _w(spot + Vector2(60, 0))
	var outside := _w(spot + Vector2(Tuning.kl_burst_radius + 50, 0))
	await _frames(1)  # make the fresh test foes visible to the immediate shape query
	var from_d: float = near.global_position.distance_to(player.global_position)
	near._stun_t = 0.0
	var ring: HearthRingSkill = c.skill("hearth_ring")
	check(ring.ring() >= 1, "Y fires Hearth ring")
	check(ring.last_hits >= 1 and is_equal_approx(near.hp, Tuning.wick_hp - Tuning.kl_burst_dmg * Progress.dmg_mult()) and outside.hp == Tuning.wick_hp, "a ring of flame does %s (x%.1f at level %d) inside %d px, nothing outside" % [str(Tuning.kl_burst_dmg), Progress.dmg_mult(), Progress.level, int(Tuning.kl_burst_radius)])
	check(near._ignite_t > 0.0, "and sets what it hits alight")
	check(absf(player.lamp_charge - (1.0 - Tuning.kl_burst_cost)) < 0.01 and ring.cd > Tuning.kl_burst_cd - 0.1, "it costs %s charge, %s s cooldown" % [str(Tuning.kl_burst_cost), str(Tuning.kl_burst_cd)])
	near.stun(999.0)
	await _frames(14)
	var pushed: float = near.global_position.distance_to(player.global_position) - from_d if _alive(near) else -1.0
	check(pushed > Tuning.kl_burst_knock * 0.8 and pushed < Tuning.kl_burst_knock * 1.3, "with a small push (%.0f px, %d wanted)" % [pushed, int(Tuning.kl_burst_knock)])
	await _frames(60)
	check(not _alive(near) or near.hp < Tuning.wick_hp - Tuning.kl_burst_dmg * Progress.dmg_mult() - Tuning.kl_burst_burn_dps * 0.8, "it burns at %s hp/s for %s s" % [str(Tuning.kl_burst_burn_dps), str(Tuning.kl_burst_burn_time)])
	check(c.burst() == -1, "the old burst() is Hearth ring now, with its cooldown")
	Progress.bar["skill_4"] = ""
	_clear()
	await _frames(2)

# --- The dash (built) ----------------------------------------------------------------------------------

func _dash() -> void:
	_reset_keeper()
	var from: Vector2 = player.global_position
	Input.action_press("move_right")
	check(c.dash(Vector2.RIGHT), "LT / Space starts the dash")
	await _frames(1)
	check(c.is_dashing(), "the dash is active")
	var w0: float = player.warmth
	player.chill(50.0)
	check(player.warmth == w0, "nothing can chill you mid-dash")
	await _frames(18)
	Input.action_release("move_right")
	var moved: float = player.global_position.x - from.x
	check(moved > Tuning.kl_dash_dist * 0.9, "the dash carries you about %d px (%.0f)" % [int(Tuning.kl_dash_dist), moved])
	check(not c.dash(Vector2.RIGHT) or c.dash_cd > 0.0, "the dash has a cooldown")
	await _frames(2)

# --- Juice (GAME_PLAN §15) -----------------------------------------------------------------------------

func _juice() -> void:
	_reset_keeper()
	player.shake(1.0)
	Settings.shake = 1.0
	var o1: Vector2 = player.shake_offset()
	Settings.shake = 0.0
	check(o1.length() > 0.5 and player.shake_offset() == Vector2.ZERO, "screen shake (trauma) follows the screen-shake setting; 0 turns it off")
	Settings.shake = 1.0
	await _frames(60)
	check(player._shake < 0.2, "trauma fades on its own (%.2f)" % player._shake)
	Settings.reduce_flashes = true
	check(Settings.flash_mult() < 0.5, "\"reduce flashes\" dims flashes")
	var w := _w(spot + Vector2(60, 0))
	w.hurt(1.0, false, "lampfire")
	w.tick_foe(0.001)
	check(w.self_modulate.r < 2.0, "a hit flash is softer with it on (%.2f)" % w.self_modulate.r)
	Settings.reduce_flashes = false
	w.hurt(0.5, false, "lampfire")
	w.tick_foe(0.001)
	check(w.self_modulate.r > 2.0, "and bright without it")
	var nums := DamageNumbers.inst.count()
	w.hurt(1.0, false, "lance")
	check(DamageNumbers.inst.count() > nums, "hits pop a damage number")
	var big := _w(spot + Vector2(60, 40), true)
	big.shell = 0.0
	big.hurt(99.0, false, "lance")
	check(player._hitstop_t > 0.0 and Engine.time_scale == 1.0, "killing a big foe freezes the keeper for a moment (hit-stop), not the game")
	_clear()
	await _frames(10)

# --- Time to kill (GAME_PLAN §4.6, the balance method in the ARPG skill) ------------------------------------

## M1c (PLAN_LANTERNS §2.1, §8 item 3): the light rule's numbers come from tuning.gd's defaults (this test turns the
## rule off for its older checks). The Ashbrood is hurt only when lit: phase 1 in the bowl lit by a lamp (the rim
## lamp: always lit while it burns), 35% uptime as before (dodging its bolts, sweeps and puffs); phase 2 only while it
## sits on a lamp (kl_ashbrood_sit_sec of each dive cycle; you unload into the sit, 80%), with the lamps it smothers
## going out in turn. The Clinker: dim (close in) as before, or lit (a lamp planted by its post).
func _m1c_time_to_kill(lf_dps: float, lf_shell: float, lance_dark: float, lance_lamp: float, clinker_scale: float, brood_scale: float, brood_scale_l5: float) -> void:
	var d = load("res://systems/tuning.gd").new()
	var lit: float = d.kl_lit_dmg_mult
	var wear: float = d.kl_lit_shell_mult
	var hp: float = d.kl_ashbrood_hp
	var phase_lit: float = d.kl_ashbrood_shell / ((lf_shell + lance_lamp) * wear) + hp / ((lf_dps + lance_lamp) * lit)
	var cycle: float = d.kl_ashbrood_sit_sec + d.kl_ashbrood_dive_period + d.kl_ashbrood_dive_tell + d.kl_ashbrood_dive_travel
	var up2: float = 0.8 * d.kl_ashbrood_sit_sec / cycle
	var fight: float = phase_lit * brood_scale / 0.35 + phase_lit * brood_scale / up2
	var fight_l5: float = phase_lit * brood_scale_l5 / 0.35 + phase_lit * brood_scale_l5 / up2
	print("    M1c Ashbrood (lit only, %.0f hp a phase): phase 1 %.0f s at 35%%, phase 2 %.0f s at %.0f%% (sits %.1f s of each %.1f s dive): %.0f s at L4, %.0f s at L5" % [hp, phase_lit * brood_scale / 0.35, phase_lit * brood_scale / up2, up2 * 100.0, d.kl_ashbrood_sit_sec, cycle, fight, fight_l5])
	check(fight > 110.0 and fight < 180.0, "M1c: the Ashbrood, hurt only when lit, takes 2-3 minutes at L4 (%.0f s)" % fight)
	check(fight_l5 > 105.0 and fight_l5 < 180.0, "and about 2 minutes for a L5 explorer (%.0f s)" % fight_l5)
	# The Clinker: dim is the old sum; lit (a lamp by its post) is faster; dark can't break its shell at all.
	var cl_lit: float = d.kl_clinker_shell / ((lf_shell + lance_dark) * wear) + d.kl_clinker_hp / ((lf_dps + lance_dark) * lit)
	var cl_dim: float = d.kl_clinker_shell / (lf_shell + lance_dark) + d.kl_clinker_hp / (lf_dps + lance_dark)
	print("    M1c Clinker: %.0f s dim (close in), %.0f s lit (a lamp by its post), at 25%% uptime; in the dark its shell holds" % [cl_dim * clinker_scale / 0.25, cl_lit * clinker_scale / 0.25])
	check(cl_lit * clinker_scale / 0.25 > 18.0 and cl_lit * clinker_scale / 0.25 < 40.0, "M1c: the Clinker lit still takes about 20-30 s (%.0f s)" % (cl_lit * clinker_scale / 0.25))
	d.free()

func _time_to_kill() -> void:
	# The sums, from tuning.gd (GAME_PLAN §4.6). M1b: foe health and shell grow 12% a level over 1, and the keeper's
	# damage 10% a level over 1. The keeper meets the Clinker (Lv 4) at L3-L4 and the Ashbrood (Lv 5) at L4 (a pure
	# beeline) or L5 (an explorer) (test_leveling); the sums below use the lower keeper level, the slower fight.
	var foe_m := func(lv: int) -> float: return 1.0 + Tuning.kl_foe_hp_per_level * (lv - 1)
	var dmg_m := func(lv: int) -> float: return 1.0 + Tuning.kl_dmg_per_level * (lv - 1)
	var clinker_scale: float = foe_m.call(Tuning.kl_clinker_level) / dmg_m.call(3)
	var brood_scale: float = foe_m.call(Tuning.kl_ashbrood_level) / dmg_m.call(4)
	var brood_scale_l5: float = foe_m.call(Tuning.kl_ashbrood_level) / dmg_m.call(5)
	var lf_dps := Tuning.kl_lampfire_dmg / Tuning.kl_lampfire_period
	var lf_shell := Tuning.kl_lampfire_dmg * 0.5 / Tuning.kl_lampfire_period
	var hits_charge := Tuning.kl_lampfire_charge / Tuning.kl_lampfire_period
	var income_dark := Tuning.kl_charge_regen + hits_charge
	var income_lamp := income_dark + Tuning.kl_light_charge_hunted
	var lance_dps_dark := minf(income_dark / Tuning.kl_lance_cost, 1.0 / Tuning.kl_lance_cd) * Tuning.kl_lance_dmg
	var lance_dps_lamp := minf(income_lamp / Tuning.kl_lance_cost, 1.0 / Tuning.kl_lance_cd) * Tuning.kl_lance_dmg
	check(ceili(Tuning.wick_hp / Tuning.kl_lampfire_dmg) == 2, "a Wickling (%s hp) dies to 2 Lampfire hits" % str(Tuning.wick_hp))
	var clinker := Tuning.kl_clinker_shell / (lf_shell + lance_dps_dark) + Tuning.kl_clinker_hp / (lf_dps + lance_dps_dark)
	var clinker_fight := clinker * clinker_scale / 0.25
	print("    Clinker: %.1f s of damage (%.1f dps on health), about %.0f s at 25%% uptime (target about 30 s)" % [clinker, lf_dps + lance_dps_dark, clinker_fight])
	check(clinker_fight > 22.0 and clinker_fight < 40.0, "the Clinker (%s hp, %s shell) takes about 30 s (%.0f s)" % [str(Tuning.kl_clinker_hp), str(Tuning.kl_clinker_shell), clinker_fight])
	var phase_lamp := Tuning.kl_ashbrood_shell / (lf_shell + lance_dps_lamp) + Tuning.kl_ashbrood_hp / (lf_dps + lance_dps_lamp)
	var phase_dark := Tuning.kl_ashbrood_shell / (lf_shell + lance_dps_dark) + Tuning.kl_ashbrood_hp / (lf_dps + lance_dps_dark)
	var fight_lamp := phase_lamp * brood_scale * 2.0 / 0.35
	var fight_dark := phase_dark * brood_scale * 2.0 / 0.35
	var fight_l5 := phase_lamp * brood_scale_l5 * 2.0 / 0.35
	print("    scaled: the Clinker Lv %d (x%.2f health) against a L3 keeper (x%.1f damage); the Ashbrood Lv %d (x%.2f) against L4 (x%.1f): %.0f s, or %.0f s at L5" % [Tuning.kl_clinker_level, foe_m.call(Tuning.kl_clinker_level), dmg_m.call(3), Tuning.kl_ashbrood_level, foe_m.call(Tuning.kl_ashbrood_level), dmg_m.call(4), fight_lamp, fight_l5])
	# M1c: these two Ashbrood sums are light-blind (the old rule); the target is now the lit-only sum below.
	print("    Ashbrood: 2 phases; %.0f s with a lamp near (charge %.2f/s), %.0f s without (%.2f/s), at 35%% uptime (target about 2 min, 2.6 without a lamp)" % [fight_lamp, income_lamp, fight_dark, income_dark])
	_m1c_time_to_kill(lf_dps, lf_shell, lance_dps_dark, lance_dps_lamp, clinker_scale, brood_scale, brood_scale_l5)
	# A real fight: Lampfire alone on a shelled elite (the crook's guard) from 120 px.
	_reset_keeper()
	var e := _w(spot + Vector2(120, -10), true)
	Input.action_press("skill_1")
	var t := 0
	while _alive(e) and t < 600:
		await _frames(1)
		t += 1
	Input.action_release("skill_1")
	var secs := t / 60.0
	print("    a shelled elite to Lampfire alone: %.2f s" % secs)
	check(secs > 2.5 and secs < 5.0, "a shelled elite falls to Lampfire alone in about 3 s (%.2f s; the plan's 3-5 s, 3.5 with M1b's foe scaling)" % secs)
	await _frames(40)
	_clear()
	# The first packs fall to Lampfire, Fireglobe and Lance alone (owner check 7): a plain pack of 4 Wicklings.
	_reset_keeper()
	var pack := []
	for off in [Vector2(200, -20), Vector2(215, 15), Vector2(190, 30), Vector2(250, -60)]:
		pack.append(_w(spot + off))
	c.aim_override = Vector2(205, 0)
	c.skill("fireglobe").press()
	Input.action_press("skill_1")
	c.aim_override = Vector2(250, -60 + 10).normalized()
	t = 0
	while pack.any(func(x): return _alive(x)) and t < 600:
		await _frames(1)
		t += 1
	Input.action_release("skill_1")
	check(t < 300, "a plain pack of 4 falls to a Fireglobe and a Lampfire stream in %.1f s (target 2-5 s)" % (t / 60.0))
	await _frames(40)
	_clear()

# --- Every new number is a kl_ tuning value in the F1 panel -------------------------------------------------

func _panel_rows() -> void:
	var rows: Array = load("res://scripts/ui/debug_panel.gd").get_script_constant_map()["ROWS"]
	var keys := rows.map(func(r): return r[0])
	var src := FileAccess.get_file_as_string("res://systems/tuning.gd")
	var block := src.substr(src.find("# M1a: fire in the Hollow"), src.find("# Feedback (PROTOTYPE)") - src.find("# M1a: fire in the Hollow"))
	var missing := []
	var rx := RegEx.create_from_string("(?m)^var (kl_\\w+)")
	for m in rx.search_all(block):
		if not keys.has(m.get_string(1)):
			missing.append(m.get_string(1))
	for k in ["kl_beam_dps", "kl_burst_burn_dps", "kl_burst_burn_time", "kl_burst_knock", "kl_burst_cd", "kl_clinker_hp", "kl_ashbrood_hp", "kl_shake_px",
			"kl_shake_lance_hit", "kl_shake_lance_cast", "kl_shake_globe", "kl_shake_ring", "kl_shake_kill", "kl_shake_kill_big",
			"kl_oil_pull", "kl_pickup_hold", "kl_stick_aim_min", "kl_stick_tilt_full"]:
		if not keys.has(k) or not k in Tuning:
			missing.append(k)
	check(missing.is_empty() and rx.search_all(block).size() >= 50, "every M1a number is a kl_ tuning value with a row in the F1 panel (missing: %s)" % str(missing))
	# And the M1a code reads them: no bare numbers left in its shake calls, the oil pull, the pick-up hold or the
	# right stick's tilt.
	var bare := []
	var shake_rx := RegEx.create_from_string("shake\\(\\s*[0-9.]")
	for f in ["res://scripts/player/skills/fire_bolts.gd", "res://scripts/player/skills/lance.gd", "res://scripts/player/skills/hearth_ring.gd", "res://scripts/enemies/foe.gd"]:
		if shake_rx.search(FileAccess.get_file_as_string(f)) != null:
			bare.append(f.get_file())
	var reads := {"res://scripts/enemies/ember.gd": "kl_oil_pull", "res://scripts/player/player.gd": "kl_pickup_hold", "res://scripts/player/combat.gd": "kl_stick_aim_min"}
	for f in reads:
		if not FileAccess.get_file_as_string(f).contains(reads[f]):
			bare.append(f.get_file())
	check(bare.is_empty() and not FileAccess.get_file_as_string("res://scripts/player/player.gd").contains("HOLD_TO_PICK_UP") \
			and FileAccess.get_file_as_string("res://scripts/player/combat.gd").contains("kl_stick_tilt_full"), "the shake amounts, oil pull, pick-up hold and stick tilt read those values (bare numbers in: %s)" % str(bare))

# --- The old combat checks, kept ---------------------------------------------------------------------------

func _old_checks() -> void:
	_reset_keeper()
	# A Wickling burned over rock drops its ember on ground you can walk on.
	var rock := Vector2i(-1, -1)
	for y in range(fog.rows):
		for x in range(fog.cols):
			var q := Vector2i(x, y)
			if rock.x < 0 and fog.solid[fog.idx(q)] == 1 and fog.in_bounds(q + Vector2i(2, 0)) and fog.solid[fog.idx(q + Vector2i(2, 0))] == 0 and fog.region[fog.idx(q + Vector2i(2, 0))] == FogGrid.R_HOLLOW:
				rock = q
	check(rock.x >= 0, "found rock at the Hollow's edge")
	for em in get_tree().get_nodes_in_group("ember"):
		em.free()
	var scrap_chance := Tuning.wick_scrap_chance
	Tuning.wick_scrap_chance = 1.0   # M1b: a kill's only drop (no fuel ember) is the chance of scrap
	var over_rock := _w(fog.tile_center(rock))
	over_rock.hurt(99.0)
	Tuning.wick_scrap_chance = scrap_chance
	var landed := get_tree().get_nodes_in_group("ember").filter(func(em): return not em.is_queued_for_deletion())
	check(landed.size() >= 1 and landed.all(func(em): return fog.solid[fog.idx(fog.tile_of(em.global_position))] == 0), "drops from a Wickling over rock land on walkable ground")
	for em in landed:
		em.queue_free()
	# Every Nth Wickling out of the fog is an elite.
	Tuning.wick_enabled = true
	var elites := 0
	for i in Tuning.kl_elite_every * 3:
		var w = spawner.spawn_near_player()
		if w and w.elite:
			elites += 1
	check(elites >= 2, "every %dth Wickling out of the fog is an elite (%d of %d)" % [Tuning.kl_elite_every, elites, Tuning.kl_elite_every * 3])
	Tuning.wick_enabled = false
	_clear()
	await _frames(2)
	# Lanterns: timid Wicklings stay out; brave ones walk in but burn and run; elites don't care.
	var lamp_t := Lantern.new()
	lamp_t.position = fog.tile_center(fog.tile_of(player.global_position + Vector2(0, 200)))
	main.get_node("Lanterns").add_child(lamp_t)
	player.global_position += Vector2(-600, 0)
	var brave := _w(lamp_t.global_position + Vector2(60, 0), false, false)
	brave.timid = false
	var timid_w := _w(lamp_t.global_position + Vector2(70, 30), false, false)
	timid_w.timid = true
	var elite_w := _w(lamp_t.global_position + Vector2(20, 0), true, false)
	elite_w.shell = 0.0   # no shell, so only "ignores lanterns" can save it
	await _frames(236)
	check(is_instance_valid(timid_w) and timid_w.healthy_level_at(timid_w.global_position) < 0.05, "a timid Wickling stays out of lantern light")
	check(not is_instance_valid(brave) or brave.hp < Tuning.wick_hp, "a brave one walks in, but burns after a while")
	check(is_instance_valid(elite_w) and elite_w.hp == Tuning.kl_elite_hp, "elites don't care about lanterns at all")
	# The old level-up cards stay in M1a: Kindled kills still pays charge on a kill (from any fire).
	Progress.combat_upgrades.append("kindled_kills")
	player.lamp_charge = 0.2
	var k := _w(spot + Vector2(50, 0))
	k.hurt(99.0, false, "lampfire")
	check(player.lamp_charge > 0.2 + Tuning.kl_kindled_kill_charge * 0.9, "the old cards still work (Kindled kills: a Lampfire kill gives charge back)")
	Progress.combat_upgrades.erase("kindled_kills")
	_clear()
	await _frames(2)
