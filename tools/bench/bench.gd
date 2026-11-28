extends Node
## Performance benchmark (not a test). Loads the game, places 30 lanterns and keeps 20 foes alive
## around the keeper, then measures a few hundred frames and prints a short table. A fight runs the whole time at a
## firing range away from the keeper: 40 Lampfire bolts always in the air, flying at and hitting 8 target foes
## (so every frame has real hits, splash, impact effects and damage numbers), with 4 burning areas under them.
## Headless (game logic only):
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/bench/bench.tscn
## With rendering (adds the whole-frame time and draw calls; silent, on a virtual display):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --audio-driver Dummy --fixed-fps 60 --disable-vsync \
##     --path . res://tools/bench/bench.tscn
## Optional user args after "--": lanterns foes frames bolts burning, e.g. "-- 30 20 600" or, for the world with no
## fight, "-- 30 20 400 0 0".
## A sixth argument "profile" also times each kind of node on its own (the bench runs their _process and
## _physics_process itself, in the same frame), e.g. "-- 30 20 400 40 4 profile".
## "tells=N" (readability step) adds a telegraph-heavy fight at the keeper: N Spitwicks on screen winding up
## without a pause, the Ashbrood (puffs and adds) and the Clinker (rolls), e.g. "-- 30 20 400 40 4 tells=8".
## Budget (DECISIONS.md): game logic (process + physics) well under 4 ms a frame at 30 lanterns and 20 foes.

const WARMUP := 30
const BUDGET_MS := 4.0
const TARGETS := 8         # foes at the firing range (they never die: huge health)
const RANGE_FROM := 160.0  # px: bolts start this far from the range's centre, so each flies ~0.3 s before it hits

var main: Node
var frame := 0
var lanterns := 30
var foes := 20
var frames := 400
var bolts := 40            # Lampfire bolts kept in the air at the firing range
var burning := 4           # burning areas at the firing range
var fog: FogGrid
var spawner: Node
var _rng := RandomNumberGenerator.new()
var _proc := PackedFloat32Array()
var _phys := PackedFloat32Array()
var _fog_ms := PackedFloat32Array()
var _frame_ms := PackedFloat32Array()
var _draw_calls := PackedFloat32Array()
var _tex_ms := PackedFloat32Array()
var _last_us := 0
var _fog_acc := 0.0
var _tail: Node
var _proc_start := 0
var _phys_start := 0
var _proc_now := 0.0
var _phys_now := 0.0
var _range := Vector2.ZERO
var _targets: Array = []   # untyped: has() is asked about Spitwicks too
var _hits0 := 0
var _paused_frames := 0
var _tells0 := 0
var _tells_live := 0       # foe wind-ups alive, summed over the measured frames
var profile := false
var tells := 0             # Spitwicks kept winding up at the keeper ("tells=N")
var _tellers: Array = []
var _prof := {}            # kind -> PackedFloat32Array: ms a frame spent in that kind's process + physics
var _prof_now := {}        # kind -> ms so far this frame

## Kinds of node the profile mode times on its own (everything else is in "the rest").
const PROFILE_KINDS := ["foes", "fire_bolts", "fire_fx", "damage_numbers", "burning_ground", "lanterns", "player", "telegraphs"]

## Runs after every other node (high priority number) so the bench can time the whole process
## and physics passes itself (Performance.TIME_PROCESS is not reliable headless).
class Tail extends Node:
	var bench: Node
	func _process(_d: float) -> void:
		bench._proc_now = (Time.get_ticks_usec() - bench._proc_start) / 1000.0
	func _physics_process(_d: float) -> void:
		bench._phys_now = (Time.get_ticks_usec() - bench._phys_start) / 1000.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for action in InputMap.get_actions():
		for e in InputMap.action_get_events(action):
			if e is InputEventJoypadButton or e is InputEventJoypadMotion:
				InputMap.action_erase_event(action, e)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		lanterns = int(args[0])
	if args.size() > 1:
		foes = int(args[1])
	if args.size() > 2:
		frames = int(args[2])
	if args.size() > 3:
		bolts = int(args[3])
	if args.size() > 4:
		burning = int(args[4])
	for a in args.slice(5):
		if a == "profile":
			profile = true
			for k in PROFILE_KINDS:
				_prof[k] = PackedFloat32Array()
				_prof_now[k] = 0.0
		elif a.begins_with("tells="):
			tells = int(a.substr(6))
	seed(7)
	_rng.seed = 7
	Story.skip_opening = true
	SaveGame.path = "user://bench_ignore_save.json"   # never read or write the player's real save
	SaveGame.delete_save()
	process_priority = -1000
	process_physics_priority = -1000
	_tail = Tail.new()
	_tail.bench = self
	_tail.process_mode = Node.PROCESS_MODE_ALWAYS
	_tail.process_priority = 1000
	_tail.process_physics_priority = 1000
	add_child(_tail)
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _physics_process(_delta: float) -> void:
	_phys_start = Time.get_ticks_usec()
	if profile and frame > 2:
		for k in PROFILE_KINDS:
			_prof_run(k, _delta, true)

## Profile mode: the nodes of one kind.
func _prof_nodes(kind: String) -> Array:
	match kind:
		"foes":
			return get_tree().get_nodes_in_group("foe")
		"fire_bolts":
			return [FireBolts.inst] if FireBolts.inst else []
		"fire_fx":
			return [FireFx.inst] if FireFx.inst else []
		"damage_numbers":
			return [DamageNumbers.inst] if DamageNumbers.inst else []
		"burning_ground":
			return get_tree().get_nodes_in_group("burning_ground")
		"lanterns":
			return get_tree().get_nodes_in_group("lantern")
		"player":
			return [main.player]
		"telegraphs":
			return get_tree().get_nodes_in_group("telegraph_layer")
	return []

## Profile mode: runs one kind's _process (or _physics_process) here, timed, instead of in the tree.
func _prof_run(kind: String, delta: float, physics: bool) -> void:
	var t0 := Time.get_ticks_usec()
	for n in _prof_nodes(kind):
		if not is_instance_valid(n) or n.is_queued_for_deletion():
			continue
		if physics:
			if n.has_method("_physics_process"):
				n.set_physics_process(false)
				n._physics_process(delta)
		else:
			# FireFx and DamageNumbers switch their own processing on when they have work: honour that.
			var own := true
			if n is FireFx:
				own = n.count() > 0 or not n._scorch.is_empty()
			elif n is DamageNumbers:
				own = n.count() > 0
			if n.has_method("_process") and own:
				n.set_process(false)
				n._process(delta)
	_prof_now[kind] += (Time.get_ticks_usec() - t0) / 1000.0

func _process(_delta: float) -> void:
	_proc_start = Time.get_ticks_usec()
	frame += 1
	if frame == 2:
		_setup()
		return
	if frame < 2:
		return
	var now := Time.get_ticks_usec()
	# The fog's own tick, run here so its step can be timed (same accumulator as FogGrid._process).
	_fog_acc += _delta
	var fog_ms := 0.0
	if _fog_acc >= FogGrid.TICK:
		var t0 := Time.get_ticks_usec()
		fog.step(_fog_acc)
		fog_ms = (Time.get_ticks_usec() - t0) / 1000.0
		_fog_acc = 0.0
		# The texture update the fog's redraw would do (timed here; the redraw then has nothing left to do).
		t0 = Time.get_ticks_usec()
		fog._rebuild_texture()
		if frame > WARMUP:
			_tex_ms.append((Time.get_ticks_usec() - t0) / 1000.0)
		fog.queue_redraw()
	_keep_foes()
	_keep_bolts()
	if tells > 0:
		_keep_tells()
	if profile:
		for k in PROFILE_KINDS:
			_prof_run(k, _delta, false)
			if frame > WARMUP:
				_prof[k].append(_prof_now[k])
			_prof_now[k] = 0.0
	if get_tree().paused:
		_paused_frames += 1
	if frame > WARMUP:
		_tells_live += Telegraph.active.size()
	if frame > WARMUP:
		# Last frame's passes (the fog tick runs inside the process pass, as in the game).
		_proc.append(_proc_now)
		_phys.append(_phys_now)
		if fog_ms > 0.0:
			_fog_ms.append(fog_ms)
		if _last_us > 0:
			_frame_ms.append((now - _last_us) / 1000.0)
		_draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_last_us = now
	if frame >= WARMUP + frames:
		_report()
		get_tree().quit(0)

func _setup() -> void:
	fog = main.fog
	fog.set_process(false)   # the bench runs the fog tick itself so it can time it
	spawner = get_tree().get_first_node_in_group("wickling_spawner")
	var wind: Wind = main.get_node("Wind")
	wind.force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
	# Lanterns: open ground spiralling out from the start, 3 tiles apart.
	var s := fog.tile_of(main.start)
	var placed := 0
	var kinds := ["post", "post", "post", "reservoir", "hooded", "mirror"]
	var taken: Array[Vector2i] = []
	for r in range(3, 60):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if placed >= lanterns or (absi(dx) != r and absi(dy) != r):
					continue
				var t := s + Vector2i(dx, dy)
				if (dx + dy) % 3 != 0 or fog.terrain_of(t) != FogGrid.T_GROUND:
					continue
				var near := false
				for q in taken:
					if absi(q.x - t.x) < 3 and absi(q.y - t.y) < 3:
						near = true
						break
				if near:
					continue
				taken.append(t)
				var l := Lantern.new()
				l.kind = kinds[placed % kinds.size()]
				l.mirror_dir = placed % 8
				l.fuel = -1.0 if placed % 4 != 0 else 8.0   # a few dying lanterns give Wicklings prey
				l.position = fog.tile_center(t)
				main.get_node("Lanterns").add_child(l)
				placed += 1
	lanterns = placed
	# Foes burned by the lanterns give wick, and the level-up cards would pause the world for the rest of the run
	# (the bench measured a paused world from about frame 100 before this): no cards in the bench.
	var cards = main.get_node("HUD").level_up_screen
	if Progress.level_up.is_connected(cards._on_level_up):
		Progress.level_up.disconnect(cards._on_level_up)
	_setup_range()
	_keep_foes()
	if tells > 0:
		_setup_tells()

## The telegraph-heavy fight: Spitwicks in a ring on screen, the Ashbrood and the Clinker near the keeper.
func _setup_tells() -> void:
	var p: Vector2 = main.player.global_position
	for i in tells:
		var sw := Spitwick.new()
		sw.position = p + Vector2.from_angle(TAU * i / tells) * 220.0
		spawner.add_child(sw)
		_tellers.append(sw)
	var boss := Ashbrood.new()
	boss.position = p + Vector2(-90, 60)
	boss._puff_t = 0.5
	boss._wave_t = 1.0
	spawner.add_child(boss)
	_tellers.append(boss)
	Progress.cleared.erase("clinker_hollow_post")
	var c := Clinker.new()
	c.position = p + Vector2(160, -40)
	spawner.add_child(c)
	_tellers.append(c)

func _keep_tells() -> void:
	main.player.warmth = Tuning.warmth_max   # the keeper never faints out of the fight
	main.player.lamp_charge = 1.0
	for f in _tellers:
		if is_instance_valid(f) and f is Spitwick and f.tell() == null:
			f._shot_t = 0.0
			f.hp = 1000.0
		elif is_instance_valid(f):
			f.hp = maxf(f.hp, 100.0)

## The firing range: open ground well away from the keeper (so its bolts never reach the foes around the keeper),
## with TARGETS foes that can't die in a ring the splash reaches, and `burning` burning areas under them.
func _setup_range() -> void:
	var best := Vector2i(-1, -1)
	for y in range(8, fog.rows - 8):
		for x in range(8, fog.cols - 8):
			var t := Vector2i(x, y)
			if fog.tile_center(t).distance_to(main.start) < 1400.0:
				continue
			var open := true
			for dy in range(-7, 8):
				for dx in range(-7, 8):
					if fog.solid[fog.idx(t + Vector2i(dx, dy))] == 1:
						open = false
						break
				if not open:
					break
			if open:
				best = t
				break
		if best.x >= 0:
			break
	_range = fog.tile_center(best)
	for i in (TARGETS if bolts > 0 or burning > 0 else 0):
		var w: Wickling = spawner.spawn_at(_range + Vector2.from_angle(TAU * i / TARGETS) * 36.0, i % 4 == 0)
		w.hp = 1.0e7
		w.hp_max = 1.0e7
		w.shell = 0.0
		w.stun(1.0e9)
		_targets.append(w)
	for i in burning:
		var g := BurningGround.new()
		g.radius = Tuning.kl_fireglobe_radius
		g.dps = Tuning.kl_fireglobe_burn_dps
		g.life = 1.0e9
		g.position = _range + Vector2.from_angle(TAU * i / maxi(1, burning) + 0.4) * 30.0
		spawner.add_child(g)
	_hits0 = FireBolts.inst.hits
	_tells0 = Telegraph.started

## Keeps `bolts` Lampfire bolts in the air at the range, each fired from the ring around it at one of the targets.
func _keep_bolts() -> void:
	var n := FireBolts.inst.in_flight(FireBolts.LAMPFIRE)
	while n < bolts and not _targets.is_empty():
		var from := _range + Vector2.from_angle(_rng.randf() * TAU) * RANGE_FROM
		var target: Wickling = _targets[_rng.randi() % _targets.size()]
		FireBolts.inst.fire_lampfire(from, target.global_position - from)
		n += 1

## Keeps the foe count steady around the keeper (lantern cores burn some of them).
func _keep_foes() -> void:
	var alive := 0
	for f in get_tree().get_nodes_in_group("foe"):
		if (f is Wickling or f is Spitwick) and not f.is_queued_for_deletion() and not _targets.has(f):
			alive += 1
	var p: Vector2 = main.player.global_position
	var tries := 0
	while alive < foes and tries < 200:
		tries += 1
		var q := p + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(80.0, 520.0)
		var t := fog.tile_of(q)
		if not fog.in_bounds(t) or fog.solid[fog.idx(t)] == 1:
			continue
		if alive % 7 == 3:
			var sw := Spitwick.new()
			sw.position = fog.tile_center(t)
			spawner.add_child(sw)
		else:
			spawner.spawn_at(fog.tile_center(t), alive % 7 == 5)
		alive += 1

func _stats(a: PackedFloat32Array) -> Array:
	if a.is_empty():
		return [0.0, 0.0]
	var sum := 0.0
	var worst := 0.0
	for v in a:
		sum += v
		worst = maxf(worst, v)
	return [sum / a.size(), worst]

func _row(label: String, a: PackedFloat32Array, unit: String = "ms") -> void:
	var st := _stats(a)
	print("%-26s %9.3f %9.3f %s" % [label, st[0], st[1], unit])

func _report() -> void:
	var logic := PackedFloat32Array()
	for i in _proc.size():
		logic.append(_proc[i] + _phys[i])
	var n_foes := 0
	for f in get_tree().get_nodes_in_group("foe"):
		n_foes += 1
	print("")
	print("BENCH map %dx%d tiles, %d lanterns, %d foes in play (%d foe nodes incl. nests and %d range targets), %d frames" % [fog.cols, fog.rows, lanterns, foes, n_foes, TARGETS, _proc.size()])
	var secs := float(frame - 2) / float(Engine.physics_ticks_per_second)
	print("FIGHT %d Lampfire bolts in the air, %d burning areas; %d hits in %.1f s (%.0f a second), %d effects and %d damage numbers alive at the end; %d paused frames" % [
		FireBolts.inst.in_flight(FireBolts.LAMPFIRE), get_tree().get_nodes_in_group("burning_ground").size(), FireBolts.inst.hits - _hits0, secs,
		(FireBolts.inst.hits - _hits0) / maxf(0.01, secs), FireFx.inst.count() if FireFx.inst else -1, DamageNumbers.inst.count() if DamageNumbers.inst else -1, _paused_frames])
	print("TELLS %d foe wind-ups started (Spitwick aims, Wickling reaches...), %.1f alive a frame on average" % [Telegraph.started - _tells0, _tells_live / maxf(1.0, float(_proc.size()))])
	print("%-26s %9s %9s" % ["", "avg", "worst"])
	_row("process (all _process)", _proc)
	_row("physics (all _physics)", _phys)
	_row("game logic (sum)", logic)
	_row("fog step (per tick)", _fog_ms)
	_row("whole frame (wall)", _frame_ms)
	_row("fog texture update", _tex_ms)
	if DisplayServer.get_name() != "headless":
		_row("draw calls", _draw_calls, "")
	if profile:
		for k in PROFILE_KINDS:
			_row("  " + k, _prof[k])
	print("%-26s %9d" % ["nodes", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	print("%-26s %9d" % ["canvas items drawn (2D)", int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))])
	var st := _stats(logic)
	if _paused_frames > 0:
		print("WARNING the world was paused for %d frames: those frames don't measure the game" % _paused_frames)
	print("BUDGET game logic avg %.3f ms, worst %.3f ms (budget %.1f ms): %s" % [st[0], st[1], BUDGET_MS, "within" if st[0] < BUDGET_MS else "OVER"])
	SaveGame.delete_save()
