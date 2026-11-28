extends Node
## M1c (review): the Ashbrood killed for real with the default rules on (hurt only when lit, its full attack set,
## adds in the way). M2: three phases (phase 2's ash wave, low pass and calls; phase 3's combos and the ember window),
## each phase timed, every move seen, and "never idle more than about 2 s" in every phase. A scripted level-4 keeper (the beeline's level) stands about 190 px from the bowl and streams
## Lampfire at it, with Lance whenever it is ready; no dodging, warmth topped up so it never faints. Two fights:
##   - the rim lamp only: lit by touch, then the keeper just fights;
##   - Fireglobes only in phase 1: the rim lamp stays cold, and a Fireglobe goes into the bowl whenever the ember
##     can be stirred; phase 2 has no ember, so the keeper lights the rim lamp then (the no-scrap way through).
## The keeper never stops firing or dodges, so these times are shorter than a real fight (test_skills' sums model the
## real 2.5-3.5 minutes with the windows a dodging keeper gets).
## Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_ashbrood_kill.tscn

var main: Node
var fails := 0
var player: Node
var spawner: Node
var hollow: WayLamp
var rim: Lantern

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

func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	player = main.player
	spawner = main.get_node("FogLayer/Wicklings")
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.id == "hollow":
			hollow = w
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.global_position.distance_to(main.rim_lamp_pos) < 8.0:
			rim = l
	Progress.notes_read["waylamp_hollow"] = true
	Progress.level = 4
	Progress._grant_level_skills()
	InputHint.pad = true
	var a: Dictionary = await _fight(false)
	print("    rim lamp only: %.0f s (phase 1 %.0f s, phase 2 %.0f s, phase 3 %.0f s), %d dark sits, %d attacks; warmth it took %.0f" % [a.t, a.p1, a.p2 - a.p1, a.t - a.p2, a.dark_sits, a.attacks, a.taken])
	print("    moves: %s; the longest wait in each phase: %s" % [str(a.moves), str(a.idle)])
	check(a.won and a.p2 > a.p1 and a.p1 > 0.0, "with the rim lamp only, a level-4 keeper kills the Ashbrood through all three phases (%.0f s of constant fire)" % a.t)
	check(a.t < 300.0 and a.t > 60.0, "in a sensible time: 60-300 s of constant fire (%.0f s)" % a.t)
	_move_checks(a)
	_reset_world()
	await get_tree().process_frame
	await get_tree().process_frame
	var b: Dictionary = await _fight(true)
	print("    Fireglobes in phase 1: %.0f s (phase 1 %.0f s with %d ember stirs, phase 2 %.0f s by the rim lamp, phase 3 %.0f s)" % [b.t, b.p1, b.stirs, b.p2 - b.p1, b.t - b.p2])
	check(b.won and b.p1 > 0.0, "with only Fireglobes in the bowl, phase 1 can be won with no lamp lit (%.0f s, %d stirs), and the fight after it (%.0f s)" % [b.p1, b.stirs, b.t])
	check(b.p1 < 240.0, "in a sensible time (%.0f s)" % b.p1)
	_reset_world()
	await get_tree().process_frame
	await get_tree().process_frame
	var c: Dictionary = await _fight(false, true)
	print("    phase 3 with no lamp at all (the rim lamp out): %.0f s" % (c.t - c.p2))
	check(c.won, "phase 3 can be won with no lamp at all: the ember through its cracked wings is the window (no soft-lock) (%.0f s)" % (c.t - c.p2))
	Input.action_release("skill_1")
	print("RESULT fails=%d" % fails)
	Art._ph.clear()
	get_tree().quit(1 if fails else 0)

func _reset_world() -> void:
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	Progress.settled.erase(FogGrid.R_HOLLOW)
	Progress.cleared.erase("ashbrood_hollow")
	hollow.kindling = false
	hollow.ember_rise_t = 0.0
	rim.cold = true
	rim.snuff_t = 0.0
	LightSense.bump()

## M2: every move came up in its phase, consecutive moves differ in phase 2, and nothing waits past about 2 s.
func _move_checks(a: Dictionary) -> void:
	var m: Dictionary = a.moves
	check(m.get(1, {}).has("bolts") and m.get(1, {}).has("puff") and m.get(1, {}).has("adds"), "phase 1: ash bolts, the puff and the adds (%s)" % str(m.get(1, {}).keys()))
	check(m.get(2, {}).has("dive") and m.get(2, {}).has("wave") and m.get(2, {}).has("strafe") and m.get(2, {}).has("call"), "phase 2: dives, the ash wave, the low pass and calls from the dark (%s)" % str(m.get(2, {}).keys()))
	check(m.get(3, {}).has("return") and m.get(3, {}).has("dive") and m.get(3, {}).has("wave") and m.get(3, {}).has("strafe") and m.get(3, {}).has("bolts") and m.get(3, {}).has("puff"), "phase 3: the return to the ember and puff, dive and wave, pass and bolts (%s)" % str(m.get(3, {}).keys()))
	check(a.repeats == 0, "phase 2's new moves alternate with dives and never repeat back to back (%d repeats in %s)" % [a.repeats, str(a.p2_seq)])
	for ph in [1, 2, 3]:
		check(float(a.idle.get(ph, 99.0)) <= Tuning.kl_ashbrood_idle_max + 0.6, "phase %d never waits more than about %.0f s (a dark sit counts as waiting) (%.1f s)" % [ph, Tuning.kl_ashbrood_idle_max, a.idle.get(ph, 99.0)])

## One fight. globes: phase 1 by Fireglobes in the bowl (rim lamp cold); else the rim lamp from the start.
## dark3: in phase 3 the rim lamp is put out and kept out (the ember is the only window).
func _fight(globes: bool, dark3 := false) -> Dictionary:
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for p in get_tree().get_nodes_in_group("enemy_pack"):
		p.queue_free()
	await get_tree().process_frame
	var stand: Vector2 = hollow.global_position + Vector2(-120, 150)
	player.global_position = stand
	player.reset_physics_interpolation()
	if not globes:
		rim.light_by_touch()
	hollow.start_kindling()
	var b: Ashbrood = hollow.guardian()
	var out := {"won": false, "t": 0.0, "p1": 0.0, "p2": 0.0, "stirs": 0, "dark_sits": 0, "attacks": 0, "taken": 0.0,
		"moves": {}, "idle": {}, "repeats": 0, "p2_seq": []}
	var idle := 0.0
	var seen := 0
	var t := 0.0
	var dt := 1.0 / 60.0
	var stirs0: int = FireBolts.inst.embers
	Input.action_press("skill_1")
	while t < 400.0:
		await get_tree().physics_frame
		t += dt
		if not is_instance_valid(b) or b.is_queued_for_deletion():
			out.won = true
			break
		out.dark_sits = b.dark_sits
		out.attacks = b.attacks
		while seen < b.history.size():
			var h: Array = b.history[seen]
			seen += 1
			if not out.moves.has(h[0]):
				out.moves[h[0]] = {}
			out.moves[h[0]][h[1]] = int(out.moves[h[0]].get(h[1], 0)) + 1
			if h[0] == 2 and h[1] in ["dive", "wave", "strafe"]:
				var seq: Array = out.p2_seq
				if not seq.is_empty() and seq[-1] == h[1] and h[1] != "dive":
					out.repeats += 1
				if seq.size() >= 2 and h[1] != "dive" and seq[-2] == h[1]:
					out.repeats += 1   # the new move after a dive differs from the one before that dive
				seq.append(h[1])
		var active: bool = b.busy() or (b.is_sitting() and not b.is_dark_sitting()) or b.in_phase_pause()
		idle = 0.0 if active else idle + dt
		out.idle[b.phase] = maxf(float(out.idle.get(b.phase, 0.0)), idle)
		# The keeper: never faints, never levels mid-fight (the cards would pause the world), never dodges.
		out.taken += maxf(0.0, Tuning.warmth_max - player.warmth)
		player.warmth = Tuning.warmth_max
		Progress.wick = 0
		Progress._input_block_until = 0
		if get_tree().paused:
			get_tree().paused = false
			Tuning.ui_open = false
		if fmod(t, 8.0) < dt:
			for w in get_tree().get_nodes_in_group("wickling"):
				if w.summoned and not w._dead:
					w.hurt(999.0, false, "core")   # the keeper clears the adds now and then, as a player would
		if player.global_position.distance_to(stand) > 4.0 and not player.is_knocked():
			player.global_position = stand   # back to its spot after a shove
		var aim_at: Vector2 = b.global_position
		player.combat.aim_override = (aim_at - player.global_position).normalized()
		if b.phase == 2 and out.p1 <= 0.0:
			out.p1 = t
			if globes:
				rim.light_by_touch()   # no ember in phase 2: the rim lamp (no scrap) is the way through
		if b.phase == 3 and out.p2 <= 0.0:
			out.p2 = t
		if dark3 and b.phase == 3:
			rim.cold = true   # the rim lamp out for good: only the ember lights it now
			LightSense.bump()
		var fg: Skill = player.combat.skill("fireglobe")
		if globes and b.phase == 1 and b.ember_ready() and fg.can_fire():
			player.combat.aim_override = hollow.global_position - player.global_position   # its length is the reach
			fg.press()
		var lance: Skill = player.combat.skill("lance")
		if lance.can_fire() and player.lamp_charge > 0.3:
			lance.press()
	Input.action_release("skill_1")
	player.combat.aim_override = Vector2.ZERO
	out.t = t
	out.stirs = FireBolts.inst.embers - stirs0
	return out
