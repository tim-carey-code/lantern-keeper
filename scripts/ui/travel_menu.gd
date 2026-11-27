extends CanvasLayer
## WayLamp fast travel (owner 2026-11-27: "the loop with a one way ridge plus waylamp fast travel").
## Lit WayLamps form a network. Interact with a lit WayLamp to open this list of every lit WayLamp;
## pick one and the keeper is there after a short fade. Pauses the world while open.
## Keyboard (arrows + E / Enter), mouse, and gamepad (D-pad + A). B, Q, Escape or Start closes it.
## Travel is blocked while foes hunt the keeper, while any WayLamp kindles, and during a guardian fight.
## Which WayLamps are lit is Progress.settled (saved), so the network needs nothing new in the save.
## Texts are DRAFT in docs/STORY.md section 11.

const TITLE := "WayLamps"
const SUBTITLE := "Travel to a lit WayLamp."
const HERE := "%s (you are here)"
const ALONE := "Light another WayLamp to travel to it."
const STAY := "Stay"
const BLOCK_HUNTED := "Can't travel while something hunts you"
const BLOCK_KINDLING := "Can't travel while a WayLamp kindles"
const BLOCK_GUARDIAN := "Can't travel during a guardian fight"

const FADE_OUT := 0.25
const FADE_IN := 0.35
const ARRIVE_OFFSET := Vector2(0, 48)   # stand just below the lamp, in reach of it

var root: Control
var list: VBoxContainer
var note: Label
var fade: ColorRect
var buttons: Array[Button] = []
var from_lamp: WayLamp
var travelling := false

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("travel_menu")
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.02, 0.7)
	dim.size = root.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var frame := PanelContainer.new()
	frame.position = Vector2(370, 170)
	frame.custom_minimum_size = Vector2(540, 0)
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.AMBER, UiStyle.NAVY, 2, 20))
	root.add_child(frame)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	frame.add_child(col)
	var title := UiStyle.label(40, UiStyle.GOLD)
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var sub := UiStyle.label(20, UiStyle.PALE)
	sub.text = SUBTITLE
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	col.add_child(list)
	note = UiStyle.label(20, UiStyle.PALE)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(note)
	# The fade sits above everything, also above the menu.
	fade = ColorRect.new()
	fade.color = Color(0.0, 0.0, 0.0, 0.0)
	fade.size = Vector2(1280, 720)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.visible = false
	add_child(fade)

func _main() -> Node:
	return get_tree().get_first_node_in_group("main")

func is_open() -> bool:
	return root.visible

# --- The network -------------------------------------------------------------------

## Every lit WayLamp, Hollow first (region order).
func lit_waylamps() -> Array[WayLamp]:
	var out: Array[WayLamp] = []
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w is WayLamp and w.is_lit():
			out.append(w)
	out.sort_custom(func(a: WayLamp, b: WayLamp) -> bool: return a.region_id < b.region_id)
	return out

## "" if the keeper may travel now, otherwise why not (shown over the WayLamp).
func block_reason() -> String:
	var main := _main()
	if main == null:
		return BLOCK_HUNTED
	for w in get_tree().get_nodes_in_group("waylamp"):
		if w.kindling:
			return BLOCK_KINDLING
	var keeper: Node2D = main.player
	for f in get_tree().get_nodes_in_group("foe"):
		if f.is_queued_for_deletion() or f._dead or f is WickNest:
			continue
		if f is Ashbrood:
			return BLOCK_GUARDIAN
		var near: bool = f.global_position.distance_to(keeper.global_position) <= Tuning.travel_hunt_radius
		if not near:
			continue
		if (f is Clinker and f.awake) or f is Spitwick or (f is Wickling and f.state == Wickling.State.CHASE):
			return BLOCK_HUNTED
	return ""

func arrive_pos(w: WayLamp) -> Vector2:
	var fog: FogGrid = _main().fog
	var p := w.global_position + ARRIVE_OFFSET
	if fog.is_solid_at(p):
		p = w.global_position
	return p

# --- The menu ------------------------------------------------------------------------

## Opens the list at a lit WayLamp. Returns false (and opens nothing) when travel is blocked.
func open(at: WayLamp) -> bool:
	if root.visible or travelling or Tuning.ui_open:
		return false
	if block_reason() != "":
		Sfx.play("ui_error", -14.0)
		return false
	from_lamp = at
	# Remove the old buttons from the list first, so focus lands on the new ones (the level-up bug).
	for b in list.get_children():
		list.remove_child(b)
		b.queue_free()
	buttons.clear()
	var first: Button = null
	for w in lit_waylamps():
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 30)
		b.custom_minimum_size = Vector2(500, 52)
		if w == at:
			b.text = HERE % w.title
			b.disabled = true
			b.focus_mode = Control.FOCUS_NONE
		else:
			b.text = w.title
			b.pressed.connect(_pick.bind(w))
			if first == null:
				first = b
		list.add_child(b)
		buttons.append(b)
	var stay := Button.new()
	stay.add_theme_font_size_override("font_size", 30)
	stay.custom_minimum_size = Vector2(500, 52)
	stay.text = STAY
	stay.pressed.connect(close)
	list.add_child(stay)
	buttons.append(stay)
	note.text = ALONE if first == null else ""
	note.visible = first == null
	root.visible = true
	Tuning.ui_open = true
	get_tree().paused = true
	(first if first else stay).grab_focus()
	Sfx.play_ui("ui_open", -14.0)
	return true

func close() -> void:
	if not root.visible:
		return
	root.visible = false
	get_viewport().gui_release_focus()
	if not travelling:
		Tuning.ui_open = false
		get_tree().paused = false
		Progress.block_input()
		Sfx.play_ui("ui_close", -14.0)

## The gamepad's A (our "interact") presses the focused button, as in the pause menu (ui_accept has no A here).
## B / Q (cancel) and Escape / Start (pause) close the list. Handled in _input so no other menu sees them.
func _input(event: InputEvent) -> void:
	if travelling:
		if event.is_action_pressed("interact") or event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
			get_viewport().set_input_as_handled()
		return
	if not root.visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("interact") and not event.is_action_pressed("ui_accept"):
		var f := get_viewport().gui_get_focus_owner()
		get_viewport().set_input_as_handled()
		if f is Button and buttons.has(f):
			(f as Button).pressed.emit()

func _pick(w: WayLamp) -> void:
	travel_to(w)

## Fades out, moves the keeper to the WayLamp, fades back in. Returns false if blocked.
func travel_to(w: WayLamp) -> bool:
	if travelling or not w.is_lit() or block_reason() != "":
		close()
		return false
	travelling = true
	close()
	Tuning.ui_open = true
	get_tree().paused = true
	fade.visible = true
	fade.color.a = 0.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(fade, "color:a", 1.0, FADE_OUT)
	tw.tween_callback(_arrive.bind(w))
	tw.tween_property(fade, "color:a", 0.0, FADE_IN)
	tw.tween_callback(_done)
	Sfx.play_ui("relight", -10.0)
	return true

func _arrive(w: WayLamp) -> void:
	var main := _main()
	var keeper: CharacterBody2D = main.player
	keeper.global_position = arrive_pos(w)
	keeper.velocity = Vector2.ZERO
	keeper.reset_physics_interpolation()
	var cam: Camera2D = keeper.get_node_or_null("Camera2D")
	if cam:
		cam.reset_smoothing()
	Story.update(main)

func _done() -> void:
	fade.visible = false
	travelling = false
	Tuning.ui_open = false
	get_tree().paused = false
	Progress.block_input()
