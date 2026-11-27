extends Node
## Keeper's Light (PROTOTYPE): the combat kit. Beam, burst, dash, lamp charge as stamina, shelled
## elites. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_combat.tscn

var main: Node
var frame := 0
var fails := 0
var fog: FogGrid
var player: Node
var c: KeeperCombat
var spawner: Node
var spot := Vector2.ZERO
var knocked: Wickling
var knock_from := 0.0
var dash_from := Vector2.ZERO

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
	process_mode = Node.PROCESS_MODE_ALWAYS
	strip_real_input()
	Tuning.wick_enabled = false   # only the Wicklings this test makes
	Story.skip_opening = true
	SaveGame.path = "user://test_combat_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _w(p: Vector2, elite := false) -> Wickling:
	return spawner.spawn_at(p, elite)

func _clear() -> void:
	for w in get_tree().get_nodes_in_group("wickling"):
		w.queue_free()

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		2:
			fog = main.fog
			player = main.player
			c = player.combat
			spawner = main.get_node("FogLayer/Wicklings")
			main.get_node("Wind").force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
			check(c != null, "the keeper carries the combat kit")
			spot = main.start + Vector2(-500, 0)   # out in the dark, away from every lantern
			player.global_position = spot
			player.lamp_charge = 1.0
			# Aim and the beam's reach.
			c.aim_override = Vector2(1, 0)
			c.update_aim(Vector2.ZERO)
			c.beaming = true
			var seg: Array = c.beam_segment()
			check(seg.size() == 2 and is_equal_approx(seg[0].distance_to(seg[1]), Tuning.kl_beam_len), "the beam reaches %d px along your aim" % int(Tuning.kl_beam_len))
			var w_in := _w(player.global_position + Vector2(150, -10))
			var w_out := _w(player.global_position + Vector2(150, 80))
			var w_far := _w(player.global_position + Vector2(Tuning.kl_beam_len + 60, -10))
			c.burn_along_beam(0.25)
			check(w_in.hp < Tuning.wick_hp, "the beam burns what it touches")
			check(w_out.hp == Tuning.wick_hp and w_far.hp == Tuning.wick_hp, "and nothing beside it or past its end")
			c.burn_along_beam(0.3)
			check(not is_instance_valid(w_in) or w_in.is_queued_for_deletion(), "a Wickling burns away in about half a second of beam")
			c.beaming = false
			_clear()
		4:
			# Holding the beam button: it fires, costs charge, lights the fog along it, slows you.
			player.lamp_charge = 1.0
			Input.action_press("beam")
		20:
			check(c.beaming, "holding the beam button fires the beam")
			check(c.beam_snd.playing and c.beam_snd.volume_db > -60.0, "the beam's sound loop plays while it fires")
			check(c.beam_snd.stream is AudioStreamOggVorbis and (c.beam_snd.stream as AudioStreamOggVorbis).loop, "and it is a loop")
			for bus in ["SFX", "Music", "Ambience"]:
				check(AudioServer.get_bus_index(bus) != -1, "the %s audio bus exists" % bus)
			var mus = main.get_node("Music")
			check(mus.player.bus == "Music" and mus.player.stream is AudioStreamMP3 and (mus.player.stream as AudioStreamMP3).loop, "the Hollow's music is a looping track on the Music bus")
			check(mus.wanted and mus.player.playing, "the Hollow's music plays while the keeper is in the Hollow")
			var bed = main.get_node("HollowBed")
			check(bed.players.size() == 2 and bed.players.all(func(p): return p.bus == "Ambience" and p.stream.loop), "the Hollow's wind and crickets are looping layers on the Ambience bus")
			check(bed.wanted and bed.players.all(func(p): return p.playing), "and they play while the keeper is in the Hollow")
			check(player.lamp_charge < 1.0, "the beam spends lamp charge")
			fog.step(0.1)
			var mid: Vector2 = player.global_position + Vector2(0, -10) + c.aim * Tuning.kl_beam_len * 0.6
			check(fog._light[fog.idx(fog.tile_of(mid))] > 0.0, "the beam lights the fog along its path")
			player.lamp_charge = 0.0
		24:
			check(not c.beaming, "an empty lamp can't fire the beam")
			Tuning.vol_music_db = -10.0
			Mix._process(0.0)
			check(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), -10.0), "the music volume slider moves the Music bus")
			Tuning.vol_music_db = 0.0
			Input.action_release("beam")
			player.lamp_charge = 1.0
		26:
			# The burst: hits what's close, throws it back, has a cooldown, costs charge.
			var near := _w(player.global_position + Vector2(60, 0))
			var outside := _w(player.global_position + Vector2(Tuning.kl_burst_radius + 60, 0))
			var before: float = player.lamp_charge
			check(c.burst() >= 1, "the burst hits what's close")
			check(is_equal_approx(near.hp, Tuning.wick_hp - Tuning.kl_burst_dmg) and outside.hp == Tuning.wick_hp, "it burns only inside its radius")
			check(is_equal_approx(player.lamp_charge, before - Tuning.kl_burst_cost), "it costs lamp charge")
			check(c.burst() == -1, "and it has a cooldown")
			knocked = near
			knock_from = near.global_position.distance_to(player.global_position)
		40:
			check(is_instance_valid(knocked) and knocked.global_position.distance_to(player.global_position) > knock_from + 60.0, "the burst throws things back (%.0f -> %.0f px)" % [knock_from, knocked.global_position.distance_to(player.global_position) if is_instance_valid(knocked) else -1.0])
			_clear()
			c.burst_cd = 0.0
			# The dash: quick, can't be chilled during it, has a cooldown.
			dash_from = player.global_position
			player.lamp_charge = 1.0
			Input.action_press("move_right")
			Input.action_press("dash")
		41:
			Input.action_release("dash")
			check(c.is_dashing(), "the dash starts")
			var w0: float = player.warmth
			player.chill(50.0)
			check(player.warmth == w0, "nothing can chill you mid-dash")
		60:
			Input.action_release("move_right")
			var moved: float = player.global_position.x - dash_from.x
			check(moved > Tuning.kl_dash_dist * 0.9, "the dash carries you about %d px (%.0f)" % [int(Tuning.kl_dash_dist), moved])
			check(not c.dash(Vector2.RIGHT) or c.dash_cd > 0.0, "the dash has a cooldown")
		62:
			# A shelled elite: only a beam wears the shell down.
			c.burst_cd = 0.0
			c.dash_cd = 0.0
			player.lamp_charge = 1.0
			var e := _w(player.global_position + Vector2(70, 0), true)
			check(e.elite and e.shell == Tuning.kl_elite_shell and e.hp == Tuning.kl_elite_hp, "an elite is bigger and shelled")
			c.burst()
			check(e.hp == Tuning.kl_elite_hp and e.shell == Tuning.kl_elite_shell, "the burst glances off its shell")
			e.hurt(5.0, false, "core")
			check(e.hp == Tuning.kl_elite_hp, "so does a lantern's core")
			c.aim_override = Vector2(1, 0)
			c.update_aim(Vector2.ZERO)
			c.beaming = true
			c.burn_along_beam(Tuning.kl_elite_shell / Tuning.kl_beam_dps + 0.1)
			check(e.shell <= 0.0 and e.hp < Tuning.kl_elite_hp, "the beam cracks the shell and burns through")
			c.burn_along_beam(Tuning.kl_elite_hp / Tuning.kl_beam_dps)
			check(not is_instance_valid(e) or e.is_queued_for_deletion(), "and burns the elite away")
			c.beaming = false
			_clear()
			# A Wickling burned over rock drops its ember on ground you can walk on.
			var rock := Vector2i(-1, -1)
			for y in range(fog.rows):
				for x in range(fog.cols):
					var q := Vector2i(x, y)
					if rock.x < 0 and fog.solid[fog.idx(q)] == 1 and fog.in_bounds(q + Vector2i(2, 0)) and fog.solid[fog.idx(q + Vector2i(2, 0))] == 0 and fog.region[fog.idx(q + Vector2i(2, 0))] == FogGrid.R_HOLLOW:
						rock = q   # rock right at the edge of the Hollow
			check(rock.x >= 0, "found rock at the Hollow's edge")
			for em in get_tree().get_nodes_in_group("ember"):
				em.free()
			var over_rock := _w(fog.tile_center(rock))
			over_rock.hurt(99.0)
			var landed := get_tree().get_nodes_in_group("ember").filter(func(em): return not em.is_queued_for_deletion())
			check(landed.size() >= 1 and landed.all(func(em): return fog.solid[fog.idx(fog.tile_of(em.global_position))] == 0), "drops from a Wickling over rock land on walkable ground")
			for em in landed:
				em.queue_free()
			# Every Nth Wickling out of the fog is an elite.
			Tuning.wick_enabled = true
			var elites := 0
			for i in Tuning.kl_elite_every * 3:
				var w = spawner.spawn_near_player()
				if w and w.elite:
					elites += 1
			check(elites >= 2, "every %dth Wickling out of the fog is an elite (%d of %d)" % [Tuning.kl_elite_every, elites, Tuning.kl_elite_every * 3])
			Tuning.wick_enabled = false
			_clear()
		64:
			SaveGame.delete_save()
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
