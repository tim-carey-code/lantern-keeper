extends CanvasLayer
## Map: M / gamepad LB. Shows lit ground bright, remembered ground dim,
## never-seen as black, lanterns (amber lit, grey cold), the keeper (white),
## and the names of regions you have found.

var root: Control
var map_rect: TextureRect
var names: Array[Label] = []
var img: Image
var tex: ImageTexture
var _refresh := 0.0
var _scale := 1.0
var _centroids := {}
var _view := Rect2i()

func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS   # works while the world is paused
	root = Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.012, 0.02, 1.0)   # opaque: HUD and fog outlines must not show through
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	var title := Label.new()
	title.text = "Map   (M / LB to close)      amber = lit lantern   yellow = low fuel   red = cold   white = you"
	title.position = Vector2(24, 16)
	root.add_child(title)
	map_rect = TextureRect.new()
	map_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	root.add_child(map_rect)
	root.visible = false

func is_open() -> bool:
	return root.visible

func toggle() -> void:
	if root.visible:
		Sfx.play("ui_close", -14.0)
		root.visible = false
		Tuning.ui_open = false
		get_tree().paused = false
		Progress.block_input()
	elif not Tuning.ui_open:
		Sfx.play("ui_open", -14.0)
		root.visible = true
		Tuning.ui_open = true
		get_tree().paused = true   # reading or choosing never costs you anything
		_refresh = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("map") or (root.visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause"))):
		toggle()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not root.visible:
		return
	_refresh -= delta
	if _refresh <= 0.0:
		_refresh = 0.25
		render()

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func render() -> void:
	var fog := _fog()
	if fog == null:
		return
	if img == null or img.get_width() != fog.cols:
		img = Image.create(fog.cols, fog.rows, false, Image.FORMAT_RGBA8)
		_compute_centroids(fog)
	# Zoom to the explored area (plus a margin) so the map stays readable.
	var lo := Vector2i(fog.cols, fog.rows)
	var hi := Vector2i(-1, -1)
	for i in fog.remembered.size():
		if fog.remembered[i] == 1:
			var t := Vector2i(i % fog.cols, i / fog.cols)
			lo = lo.min(t)
			hi = hi.max(t)
	if hi.x < 0:
		lo = Vector2i.ZERO
		hi = Vector2i(fog.cols - 1, fog.rows - 1)
	lo = (lo - Vector2i(6, 6)).clamp(Vector2i.ZERO, Vector2i(fog.cols - 1, fog.rows - 1))
	hi = (hi + Vector2i(6, 6)).clamp(Vector2i.ZERO, Vector2i(fog.cols - 1, fog.rows - 1))
	# At least 40x24 tiles so a small explored area is not blown up.
	var want := Vector2i(maxi(hi.x - lo.x + 1, 40), maxi(hi.y - lo.y + 1, 24))
	var mid := (lo + hi) / 2
	lo = (mid - want / 2).clamp(Vector2i.ZERO, Vector2i(fog.cols, fog.rows) - want)
	_view = Rect2i(lo, want.min(Vector2i(fog.cols, fog.rows)))
	_scale = clampf(floorf(minf(1180.0 / _view.size.x, 600.0 / _view.size.y)), 2.0, 9.0)
	map_rect.size = Vector2(_view.size) * _scale
	map_rect.position = (Vector2(1280, 720) - map_rect.size) / 2.0 + Vector2(0, 20)
	# Bytes, not set_pixel (performance: the valley is 44,800 tiles since the regions grew 4x).
	_ensure_palette()
	var px := PackedByteArray()
	px.resize(fog.cols * fog.rows * 4)
	for i in fog.terrain.size():
		var k := 0   # palette row: 0 unseen; then per terrain, lit and dim
		if fog.remembered[i] == 1:
			var ter: int = fog.terrain[i]
			if ter == FogGrid.T_ROCK:
				k = 1
			else:
				k = 2 + mini(ter, 3) * 2 + (0 if fog.density[i] < FogGrid.REMEMBER_BELOW else 1)
		var o := i * 4
		var c: PackedByteArray = _palette[k]
		px[o] = c[0]
		px[o + 1] = c[1]
		px[o + 2] = c[2]
		px[o + 3] = 255
	img.set_data(fog.cols, fog.rows, false, Image.FORMAT_RGBA8, px)
	for l in get_tree().get_nodes_in_group("lantern"):
		var t := fog.tile_of(l.global_position)
		if fog.in_bounds(t):
			var c := Color(1.0, 0.75, 0.3)
			if l.kind == "mirror":
				c = Color(0.9, 0.95, 1.0) if l.is_lit() else Color(0.45, 0.55, 0.7)
			elif not l.is_lit():
				c = Color(0.95, 0.3, 0.25)
			elif l.fuel_frac() < 0.25:
				c = Color(1.0, 0.95, 0.4)
			img.set_pixel(t.x, t.y, c)
	for w in get_tree().get_nodes_in_group("waylamp"):
		var wt := fog.tile_of(w.global_position)
		if fog.in_bounds(wt) and fog.remembered[fog.idx(wt)] == 1:
			img.set_pixel(wt.x, wt.y, Color(1.0, 0.95, 0.6) if w.is_lit() else Color(0.75, 0.5, 0.25))
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var pt := fog.tile_of(player.global_position)
		if fog.in_bounds(pt):
			img.set_pixel(pt.x, pt.y, Color.WHITE)
	var shown := img.get_region(_view)
	if tex == null or tex.get_size() != Vector2(shown.get_size()):
		tex = ImageTexture.create_from_image(shown)
		map_rect.texture = tex
	else:
		tex.update(shown)
	_update_names()

var _palette: Array = []

## The map's colours as bytes: unseen, rock, then each walkable terrain lit and dim (as before).
func _ensure_palette() -> void:
	if not _palette.is_empty():
		return
	var base := {FogGrid.T_GROUND: Color(0.33, 0.42, 0.28), FogGrid.T_ROCK: Color(0.2, 0.2, 0.23),
		FogGrid.T_MARSH: Color(0.22, 0.34, 0.32), FogGrid.T_BOARDWALK: Color(0.58, 0.46, 0.3)}
	var cols: Array[Color] = [Color(0.015, 0.015, 0.025), base[FogGrid.T_ROCK]]
	for ter in 4:
		var c: Color = base[ter]
		cols.append(c.lightened(0.25))
		cols.append(c.darkened(0.45))
	for c in cols:
		_palette.append(PackedByteArray([c.r8, c.g8, c.b8, 255]))

func _compute_centroids(fog: FogGrid) -> void:
	var sums := {}
	for y in fog.rows:
		for x in fog.cols:
			var r: int = fog.region[y * fog.cols + x]
			if r == 0 or fog.solid[y * fog.cols + x] == 1:
				continue
			if not sums.has(r):
				sums[r] = [Vector2.ZERO, 0]
			sums[r][0] += Vector2(x + 0.5, y + 0.5)
			sums[r][1] += 1
	for r in sums:
		_centroids[r] = sums[r][0] / float(sums[r][1])

func _update_names() -> void:
	for n in names:
		n.queue_free()
	names.clear()
	for r in Progress.regions_seen:
		if not _centroids.has(r) or r >= FogGrid.REGION_NAMES.size():
			continue
		var l := Label.new()
		l.text = FogGrid.REGION_NAMES[r]
		l.add_theme_color_override("font_shadow_color", Color.BLACK)
		l.add_theme_constant_override("shadow_offset_x", 1)
		l.add_theme_constant_override("shadow_offset_y", 1)
		var c: Vector2 = _centroids[r] - Vector2(_view.position)
		if not Rect2(Vector2.ZERO, Vector2(_view.size)).has_point(c):
			continue
		l.position = map_rect.position + c * _scale - Vector2(50, 34)   # sit above paths through the centre
		root.add_child(l)
		names.append(l)
