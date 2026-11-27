extends Node2D
## The valley (M5): Region 1 The Hollow (start), Region 2 The Reedmarsh (east),
## Region 3 The Windward Ridge (north). The marsh is soft ground; lanterns stand on
## boardwalks and islands; its pumphouse unlocks the Reservoir Lamp. The Ridge is
## windswept, holds glass, and its glazier's workshop and signal station unlock the
## Hooded Lamp and the Mirror Post. (Region 4, The Still Lake, comes next.)

const SEED := 11
const HOLLOW_FUEL := 18
const HOLLOW_SCRAP := 16
const MARSH_PEAT := 24
const MARSH_SCRAP := 6

const Y := 36   # the Hollow and Reedmarsh sit below the Ridge
const HOLLOW_C := Vector2(24, 32 + Y)
const HOLLOW_R := Vector2(19, 22)
const MARSH_C := Vector2(80, 32 + Y)
const MARSH_R := Vector2(28, 24)
const ISLANDS := [Vector3(72, 23 + Y, 2), Vector3(76, 42 + Y, 2), Vector3(95, 24 + Y, 2), Vector3(97, 41 + Y, 2), Vector3(59, 43 + Y, 2), Vector3(102, 32 + Y, 3)]
const RIDGE_C := Vector2(34, 17)
const RIDGE_R := Vector2(30, 13)
const RIDGE_GLASS := 14
const RIDGE_FUEL := 8
const RIDGE_SCRAP := 7

@onready var fog: FogGrid = $FogLayer/FogGrid
@onready var player: CharacterBody2D = $Player

var start := Vector2.ZERO
var start_lantern_pos := Vector2.ZERO
var loaded_save := false
var rng := RandomNumberGenerator.new()
var _taken: Array[Vector2] = []

func _ready() -> void:
	# This prototype must never load or overwrite the owner's main-game save.
	# Automated captures/tests set skip_opening and choose their own isolated path.
	if not Story.skip_opening:
		SaveGame.slot_prefix = "user://keepers_light_slot_"
		SaveGame.path = "user://keepers_light_prototype.json"
	add_to_group("main")
	Inventory.reset()
	Progress.reset()
	Story.reset()
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
	# The old lantern by the hut starts cold: relighting it is the keeper's first task.
	var first := _add_lantern(start + Vector2(96, 0))
	first.fuel = 0.0
	start_lantern_pos = first.position
	# Near the hut: a woodpile that always regrows (no soft-lock) and a little scrap.
	_add_resource("fuel", start + Vector2(-64, 32), 3, 5, 10.0, true)
	_add_resource("scrap", start + Vector2(64, -32), 6, 6, 60.0, false)   # beside the hut, clear of its wall
	_place_landmarks()
	_place_upgrades()
	_place_hollow_prototype()
	_scatter()
	queue_redraw()
	# Continue from the save unless "New game" was just chosen.
	if SaveGame.skip_load_once:
		SaveGame.skip_load_once = false
	else:
		loaded_save = SaveGame.load_into(self)
	Progress.region_settled.connect(_on_region_settled)
	if not loaded_save and not Story.skip_opening:
		$Opening.start.call_deferred()

## A WayLamp caught: every lantern in its region flares back to a full tank and is held from now on.
func _on_region_settled(region_id: int, _name: String) -> void:
	Story.update(self)
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.needs_fuel() and fog.region_at(l.global_position) == region_id:
			l.fuel = l.max_fuel()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveGame.save(self)   # closing the window keeps your progress

func _input(event: InputEvent) -> void:
	# Hide the cursor while playing with keys or a controller; show it when the mouse moves.
	if event is InputEventMouseMotion and event.relative.length() > 2.0:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventJoypadButton or event is InputEventKey or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		if Input.mouse_mode != Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

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
		for y in range(30 + Y + wiggle, 35 + Y + wiggle):
			fog.set_tile(Vector2i(x, y), FogGrid.T_GROUND, FogGrid.R_HOLLOW if x < 48 else FogGrid.R_MARSH)
	# Boardwalks.
	_boardwalk(Vector2i(57, 32 + Y), Vector2i(104, 32 + Y))
	_boardwalk(Vector2i(66, 13 + Y), Vector2i(66, 51 + Y))
	_boardwalk(Vector2i(88, 17 + Y), Vector2i(88, 47 + Y))
	_boardwalk(Vector2i(66, 23 + Y), Vector2i(72, 23 + Y))
	_boardwalk(Vector2i(88, 41 + Y), Vector2i(97, 41 + Y))
	# Islands of firm ground.
	for c in ISLANDS:
		var cx := int(c.x)
		var cy := int(c.y)
		var cr := int(c.z)
		for y in range(cy - cr, cy + cr + 1):
			for x in range(cx - cr, cx + cr + 1):
				if Vector2(x, y).distance_to(Vector2(c.x, c.y)) <= c.z + 0.3 and fog.terrain_of(Vector2i(x, y)) != FogGrid.T_ROCK:
					fog.set_tile(Vector2i(x, y), FogGrid.T_GROUND, FogGrid.R_MARSH)

	_generate_ridge()
	# The first prototype ends in the Hollow; keep the east and north routes shut in normal play.
	if not Story.skip_opening:
		for y in range(65, 73):
			fog.set_tile(Vector2i(47, y), FogGrid.T_ROCK, FogGrid.R_HOLLOW)
		for x in range(16, 33):
			fog.set_tile(Vector2i(x, 42), FogGrid.T_ROCK, FogGrid.R_HOLLOW)

## Region 3: a long windswept ridge north of the Hollow, reached by a narrow climb.
## Rock outcrops give shelter from the west wind.
func _generate_ridge() -> void:
	_carve_ellipse(RIDGE_C, RIDGE_R, FogGrid.T_GROUND, FogGrid.R_RIDGE, 2.7)
	# The climb from the top of the Hollow up to the Ridge.
	for y in range(26, 50):
		var wiggle := int(round(sin(y * 0.5) * 1.5))
		for x in range(22 + wiggle, 27 + wiggle):
			if fog.terrain_of(Vector2i(x, y)) == FogGrid.T_ROCK:
				fog.set_tile(Vector2i(x, y), FogGrid.T_GROUND, FogGrid.R_RIDGE if y < 38 else FogGrid.R_HOLLOW)
	# Outcrops: small rock clusters, kept off the middle line so the Ridge stays walkable end to end.
	var orng := RandomNumberGenerator.new()
	orng.seed = SEED + 3
	var placed := 0
	var tries := 0
	while placed < 22 and tries < 500:
		tries += 1
		var c := Vector2i(orng.randi_range(8, 60), orng.randi_range(7, 27))
		if fog.terrain_of(c) != FogGrid.T_GROUND or fog.region[fog.idx(c)] != FogGrid.R_RIDGE:
			continue
		if absi(c.y - int(RIDGE_C.y)) < 2 or (c.x >= 20 and c.x <= 29 and c.y > 20):
			continue   # keep the spine and the top of the climb open
		for t in [Vector2i.ZERO, Vector2i(0, 1), Vector2i(0, -1)] if orng.randf() < 0.6 else [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
			if fog.region[fog.idx(c + t)] == FogGrid.R_RIDGE:
				fog.set_tile(c + t, FogGrid.T_ROCK, FogGrid.R_RIDGE)
		placed += 1

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
	_place_ridge_landmarks()
	_place_waylamps()
	# The rack by the hut is scenery now (owner: too much to read at the start); the letter is the opening.
	var rack := _add_landmark("rack", "Lantern rack", "rack", start + Vector2(-80, -40), "")
	rack.scenery = true
	_add_landmark("climb_cairn", "A stone cairn", "cairn", fog.tile_center(Vector2i(24, 47)),
		"A small cairn, a chalk arrow on the top stone, pointing up.\nThe wind is worse up there. Come back when the marsh is lit. - Oswin")
	_add_landmark("ledger", "Keepers' ledger", "ledger", start + Vector2(-96, -64),
		"Long columns of tally marks, one for every lamp lit each night.\nNear the end the columns shrink to a single mark, in a newer hand.\nUnder it: The north lamps first. Wake the WayLamp up there, then follow the stones east. - Oswin")
	_add_landmark("stone_way", "Carved stone", "stone", fog.tile_center(Vector2i(40, 30 + Y)),
		"KEEP THE WAY TO THE WATER LIT.\nBelow the old letters, a fresh chalk arrow points east.")
	_add_landmark("frames_east", "Old lantern frames", "frames", fog.tile_center(Vector2i(78, 31 + Y)),
		"Three empty frames along the boardwalk, all turned east, toward the lake.\nA rag is tied to the last one: The pump still works. Wake it. - Oswin")
	_add_landmark("chalk_lake", "Chalk on the pumphouse wall", "chalk", fog.tile_center(Vector2i(100, 30 + Y)),
		"Two drawings of the same lake. In the first it shines.\nIn the second, something dark is coiled around the light.\nBeside them, newer chalk: I went to look. - Oswin")
	var pump := _add_landmark("pumphouse", "The pumphouse", "pumphouse", fog.tile_center(Vector2i(103, 33 + Y)),
		"The old pump still turns when you push it. Its tank could feed a lamp for a long time.\nScratched on the tank: Light has to be fed from somewhere.\nNow go up, past the Hollow. The ridge has glass. - Oswin")
	pump.unlock_kind = "reservoir"

func _place_ridge_landmarks() -> void:
	var glazier := _add_landmark("glazier", "The glazier's workshop", "workshop", _ridge_spot(Vector2i(14, 15)),
		"Cold kilns and racks of cut glass. A half-finished hood sits on the bench,\nshaped to keep a flame alive in any wind.\nA note under it: Finish it. I could not stay. - Oswin")
	glazier.unlock_kind = "hooded"
	var station := _add_landmark("station", "The signal station", "station", _ridge_spot(Vector2i(58, 13)),
		"A tall post with a cracked mirror. Keepers passed light from post to post, all the way to the lake.\nSomeone has turned the mirror down, toward the water.\nOld steps beside it go down into the fog.")
	station.unlock_kind = "mirror"
	_add_landmark("coat", "A keeper's coat", "coat", _ridge_spot(Vector2i(42, 22)),
		"Snagged on the rocks, stiff with frost. An O is stitched inside the collar.\nIn the pocket: \"It came up out of the water. It drank the great lamp.\nNow it is hungry for the rest. Only mirrors reach the lake.\"")
	_add_landmark("ridge_steps", "Old steps", "steps", _ridge_spot(Vector2i(62, 17)),
		"Old steps, worn smooth, going down.\nBelow, the fog does not move, even in the wind.")
	_add_landmark("lens", "A broken lens", "lens", _ridge_spot(Vector2i(30, 9)),
		"A great curved lens, split down the middle. Scratched into the frame:\nTHE WICK REMEMBERS EVERY FLAME.\nBelow, in a newer hand: Then it will remember ours. - Oswin")

## PROTOTYPE: one old WayLamp per region (texts are drafts until the owner approves STORY.md).
func _place_waylamps() -> void:
	# Texts approved by the owner on 2026-11-27 (STORY.md section 11).
	_add_waylamp("hollow", FogGrid.R_HOLLOW, Vector2i(32, 45), "WayLamp of the Hollow",
		"A tall lamp with a wide iron bowl, cold and full of old ash.\nCut into the base: WHILE THIS BURNS, THE HOLLOW IS KEPT.\nTied to the post: This has to be held until it takes. I could not hold it and keep the rest. - Oswin")
	_add_waylamp("marsh", FogGrid.R_MARSH, Vector2i(100, 70), "WayLamp of the Reedmarsh",
		"A WayLamp on a stone footing, above the damp. Its bowl is dry.\nCut into the base: WHILE THIS BURNS, THE MARSH IS KEPT.\nUnder it, a tin of dry wicks and a tag in an old hand: For whoever comes next.")
	_add_waylamp("ridge", FogGrid.R_RIDGE, Vector2i(55, 15), "WayLamp of the Ridge",
		"A WayLamp in the lee of the station wall. Frost has cracked its hood.\nCut into the base: WHILE THIS BURNS, THE RIDGE IS KEPT.\nUnder a stone: When this went out, the small dark ones came up the steps. - Oswin")

func _add_waylamp(id: String, region_id: int, want: Vector2i, title: String, text: String) -> WayLamp:
	var w := WayLamp.new()
	w.guardian_fight = id == "hollow"
	w.id = id
	w.region_id = region_id
	w.title = title
	w.text = text
	w.position = _spot_in_region(want, region_id)
	_taken.append(w.position)
	$Landmarks.add_child(w)
	return w

## The nearest open Ridge tile to a wanted spot (outcrops are random).
func _ridge_spot(want: Vector2i) -> Vector2:
	for r in 6:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := want + Vector2i(dx, dy)
				if fog.terrain_of(t) == FogGrid.T_GROUND and fog.region[fog.idx(t)] == FogGrid.R_RIDGE:
					return fog.tile_center(t)
	return fog.tile_center(want)

func _ridge_open(t: Vector2i) -> bool:
	if fog.region[fog.idx(t)] != FogGrid.R_RIDGE or fog.terrain_of(t) != FogGrid.T_GROUND:
		return false
	return fog.terrain_of(t + Vector2i.LEFT) == FogGrid.T_GROUND or fog.terrain_of(t + Vector2i.RIGHT) == FogGrid.T_GROUND

func _scatter() -> void:
	_scatter_kind("fuel", "", HOLLOW_FUEL, func(t): return _hollow_spot(t), 4, 8, 8, 60.0)
	_scatter_kind("scrap", "", HOLLOW_SCRAP, func(t): return _hollow_spot(t), 4, 7, 7, 75.0)
	_scatter_kind("fuel", "Peat", MARSH_PEAT, func(t): return _peat_spot(t), 5, 9, 9, 45.0)
	_scatter_kind("scrap", "", MARSH_SCRAP, func(t): return _island_spot(t), 4, 7, 7, 75.0)
	_scatter_kind("glass", "", RIDGE_GLASS, func(t): return _ridge_open(t), 2, 4, 4, 120.0)
	_scatter_kind("fuel", "", RIDGE_FUEL, func(t): return _ridge_open(t), 3, 6, 6, 60.0)
	_scatter_kind("scrap", "", RIDGE_SCRAP, func(t): return _ridge_open(t), 3, 6, 6, 75.0)

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

## PROTOTYPE: what the keeper drops on fainting. A one-off pile, no regrowth.
func drop_pile(kind: String, p: Vector2, amount: int) -> ResourceNode:
	var r := _add_resource(kind, p, amount, amount, 1.0e9, false)
	r.label = "Dropped " + ("fuel" if kind == "fuel" else "scrap")
	return r

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
				FogGrid.T_ROCK when fog.region[y * fog.cols + x] == FogGrid.R_RIDGE:
					# Ridge outcrops: bare stone that breaks the wind.
					Art.cell(self, Art.TOWN, Art.GRASS, pos, Color(0.5, 0.55, 0.65))
					Art.cell(self, Art.DUNGEON, Art.STONE_WALL, pos, Color(0.75, 0.78, 0.88))
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

## Keeper's Light prototype content, limited to the Hollow.
func _place_hollow_prototype() -> void:
	var post_pos := fog.tile_center(Vector2i(24, 58))
	var post := _add_landmark("crook_post", "A keeper's post", "post", post_pos,
		"A keeper's crook, fallen across the path. The lamp on it is cold, but whole.\nTied to it: Plant one where you mean to stand. The small ones will not come into it. - Oswin")
	post.unlock_kind = "post"
	var lure := PostLure.new()
	lure.position = post_pos
	$FogLayer/Wicklings.add_child(lure)
	var clinker := Clinker.new()
	clinker.position = post_pos
	$FogLayer/Wicklings.add_child(clinker)
	var nest_tiles := [Vector2i(21, 53), Vector2i(27, 50), Vector2i(30, 47)]
	for i in nest_tiles.size():
		var nest := WickNest.new()
		nest.foe_id = "nest_hollow_%d" % (i + 1)
		nest.position = _spot_in_region(nest_tiles[i], FogGrid.R_HOLLOW)
		$FogLayer/Wicklings.add_child(nest)
	var packs := [
		[Vector2i(13, 64), 3, 0], [Vector2i(35, 66), 4, 0],
		[Vector2i(15, 57), 4, 1], [Vector2i(34, 58), 4, 1],
		[Vector2i(18, 49), 4, 0], [Vector2i(29, 54), 5, 0],
	]
	for i in packs.size():
		var row: Array = packs[i]
		var pack := EnemyPack.new()
		pack.id = "hollow_%d" % (i + 1)
		pack.count = int(row[1])
		pack.spitwicks = int(row[2])
		pack.position = _spot_in_region(row[0], FogGrid.R_HOLLOW)
		$FogLayer/Wicklings.add_child(pack)

## Upgrades in the far corners of each region: a keeper's satchel (carry more) and a lamp glass
## (a better hand lamp). Texts are DRAFT in STORY.md until the owner approves them.
func _place_upgrades() -> void:
	var u := _add_landmark("satchel_hollow", "A keeper's satchel", "satchel", _spot_in_region(Vector2i(7, 55), FogGrid.R_HOLLOW),
		"A keeper's satchel, hung on a nail in a fallen wall.\nPatched many times, and still sound.")
	u.upgrade = "carry"
	u = _add_landmark("lampglass_hollow", "A lamp glass", "lampglass", _spot_in_region(Vector2i(11, 82), FogGrid.R_HOLLOW),
		"A spare glass for a hand lamp, wrapped in a rag.\nIt is clearer than yours.")
	u.upgrade = "lamp"
	u = _add_landmark("satchel_marsh", "A keeper's satchel", "satchel", _spot_in_region(Vector2i(88, 54), FogGrid.R_MARSH),
		"A satchel wrapped in oilcloth, wedged under an old post.\nIt is dry inside.")
	u.upgrade = "carry"
	u = _add_landmark("lampglass_marsh", "A lamp glass", "lampglass", _spot_in_region(Vector2i(97, 79), FogGrid.R_MARSH),
		"A lamp glass in a tin box, packed in dry moss.\nNot a crack in it.")
	u.upgrade = "lamp"
	u = _add_landmark("satchel_ridge", "A keeper's satchel", "satchel", _spot_in_region(Vector2i(46, 6), FogGrid.R_RIDGE),
		"A satchel under a flat stone, its strap mended with wire.\nSomeone meant to come back for it.")
	u.upgrade = "carry"
	u = _add_landmark("lampglass_ridge", "A lamp glass", "lampglass", _spot_in_region(Vector2i(7, 20), FogGrid.R_RIDGE),
		"A thin lamp glass from the glazier's racks, cut clear as water.\nIt fits your hand lamp.")
	u.upgrade = "lamp"

## The nearest walkable ground or boardwalk tile of a region to a wanted tile.
func _spot_in_region(want: Vector2i, region_id: int) -> Vector2:
	for r in 10:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := want + Vector2i(dx, dy)
				if not fog.in_bounds(t):
					continue
				var ter := fog.terrain_of(t)
				if (ter == FogGrid.T_GROUND or ter == FogGrid.T_BOARDWALK) and fog.region[fog.idx(t)] == region_id:
					return fog.tile_center(t)
	return fog.tile_center(want)
