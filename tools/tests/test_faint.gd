extends Node
## The faint rule (M1b, GAME_PLAN §12; FaintRule, player.gd faint()). Replaces the old faint, which erased every
## cleared pack and dropped half of what you carried. Checks:
##   - cleared packs stay cleared; a half-fought pack is whole and asleep again and keeps its dead;
##   - nothing carried is lost (scrap, flasks); unspent wick waits where you fell, a second faint makes a second
##     drop, and walking back collects them;
##   - you wake at the nearest lit light in the region at 60% warmth, skipping lights near an unbeaten fight;
##   - the Clinker goes back to the start of its phase, asleep on its post; the Ashbrood goes back to the start of
##     the phase it reached, shell regrown, its oil armed again; summoned foes go; a half-burned nest is whole.
## Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_faint.tscn

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var arena: Node
var reader: Node
var pack_half: EnemyPack     # pack 23: three Wicklings on the main route
var pack_done: EnemyPack     # pack 20: the lone first Wickling
var safe_lamp: Lantern
var risky_lamp: Lantern
var fell_at := Vector2.ZERO
var clinker: Clinker
var brood: Ashbrood
var nest: WickNest
var hatchling: Wickling

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
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames when the faint note pauses the world
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
	SaveGame.path = "user://test_faint_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _pack(id: String) -> EnemyPack:
	for p in get_tree().get_nodes_in_group("enemy_pack"):
		if p.id == id:
			return p
	return null

func _members(id: String) -> Array:
	return get_tree().get_nodes_in_group("foe").filter(func(f): return f.pack_id == id and not f.is_queued_for_deletion() and not f._dead)

func _faint() -> void:
	fell_at = player.global_position
	player.faint()
	reader.close()

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			arena = main.get_node("FogLayer/Wicklings")
			reader = main.get_node("NoteReader")
			main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			pack_half = _pack("hollow_23")
			pack_done = _pack("hollow_20")
			check(pack_half != null and pack_done != null and pack_half.count == 3 and pack_done.count == 1, "the route's first packs: pack 23 (3) and pack 20 (1)")
			player.global_position = pack_done.global_position
		4:
			check(pack_done.awake and _members(pack_done.id).size() == 1, "walking in wakes the lone Wickling")
			for f in _members(pack_done.id):
				f.hurt(99.0, false, "lance")
		6:
			check(Progress.cleared.has("pack_hollow_20"), "beaten, pack 20 is cleared")
			player.global_position = pack_half.global_position
		8:
			var m := _members(pack_half.id)
			check(pack_half.awake and m.size() == 3, "pack 23 wakes with three members")
			m[0].hurt(99.0, false, "lance")   # one beaten
			m[1].hurt(1.0, false, "lance")    # one hurt
		10:
			check(_members(pack_half.id).size() == 2, "a half-fought pack: one down, two left")
			# What the keeper carries, and some wick.
			Inventory.counts["scrap"] = 9
			player.flasks = 2
			Progress.wick = 5
			player.global_position = pack_half.global_position + Vector2(40, 0)
			_faint()
		12:
			check(player.faints == 1, "the keeper faints (no game over)")
			check(Progress.cleared.has("pack_hollow_20"), "a cleared pack stays cleared after a faint (the old faint erased it)")
			check(not Progress.cleared.has("pack_hollow_23") and not pack_half.awake and _members(pack_half.id).is_empty(), "the half-fought pack is asleep again")
			check(pack_half.dead_slots.size() == 1 and pack_half.living_slots() == 2, "and keeps its dead (%d of 3 left)" % pack_half.living_slots())
			check(Inventory.get_count("scrap") == 9 and player.flasks == 2, "nothing carried is lost (scrap %d, flasks %d)" % [Inventory.get_count("scrap"), player.flasks])
			var drops := get_tree().get_nodes_in_group("wick_drop")
			check(drops.size() == 1 and drops[0].amount == 5 and drops[0].global_position.distance_to(fell_at) < 1.0 and Progress.wick == 0, "unspent wick waits where you fell (%d)" % (drops[0].amount if drops.size() > 0 else -1))
			check(is_equal_approx(player.warmth, Tuning.warmth_max * 0.6), "you wake at 60%% warmth (%.0f)" % player.warmth)
			check(player.global_position.distance_to(main.start) < 2.0, "with no light lit, you wake at the hut")
			check(not reader.is_open(), "the faint note closes")
			# Walk back in: the pack wakes whole, but only with the members it had left, fresh.
			player.global_position = pack_half.global_position
		14:
			var m := _members(pack_half.id)
			check(pack_half.awake and m.size() == 2, "woken again, it has its two survivors (%d)" % m.size())
			check(m.all(func(f): return f.hp >= Tuning.wick_hp * f.level_mult() - 0.001), "healed: whole again")
			# A second faint makes a second wick drop.
			Progress.wick = 3
			player.global_position = pack_half.global_position + Vector2(0, 60)
			_faint()
		16:
			var drops := get_tree().get_nodes_in_group("wick_drop")
			check(drops.size() == 2, "a second faint makes a second drop; nothing is lost until you collect them (%d)" % drops.size())
			check(pack_half.living_slots() == 2 and not pack_half.awake, "a pack put to sleep twice still keeps its two")
			# Collect both.
			for d in drops:
				player.global_position = d.global_position
				d._process(0.016)
			check(Progress.wick == 8 or Progress.level > 1, "walking back collects the wick (%d)" % Progress.wick)
			# Waking by a light: the nearest lit light in the region, but not one near an unbeaten fight.
			var lone: Vector2 = main.start + Vector2(0, 8 * FogGrid.TILE)
			safe_lamp = _lamp(lone)
			var near_pack: Vector2 = pack_half.global_position + Vector2(5 * FogGrid.TILE, 0)
			risky_lamp = _lamp(near_pack)
			player.global_position = near_pack + Vector2(0, 40)   # fall right by the risky lamp
			check(FaintRule.unbeaten_spots(get_tree()).any(func(p): return p.distance_to(risky_lamp.global_position) < Tuning.kl_faint_skip_radius), "the near lamp is within %d px of an unbeaten pack" % roundi(Tuning.kl_faint_skip_radius))
			_faint()
		18:
			check(player.global_position.distance_to(safe_lamp.global_position + Vector2(0, 24)) < 2.0, "you wake by the nearest safe light, skipping one next to an unbeaten pack")
			# A lit old lamp counts too, and the nearest wins.
			var hut: Lantern = get_tree().get_nodes_in_group("lantern").filter(func(l): return l.global_position.distance_to(main.start_lantern_pos) < 8.0)[0]
			hut.light_by_touch()
			player.global_position = hut.global_position + Vector2(64, 0)
			_faint()
		20:
			var hut: Lantern = get_tree().get_nodes_in_group("lantern").filter(func(l): return l.global_position.distance_to(main.start_lantern_pos) < 8.0)[0]
			check(player.global_position.distance_to(hut.global_position + Vector2(0, 24)) < 2.0, "you wake by the nearest lit light (the hut's old lamp)")
			# The Clinker: wake it, hurt it, faint.
			for f in get_tree().get_nodes_in_group("foe"):
				if f is Clinker:
					clinker = f
			check(clinker != null and clinker.level == Tuning.kl_clinker_level, "the Clinker, Lv %d" % Tuning.kl_clinker_level)
			player.global_position = clinker.global_position + Vector2(60, 0)
		24:
			check(clinker.awake, "the Clinker wakes")
			clinker.shell = 0.0
			clinker.hurt(clinker.hp_max * 0.6, false, "lance")
			check(clinker._oil_step_given and clinker.hp < clinker.hp_max * 0.5, "past half it drops its oil")
			clinker.global_position += Vector2(30, 20)
			player.global_position = clinker.home + Vector2(200, 0)
			_faint()
		26:
			check(not clinker.awake and clinker.global_position == clinker.home, "after a faint the Clinker is asleep on its post")
			check(is_equal_approx(clinker.hp, Tuning.kl_clinker_hp * clinker.level_mult()) and is_equal_approx(clinker.shell, clinker.shell_max) and clinker.shell_max > 0.0, "back to the start of its phase: full health, shell regrown")
			check(not clinker._oil_step_given and not Progress.cleared.has(clinker.foe_id), "its oil drops again on the next try; it is not cleared")
			# A nest: half-burned, with a hatchling out.
			for f in get_tree().get_nodes_in_group("foe"):
				if f is WickNest and f.foe_id == "nest_hollow_8":
					nest = f
			nest.hp = nest.hp_max * 0.4
			hatchling = Wickling.new()
			hatchling.summoned = true
			hatchling.position = nest.global_position + Vector2(30, 0)
			arena.add_child(hatchling)
			# The Ashbrood: read the WayLamp, light it, reach phase 2, take it past half.
			var wl: WayLamp = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0]
			Progress.notes_read["waylamp_hollow"] = true
			player.global_position = wl.global_position + Vector2(0, 30)
			check(wl.touch() == "lit", "the Hollow's WayLamp lights by touch")
			brood = wl.guardian()
			check(brood != null, "and the Ashbrood wakes")
		28:
			var wl: WayLamp = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0]
			brood.end_phase_pause()
			brood.shell = 0.0
			brood.hurt(brood.hp + 1.0, false, "lance")
			check(brood.phase == 2, "the Ashbrood reaches phase 2")
			brood.end_phase_pause()
			brood.shell = 0.0
			brood.hurt(brood.phase_hp() * 0.6, false, "lance")
			check(brood._oil_step_given, "past half of phase 2 it drops its oil")
			var add := Wickling.new()
			add.summoned = true
			add.position = brood.global_position + Vector2(50, 0)
			arena.add_child(add)
			brood.global_position += Vector2(120, 40)   # it has flown off to dive
			player.global_position = wl.global_position + Vector2(0, 300)
			_faint()
		30:
			var wl: WayLamp = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0]
			check(is_instance_valid(brood) and brood.phase == 2, "after a faint the Ashbrood keeps the phase it reached (phase %d)" % brood.phase)
			check(is_equal_approx(brood.hp, brood.phase_hp()) and is_equal_approx(brood.shell, brood.phase_shell()), "back to the start of that phase: full phase health and shell (%.0f, %.1f)" % [brood.hp, brood.shell])
			check(not brood._oil_step_given, "its phase oil is armed again")
			check(brood.global_position == wl.global_position, "back over its WayLamp")
			check(wl.kindling and not wl.is_lit() and not Progress.is_settled(FogGrid.R_HOLLOW), "the fight isn't won or lost: the WayLamp still waits")
			check(get_tree().get_nodes_in_group("foe").filter(func(f): return f.summoned and not f.is_queued_for_deletion()).is_empty(), "summoned foes go (its adds, a nest's hatchlings)")
			check(not is_instance_valid(hatchling) or hatchling.is_queued_for_deletion(), "the hatchling went with no drop")
			check(is_equal_approx(nest.hp, nest.hp_max) and not Progress.cleared.has(nest.foe_id), "a half-burned nest is whole again")
			check(player.global_position.distance_to(brood.global_position) >= Tuning.kl_faint_skip_radius - 30.0, "you don't wake right next to the Ashbrood")
			check(Progress.cleared.has("pack_hollow_20"), "and pack 20 is still cleared after five faints")
			SaveGame.delete_save()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)

func _lamp(p: Vector2) -> Lantern:
	var l := Lantern.new()
	l.kind = "post"
	l.position = fog.tile_center(fog.tile_of(p))
	main.get_node("Lanterns").add_child(l)
	return l
