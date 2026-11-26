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

func _ready() -> void:
	layer = 9
	root = Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
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
		root.visible = false
		Tuning.ui_open = false
		Progress.block_input()
	elif not Tuning.ui_open:
		root.visible = true
		Tuning.ui_open = true
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
		_scale = floorf(minf(1180.0 / fog.cols, 620.0 / fog.rows))
		map_rect.size = Vector2(fog.cols, fog.rows) * _scale
		map_rect.position = (Vector2(1280, 720) - map_rect.size) / 2.0 + Vector2(0, 16)
		_compute_centroids(fog)
	for y in fog.rows:
		for x in fog.cols:
			var i := y * fog.cols + x
			var c := Color(0.015, 0.015, 0.025)
			if fog.remembered[i] == 1:
				match fog.terrain[i]:
					FogGrid.T_ROCK:
						c = Color(0.2, 0.2, 0.23)
					FogGrid.T_MARSH:
						c = Color(0.22, 0.34, 0.32)
					FogGrid.T_BOARDWALK:
						c = Color(0.58, 0.46, 0.3)
					_:
						c = Color(0.33, 0.42, 0.28)
				if fog.terrain[i] != FogGrid.T_ROCK:
					c = c.lightened(0.25) if fog.density[i] < FogGrid.REMEMBER_BELOW else c.darkened(0.45)
			img.set_pixel(x, y, c)
	for l in get_tree().get_nodes_in_group("lantern"):
		var t := fog.tile_of(l.global_position)
		if fog.in_bounds(t):
			var c := Color(1.0, 0.75, 0.3)
			if not l.is_lit():
				c = Color(0.95, 0.3, 0.25)
			elif l.fuel_frac() < 0.25:
				c = Color(1.0, 0.95, 0.4)
			img.set_pixel(t.x, t.y, c)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var pt := fog.tile_of(player.global_position)
		if fog.in_bounds(pt):
			img.set_pixel(pt.x, pt.y, Color.WHITE)
	if tex == null:
		tex = ImageTexture.create_from_image(img)
		map_rect.texture = tex
	else:
		tex.update(img)
	_update_names()

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
		l.position = map_rect.position + _centroids[r] * _scale - Vector2(50, 10)
		root.add_child(l)
		names.append(l)
