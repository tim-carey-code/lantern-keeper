extends Node
## Save/load round trip (version 6, M1b: no fuel or glass), and older files: a version 5 file (the owner's save
## is v5) migrates to v6 with fuel, glass and tending dropped cleanly and progress, level, the bar and flasks
## kept; a version 4 file migrates through v5. Every old file here is test-only, written next to the test save. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_save.tscn

var main: Node
var frame := 0
var fails := 0
var old_main_id := 0
var lamp_pos := Vector2.ZERO
var keeper_pos := Vector2.ZERO
var res_pos := Vector2.ZERO
var seen_before := 0
var piles_before := 0

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func strip_real_input() -> void:
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)

func _new_main() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	Progress.unlock("post")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when a note or menu pauses the world
	strip_real_input()
	Tuning.wick_enabled = false
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
	Settings.path = "user://test_save_settings.cfg"   # never the owner's settings
	Settings.use_defaults()
	SaveGame.path = "user://test_save.json"
	SaveGame.delete_save()
	_new_main()

## Test-only files next to the test save (never the owner's slots or settings).
const V4_PATH := "user://test_save_v4.json"
const V5_PATH := "user://test_save_v5.json"
const V6_PATH := "user://test_save_v6.json"
const V7_PATH := "user://test_save_v7.json"
const BAD_BAR_PATH := "user://test_save_bad_bar.json"

func _read_json(path: String) -> Dictionary:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if typeof(data) == TYPE_DICTIONARY else {}

func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

## Loads `data` from a test-only file into the running world, then points SaveGame back at the test save.
func _load_file(path: String, data: Dictionary) -> bool:
	_write_json(path, data)
	var keep := SaveGame.path
	SaveGame.path = path
	Progress.reset()
	var ok := SaveGame.load_into(main)
	SaveGame.delete_save()
	SaveGame.path = keep
	return ok

## A version 4 save *file* (the shape before M1a: no bar, no Lance flag, no flasks) loads and migrates, at level 2
## and at level 1; a saved bar with things it may not hold falls back to the default bar slot by slot.
func _old_and_bad_files() -> void:
	var v8 := _read_json(SaveGame.path)
	check(int(v8.get("version", 0)) == SaveGame.VERSION and SaveGame.VERSION == 8, "the test save is version 8 (%d)" % SaveGame.VERSION)
	check(v8.progress.has("picks") and v8.progress.has("lines") and v8.progress.has("respec_at") and not v8.progress.has("combat_upgrades"), "M2: it saves picks, carried lines and the respec spot, no cards")
	_v7_file(v8)
	var v6 := _as_v7(v8)   # the older files below are built from a version 7 shape (cards, not picks)
	var text := FileAccess.get_file_as_string(SaveGame.path)
	check(not text.contains("fuel") and not text.contains("glass") and not text.contains("regrow"), "a version 6 save has no fuel, glass or regrowth in it")
	var v5 := _v5_from(v6)
	_v5_file(v5)
	_v6_file(v6)
	var v4: Dictionary = _v5_from(v6)
	v4["version"] = 4
	v4["progress"].erase("bar")
	v4["progress"].erase("lance_given")
	v4["player"].erase("flasks")
	v4["progress"]["level"] = 2
	v4["progress"]["wick"] = 7
	v4["player"]["warmth"] = 55.0
	check(_load_file(V4_PATH, v4), "a version 4 save file loads")
	check(Progress.bar == {"skill_1": "lampfire", "skill_2": "fireglobe", "skill_3": "lance", "skill_4": ""} and Progress.lance_given, "a level 2 v4 file gets the default bar with Lance on LB (%s)" % str(Progress.bar))
	check(main.player.flasks == Tuning.kl_flask_max and absf(main.player.warmth - 55.0) < 0.5, "with full flasks, and its keeper as saved (flasks %d, warmth %.0f)" % [main.player.flasks, main.player.warmth])
	check(Progress.level == 2 and Progress.wick == 7 and Inventory.get_count("scrap") == 7 and Progress.notes_read.has("ledger") and Progress.has_pick("long_throw"), "and its world state: level, wick, inventory, notes, upgrades")
	check(Inventory.counts.keys() == ["scrap"], "a v4 file goes on through v5 to v6: no fuel or glass (%s)" % str(Inventory.counts))
	check(not FileAccess.file_exists(V4_PATH), "the v4 test file is cleaned up")
	v4["progress"]["level"] = 1
	v4["progress"]["wick"] = 0
	check(_load_file(V4_PATH, v4), "a level 1 version 4 save file loads")
	check(Progress.level == 1 and Progress.bar == Progress.default_bar() and not Progress.lance_given and not Progress.knows("lance"), "level 1: the default bar with the Beam on LB, and no Lance (%s)" % str(Progress.bar))
	check(main.player.flasks == Tuning.kl_flask_max, "and full flasks")
	_beam_hint_after_migration(v4)
	# A v6 file whose bar holds what it may not.
	var bad: Dictionary = v6.duplicate(true)
	bad["progress"]["level"] = 1
	bad["progress"]["lance_given"] = false
	bad["progress"]["bar"] = {"skill_1": "fireglobe", "skill_2": "hearth_ring", "skill_3": "lance", "skill_4": "no_such_skill"}
	check(_load_file(BAD_BAR_PATH, bad), "a save with a bad action bar still loads")
	check(Progress.bar == Progress.default_bar(), "each bad slot falls back to the default bar: Lampfire on 1, Fireglobe, the Beam, empty (%s)" % str(Progress.bar))
	bad["progress"]["bar"] = {"skill_1": "lampfire", "skill_2": "beam", "skill_3": 7, "skill_4": "fireglobe"}
	check(_load_file(BAD_BAR_PATH, bad), "and another")
	check(Progress.bar == {"skill_1": "lampfire", "skill_2": "beam", "skill_3": "", "skill_4": "fireglobe"}, "good slots stay, a bad slot whose default is already used goes empty; an aimed skill on slot 4 stays (M1c: Y takes any skill) (%s)" % str(Progress.bar))
	bad["progress"]["bar"] = {"skill_1": "lampfire", "skill_2": "lampfire", "skill_3": "fireglobe", "skill_4": "hearth_ring"}
	_load_file(BAD_BAR_PATH, bad)
	check(Progress.bar == {"skill_1": "lampfire", "skill_2": "fireglobe", "skill_3": "beam", "skill_4": "hearth_ring"}, "a skill twice keeps only the first (the later slot takes its default); a self-cast on slot 4 stays (%s)" % str(Progress.bar))
	bad["progress"].erase("bar")
	_load_file(BAD_BAR_PATH, bad)
	check(Progress.bar == Progress.default_bar(), "a v6 file with no bar gets the default one")
	check(not FileAccess.file_exists(BAD_BAR_PATH), "the bad-bar test file is cleaned up")
	# Put the round-trip state back for the pause-menu checks that follow.
	Progress.reset()
	SaveGame.load_into(main)

## A version 8 save in the version 7 shape: cards (combat_upgrades) instead of picks.
func _as_v7(v8: Dictionary) -> Dictionary:
	var v7: Dictionary = v8.duplicate(true)
	v7["version"] = 7
	var p: Dictionary = v7["progress"]
	p["combat_upgrades"] = (p.get("picks", []) as Array) + (p.get("lines", []) as Array)
	p.erase("picks")
	p.erase("lines")
	p.erase("respec_at")
	return v7

## M2: a version 7 file (the owner's save is v7) migrates to v8 (GAME_PLAN §4.3). Its level gives the points (one a level
## over 1); each card becomes its pick if that tier is open and free, the first card of two in one tier wins, and the
## rest stay as unspent points; Kindled kills, Hot core and Lee are carried as lines (gear lines in M3).
func _v7_file(v8: Dictionary) -> void:
	var v7 := _as_v7(v8)
	v7["progress"]["level"] = 7
	v7["progress"]["lance_given"] = true
	v7["progress"]["combat_upgrades"] = ["lingering_burn", "catching", "steady_hand", "long_throw", "heavy_flare", "kindled_kills", "hot_core", "spill", "tight_focus", "deep_tank"]
	var cleared: Dictionary = v7["progress"].get("cleared", {})
	cleared.erase("ashbrood_hollow")
	v7["progress"]["cleared"] = cleared
	v7["progress"]["settled"] = []
	check(_load_file(V7_PATH, v7), "a version 7 save file with ten cards loads")
	var want := ["lingering_burn", "steady_hand", "tight_focus", "heavy_ring", "spill"]
	check(Progress.pick_list() == want, "its cards become picks where their tier is open and free (%s)" % str(Progress.pick_list()))
	check(not Progress.has_pick("catching") and not Progress.has_pick("long_throw") and not Progress.has_pick("deep_tank"), "Catching waits for tier 3 (no Ashbrood kill yet); Long throw and Deep tank shared a tier with an earlier card")
	check(Progress.points_total() == 6 and Progress.skill_points() == 1, "a level-7 keeper has 6 points: 5 in picks, 1 to spend (%d)" % Progress.skill_points())
	check(Progress.lines == ["kindled_kills", "hot_core"], "Kindled kills and Hot core are carried as lines (%s)" % str(Progress.lines))
	check(not FileAccess.file_exists(V7_PATH), "the v7 test file is cleaned up")
	v7["progress"]["cleared"]["ashbrood_hollow"] = true
	check(_load_file(V7_PATH, v7), "the same save past the Ashbrood loads")
	check(Progress.has_pick("catching") and Progress.skill_points() == 0, "and Catching takes tier 3 (%s)" % str(Progress.pick_list()))
	var low: Dictionary = v7.duplicate(true)
	low["progress"]["level"] = 2
	low["progress"]["cleared"].erase("ashbrood_hollow")
	low["progress"]["combat_upgrades"] = ["long_throw", "second_step"]
	check(_load_file(V7_PATH, low), "a level-2 v7 save with two cards (one from a later level-up) loads")
	check(Progress.pick_list() == ["long_throw"] and Progress.skill_points() == 0, "it keeps one pick for its one point (%s)" % str(Progress.pick_list()))
	Progress.reset()

## A version 5 file as M1a wrote it, built from this world's v6 save: fuel and glass carried, fuel fed to a WayLamp,
## every lantern with a tank, fuel spots, peat, glass shards and the woodpile, untaken fuel and glass caches, a
## dropped fuel pile, an empty scrap pile, a keeper at level 7 of the old curve with a bar and 2 flasks.
func _v5_from(v6: Dictionary) -> Dictionary:
	var v5: Dictionary = v6.duplicate(true)
	v5["version"] = 5
	v5["inventory"] = {"fuel": 12, "scrap": 7, "glass": 3}
	v5["progress"]["waylamp_fuel"] = {"hollow": 9}
	var lamps := []
	for l in v6["lanterns"]:
		if Vector2(l["x"], l["y"]).distance_to(main.rim_lamp_pos) < 8.0:
			continue   # a real version 5 save never had the rim lamp (M1c)
		var old: Dictionary = (l as Dictionary).duplicate()
		old.erase("cold")
		old["fuel"] = 0.0 if bool(l.get("cold", false)) else 77.0
		lamps.append(old)
	var c: Vector2 = main.start + Vector2(160, 160)
	lamps.append({"kind": "post", "x": c.x, "y": c.y, "fuel": 0.0, "dir": 0})   # a planted lamp that had burned out
	v5["lanterns"] = lamps
	var piles := []
	for r in v6["resources"]:
		var old: Dictionary = (r as Dictionary).duplicate()
		old["max"] = int(r["amount"])
		old["regrow"] = 75.0
		old["always"] = false
		piles.append(old)
	piles.append({"kind": "fuel", "label": "", "x": 300.0, "y": 300.0, "amount": 5, "max": 8, "regrow": 60.0, "always": false})
	piles.append({"kind": "fuel", "label": "Peat", "x": 320.0, "y": 300.0, "amount": 5, "max": 9, "regrow": 45.0, "always": false})
	piles.append({"kind": "glass", "label": "", "x": 340.0, "y": 300.0, "amount": 3, "max": 4, "regrow": 120.0, "always": false})
	piles.append({"kind": "fuel", "label": "", "x": 360.0, "y": 300.0, "amount": 3, "max": 5, "regrow": 10.0, "always": true})   # the woodpile
	piles.append({"kind": "fuel", "label": "Old cache", "x": 380.0, "y": 300.0, "amount": 10, "max": 10, "regrow": 1.0e9, "always": false})
	piles.append({"kind": "glass", "label": "Old cache", "x": 400.0, "y": 300.0, "amount": 6, "max": 6, "regrow": 1.0e9, "always": false})
	piles.append({"kind": "fuel", "label": "Dropped fuel", "x": 420.0, "y": 300.0, "amount": 4, "max": 4, "regrow": 1.0e9, "always": false})
	piles.append({"kind": "scrap", "label": "Dropped scrap", "x": 440.0, "y": 300.0, "amount": 3, "max": 3, "regrow": 1.0e9, "always": false})
	piles.append({"kind": "scrap", "label": "", "x": 460.0, "y": 300.0, "amount": 0, "max": 6, "regrow": 75.0, "always": false})
	v5["resources"] = piles
	v5["progress"]["level"] = 7
	v5["progress"]["wick"] = 30
	v5["progress"]["lance_given"] = true
	v5["progress"]["bar"] = {"skill_1": "lampfire", "skill_2": "fireglobe", "skill_3": "beam", "skill_4": "hearth_ring"}
	v5["player"]["flasks"] = 2
	v5["player"]["lamp_charge"] = 1.0
	return v5

## The v6 -> v7 migration through a real file (M1c): a v6 save never had the rim lamp; it comes back cold, to light
## by touch. A v7 save keeps the rim lamp lit once it is lit.
func _v6_file(v7: Dictionary) -> void:
	var v6: Dictionary = v7.duplicate(true)
	v6["version"] = 6
	var kept := []
	for l in v6["lanterns"]:
		if Vector2(l["x"], l["y"]).distance_to(main.rim_lamp_pos) >= 8.0:
			kept.append(l)
	v6["lanterns"] = kept
	check(main.rim_lamp_pos != Vector2.INF and kept.size() == v7["lanterns"].size() - 1, "a v6 file has no rim lamp (%d of %d lanterns)" % [kept.size(), v7["lanterns"].size()])
	check(_load_file(V6_PATH, v6), "a version 6 save file loads")
	var rim := get_tree().get_nodes_in_group("lantern").filter(func(x): return x.position.distance_to(main.rim_lamp_pos) < 8.0)
	check(rim.size() == 1 and rim[0].old and rim[0].cold and not rim[0].can_pick_up(), "the bowl's rim lamp is put back, cold, an old lamp (lit by touch)")
	# A v6 save with a planted Mirror Post on that tile: its scrap comes back, and the rim lamp still stands there.
	var crowded: Dictionary = v6.duplicate(true)
	crowded["lanterns"].append({"kind": "mirror", "x": main.rim_lamp_pos.x, "y": main.rim_lamp_pos.y, "cold": false, "dir": 0})
	var scrap_saved := int(crowded["inventory"].get("scrap", 0))
	check(_load_file(V6_PATH, crowded), "a version 6 save with a lamp planted on the rim lamp's tile loads")
	rim = get_tree().get_nodes_in_group("lantern").filter(func(x): return x.position.distance_to(main.rim_lamp_pos) < 8.0)
	check(rim.size() == 1 and rim[0].old and rim[0].kind == "post", "the rim lamp takes the tile")
	check(Inventory.get_count("scrap") == scrap_saved + Tuning.mirror_cost_scrap, "and the planted lamp's %d scrap comes back (%d -> %d)" % [Tuning.mirror_cost_scrap, scrap_saved, Inventory.get_count("scrap")])
	var lit7: Dictionary = v7.duplicate(true)
	for l in lit7["lanterns"]:
		if Vector2(l["x"], l["y"]).distance_to(main.rim_lamp_pos) < 8.0:
			l["cold"] = false
	check(_load_file(V6_PATH, lit7), "a version 7 save with the rim lamp lit loads")
	rim = get_tree().get_nodes_in_group("lantern").filter(func(x): return x.position.distance_to(main.rim_lamp_pos) < 8.0)
	check(rim.size() == 1 and rim[0].is_lit(), "and the rim lamp stays lit")

## The v5 -> v6 migration through a real file (test-only, next to the test save; never the owner's slots).
func _v5_file(v5: Dictionary) -> void:
	check(_load_file(V5_PATH, v5), "a version 5 save file loads (the owner's current save is v5)")
	check(not FileAccess.file_exists(V5_PATH), "the v5 test file is cleaned up")
	check(Progress.level == 7 and Progress.wick == 30 and Progress.lance_given, "it keeps the level and wick (L%d, %d)" % [Progress.level, Progress.wick])
	check(Progress.bar == {"skill_1": "lampfire", "skill_2": "fireglobe", "skill_3": "beam", "skill_4": "hearth_ring"}, "and the action bar as it was (%s)" % str(Progress.bar))
	check(main.player.flasks == 2, "and the flasks (%d)" % main.player.flasks)
	check(Progress.notes_read.has("ledger") and Progress.has_pick("long_throw") and Progress.cleared.has("nest_hollow_1") and Progress.is_unlocked("reservoir"), "and progress: notes, upgrades, cleared fights, unlocks")
	check(Inventory.counts == {"scrap": 7}, "fuel and glass leave the inventory; scrap stays (%s)" % str(Inventory.counts))
	check(not ("waylamp_fuel" in Progress), "nothing remembers fuel fed to a WayLamp")
	var lamps := get_tree().get_nodes_in_group("lantern")
	var res := lamps.filter(func(x): return x.position == lamp_pos)
	check(lamps.size() == 5 and res.size() == 1 and res[0].kind == "reservoir" and res[0].is_lit(), "every lantern comes back, lit, and the bowl's rim lamp it never had is put back (%d)" % lamps.size())
	var hut := lamps.filter(func(x): return x.position.distance_to(main.start_lantern_pos) < 8.0)
	var way := lamps.filter(func(x): return x.position.distance_to(main.waypost_lantern_pos) < 8.0)
	check(hut.size() == 1 and hut[0].old and hut[0].is_lit(), "a fuelled old lamp comes back lit")
	check(way.size() == 1 and way[0].old and way[0].can_light_by_touch(), "an empty old lamp comes back cold, to be lit by touch")
	var burned := lamps.filter(func(x): return x.position.distance_to(main.start + Vector2(160, 160)) < 20.0)
	check(burned.size() == 1 and burned[0].is_lit() and not burned[0].old, "a planted lamp that had burned out comes back lit (lamps never burn now)")
	var piles := get_tree().get_nodes_in_group("resource")
	check(piles.all(func(r): return r.kind == "scrap" and r.amount > 0), "only scrap piles with something in them come back")
	var caches := piles.filter(func(r): return r.label == "Old cache" and r.position.y == 300.0)
	check(caches.size() == 2 and caches.any(func(r): return r.amount == 10) and caches.any(func(r): return r.amount == 6), "untaken fuel and glass caches become scrap caches (%d)" % caches.size())
	check(piles.filter(func(r): return r.position.y == 300.0).size() == 3, "fuel spots, peat, glass, the woodpile, dropped fuel and empty piles are gone; dropped scrap stays")
	check(main.player.lamp_charge <= Progress.charge_max() + 0.0001, "the hand lamp's charge is within its max")

## The owner's case (playtest 2026-11-27): a version 4 save at level 7 migrates with Lance on LB, and nothing said
## where the Beam went. The first check of the world afterwards shows a one-time hint, with the Skills button.
func _beam_hint_after_migration(v4_base: Dictionary) -> void:
	var v4: Dictionary = v4_base.duplicate(true)
	v4["progress"]["level"] = 7
	v4["progress"]["wick"] = 0
	v4["story"]["tips"] = []   # a v4 save never saw this hint
	check(_load_file(V4_PATH, v4), "a level 7 version 4 save file loads")
	check(Progress.bar["skill_3"] == "lance" and Progress.slot_of("beam") == "" and not Story.tips_seen.has("beam_off_bar"), "Lance is on LB and the Beam is off the bar (%s)" % str(Progress.bar))
	var shown: Array[String] = []
	var catch := func(t: String) -> void: shown.append(t)
	Story.tip_shown.connect(catch)
	for pad in [true, false]:
		InputHint.pad = pad
		var want := "The Beam is in your pack, on the Skills tab (%s)." % InputHint.key("skills")
		check(Story.tip_text("beam_off_bar") == want, "the hint names the Skills button for the device in use (%s)" % Story.tip_text("beam_off_bar"))
	InputHint.pad = true
	Story.update(main)
	var hint := "The Beam is in your pack, on the Skills tab (D-pad down)."
	check(shown.count(hint) == 1, "after the migration, the first check shows the Beam hint once (%s)" % str(shown))
	Story.update(main)
	check(shown.count(hint) == 1 and Story.to_dict()["tips"].has("beam_off_bar"), "never again, and it is saved as seen")
	InputHint.pad = false
	# Level 1: the Beam is on the bar, so no hint.
	v4["progress"]["level"] = 1
	check(_load_file(V4_PATH, v4), "a level 1 version 4 save file loads again")
	shown.clear()
	Story.update(main)
	check(not shown.any(func(t): return t.begins_with("The Beam is in")), "at level 1, with the Beam on LB, there is no hint")
	Story.tip_shown.disconnect(catch)

## The controller's A, as our "interact" action.
func _press_a() -> void:
	var ev := InputEventAction.new()
	ev.action = "interact"
	ev.pressed = true
	Input.parse_input_event(ev)

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			check(not main.loaded_save, "a fresh start has no save to load")
			var v4 := {"version": 4, "progress": {"level": 2}, "player": {"warmth": 73.0}}
			var v6: Dictionary = SaveGame.migrate_data(v4)
			check(v6.version == 8 and v6.progress.bar.skill_3 == "lance" and v6.progress.lance_given, "version 4 saves migrate (through v5, v6 and v7) to v8 with Lance on LB at level 2")
			check(v6.player.flasks == Tuning.kl_flask_max and v6.player.warmth == 73.0, "migration fills flasks and preserves the old keeper state")
			var v5 := {"version": 5, "inventory": {"fuel": 3, "scrap": 4, "glass": 1}, "progress": {"level": 6, "waylamp_fuel": {"marsh": 2}},
				"lanterns": [{"kind": "post", "x": 1.0, "y": 2.0, "fuel": 0.0, "dir": 0}, {"kind": "mirror", "x": 5.0, "y": 6.0, "fuel": 1.0, "dir": 3}],
				"resources": [{"kind": "fuel", "label": "", "x": 0.0, "y": 0.0, "amount": 4, "max": 8, "regrow": 60.0, "always": false}], "player": {"flasks": 1}}
			var m: Dictionary = SaveGame.migrate_data(v5)
			check(m.version == 8 and m.inventory == {"scrap": 4} and not m.progress.has("waylamp_fuel") and m.progress.level == 6 and m.player.flasks == 1, "a v5 save migrates to v8: fuel and glass dropped, progress kept")
			var m6: Dictionary = SaveGame.migrate_data({"version": 6, "lanterns": [{"kind": "post", "x": 1.0, "y": 2.0, "cold": true, "dir": 0}], "progress": {"level": 3}})
			check(m6.version == 8 and m6.lanterns.size() == 1 and m6.lanterns[0].cold and m6.progress.level == 3, "a v6 save migrates to v8 with its lamps unchanged (M1c)")
			var m7: Dictionary = SaveGame.migrate_data({"version": 7, "progress": {"level": 4, "combat_upgrades": ["heavy_flare", "lee", "lee", "no_such_card"]}})
			check(m7.version == 8 and m7.progress.picks == ["heavy_ring"] and m7.progress.lines == ["lee"] and not m7.progress.has("combat_upgrades"), "a v7 save's cards map to picks and lines (Heavy flare is Heavy ring; Lee is carried; unknown cards go) (%s)" % str(m7.progress))
			check(m.lanterns.size() == 2 and m.lanterns.all(func(l): return not l.has("fuel")) and m.lanterns[0].cold and m.lanterns[1].dir == 3 and m.resources.is_empty(), "lanterns lose their tanks (an empty one is marked cold); fuel spots go")
		120:
			# Change everything a save should keep.
			var fog: FogGrid = main.fog
			lamp_pos = fog.tile_center(fog.tile_of(main.start + Vector2(-128, 96)))
			var l := Lantern.new()
			l.kind = "reservoir"
			l.position = lamp_pos
			main.get_node("Lanterns").add_child(l)
			for old in get_tree().get_nodes_in_group("lantern"):
				if old.global_position.distance_to(main.start_lantern_pos) < 8.0:
					old.light_by_touch()   # the hut's old lamp lit; the north path's stays cold
			Inventory.counts["scrap"] = 7
			Progress.unlock("reservoir")
			Progress.selected = "reservoir"
			Progress.wick = 7
			Progress.level = 2
			Progress.bar = {"skill_1": "lampfire", "skill_2": "fireglobe", "skill_3": "lance", "skill_4": ""}
			Progress.lance_given = true
			main.player.flasks = 2
			Progress.cleared["nest_hollow_1"] = true
			Progress.set_picks(["long_throw"])
			var wick_drop := WickDrop.new()
			wick_drop.amount = 4
			wick_drop.position = main.start + Vector2(160, 40)
			main.get_node("FogLayer/Wicklings").add_child(wick_drop)
			Progress.notes_read["ledger"] = true
			var r: ResourceNode = main.get_node("Resources").get_child(5)
			res_pos = r.position
			r.amount = 1
			var taken: ResourceNode = main.get_node("Resources").get_child(6)
			taken.amount = 0   # an emptied pile stays gone
			taken.remove_from_group("resource")
			keeper_pos = main.start + Vector2(64, 32)
			main.player.global_position = keeper_pos
			main.player.warmth = 42.0
			main.player.lamp_charge = 0.5
			seen_before = fog.remembered.count(1)
			piles_before = get_tree().get_nodes_in_group("resource").size()
			check(SaveGame.save(main), "saving writes the file")
			check(SaveGame.has_save(), "the save file exists")
		122:
			# Throw the world away and start again: it should come back from the save.
			main.queue_free()
			Inventory.reset()
			Progress.reset()
		124:
			_new_main()   # loads the save synchronously in _ready
			check(absf(main.player.warmth - 42.0) < 0.5 and absf(main.player.lamp_charge - 0.5) < 0.01, "warmth and hand lamp come back")
			check(main.player.flasks == 2 and Progress.bar.skill_3 == "lance", "the action bar and flask count come back")
		128:
			check(main.loaded_save, "starting the game loads the save")
			var lamps := get_tree().get_nodes_in_group("lantern")
			var found = lamps.filter(func(x): return x.position == lamp_pos)
			check(lamps.size() == 4 and found.size() == 1, "lanterns come back: the three old lamps (hut, north path, the bowl's rim) and the built one (%d)" % lamps.size())
			if found.size() == 1:
				check(found[0].kind == "reservoir" and found[0].is_lit(), "with their type, lit")
			var hut := lamps.filter(func(x): return x.position.distance_to(main.start_lantern_pos) < 8.0)
			var way := lamps.filter(func(x): return x.position.distance_to(main.waypost_lantern_pos) < 8.0)
			check(hut.size() == 1 and hut[0].old and hut[0].is_lit() and way.size() == 1 and way[0].old and not way[0].is_lit(), "the old lamps come back: the lit one lit, the cold one cold")
			check(Inventory.counts == {"scrap": 7}, "inventory comes back (%s)" % str(Inventory.counts))
			check(Progress.is_unlocked("reservoir") and Progress.selected == "reservoir", "unlocks and selected lantern come back")
			check(Progress.wick == 7 and Progress.level == 2 and Progress.cleared.has("nest_hollow_1"), "wick/level/cleared come back (%d/%d/%s)" % [Progress.wick, Progress.level, str(Progress.cleared)])
			check(Progress.has_pick("long_throw") and Progress.skill_points() == 0, "picks come back (M2)")
			var wick_drops := get_tree().get_nodes_in_group("wick_drop")
			check(wick_drops.size() == 1 and wick_drops[0].amount == 4, "dropped wick comes back (%d)" % wick_drops.size())
			check(Progress.notes_read.has("ledger"), "notes read come back")
			var rs := get_tree().get_nodes_in_group("resource").filter(func(x): return x.position == res_pos)
			check(rs.size() == 1 and rs[0].amount == 1, "what is left in a scrap pile comes back")
			check(get_tree().get_nodes_in_group("resource").size() == piles_before, "and a taken pile stays gone (%d piles)" % piles_before)
			check(main.player.global_position.distance_to(keeper_pos) < 2.0, "the keeper is where they were")
			check(main.fog.remembered.count(1) >= seen_before, "the map of what you've seen comes back")
			check(Progress.regions_seen.has(FogGrid.R_HOLLOW), "found regions come back")
			_old_and_bad_files()
			# Pause menu: the controller's A (our "interact") presses the focused button.
			var pm = main.get_node("PauseMenu")
			pm.open()
			check(pm.is_open() and get_tree().paused, "the pause menu opens and pauses the world")
			var ev := InputEventAction.new()
			ev.action = "interact"
			ev.pressed = true
			Input.parse_input_event(ev)
		130:
			var pm2 = main.get_node("PauseMenu")
			check(not pm2.is_open() and not get_tree().paused, "A / E chooses the focused option (Resume)")
			# New game with the controller: A on "New game", then A again. It reloads the game
			# scene, so make the game the current scene first (as when you play it).
			check(SaveGame.has_save(), "a save exists before the new game")
			main.reparent(get_tree().root)   # the current scene must be a child of the root
			get_tree().current_scene = main
			old_main_id = main.get_instance_id()
			pm2.open()
			pm2.buttons[2].grab_focus()
			_press_a()
		140:
			var pm3 = main.get_node("PauseMenu")
			check(pm3.buttons[2].text == "New game? Press again", "A on New game asks to confirm")
			_press_a()
		170:
			var cur := get_tree().current_scene
			check(cur != null and cur.get_instance_id() != old_main_id and cur.is_in_group("main"), "A again starts a new game: the game scene reloads")
			check(not get_tree().paused and not Tuning.ui_open, "the new game runs, unpaused")
			check(not SaveGame.has_save(), "new game deletes the save")
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
