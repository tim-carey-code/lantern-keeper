extends Node
## M1c fights (owner, M1b playtest; docs/replan/PLAN_LANTERNS.md §2.1, §8 item 3), and M2's Ashbrood (owner, M1c
## playtest: "phase 2 is still a bit boring and there definitely needs to be more moves"): phase 2's ash wave, low pass
## (cold embers) and calls, phase 3's combos and its ember window, and a faint during every boss attack in every
## phase (and the Clinker's roll) without an error (owner crash, hotfix d13d5b6):
##   - the damage fix: Wicklings chill in ticks with a cap on the whole swarm (3 Wicklings and no dodging: about
##     3-4 s to a faint), the Clinker's roll is the Hollow's hardest single hit and knocks back, foe damage grows by
##     level;
##   - the Ashbrood fights back: it starts a wind-up within a couple of seconds in each phase and never waits longer
##     than kl_ashbrood_idle_max in phase 1; phase-2 dives come often; it is hurt only when lit; the rim lamp; the
##     ember flare; the puff snuffs lamps; the dive smothers its lamp during the sit; no quest arrow during the fight.
## Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_fights.tscn

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
		await get_tree().physics_frame

func clear_foes() -> void:
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for s in get_tree().get_nodes_in_group("enemy_pack"):
		s.queue_free()
	for n in spawner.get_children():
		if n is SpitProjectile:
			n.queue_free()

func reset_keeper(at: Vector2) -> void:
	player.global_position = at
	player.reset_physics_interpolation()
	player.warmth = Tuning.warmth_max
	player.lamp_charge = 1.0
	player.combat.dash_t = 0.0
	player.hurt_t = 0.0
	player._knock_t = 0.0
	player.swarm_budget = Tuning.kl_swarm_chill_cap * Tuning.kl_swarm_chill_burst

func open_spot(from: Vector2) -> Vector2:
	var c := fog.tile_of(from)
	for r in 40:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := c + Vector2i(dx, dy)
				var ok := true
				for oy in range(-10, 11):
					for ox in range(-10, 11):
						var q := t + Vector2i(ox, oy)
						if not fog.in_bounds(q) or fog.solid[fog.idx(q)] == 1 or Progress.is_settled(fog.region[fog.idx(q)]):
							ok = false
							break
					if not ok:
						break
				if ok:
					return fog.tile_center(t)
	return from

func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	player = main.player
	spawner = main.get_node("FogLayer/Wicklings")
	fog = main.fog
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	clear_foes()
	spot = open_spot(main.start + Vector2(-700, 300))
	await wait(0.1)
	await _swarm_checks()
	await _clinker_checks()
	_level_checks()
	await _faint_timing_checks()
	await _ashbrood_checks()
	await _m2_moves()
	await _faint_every_attack()
	print("RESULT fails=%d" % fails)
	Art._ph.clear()
	get_tree().quit(1 if fails else 0)

## Wicklings on the keeper, chasing; seconds until the keeper faints (no dodging), or 99.
func _time_to_faint(n: int, level: int = 1) -> float:
	reset_keeper(spot)
	var ws: Array = []
	for i in n:
		var w := Wickling.new()
		w.level = level
		w.position = spot + Vector2.from_angle(TAU * i / n) * 6.0
		spawner.add_child(w)
		ws.append(w)
	await get_tree().process_frame
	for w in ws:
		w.state = Wickling.State.CHASE
		w.timid = false
	var faints0: int = player.faints
	var t := 0.0
	while player.faints == faints0 and t < 30.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		player.global_position = spot   # no dodging
		for w in ws:
			if is_instance_valid(w):
				w.state = Wickling.State.CHASE
				w.global_position = spot + (w.global_position - spot).limit_length(8.0)
	var reader = main.get_node("NoteReader")
	if reader.is_open():
		reader.close()
	Progress._input_block_until = 0
	clear_foes()
	await wait(0.1)
	return t if player.faints > faints0 else 99.0

func _swarm_checks() -> void:
	check(is_equal_approx(Tuning.kl_wick_chill_hit, 5.0) and is_equal_approx(Tuning.kl_wick_chill_tick, 0.5) and is_equal_approx(Tuning.kl_swarm_chill_cap, 28.0), "a touch chills 5 every 0.5 s; the swarm's cap is 28 a second")
	var one: float = await _time_to_faint(1)
	print("    one Wickling: %.1f s to a faint" % one)
	check(one > 8.0 and one < 13.0, "one Wickling on you: about 10 s to a faint, no dodging (%.1f s; was 3.3 s)" % one)
	var three: float = await _time_to_faint(3)
	print("    three Wicklings: %.1f s" % three)
	check(three >= 3.0 and three <= 4.5, "three Wicklings: about 3-4 s (%.1f s; was 1.1 s at 30/s each)" % three)
	var seven: float = await _time_to_faint(7)
	print("    seven Wicklings: %.1f s" % seven)
	check(seven >= 2.8 and seven <= 4.5, "seven: the cap holds the swarm near three's pace (%.1f s)" % seven)
	# The cap itself: over 3 s, 7 Wicklings take no more than the cap allows.
	reset_keeper(spot)
	player.warmth = 1000.0
	var ws: Array = []
	for i in 7:
		var w := Wickling.new()
		w.position = spot + Vector2.from_angle(TAU * i / 7) * 6.0
		spawner.add_child(w)
		ws.append(w)
	await get_tree().process_frame
	var t0: float = player.swarm_taken
	for f in 180:
		await get_tree().physics_frame
		player.global_position = spot
		for w in ws:
			if is_instance_valid(w):
				w.state = Wickling.State.CHASE
				w.timid = false
				w.global_position = spot + (w.global_position - spot).limit_length(8.0)
	var taken: float = player.swarm_taken - t0
	var most := Tuning.kl_swarm_chill_cap * (3.0 + Tuning.kl_swarm_chill_burst) + 1.0
	check(taken <= most and taken > 50.0, "over 3 s seven Wicklings take %.0f warmth: never past the cap (%.0f)" % [taken, most])
	# A dash: no chill.
	player.combat.dash_t = 1.0
	check(player.swarm_chill(5.0) == 0.0, "nothing chills mid-dash")
	player.combat.dash_t = 0.0
	clear_foes()
	await wait(0.1)

func _clinker_checks() -> void:
	reset_keeper(spot)
	var c := Clinker.new()
	c.position = spot + Vector2(120, 0)
	spawner.add_child(c)
	await wait(0.05)
	c.home = c.global_position
	var lv_hit := Tuning.kl_clinker_hit_warmth * c.dmg_level_mult()
	# The hardest single hits in the Hollow, each at its foe level (Spitwicks up to Lv 4, the Ashbrood Lv 5).
	var dm := func(lv: int) -> float: return 1.0 + Tuning.kl_foe_dmg_per_level * (lv - 1)
	var others := {
		"spit (Lv 4)": Tuning.kl_spit_warmth * dm.call(4),
		"Ashbrood dive": Tuning.kl_ashbrood_dive_warmth * dm.call(Tuning.kl_ashbrood_level),
		"Ashbrood puff": Tuning.kl_ashbrood_puff_warmth * dm.call(Tuning.kl_ashbrood_level),
		"Ashbrood sweep": Tuning.kl_ashbrood_sweep_warmth * dm.call(Tuning.kl_ashbrood_level),
		"Ashbrood ash bolt": Tuning.kl_ashbrood_bolt_warmth * dm.call(Tuning.kl_ashbrood_level),
		"an elite's touch tick (Lv 4)": Tuning.kl_wick_chill_hit * Tuning.kl_elite_chill_mult * dm.call(4),
	}
	var scariest := true
	for k in others:
		if others[k] >= lv_hit:
			scariest = false
	print("    the Clinker's roll: %.1f warmth; others: %s" % [lv_hit, str(others)])
	check(scariest, "the Clinker's roll (%.1f at Lv %d) is the hardest single hit in the Hollow" % [lv_hit, c.level])
	check(lv_hit >= 7.0 * Tuning.kl_wick_chill_hit, "and harder than 7 Wickling ticks (it was less than a couple of Wicklings)")
	# A real roll: it hits once and throws the keeper out of its lane.
	c.awake = true
	c._wake_t = 0.0
	c._cooldown = 0.0
	var w0: float = player.warmth
	var p0: Vector2 = player.global_position
	var knocked := false
	for f in 150:
		await get_tree().physics_frame
		if player.is_knocked():
			knocked = true
	var lost: float = w0 - player.warmth
	check(absf(lost - lv_hit) < 0.5, "the roll hits once for %.1f (%.1f)" % [lv_hit, lost])
	check(knocked and player.global_position.distance_to(p0) > Tuning.kl_clinker_knock * 0.5, "and throws the keeper %.0f px (moved %.0f px)" % [Tuning.kl_clinker_knock, player.global_position.distance_to(p0)])
	c.queue_free()
	reset_keeper(spot)
	await wait(0.1)

func _level_checks() -> void:
	check(is_equal_approx(Tuning.kl_foe_dmg_per_level, 0.08), "foe damage grows 8% a level (kl_foe_dmg_per_level, in the tuning panel)")
	var w := Wickling.new()
	w.level = 4
	check(is_equal_approx(w.dmg_level_mult(), 1.24) and is_equal_approx(w.touch_chill(), Tuning.kl_wick_chill_hit * 1.24), "a Lv 4 Wickling's touch tick is x1.24 (%.2f)" % w.touch_chill())
	w.level = 1
	check(is_equal_approx(w.dmg_level_mult(), 1.0), "a Lv 1 foe hits as before")
	w.free()
	var rows: Array = load("res://scripts/ui/debug_panel.gd").ROWS
	var names := rows.map(func(r): return r[0])
	var ok := true
	for k in ["kl_wick_chill_hit", "kl_wick_chill_tick", "kl_swarm_chill_cap", "kl_foe_dmg_per_level", "kl_clinker_knock", "kl_clinker_hit_warmth"]:
		if not names.has(k):
			ok = false
	check(ok, "every new damage number is in the tuning panel")

func _hollow() -> WayLamp:
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.id == "hollow":
			return w
	return null

func _rim() -> Lantern:
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.global_position.distance_to(main.rim_lamp_pos) < 8.0:
			return l
	return null

## Wind-up start times (seconds) over `secs`, with the keeper kept at `at` (warmth topped up).
func _watch(b: Ashbrood, secs: float, at: Vector2) -> Array:
	var starts: Array = []
	var last := b.attacks
	var t := 0.0
	while t < secs and is_instance_valid(b):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		player.global_position = at
		player.warmth = Tuning.warmth_max
		if b.attacks != last:
			last = b.attacks
			starts.append([t, b.last_attack])
	return starts

## Hotfix 2026-11-28 (owner crash in the Ashbrood fight): a faint resets every fight, so it must not run inside the
## attacker's own code (the dive's landing faulted when the faint cleared its dive mid-landing).
func _faint_timing_checks() -> void:
	reset_keeper(spot)
	await wait(0.05)
	var f0: int = player.faints
	player.warmth = 1.0
	player.chill(50.0)
	check(player.faints == f0, "a killing chill doesn't faint inside the attacker's code")
	player.chill(50.0)
	await get_tree().process_frame
	await get_tree().process_frame
	check(player.faints == f0 + 1, "it faints right after, once (%d)" % (player.faints - f0))
	reset_keeper(spot)
	await wait(0.05)

func _ashbrood_checks() -> void:
	var w := _hollow()
	var rim := _rim()
	check(rim != null and rim.old and rim.cold and not rim.can_pick_up(), "an old lamp stands on the rim of the Ashbrood's bowl, cold, lit by touch")
	var rd := rim.global_position.distance_to(w.global_position) if rim else 0.0
	check(rd > 150.0 and rd < 210.0 and rd < Tuning.lantern_max_radius - 20.0, "about %.0f px out (%.0f), so its light reaches the bowl" % [Tuning.kl_rim_lamp_dist, rd])
	check(not main.get_node("FogLayer/LanternMarkers").unlit_old_lamps().has(rim), "its cold-frame lure waits until the WayLamp has been read")
	# Wake it.
	Progress.notes_read["waylamp_hollow"] = true
	reset_keeper(w.global_position + Vector2(0, 30))
	w.start_kindling()
	var b := w.guardian()
	await wait(0.05)
	check(b != null and w.guardian_awake(), "the Ashbrood wakes")
	var gp = main.get_node("FogLayer/GoalPointer")
	var goal_was := Story.current
	var mode_was: String = Story.pointer_mode
	Story.current = "kindle_hollow"
	Story.pointer_mode = "on"
	check(gp.target_pos() == null, "no quest arrow at the fight (the ember is the only amber over the bowl)")
	player.global_position = w.global_position + Vector2(-(gp.HIDE_NEAR_FIGHT + 200.0), 0)
	check(gp.target_pos() != null and gp.target_pos().distance_to(w.global_position) < 1.0, "away from the fight (after a faint, say) the arrow shows the way back")
	player.global_position = w.global_position + Vector2(0, 30)
	Story.current = goal_was
	Story.pointer_mode = mode_was
	check(WayLamp.EMBER_BOWL == Ashbrood.EMBER_AT, "the WayLamp's ember lies in the bowl at its feet, on the sprite's own bowl ember: one ember")
	# In the dark (rim lamp cold, no lamps): every hit glances.
	b.shell = 0.0
	var h := b.hp
	b.hurt(20.0, false, "lance")
	check(is_equal_approx(b.hp, h) and b.dark_hint(), "in the dark it shrugs off fire")
	# Phase 1: it starts a wind-up within a couple of seconds, and never waits longer than kl_ashbrood_idle_max.
	var at := w.global_position + Vector2(0, 220)
	var starts: Array = await _watch(b, 20.0, at)
	var kinds := {}
	var gap := 0.0
	var prev := 0.0
	for s in starts:
		kinds[s[1]] = true
		gap = maxf(gap, s[0] - prev)
		prev = s[0]
	print("    phase 1: %d wind-ups in 20 s, %s, the longest wait %.1f s" % [starts.size(), str(kinds.keys()), gap])
	check(starts.size() > 0 and starts[0][0] <= 2.5, "phase 1: it attacks within 2.5 s (%.1f s)" % (starts[0][0] if starts.size() > 0 else 99.0))
	check(gap <= Tuning.kl_ashbrood_idle_max + 0.6, "and never waits more than about %.0f s between wind-ups (%.1f s)" % [Tuning.kl_ashbrood_idle_max, gap])
	check(kinds.has("bolts") and kinds.has("puff") and kinds.has("adds"), "ash bolts at you, the puff and the adds (%s)" % str(kinds.keys()))
	check(starts.size() >= 8, "about one a second or two (%d in 20 s)" % starts.size())
	for f in get_tree().get_nodes_in_group("wickling"):
		f.queue_free()
	# Its bolts: each has its aim marker, cold.
	b._bolt_t = 0.0
	b._idle_t = 99.0
	await wait(0.05)
	var tells: Array = b.bolt_tells()
	check(tells.size() == Tuning.kl_ashbrood_bolt_count and tells.all(func(t): return t.kind == Telegraph.AIM and t.hit), "ash bolts: %d aim markers (the marker is the hitbox)" % Tuning.kl_ashbrood_bolt_count)
	await wait(1.6)
	# Stand close: the wing sweep (a circle, a chill and a shove).
	reset_keeper(b.global_position + Vector2(0, Tuning.kl_ashbrood_sweep_radius - 20.0))
	b._sweep_cd = 0.0
	b._puff_t = 99.0
	for t in b.bolt_tells():
		t.finish()
	b._bolts.clear()
	var swept := false
	var shoved := false
	var w1: float = player.warmth
	for f in 120:
		await get_tree().physics_frame
		if b.sweep_tell():
			swept = true
		if player.is_knocked():
			shoved = true
		if not shoved:
			player.global_position = b.global_position + Vector2(0, Tuning.kl_ashbrood_sweep_radius - 20.0)
	check(swept, "close in, it sweeps its wings (a cold circle)")
	check(shoved and w1 - player.warmth >= Tuning.kl_ashbrood_sweep_warmth - 0.1, "which chills and shoves you (%.0f warmth)" % (w1 - player.warmth))
	# The rim lamp lights it; the puff snuffs lamps inside its circle.
	reset_keeper(rim.global_position + Vector2(0, 10))
	check(rim.light_by_touch(), "the rim lamp lights by touch")
	LightSense.bump()
	await wait(0.05)
	check(b.is_exposed(), "and its light reaches the bowl: the Ashbrood is exposed")
	h = b.hp
	b.shell = 0.0
	b.hurt(10.0, false, "lance")
	check(h - b.hp > 12.0, "now it is hurt, x1.3 (%.1f)" % (h - b.hp))
	var near_lamp := Lantern.new()
	near_lamp.kind = "post"
	near_lamp.position = w.global_position + Vector2(100, 0)
	main.get_node("Lanterns").add_child(near_lamp)
	b._puff_t = 0.0
	await wait(Tuning.kl_ashbrood_puff_tell + 0.6)
	check(near_lamp.is_snuffed() and rim.is_lit(), "its puff snuffs a lamp inside its circle for %.0f s; the rim lamp, outside it, burns on" % Tuning.kl_ashbrood_puff_snuff)
	# The ember: a Fireglobe in the bowl exposes it with no lamp at all.
	rim.cold = true
	near_lamp.queue_free()
	LightSense.bump()
	await wait(Tuning.kl_exposed_linger + 0.2)
	check(not b.is_exposed(), "with the rim lamp out it is dark again")
	FireBolts.inst.throw_globe(w.global_position + Vector2(0, 200), w.global_position + Vector2(10, 5))
	await wait(Tuning.kl_fireglobe_flight + 0.05)
	check(b.ember_stirred() and b.is_exposed(), "a Fireglobe in the bowl stirs the ember: it is exposed for %.0f s" % Tuning.kl_ember_flare_time)
	check(not b.ember_ready(), "at most once every %.0f s" % Tuning.kl_ember_flare_cd)
	await wait(Tuning.kl_ember_flare_time + Tuning.kl_exposed_linger + 0.1)
	check(not b.is_exposed(), "then the ember settles and it is dark again")
	# Phase 2.
	rim.cold = false
	LightSense.bump()
	b.shell = 0.0
	b.update_light_state(0.0)
	b.hurt(b.hp + 1.0, false, "lance")
	check(b.phase == 2 and b.in_phase_pause(), "breaking phase one: it rises out of the bowl")
	for f in get_tree().get_nodes_in_group("wickling"):
		f.queue_free()
	await wait(Tuning.kl_ashbrood_phase_pause + 0.05)
	var at2 := w.global_position + Vector2(0, 260)
	var starts2: Array = await _watch(b, 3.0, at2)
	check(starts2.size() > 0 and starts2[0][1] == "dive" and starts2[0][0] <= 2.5, "phase 2: it dives within 2.5 s (%s)" % str(starts2))
	# It dives at the lit rim lamp and smothers it during the sit (still lit), then the lamp goes out.
	var sat := false
	var lit_while_sat := true
	for f in 480:
		await get_tree().physics_frame
		player.global_position = at2
		player.warmth = Tuning.warmth_max
		if b.is_sitting():
			sat = true
			if b.smothered_lamp() == rim and not rim.is_lit():
				lit_while_sat = false
		elif sat:
			break
	check(sat and lit_while_sat, "it lands on the lit rim lamp and sits on it, smothering it: still lit (the window)")
	check(rim.is_snuffed(), "when the sit ends the lamp goes out for %.0f s" % Tuning.kl_snuff_sec)
	var dives: Array = await _watch(b, 20.0, at2)
	var n_dives := dives.filter(func(s): return s[1] == "dive").size()
	print("    phase 2: %d dives in 20 s (%s)" % [n_dives, str(dives)])
	check(n_dives >= 2, "phase 2's dives come often (%d in 20 s)" % n_dives)
	# Review fix: with only the rim lamp, a smother leaves it out for 8 s, so some dives find no lit lamp. Those dark
	# sits count as idle (it can't be hurt in the dark). Only a sit on a lit lamp (the punish window) doesn't.
	var idle := 0.0
	var longest := 0.0
	var dark0 := b.dark_sits
	for f in 60 * 40:
		await get_tree().physics_frame
		player.global_position = at2
		player.warmth = Tuning.warmth_max
		var active: bool = b.busy() or (b.is_sitting() and not b.is_dark_sitting())
		idle = 0.0 if active else idle + 1.0 / 60.0
		longest = maxf(longest, idle)
	print("    phase 2, rim lamp only, 40 s: %d dark sits, the longest wait %.1f s" % [b.dark_sits - dark0, longest])
	check(b.dark_sits > dark0, "with the rim lamp only, some dives find it still out (%d dark sits in 40 s)" % (b.dark_sits - dark0))
	check(longest <= Tuning.kl_ashbrood_idle_max + 0.6, "phase 2 never waits more than about 2 s, counting a dark sit as waiting (%.1f s; was 5.5 s)" % longest)
	check(main.get_node("FogLayer/GoalPointer").target_pos() == null, "still no quest arrow")
	b.queue_free()
	await wait(0.1)

# --- M2: the Ashbrood's new moves and phase 3 -----------------------------------------------------------------

## A fresh Ashbrood at the Hollow's WayLamp (the rim lamp lit), in `ph`, its rise over.
func _fresh_brood(ph: int) -> Ashbrood:
	var w := _hollow()
	for f in get_tree().get_nodes_in_group("foe"):
		if f is Ashbrood:
			f.queue_free()
	await wait(0.05)
	w.kindling = false
	Progress.notes_read["waylamp_hollow"] = true
	w.start_kindling()
	await wait(0.05)
	var b := w.guardian()
	var rim := _rim()
	rim.cold = false
	rim.snuff_t = 0.0
	LightSense.bump()
	b.phase = ph
	b.restart_phase()
	b._dive_t = 99.0          # nothing starts on its own until a check asks
	b._puff_t = 99.0
	b._bolt_t = 99.0
	b._wave_t = 99.0
	b._call_t = 99.0
	b._sweep_cd = 99.0
	b._idle_t = -999.0
	return b

func _m2_moves() -> void:
	var w := _hollow()
	var at := w.global_position + Vector2(0, 230)
	reset_keeper(at)
	var b: Ashbrood = await _fresh_brood(2)
	# The ash wave: a 60 px cold lane from it through you, the marker is the hitbox, a dash avoids it.
	b._start_move("wave", player)
	var wt := b.wave_tell()
	check(wt != null and wt.kind == Telegraph.LANE and wt.boss and wt.hit and is_equal_approx(wt.radius, Tuning.kl_ashbrood_ash_wave_half) and wt.radius * 2.0 <= 64.0 and wt.duration >= Tuning.kl_tell_min, "phase 2's ash wave: a %.0f px cold lane (no wider than 64), at least %.1f s of warning" % [wt.radius * 2.0 if wt else 0.0, Tuning.kl_tell_min])
	check(wt != null and wt.contains(player.global_position), "it runs through you")
	var w0: float = player.warmth
	while b.wave_tell() != null:
		await get_tree().physics_frame
		player.global_position = at
	check(w0 - player.warmth >= Tuning.kl_ashbrood_ash_wave_warmth - 0.1 and b.landed.get("wave", 0) == 1, "standing in its lane chills you (%.1f)" % (w0 - player.warmth))
	reset_keeper(at)
	b = await _fresh_brood(2)
	b._start_move("wave", player)
	w0 = player.warmth
	while b.wave_tell() != null:
		await get_tree().physics_frame
		player.global_position = at
		if b.wave_tell() and b.wave_tell().left() < 0.1:
			player.combat.dash_t = 0.3
	check(not b.landed.has("wave"), "a dash through it takes nothing (%s)" % str(b.landed))
	player.combat.dash_t = 0.0
	# The low pass: a lane past you, flown, leaving cold embers that chill only after their glow.
	reset_keeper(at)
	b = await _fresh_brood(2)
	var from: Vector2 = b.global_position
	b._start_move("strafe", player)
	var st := b.strafe_tell()
	check(st != null and st.kind == Telegraph.LANE and st.radius * 2.0 <= 64.0 and st.duration >= Tuning.kl_tell_min, "the low pass: a %.0f px cold lane with at least %.1f s of warning" % [st.radius * 2.0 if st else 0.0, Tuning.kl_tell_min])
	var lane_end := Vector2.ZERO
	var flew := 0
	while b.strafe_tell() != null or b.is_strafing():
		await get_tree().physics_frame
		player.global_position = at
		if b.strafe_tell() and b.strafe_tell().locked():
			lane_end = b.strafe_tell().to
		if b.is_strafing():
			flew += 1
	var embers := get_tree().get_nodes_in_group("cold_ember")
	check(flew >= int(Tuning.kl_ashbrood_strafe_travel * 60.0) - 2 and b.global_position.distance_to(lane_end) < 2.0 and b.global_position.distance_to(from) > 100.0, "it flies the locked lane over %.2f s (a visible pass, not a jump; %d frames)" % [Tuning.kl_ashbrood_strafe_travel, flew])
	check(embers.size() == Tuning.kl_ashbrood_strafe_embers, "and leaves %d cold embers on its path (%d)" % [Tuning.kl_ashbrood_strafe_embers, embers.size()])
	var e: ColdEmber = ColdEmber.new()
	e.position = at + Vector2(60, 0)
	spawner.add_child(e)
	reset_keeper(at + Vector2(60, 0))
	await get_tree().physics_frame
	w0 = player.warmth
	await wait(Tuning.kl_cold_ember_warm * 0.6)
	check(is_equal_approx(player.warmth, w0) and not e.armed(), "a new cold ember only glows at first (it can't hurt you yet)")
	await wait(Tuning.kl_cold_ember_warm + 0.6)
	check(player.warmth < w0 and e.chilled > 0.0, "then standing in it chills you (%.1f)" % (w0 - player.warmth))
	for n in get_tree().get_nodes_in_group("cold_ember"):
		n.queue_free()
	# Calls from the dark (spawn glows, then bold Wicklings).
	reset_keeper(at)
	for f in get_tree().get_nodes_in_group("wickling"):
		f.queue_free()
	await wait(0.05)
	b._call_t = 0.0
	await wait(0.05)
	var ct := b.call_tell()
	check(ct != null and ct.kind == Telegraph.SPAWN and ct.points.size() == Tuning.kl_ashbrood_call_count, "phase 2 calls Wicklings from the dark: %d cold spawn glows first" % Tuning.kl_ashbrood_call_count)
	await wait(Tuning.kl_ashbrood_add_tell + 0.2)
	check(get_tree().get_nodes_in_group("wickling").filter(func(x): return x.summoned).size() == Tuning.kl_ashbrood_call_count, "then they rise")
	for f in get_tree().get_nodes_in_group("wickling"):
		f.queue_free()
	# Variety: in phase 2 a dive, then a new move, then a dive; the new move after a dive differs from the last one.
	b = await _fresh_brood(2)
	b._dive_t = 0.0
	b._idle_t = 0.0
	b._call_t = 99.0
	var seq: Array = []
	var t := 0.0
	while t < 40.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		player.global_position = at
		player.warmth = Tuning.warmth_max
		if seq.size() < b.history.size():
			for h in b.history.slice(seq.size()):
				seq.append(h[1])
	var main_moves := seq.filter(func(m): return m in ["dive", "wave", "strafe"])
	var alternating := true
	for i in range(1, main_moves.size()):
		if main_moves[i] != "dive" and main_moves[i - 1] != "dive":
			alternating = false
		if main_moves[i] != "dive" and i >= 2 and main_moves[i - 2] == main_moves[i]:
			alternating = false
	print("    phase 2, 40 s: %s" % str(seq))
	check(main_moves.count("wave") >= 1 and main_moves.count("strafe") >= 1 and main_moves.count("dive") >= 3 and alternating, "phase 2 mixes dives with the wave and the pass, never the same new move twice running")
	# Phase 3: it returns to the bowl, where the ember lights it through its cracked wings (no lamp needed).
	var rim := _rim()
	b = await _fresh_brood(3)
	rim.cold = true
	LightSense.bump()
	b.global_position = w.global_position + Vector2(220, 0)
	b.update_light_state(0.0)
	check(not b.is_exposed(), "phase 3, away from the bowl with no lamp lit: it is dark")
	b._dive_t = 0.0
	b._idle_t = 0.0
	var first := ""
	var lit_in_bowl := false
	t = 0.0
	while t < 6.0:
		await get_tree().physics_frame
		t += 1.0 / 60.0
		player.global_position = at
		player.warmth = Tuning.warmth_max
		if first == "" and not b.history.is_empty():
			first = b.history[0][1]
		if b.is_sitting() and b.current_move() == "return" and b.is_exposed():
			lit_in_bowl = true
	check(first == "return" and lit_in_bowl, "phase 3 opens by settling over the last ember, which lights it: the window that needs no lamp (%s)" % first)
	var p3: Array = []
	t = 0.0
	b._idle_t = 0.0
	while t < 45.0 and is_instance_valid(b):
		await get_tree().physics_frame
		t += 1.0 / 60.0
		player.global_position = at
		player.warmth = Tuning.warmth_max
	for h in b.history:
		p3.append(h[1])
	print("    phase 3, about 50 s: %s" % str(p3))
	var combo_dw := false
	var combo_sb := false
	var combo_rp := false
	for i in range(1, p3.size()):
		if p3[i - 1] == "dive" and (p3[i] == "wave" or (p3[i] == "bolts" and i + 1 < p3.size() and p3[i + 1] == "wave")):
			combo_dw = true   # (a dive that lands with no lit lamp shakes off ash bolts first)
		if p3[i - 1] == "strafe" and p3[i] == "bolts":
			combo_sb = true
		if p3[i - 1] == "return" and p3[i] == "puff":
			combo_rp = true
	check(combo_dw and combo_sb and combo_rp, "phase 3 fights in combos: dive then wave, pass then bolts, the return then a puff")
	check(Tuning.kl_ashbrood_p3_mult < 1.0, "and faster: every wind-up x%.1f (never under the %.1f s minimum)" % [Tuning.kl_ashbrood_p3_mult, Tuning.kl_tell_min])
	rim.cold = false
	LightSense.bump()
	for f in get_tree().get_nodes_in_group("foe"):
		if f is Ashbrood or f is Wickling:
			f.queue_free()
	await wait(0.1)

## Owner crash (hotfix d13d5b6): a faint mid-fight resets the fight. Every attack of every phase (and the Clinker's
## roll) is made to land on a keeper with 1 warmth: the keeper faints once, right after, and nothing errors (the runner
## fails on any SCRIPT ERROR).
func _faint_every_attack() -> void:
	var w := _hollow()
	var at := w.global_position + Vector2(0, 230)
	var cases := [[1, "puff"], [1, "sweep"], [1, "bolts"], [1, "adds"], [2, "dive"], [2, "wave"], [2, "strafe"], [2, "ember"],
		[2, "call"], [2, "bolts"], [3, "return"], [3, "dive"], [3, "wave"], [3, "strafe"], [3, "bolts"], [3, "puff"]]
	var ok := 0
	for cs in cases:
		var ph: int = cs[0]
		var what: String = cs[1]
		reset_keeper(at)
		var b: Ashbrood = await _fresh_brood(ph)
		var f0: int = player.faints
		match what:
			"puff":
				if ph == 1:
					b._start_puff()
				else:
					b._start_move("puff", player)
			"sweep":
				b._start_sweep()
			"bolts":
				b._start_bolts(player)
			"adds":
				b._wave_t = 0.0
			"call":
				b._call_t = 0.0
			"ember":
				var e := ColdEmber.new()
				e.position = at
				e.age = Tuning.kl_cold_ember_warm
				spawner.add_child(e)
			_:
				b._start_move(what, player)
		var t := 0.0
		while player.faints == f0 and t < 8.0 and is_instance_valid(b):
			await get_tree().physics_frame
			t += 1.0 / 60.0
			# Stand where it will land.
			var spot_now := at
			if b.dive_tell():
				spot_now = b.dive_tell().center
			elif b.puff_tell() or b.sweep_tell():
				spot_now = b.global_position + Vector2(0, 30)
			elif what in ["adds", "call"]:
				var ws := get_tree().get_nodes_in_group("wickling").filter(func(x): return x.summoned and not x.is_fading_in())
				if not ws.is_empty():
					spot_now = ws[0].global_position
			if not player.is_knocked():
				player.global_position = spot_now
			player.warmth = minf(player.warmth, 1.0)
			player.swarm_budget = Tuning.kl_swarm_chill_cap * Tuning.kl_swarm_chill_burst
		await get_tree().process_frame
		var reader = main.get_node("NoteReader")
		if reader.is_open():
			reader.close()
		get_tree().paused = false
		Tuning.ui_open = false
		Progress._input_block_until = 0
		var fainted: bool = player.faints == f0 + 1
		var reset_ok: bool = is_instance_valid(b) and b.phase == ph and is_equal_approx(b.hp, b.phase_hp()) and not b.is_flying() and not b.is_strafing()
		if fainted and reset_ok:
			ok += 1
		else:
			print("    faint case phase %d %s: fainted %s, reset %s" % [ph, what, str(fainted), str(reset_ok)])
		for e in get_tree().get_nodes_in_group("cold_ember"):
			e.queue_free()
		for f in get_tree().get_nodes_in_group("wickling"):
			f.queue_free()
		await wait(0.05)
	check(ok == cases.size(), "a faint during every Ashbrood attack in every phase faints once and resets the phase, with no error (%d of %d)" % [ok, cases.size()])
	for f in get_tree().get_nodes_in_group("foe"):
		if f is Ashbrood:
			f.queue_free()
	await wait(0.1)
	# The Clinker's roll.
	reset_keeper(spot)
	var c := Clinker.new()
	c.position = spot + Vector2(120, 0)
	spawner.add_child(c)
	await wait(0.05)
	c.home = c.global_position
	c.awake = true
	c._wake_t = 0.0
	c._cooldown = 0.0
	var f1: int = player.faints
	for i in 240:
		await get_tree().physics_frame
		player.warmth = minf(player.warmth, 1.0)
		if player.faints > f1:
			break
	await get_tree().process_frame
	var reader2 = main.get_node("NoteReader")
	if reader2.is_open():
		reader2.close()
	get_tree().paused = false
	Tuning.ui_open = false
	check(player.faints == f1 + 1 and is_instance_valid(c), "a faint from the Clinker's roll: once, no error, the Clinker reset")
	c.queue_free()
	await wait(0.1)
