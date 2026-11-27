extends Node
## Leveling balance (2026-11-27): counts all the wick in the Hollow from the placed packs, nests, the Clinker,
## the Ashbrood and kindling, walks two full clears (a beeline to the Clinker, and an explorer who takes the
## nearest thing first), and checks the level curve against the targets in DESIGN §9. It also prints the old
## flat curve and old wick values on the same map, and a time-to-kill table from tuning.gd. Then it runs one
## clear through the real Progress and level-up screen: every level-up must offer three real cards.
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_leveling.tscn

# Before the balance pass (flat 15, +10 a level; shelled Wicklings fell back to Foe's default of 1).
const OLD := {"wickling": 1, "elite": 1, "spitwick": 2, "nest": 8, "clinker": 15, "ashbrood": 40, "kindle": 30}
const OLD_NEST_HATCH := 3       # old: one hatch (3 Wicklings, 1 wick each) per nest while you burn it
const OLD_ASHBROOD_ADDS := 12   # old: about four waves of 3 in phase 1 (a 30-40 s phase)

var main: Node
var frame := 0
var fails := 0
var level_ui: Node
var holder: Node
var wv := {}                    # live wick per kind, read from real foes
var start := Vector2.ZERO
var routes := {}                # name -> Array of events {name, kind, units (new wick per kill), old, old_adds}
var _run: Array = []            # the clear fed through the real Progress
var _run_i := 0
var _offers: Array[int] = []
var _step := 0

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
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
	SaveGame.path = "user://test_leveling.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	level_ui = main.get_node("HUD").level_up_screen

## The wick a real foe of each kind is worth (they set it in _ready from tuning.gd).
func _read_wick_values() -> void:
	holder = Node2D.new()
	holder.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(holder)
	var w := Wickling.new()
	var e := Wickling.new()
	e.elite = true
	var samples := {"wickling": w, "elite": e, "spitwick": Spitwick.new(), "nest": WickNest.new(), "clinker": Clinker.new(), "ashbrood": Ashbrood.new()}
	for k in samples:
		holder.add_child(samples[k])
		wv[k] = samples[k].wick_value
	wv["kindle"] = Tuning.kl_wick_kindle
	holder.free()

func _pack_event(p: EnemyPack) -> Dictionary:
	var units := []
	var old := 0
	for i in p.count:
		var kind := "spitwick" if i < p.spitwicks else ("elite" if i >= p.count - p.elites else "wickling")
		units.append(wv[kind])
		old += OLD[kind]
	return {"name": "pack %s (%d)" % [p.id, p.count], "kind": "pack", "pos": p.global_position, "units": units, "old": old, "old_adds": old}

func _one(name: String, kind: String, pos: Vector2, old_adds: int) -> Dictionary:
	return {"name": name, "kind": kind, "pos": pos, "units": [wv[kind]], "old": OLD[kind], "old_adds": OLD[kind] + old_adds}

func _build_routes() -> void:
	start = main.start
	var packs: Array = []
	for p in get_tree().get_nodes_in_group("enemy_pack"):
		packs.append(_pack_event(p))
	var nests: Array = []
	var clinker: Dictionary
	for f in get_tree().get_nodes_in_group("foe"):
		if f is WickNest:
			nests.append(_one("nest " + f.foe_id, "nest", f.global_position, OLD_NEST_HATCH))
		elif f is Clinker:
			clinker = _one("the Clinker", "clinker", f.global_position, 0)
	var wl: Vector2 = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0].global_position
	var finale := [_one("the Ashbrood", "ashbrood", wl, OLD_ASHBROOD_ADDS), _one("kindling the WayLamp", "kindle", wl, 0)]
	# Beeline: follow the pointer to the Clinker, fighting every pack whose wake radius the path crosses;
	# then everything else nearest-first (nests only burn once you have the Post Lamp); the guardian last.
	var on_path := packs.filter(func(e): return _dist_to_segment(e.pos, start, clinker.pos) <= Tuning.kl_pack_wake_radius)
	on_path.sort_custom(func(a, b): return start.distance_to(a.pos) < start.distance_to(b.pos))
	var rest := packs.filter(func(e): return not on_path.has(e)) + nests
	routes["beeline"] = on_path + [clinker] + _nearest_first(rest, clinker.pos) + finale
	# Explorer: always the nearest thing it can fight; nests open up after the Clinker.
	var route := []
	var todo := packs.duplicate() + [clinker]
	var at := start
	var nests_open := false
	while not todo.is_empty():
		todo.sort_custom(func(a, b): return at.distance_to(a.pos) < at.distance_to(b.pos))
		var next: Dictionary = todo.pop_front()
		route.append(next)
		at = next.pos
		if next.kind == "clinker" and not nests_open:
			nests_open = true
			todo += nests
	routes["explorer"] = route + finale

func _nearest_first(events: Array, from: Vector2) -> Array:
	var todo := events.duplicate()
	var out := []
	var at := from
	while not todo.is_empty():
		todo.sort_custom(func(a, b): return at.distance_to(a.pos) < at.distance_to(b.pos))
		var next: Dictionary = todo.pop_front()
		out.append(next)
		at = next.pos
	return out

func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))

static func old_need(lv: int) -> int:
	return 15 + 10 * (lv - 1)

## Walks a route: the level after each event. curve: "new" (Progress.wick_for_level) or "old".
func simulate(route: Array, curve: String, field: String) -> Array:
	var lv := 1
	var wick := 0
	var out := []
	for e in route:
		var gain: int = 0
		if field == "units":
			for u in e.units:
				gain += int(u)
		else:
			gain = int(e[field])
		wick += gain
		while true:
			var need: int = Progress.wick_for_level(lv) if curve == "new" else old_need(lv)
			if curve == "new" and lv >= Tuning.kl_level_cap:
				break
			if wick < need:
				break
			wick -= need
			lv += 1
		out.append(lv)
	return out

func _total(route: Array, field: String) -> int:
	var t := 0
	for e in route:
		if field == "units":
			for u in e.units:
				t += int(u)
		else:
			t += int(e[field])
	return t

func _first_index(route: Array, kind: String, nth: int = 1) -> int:
	var seen := 0
	for i in route.size():
		if route[i].kind == kind:
			seen += 1
			if seen == nth:
				return i
	return -1

## Time to kill with the beam, from tuning.gd: [seconds of beam, lamp charge used, seconds including refills].
## "stacked" = Tight focus + Lingering burn + Deep tank, the damage upgrades that stack on one target.
func ttk(hp: float, shell: float, stacked: bool) -> Array:
	var dps := Tuning.kl_beam_dps
	var linger := Tuning.kl_linger_dps if stacked else 0.0
	var shell_dps := dps * (Tuning.kl_focus_shell_mult if stacked else 1.0)
	var t_shell := shell / shell_dps
	var hp_left := maxf(0.0, hp - linger * t_shell)   # Lingering burn eats hp even under the shell
	var t := t_shell + hp_left / (dps + linger)
	var charge := t * Tuning.kl_beam_cost * (Tuning.kl_deep_tank_mult if stacked else 1.0)
	return [t, charge, t + charge / Tuning.hand_lamp_recharge_per_sec]

func _measure() -> void:
	_read_wick_values()
	_build_routes()
	print("--- Wick per kill (live): %s" % str(wv))
	var r: Array = routes["beeline"]
	var n_packs := r.filter(func(e): return e.kind == "pack").size()
	var n_foes := 0
	for e in r:
		if e.kind == "pack":
			n_foes += e.units.size()
	print("--- The Hollow: %d packs (%d foes), %d nests, the Clinker, the Ashbrood, kindling" % [n_packs, n_foes, r.filter(func(e): return e.kind == "nest").size()])
	for kind in ["pack", "nest", "clinker", "ashbrood", "kindle"]:
		var part := r.filter(func(e): return e.kind == kind)
		print("    %-9s old %4d   old+adds %4d   new %4d" % [kind, _total(part, "old"), _total(part, "old_adds"), _total(part, "units")])
	print("    %-9s old %4d   old+adds %4d   new %4d" % ["TOTAL", _total(r, "old"), _total(r, "old_adds"), _total(r, "units")])
	var curve_new := []
	var curve_old := []
	var cum_new := 0
	var cum_old := 0
	for lv in range(1, 12):
		cum_new += Progress.wick_for_level(lv)
		cum_old += old_need(lv)
		curve_new.append("L%d %d (%d)" % [lv + 1, Progress.wick_for_level(lv), cum_new])
		curve_old.append("L%d %d (%d)" % [lv + 1, old_need(lv), cum_old])
	print("--- Old curve, wick to reach (total): " + ", ".join(curve_old))
	print("--- New curve, wick to reach (total): " + ", ".join(curve_new))
	var upgrades: int = level_ui.OPTIONS.size()
	for name in routes:
		var route: Array = routes[name]
		var lv_new := simulate(route, "new", "units")
		var lv_old := simulate(route, "old", "old")
		var lv_old_adds := simulate(route, "old", "old_adds")
		var p1 := _first_index(route, "pack", 1)
		var p2 := _first_index(route, "pack", 2)
		var ci := _first_index(route, "clinker")
		var ai := _first_index(route, "ashbrood")
		var before_boss: int = lv_new[ai - 1]
		var ups := []
		var prev := 1
		for i in route.size():
			if lv_new[i] > prev:
				ups.append("L%d at #%d %s" % [lv_new[i], i + 1, route[i].name])
			prev = lv_new[i]
		print("--- Route %s (%d stops). New: %s" % [name, route.size(), "; ".join(ups)])
		print("    old curve: L%d after pack 2, L%d before the Clinker (stop %d), L%d at the end (L%d with nest hatches and Ashbrood adds)" % [lv_old[p2], lv_old[ci - 1] if ci > 0 else 1, ci + 1, lv_old[-1], lv_old_adds[-1]])
		print("    new curve: L%d after pack 1, L%d after pack 2, L%d before the Clinker, L%d before the Ashbrood, L%d at the end" % [lv_new[p1], lv_new[p2], lv_new[ci - 1] if ci > 0 else 1, before_boss, lv_new[-1]])
		var level_ups: int = lv_new[-1] - 1
		check(level_ups >= 6 and level_ups <= 8, "%s: a full Hollow clear gives 6-8 level-ups (%d, ending at L%d)" % [name, level_ups, lv_new[-1]])
		check(lv_new[p2] >= 2 and lv_new[p1] <= 2, "%s: level 2 comes with the first pack or two" % name)
		check(ci > 0 and lv_new[ci - 1] >= 3, "%s: level 3 before the Clinker" % name)
		var boss_ups: int = lv_new[-1] - before_boss
		check(boss_ups >= 1 and boss_ups <= 2, "%s: the Ashbrood and its WayLamp give one or two levels (%d)" % [name, boss_ups])
		check(level_ups <= upgrades - 2, "%s: no level-up is wasted: every offer still has three cards (%d level-ups, %d upgrades)" % [name, level_ups, upgrades])
		check(lv_new[-1] < Tuning.kl_level_cap, "%s: the Hollow stays under the level cap (%d)" % [name, Tuning.kl_level_cap])
	check(upgrades == 12, "twelve upgrades to choose from (%d)" % upgrades)
	# Time to kill, from the numbers in tuning.gd.
	var rows := [
		["Wickling", Tuning.wick_hp, 0.0], ["Spitwick", Tuning.kl_spitwick_hp, 0.0],
		["Shelled Wickling", Tuning.kl_elite_hp, Tuning.kl_elite_shell],
		["Clinker", Tuning.kl_clinker_hp, Tuning.kl_clinker_shell],
		["Ashbrood (a phase)", Tuning.kl_ashbrood_hp, Tuning.kl_ashbrood_shell],
	]
	print("--- Time to kill with the beam: fresh -> stacked (Tight focus + Lingering burn + Deep tank). s of beam / lamps / s with refills")
	for row in rows:
		var a := ttk(row[1], row[2], false)
		var b := ttk(row[1], row[2], true)
		print("    %-20s %5.2f / %4.2f / %5.1f   ->   %5.2f / %4.2f / %5.1f" % [row[0], a[0], a[1], a[2], b[0], b[1], b[2]])
	var fresh := ttk(Tuning.kl_ashbrood_hp, Tuning.kl_ashbrood_shell, false)
	var stacked := ttk(Tuning.kl_ashbrood_hp, Tuning.kl_ashbrood_shell, true)
	check(stacked[2] >= 0.6 * fresh[2], "stacked upgrades don't trivialize the Ashbrood (%.1f s vs %.1f s of damage per phase)" % [stacked[2], fresh[2]])
	check(fresh[2] * 2.0 >= 20.0, "a fresh keeper needs at least 20 s of beam and refills for both phases (%.1f s)" % (fresh[2] * 2.0))
	_run = routes["beeline"]

func _process(_delta: float) -> void:
	frame += 1
	if frame == 2:
		_measure()
		Progress.reset()
		return
	if frame < 3:
		return
	# A level-up screen is up: note how many cards it offers and take the first.
	if level_ui.root.visible:
		_offers.append(level_ui.cards.get_child_count())
		(level_ui.cards.get_child(0) as Button).pressed.emit()
		return
	if _run_i < _run.size():
		for u in _run[_run_i].units:
			Progress.add_wick(int(u))
		_run_i += 1
		return
	_step += 1
	match _step:
		1:
			var sim: Array = simulate(_run, "new", "units")
			check(Progress.level == sim[-1], "the real Progress lands on the same level (L%d)" % Progress.level)
			check(_offers.size() == Progress.level - 1 and _offers.all(func(n): return n == 3), "every level-up offered three cards (%s)" % str(_offers))
			check(not Progress.has_combat_upgrade("level_cap") and Progress.combat_upgrades.size() == Progress.level - 1, "every level-up became a real upgrade (%s)" % str(Progress.combat_upgrades))
			Progress.reset()
			Progress.level = 3
			Progress.wick = 5
		3:
			var hud = main.get_node("HUD")
			check(hud.wick_level.text == "Lv 3" and hud.wick_count.text == "5/%d" % Progress.wick_for_level(3), "the HUD shows the level and the wick to the next (%s %s)" % [hud.wick_level.text, hud.wick_count.text])
			check(hud.wick_level.get_theme_font_size("font_size") == 20 and hud.wick_count.get_theme_font_size("font_size") == 20, "at a readable Ark Pixel size (20)")
			# Wick per kill, through real foes.
			Progress.reset()
			var wl := main.get_node("FogLayer/Wicklings")
			var called := Wickling.new()
			called.summoned = true
			wl.add_child(called)
			called.hurt(99.0, false, "burst")
			check(Progress.wick == Tuning.kl_wick_summoned, "a hatched or called Wickling pays %d wick" % Tuning.kl_wick_summoned)
			var member := Wickling.new()
			member.wick_key = "wick_test_0"
			wl.add_child(member)
			member.hurt(99.0, false, "burst")
			var after_first := Progress.wick
			check(after_first == Tuning.kl_wick_summoned + Tuning.kl_wickling_wick, "a pack member pays its wick")
			Progress.cleared.erase("pack_test")   # a faint brings the pack back
			var again := Wickling.new()
			again.wick_key = "wick_test_0"
			wl.add_child(again)
			again.hurt(99.0, false, "burst")
			check(Progress.wick == after_first, "and beating it again after a faint pays nothing")
			var elite := Wickling.new()
			elite.elite = true
			wl.add_child(elite)
			elite.hurt(99.0, false, "beam")
			check(Progress.wick == after_first + Tuning.kl_elite_wick, "a shelled Wickling pays %d wick" % Tuning.kl_elite_wick)
			# The cap: no level-ups past it.
			Progress.level = Tuning.kl_level_cap
			Progress.wick = 0
			Progress.add_wick(1000)
			check(Progress.level == Tuning.kl_level_cap and Progress.wick == 0 and Progress.pending_level_ups == 0, "no level-ups past the cap (L%d)" % Tuning.kl_level_cap)
		5:
			check(main.get_node("HUD").wick_count.text == "max", "the HUD says max at the cap")
			Progress.reset()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
