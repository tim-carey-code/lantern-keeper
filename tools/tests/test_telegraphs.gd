extends Node
## The readability step: the shared telegraph system and the fairness rules (docs/ART_DIRECTION.md §4.4), every
## built foe attack in §4.3, the keeper's own feedback, and the placeholder swap hook (§6.4). Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_telegraphs.tscn

var main: Node
var fails := 0
var player: Node2D
var spawner: Node
var spot := Vector2.ZERO     # open, dark ground where the keeper stands for these checks
var _arrow_checks := 0
var _arrow_missing := 0

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
	# M1c: this test predates the light states and lamp slots (test_light_states, test_combos and test_core's slot
	# checks cover those). The light rule and the slot limit are off here, so its sums stay as they were.
	Tuning.kl_dark_dmg_mult = 1.0
	Tuning.kl_lit_dmg_mult = 1.0
	Tuning.kl_lit_shell_mult = 1.0
	Tuning.kl_dark_shell_floor = 0.0
	Tuning.kl_ashbrood_needs_light = false
	Tuning.kl_lamp_slots_base = 6
	Tuning.kl_lamp_replant_cd = 0.0
	SaveGame.path = "user://test_ignore_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	Settings.path = "user://test_ignore_settings.cfg"
	Settings.use_defaults()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	_run()

## Waits this many seconds of game time (60 frames a second), checking the edge-arrow rule every frame.
func wait(sec: float) -> void:
	for i in maxi(1, roundi(sec * 60.0)):
		await get_tree().process_frame
		_check_arrows()

## Rule 5: every hit's wind-up is on screen, or has an edge arrow (counted; reported once at the end).
func _check_arrows() -> void:
	var view := Telegraph.view_rect(player)
	for t in Telegraph.active:
		if not t.alive or not t.hit:
			continue
		var owner := instance_from_id(t.owner_id) as Node2D if is_instance_id_valid(t.owner_id) else null
		var all_on := view.has_point(t.focus()) and (owner == null or view.has_point(owner.global_position))
		_arrow_checks += 1
		if not all_on and t.focus().distance_to(player.global_position) <= Tuning.kl_tell_arrow_range and Telegraph.arrow_for(t, view, player.global_position).is_empty():
			_arrow_missing += 1

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

## Keeps the keeper still but "dashing" (no move: dash_dir zero), so the dash's protection alone is tested.
func hold_dash(sec: float) -> void:
	player.combat.dash_dir = Vector2.ZERO
	player.combat.dash_t = sec

func add_foe(f: Node2D, at: Vector2) -> Node2D:
	f.position = at
	spawner.add_child(f)
	return f

func _run() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	player = main.player
	spawner = main.get_node("FogLayer/Wicklings")
	main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.old:
			l.cold = true   # every lamp dark: no light to hide in, nothing for a dive to aim at
		else:
			l.snuff(9999.0)
	LightSense.bump()
	clear_foes()
	spot = main.start + Vector2(-480, 0)
	reset_keeper(spot)
	await wait(0.1)
	_table_checks()
	await _puff_checks()
	await _adds_and_phase_checks()
	await _dive_checks()
	await _clinker_checks()
	await _spit_checks()
	await _gap_checks()
	await _nest_checks()
	await _wickling_checks()
	_reduce_flash_checks()
	await _keeper_checks()
	await _m1c_checks()
	await _swap_checks()
	check(_arrow_checks > 100 and _arrow_missing == 0, "no hit winds up off-screen without an edge arrow (%d frames of wind-ups checked, %d without)" % [_arrow_checks, _arrow_missing])
	print("RESULT fails=%d" % fails)
	get_tree().quit(1 if fails > 0 else 0)

# --- The table (rules 1 and 12) and the tuning rows -------------------------------------------------------------

func _table_checks() -> void:
	for name in ["kl_spit_tell", "kl_clinker_roll_tell", "kl_ashbrood_puff_tell", "kl_ashbrood_dive_tell"]:
		check(float(Tuning.get(name)) >= Tuning.kl_tell_min, "%s (%.2f s) gives at least the %.2f s minimum warning" % [name, Tuning.get(name), Tuning.kl_tell_min])
	var t := Telegraph.begin(player, Telegraph.CIRCLE, "test", 0.1)
	check(is_equal_approx(t.duration, Tuning.kl_tell_min), "a hit asked to wind up for 0.1 s still gets %.2f s" % Tuning.kl_tell_min)
	t.finish()
	var rows := {}
	for r in load("res://scripts/ui/debug_panel.gd").ROWS:
		rows[r[0]] = true
	var timings := ["kl_tell_min", "kl_tell_commit", "kl_tell_commit_boss", "kl_notice_time", "kl_tell_gap", "kl_wick_latch_tell",
		"kl_elite_latch_tell", "kl_spit_tell", "kl_spit_aim_lock", "kl_nest_hatch_tell", "kl_hatch_fade", "kl_clinker_wake_time",
		"kl_clinker_roll_tell", "kl_clinker_recover", "kl_ashbrood_puff_tell", "kl_ashbrood_add_tell", "kl_ashbrood_dive_tell",
		"kl_ashbrood_dive_travel", "kl_ashbrood_sit_sec", "kl_ashbrood_phase_pause"]
	var missing := timings.filter(func(n): return not rows.has(n) or Tuning.get(n) == null)
	check(missing.is_empty(), "every telegraph timing is a kl_* tuning value with an F1 row (missing: %s)" % str(missing))
	check(Telegraph.COLD.to_html(false) == "a3bcd4", "foe markers use the cold threat colour #a3bcd4")
	var warm := false
	for slot in [false, true]:
		var s := Telegraph.Tell.new()
		s.duration = 1.0
		for i in 20:
			s.t = i * 0.05
			var c: Color = Telegraph.style(s, slot)["color"]
			warm = warm or c.r > c.b + 0.01
	check(not warm, "no telegraph colour is warm (never amber), with or without reduce flashes")

# --- The Ashbrood --------------------------------------------------------------------------------------------

func _new_boss(at: Vector2) -> Ashbrood:
	var b := Ashbrood.new()
	b._puff_t = 99.0
	b._wave_t = 99.0
	b._dive_t = 99.0
	add_foe(b, at)
	return b

## One puff with the keeper at `off` px from the boss; returns [warmth lost, charge after].
func _one_puff(off: float, dashing: bool) -> Array:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	var b := _new_boss(spot + Vector2(-off, 0))
	await wait(0.05)
	b._puff_t = 0.0
	await wait(0.05)
	var t := b.puff_tell()
	var sizes_ok := t != null and is_equal_approx(t.radius, Tuning.kl_ashbrood_puff_radius)
	var first_ok := t != null and t.t < 0.1   # full size from its first frame
	while t != null and t.alive and not t.done():
		if t.left() < 0.1 and dashing and player.combat.dash_t <= 0.0:
			hold_dash(0.3)
		await wait(1.0 / 60.0)
		sizes_ok = sizes_ok and is_equal_approx(t.radius, Tuning.kl_ashbrood_puff_radius)
	await wait(0.05)
	var lost: float = Tuning.warmth_max - player.warmth
	var charge: float = player.lamp_charge
	b.queue_free()
	return [lost, charge, sizes_ok and first_ok]

func _puff_checks() -> void:
	var r := Tuning.kl_ashbrood_puff_radius
	var inside: Array = await _one_puff(r - 3.0, false)
	check(inside[2], "the ash puff's circle is its full %.0f px from the first frame of the wind-up" % r)
	check(inside[0] >= Tuning.kl_ashbrood_puff_warmth - 0.1 and inside[1] <= Tuning.kl_ashbrood_puff_charge + 0.01, "3 px inside the puff's marker: it chills you and drops your charge")
	var outside: Array = await _one_puff(r + 3.0, false)
	check(outside[0] < 0.1 and outside[1] > 0.9, "3 px outside the marker: nothing (the marker is the hitbox)")
	var dashed: Array = await _one_puff(r - 30.0, true)
	check(dashed[0] < 0.1 and dashed[1] > 0.9, "a dash through the puff avoids its chill and its charge drain (it used to drain a dashing keeper)")

func _adds_and_phase_checks() -> void:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	var b := _new_boss(spot + Vector2(-200, 0))
	await wait(0.05)
	var before := get_tree().get_nodes_in_group("wickling").size()
	b._wave_t = 0.0
	await wait(0.05)
	var t := b.adds_tell()
	check(t != null and t.kind == Telegraph.SPAWN and t.points.size() == Tuning.kl_ashbrood_wave_count, "the Ashbrood's call shows a cold glow where each add will rise")
	await wait(Tuning.kl_ashbrood_add_tell * 0.6)
	check(get_tree().get_nodes_in_group("wickling").size() == before, "no add appears before the warning ends")
	await wait(Tuning.kl_ashbrood_add_tell * 0.4 + 0.05)
	var adds := get_tree().get_nodes_in_group("wickling").filter(func(w): return w.summoned and not w.is_queued_for_deletion())
	check(adds.size() == Tuning.kl_ashbrood_wave_count and adds.all(func(w): return w.is_fading_in()), "after %.1f s its %d adds rise, fading in" % [Tuning.kl_ashbrood_add_tell, adds.size()])
	for w in adds:
		w.queue_free()
	# The phase change: a rise out of the bowl; no attacks, no damage.
	b.shell = 0.0
	b.hurt(b.hp + 1.0, false, "lance")   # (M1b: a phase's health grows with its level)
	check(b.phase == 2 and b.in_phase_pause(), "breaking phase one starts the rise out of the bowl (the boss bar shows phase 2)")
	var hp_now := b.hp
	b.hurt(50.0, false, "lance")
	check(is_equal_approx(b.hp, hp_now), "it can't be hurt while it rises")
	b._dive_t = 0.0
	await wait(Tuning.kl_ashbrood_phase_pause * 0.8)
	check(b.in_phase_pause() and b.dive_tell() == null, "and it can't attack while it rises")
	await wait(Tuning.kl_ashbrood_phase_pause * 0.2 + 0.1)
	check(not b.in_phase_pause(), "after %.1f s the second phase begins" % Tuning.kl_ashbrood_phase_pause)
	b.queue_free()

## One dive at a lamp; the keeper at `keeper_off` from the landing point.
func _one_dive(lamp_at: Vector2, keeper_off: Vector2, dashing: bool) -> Dictionary:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	var lamp := Lantern.new()
	lamp.kind = "post"
	lamp.position = lamp_at
	main.get_node("Lanterns").add_child(lamp)
	var b := _new_boss(spot + Vector2(-260, -60))
	b.phase = 2
	await wait(0.05)
	var land := lamp_at + Vector2(0, -12)
	reset_keeper(land + keeper_off)
	await wait(0.05)
	b._dive_t = 0.0
	await wait(0.05)
	var out := {}
	var t := b.dive_tell()
	out["radius_ok"] = t != null and is_equal_approx(t.radius, Tuning.kl_ashbrood_hit_radius) and t.center.distance_to(land) < 0.5
	var view := Telegraph.view_rect(player)
	out["arrow"] = t != null and not Telegraph.arrow_for(t, view, player.global_position).is_empty()
	var start := b.global_position
	while t != null and t.alive and not t.done():
		await wait(1.0 / 60.0)
	if dashing:
		hold_dash(Tuning.kl_ashbrood_dive_travel + 0.2)
	await wait(Tuning.kl_ashbrood_dive_travel * 0.5)
	out["flying"] = b.is_flying() and b.global_position.distance_to(start) > 5.0 and b.global_position.distance_to(land) > 5.0
	await wait(Tuning.kl_ashbrood_dive_travel * 0.5 + 0.1)
	# M1c: it smothers the lamp while it sits (still lit: the punish window); the lamp goes out when the sit ends.
	out["landed"] = b.global_position.distance_to(land) < 1.0 and lamp.smother_by == b and lamp.is_lit() and b.is_sitting()
	out["lost"] = Tuning.warmth_max - player.warmth
	b.queue_free()
	lamp.queue_free()
	return out

func _dive_checks() -> void:
	var r := Tuning.kl_ashbrood_hit_radius
	var near: Dictionary = await _one_dive(spot + Vector2(60, 0), Vector2(r - 3.0, 0), false)
	check(near["radius_ok"], "the dive shows one landing circle at the lamp, the same %.0f px it hits with" % r)
	check(near["flying"], "the dive is a visible flight, not a jump")
	check(near["landed"], "it lands on the lamp and sits on it, smothering it (still lit: hit it now)")
	check(near["lost"] >= Tuning.kl_ashbrood_dive_warmth - 0.1, "3 px inside the landing circle: it chills you")
	var edge: Dictionary = await _one_dive(spot + Vector2(60, 0), Vector2(r + 3.0, 0), false)
	check(edge["lost"] < 0.1, "3 px outside it: nothing")
	var dash: Dictionary = await _one_dive(spot + Vector2(60, 0), Vector2(r * 0.5, 0), true)
	check(dash["lost"] < 0.1, "a dash as it lands avoids the hit")
	var far: Dictionary = await _one_dive(spot + Vector2(780, 0), Vector2(-780 + 10.0, 12.0), false)
	check(far["arrow"], "a dive at an off-screen lamp shows an edge arrow")
	# No lamp lit: it dives at the keeper, and its circle sits at the end of its 200 px dive.
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	var b := _new_boss(spot + Vector2(-300, 0))
	b.phase = 2
	await wait(0.05)
	b._dive_t = 0.0
	await wait(0.05)
	var t := b.dive_tell()
	check(t != null and absf(t.center.distance_to(b.global_position) - Tuning.kl_ashbrood_dive_dist) < 1.0 and is_equal_approx(t.radius, r), "with no lamp lit the circle sits at the dive's end, %.0f px out (the old line ran 240)" % Tuning.kl_ashbrood_dive_dist)
	b.queue_free()

# --- The Clinker ---------------------------------------------------------------------------------------------

func _new_clinker(at: Vector2) -> Clinker:
	var c := Clinker.new()
	add_foe(c, at)
	return c

## One roll; the keeper moved `side` px off the lane's middle once the roll's direction is set.
func _one_roll(side: float, dashing: bool) -> Dictionary:
	clear_foes()
	Progress.cleared.erase("clinker_hollow_post")
	await wait(0.05)
	reset_keeper(spot)
	var c := _new_clinker(spot + Vector2(-150, 0))
	await wait(0.05)
	var out := {"woke": c.awake and c.is_waking()}
	await wait(Tuning.kl_clinker_wake_time * 0.8)
	out["no_roll_while_waking"] = c.tell() == null
	c._cooldown = 0.0
	var waited := 0.0
	while c.tell() == null and waited < 2.0:
		await wait(1.0 / 60.0)
		waited += 1.0 / 60.0
	var t := c.tell()
	out["lane"] = t != null and is_equal_approx(t.radius, Tuning.kl_clinker_hit_range) and absf(t.center.distance_to(t.to) - Tuning.kl_clinker_roll_dist) < 0.5
	out["tell_len"] = t.duration if t else 0.0
	reset_keeper(spot + Vector2(0, side))
	while t != null and t.alive and not t.done():
		await wait(1.0 / 60.0)
	if dashing:
		hold_dash(Tuning.kl_clinker_roll_dist / Tuning.kl_clinker_roll_speed + 0.2)
	await wait(Tuning.kl_clinker_roll_dist / Tuning.kl_clinker_roll_speed + 0.05)
	out["lost"] = Tuning.warmth_max - player.warmth
	out["dizzy"] = c.is_dizzy()
	var p0 := c.global_position
	await wait(Tuning.kl_clinker_recover * 0.6)
	out["still"] = c.global_position.distance_to(p0) < 0.5 and c.tell() == null
	c.queue_free()
	return out

func _clinker_checks() -> void:
	var hw := Tuning.kl_clinker_hit_range
	var a: Dictionary = await _one_roll(hw - 3.0, false)
	check(a["woke"] and a["no_roll_while_waking"], "the Clinker uncurls for %.1f s when it wakes, and can't roll until it is done" % Tuning.kl_clinker_wake_time)
	check(a["lane"], "its roll shows a full-width lane (%.0f px wide) to the roll's end" % (hw * 2.0))
	check(a["tell_len"] >= Tuning.kl_clinker_roll_tell - 0.001, "the lane shows for %.1f s" % a["tell_len"])
	check(a["lost"] >= Tuning.kl_clinker_hit_warmth - 0.1, "3 px inside the lane's edge: the roll hits")
	check(a["dizzy"] and a["still"], "after the roll it is dizzy for %.1f s: no move, no roll" % Tuning.kl_clinker_recover)
	var b: Dictionary = await _one_roll(hw + 3.0, false)
	check(b["lost"] < 0.1, "3 px outside the lane: it misses (the lane is the hitbox)")
	var d: Dictionary = await _one_roll(0.0, true)
	check(d["lost"] < 0.1, "a dash avoids the roll")

# --- The Spitwick --------------------------------------------------------------------------------------------

func _spit_checks() -> void:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	await wait(0.05)
	var s: Spitwick = add_foe(Spitwick.new(), spot + Vector2(-220, 0))
	s._shot_t = 0.0
	var opened: int = Sfx.plays.get("ui_open", 0)
	await wait(0.05)
	var t := s.tell()
	check(t != null and t.kind == Telegraph.AIM and is_equal_approx(t.radius, Tuning.kl_spit_hit_radius + Telegraph.KEEPER_RADIUS), "the Spitwick's aim marker is as wide as its spit reaches")
	check(Sfx.plays.get("ui_open", 0) > opened, "its wind-up sound slot plays (a reused Kenney stand-in)")
	check(t != null and is_equal_approx(t.duration, Tuning.kl_spit_tell), "it winds up for %.1f s" % Tuning.kl_spit_tell)
	# The aim follows you, then locks for the last kl_spit_aim_lock seconds.
	reset_keeper(spot + Vector2(0, 30))
	await wait(0.1)
	check(t.to.distance_to(player.global_position) < 6.0, "until it locks, the aim follows you")
	while not t.locked():
		await wait(1.0 / 60.0)
	check(t.left() <= Tuning.kl_spit_aim_lock + 0.02 and t.left() >= Tuning.kl_spit_aim_lock - 0.04, "it locks %.2f s before the spit" % t.left())
	var locked_at := t.to
	var dir := (locked_at - t.center).normalized()
	var side := dir.orthogonal() * (t.radius - 3.0)
	reset_keeper(locked_at + side)
	await wait(0.05)
	check(t.to.distance_to(locked_at) < 0.01, "after it locks, the aim stays put")
	await wait(1.8)
	check(Tuning.warmth_max - player.warmth >= Tuning.kl_spit_warmth - 0.1, "3 px inside the marker's edge: the spit hits")
	# Again, 3 px outside.
	reset_keeper(spot)
	s._shot_t = 0.0
	s._tell = null
	await wait(0.05)
	t = s.tell()
	while t != null and not t.locked():
		await wait(1.0 / 60.0)
	if t:
		reset_keeper(t.to + (t.to - t.center).normalized().orthogonal() * (t.radius + 3.0))
	await wait(t.left() + 1.8 if t else 1.8)
	check(player.warmth > Tuning.warmth_max - 0.1, "3 px outside it: the spit misses")
	# Dashing as it arrives.
	reset_keeper(spot)
	s._shot_t = 0.0
	await wait(0.05)
	t = s.tell()
	while t != null and not t.done():
		await wait(1.0 / 60.0)
	hold_dash(2.0)
	await wait(1.8)
	check(player.warmth > Tuning.warmth_max - 0.1, "a dash avoids the spit")
	player.combat.dash_t = 0.0
	s.queue_free()
	# Off-screen it never starts a wind-up: it creeps closer first.
	await wait(0.05)
	var off: Spitwick = add_foe(Spitwick.new(), spot + Vector2(0, 460))
	off._shot_t = 0.0
	var d0 := off.global_position.distance_to(player.global_position)
	await wait(0.3)
	check(off.tell() == null and not Telegraph.on_screen(player, spot + Vector2(0, 460), 0.0), "a Spitwick below the screen's edge doesn't start a wind-up")
	check(off.global_position.distance_to(player.global_position) < d0 - 5.0, "it creeps closer first")
	off.queue_free()

# --- Rule 9: two warnings never land together near the keeper --------------------------------------------------

func _gap_checks() -> void:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	await wait(0.05)
	var a: Spitwick = add_foe(Spitwick.new(), spot + Vector2(-200, 0))
	var b: Spitwick = add_foe(Spitwick.new(), spot + Vector2(200, 0))
	var c: Clinker = _new_clinker(spot + Vector2(0, -150))
	Progress.cleared.erase("clinker_hollow_post")
	c.awake = true
	c._cooldown = 0.0
	a._shot_t = 0.0
	b._shot_t = 0.0
	await wait(0.05)
	var ends := []
	for t in [a.tell(), b.tell(), c.tell()]:
		if t:
			ends.append(t.left())
	ends.sort()
	var ok := ends.size() == 3
	for i in range(1, ends.size()):
		ok = ok and ends[i] - ends[i - 1] >= Tuning.kl_tell_gap - 0.02
	check(ok, "three foes winding up in the same frame land %.2f s apart or more (%s)" % [Tuning.kl_tell_gap, str(ends)])
	clear_foes()

# --- The nest ------------------------------------------------------------------------------------------------

func _nest_checks() -> void:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	var n := WickNest.new()
	n.foe_id = "test_nest_tell"
	add_foe(n, spot + Vector2(-40, 0))
	await wait(0.05)
	n.set_time_to_hatch(Tuning.kl_nest_hatch_tell + 0.2)
	await wait(0.1)
	check(n.tell() == null, "no hatch warning until %.1f s before the hatch" % Tuning.kl_nest_hatch_tell)
	await wait(0.15)
	var t := n.tell()
	check(t != null and t.points.size() == Tuning.kl_nest_hatch_count, "then its ring fills and glows show where each hatchling will rise")
	reset_keeper(n._hatch_point(0))
	await wait(Tuning.kl_nest_hatch_tell)
	var hatch := get_tree().get_nodes_in_group("wickling").filter(func(w): return w.summoned and not w.is_queued_for_deletion())
	check(hatch.size() == Tuning.kl_nest_hatch_count and hatch.all(func(w): return w.is_fading_in()), "the hatchlings fade in")
	await wait(Tuning.kl_hatch_fade * 0.8)
	check(player.warmth > Tuning.warmth_max - 0.1, "a hatchling can't touch you while it fades in, even right on top of you")
	clear_foes()

# --- Wicklings: notice, reach, drain, frost ------------------------------------------------------------------

func _wickling_checks() -> void:
	for elite in [false, true]:
		clear_foes()
		await wait(0.05)
		reset_keeper(spot)
		var w: Wickling = spawner.spawn_at(spot + Vector2(150, 0), elite)
		w.timid = true
		await wait(0.1)
		check(w.state == Wickling.State.CHASE and w._notice_t > 0.0, "%s: its eyes flare as it notices you" % w.foe_name)
		w.global_position = player.global_position + Vector2(10, 0)
		var latch := Tuning.kl_elite_latch_tell if elite else Tuning.kl_wick_latch_tell
		await wait(latch * 0.6)
		check(w.latch_tell() != null and player.warmth > Tuning.warmth_max - 0.1, "%s: it reaches for %.2f s before its touch drains" % [w.foe_name, latch])
		await wait(latch * 0.6 + 0.2)
		check(w.latched and player.warmth < Tuning.warmth_max - 1.0 and player.frost_t > 0.0, "%s: then it drains, and the keeper shows a frost edge" % w.foe_name)
		w.global_position = player.global_position + Vector2(10, 0)
		hold_dash(0.3)
		var before: float = player.warmth
		await wait(0.2)
		check(absf(player.warmth - before) < 0.01, "%s: a dash stops the drain" % w.foe_name)
		player.combat.dash_t = 0.0
	clear_foes()

# --- Rule 11 / §1.6 rule 7: "reduce flashes" never hides a telegraph -------------------------------------------

func _reduce_flash_checks() -> void:
	var t := Telegraph.Tell.new()
	t.duration = 1.0
	var faint_ok := true
	for i in 20:
		t.t = i * 0.05
		var on := Telegraph.style(t, true)
		var off := Telegraph.style(t, false)
		faint_ok = faint_ok and on["edge"] >= 0.75 and on["edge"] >= off["edge"] - 0.001 or (t.committing() and on["edge"] >= 0.99)
	check(faint_ok, "with reduce flashes every marker keeps a bright edge from its first frame")
	t.t = 0.9
	var a := Telegraph.style(t, true)
	t.t = 0.95
	var b := Telegraph.style(t, true)
	t.t = 0.5
	var w := Telegraph.style(t, true)
	check(t.committing() == false and a["color"] == b["color"] and a["color"] != w["color"] and a["edge"] >= 0.99, "with reduce flashes the commit turns solid (no flashing), still unlike the wind-up")
	t.t = 0.87
	var c := Telegraph.style(t, false)
	t.t = 0.92
	var d := Telegraph.style(t, false)
	check(c["color"] != d["color"], "without it, the commit flashes")
	Settings.reduce_flashes = true
	check(Telegraph.inst != null and Telegraph.inst.visible and Telegraph.inst.is_inside_tree(), "the telegraph layer still draws with reduce flashes on")
	Settings.reduce_flashes = false

# --- The keeper's own feedback -------------------------------------------------------------------------------

func _keeper_checks() -> void:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot)
	player.combat.dash_cd = 0.0
	check(player.combat.dash(Vector2.RIGHT), "the keeper dashes")
	await wait(0.1)
	check(KeeperFx.inst != null and KeeperFx.inst.ghost_count() >= 1, "a dash leaves afterimages (%d)" % (KeeperFx.inst.ghost_count() if KeeperFx.inst else -1))
	await wait(0.5)
	check(KeeperFx.inst.ghost_count() == 0, "and they fade")
	for kind in ["throw", "lob", "thrust"]:
		player.combat.cast_cue(kind, Vector2.UP)
		var ps: Array = player.pose()
		await wait(Tuning.kl_fx_cast_time * 0.7)
		var ps2: Array = player.pose()
		check(ps[0] in [player.PUNY_CAST_RAISE, player.PUNY_CAST_UP, player.PUNY_CAST_THRUST] and ps2[0] in [player.PUNY_CAST_UP, player.PUNY_CAST_THRUST] and ps[1] == 4,
			"a %s cast shows the Puny raise and thrust frames, facing the aim (%s, %s)" % [kind, str(ps[0]), str(ps2[0])])
	await wait(0.2)
	player.flasks = 1
	player.flask_lock = 0.0
	player.warmth = 50.0
	check(player.drink() and player.drink_t > 0.0, "a drink starts the warm glow")
	await wait(0.05)
	player.chill(10.0)
	check(player.hurt_t > 0.0 and player.pose()[0] == player.PUNY_HIT, "a hit flashes the keeper cold (the Puny hit silhouette, tinted)")
	await wait(Tuning.kl_fx_hurt_time * 0.6)
	check(player.pose()[0] == player.PUNY_FLINCH, "then the flinch frame")
	Settings.reduce_flashes = true
	player.chill(10.0)
	check(player.pose()[0] == player.PUNY_FLINCH, "with reduce flashes there is no white silhouette, only the cold flinch")
	Settings.reduce_flashes = false
	player.warmth = Tuning.warmth_max

# --- M1c: the Ashbrood's new tells and the lock marker ---------------------------------------------------------

func _m1c_checks() -> void:
	clear_foes()
	await wait(0.05)
	reset_keeper(spot + Vector2(0, 200))
	var b: Ashbrood = add_foe(Ashbrood.new(), spot)
	await wait(0.05)
	b.end_phase_pause()
	b._puff_t = 99.0
	b._wave_t = 99.0
	b._bolt_t = 0.0
	await wait(0.05)
	var bolts: Array = b.bolt_tells()
	check(bolts.size() == Tuning.kl_ashbrood_bolt_count and bolts.all(func(t): return t.kind == Telegraph.AIM and t.hit and t.duration >= Tuning.kl_tell_min), "its ash bolts: one cold aim marker each, at least %.1f s of warning" % Tuning.kl_tell_min)
	var lands: Array = bolts.map(func(t): return t.duration)
	lands.sort()
	var spaced := true
	for i in range(1, lands.size()):
		if lands[i] - lands[i - 1] < Tuning.kl_tell_gap - 0.001:
			spaced = false
	check(spaced, "they land one after another, at least %.1f s apart (the gap rule) (%s)" % [Tuning.kl_tell_gap, str(lands)])
	check(Telegraph.style(bolts[0], false)["color"] == Telegraph.COLD, "in the cold threat colour")
	await wait(1.6)
	reset_keeper(spot + Vector2(0, Tuning.kl_ashbrood_sweep_radius - 30.0))
	b._sweep_cd = 0.0
	b._bolt_t = 99.0
	b._idle_t = 0.0
	await wait(0.05)
	var sw := b.sweep_tell()
	check(sw != null and sw.kind == Telegraph.CIRCLE and is_equal_approx(sw.radius, Tuning.kl_ashbrood_sweep_radius) and sw.duration >= Tuning.kl_tell_min, "its wing sweep: a %.0f px cold circle with at least %.1f s of warning" % [Tuning.kl_ashbrood_sweep_radius, Tuning.kl_tell_min])
	await wait(1.0)
	b.queue_free()
	clear_foes()
	await wait(0.05)
	# The lock marker: drawn by this node (above fog and foes), warm, never in a foe's colour.
	var w: Wickling = add_foe(Wickling.new(), spot + Vector2(120, 0))
	w.set_process(false)
	reset_keeper(spot)
	await wait(0.05)
	var lock: LockOn = player.combat.lock
	check(lock.acquire(Vector2.RIGHT), "a lock starts")
	var m := lock.marker()
	check(not m.is_empty() and m["color"] == LockOn.MARKER, "the lock marker is the keeper's amber #ffd27a")
	check(m["color"] != Telegraph.COLD and m["color"] != Telegraph.COLD_DEEP and m["color"] != Color.WHITE, "never a foe colour (cold means a foe's attack)")
	check(Telegraph.inst != null and Telegraph.inst.z_index == 13 and LockOn.current == lock, "it is drawn in the telegraph pass on the fog layer, above fog and foes")
	Settings.reduce_flashes = true
	var m2 := lock.marker()
	check(m2["alpha"] == m["alpha"] and m2["width"] == m["width"], "it never flashes, so reduce flashes changes nothing")
	Settings.reduce_flashes = false
	lock.release("test")
	clear_foes()
	await wait(0.05)

# --- The placeholder swap hook (§6.4) ------------------------------------------------------------------------

func _swap_checks() -> void:
	clear_foes()
	await wait(0.05)
	await _owner_art_checks()
	# The fallback, tested explicitly: with no strips anywhere (an empty art root), nothing loads and every foe
	# draws its code shape. (The committed owner art is checked above.)
	var real_roots := Art.sprite_roots
	DirAccess.make_dir_recursive_absolute("user://test_art_empty")
	Art.sprite_roots = PackedStringArray(["user://test_art_empty/"])
	Art.clear_frames()
	check(Art.frames("wickling") == null and Art.frames("spitwick") == null and Art.frames("keeper") == null and Art.frames("nest") == null and Art.frames("ashbrood") == null,
		"fallback: with no strips there are no frames for any subject")
	var w: Wickling = spawner.spawn_at(spot + Vector2(300, 0))
	var s: Spitwick = add_foe(Spitwick.new(), spot + Vector2(300, 60))
	var n: WickNest = add_foe(WickNest.new(), spot + Vector2(300, -80))
	n.foe_id = "test_nest_fallback"
	var b: Ashbrood = add_foe(Ashbrood.new(), spot + Vector2(400, 0))
	b._puff_t = 99.0
	b._wave_t = 99.0
	await wait(0.05)
	check(w._art == null and s._art == null and n._art == null and b._art == null and w.get_node_or_null("Art") == null and b.get_node_or_null("Art") == null,
		"so they draw their code shapes (the fallback)")
	w.queue_free()
	s.queue_free()
	n.queue_free()
	b.queue_free()
	Art.sprite_roots = real_roots
	Art.clear_frames()
	DirAccess.remove_absolute("user://test_art_empty")
	# A test-only strip: 4 frames of 16x16 for "idle", 3 for "windup" (timed by kl_spit_tell), in user://.
	var root := "user://test_art/creatures/"
	DirAccess.make_dir_recursive_absolute(root + "wickling")
	DirAccess.make_dir_recursive_absolute(root + "spitwick")
	_strip(root + "wickling/wickling_idle.png", 4)
	_strip(root + "wickling/wickling_elite_idle.png", 2)
	_strip(root + "spitwick/spitwick_idle.png", 4)
	_strip(root + "spitwick/spitwick_windup.png", 3)
	var cfg := ConfigFile.new()
	cfg.set_value("sheet", "frame_size", Vector2i(16, 16))
	cfg.set_value("sheet", "anchor", "foot")
	cfg.set_value("idle", "fps", 6.0)
	cfg.set_value("idle", "loop", true)
	cfg.set_value("windup", "fps", 8.0)
	cfg.set_value("windup", "loop", false)
	cfg.set_value("windup", "timed_by", "kl_spit_tell")
	cfg.save(root + "spitwick/spitwick.frames.cfg")
	var old := Art.sprite_roots
	Art.sprite_roots = PackedStringArray([root])
	Art.clear_frames()
	var sf := Art.frames("wickling")
	check(sf != null and sf.has_animation("idle") and sf.get_frame_count("idle") == 4, "a test-only PNG strip loads as a 4-frame idle (no frames file: defaults)")
	var ef := Art.frames("wickling", "elite")
	check(ef != null and ef.get_frame_count("idle") == 2, "a variant strip (wickling_elite_idle) wins over the plain one")
	# Per-variant frame sizes: the shelled Wickling is 24x24 while timid and brave are 16x16 (ART_DIRECTION §1.2).
	_strip(root + "wickling/wickling_elite_idle.png", 3, 24)
	_strip(root + "wickling/wickling_move.png", 4)
	var wcfg := ConfigFile.new()
	wcfg.set_value("sheet", "frame_size", Vector2i(16, 16))
	wcfg.set_value("sheet", "anchor", "foot")
	wcfg.set_value("variant.elite", "frame_size", Vector2i(24, 24))
	wcfg.save(root + "wickling/wickling.frames.cfg")
	Art.clear_frames()
	ef = Art.frames("wickling", "elite")
	var e0 := ef.get_frame_texture("idle", 0) as AtlasTexture if ef else null
	check(ef != null and ef.get_frame_count("idle") == 3 and e0 != null and e0.region.size == Vector2(24, 24) and ef.get_meta("frame_size_idle") == Vector2i(24, 24),
		"[variant.elite] frame_size = 24x24: the elite's 72x24 strip slices into 3 frames of 24x24 under a 16x16 sheet")
	check(ef != null and ef.get_frame_count("move") == 4 and ef.get_meta("frame_size_move") == Vector2i(16, 16),
		"the elite's missing move falls back to the plain 16x16 strip, sliced at the sheet's 16x16")
	var tf := Art.frames("wickling", "timid")
	check(tf != null and tf.get_meta("frame_size_idle") == Vector2i(16, 16) and tf.get_frame_count("idle") == 4, "timid and brave keep the sheet's 16x16")
	check(Art.strip_frame_size(wcfg, "elite", "idle", 32) == Vector2i(32, 32) and Art.strip_frame_size(null, "", "idle", 24) == Vector2i(24, 24),
		"a configured size that doesn't match the strip's height gives way to a square of that height; no frames file: the strip's height")
	var eholder := Node2D.new()
	add_child(eholder)
	var es := FoeSprite.attach(eholder, "wickling", "elite")
	var off_idle := es.offset if es else Vector2.ONE
	if es:
		es.play_anim("move")
	check(es != null and off_idle == Vector2(0, -12) and es.offset == Vector2(0, -8),
		"FoeSprite keeps the foot on the origin for each frame size (24x24 idle: offset -12; 16x16 move: -8)")
	eholder.queue_free()
	DirAccess.remove_absolute(root + "wickling/wickling.frames.cfg")
	DirAccess.remove_absolute(root + "wickling/wickling_move.png")
	_strip(root + "wickling/wickling_elite_idle.png", 2)
	Art.clear_frames()
	var w2: Wickling = spawner.spawn_at(spot + Vector2(300, 0))
	var s2: Spitwick = add_foe(Spitwick.new(), spot + Vector2(-200, 0))
	await wait(0.05)
	check(w2._art != null and w2._art.showing() and w2._art.current() == "idle", "a Wickling with owner art shows the sprite instead of its code shape")
	w2._art.play_anim("windup")
	check(w2._art.current() == "idle", "a missing wind-up falls back to idle")
	s2._shot_t = 0.0
	await wait(0.05)
	check(s2._art != null and s2._art.current() == "windup" and absf(s2._art.speed_scale - (3.0 / 8.0) / s2.tell().duration) < 0.01, "the Spitwick's wind-up strip is stretched to its wind-up's length")
	w2.queue_free()
	s2.queue_free()
	# The keeper's poses: the same hook.
	DirAccess.make_dir_recursive_absolute("user://test_art/keeper")
	_strip("user://test_art/keeper/keeper_idle.png", 2)
	Art.sprite_roots = PackedStringArray(["user://test_art/"])
	Art.clear_frames()
	var holder := Node2D.new()
	add_child(holder)
	var ks := FoeSprite.attach(holder, "keeper")
	check(ks != null and ks.showing() and ks.sprite_frames.get_frame_count("idle") == 2, "the keeper's poses load through the same hook")
	ks.play_anim("dash")
	check(ks.current() == "idle", "a missing dash pose falls back to idle")
	holder.queue_free()
	Art.sprite_roots = old
	Art.clear_frames()
	for p in ["keeper/keeper_idle.png", "creatures/wickling/wickling_idle.png", "creatures/wickling/wickling_elite_idle.png", "creatures/spitwick/spitwick_idle.png", "creatures/spitwick/spitwick_windup.png", "creatures/spitwick/spitwick.frames.cfg"]:
		DirAccess.remove_absolute("user://test_art/" + p)

## The committed owner art (assets/art/, approved 2026-11-27): every subject loads its strips, and the game
## shows them with the overlays still on top.
func _owner_art_checks() -> void:
	Art.clear_frames()
	# subject, variant, [animation, frame count, frame size]...
	var want := [
		["wickling", "timid", [["idle", 4, 16], ["move", 4, 16], ["notice", 2, 16], ["flee", 2, 16], ["spawn", 5, 16], ["death", 5, 16]]],
		["wickling", "brave", [["idle", 4, 16], ["move", 4, 16], ["windup", 1, 16], ["attack", 2, 16], ["death", 5, 16]]],
		["wickling", "elite", [["idle", 4, 24], ["crack", 2, 24], ["notice", 2, 24], ["death", 5, 24]]],
		["wickling", "elite_broken", [["idle", 4, 24]]],
		["spitwick", "", [["idle", 4, 16], ["windup", 1, 16], ["attack", 2, 16], ["recover", 1, 16], ["death", 5, 16]]],
		["nest", "", [["idle", 1, 32], ["windup", 1, 32], ["attack", 1, 32], ["death", 1, 32]]],
		["keeper", "", [["idle", 4, 32], ["move", 4, 32], ["thrust", 1, 32], ["lob", 1, 32], ["dash", 1, 32], ["drink", 1, 32], ["hurt", 1, 32], ["kindle", 1, 32]]],
		["ashbrood", "", [["idle", 4, 48], ["windup_puff", 1, 48], ["attack_puff", 1, 48], ["windup_dive", 1, 48], ["attack_dive", 1, 48], ["recover", 1, 48], ["phase_rise", 1, 48], ["death", 1, 48]]],
		["amos", "", [["idle", 4, 32], ["move", 4, 32], ["talk", 2, 32], ["wave", 1, 32], ["push", 1, 32], ["give", 1, 32], ["laugh", 1, 32]]],
	]
	for row in want:
		var sf := Art.frames(row[0], row[1])
		var ok := sf != null
		var bad := ""
		for a in row[2]:
			if not ok:
				break
			var at := sf.get_frame_texture(a[0], 0) as AtlasTexture if sf.has_animation(a[0]) else null
			if at == null or sf.get_frame_count(a[0]) != a[1] or int(at.region.size.x) != a[2]:
				ok = false
				bad = a[0]
		check(ok, "owner art: %s%s loads its strips (%s)%s" % [row[0], (" " + row[1]) if row[1] != "" else "", ", ".join(row[2].map(func(a): return a[0])), (" - bad: " + bad) if bad != "" else ""])
	var cart := Art.prop("amos", "amos_cart")
	check(cart != null and cart.get_size() == Vector2(48, 32), "owner art: Amos's cart loads as a 48 x 32 prop (left out of his animations)")
	check(Art.frames("amos") != null and not Art.frames("amos").has_animation("cart"), "the cart is not one of Amos's animations")
	check(player._art != null and player._art.showing(), "the keeper shows the owner poses (no Puny frames)")
	# The foes, in the game: sprite on, code shape off, overlays (drawn by the foe) on top of the sprite.
	var w: Wickling = spawner.spawn_at(spot + Vector2(300, 0))
	var e: Wickling = spawner.spawn_at(spot + Vector2(340, 0), true)
	var s: Spitwick = add_foe(Spitwick.new(), spot + Vector2(300, 60))
	s._shot_t = 99.0
	var n: WickNest = add_foe(WickNest.new(), spot + Vector2(300, -80))
	n.foe_id = "test_nest_art"
	var b: Ashbrood = add_foe(Ashbrood.new(), spot + Vector2(420, 0))
	b._puff_t = 99.0
	b._wave_t = 99.0
	await wait(0.05)
	for f in [w, e, s, n, b]:
		var a: FoeSprite = f._art
		check(a != null and a.showing() and a.show_behind_parent and a.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST,
			"%s shows its owner sprite, drawn behind its own overlays" % f.foe_name)
	check(w._art.variant in ["timid", "brave"] and e._art.variant == "elite", "a Wickling uses its variant's strips (timid or brave; the elite its shelled one)")
	var tl := get_tree().get_first_node_in_group("telegraph_layer") as Node2D
	var top := 0
	for f in [w, e, s, n, b]:
		top = maxi(top, f.z_index + (f._art.z_index if f._art.z_as_relative else 0))
	check(tl != null and tl.z_index > top and tl.get_parent() == b.get_parent().get_parent(), "the telegraph markers draw over every foe sprite (z %d over %d, same layer)" % [tl.z_index if tl else -1, top])
	# An elite's shell breaks: the crack plays, then the shell-less body.
	e.shell = 0.01
	e.hurt(5.0, false, "lance")
	await wait(0.02)
	check(e._art.current() == "crack", "an elite's shell breaking plays its crack strip")
	await wait(0.5)
	check(e._art.variant == "elite_broken", "then it shows the shell-less body (elite_broken)")
	# The Ashbrood: the puff's wind-up strip, stretched to the tell.
	b._puff_t = 0.0
	await wait(0.05)
	check(b._art.current() == "windup_puff" and absf(b._art.speed_scale - (1.0 / 8.0) / b.puff_tell().duration) < 0.01,
		"the Ashbrood's puff wind-up shows its strip for the whole tell")
	b.phase = 2
	b._puff_t = 99.0
	if b.puff_tell():
		b.puff_tell().finish()
		b._puff = null
	b._dive_t = 99.0
	await wait(0.05)
	check(b._art.current() == "phase_rise", "out of the bowl (phase 2) it shows its risen pose, not the bowl")
	# The nest's hatch: its wind-up strip under the hatch ring.
	reset_keeper(spot + Vector2(300, -40))
	n.set_time_to_hatch(Tuning.kl_nest_hatch_tell - 0.05)
	await wait(0.05)
	check(n._art.current() == "windup" and n.tell() != null, "a nest about to hatch shows its wind-up strip (the hatch ring is drawn over it)")
	# A kill leaves the death strip where the foe fell; then it fades away.
	var at := w.global_position
	w.hurt(999.0, false, "lance")
	await wait(0.02)
	var rem: Node = null
	for c in spawner.get_children():
		if c.has_meta("remnant") and c is AnimatedSprite2D:
			rem = c
	check(rem != null and (rem as AnimatedSprite2D).animation == "death" and (rem as Node2D).global_position.distance_to(at) < 2.0 and not rem.is_in_group("foe"),
		"a Wickling's kill plays its death strip where it fell (a picture only: not a foe)")
	await wait(2.0)
	check(rem == null or not is_instance_valid(rem), "the remnant goes after its death strip")
	for f in [e, s, n, b]:
		if is_instance_valid(f):
			f.queue_free()
	reset_keeper(spot)
	await wait(0.05)

func _strip(path: String, frames: int, size: int = 16) -> void:
	var img := Image.create(size * frames, size, false, Image.FORMAT_RGBA8)
	for i in frames:
		img.fill_rect(Rect2i(i * size + 4, 4, 8, 8), Color(0.2, 0.3, 0.4 + 0.1 * i))
	img.save_png(path)
