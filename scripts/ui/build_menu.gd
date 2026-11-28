extends CanvasLayer
## Lanterns: choosing what to build.
##   Tap Tab / D-pad right: switch to the next lantern you have (no menu). D-pad left: the previous one.
##   Hold Tab / D-pad right: open the list of cards. Left/right to choose, A / E / X / C / B / Tab to close.
##   Keys 1-4: pick a lantern directly.
## The world is paused while the list is open. M1a: Y is a skill slot now, and the D-pad keys are read only
## while no menu is open (GAME_PLAN §3).

const HOLD := 0.35   # seconds held before the list opens instead of switching

var root: Control
var cards: Array[PanelContainer] = []
var index := 0
var _held := -1.0     # >= 0 while the button is held

func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.02, 0.7)
	dim.size = Vector2(1280, 720)
	root.add_child(dim)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD, UiStyle.NAVY, 2, 18))
	root.add_child(frame)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	frame.add_child(col)
	var title := UiStyle.label(40, UiStyle.GOLD)
	title.text = "Lanterns"
	col.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	col.add_child(row)
	for k in Progress.LANTERN_ORDER:
		var c := PanelContainer.new()
		c.custom_minimum_size = Vector2(230, 300)
		row.add_child(c)
		cards.append(c)
	var hint := UiStyle.label(20, Color(0.43, 0.56, 0.7))
	hint.name = "Hint"
	col.add_child(hint)
	frame.reset_size()
	root.visible = false
	frame.position = Vector2(64, 140)

func is_open() -> bool:
	return root.visible

func open() -> void:
	root.visible = true
	Tuning.ui_open = true
	get_tree().paused = true
	index = maxi(0, Progress.LANTERN_ORDER.find(Progress.selected))
	_refresh()
	Sfx.play("ui_open", -14.0)

func close() -> void:
	Sfx.play("ui_close", -14.0)
	root.visible = false
	Tuning.ui_open = false
	get_tree().paused = false
	Progress.block_input()

## Next unlocked lantern after the selected one (wraps); dir -1 goes back. Public for tests.
func cycle(dir: int = 1) -> void:
	var order: Array = Progress.LANTERN_ORDER
	var i := order.find(Progress.selected)
	for step in range(1, order.size() + 1):
		var k: String = order[posmod(i + step * dir, order.size())]
		if Progress.is_unlocked(k):
			if k != Progress.selected:
				Progress.selected = k
				Sfx.play("ui_tick", -12.0)
			return

func select_slot(n: int) -> void:
	var order: Array = Progress.LANTERN_ORDER
	if n >= 0 and n < order.size() and Progress.is_unlocked(order[n]):
		Progress.selected = order[n]
		Sfx.play("ui_tick", -12.0)

func _unhandled_input(event: InputEvent) -> void:
	if root.visible:
		# (D-pad right is "build_menu" too, but in the list it moves the cursor: only the Tab key closes it.)
		if (event.is_action_pressed("build_menu") and event is InputEventKey) or event.is_action_pressed("interact") or event.is_action_pressed("place_lantern") or event.is_action_pressed("cancel"):
			close()
			get_viewport().set_input_as_handled()
		return
	if Tuning.ui_open:
		return
	if event.is_action_pressed("lamp_prev"):
		cycle(-1)
		get_viewport().set_input_as_handled()
		return
	for n in 4:
		if event.is_action_pressed("select_%d" % (n + 1)):
			select_slot(n)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("build_menu"):
		_held = 0.0
		get_viewport().set_input_as_handled()
	elif event.is_action_released("build_menu") and _held >= 0.0:
		if _held < HOLD:
			cycle()   # a tap switches lanterns
		_held = -1.0
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _held >= 0.0 and not root.visible:
		_held += delta
		if Tuning.ui_open:
			_held = -1.0   # another menu opened mid-hold: the hold is off (its release never reaches us)
		elif _held >= HOLD:
			_held = -1.0
			open()   # a hold opens the list
	if not root.visible:
		return
	var order: Array = Progress.LANTERN_ORDER
	var moved := false
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		index = posmod(index - 1, order.size())
		moved = true
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		index = posmod(index + 1, order.size())
		moved = true
	if moved:
		if Progress.is_unlocked(order[index]):
			Progress.selected = order[index]
		Sfx.play("ui_tick", -16.0)
		_refresh()

func _refresh() -> void:
	var order: Array = Progress.LANTERN_ORDER
	for i in order.size():
		_fill_card(cards[i], order[i], i == index)
	var hint: Label = root.find_child("Hint", true, false)
	if InputHint.pad:
		hint.text = "Left / Right choose    A select    tap D-pad right or left to switch without this list"
	else:
		hint.text = "A / D choose    E select    tap Tab to switch without opening    keys 1-4 pick directly"

func _fill_card(card: PanelContainer, k: String, cursor: bool) -> void:
	for c in card.get_children():
		c.queue_free()
	var unlocked := Progress.is_unlocked(k)
	var selected := k == Progress.selected
	var border := UiStyle.AMBER if cursor else (UiStyle.GOLD if selected else Color(0.29, 0.42, 0.58, 0.6))
	card.add_theme_stylebox_override("panel", UiStyle.panel(border, Color(0.043, 0.055, 0.1, 0.95), 3 if cursor else 1, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	var pic := TextureRect.new()
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(200, 96)
	var file := {"post": "post_lamp_lit.png", "reservoir": "reservoir_lamp_lit.png", "hooded": "hooded_lamp_lit.png", "mirror": "mirror_post_lit.png"}.get(k, "post_lamp_lit.png") as String
	pic.texture = Art.placeholder(file)
	if not unlocked:
		pic.modulate = Color(0.05, 0.06, 0.1, 0.9)
	v.add_child(pic)
	var name_l := UiStyle.label(30, UiStyle.GOLD if unlocked else Color(0.43, 0.56, 0.7))
	name_l.text = Lantern.display(k) if unlocked else "???"
	v.add_child(name_l)
	if unlocked:
		var cost := HBoxContainer.new()
		cost.add_theme_constant_override("separation", 6)
		v.add_child(cost)
		for res in [["scrap", Lantern.cost(k)]]:   # M1b: scrap is the one material
			if res[1] <= 0:
				continue
			cost.add_child(UiStyle.icon_rect("icon_" + res[0], 22))
			var have: bool = Inventory.get_count(res[0]) >= res[1]
			var n := UiStyle.label(20, UiStyle.CREAM if have else UiStyle.WARN)
			n.text = str(res[1])
			cost.add_child(n)
		var blurb := UiStyle.label(20, UiStyle.PALE)
		blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		blurb.custom_minimum_size = Vector2(200, 0)
		blurb.text = Lantern.blurb(k)
		v.add_child(blurb)
		if selected:
			var tag := UiStyle.label(20, UiStyle.AMBER)
			tag.text = "Selected"
			v.add_child(tag)
	else:
		var hint := UiStyle.label(20, Color(0.43, 0.56, 0.7))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.custom_minimum_size = Vector2(200, 0)
		hint.text = "Found somewhere in the valley."
		v.add_child(hint)
