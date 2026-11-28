extends Node
## M2 elite affixes (GAME_PLAN §8.1; PLAN_LANTERNS §8 "Where parts 3 and 4 slot in"): Swift, Biting cold, Bursting,
## Thick shell, Lightless. One affix on each level-4 pack's elite in the Hollow (none below level 4); the affix line
## shows under its name; Lightless is never lit by lamps (only dim, by the hand lamp) and snuffs lamps it passes after
## a cold flicker; Bursting leaves spawn glows, then summoned Wicklings that a faint clears. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_affixes.tscn

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
	Tuning.wick_enabled = false
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

func elite(at: Vector2, affix: Array, lv := 4) -> Wickling:
	var w := Wickling.new()
	w.elite = true
	w.level = lv
	w.affixes.assign(affix)
	w.position = at
	spawner.add_child(w)
	return w

func _run() -> void:
	await wait(0.05)
	player = main.player
	spawner = main.get_node("FogLayer/Wicklings")
	fog = main.fog
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	spot = main.start + Vector2(-700, 300)
	# The Hollow's packs: one affix on each level-4 elite, none below level 4.
	var packs := get_tree().get_nodes_in_group("enemy_pack")
	var with_affix := packs.filter(func(p): return not p.affixes.is_empty())
	var all := {}
	for p in with_affix:
		for a in p.affixes:
			all[a] = true
	check(with_affix.size() == 4 and with_affix.all(func(p): return p.level >= Tuning.kl_affix_min_level and p.elites > 0 and p.affixes.size() == 1), "the Hollow's four level-4 elite packs each carry one affix (%d)" % with_affix.size())
	check(all.has("swift") and all.has("thick") and all.has("bursting") and all.has("lightless"), "Swift, Thick shell, Bursting and Lightless all appear in the Hollow (%s)" % str(all.keys()))
	var p1: EnemyPack = with_affix[0]
	player.global_position = p1.global_position
	player.reset_physics_interpolation()
	await wait(0.1)
	var woke := get_tree().get_nodes_in_group("wickling").filter(func(w): return w.pack_id == p1.id and w.elite)
	check(woke.size() >= 1 and woke[0].affixes == p1.affixes, "a woken elite takes its pack's affix (%s)" % (str(woke[0].affixes) if woke.size() > 0 else "none"))
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for p in packs:
		p.queue_free()
	player.global_position = spot + Vector2(0, 600)
	await wait(0.1)
	# The affix line.
	var s := elite(spot, ["swift"])
	var plain := elite(spot + Vector2(80, 0), [])
	await wait(0.05)
	check(s.affix_line() == "Swift" and plain.affix_line() == "", "the affix line under its name: \"%s\"" % s.affix_line())
	var two := elite(spot + Vector2(-80, 0), ["swift", "lightless"])
	check(two.affix_line() == "Swift · Lightless", "two affixes (from the marsh on) on one line: \"%s\"" % two.affix_line())
	# Swift.
	check(is_equal_approx(s.speed_mult(), Tuning.kl_affix_swift) and is_equal_approx(plain.speed_mult(), 1.0), "Swift: x%.1f speed" % Tuning.kl_affix_swift)
	# Biting cold.
	var bc := elite(spot + Vector2(0, 80), ["biting"])
	check(is_equal_approx(bc.touch_chill(), plain.touch_chill() * Tuning.kl_affix_biting), "Biting cold: its touch chills x%.1f (%.1f vs %.1f)" % [Tuning.kl_affix_biting, bc.touch_chill(), plain.touch_chill()])
	# Thick shell.
	var th := elite(spot + Vector2(0, -80), ["thick"])
	await wait(0.05)
	check(is_equal_approx(th.shell_max, plain.shell_max * Tuning.kl_affix_thick), "Thick shell: x%.0f shell (%.1f vs %.1f)" % [Tuning.kl_affix_thick, th.shell_max, plain.shell_max])
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	await wait(0.05)
	# Lightless: a lamp's light never lights it; the hand lamp makes it dim; it snuffs lamps it passes after a flicker.
	var lamp := Lantern.new()
	lamp.kind = "post"
	lamp.position = spot
	main.get_node("Lanterns").add_child(lamp)
	LightSense.bump()
	var normal := elite(spot + Vector2(60, 0), [])
	var dark := elite(spot + Vector2(70, 10), ["lightless"])
	normal.set_process(false)
	dark.set_process(false)
	await wait(0.05)
	normal.update_light_state(0.0)
	dark.update_light_state(0.0)
	check(normal.is_exposed() and not dark.is_exposed() and dark.lightless, "Lightless: in a lamp's light a plain elite is lit; a Lightless one is not")
	player.global_position = dark.global_position + Vector2(20, 0)
	player.reset_physics_interpolation()
	dark.update_light_state(0.0)
	check(dark.light_state == Foe.DIM, "only the keeper's hand lamp exposes it a little (dim)")
	check(lamp.is_lit(), "the lamp is lit")
	dark.global_position = lamp.global_position + Vector2(20, 0)
	dark.set_process(true)
	dark.stun(99.0)
	await wait(Tuning.kl_lightless_tell * 0.5)
	check(lamp.is_lit() and lamp.threatened > 0.0, "a lamp it comes near flickers cold first (%.1f s), still lit" % Tuning.kl_lightless_tell)
	await wait(Tuning.kl_lightless_tell)
	check(lamp.is_snuffed() and dark.doused == 1, "then it is snuffed for %.0f s" % Tuning.kl_lightless_snuff)
	# Review fix: a lamp that goes out during the flicker (a puff, a pick-up) loses its countdown; when it relights
	# later, with the Lightless elite far off, it stays lit.
	lamp.snuff_t = 0.0
	LightSense.bump()
	await wait(0.05)
	check(lamp.is_lit(), "the lamp relights")
	await wait(Tuning.kl_lightless_tell * 0.5)
	check(dark._dousing.has(lamp.get_instance_id()), "a new flicker starts")
	lamp.snuff(1.0)   # out mid-flicker (as a puff would)
	dark.global_position = lamp.global_position + Vector2(400, 0)
	await wait(0.1)
	check(not dark._dousing.has(lamp.get_instance_id()), "its countdown is dropped when the lamp goes out")
	lamp.snuff_t = 0.0
	LightSense.bump()
	await wait(Tuning.kl_lightless_tell + 0.3)
	check(lamp.is_lit() and dark.doused == 1, "relit far from the elite, it stays lit")
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	lamp.queue_free()
	await wait(0.1)
	# Bursting: spawn glows as it dies, then summoned Wicklings (no drops), cleared by a faint.
	player.global_position = spot + Vector2(0, 600)
	var bu := elite(spot, ["bursting"])
	bu.set_process(false)
	await wait(0.05)
	bu.shell = 0.0
	bu.hurt(999.0, false, "lance")
	await get_tree().process_frame
	var hatches := get_tree().get_nodes_in_group("burst_hatch")
	check(hatches.size() == 1 and hatches[0].tell() != null and hatches[0].tell().kind == Telegraph.SPAWN and hatches[0].tell().points.size() == Tuning.kl_affix_bursting, "Bursting: as it dies, %d cold spawn glows" % Tuning.kl_affix_bursting)
	check(get_tree().get_nodes_in_group("wickling").filter(func(w): return not w._dead and not w.is_queued_for_deletion()).is_empty(), "nothing rises at once")
	await wait(Tuning.kl_affix_burst_tell + 0.1)
	var kids := get_tree().get_nodes_in_group("wickling").filter(func(w): return not w._dead and not w.is_queued_for_deletion())
	check(kids.size() == Tuning.kl_affix_bursting and kids.all(func(w): return w.summoned and w.level == 4), "then %d summoned Wicklings rise (they drop nothing)" % Tuning.kl_affix_bursting)
	var bu2 := elite(spot + Vector2(200, 0), ["bursting"])
	bu2.set_process(false)
	await wait(0.05)
	bu2.shell = 0.0
	bu2.hurt(999.0, false, "lance")
	await get_tree().process_frame
	FaintRule.reset_fights(get_tree())
	await wait(Tuning.kl_affix_burst_tell + 0.1)
	var left := get_tree().get_nodes_in_group("wickling").filter(func(w): return not w._dead and not w.is_queued_for_deletion())
	check(left.is_empty() and get_tree().get_nodes_in_group("burst_hatch").is_empty(), "a faint clears its hatch and hatchlings")
	# The bar draws the line (no error), and the numbers are in the tuning panel.
	var bars = main.get_node("FogLayer/FoeBars")
	var shown := elite(player.global_position + Vector2(40, 0), ["thick"])
	shown.hurt(0.5, false, "lance")
	bars.queue_redraw()
	await wait(0.05)
	check(bars.wants_bar(shown, player), "a hurt elite shows its bar, name and affix line")
	var rows := {}
	for r in load("res://scripts/ui/debug_panel.gd").ROWS:
		rows[r[0]] = true
	check(["kl_affix_min_level", "kl_affix_swift", "kl_affix_biting", "kl_affix_bursting", "kl_affix_burst_tell", "kl_affix_thick", "kl_lightless_snuff", "kl_lightless_reach", "kl_lightless_tell"].all(func(k): return rows.has(k)), "every affix number is in the tuning panel")
	check(Tuning.kl_affix_burst_tell >= Tuning.kl_tell_min - 0.11, "the burst's glow is at least the 0.5 s spawn-glow minimum (%.1f s)" % Tuning.kl_affix_burst_tell)
	print("RESULT fails=%d" % fails)
	Art._ph.clear()
	get_tree().quit(1 if fails else 0)
