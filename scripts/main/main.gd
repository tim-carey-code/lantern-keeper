extends Node2D
## The valley (M5): Region 1 The Hollow (start), Region 2 The Reedmarsh (east),
## Region 3 The Windward Ridge (north). The marsh is soft ground; lanterns stand on
## boardwalks and islands; its pumphouse unlocks the Reservoir Lamp. The Ridge is
## windswept, holds glass, and its glazier's workshop and signal station unlock the
## Hooded Lamp and the Mirror Post. (Region 4, The Still Lake, comes next.)
## The map is 224 x 200 tiles (2026-11-27: every region 4x the area, owner); the north-east
## quarter above the Reedmarsh is kept free for the Lakeshore and the Still Lake.

const SEED := 11
# Resource spots per region: 4x the old counts for 4x the area.
const HOLLOW_FUEL := 72
const HOLLOW_SCRAP := 64
const MARSH_PEAT := 96
const MARSH_SCRAP := 24

const Y := 72   # the Hollow and Reedmarsh sit below the Ridge
const HOLLOW_C := Vector2(48, 64 + Y)
const HOLLOW_R := Vector2(38, 44)
const MARSH_C := Vector2(160, 64 + Y)
const MARSH_R := Vector2(56, 48)
const ISLANDS := [
	Vector3(144, 46 + Y, 4), Vector3(152, 84 + Y, 4), Vector3(190, 48 + Y, 4), Vector3(194, 82 + Y, 4),
	Vector3(118, 86 + Y, 4), Vector3(204, 64 + Y, 6),
	# More firm ground in the bigger marsh.
	Vector3(122, 40 + Y, 3), Vector3(168, 30 + Y, 3), Vector3(170, 100 + Y, 3), Vector3(200, 94 + Y, 3),
]
const RIDGE_C := Vector2(68, 34)
const RIDGE_R := Vector2(60, 26)
const RIDGE_GLASS := 56
const RIDGE_FUEL := 32
const RIDGE_SCRAP := 28
const RIDGE_OUTCROPS := 88

@onready var fog: FogGrid = $FogLayer/FogGrid
@onready var player: CharacterBody2D = $Player

var start := Vector2.ZERO
var start_lantern_pos := Vector2.ZERO
var waypost_lantern_pos := Vector2.ZERO   # the second cold lantern on the north path (onboarding)
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
	# A second cold old lantern on the north path (onboarding, owner 2026-11-27): a safe spot and an easy win.
	var waypost := _add_lantern(start + Vector2(WAYPOST_OFFSET) * FogGrid.TILE)
	waypost.fuel = 0.0
	waypost_lantern_pos = waypost.position
	_taken.append(waypost_lantern_pos)
	# Near the hut: a woodpile that always regrows (no soft-lock) and a little scrap.
	_add_resource("fuel", start + Vector2(-64, 32), 3, 5, 10.0, true)
	_add_resource("scrap", start + Vector2(64, -32), 6, 6, 60.0, false)   # beside the hut, clear of its wall
	_place_landmarks()
	_place_upgrades()
	var bars := Node2D.new()
	bars.set_script(load("res://scripts/ui/foe_bars.gd"))
	bars.name = "FoeBars"
	$FogLayer.add_child(bars)
	var boss_bar := CanvasLayer.new()
	boss_bar.set_script(load("res://scripts/ui/boss_bar.gd"))
	boss_bar.name = "BossBar"
	add_child(boss_bar)
	_place_hollow_prototype()
	_scatter()
	_build_terrain()
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
	for x in range(76, 116):
		var wiggle := int(round(sin(x * 0.3) * 2.0))
		for y in range(60 + Y + wiggle, 70 + Y + wiggle):
			fog.set_tile(Vector2i(x, y), FogGrid.T_GROUND, FogGrid.R_HOLLOW if x < 96 else FogGrid.R_MARSH)
	# Boardwalks.
	_boardwalk(Vector2i(114, 64 + Y), Vector2i(208, 64 + Y))
	_boardwalk(Vector2i(132, 26 + Y), Vector2i(132, 102 + Y))
	_boardwalk(Vector2i(176, 34 + Y), Vector2i(176, 94 + Y))
	_boardwalk(Vector2i(132, 46 + Y), Vector2i(144, 46 + Y))
	_boardwalk(Vector2i(176, 82 + Y), Vector2i(194, 82 + Y))
	_boardwalk(Vector2i(132, 86 + Y), Vector2i(152, 86 + Y))   # out to the southern island
	_boardwalk(Vector2i(176, 48 + Y), Vector2i(190, 48 + Y))   # out to the north-east island
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
		for y in range(128, 148):
			for x in [94, 95]:
				fog.set_tile(Vector2i(x, y), FogGrid.T_ROCK, FogGrid.R_HOLLOW)
		for x in range(32, 66):
			for y in [84, 85]:
				fog.set_tile(Vector2i(x, y), FogGrid.T_ROCK, FogGrid.R_HOLLOW)

## Region 3: a long windswept ridge north of the Hollow, reached by a narrow climb.
## Rock outcrops give shelter from the west wind.
func _generate_ridge() -> void:
	_carve_ellipse(RIDGE_C, RIDGE_R, FogGrid.T_GROUND, FogGrid.R_RIDGE, 2.7)
	# The climb from the top of the Hollow up to the Ridge.
	for y in range(52, 100):
		var wiggle := int(round(sin(y * 0.25) * 3.0))
		for x in range(44 + wiggle, 54 + wiggle):
			if fog.terrain_of(Vector2i(x, y)) == FogGrid.T_ROCK:
				fog.set_tile(Vector2i(x, y), FogGrid.T_GROUND, FogGrid.R_RIDGE if y < 76 else FogGrid.R_HOLLOW)
	# Outcrops: small rock clusters, kept off the middle line so the Ridge stays walkable end to end.
	var orng := RandomNumberGenerator.new()
	orng.seed = SEED + 3
	var placed := 0
	var tries := 0
	while placed < RIDGE_OUTCROPS and tries < 2000:
		tries += 1
		var c := Vector2i(orng.randi_range(16, 120), orng.randi_range(14, 54))
		if fog.terrain_of(c) != FogGrid.T_GROUND or fog.region[fog.idx(c)] != FogGrid.R_RIDGE:
			continue
		if absi(c.y - int(RIDGE_C.y)) < 3 or (c.x >= 38 and c.x <= 60 and c.y > 40):
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
	_add_landmark("climb_cairn", "A stone cairn", "cairn", fog.tile_center(Vector2i(48, 94)),
		"A small cairn, a chalk arrow on the top stone, pointing up.\nThe wind is worse up there. Come back when the marsh is lit. - Oswin")
	_add_landmark("ledger", "Keepers' ledger", "ledger", start + Vector2(-96, -64),
		"Long columns of tally marks, one for every lamp lit each night.\nNear the end the columns shrink to a single mark, in a newer hand.\nUnder it: My lamp hangs on my crook, on the north path. Take it back. Then the WayLamp, at the top. - Oswin")
	_add_landmark("stone_way", "Carved stone", "stone", fog.tile_center(Vector2i(80, 60 + Y)),
		"KEEP THE WAY TO THE WATER LIT.\nBelow the old letters, a fresh chalk arrow points east.")
	_add_landmark("frames_east", "Old lantern frames", "frames", fog.tile_center(Vector2i(156, 62 + Y)),
		"Three empty frames along the boardwalk, all turned east, toward the lake.\nA rag is tied to the last one: The pump still works. Wake it. - Oswin")
	_add_landmark("chalk_lake", "Chalk on the pumphouse wall", "chalk", fog.tile_center(Vector2i(200, 60 + Y)),
		"Two drawings of the same lake. In the first it shines.\nIn the second, something dark is coiled around the light.\nBeside them, newer chalk: I went to look. - Oswin")
	var pump := _add_landmark("pumphouse", "The pumphouse", "pumphouse", fog.tile_center(Vector2i(206, 66 + Y)),
		"The old pump still turns when you push it. Its tank could feed a lamp for a long time.\nScratched on the tank: Light has to be fed from somewhere.\nNow go up, past the Hollow. The ridge has glass. - Oswin")
	pump.unlock_kind = "reservoir"

func _place_ridge_landmarks() -> void:
	var glazier := _add_landmark("glazier", "The glazier's workshop", "workshop", _ridge_spot(Vector2i(28, 30)),
		"Cold kilns and racks of cut glass. A half-finished hood sits on the bench,\nshaped to keep a flame alive in any wind.\nA note under it: Finish it. I could not stay. - Oswin")
	glazier.unlock_kind = "hooded"
	var station := _add_landmark("station", "The signal station", "station", _ridge_spot(Vector2i(116, 26)),
		"A tall post with a cracked mirror. Keepers passed light from post to post, all the way to the lake.\nSomeone has turned the mirror down, toward the water.\nOld steps beside it go down into the fog.")
	station.unlock_kind = "mirror"
	_add_landmark("coat", "A keeper's coat", "coat", _ridge_spot(Vector2i(84, 44)),
		"Snagged on the rocks, stiff with frost. An O is stitched inside the collar.\nIn the pocket: \"It came up out of the water. It drank the great lamp.\nNow it is hungry for the rest. Only mirrors reach the lake.\"")
	_add_landmark("ridge_steps", "Old steps", "steps", _ridge_spot(Vector2i(124, 34)),
		"Old steps, worn smooth, going down.\nBelow, the fog does not move, even in the wind.")
	_add_landmark("lens", "A broken lens", "lens", _ridge_spot(Vector2i(60, 18)),
		"A great curved lens, split down the middle. Scratched into the frame:\nTHE WICK REMEMBERS EVERY FLAME.\nBelow, in a newer hand: Then it will remember ours. - Oswin")

## PROTOTYPE: one old WayLamp per region (texts are drafts until the owner approves STORY.md).
func _place_waylamps() -> void:
	# Texts approved by the owner on 2026-11-27 (STORY.md section 11).
	_add_waylamp("hollow", FogGrid.R_HOLLOW, Vector2i(64, 90), "WayLamp of the Hollow",
		"A tall lamp with a wide iron bowl, cold and full of old ash.\nCut into the base: WHILE THIS BURNS, THE HOLLOW IS KEPT.\nTied to the post: This has to be held until it takes. I could not hold it and keep the rest. - Oswin")
	_add_waylamp("marsh", FogGrid.R_MARSH, Vector2i(200, 140), "WayLamp of the Reedmarsh",
		"A WayLamp on a stone footing, above the damp. Its bowl is dry.\nCut into the base: WHILE THIS BURNS, THE MARSH IS KEPT.\nUnder it, a tin of dry wicks and a tag in an old hand: For whoever comes next.")
	_add_waylamp("ridge", FogGrid.R_RIDGE, Vector2i(110, 30), "WayLamp of the Ridge",
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
	for r in 12:
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
	return fog.terrain_of(t) == FogGrid.T_GROUND and fog.region[fog.idx(t)] == FogGrid.R_MARSH and t.x > 114

func _scatter_kind(kind: String, label: String, count: int, ok: Callable, lo: int, hi: int, cap: int, regrow: float) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < 30000:
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

## The static map, drawn once in chunks (MapChunk) so the renderer can cull what is off screen.
## The terrain sits behind everything else in the scene; the hut is drawn over it.
func _build_terrain() -> void:
	var terrain := Node2D.new()
	terrain.name = "Terrain"
	add_child(terrain)
	move_child(terrain, 0)
	for cy in range(0, fog.rows, MapChunk.SIZE):
		for cx in range(0, fog.cols, MapChunk.SIZE):
			var c := MapChunk.new()
			c.fog = fog
			c.t0 = Vector2i(cx, cy)
			c.position = Vector2(cx, cy) * FogGrid.TILE
			terrain.add_child(c)
	var hut := Node2D.new()
	hut.name = "Hut"
	hut.position = start + Vector2(-48, -112)   # 3 tiles wide, roof over walls, just north of the start
	hut.draw.connect(func():
		for i in 3:
			Art.cell(hut, Art.TOWN, Art.HUT_ROOF[i], Vector2(i * FogGrid.TILE, 0))
			Art.cell(hut, Art.TOWN, Art.HUT_WALL[i], Vector2(i * FogGrid.TILE, FogGrid.TILE)))
	terrain.add_child(hut)

## The first 10 minutes (docs/PLAN_ONBOARDING.md, owner answers 2026-11-27, Option B). Tile offsets from the
## hut's start tile, +x east, -y north. The main route: the lone Wickling (pack 20, -1,-10), this cold lantern
## (+2,-12), a pack of 3 (pack 23, +5,-17), Oswin's crook with its small guard and a 6-scrap cache (-1,-19),
## nest A (nest 4, +2,-30), one pack (pack 2, +13,-32), the Clinker (+7,-40), the WayLamp (+15,-45 once snapped).
const WAYPOST_OFFSET := Vector2i(2, -12)
const CROOK_OFFSET := Vector2i(-1, -19)
const CLINKER_TILE := Vector2i(55, 96)   # a mid-boss near the WayLamp, before the Ashbrood (out of its wake range from the WayLamp)

## Keeper's Light prototype content, limited to the Hollow.
func _place_hollow_prototype() -> void:
	# The hut is calm (owner): nothing wakes at the hut, the woodpile or the ledger. The crook is about 18 tiles north.
	var post_pos := _spot_in_region(Vector2i(HOLLOW_C) + CROOK_OFFSET, FogGrid.R_HOLLOW)
	var post := _add_landmark("crook_post", "A keeper's post", "post", post_pos,
		"A keeper's crook, fallen across the path. The lamp on it is cold, but whole.\nTied to it: Plant one where you mean to stand. The small ones will not come into it. - Oswin")
	post.unlock_kind = "post"
	var lure := PostLure.new()
	lure.position = post_pos
	$FogLayer/Wicklings.add_child(lure)
	# Option B: a small guard on the crook, one shelled Wickling. The Clinker keeps its sleep and leash near the WayLamp.
	var guard := EnemyPack.new()
	guard.id = "hollow_post_guard"
	guard.guard = true
	guard.count = 1
	guard.elites = 1
	guard.level = Tuning.kl_post_guard_level
	guard.position = post_pos
	$FogLayer/Wicklings.add_child(guard)
	var clinker := Clinker.new()
	clinker.position = _spot_in_region(CLINKER_TILE, FogGrid.R_HOLLOW)
	$FogLayer/Wicklings.add_child(clinker)
	for i in HOLLOW_NESTS.size():
		var nest := WickNest.new()
		nest.foe_id = "nest_hollow_%d" % (i + 1)
		nest.position = _spot_in_region(HOLLOW_NESTS[i][0], FogGrid.R_HOLLOW)
		nest.level = int(HOLLOW_NESTS[i][1])
		$FogLayer/Wicklings.add_child(nest)
	for i in HOLLOW_PACKS.size():
		var row: Array = HOLLOW_PACKS[i]
		var pack := EnemyPack.new()
		pack.id = "hollow_%d" % (i + 1)
		pack.count = int(row[1])
		pack.spitwicks = int(row[2])
		pack.elites = int(row[3])
		pack.level = int(row[4])
		if row.size() > 5:
			pack.wake_radius = float(row[5]) * FogGrid.TILE
		pack.position = _spot_in_region(row[0], FogGrid.R_HOLLOW)
		$FogLayer/Wicklings.add_child(pack)
	_place_caches()

## Nests (4x for the 4x Hollow): one on the main route (nest 4, nest A: the first thing the Post Lamp unlocks,
## more than its wake radius past the crook), the rest optional on the flanks and in the south, all at least
## 30 tiles from the hut. [tile, foe level]: 1 on the hut row and south, rising to 6 by the WayLamp;
## hatchlings take their nest's level (DESIGN §9, level-gap wick).
const HOLLOW_NESTS := [
	[Vector2i(32, 100), 5], [Vector2i(42, 90), 6], [Vector2i(76, 98), 6],     # the north flanks; nest 3 is clear of the WayLamp fight
	[Vector2i(50, 106), 2], [Vector2i(22, 106), 3],                           # nest A on the route; nest 5 out west
	[Vector2i(20, 112), 3], [Vector2i(80, 118), 3], [Vector2i(14, 130), 1], [Vector2i(84, 136), 1],
	[Vector2i(30, 160), 1], [Vector2i(66, 162), 1], [Vector2i(48, 172), 1],
]

## Fixed packs (4x for the 4x Hollow). [tile, how many, Spitwicks, shelled elites, foe level, (wake radius in tiles)]:
## tougher the closer to the WayLamp (north), quiet in the south. Levels (DESIGN §9): 1 on the hut row and south
## of it, 2-4 through the middle, 5-6 by the WayLamp. The main route (onboarding) holds three: pack 20 (the lone
## Wickling) and pack 23 (3 Wicklings) wake closer than the rest, so nothing wakes at the hut; pack 2 is the
## first Spitwick and elite, after nest A. The rest are optional side content: no Spitwick or elite within
## 25 tiles of the hut, and none wakes from the route.
const HOLLOW_PACKS := [
	# Near the WayLamp: elites.
	[Vector2i(74, 102), 5, 1, 1, 6], [Vector2i(61, 104), 4, 1, 1, 4], [Vector2i(36, 94), 4, 0, 1, 5],
	[Vector2i(76, 112), 4, 1, 1, 5], [Vector2i(34, 104), 4, 1, 0, 4], [Vector2i(26, 100), 4, 0, 1, 5],
	# The middle: Spitwicks on the flanks.
	[Vector2i(24, 110), 4, 1, 0, 4], [Vector2i(72, 120), 4, 1, 0, 4], [Vector2i(66, 122), 4, 0, 0, 2],
	[Vector2i(30, 120), 4, 0, 0, 3], [Vector2i(82, 126), 4, 1, 0, 2],
	[Vector2i(16, 122), 4, 0, 0, 2], [Vector2i(68, 132), 4, 0, 0, 1], [Vector2i(72, 150), 4, 0, 0, 1],
	[Vector2i(86, 146), 4, 0, 0, 1], [Vector2i(80, 160), 4, 0, 0, 1],
	# The quiet south and the west.
	[Vector2i(16, 160), 3, 0, 0, 1], [Vector2i(34, 176), 3, 0, 0, 1], [Vector2i(60, 176), 3, 0, 0, 1],
	[Vector2i(47, 126), 1, 0, 0, 1, 5],   # pack 20: the main route's lone first Wickling, 10 tiles north
	[Vector2i(12, 138), 3, 0, 0, 1], [Vector2i(24, 150), 3, 0, 0, 1],
	[Vector2i(53, 119), 3, 0, 0, 1, 6],   # pack 23: the main route's first pack, past the cold lantern
	[Vector2i(70, 170), 3, 0, 0, 1],
]

## Side caches: an old keeper's stash at a dead end of each region, worth a detour. One-off (no regrowth).
## [region, tile, kind, amount]
const CACHES := [
	[FogGrid.R_HOLLOW, Vector2i(12, 150), "scrap", 10], [FogGrid.R_HOLLOW, Vector2i(84, 168), "fuel", 10],
	[FogGrid.R_HOLLOW, Vector2i(16, 104), "scrap", 8],
	[FogGrid.R_HOLLOW, Vector2i(48, 117), "scrap", 6],   # at Oswin's crook: enough for a Post Lamp right away
	[FogGrid.R_MARSH, Vector2i(122, 112), "scrap", 10], [FogGrid.R_MARSH, Vector2i(170, 172), "fuel", 10],
	[FogGrid.R_RIDGE, Vector2i(20, 26), "glass", 6], [FogGrid.R_RIDGE, Vector2i(120, 46), "glass", 6],
]

func _place_caches() -> void:
	for c in CACHES:
		var t: Vector2i = c[1]
		var p := _spot_in_region(t, int(c[0]))
		var r := _add_resource(str(c[2]), p, int(c[3]), int(c[3]), 1.0e9, false)
		r.label = "Old cache"

## Upgrades in the far corners of each region: a keeper's satchel (carry more) and a lamp glass
## (a better hand lamp). Texts are DRAFT in STORY.md until the owner approves them.
func _place_upgrades() -> void:
	var u := _add_landmark("satchel_hollow", "A keeper's satchel", "satchel", _spot_in_region(Vector2i(14, 110), FogGrid.R_HOLLOW),
		"A keeper's satchel, hung on a nail in a fallen wall.\nPatched many times, and still sound.")
	u.upgrade = "carry"
	u = _add_landmark("lampglass_hollow", "A lamp glass", "lampglass", _spot_in_region(Vector2i(22, 164), FogGrid.R_HOLLOW),
		"A spare glass for a hand lamp, wrapped in a rag.\nIt is clearer than yours.")
	u.upgrade = "lamp"
	u = _add_landmark("satchel_marsh", "A keeper's satchel", "satchel", _spot_in_region(Vector2i(176, 108), FogGrid.R_MARSH),
		"A satchel wrapped in oilcloth, wedged under an old post.\nIt is dry inside.")
	u.upgrade = "carry"
	u = _add_landmark("lampglass_marsh", "A lamp glass", "lampglass", _spot_in_region(Vector2i(194, 158), FogGrid.R_MARSH),
		"A lamp glass in a tin box, packed in dry moss.\nNot a crack in it.")
	u.upgrade = "lamp"
	u = _add_landmark("satchel_ridge", "A keeper's satchel", "satchel", _spot_in_region(Vector2i(92, 12), FogGrid.R_RIDGE),
		"A satchel under a flat stone, its strap mended with wire.\nSomeone meant to come back for it.")
	u.upgrade = "carry"
	u = _add_landmark("lampglass_ridge", "A lamp glass", "lampglass", _spot_in_region(Vector2i(14, 40), FogGrid.R_RIDGE),
		"A thin lamp glass from the glazier's racks, cut clear as water.\nIt fits your hand lamp.")
	u.upgrade = "lamp"

## The nearest walkable ground or boardwalk tile of a region to a wanted tile.
func _spot_in_region(want: Vector2i, region_id: int) -> Vector2:
	for r in 20:
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				var t := want + Vector2i(dx, dy)
				if not fog.in_bounds(t):
					continue
				var ter := fog.terrain_of(t)
				if (ter == FogGrid.T_GROUND or ter == FogGrid.T_BOARDWALK) and fog.region[fog.idx(t)] == region_id:
					return fog.tile_center(t)
	return fog.tile_center(want)
