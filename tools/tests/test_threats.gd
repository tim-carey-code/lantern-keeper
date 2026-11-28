extends Node
## Checks for Wicklings, light reactions and warmth (M1b: lamps can't be drained; the ward is gone). Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_threats.tscn

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var spawner: Node
var lamp: Lantern
var w_rim: Wickling
var w_brave: Wickling
var w_core: Wickling
var w_chase: Wickling

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
			check(lamp.light_by_touch(), "the old lantern by the hut lights by touch")
			main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			check(spawner.count() == 0, "no Wicklings during the opening grace period")
			var w = spawner.spawn_near_player()
			check(w != null and fog.density_at(w.global_position) >= 0.85, "Wicklings spawn in deep fog, away from the keeper")
			if w:
				w.queue_free()
			check(not player.has_method("update_ward") and not ("warding" in player), "the ward is gone (GAME_PLAN §16)")
		60:
			# Light reactions (GAME_PLAN §8.4): a timid Wickling at the rim stays out; a brave one walks in and burns
			# after kl_light_tolerance; one dropped into the bright core burns away. Nothing drains the lamp (M1b).
			var r: float = lamp.get_light_radius()
			w_rim = spawner.spawn_at(lamp.global_position + Vector2(0, r * 0.85))
			w_rim.timid = true
			w_brave = spawner.spawn_at(lamp.global_position + Vector2(r * 0.7, 0))
			w_brave.timid = false
			w_brave._wander_to = lamp.global_position   # it wanders into the light (a random wander could take it out first: a flaky check)
			w_core = spawner.spawn_at(lamp.global_position + Vector2(10, 0))
			w_core.timid = false   # (a timid one is pushed straight back out of a healthy lamp's light)
			player.position = main.start + Vector2(-500, 0)   # far away, in the dark
		300:
			check(lamp.is_lit() and is_equal_approx(lamp.get_light_radius(), Tuning.lantern_max_radius), "Wicklings can't drain a lamp: it is still lit at full radius")
			check(not is_instance_valid(w_core), "a Wickling in a lantern's bright core burns away")
			check(is_instance_valid(w_rim) and w_rim.healthy_level_at(w_rim.global_position) < 0.05, "a timid Wickling stays out of the light")
			check(not is_instance_valid(w_brave) or w_brave._in_light >= Tuning.kl_light_tolerance or w_brave.hp < w_brave.hp_max or w_brave.state == Wickling.State.FLEE, "a brave one walks in, but burns after %.1f s and runs" % Tuning.kl_light_tolerance)
			if is_instance_valid(w_brave):
				w_brave.queue_free()
			check(get_tree().get_nodes_in_group("ember").filter(func(e): return e.kind == "fuel").is_empty(), "burned Wicklings leave no fuel embers (M1b)")
			for e in get_tree().get_nodes_in_group("ember"):
				e.queue_free()
			# The beam (Keeper's Light, optional): hold to burn along your aim; spends lamp charge.
			player.position = w_rim.global_position + Vector2(-200, 4)   # in beam range, outside the drop magnet
			player.lamp_charge = 1.0
			player.combat.aim_override = w_rim.global_position - (player.global_position + Vector2(0, -10))
			Input.action_press("skill_3")   # M1a: the Beam is an optional skill, on LB / Q (slot 3) at level 1
		330:
			check(player.combat.beaming, "holding the button fires the beam")
			check(player.lamp_charge < 1.0, "the beam spends hand-lamp charge")
		355:
			check(not is_instance_valid(w_rim), "the beam burns a Wickling away in about half a second")
			# Scrap drops: force the chance to 100% and burn one more.
			Tuning.wick_scrap_chance = 1.0
			var extra = spawner.spawn_at(player.global_position + Vector2(200, 0))
			extra.hurt(99.0)
			player.lamp_charge = 0.0
		357:
			var drops := get_tree().get_nodes_in_group("ember")
			var scraps := drops.filter(func(e): return e.kind == "scrap")
			check(scraps.size() >= 1, "a burned Wickling can drop scrap (%d)" % scraps.size())
			check(drops.all(func(e): return e.get_parent() == spawner), "drops sit on the fog layer so they glow through the dark")
			if scraps.size() > 0:
				player.position = scraps[0].global_position
		362:
			check(Inventory.get_count("scrap") >= 1, "walking over scrap collects it (%d)" % Inventory.get_count("scrap"))
		365:
			check(not player.combat.beaming, "an empty hand lamp can't beam: go back to the light")
			Input.action_release("skill_3")
			player.combat.aim_override = Vector2.ZERO
		462:
			check(not player.combat.beaming, "releasing the button ends the beam")
			Tuning.wick_scrap_chance = 0.35
			for e in get_tree().get_nodes_in_group("ember"):
				e.queue_free()   # leftover drops would be magnet-collected after waking
			# Chase and chill in the dark.
			player.position = main.start + Vector2(-480, 0)
			player.warmth = Tuning.warmth_max
			w_chase = spawner.spawn_at(player.global_position + Vector2(10, 0))
			w_chase.state = Wickling.State.CHASE
			Inventory.counts["scrap"] = 10
		490:
			check(player.warmth < Tuning.warmth_max, "a Wickling's touch drains warmth (%.0f)" % player.warmth)
			player.warmth = 1.0
		500:
			check(get_tree().paused, "the fainting note pauses the world")
			main.get_node("NoteReader").close()
			check(player.faints == 1, "out of warmth: the keeper faints (no game over)")
			check(player.global_position.distance_to(lamp.global_position) < 60.0, "and wakes beside the nearest lit lantern")
			check(Inventory.get_count("scrap") == 10, "nothing carried is lost (M1b, the faint rule)")
			check(get_tree().get_nodes_in_group("resource").filter(func(r): return r.label.begins_with("Dropped")).is_empty(), "no dropped piles")
			check(player.warmth >= Tuning.warmth_max * Tuning.kl_faint_warmth - 0.01 and player.warmth < Tuning.warmth_max * Tuning.kl_faint_warmth + 10.0, "and wakes at %d%% warmth (%.0f, then the light warms them)" % [roundi(Tuning.kl_faint_warmth * 100.0), player.warmth])
			main.get_node("NoteReader").close()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
