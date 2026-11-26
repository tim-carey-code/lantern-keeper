extends CanvasLayer
## Lantern list. Tab / gamepad Y opens it (the keeper stops). Up/down picks a
## lantern you have unlocked; Tab / Y, E / A, Space / X or Q / B closes it.
## Locked lanterns show as ??? so the player knows more are out there.

var panel: PanelContainer
var body: Label
var index := 0

func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS   # works while the world is paused
	panel = PanelContainer.new()
	panel.position = Vector2(1280 - 16 - 560, 130)
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD, UiStyle.NAVY, 2, 14))
	add_child(panel)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(536, 0)
	panel.add_child(body)
	panel.visible = false

func is_open() -> bool:
	return panel.visible

func open() -> void:
	panel.visible = true
	Tuning.ui_open = true
	get_tree().paused = true   # reading or choosing never costs you anything
	Sfx.play("ui_open", -14.0)
	index = maxi(0, Progress.LANTERN_ORDER.find(Progress.selected))

func close() -> void:
	Sfx.play("ui_close", -14.0)
	panel.visible = false
	Tuning.ui_open = false
	get_tree().paused = false
	Progress.block_input()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		if panel.visible:
			close()
		elif not Tuning.ui_open:
			open()
		get_viewport().set_input_as_handled()
	elif panel.visible and (event.is_action_pressed("interact") or event.is_action_pressed("place_lantern") or event.is_action_pressed("cancel")):
		close()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not panel.visible:
		return
	# Just-pressed works for D-pad, stick and keys without repeat spam.
	if Input.is_action_just_pressed("move_up") and index > 0:
		index -= 1
		Sfx.play("ui_tick", -16.0)
	elif Input.is_action_just_pressed("move_down") and index < Progress.LANTERN_ORDER.size() - 1:
		index += 1
		Sfx.play("ui_tick", -16.0)
	var kind: String = Progress.LANTERN_ORDER[index]
	if Progress.is_unlocked(kind):
		Progress.selected = kind
	var scrap := Inventory.get_count("scrap")
	var lines: Array[String] = ["Lanterns   (up/down to choose, Tab / Y to close)", ""]
	for i in Progress.LANTERN_ORDER.size():
		var k: String = Progress.LANTERN_ORDER[i]
		var cursor := ">" if i == index else " "
		if Progress.is_unlocked(k):
			var tag := "  [selected]" if k == Progress.selected else ""
			var ok := scrap >= Lantern.cost(k) and Inventory.get_count("glass") >= Lantern.glass_cost(k)
			var afford := "ready" if ok else "not enough yet"
			lines.append("%s %s   %s   %s%s" % [cursor, Lantern.display(k), Lantern.cost_text(k), afford, tag])
			lines.append("     %s" % Lantern.blurb(k))
		else:
			lines.append("%s ???   found somewhere in the valley" % cursor)
	body.text = "\n".join(lines)
