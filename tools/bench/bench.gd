extends Node
## Performance benchmark (not a test). Loads the game, places 30 lanterns and keeps 20 foes alive
## around the keeper, adds 40 in-flight fire bolts, then measures a few hundred frames and prints a short table.
## Headless (game logic only):
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/bench/bench.tscn
## With rendering (adds the whole-frame time and draw calls; silent, on a virtual display):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --audio-driver Dummy --fixed-fps 60 --disable-vsync \
##     --path . res://tools/bench/bench.tscn
## Optional user args after "--": lanterns foes frames, e.g. "-- 30 20 600".
## Budget (DECISIONS.md): game logic (process + physics) well under 4 ms a frame at 30 lanterns and 20 foes.

const WARMUP := 30
const BUDGET_MS := 4.0

var main: Node
var frame := 0
var lanterns := 30
var foes := 20
var frames := 400
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
	# Forty simultaneous bolts at a remote walkable tile; they remain alive and exercise the pool's hot path.
	var projectile_tile := Vector2i(-1, -1)
	for y in range(fog.rows):
		for x in range(fog.cols):
			var tile := Vector2i(x, y)
			if fog.solid[fog.idx(tile)] == 0 and fog.tile_center(tile).distance_to(main.start) > 700.0:
				projectile_tile = tile
				break
		if projectile_tile.x >= 0: break
	var origin := fog.tile_center(projectile_tile)
	for i in 40:
		var b = FireBolts.inst.fire_lampfire(origin + Vector2(float(i % 8) * 3.0, float(i / 8) * 3.0), Vector2.RIGHT)
		b.speed = 0.0
		b.reach = 1000000.0

	_keep_foes()

## Keeps the foe count steady around the keeper (lantern cores burn some of them).
func _keep_foes() -> void:
	var alive := 0
	for f in get_tree().get_nodes_in_group("foe"):
		if (f is Wickling or f is Spitwick) and not f.is_queued_for_deletion():
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
	print("BENCH map %dx%d tiles, %d lanterns, %d foes in play (%d foe nodes incl. nests), %d projectiles in flight, %d frames" % [fog.cols, fog.rows, lanterns, foes, n_foes, FireBolts.inst.in_flight(), _proc.size()])
	print("%-26s %9s %9s" % ["", "avg", "worst"])
	_row("process (all _process)", _proc)
	_row("physics (all _physics)", _phys)
	_row("game logic (sum)", logic)
	_row("fog step (per tick)", _fog_ms)
	_row("whole frame (wall)", _frame_ms)
	_row("fog texture update", _tex_ms)
	if DisplayServer.get_name() != "headless":
		_row("draw calls", _draw_calls, "")
	print("%-26s %9d" % ["nodes", int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
	print("%-26s %9d" % ["canvas items drawn (2D)", int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))])
	var st := _stats(logic)
	print("BUDGET game logic avg %.3f ms (budget %.1f ms): %s" % [st[0], BUDGET_MS, "within" if st[0] < BUDGET_MS else "OVER"])
	SaveGame.delete_save()
