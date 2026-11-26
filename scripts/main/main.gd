extends Node2D
## Grey-box valley, M3: Region 1 The Hollow (start) and Region 2 The Reedmarsh,
## joined by a rocky passage. The marsh is soft ground; lanterns stand on
## boardwalks and islands. The pumphouse on the far island unlocks the Reservoir Lamp.

const SEED := 11
const HOLLOW_FUEL := 18
const HOLLOW_SCRAP := 16
const MARSH_PEAT := 24
const MARSH_SCRAP := 6

const HOLLOW_C := Vector2(24, 32)
const HOLLOW_R := Vector2(19, 22)
const MARSH_C := Vector2(80, 32)
const MARSH_R := Vector2(28, 24)
const ISLANDS := [Vector3(72, 23, 2), Vector3(76, 42, 2), Vector3(95, 24, 2), Vector3(97, 41, 2), Vector3(59, 43, 2), Vector3(102, 32, 3)]

@onready var fog: FogGrid = $FogLayer/FogGrid
@onready var player: CharacterBody2D = $Player

var start := Vector2.ZERO
var rng := RandomNumberGenerator.new()
var _taken: Array[Vector2] = []

func _ready() -> void:
	Inventory.reset()
	Progress.reset()
	rng.seed = SEED
	_generate()
	_build_rock_collision()
	var size := fog.world_size()
	var cam: Camera2D = $Player/Camera2D
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(size.x)
	cam.limit_bottom = int(size.y)
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 7.0
	start = fog.tile_center(Vector2i(HOLLOW_C))
	player.position = start
	_taken.append(start)
	_add_lantern(start + Vector2(96, 0))
	# Near the hut: a woodpile that always regrows (no soft-lock) and a little scrap.
	_add_resource("fuel", start + Vector2(-64, 32), 3, 5, 10.0, true)
	_add_resource("scrap", start + Vector2(32, -64), 6, 6, 60.0, false)
	_place_landmarks()
	_scatter()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()

# --- Terrain -----------------------------------------------------------------

func _generate() -> void:
	for y in fog.rows:
		for x in fog.cols:
			fog.set_tile(Vector2i(x, y), FogGrid.T_ROCK, 0)
	_carve_ellipse(HOLLOW_C, HOLLOW_R, FogGrid.T_GROUND, FogGrid.R_HOLLOW, 1.3)
	_carve_ellipse(MARSH_C, MARSH_R, FogGrid.T_MARSH, FogGrid.R_MARSH, 4.1)
	# The passage between them, with a firm landing at the marsh edge.
	for x in range(38, 58):
		var wiggle := int(round(sin(x * 0.6)))
		for y in range(30 + wiggle, 35 + wiggle):
			fog.set_tile(Vector2i(x, y), FogGrid.T_GROUND, FogGrid.R_HOLLOW if x < 48 else FogGrid.R_MARSH)
	# Boardwalks.
	_boardwalk(Vector2i(57, 32), Vector2i(104, 32))
	_boardwalk(Vector2i(66, 13), Vector2i(66, 51))
	_boardwalk(Vector2i(88, 17), Vector2i(88, 47))
	_boardwalk(Vector2i(66, 23), Vector2i(72, 23))
	_boardwalk(Vector2i(88, 41), Vector2i(97, 41))
	# Islands of firm ground.
	for c in ISLANDS:
		var cx := int(c.x)
		var cy := int(c.y)
		var cr := int(c.z)
		for y in range(cy - cr, cy + cr + 1):
			for x in range(cx - cr, cx + cr + 1):
				if Vector2(x, y).distance_to(Vector2(c.x, c.y)) <= c.z + 0.3 and fog.terrain_of(Vector2i(x, y)) != FogGrid.T_ROCK:
					fog.set_tile(Vector2i(x, y), FogGrid.T_GROUND, FogGrid.R_MARSH)

func _carve_ellipse(c: Vector2, r: Vector2, t: int, reg: int, phase: float) -> void:
	for y in fog.rows:
		for x in fog.cols:
			var n := Vector2((x + 0.5 - c.x) / r.x, (y + 0.5 - c.y) / r.y)
			var ang := n.angle()
			var wobble := 0.07 * sin(ang * 5.0 + phase) + 0.04 * sin(ang * 11.0 + phase * 2.0)
			if n.length() <= 1.0 + wobble:
				fog.set_tile(Vector2i(x, y), t, reg)

func _boardwalk(a: Vector2i, b: Vector2i) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in steps + 1:
		var t := Vector2i(Vector2(a).lerp(Vector2(b), float(i) / maxf(steps, 1)).round())
		if fog.terrain_of(t) == FogGrid.T_MARSH:
			fog.set_tile(t, FogGrid.T_BOARDWALK, FogGrid.R_MARSH)

func _build_rock_collision() -> void:
	var body := StaticBody2D.new()
	add_child(body)
	for y in fog.rows:
		var x := 0
		while x < fog.cols:
			if fog.solid[y * fog.cols + x] == 0:
				x += 1
				continue
			var x0 := x
			while x < fog.cols and fog.solid[y * fog.cols + x] == 1:
				x += 1
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2((x - x0) * FogGrid.TILE, FogGrid.TILE)
			shape.shape = rect
			shape.position = Vector2((x0 + x) * FogGrid.TILE / 2.0, (y + 0.5) * FogGrid.TILE)
			body.add_child(shape)

# --- Things in the world -----------------------------------------------------

func _place_landmarks() -> void:
	_add_landmark("ledger", "Keepers' ledger", "ledger", start + Vector2(-96, -64),
		"Long columns of tally marks, one for every lamp lit each night.\nNear the end the columns grow short. The last page has a single mark.")
	_add_landmark("stone_way", "Carved stone", "stone", fog.tile_center(Vector2i(40, 30)),
		"KEEP THE WAY TO THE WATER LIT.")
	_add_landmark("frames_east", "Old lantern frames", "frames", fog.tile_center(Vector2i(78, 31)),
		"Three empty frames stand along the boardwalk.\nSomeone turned every one of them to face east, toward the lake.")
	_add_landmark("chalk_lake", "Chalk on the pumphouse wall", "chalk", fog.tile_center(Vector2i(100, 30)),
		"Two drawings of the same lake.\nIn the first it shines, rays drawn all around it.\nIn the second it has been scribbled over in black.")
	var pump := _add_landmark("pumphouse", "The pumphouse", "pumphouse", fog.tile_center(Vector2i(103, 33)),
		"The old pump still turns when you push it. Its tank could feed a lamp for a long time,\nand pipes once ran from here to the posts along the boardwalk.")
	pump.unlock_kind = "reservoir"

func _scatter() -> void:
	_scatter_kind("fuel", "", HOLLOW_FUEL, func(t): return _hollow_spot(t), 4, 8, 8, 60.0)
	_scatter_kind("scrap", "", HOLLOW_SCRAP, func(t): return _hollow_spot(t), 4, 7, 7, 75.0)
	_scatter_kind("fuel", "Peat", MARSH_PEAT, func(t): return _peat_spot(t), 5, 9, 9, 45.0)
	_scatter_kind("scrap", "", MARSH_SCRAP, func(t): return _island_spot(t), 4, 7, 7, 75.0)

func _hollow_spot(t: Vector2i) -> bool:
	var p := fog.tile_center(t)
	if fog.region[fog.idx(t)] != FogGrid.R_HOLLOW or p.distance_to(start) < 160.0:
		return false
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			if fog.terrain_of(t + Vector2i(ox, oy)) != FogGrid.T_GROUND:
				return false
	return true

func _peat_spot(t: Vector2i) -> bool:
	if fog.terrain_of(t) != FogGrid.T_MARSH:
		return false
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var n := fog.terrain_of(t + d)
		if n == FogGrid.T_BOARDWALK or (n == FogGrid.T_GROUND and fog.region[fog.idx(t + d)] == FogGrid.R_MARSH):
			return true
	return false

func _island_spot(t: Vector2i) -> bool:
	return fog.terrain_of(t) == FogGrid.T_GROUND and fog.region[fog.idx(t)] == FogGrid.R_MARSH and t.x > 57

func _scatter_kind(kind: String, label: String, count: int, ok: Callable, lo: int, hi: int, cap: int, regrow: float) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < 6000:
		tries += 1
		var t := Vector2i(rng.randi_range(0, fog.cols - 1), rng.randi_range(0, fog.rows - 1))
		if not ok.call(t):
			continue
		var p := fog.tile_center(t)
		var too_close := false
		for q in _taken:
			if q.distance_to(p) < 64.0:
				too_close = true
				break
		if too_close:
			continue
		var r := _add_resource(kind, p, rng.randi_range(lo, hi), cap, regrow, false)
		r.label = label
		placed += 1

func _add_lantern(p: Vector2, kind: String = "post") -> Lantern:
	var l := Lantern.new()
	l.kind = kind
	l.position = fog.tile_center(fog.tile_of(p))
	$Lanterns.add_child(l)
	return l

func _add_resource(kind: String, p: Vector2, amount: int, max_amount: int, regrow: float, always: bool) -> ResourceNode:
	var r := ResourceNode.new()
	r.kind = kind
	r.amount = amount
	r.max_amount = max_amount
	r.regrow_sec = regrow
	r.always_regrow = always
	r.position = fog.tile_center(fog.tile_of(p))
	_taken.append(r.position)
	$Resources.add_child(r)
	return r

func _add_landmark(id: String, title: String, look: String, p: Vector2, text: String) -> Landmark:
	var m := Landmark.new()
	m.id = id
	m.title = title
	m.look = look
	m.text = text
	m.position = fog.tile_center(fog.tile_of(p))
	_taken.append(m.position)
	$Landmarks.add_child(m)
	return m

# --- Drawing -----------------------------------------------------------------

func _hash(x: int, y: int) -> int:
	return ((x * 73856093) ^ (y * 19349663)) & 0xffff

func _draw() -> void:
	var t := FogGrid.TILE
	var ground_tint := Color(0.78, 0.8, 0.9)   # keep lamplit grass from washing out
	var marsh_tint := Color(0.5, 0.68, 0.74)
	var plank_tint := Color(1.0, 0.8, 0.6)
	for y in fog.rows:
		for x in fog.cols:
			var pos := Vector2(x * t, y * t)
			var h := _hash(x, y)
			match fog.terrain[y * fog.cols + x]:
				FogGrid.T_ROCK:
					Art.cell(self, Art.TOWN, Art.GRASS, pos, Color(0.22, 0.24, 0.32))
					if h % 100 < 70:
						Art.cell(self, Art.TOWN, Art.PINES[h % Art.PINES.size()], pos + Vector2((h % 7) - 3, (h % 5) - 2), Color(0.6, 0.64, 0.78))
				FogGrid.T_MARSH:
					Art.cell(self, Art.TOWN, Art.GRASS, pos, marsh_tint)
					if h % 100 < 45:
						draw_texture_rect(Art.placeholder("reeds.png"), Rect2(pos, Vector2(t, t)), false)
				FogGrid.T_BOARDWALK:
					Art.cell(self, Art.TOWN, Art.GRASS, pos, marsh_tint)
					Art.cell(self, Art.DUNGEON, Art.PLANKS, pos, plank_tint)
				_:
					var c := Art.GRASS
					if h % 100 < 3:
						c = Art.GRASS_FLOWERS
					elif h % 100 < 25:
						c = Art.GRASS_TUFT
					Art.cell(self, Art.TOWN, c, pos, ground_tint)
	# The keeper's hut: 3 tiles wide, roof over walls, just north of the start.
	var hut := start + Vector2(-48, -112)
	for i in 3:
		Art.cell(self, Art.TOWN, Art.HUT_ROOF[i], hut + Vector2(i * t, 0))
		Art.cell(self, Art.TOWN, Art.HUT_WALL[i], hut + Vector2(i * t, t))
