extends Node
## Upgrades found in the valley: a keeper's satchel (carry more scrap; bag slots in M3) and a lamp glass in each
## region. M1b: a lamp glass makes the hand lamp reach 12 px further and hold 0.1 more charge (GAME_PLAN §5; its
## old "dims slower" and "wards longer" went with the dimming and the ward). Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_upgrades.tscn

const IDS := {
	"satchel_hollow": [FogGrid.R_HOLLOW, "carry"], "lampglass_hollow": [FogGrid.R_HOLLOW, "lamp"],
	"satchel_marsh": [FogGrid.R_MARSH, "carry"], "lampglass_marsh": [FogGrid.R_MARSH, "lamp"],
	"satchel_ridge": [FogGrid.R_RIDGE, "carry"], "lampglass_ridge": [FogGrid.R_RIDGE, "lamp"],
}

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var radius_before := 0.0

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
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when a note pauses the world
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
	SaveGame.path = "user://test_upgrades_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _find(id: String) -> Landmark:
	for m in get_tree().get_nodes_in_group("landmark"):
		if m.id == id:
			return m
	return null

## Walking distance in tiles from the hut to every tile you can reach (rock blocks; marsh is wadeable).
func _reach() -> Dictionary:
	var start := fog.tile_of(main.start)
	var dist := {start: 0}
	var q: Array[Vector2i] = [start]
	while not q.is_empty():
		var t: Vector2i = q.pop_front()
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n: Vector2i = t + d
			if fog.in_bounds(n) and fog.solid[fog.idx(n)] == 0 and not dist.has(n):
				dist[n] = dist[t] + 1
				q.append(n)
	return dist

func _take(id: String) -> void:
	_find(id).activate()
	main.get_node("NoteReader").close()

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			var reach := _reach()
			var others := get_tree().get_nodes_in_group("landmark").filter(func(m): return not IDS.has(m.id))
			for id in IDS:
				var m := _find(id)
				if m == null:
					check(false, "%s is placed" % id)
					continue
				var t := fog.tile_of(m.global_position)
				var near := 999.0
				for o in others:
					near = minf(near, m.global_position.distance_to(o.global_position) / FogGrid.TILE)
				check(fog.region_at(m.global_position) == IDS[id][0] and m.upgrade == IDS[id][1], "%s lies in its region (%s)" % [id, str(t)])
				check(reach.has(t) and int(reach[t]) >= 20, "%s can be walked to, off the beaten path (%s tiles from the hut)" % [id, str(reach.get(t, -1))])
				check(near >= 6.0, "%s isn't crowded by other landmarks (%.1f tiles)" % [id, near])
			# Carry: a satchel lets you carry 10 more scrap, once.
			check(Inventory.carry_limit == Tuning.carry_base, "you start able to carry %d scrap" % Tuning.carry_base)
			var wp = main.get_node("FogLayer/WorldPrompt")
			InputHint.pad = false
			check(wp.lines_for(_find("satchel_hollow"))[0][1] == "Take", "an upgrade's prompt says 'Take'")
			_find("satchel_hollow").activate()
			check(get_tree().paused, "taking one opens its note (and pauses)")
			check(main.get_node("NoteReader").body_label.text.contains("You can carry %d scrap now." % Inventory.carry_limit), "its note says how much scrap you can carry now")
			main.get_node("NoteReader").close()
			check(Inventory.carry_limit == Tuning.carry_base + Tuning.carry_upgrade_step, "a keeper's satchel: carry %d scrap" % Inventory.carry_limit)
			Inventory.counts["scrap"] = 0
			check(Inventory.add("scrap", 100) == Inventory.carry_limit, "taking scrap now stops at the new limit")
			Inventory.counts["scrap"] = 0
			_take("satchel_hollow")
			check(Inventory.carry_limit == Tuning.carry_base + Tuning.carry_upgrade_step, "reading it again gives nothing more")
			check(wp.lines_for(_find("satchel_hollow"))[0][1] == "Look again" and _find("satchel_hollow").is_taken(), "and its prompt says 'Look again'")
			# Lamp: a lamp glass makes the hand lamp reach further and hold more charge (M1b).
			check(is_equal_approx(Progress.charge_max(), 1.0), "lamp charge runs to 1.0 at first")
			player.lamp_charge = 1.0
			radius_before = player.get_light_radius()
			_find("lampglass_hollow").activate()
			check(main.get_node("NoteReader").body_label.text.contains("Your hand lamp reaches further and holds more charge."), "its note says what it does (no dimming or ward)")
			main.get_node("NoteReader").close()
			check(is_equal_approx(Progress.charge_max(), 1.0 + Tuning.lamp_upgrade_charge), "a lamp glass: +%.1f max charge (%.1f)" % [Tuning.lamp_upgrade_charge, Progress.charge_max()])
			player.lamp_charge = Progress.charge_max()
			check(is_equal_approx(player.get_light_radius(), radius_before + Tuning.lamp_upgrade_radius), "and the hand lamp reaches further at full charge (%.0f -> %.0f px)" % [radius_before, player.get_light_radius()])
			player.lamp_charge = 1.0
			player.drink()
			check(is_equal_approx(player.lamp_charge, minf(Progress.charge_max(), 1.0 + Tuning.kl_flask_charge)), "charge can fill past 1.0 now, up to the new max (%.2f)" % player.lamp_charge)
			player.lamp_charge = Progress.charge_max()
			player.update_hand_lamp(1.0)
			check(player.lamp_charge <= Progress.charge_max() + 0.0001, "and never past it")
			# Everything found, then save.
			for id in ["satchel_marsh", "satchel_ridge", "lampglass_marsh", "lampglass_ridge"]:
				_take(id)
			check(Inventory.carry_limit == Tuning.carry_base + 3 * Tuning.carry_upgrade_step and Progress.upgrade_level("lamp") == 3, "all three satchels and glasses found (carry %d, lamp level %d)" % [Inventory.carry_limit, Progress.upgrade_level("lamp")])
			check(is_equal_approx(Progress.charge_max(), 1.0 + 3.0 * Tuning.lamp_upgrade_charge), "three glasses: max charge %.1f" % Progress.charge_max())
			player.lamp_charge = Progress.charge_max()
			check(SaveGame.save(main), "save with every upgrade")
			Progress.upgrades = {}
			Progress.apply_upgrades()
			main.queue_free()
		6:
			main = load("res://scenes/main/main.tscn").instantiate()
			add_child(main)
		10:
			fog = main.fog
			check(Progress.upgrade_level("carry") == 3 and Progress.upgrade_level("lamp") == 3, "upgrades come back after loading")
			check(Inventory.carry_limit == Tuning.carry_base + 3 * Tuning.carry_upgrade_step, "and so does the carry limit (%d)" % Inventory.carry_limit)
			check(_find("satchel_ridge").is_taken() and _find("satchel_ridge").is_read(), "taken upgrades stay taken")
			check(is_equal_approx(main.player.lamp_charge, Progress.charge_max()) and main.player.lamp_charge > 1.0, "a charge above 1.0 is kept by the save (%.2f)" % main.player.lamp_charge)
			# A new game starts over.
			Progress.reset()
			check(Inventory.carry_limit == Tuning.carry_base and Progress.upgrade_level("lamp") == 0 and is_equal_approx(Progress.charge_max(), 1.0), "a new game starts with no upgrades")
			SaveGame.delete_save()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
