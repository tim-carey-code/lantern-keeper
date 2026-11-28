extends Node
## Silent smoke checks for the Keeper's Light Hollow prototype.
## godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_prototype_hollow.tscn

var main: Node
var frame := 0
var fails := 0
var level_ui: Node

func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		fails += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.skip_opening = true
	# M1c (review): the real rules stay on here: light states, the Ashbrood hurt only when lit, lamp slots.
	Tuning.wick_enabled = false
	SaveGame.path = "user://test_hollow_prototype.json"
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	level_ui = main.get_node("HUD").level_up_screen

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			check(not Progress.is_unlocked("post"), "the Post Lamp starts locked")
			var all_packs := get_tree().get_nodes_in_group("enemy_pack")
			check(all_packs.filter(func(p): return not p.guard).size() == 24 and all_packs.filter(func(p): return p.guard).size() == 1, "24 fixed Hollow packs are placed (4x for the 4x Hollow), plus the Post Lamp's small guard")
			check(get_tree().get_nodes_in_group("foe").filter(func(f): return f is WickNest).size() == 12, "twelve nests, one of them on the road north")
			var caches := get_tree().get_nodes_in_group("resource").filter(func(r): return r.label == "Old cache")
			check(caches.size() == 8, "side caches wait at the dead ends, and one at Oswin's crook (%d)" % caches.size())
			var find := get_tree().get_nodes_in_group("landmark").filter(func(m): return m.id == "crook_post")
			check(find.size() == 1, "the Post Lamp find is placed north of the hut")
			check(Story.goal_target("build_post") == "crook_post", "the goal pointer leads to the Hollow find")
			Progress.add_wick(Progress.wick_for_level(1))
		3:
			check(Progress.level == 2 and Progress.skill_points() == 1, "the first level's wick raises the keeper to level 2, with a skill point (M2)")
			check(not get_tree().paused and level_ui.shown >= 1, "a level-up doesn't pause the world: a line says it (M2: no card screen)")
			var fb = main.get_node("FogLayer/FoeBars")
			var named := Wickling.new()
			named.elite = true
			main.get_node("FogLayer/Wicklings").add_child(named)
			named.tick_foe(0.01)
			named.hurt(1.0, false, "burst")
			check(named.foe_name == "Shelled Wickling" and fb.wants_bar(named, main.player), "a hurt foe shows its name and health bar")
			check(named._flash > 0.0, "a hit makes it flash")
			named.queue_free()
			var nest := WickNest.new()
			nest.foe_id = "test_nest"
			main.get_node("FogLayer/Wicklings").add_child(nest)
			var hp_before := nest.hp
			nest.hurt(5.0, false, "beam")
			check(is_equal_approx(nest.hp, hp_before), "a beam cannot damage a nest")
			nest.hurt(2.0, false, "core")
			check(nest.hp < hp_before, "a lantern core can burn a nest")
		4:
			var post: Landmark = get_tree().get_nodes_in_group("landmark").filter(func(m): return m.id == "crook_post")[0]
			post.activate()
			check(Progress.is_unlocked("post"), "reading the keeper's post unlocks the Post Lamp")
			var lamp: WayLamp
			for w in get_tree().get_nodes_in_group("waylamp"):
				if w.id == "hollow":
					lamp = w
			Progress.notes_read["waylamp_hollow"] = true
			check(lamp.touch() == "lit" and lamp.kindling, "a touch on the WayLamp wakes the Hollow's guardian (M1b: no fuel)")
			# M1c: the bowl's rim lamp, lit by touch, is what lets the keeper hurt it (no scrap needed).
			var rim: Array = get_tree().get_nodes_in_group("lantern").filter(func(l): return l.global_position.distance_to(main.rim_lamp_pos) < 8.0)
			check(rim.size() == 1 and rim[0].light_by_touch(), "M1c: the rim lamp lights by touch")
		6:
			var bosses := get_tree().get_nodes_in_group("foe").filter(func(f): return f is Ashbrood)
			check(bosses.size() == 1, "the Ashbrood appears at the WayLamp")
			if bosses.size() == 1:
				var boss: Ashbrood = bosses[0]
				var bb = main.get_node("BossBar")
				check(bb.boss() == boss and boss.foe_name == "The Ashbrood", "the guardian gets a named boss bar")
				check(boss.is_exposed(), "M1c: the rim lamp's light reaches the bowl: it is lit (exposed)")
				boss.hurt(boss.phase_hp() + boss.phase_shell() + 1.0, false, "beam")
				check(boss.phase == 2 and boss.hp == boss.phase_hp(), "breaking phase one opens the diving phase")
				check(boss.level == Tuning.kl_ashbrood_level and is_equal_approx(boss.phase_hp(), Tuning.kl_ashbrood_hp2 * (1.0 + Tuning.kl_foe_hp_per_level * (Tuning.kl_ashbrood_level - 1))), "a phase's health grows 12%% a level: Lv %d, %.0f a phase (M1b)" % [boss.level, boss.phase_hp()])
				boss.hurt(boss.phase_hp() + boss.phase_shell() + 1.0, false, "beam")
				check(boss.in_phase_pause() and boss.hp == boss.phase_hp(), "it rises out of the bowl first, and can't be hurt meanwhile")
				boss.end_phase_pause()
				boss.hurt(boss.phase_hp() + boss.phase_shell() + 1.0, false, "beam")
				check(boss.phase == 3 and boss.in_phase_pause() and not Progress.is_settled(FogGrid.R_HOLLOW), "M2: breaking phase two brings phase 3, the last of the brood")
				boss.end_phase_pause()
				boss.hurt(boss.phase_hp() + boss.phase_shell() + 1.0, false, "beam")
				check(Progress.is_settled(FogGrid.R_HOLLOW), "beating phase three holds the Hollow")
		7:
			# M1b: while the WayLamp takes its ember back (it rises into the lamp), the level-up cards wait.
			var wl: WayLamp = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0]
			check(wl.ember_rise_t > 0.0 and not main.get_node("SkillsList").is_open(), "the ember rises into the WayLamp; no level-up screen opens over it (M2)")
			wl.ember_rise_t = 0.0
			get_tree().paused = false
			Tuning.ui_open = false
			for c in get_tree().get_nodes_in_group("note_reader"):
				c.close()
			Progress.add_wick(60)
		9:
			check(Progress.skill_points() >= 2 and not get_tree().paused, "a later level-up adds another point (%d)" % Progress.skill_points())
		10:
			check(not Tuning.kl_ambient_spawns, "nothing streams out of the fog: enemies wait in packs and nests")
			var start: Vector2 = main.start
			var too_close := []
			for n in get_tree().get_nodes_in_group("enemy_pack") + get_tree().get_nodes_in_group("foe"):
				if (n is EnemyPack or n is WickNest or n is Clinker) and n.global_position.distance_to(start) < 16.0 * FogGrid.TILE:
					too_close.append("%s %s %s" % [n.get_class(), n.get_script().resource_path.get_file(), str(main.fog.tile_of(n.global_position))])
			var clink: Clinker = get_tree().get_nodes_in_group("foe").filter(func(f): return f is Clinker)[0]
			var wl_pos: Vector2 = get_tree().get_nodes_in_group("waylamp").filter(func(w): return w.id == "hollow")[0].global_position
			check(clink.global_position.distance_to(wl_pos) < 10.0 * FogGrid.TILE, "the Clinker guards its post near the WayLamp")
			check(not clink.awake, "and sleeps there until you come close")
			# Owner 2026-11-27 (onboarding): the lone first Wickling may sit closer; test_prototype_onboarding checks nothing wakes at the hut.
			check(too_close.size() == 1 and too_close[0].contains(str(main.fog.tile_of(start + Vector2(-1, -10) * FogGrid.TILE))), "a calm start: within 16 tiles of the hut only the lone first Wickling (%s)" % str(too_close))
			var packs := get_tree().get_nodes_in_group("enemy_pack")
			check(packs.any(func(p): return p.elites > 0), "the northern packs hold shelled elites")
			# Tougher toward the WayLamp: the third of the packs nearest it outweighs the farthest third.
			packs.sort_custom(func(a, b): return a.global_position.distance_to(wl_pos) < b.global_position.distance_to(wl_pos))
			var weight := func(p): return p.count + p.spitwicks * 2 + p.elites * 3
			var third := packs.size() / 3
			var near_w := 0
			var far_w := 0
			for i in third:
				near_w += weight.call(packs[i])
				far_w += weight.call(packs[packs.size() - 1 - i])
			# The loop (2026-11-27) moved the WayLamp east, beside the quiet south-east, so the far third now holds the
			# north-west's optional elites: elites stay in the north half (north of the crook), never in the south.
			var crook_y: float = start.y - 18.0 * FogGrid.TILE
			check(near_w > far_w and packs.filter(func(p): return p.global_position.y > crook_y).all(func(p): return p.elites == 0 or p.guard), "packs get tougher toward the WayLamp (%d vs %d), and the south holds no elites" % [near_w, far_w])
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
