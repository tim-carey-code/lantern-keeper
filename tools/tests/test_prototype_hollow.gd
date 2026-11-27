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
			check(get_tree().get_nodes_in_group("enemy_pack").size() == 24, "24 fixed Hollow packs are placed (4x for the 4x Hollow)")
			check(get_tree().get_nodes_in_group("foe").filter(func(f): return f is WickNest).size() == 12, "twelve nests, three of them on the road north")
			var caches := get_tree().get_nodes_in_group("resource").filter(func(r): return r.label == "Old cache")
			check(caches.size() == 7, "side caches wait at the dead ends (%d)" % caches.size())
			var find := get_tree().get_nodes_in_group("landmark").filter(func(m): return m.id == "crook_post")
			check(find.size() == 1, "the Post Lamp find is placed north of the hut")
			check(Story.goal_target("build_post") == "crook_post", "the goal pointer leads to the Hollow find")
			Progress.add_wick(15)
		3:
			check(Progress.level == 2 and Progress.pending_level_ups == 1, "15 wick raises the keeper to level 2")
			check(get_tree().paused and level_ui.root.visible, "level-up choice pauses the world")
			var choice: Button = level_ui.cards.get_child(0)
			var chosen_id: String = level_ui._offer[0].id
			choice.pressed.emit()
			check(Progress.has_combat_upgrade(chosen_id), "choosing a card keeps the upgrade")
			check(not get_tree().paused, "choosing an upgrade resumes play")
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
			Inventory.add("fuel", Tuning.waylamp_fuel_need)
			check(lamp.feed() == "fed" and lamp.kindling, "15 fuel wakes the Hollow's guardian")
		6:
			var bosses := get_tree().get_nodes_in_group("foe").filter(func(f): return f is Ashbrood)
			check(bosses.size() == 1, "the Ashbrood appears at the WayLamp")
			if bosses.size() == 1:
				var boss: Ashbrood = bosses[0]
				var bb = main.get_node("BossBar")
				check(bb.boss() == boss and boss.foe_name == "The Ashbrood", "the guardian gets a named boss bar")
				boss.hurt(Tuning.kl_ashbrood_hp + Tuning.kl_ashbrood_shell + 1.0, false, "beam")
				check(boss.phase == 2 and boss.hp == Tuning.kl_ashbrood_hp, "breaking phase one opens the diving phase")
				boss.hurt(Tuning.kl_ashbrood_hp + Tuning.kl_ashbrood_shell + 1.0, false, "beam")
				check(Progress.is_settled(FogGrid.R_HOLLOW), "beating phase two holds the Hollow")
		7:
			# A second level-up: the controller must land on the new cards (owner: the pad stopped working).
			get_tree().paused = false
			Tuning.ui_open = false
			for c in get_tree().get_nodes_in_group("note_reader"):
				c.close()
			Progress.add_wick(60)
		9:
			var focus := get_viewport().gui_get_focus_owner()
			check(level_ui.root.visible, "a later level-up opens the choice again")
			check(focus is Button and focus.get_parent() == level_ui.cards and not focus.is_queued_for_deletion(), "and the controller's focus is on one of its new cards")
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
			check(too_close.is_empty(), "a calm start: no pack, nest or Clinker within 16 tiles of the hut (%s)" % str(too_close))
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
			check(near_w > far_w and packs.slice(packs.size() - third).all(func(p): return p.elites == 0), "packs get tougher toward the WayLamp (%d vs %d)" % [near_w, far_w])
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
