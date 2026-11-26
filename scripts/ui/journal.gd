extends CanvasLayer
## The keeper's journal: J / gamepad Back (View). Three pages, left/right to switch:
##   Goals       the current goal and the ones finished
##   Story       the keeper's own entries ("story so far"), and H.'s letter
##   Notes       every landmark you have read, in full, to read again
## Up/down scrolls. J / Back / B / Esc closes.

const PAGES := ["Goals", "Story so far", "Notes"]

var root: Control
var title: Label
var tabs: Label
var body: Label
var scroll: ScrollContainer
var page := 0

func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.size = Vector2(1280, 720)
	add_child(root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.05, 1.0)   # solid: the HUD must not show through
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	title = Label.new()
	title.position = Vector2(140, 40)
	title.add_theme_font_size_override("font_size", 40)
	root.add_child(title)
	tabs = Label.new()
	tabs.position = Vector2(140, 100)
	root.add_child(tabs)
	scroll = ScrollContainer.new()
	scroll.position = Vector2(140, 150)
	scroll.size = Vector2(1000, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	body = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(980, 0)
	scroll.add_child(body)
	var hint := Label.new()
	hint.text = "[Left / Right] page    [Up / Down] scroll    [J / Back / B] close"
	hint.position = Vector2(140, 670)
	hint.modulate = Color(1, 1, 1, 0.6)
	root.add_child(hint)
	root.visible = false

func is_open() -> bool:
	return root.visible

func toggle() -> void:
	if root.visible:
		root.visible = false
		Tuning.ui_open = false
		get_tree().paused = false
		Progress.block_input()
		Sfx.play("note_close", -12.0)
	elif not Tuning.ui_open:
		root.visible = true
		Tuning.ui_open = true
		get_tree().paused = true
		page = 0
		refresh()
		Sfx.play("note_open", -10.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal") or (root.visible and (event.is_action_pressed("cancel") or event.is_action_pressed("pause"))):
		toggle()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not root.visible:
		return
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		page = (page + PAGES.size() - 1) % PAGES.size()
		refresh()
		Sfx.play("ui_tick", -16.0)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		page = (page + 1) % PAGES.size()
		refresh()
		Sfx.play("ui_tick", -16.0)
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		scroll.scroll_vertical += 8
	elif Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		scroll.scroll_vertical -= 8

func refresh() -> void:
	title.text = "%s's journal" % Story.display_name()
	var t := []
	for i in PAGES.size():
		t.append("[ %s ]" % PAGES[i] if i == page else "  %s  " % PAGES[i])
	tabs.text = "   ".join(t)
	scroll.scroll_vertical = 0
	match page:
		0:
			body.text = _goals_text()
		1:
			body.text = _story_text()
		_:
			body.text = _notes_text()

func _goals_text() -> String:
	var lines: Array[String] = []
	if Story.current != "":
		lines.append("Now:   " + Story.goal_text(Story.current))
	else:
		lines.append("Now:   Nothing pressing. The valley waits.")
	lines.append("")
	lines.append("Done:")
	var any := false
	for g in Story.GOALS:
		if Story.done.has(g["id"]):
			lines.append("   + " + g["text"])
			any = true
	if not any:
		lines.append("   (nothing yet)")
	lines.append("")
	lines.append("Goal pointer: %s  (change it in the pause menu)" % {"auto": "on in the Hollow, off after", "on": "always on", "off": "off"}.get(Story.pointer_mode, "auto"))
	return "\n".join(lines)

func _story_text() -> String:
	var parts: Array[String] = ["The letter\n" + Story.LETTER]
	for n in Story.entries:
		var e: Array = Story.ENTRIES[n]
		parts.append("%s\n%s" % [e[0], e[1]])
	return "\n\n".join(parts)

func _notes_text() -> String:
	var parts: Array[String] = []
	for m in get_tree().get_nodes_in_group("landmark"):
		if Progress.notes_read.has(m.id):
			parts.append("%s\n%s" % [m.title, m.text])
	if parts.is_empty():
		return "No notes yet. Look closer at what your light finds."
	return "\n\n".join(parts)
