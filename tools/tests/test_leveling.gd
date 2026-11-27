extends Node
## Leveling balance (2026-11-27): counts all the wick in the Hollow from the placed packs, nests, the Clinker,
## the Ashbrood and kindling, walks two full clears (a beeline to the Clinker, and an explorer who takes the
## nearest thing first), and checks the level curve against the targets in DESIGN §9. Each kill pays its wick
## scaled by the foe's level and the level gap (Progress.kill_wick). It also prints the old flat curve and old
## wick values on the same map, and a time-to-kill table from tuning.gd. A farming keeper who camps the hut row
## and the south (endless hatchlings, packs re-fought after faints) must stall around level 4, slower than going
## forward. Then it runs one clear through the real Progress and level-up screen: every level-up must offer three
## real cards.
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
var lv_of := {}                 # live foe level per kind (the Clinker, the Ashbrood)
var routes := {}                # name -> Array of events {name, kind, units ([base wick, foe level] per kill; level 0 = flat), old, old_adds}
var farm_packs: Array = []      # packs on the hut row and south of it (the farming check)
var farm_nests: Array = []
var _run: Array = []            # the clear fed through the real Progress
var _run_i := 0
var _offers: Array[int] = []
var _step := 0
var _sim_wick := 0              # wick toward the next level at the end of the last simulate()

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
		lv_of[k] = samples[k].level
	wv["kindle"] = Tuning.kl_wick_kindle
	holder.free()

func _pack_event(p: EnemyPack) -> Dictionary:
	var units := []
	var old := 0
	for i in p.count:
		var kind := "spitwick" if i < p.spitwicks else ("elite" if i >= p.count - p.elites else "wickling")
		units.append([wv[kind], p.level])
		old += OLD[kind]
	return {"name": "pack %s Lv%d (%d)" % [p.id, p.level, p.count], "kind": "pack", "pos": p.global_position, "units": units, "old": old, "old_adds": old, "level": p.level}

## level: the foe level (0 = flat wick, like kindling).
func _one(name: String, kind: String, pos: Vector2, old_adds: int, level: int) -> Dictionary:
	return {"name": name, "kind": kind, "pos": pos, "units": [[wv[kind], level]], "old": OLD[kind], "old_adds": OLD[kind] + old_adds, "level": level}

func _build_routes() -> void:
	start = main.start
	var packs: Array = []
	for p in get_tree().get_nodes_in_group("enemy_pack"):
		packs.append(_pack_event(p))
		if p.global_position.y >= start.y - 7.0 * FogGrid.TILE:
			farm_packs.append(packs[-1])
	var nests: Array = []
	var clinker: Dictionary
	for f in get_tree().get_nodes_in_group("foe"):
		if f is WickNest:
			var ne := _one("nest %s Lv%d" % [f.foe_id, f.level], "nest", f.global_position, OLD_NEST_HATCH, f.level)
			# Hatchlings now pay like any Wickling of the nest's level: one hatch while you burn it, before the nest.
			var hatch := []
			for i in Tuning.kl_nest_hatch_count:
				hatch.append([wv["wickling"], f.level])
			ne.units = hatch + ne.units
			nests.append(ne)
			if f.global_position.y >= start.y - 7.0 * FogGrid.TILE:
				farm_nests.append(f.level)
		elif f is Clinker:
			clinker = _one("the Clinker", "clinker", f.global_position, 0, f.level)
	var wl: Vector2 = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0].global_position
	var boss := _one("the Ashbrood", "ashbrood", wl, OLD_ASHBROOD_ADDS, lv_of["ashbrood"])
	# Its phase-1 adds (about four waves of 3) pay like any Wickling of their level, before the kill.
	var adds := []
	for i in OLD_ASHBROOD_ADDS:
		adds.append([wv["wickling"], Tuning.kl_ashbrood_add_level])
	boss.units = adds + boss.units
	var finale := [boss, _one("kindling the WayLamp", "kindle", wl, 0, 0)]
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

## A kill's wick for a keeper of level `keeper`: unit = [base wick, foe level]; foe level 0 = flat (kindling).
static func unit_wick(u: Array, keeper: int) -> float:
	return float(u[0]) if int(u[1]) <= 0 else Progress.kill_wick(int(u[0]), int(u[1]), keeper)

## Walks a route: the level after each event. curve: "new" (Progress.wick_for_level, wick scaled by the
## level gap, fractions carried like Progress.add_wick_f) or "old" (flat curve, flat old wick).
func simulate(route: Array, curve: String, field: String) -> Array:
	var lv := 1
	var wick := 0
	var frac := 0.0
	var out := []
	for e in route:
		var gain: int = 0
		if field == "units":
			for u in e.units:
				if lv >= Tuning.kl_level_cap:
					break
				frac += unit_wick(u, lv)
				var whole := floori(frac + 0.0001)
				frac = maxf(0.0, frac - whole)
				wick += whole
				while lv < Tuning.kl_level_cap and wick >= Progress.wick_for_level(lv):
					wick -= Progress.wick_for_level(lv)
					lv += 1
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
	_sim_wick = wick
	return out

## Total wick at full value (no level gap): the base grown by the foe's level.
func _total(route: Array, field: String) -> int:
	var t := 0
	for e in route:
		if field == "units":
			for u in e.units:
				t += roundi(unit_wick(u, 1 if int(u[1]) <= 0 else int(u[1])))
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
		check(before_boss == 7, "%s: level 7 into the Ashbrood (L%d)" % [name, before_boss])
		check(lv_new[ai] == 8 and lv_new[ai] > before_boss, "%s: the Ashbrood kill gives the Hollow's last level, L8 (L%d)" % [name, lv_new[ai]])
		var adds_only: Dictionary = route[ai].duplicate()
		adds_only.units = route[ai].units.slice(0, route[ai].units.size() - 1)
		var lv_adds := simulate(route.slice(0, ai) + [adds_only], "new", "units")
		check(lv_adds[-1] == before_boss, "%s: its adds alone don't cross the line; the kill does (L%d, %d/%d wick after the adds)" % [name, lv_adds[-1], _sim_wick, Progress.wick_for_level(lv_adds[-1])])
		check(lv_new[-1] == lv_new[ai], "%s: kindling afterwards adds wick but no level (L%d)" % [name, lv_new[-1]])
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
	_farm_check()
	_run = routes["beeline"]

## Forward route, minutes: walking (at fog-slowed speed) plus beam time with refills for each kill, plus a short
## fight overhead per stop. Rough, but the same model for every route.
func _route_minutes(route: Array) -> float:
	var walk := 0.0
	var at := start
	var fight := 0.0
	var kill_s := {1: ttk(Tuning.wick_hp, 0.0, false)[2], 2: ttk(Tuning.kl_spitwick_hp, 0.0, false)[2], 3: ttk(Tuning.kl_elite_hp, Tuning.kl_elite_shell, false)[2]}
	for e in route:
		walk += at.distance_to(e.pos)
		at = e.pos
		fight += 8.0
		for u in e.units:
			fight += kill_s.get(int(u[0]), 10.0)
	return (walk / (160.0 * Tuning.fog_slow_min) + fight) / 60.0

## Farming (owner, 2026-11-27: "eventually it doesn't pay"): a keeper camps the hut row and the south. Each
## minute the best nest there hatches kl_nest_hatch_count every kl_nest_hatch_sec (all killed), and every
## FARM_FAINT_MIN minutes a faint re-arms every pack there, which are all fought again. Generous on purpose.
const FARM_FAINT_MIN := 5
const FARM_MINUTES := 30
func _farm_check() -> void:
	var nest_lv := 1
	for l in farm_nests:
		nest_lv = maxi(nest_lv, int(l))
	var hatch_per_min := Tuning.kl_nest_hatch_count * 60.0 / Tuning.kl_nest_hatch_sec
	var lv := 1
	var wick := 0.0
	var per_min: Array[float] = []
	var reached := {}
	for minute in range(1, FARM_MINUTES + 1):
		var gain := hatch_per_min * unit_wick([wv["wickling"], nest_lv], lv)
		if minute % FARM_FAINT_MIN == 0:
			for e in farm_packs:
				for u in e.units:
					gain += unit_wick(u, lv)
		per_min.append(gain)
		wick += gain
		while lv < Tuning.kl_level_cap and wick >= Progress.wick_for_level(lv):
			wick -= Progress.wick_for_level(lv)
			lv += 1
			reached[lv] = minute
	var last10 := 0.0
	for g in per_min.slice(FARM_MINUTES - 10):
		last10 += g / 10.0
	var levels := []
	for l in reached:
		levels.append("L%d at %d min" % [l, reached[l]])
	print("--- Farming the hut row and the south (%d packs, nests Lv %d, %.0f hatchlings/min, packs again every %d min): %s; L%d after %d min; wick/min: first %.1f, last 10 min %.2f" % [farm_packs.size(), nest_lv, hatch_per_min, FARM_FAINT_MIN, ", ".join(levels), lv, FARM_MINUTES, per_min[0], last10])
	var fwd: Array = routes["beeline"]
	var ai := _first_index(fwd, "ashbrood")
	var fwd_part := fwd.slice(0, ai + 1)
	var fwd_lv := simulate(fwd_part, "new", "units")
	var fwd_min := _route_minutes(fwd_part)
	print("--- Forward (beeline to the Ashbrood kill): L%d in about %.0f min (rough walk + fight model)" % [fwd_lv[-1], fwd_min])
	check(lv <= 5 and int(reached.get(5, 999)) >= 20, "farming stalls: still level 4 after 20 min, at most level 5 after %d (L%d)" % [FARM_MINUTES, lv])
	check(last10 <= 0.1 * per_min[0], "farming wick per minute falls toward nothing (%.2f vs %.1f at the start)" % [last10, per_min[0]])
	check(fwd_lv[-1] > lv and fwd_min < FARM_MINUTES, "going forward is faster: L%d in about %.0f min vs L%d after %d min of farming" % [fwd_lv[-1], fwd_min, lv, FARM_MINUTES])

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
			if int(u[1]) <= 0:
				Progress.add_wick(int(u[0]))
			else:
				Progress.add_wick_f(Progress.kill_wick(int(u[0]), int(u[1])))
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
			Progress.level = 3
			var called := Wickling.new()
			called.summoned = true
			called.level = 3
			wl.add_child(called)
			called.hurt(99.0, false, "burst")
			var hatch_pay := Progress.kill_wick(Tuning.kl_wickling_wick, 3)
			check(Progress.wick == floori(hatch_pay + 0.0001) and absf(Progress.wick + Progress.wick_frac - hatch_pay) < 0.001, "a hatched or called Wickling pays like any Lv 3 Wickling (%.2f)" % hatch_pay)
			var w0 := Progress.wick + Progress.wick_frac
			for i in 2:   # a pack member, then the same member again after a faint brings its pack back
				var member := Wickling.new()
				member.pack_id = "test"
				member.level = 3
				wl.add_child(member)
				member.hurt(99.0, false, "burst")
				Progress.cleared.erase("pack_test")
			check(absf(Progress.wick + Progress.wick_frac - w0 - 2.0 * hatch_pay) < 0.001, "a re-fought pack pays again, scaled by the level gap")
			var elite := Wickling.new()
			elite.elite = true
			elite.level = 3
			wl.add_child(elite)
			var w1 := Progress.wick + Progress.wick_frac
			elite.hurt(99.0, false, "beam")
			check(absf(Progress.wick + Progress.wick_frac - w1 - Progress.kill_wick(Tuning.kl_elite_wick, 3)) < 0.001, "a shelled Wickling pays %d base wick, grown by its level" % Tuning.kl_elite_wick)
			# The gap rule itself.
			check(is_equal_approx(Progress.wick_gap_mult(5, 5), 1.0) and is_equal_approx(Progress.wick_gap_mult(4, 4 + Tuning.kl_xp_band), 1.0), "full wick up to %d level(s) over a foe" % Tuning.kl_xp_band)
			check(is_equal_approx(Progress.wick_gap_mult(1, 3 + Tuning.kl_xp_band), Tuning.kl_xp_falloff * Tuning.kl_xp_falloff), "x%.2f per level past the band" % Tuning.kl_xp_falloff)
			check(Progress.wick_gap_mult(1, 1 + Tuning.kl_xp_zero_gap) == 0.0 and Progress.kill_wick(5, 1, 12) == 0.0, "nothing at %d or more levels over" % Tuning.kl_xp_zero_gap)
			check(Progress.wick_gap_mult(9, 1) <= 1.0 + Tuning.kl_xp_bonus_max + 0.001 and Progress.wick_gap_mult(4, 3) > 1.0, "a small, capped bonus for foes above the keeper")
			check(is_equal_approx(Progress.kill_wick(4, 5, 5), 4.0 * (1.0 + 4.0 * Tuning.kl_xp_level_growth)), "higher-level foes are worth more (+%d%% a level)" % roundi(Tuning.kl_xp_level_growth * 100.0))
			var pk: EnemyPack = get_tree().get_nodes_in_group("enemy_pack")[0]
			check(pk.level >= 1, "packs have a level from the table (%s: Lv %d)" % [pk.id, pk.level])
			var named := Wickling.new()
			named.level = 2
			wl.add_child(named)
			check(named.bar_name() == "Wickling Lv 2", "the name bar shows the level (%s)" % named.bar_name())
			named.queue_free()
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
