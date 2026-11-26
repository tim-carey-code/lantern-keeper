extends Node
## Checks for Wicklings, the warding glow and warmth. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_threats.tscn

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var spawner: Node
var lamp: Lantern
var w_snuff: Wickling
var w_core: Wickling
var w_chase: Wickling
var lamp_fuel_before := 0.0

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
	strip_real_input()
	SaveGame.path = "user://test_ignore_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			spawner = main.get_node("FogLayer/Wicklings")
			lamp = main.get_node("Lanterns").get_child(0)
			main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			Tuning.lantern_burn_per_sec = 0.0   # isolate Wickling drain
			check(spawner.count() == 0, "no Wicklings during the opening grace period")
			var w = spawner.spawn_near_player()
			check(w != null and fog.density_at(w.global_position) >= 0.85, "Wicklings spawn in deep fog, away from the keeper")
			if w:
				w.queue_free()
		60:
			# One Wickling at the rim of the starting lantern's light, one dropped into its bright core.
			var r: float = lamp.get_light_radius()
			w_snuff = spawner.spawn_at(lamp.global_position + Vector2(0, r * 0.85))
			w_snuff.target = lamp
			w_snuff.state = Wickling.State.SEEK_LANTERN
			w_core = spawner.spawn_at(lamp.global_position + Vector2(10, 0))
			lamp_fuel_before = lamp.fuel
			player.position = main.start + Vector2(-500, 0)   # far away, in the dark
		300:
			check(lamp.fuel < lamp_fuel_before - 5.0, "a Wickling at the rim drains the lantern (%.0f -> %.0f)" % [lamp_fuel_before, lamp.fuel])
			check(not is_instance_valid(w_core), "a Wickling in a lantern's bright core burns away")
			check(is_instance_valid(w_snuff) and w_snuff.light_level_at(w_snuff.global_position) < Tuning.wick_core, "Wicklings keep to the rim, out of the core")
			# Warding glow: hold to burn and push back Wicklings; spends lamp charge, not fuel.
			player.position = w_snuff.global_position + Vector2(-6, 4)   # point blank
			player.lamp_charge = 1.0
			Inventory.counts["fuel"] = 3
			Input.action_press("flare")
		330:
			check(player.warding, "holding the button swells the warding glow")
			check(Inventory.get_count("fuel") == 3, "warding never spends carried fuel")
			check(player.lamp_charge < 1.0, "warding spends hand-lamp charge")
		355:
			check(not is_instance_valid(w_snuff), "the ward burns away a Wickling right on top of you in under a second")
			var embers := get_tree().get_nodes_in_group("ember")
			check(embers.size() >= 1, "burned Wicklings leave embers (%d)" % embers.size())
			check(embers.all(func(e): return e.get_parent() == spawner), "drops sit on the fog layer so they glow through the dark")
			# Walk onto the nearest ember to collect it.
			var best = null
			for e in embers:
				if best == null or e.global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
					best = e
			if best:
				player.position = best.global_position
		360:
			check(Inventory.get_count("fuel") == 3 + Tuning.ember_fuel, "collecting an ember gives fuel")
			# Scrap drops: force the chance to 100% and burn one more.
			Tuning.wick_scrap_chance = 1.0
			var extra = spawner.spawn_at(player.global_position + Vector2(200, 0))
			extra.hurt(99.0)
			player.lamp_charge = 0.0
		362:
			var scraps := get_tree().get_nodes_in_group("ember").filter(func(e): return e.kind == "scrap")
			check(scraps.size() >= 1, "a burned Wickling can also drop scrap (%d)" % scraps.size())
		365:
			check(not player.warding, "an empty hand lamp can't ward: go back to the light")
			Input.action_release("flare")
		462:
			check(not player.warding, "releasing the button ends the ward")
			Inventory.counts["fuel"] = 0
			Tuning.wick_scrap_chance = 0.35
			for e in get_tree().get_nodes_in_group("ember"):
				e.queue_free()   # leftover drops would be magnet-collected after waking
			# Chase and chill in the dark.
			player.position = main.start + Vector2(-480, 0)
			player.warmth = Tuning.warmth_max
			w_chase = spawner.spawn_at(player.global_position + Vector2(10, 0))
			w_chase.state = Wickling.State.CHASE
			Inventory.counts["fuel"] = 10
			Inventory.counts["scrap"] = 10
		490:
			check(player.warmth < Tuning.warmth_max, "a Wickling's touch drains warmth (%.0f)" % player.warmth)
			player.warmth = 1.0
		500:
			check(player.faints == 1, "out of warmth: the keeper faints (no game over)")
			check(player.global_position.distance_to(lamp.global_position) < 60.0, "and wakes beside the nearest lit lantern")
			check(Inventory.get_count("fuel") == 5 and Inventory.get_count("scrap") == 5, "half of what was carried is dropped")
			var piles := get_tree().get_nodes_in_group("resource").filter(func(r): return r.label.begins_with("Dropped"))
			check(piles.size() == 2, "dropped resources wait where the keeper fell")
			check(player.warmth > 0.0, "warmth partly restored on waking")
			main.get_node("NoteReader").close()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
