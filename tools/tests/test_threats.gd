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
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when a note or menu pauses the world
	strip_real_input()
	Story.skip_opening = true
	SaveGame.path = "user://test_ignore_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	# This suite isolates the ambient Wickling threat; fixed Hollow encounters have their own test.
	for pack in get_tree().get_nodes_in_group("enemy_pack"):
		pack.queue_free()

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			spawner = main.get_node("FogLayer/Wicklings")
			lamp = main.get_node("Lanterns").get_child(0)
			lamp.fuel = Tuning.lantern_max_fuel   # the old lantern starts cold; light it for these checks
			main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			Tuning.lantern_burn_per_sec = 0.0   # isolate Wickling drain
			check(spawner.count() == 0, "no Wicklings during the opening grace period")
			var w = spawner.spawn_near_player()
			check(w != null and fog.density_at(w.global_position) >= 0.85, "Wicklings spawn in deep fog, away from the keeper")
			if w:
				w.queue_free()
		60:
			# One Wickling at the rim of the starting lantern's light, one dropped into its bright core.
			# Only a dying lantern (under a quarter) can be drained, so let this one burn low first.
			lamp.fuel = Tuning.lantern_max_fuel * Tuning.dying_frac - 1.0
			Tuning.wick_drain_per_sec = 2.0   # drain slowly, so it is still lit (and dying) for the ward checks
			check(lamp.is_dying(), "a lantern under a quarter of its tank is dying")
			var r: float = lamp.get_light_radius()
			w_snuff = spawner.spawn_at(lamp.global_position + Vector2(0, r * 0.85))
			w_snuff.target = lamp
			w_snuff.state = Wickling.State.SEEK_LANTERN
			w_core = spawner.spawn_at(lamp.global_position + Vector2(10, 0))
			lamp_fuel_before = lamp.fuel
			player.position = main.start + Vector2(-500, 0)   # far away, in the dark
		300:
			check(lamp.fuel < lamp_fuel_before - 5.0, "a Wickling at the rim drains the lantern (%.0f -> %.0f)" % [lamp_fuel_before, lamp.fuel])
			Tuning.wick_drain_per_sec = 5.0
			check(not is_instance_valid(w_core), "a Wickling in a lantern's bright core burns away")
			check(is_instance_valid(w_snuff) and w_snuff.light_level_at(w_snuff.global_position) < Tuning.wick_core, "Wicklings keep to the rim, out of the core")
			# (A dying lantern's light is small, so the core Wickling's ember lies close by: clear it,
			# so only the beam's kill is counted below.)
			for e in get_tree().get_nodes_in_group("ember"):
				e.queue_free()
			# The beam (Keeper's Light): hold to burn along your aim; spends lamp charge, not fuel.
			player.position = w_snuff.global_position + Vector2(-120, 4)   # in range, beyond the ember magnet
			player.lamp_charge = 1.0
			Inventory.counts["fuel"] = 3
			player.combat.aim_override = w_snuff.global_position - (player.global_position + Vector2(0, -10))
			Input.action_press("beam")
		330:
			check(player.combat.beaming, "holding the button fires the beam")
			check(Inventory.get_count("fuel") == 3, "the beam never spends carried fuel")
			check(player.lamp_charge < 1.0, "the beam spends hand-lamp charge")
		355:
			check(not is_instance_valid(w_snuff), "the beam burns a Wickling away in about half a second")
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
			check(Inventory.get_count("fuel") == 3 + Tuning.ember_fuel, "collecting an ember gives fuel (%d)" % Inventory.get_count("fuel"))
			# Scrap drops: force the chance to 100% and burn one more.
			Tuning.wick_scrap_chance = 1.0
			var extra = spawner.spawn_at(player.global_position + Vector2(200, 0))
			extra.hurt(99.0)
			player.lamp_charge = 0.0
		362:
			var scraps := get_tree().get_nodes_in_group("ember").filter(func(e): return e.kind == "scrap")
			check(scraps.size() >= 1, "a burned Wickling can also drop scrap (%d)" % scraps.size())
		365:
			check(not player.combat.beaming, "an empty hand lamp can't beam: go back to the light")
			Input.action_release("beam")
			player.combat.aim_override = Vector2.ZERO
		462:
			check(not player.combat.beaming, "releasing the button ends the beam")
			Inventory.counts["fuel"] = 0
			Tuning.wick_scrap_chance = 0.35
			for e in get_tree().get_nodes_in_group("ember"):
				e.queue_free()   # leftover drops would be magnet-collected after waking
			# Chase and chill in the dark. (Top the old lantern up so there is a light to wake by.)
			lamp.fuel = Tuning.lantern_max_fuel
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
			check(get_tree().paused, "the fainting note pauses the world")
			main.get_node("NoteReader").close()
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
