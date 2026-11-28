extends Node
## Visual check without a screen: loads the game, sets up a view, runs a few
## seconds, and lets Godot's movie writer record frames. Run on a virtual display:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --audio-driver Dummy \
##     --write-movie ~/.cache/openclaw/project-scratch/shots/frame.png --fixed-fps 30 \
##     res://tools/capture/capture.tscn -- start
## Views (after "--"): lanterns, start, marsh, cold, edge, wick, drops, ridge, map, journal, opening, opening_name, opening_letter, waylamp_kindle, waylamp_held, upgrade, kl_combat,
## kl_level (the HUD's level and wick row, then a level-up's card screen), m1a_bar (HUD and action bar),
## m1a_lampfire (a stream with impacts), m1a_fireglobe_marker (in-flight landing marker),
## m1a_fireglobe_ground (burning ground), m1a_skills (plain Skills list), onboard_start, onboard_north, onboard_haven,
## onboard_crook (the first 10 minutes' main route, nothing staged), loop_waylamp, loop_marsh_climb,
## loop_ridge_entry, loop_travel (the loop and WayLamp fast travel). The last frame is the one to look at.
## README views (staged, pop-ups hidden; rendered by tools/capture/readme_shots.sh): readme_hollow, readme_ward,
## readme_marsh, readme_ridge, readme_map, readme_lanterns, readme_relight (an animation: use every frame).
## Readability views (telegraphs and the keeper's feedback; the last frame shows the wind-up part-way): tell_puff,
## tell_puff_reduce (at commit, "reduce flashes" on), tell_adds (the call, with the bold swarm's cold rim), tell_dive,
## tell_dive_arrow (a dive at an off-screen lamp: the edge arrow), tell_spit, tell_lane, tell_reach (a Wickling
## reaching, another draining: the frost edge), tell_hatch, keeper_dash, keeper_cast, keeper_drink, keeper_hurt.
## M1b views (no more tending): m1b_opening (the hut's cold old lamp, its lure and "Light it"), m1b_opening_lit (the
## same, lit by touch), m1b_faint (the faint note), m1b_wake (awake by a lamp, the wick waiting where you fell),
## m1b_lures (a pack's eyes, an elite's ring and a nest's glow through the fog), m1b_ember (the Ashbrood over the
## WayLamp's last ember), m1b_kindle (the kill: the ember rises into the lamp as it lights; look at frames 45-75).
## M1c views (lamps in the fight): m1c_dark_lit (a dark foe and a lit one side by side: the dim cold body, the dimmed
## bar and the shell's floor notch; the warm rim and shell cracks), m1c_lock (the warm lock brackets on a foe, with
## its warm bar ticks), m1c_ash_bolts (the Ashbrood's phase-1 ash bolts winding up: three cold aim markers, the rim
## lamp lit), m1c_pips (the HUD's lamp-slot pips: two lamps planted of three slots, one replant wait).
## Sprites view: sprites (every owner-art subject side by side, frozen: the three Wicklings, an elite whose shell
## broke, the Spitwick, a nest, the Ashbrood in its bowl and out of it, and Amos with his cart, who isn't in the
## game until M4).
## (M1b: the old "cold" and "readme_ward" views stage what is gone: a dark lamp stands in for a cold one, and
## the ward is not drawn.)

var main: Node
var frame := 0
var view := "start"
var end_frame := 45

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keep counting frames while the opening/journal pauses the world
	# Ignore any real controller on this PC.
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		view = args[0]
	Story.skip_opening = not view.begins_with("opening")
	if view == "readme_relight":
		end_frame = 110
	elif view == "m1a_lampfire":
		end_frame = 48   # the stream has landed, and one bolt is still in flight
	elif view == "m1b_kindle":
		end_frame = 80
	SaveGame.path = "user://test_ignore_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

## A planted lantern; dark = snuffed for the whole shot (M1b: lamps never burn down).
func _lantern(p: Vector2, kind: String = "post", dark: bool = false) -> Lantern:
	var l := Lantern.new()
	l.kind = kind
	l.position = main.fog.tile_center(main.fog.tile_of(p))
	main.get_node("Lanterns").add_child(l)
	if dark:
		l.snuff(9999.0)
	return l

func _process(_delta: float) -> void:
	frame += 1
	if frame == 2:
		var wind: Wind = main.get_node("Wind")
		wind.force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
		var s: Vector2 = main.start
		match view:
			"marsh":
				var pump: Vector2 = main.fog.tile_center(Vector2i(200, 136))
				main.player.position = pump + Vector2(-40, 40)
				_lantern(main.fog.tile_center(Vector2i(184, 136)))
				_lantern(main.fog.tile_center(Vector2i(194, 136)), "reservoir")
				_lantern(main.fog.tile_center(Vector2i(176, 144)))
			"cold":
				_lantern(s + Vector2(-160, 64), "post", true)
				_lantern(s + Vector2(200, 120), "post")
				main.player.position = s + Vector2(-40, 60)
			"edge":
				main.player.position = main.fog.tile_center(Vector2i(16, 136))
				_lantern(main.fog.tile_center(Vector2i(18, 132)))
			"wick":
				var l := _lantern(s + Vector2(-200, 40))
				var sp = main.get_node("FogLayer/Wicklings")
				for a in [0.3, 2.2, 4.0]:
					var w = sp.spawn_at(l.global_position + Vector2.from_angle(a) * l.get_light_radius() * 0.9)
					w.target = l
					w.state = Wickling.State.SEEK_LANTERN
				var c = sp.spawn_at(s + Vector2(170, -60))
				main.player.position = s + Vector2(110, -20)
			"drops":
				main.player.position = s + Vector2(0, 260)
				var sp2 = main.get_node("FogLayer/Wicklings")
				Tuning.wick_scrap_chance = 1.0
				for off in [Vector2(-90, 0), Vector2(90, 30)]:
					var w2 = sp2.spawn_at(main.player.position + off)
					w2.hurt(99.0)
			"ridge":
				var f: FogGrid = main.fog
				var c := f.tile_center(Vector2i(68, 34))
				main.player.position = c + Vector2(-40, 40)
				var src := _lantern(c + Vector2(-160, 0), "hooded")
				var m := _lantern(c + Vector2(-60, 0), "mirror")
				m.mirror_dir = 0
				_lantern(c + Vector2(40, 96))
				Progress.unlock("hooded")
				Progress.unlock("mirror")
			"waylamp_kindle", "waylamp_held":
				var wl: WayLamp = null
				for w in get_tree().get_nodes_in_group("waylamp"):
					if w.id == "hollow":
						wl = w
				Progress.notes_read["waylamp_hollow"] = true
				_lantern(wl.global_position + Vector2(-176, 30))
				if view == "waylamp_held":
					_lantern(wl.global_position + Vector2(-300, 220))
					_lantern(wl.global_position + Vector2(-60, 330))
					main.player.position = wl.global_position + Vector2(-50, 70)
				else:
					main.player.position = wl.global_position + Vector2(46, 44)
					wl.start_kindling()
					wl.kindle_t = Tuning.waylamp_kindle_sec * 0.45
					var k := 0
					for w in get_tree().get_nodes_in_group("wickling"):
						w.global_position = wl.global_position + Vector2.from_angle(0.6 + k * 1.7) * (40.0 + 34.0 * k)
						k += 1
			"readme_hollow", "readme_ward", "readme_marsh", "readme_ridge", "readme_map", "readme_lanterns", "readme_relight":
				_readme_setup()
			"upgrade":
				for m in get_tree().get_nodes_in_group("landmark"):
					if m.id == "satchel_hollow":
						_lantern(m.global_position + Vector2(120, 40))
						main.player.position = m.global_position + Vector2(30, 20)
					if m.id == "lampglass_hollow":
						_lantern(m.global_position + Vector2(-90, -30))
			"onboard_start", "onboard_north", "onboard_haven", "onboard_crook":
				_onboard_setup()
			"loop_waylamp", "loop_marsh_climb", "loop_ridge_entry", "loop_travel":
				_loop_setup()
			"m1a_bar", "m1a_lampfire", "m1a_fireglobe_marker", "m1a_fireglobe_ground", "m1a_skills":
				_m1a_setup()
			"m1b_opening", "m1b_opening_lit", "m1b_faint", "m1b_wake", "m1b_lures", "m1b_ember", "m1b_kindle":
				_m1b_setup()
			"m1c_dark_lit", "m1c_lock", "m1c_ash_bolts", "m1c_pips":
				_m1c_setup()
			"tell_puff", "tell_puff_reduce", "tell_adds", "tell_dive", "tell_dive_arrow", "tell_spit", "tell_lane", "tell_reach", "tell_hatch", \
					"keeper_dash", "keeper_cast", "keeper_drink", "keeper_hurt", "sprites":
				_tell_setup()
			"kl_combat":
				_lantern(s + Vector2(-260, 60))
				main.player.position = s + Vector2(-420, 120)
				var sp3 = main.get_node("FogLayer/Wicklings")
				var e = sp3.spawn_at(main.player.position + Vector2(170, -30), true)
				e.state = Wickling.State.CHASE
				for off in [Vector2(120, 50), Vector2(200, 70), Vector2(-90, 40)]:
					var w4 = sp3.spawn_at(main.player.position + off)
					w4.state = Wickling.State.CHASE
				main.player.combat.aim_override = Vector2(170, -20)
			"map":
				_lantern(s + Vector2(-160, 64))
				for i in 60:
					main.fog.step(0.1)
			"start_nohud":
				_lantern(s + Vector2(-140, 90))
				_lantern(s + Vector2(60, 150))
				main.player.position = s + Vector2(-20, 30)
			_:
				_lantern(s + Vector2(-140, 90))
				_lantern(s + Vector2(60, 150))
				main.player.position = s + Vector2(-20, 30)
		if view != "readme_relight":
			for i in 30:
				main.fog.step(0.1)   # let the light push the fog back before the shot
	if frame == 4 and view == "waylamp_held":
		Progress.settle(FogGrid.R_HOLLOW, "The Hollow")   # after the Hollow's own banner
		for i in 30:
			main.fog.step(0.1)
	if view == "kl_level" and frame == 3:
		Progress.level = 6
		Progress.wick = 0
		Progress.add_wick(31)   # Lv 6, 31/56
	if view == "kl_level" and frame == 20:
		Progress.add_wick(40)   # to Lv 7: the card screen
	if view == "kl_combat" and frame == 8:
		Input.action_press("beam")
	if view == "kl_combat" and frame == 36:
		main.player.combat.burst()
	if view == "pause" and frame == 30:
		main.get_node("PauseMenu").open()
		main.get_node("PauseMenu").info.text = "Last save: 2026-11-27 16:52:50 (autosaves every minute)"
	if view == "m1a_skills" and frame == 30:
		main.get_node("SkillsList").open()
	if view == "m1a_lampfire" and frame in [14, 24, 34]:
		main.player.combat.skill("lampfire").fire()
	if view == "loop_travel" and frame == 30:
		var tm = main.get_node("TravelMenu")
		for w in get_tree().get_nodes_in_group("waylamp"):
			if w.id == "hollow":
				tm.open(w)
	if frame == 6 and view == "map":
		main.get_node("MapScreen").toggle()
	# Opening views: step through to the page we want to see.
	if view == "opening_name" and frame == 5:
		main.get_node("Opening")._next()
		main.get_node("Opening").name_box.text = "Tess"
	if view == "opening_letter" and frame == 5:
		var o = main.get_node("Opening")
		o._next()
		o.name_box.text = "Tess"
		o._next()
	if view == "journal" and frame == 30:
		Story.player_name = "Tess"
		Story.update(main)
		for id in ["ledger", "stone_way"]:
			for m in get_tree().get_nodes_in_group("landmark"):
				if m.id == id:
					Progress.notes_read[id] = true
		Story.update(main)
		main.get_node("Journal").toggle()
		main.get_node("Journal").page = 1
		main.get_node("Journal").refresh()
	if view in ["lanterns", "readme_lanterns"] and frame == 30:
		for k in ["reservoir", "hooded"]:
			Progress.unlock(k)
		Inventory.counts["scrap"] = 6
		Progress.selected = "reservoir"
		main.get_node("BuildMenu").open()
	if view == "start_nohud" and frame == 3:
		main.get_node("HUD").visible = false
	if view.begins_with("readme") and frame >= 3:
		var hud = main.get_node("HUD")
		hud.banner.visible = false   # no region banners, toasts or tips in README shots
		hud.toast.visible = false
		hud.tip.visible = false
		if view != "readme_hollow":
			main.get_node("FogLayer/WorldPrompt").visible = false
	if view.begins_with("m1a_") and frame >= 3:
		var hud = main.get_node("HUD")
		hud.banner.visible = false
		hud.toast.visible = false
		hud.tip.visible = false
		main.get_node("FogLayer/WorldPrompt").visible = false
	if view == "readme_map" and frame == 6:
		main.get_node("MapScreen").toggle()
	if view == "readme_relight" and frame == 30:
		main.get_node("Lanterns").get_child(0).light_by_touch()
	if (view.begins_with("tell_") or view.begins_with("keeper_") or view == "sprites") and frame >= 3:
		var hud = main.get_node("HUD")
		hud.banner.visible = false
		hud.toast.visible = false
		hud.tip.visible = false
		main.get_node("FogLayer/WorldPrompt").visible = false
		main.player.warmth = Tuning.warmth_max if view != "keeper_drink" else 45.0
		_tell_frame()
	if view.begins_with("m1b_"):
		_m1b_frame()
	if view.begins_with("m1c_"):
		_m1c_frame()
	if frame >= end_frame:
		get_tree().quit()

## The first 10 minutes (onboarding): the real map with nothing added, at each step of the main route.
##   onboard_start: a fresh start at the hut. onboard_north: hut lamp lit, ledger read, 6 tiles north (the
##   north path's cold lamp and the lone Wickling ahead). onboard_haven: that lamp lit, the crook's red pulse
##   ahead. onboard_crook: the Post Lamp found, the pointer on nest A.
func _onboard_setup() -> void:
	var s: Vector2 = main.start
	var T := FogGrid.TILE
	main.player.position = s
	if view == "onboard_start":
		Story.update(main)
		return
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.global_position.distance_to(main.start_lantern_pos) < 8.0 or (view != "onboard_north" and l.global_position.distance_to(main.waypost_lantern_pos) < 8.0):
			l.light_by_touch()
	Progress.notes_read["ledger"] = true
	match view:
		"onboard_north":
			main.player.position = s + Vector2(0, -6) * T
			_goals_done_until("relight_waypost")
		"onboard_haven":
			main.player.position = main.waypost_lantern_pos + Vector2(0, 40)
			_goals_done_until("build_post")
		"onboard_crook":
			var crook: Node2D = get_tree().get_nodes_in_group("landmark").filter(func(m): return m.id == "crook_post")[0]
			Progress.notes_read["crook_post"] = true
			Progress.unlock("post")
			Progress.cleared["pack_hollow_post_guard"] = true
			Progress.cleared["pack_hollow_20"] = true
			Progress.cleared["pack_hollow_23"] = true
			Inventory.counts["scrap"] = 6
			main.player.position = crook.global_position + Vector2(10, -60)
			_goals_done_until("burn_nest")

## The loop (2026-11-27): loop_waylamp (the Hollow's WayLamp by the way east, the Clinker before it, the
## carved stone after), loop_marsh_climb (the path up out of the marsh, from the cairn), loop_ridge_entry
## (the top of that path on the Ridge, with the glazier's workshop and the lens), loop_travel (three lit
## WayLamps and the fast-travel list at the Hollow's).
func _loop_setup() -> void:
	var f: FogGrid = main.fog
	for k in Story.TIPS:
		Story.tips_seen[k] = true
	for w in get_tree().get_nodes_in_group("waylamp"):
		Progress.notes_read["waylamp_" + w.id] = true
	match view:
		"loop_waylamp":
			main.player.position = f.tile_center(Vector2i(75, 126))
			_lantern(f.tile_center(Vector2i(74, 128)))
			_lantern(f.tile_center(Vector2i(80, 129)))
			Progress.unlock("post")
			_goals_done_until("kindle_hollow")
		"loop_marsh_climb":
			Progress.settled[FogGrid.R_HOLLOW] = true
			Progress.settled[FogGrid.R_MARSH] = true
			main.player.position = f.tile_center(Vector2i(124, 86))
			for t in [Vector2i(128, 94), Vector2i(121, 82)]:
				_lantern(f.tile_center(t))
			_goals_done_until("climb_north")
		"loop_ridge_entry":
			Progress.settled[FogGrid.R_HOLLOW] = true
			Progress.settled[FogGrid.R_MARSH] = true
			main.player.position = f.tile_center(Vector2i(101, 55))
			for t in [Vector2i(100, 57), Vector2i(101, 49)]:
				_lantern(f.tile_center(t), "post")
			_goals_done_until("glazier")
		"loop_travel":
			for r in [FogGrid.R_HOLLOW, FogGrid.R_MARSH, FogGrid.R_RIDGE]:
				Progress.settled[r] = true
			for w in get_tree().get_nodes_in_group("waylamp"):
				if w.id == "hollow":
					main.player.position = w.global_position + Vector2(0, 48)
			_goals_done_until("descend")

## Marks every goal before this one done, so the HUD shows a goal that fits the shot.
func _goals_done_until(goal_id: String) -> void:
	for g in Story.GOALS:
		if g["id"] == goal_id:
			break
		Story.done[g["id"]] = true
	Story.update(main)

## Staged scenes for the README screenshots.
func _readme_setup() -> void:
	var f: FogGrid = main.fog
	var s: Vector2 = main.start
	var sp = main.get_node("FogLayer/Wicklings")
	var old: Lantern = main.get_node("Lanterns").get_child(0)
	Story.player_name = "Tess"
	for k in Story.TIPS:
		Story.tips_seen[k] = true
	if view != "readme_hollow":
		Story.pointer_mode = "off"
	match view:
		"readme_hollow":
			old.light_by_touch()
			_lantern(s + Vector2(-250, 150))
			_lantern(s + Vector2(230, 230))
			_lantern(s + Vector2(-20, 300))
			Inventory.counts["scrap"] = 7
			Progress.notes_read["ledger"] = true
			Story.note_built("post")
			main.player.position = s + Vector2(70, 120)
			for p in [s + Vector2(-560, 260), s + Vector2(540, 60), s + Vector2(330, 540)]:
				sp.spawn_at(p)
			Story.update(main)
		"readme_ward":
			old.light_by_touch()
			_lantern(s + Vector2(-240, 90))
			main.player.position = s + Vector2(60, 230)
			for off in [Vector2(80, -30), Vector2(-70, 40), Vector2(60, 75), Vector2(-20, -85)]:
				var w = sp.spawn_at(main.player.position + off)
				w.state = Wickling.State.CHASE
			Inventory.counts["scrap"] = 3
			_goals_done_until("build_post")
		"readme_marsh":
			for t in [Vector2i(160, 136), Vector2i(172, 136), Vector2i(184, 136), Vector2i(176, 146)]:
				_lantern(f.tile_center(t))
			_lantern(f.tile_center(Vector2i(194, 136)), "reservoir")
			Progress.unlock("reservoir")
			old.light_by_touch()
			main.player.position = f.tile_center(Vector2i(178, 136))
			Inventory.counts["scrap"] = 4
			_goals_done_until("climb_north")   # the pump is awake, so the Reservoir Lamp is unlocked
		"readme_ridge":
			var c := f.tile_center(Vector2i(68, 34))
			main.player.position = c + Vector2(-20, 60)
			_lantern(c + Vector2(-160, 0), "hooded")
			var m := _lantern(c + Vector2(-60, 0), "mirror")
			m.mirror_dir = 0
			var m2 := _lantern(c + Vector2(230, 0), "mirror")
			m2.mirror_dir = 2
			_lantern(c + Vector2(60, 120), "hooded")
			Progress.unlock("reservoir")
			Progress.unlock("hooded")
			Progress.unlock("mirror")
			Inventory.counts["scrap"] = 6
			old.light_by_touch()
			_goals_done_until("descend")
		"readme_map":
			for i in f.remembered.size():
				var reg: int = f.region[i]
				if reg == FogGrid.R_HOLLOW or reg == FogGrid.R_MARSH or (reg == FogGrid.R_RIDGE and i / f.cols > 36):
					f.remembered[i] = 1
					f.density[i] = minf(f.density[i], 0.7)
			f.mark_all_dirty()   # the fog's sparse update must see tiles written directly
			old.light_by_touch()
			for t in [Vector2i(72, 132), Vector2i(88, 136), Vector2i(104, 134), Vector2i(120, 136), Vector2i(140, 136), Vector2i(160, 136), Vector2i(184, 136), Vector2i(48, 104), Vector2i(60, 60)]:
				_lantern(f.tile_center(t))
			_lantern(f.tile_center(Vector2i(194, 136)), "reservoir")
			_lantern(f.tile_center(Vector2i(172, 152)), "post")
			_lantern(f.tile_center(Vector2i(80, 52)), "post", true)
			for r in [FogGrid.R_HOLLOW, FogGrid.R_MARSH, FogGrid.R_RIDGE]:
				Progress.reveal_region(r, FogGrid.REGION_NAMES[r])
			main.player.position = f.tile_center(Vector2i(120, 136))
		"readme_lanterns":
			old.light_by_touch()
			_lantern(s + Vector2(-140, 90))
			_lantern(s + Vector2(60, 150))
			main.player.position = s + Vector2(-20, 30)
			_goals_done_until("build_post")
		"readme_relight":
			main.player.position = old.global_position + Vector2(-34, 44)


func _m1a_setup() -> void:
	var s: Vector2 = main.start
	main.player.position = s + Vector2(-20, 30)
	main.player.lamp_charge = 1.0
	if view == "m1a_lampfire":
		var foes := main.get_node("FogLayer/Wicklings")
		for off in [Vector2(180, -24), Vector2(260, 10), Vector2(300, 40)]:
			var w = foes.spawn_at(main.player.global_position + off)
			w.stun(8.0)
		main.player.combat.aim_override = Vector2.RIGHT
		for i in 4: main.player.combat.skill("lampfire").fire()
	elif view in ["m1a_fireglobe_marker", "m1a_fireglobe_ground"]:
		var combat = main.player.combat
		combat.aim_override = Vector2(210, 0)
		combat.update_aim(Vector2.ZERO)
		combat.skill("fireglobe").press()
		var target: Vector2 = combat.globe_target()
		if view == "m1a_fireglobe_ground":
			var w = main.get_node("FogLayer/Wicklings").spawn_at(target + Vector2(24, 0))
			w.stun(8.0)


# --- M1b views (no more tending) ----------------------------------------------------------------------------------

var _m1b_lamp: Lantern
var _m1b_wl: WayLamp

func _m1b_setup() -> void:
	var s: Vector2 = main.start
	var f: FogGrid = main.fog
	var T := FogGrid.TILE
	var hut: Lantern = get_tree().get_nodes_in_group("lantern").filter(func(l): return l.global_position.distance_to(main.start_lantern_pos) < 8.0)[0]
	match view:
		"m1b_opening", "m1b_opening_lit":
			main.player.position = hut.global_position + Vector2(-30, 26)
			Story.update(main)
		"m1b_faint", "m1b_wake":
			hut.light_by_touch()
			Progress.notes_read["ledger"] = true
			_goals_done_until("relight_waypost")
			Progress.wick = 5
			main.player.position = hut.global_position + Vector2(300, -40)
			main.player.warmth = 2.0
		"m1b_lures":
			main.player.position = f.tile_center(Vector2i(50, 112))
			main.player.lamp_charge = 0.0
			for k in Story.TIPS:
				Story.tips_seen[k] = true
			_goals_done_until("build_post")
		"m1b_ember", "m1b_kindle":
			for k in Story.TIPS:
				Story.tips_seen[k] = true
			for w in get_tree().get_nodes_in_group("waylamp"):
				if w.id == "hollow":
					_m1b_wl = w
			Progress.notes_read["waylamp_hollow"] = true
			hut.light_by_touch()
			_goals_done_until("kindle_hollow")
			main.player.position = _m1b_wl.global_position + Vector2(90, 120)
			_m1b_wl.touch()

func _m1b_frame() -> void:
	var hud = main.get_node("HUD")
	if frame >= 3:
		hud.banner.visible = false
		hud.toast.visible = false
		hud.tip.visible = view in ["m1b_wake"]
	match view:
		"m1b_opening_lit":
			if frame == 20:
				main.player.begin_interact()   # one touch lights it
		"m1b_faint":
			if frame == 25:
				main.player.chill(10.0)   # the cold takes them: the faint note
		"m1b_wake":
			if frame == 10:
				main.player.chill(10.0)
			if frame == 12:
				main.get_node("NoteReader").close()
		"m1b_ember":
			if _m1b_wl == null:
				return
			var b: Ashbrood = _m1b_wl.guardian()
			if b:
				b._puff_t = 99.0   # no puff in the shot: the ember is the subject
				b._wave_t = 99.0
		"m1b_kindle":
			if _m1b_wl == null:
				return
			var b: Ashbrood = _m1b_wl.guardian()
			if b:
				b._puff_t = 99.0
				b._wave_t = 99.0
			if frame == 40 and b:
				b.end_phase_pause()
				b.shell = 0.0
				b.hurt(b.hp + 1.0, false, "lance")
				b.end_phase_pause()
				b.shell = 0.0
				b.hurt(b.hp + 1.0, false, "lance")

# --- M1c views (lamps in the fight) -------------------------------------------------------------------------------

var _m1c_foes: Array = []
var _m1c_brood: Ashbrood

func _m1c_setup() -> void:
	var s: Vector2 = main.start
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for p in get_tree().get_nodes_in_group("enemy_pack"):
		p.queue_free()
	for k in Story.TIPS:
		Story.tips_seen[k] = true
	Story.pointer_mode = "off"
	var sp = main.get_node("FogLayer/Wicklings")
	match view:
		"m1c_dark_lit", "m1c_lock":
			var spot := s + Vector2(-360, 140)
			main.player.position = spot + Vector2(0, 90)
			main.player.lamp_charge = 0.15   # a small hand lamp: the dark foe stays dark
			var lamp := _lantern(spot + Vector2(150, -20))
			for i in 2:
				var w := Wickling.new()
				w.elite = true
				w.position = spot + Vector2(-120, -30) if i == 0 else lamp.position + Vector2(-100, 40)
				sp.add_child(w)
				w.set_process(false)
				w.hp_max = w.hp
				w.hp *= 0.7
				w.since_hurt = 0.0
				_m1c_foes.append(w)
		"m1c_ash_bolts":
			var wl: WayLamp = null
			for w in get_tree().get_nodes_in_group("waylamp"):
				if w.id == "hollow":
					wl = w
			Progress.notes_read["waylamp_hollow"] = true
			for l in get_tree().get_nodes_in_group("lantern"):
				if l.global_position.distance_to(main.rim_lamp_pos) < 8.0:
					l.light_by_touch()
			main.player.position = wl.global_position + Vector2(40, 200)
			wl.touch()
			_m1c_brood = wl.guardian()
		"m1c_pips":
			Progress.unlock("post")
			Progress.level = 4
			main.player.position = s + Vector2(-20, 60)
			_lantern(s + Vector2(-200, 90))
			_lantern(s + Vector2(80, 170))
			main.player.replant_t = Tuning.kl_lamp_replant_cd * 0.4

func _m1c_frame() -> void:
	var hud = main.get_node("HUD")
	if frame >= 3:
		hud.banner.visible = false
		hud.toast.visible = false
		hud.tip.visible = false
	match view:
		"m1c_dark_lit", "m1c_lock":
			for w in _m1c_foes:
				if is_instance_valid(w):
					w.since_hurt = 0.0
					if frame < 6:
						w.shell = Tuning.kl_dark_shell_floor if w == _m1c_foes[0] else w.shell_max * 0.6
					w.update_light_state(1.0 / 30.0)
					w.self_modulate = w.light_tint()
					w.queue_redraw()
			if view == "m1c_lock" and frame == 8:
				main.player.combat.lock._set_target(_m1c_foes[1])
		"m1c_ash_bolts":
			if _m1c_brood:
				_m1c_brood._puff_t = 99.0
				_m1c_brood._wave_t = 99.0
				_m1c_brood._sweep_cd = 99.0
				if frame == 20:
					_m1c_brood._bolt_t = 0.0
					_m1c_brood._idle_t = 99.0
		"m1c_pips":
			main.player.replant_t = Tuning.kl_lamp_replant_cd * 0.4

# --- Readability views (telegraphs, the keeper's feedback) -------------------------------------------------------

var _tell_foe: Node2D
var _tell_spot := Vector2.ZERO

func _tell_setup() -> void:
	var s: Vector2 = main.start
	for f in get_tree().get_nodes_in_group("foe"):
		f.queue_free()
	for p in get_tree().get_nodes_in_group("enemy_pack"):
		p.queue_free()
	for k in Story.TIPS:
		Story.tips_seen[k] = true
	Story.pointer_mode = "off"
	_tell_spot = s + Vector2(-20, 60)
	main.player.position = _tell_spot
	main.player.lamp_charge = 1.0
	if not view.begins_with("tell_dive") and view != "sprites":
		_lantern(s + Vector2(-260, -40))   # some light for context (a dive would go for it)
	var sp = main.get_node("FogLayer/Wicklings")
	match view:
		"tell_puff", "tell_puff_reduce", "tell_adds":
			var b := Ashbrood.new()
			b._puff_t = 99.0
			b._wave_t = 99.0
			b.position = _tell_spot + Vector2(90, -30)
			sp.add_child(b)
			_tell_foe = b
			if view == "tell_puff_reduce":
				Settings.reduce_flashes = true
			if view == "tell_adds":
				for a in [0.4, 2.6]:
					var w = sp.spawn_at(b.position + Vector2.from_angle(a) * 120.0)
					w.bold = true
		"tell_dive", "tell_dive_arrow":
			var b := Ashbrood.new()
			b.phase = 2
			b._dive_t = 99.0
			b.position = _tell_spot + Vector2(-190, -120)
			sp.add_child(b)
			_tell_foe = b
			var lamp_at := _tell_spot + (Vector2(150, 60) if view == "tell_dive" else Vector2(760, 120))
			_lantern(lamp_at)
		"tell_spit":
			var w := Spitwick.new()
			w.position = _tell_spot + Vector2(210, -110)
			w._shot_t = 99.0
			sp.add_child(w)
			_tell_foe = w
		"tell_lane":
			var c := Clinker.new()
			c.position = _tell_spot + Vector2(200, -60)
			c._cooldown = 99.0
			sp.add_child(c)
			_tell_foe = c
		"tell_reach":
			var a = sp.spawn_at(_tell_spot + Vector2(70, 10))
			a.state = Wickling.State.CHASE
			var e = sp.spawn_at(_tell_spot + Vector2(-60, 10), true)
			e.state = Wickling.State.CHASE
			_tell_foe = a
		"tell_hatch":
			var n := WickNest.new()
			n.foe_id = "capture_nest"
			n.position = _tell_spot + Vector2(110, -20)
			sp.add_child(n)
			_tell_foe = n
		"keeper_hurt":
			var w := Spitwick.new()
			w.position = _tell_spot + Vector2(-180, 0)
			w._shot_t = 99.0
			sp.add_child(w)
		"sprites":
			_sprites_lineup(sp)
	for i in 30:
		main.fog.step(0.1)

## Per frame: start each attack so the last frame (45, at 30 fps) shows it part-way.
func _tell_frame() -> void:
	var c = main.player.combat
	match view:
		"tell_puff":
			if frame == 30:
				_tell_foe._puff_t = 0.0
		"tell_puff_reduce":
			if frame == 15:
				_tell_foe._puff_t = 0.0   # 1.0 s later, at frame 45, it is at its commit
		"tell_adds":
			if frame == 25:
				_tell_foe._wave_t = 0.0
		"tell_dive", "tell_dive_arrow":
			if frame == 28:
				_tell_foe._dive_t = 0.0
		"tell_spit":
			if frame == 25:
				_tell_foe._shot_t = 0.0   # at frame 45 its aim has just locked
		"tell_lane":
			if frame == 8:
				_tell_foe._wake_t = 0.0
			if frame == 30:
				_tell_foe._cooldown = 0.0
		"tell_reach":
			for w in get_tree().get_nodes_in_group("wickling"):
				if w.elite:
					w.global_position = main.player.global_position + Vector2(-26, 8)
				elif frame >= 40:
					w.global_position = main.player.global_position + Vector2(20, -4)
		"tell_hatch":
			if frame == 20:
				_tell_foe.set_time_to_hatch(Tuning.kl_nest_hatch_tell + 0.15)
		"keeper_dash":
			if frame == 42:
				c.dash_cd = 0.0
				c.dash(Vector2(1, -0.25))
		"keeper_cast":
			c.aim_override = Vector2(1, -0.3)
			if frame == 40:
				c.skill("lampfire").fire()
			if frame == 43:
				c.skill("lance").cd = 0.0
				c.skill("lance").press()
		"keeper_drink":
			if frame == 36:
				main.player.flask_lock = 0.0
				main.player.drink()
		"keeper_hurt":
			if frame == 43:
				main.player.chill(12.0)

## The sprites view: each subject frozen in place (stunned, attacks held off) in two rows around the keeper.
func _sprites_lineup(sp: Node) -> void:
	var o := _tell_spot + Vector2(-60, 300)   # out of the hut lantern's light (it would burn the Wicklings)
	main.player.position = o
	var row1 := o + Vector2(-260, -90)
	var kinds := [["timid", false], ["brave", false], ["elite", true], ["broken", true]]
	for i in kinds.size():
		var w: Wickling = sp.spawn_at(row1 + Vector2(i * 56, 0), kinds[i][1])
		w.stun(999.0)
		w.timid = kinds[i][0] == "timid"
		if w._art:
			w._art.set_variant("elite" if w.elite else ("timid" if w.timid else "brave"))
		if kinds[i][0] == "broken":
			w.shell = 0.0
	var spit := Spitwick.new()
	spit._shot_t = 999.0
	spit.position = row1 + Vector2(240, 0)
	sp.add_child(spit)
	spit.stun(999.0)
	var nest := WickNest.new()
	nest.foe_id = "capture_nest"
	nest.position = row1 + Vector2(310, 0)
	sp.add_child(nest)
	var b1 := Ashbrood.new()
	b1._puff_t = 999.0
	b1._wave_t = 999.0
	b1.position = o + Vector2(-200, 110)
	sp.add_child(b1)
	b1.stun(999.0)
	var b2 := Ashbrood.new()
	b2.phase = 2
	b2._dive_t = 999.0
	b2.position = o + Vector2(-60, 110)
	sp.add_child(b2)
	b2.stun(999.0)
	var amos := Node2D.new()
	amos.position = o + Vector2(90, 110)
	amos.z_index = 8
	sp.add_child(amos)
	FoeSprite.attach(amos, "amos")
	var cart := Art.prop("amos", "amos_cart")
	if cart:
		var c := Sprite2D.new()
		c.texture = cart
		c.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		c.scale = Vector2(Art.SCALE, Art.SCALE)
		c.offset = Vector2(0, -cart.get_height() / 2.0)
		c.position = amos.position + Vector2(80, 0)
		c.z_index = 8
		sp.add_child(c)
