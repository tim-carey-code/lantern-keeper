extends CanvasLayer
## The Skills list (M1a: a plain list; the keeper's pack with a Skills tab comes in M2, GAME_PLAN §14).
## K / D-pad down opens it, only while no other menu is open. Left / right picks a slot (slot 2, 3 or 4; slot 1 is
## always Lampfire), up / down picks a skill, A / E / a click puts it on that slot (pressing the skill already
## there takes it off). B, K or Esc / Start closes it. It opens on slot 3 with the first skill that's off the bar,
## so after level 2 one press puts the Beam back on LB. Greyed, with the reason, while something hunts you.
## The world is paused while it is open. Texts are DRAFT (docs/replan/M1A_BUILD_NOTES.md).

const TITLE := "Skills"
const HUNTED := "Something hunts you. Change skills when it's quiet."
const PLACED := "%s is on %s."
const REMOVED := "%s is off the bar."
const NOT_YET := "%s (level %d)"
const EMPTY := "empty"
const DASH_ROW := "Dash   %s   A quick step. Nothing can chill you mid-dash."
const HINT_PAD := "Left / Right: slot    Up / Down: skill    A: put it there    B: close"
const HINT_KEYS := "A / D or arrows: slot    W / S: skill    E or click: put it there    K / Esc: close"

var root: Control
var slot_row: HBoxContainer
var list: VBoxContainer
var info: Label
var hint: Label
var dash_label: Label
var slot := "skill_3"
var buttons := {}            # skill id -> Button
var locked := false          # hunted when it opened: nothing can be changed

func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("skills_list")
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.02, 0.86)
	dim.size = root.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var frame := PanelContainer.new()
	frame.position = Vector2(250, 40)
	frame.custom_minimum_size = Vector2(780, 0)
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD, UiStyle.NAVY, 2, 18))
	root.add_child(frame)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	frame.add_child(col)
	var title := UiStyle.label(40, UiStyle.GOLD)
	title.text = TITLE
	col.add_child(title)
	slot_row = HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 10)
	col.add_child(slot_row)
	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	col.add_child(list)
	dash_label = UiStyle.label(20, UiStyle.PALE)
	col.add_child(dash_label)
	info = UiStyle.label(20, UiStyle.CREAM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(740, 0)
	col.add_child(info)
	hint = UiStyle.label(20, Color(0.43, 0.56, 0.7))
	col.add_child(hint)

func is_open() -> bool:
	return root.visible

## Opens the list. False (and nothing opens) while another menu is open.
func open() -> bool:
	if root.visible or Tuning.ui_open:
		return false
	var main := get_tree().get_first_node_in_group("main")
	locked = main != null and Hunt.is_hunted(get_tree(), main.player.global_position)
	slot = "skill_3"
	root.visible = true
	Tuning.ui_open = true
	get_tree().paused = true
	info.text = HUNTED if locked else ""
	info.add_theme_color_override("font_color", UiStyle.WARN if locked else UiStyle.CREAM)
	_rebuild(true)
	Sfx.play_ui("ui_open", -14.0)
	return true

func close() -> void:
	if not root.visible:
		return
	root.visible = false
	get_viewport().gui_release_focus()
	Tuning.ui_open = false
	get_tree().paused = false
	Progress.block_input()
	Sfx.play_ui("ui_close", -14.0)

## Picks the slot being filled (tests, and left / right).
func choose_slot(s: String) -> void:
	if s in ["skill_2", "skill_3", "skill_4"]:
		slot = s
		_rebuild(false)

## Puts skill `id` on the chosen slot (or takes it off if it is there already). Returns "" or why not.
func pick(id: String) -> String:
	if locked:
		info.text = HUNTED
		return HUNTED
	var s: Skill = _combat().skill(id) if _combat() else null
	var name_s := s.title() if s else id
	var why := ""
	if Progress.bar.get(slot, "") == id and slot != "skill_1":
		why = Progress.bind(slot, "")
		if why == "":
			info.text = REMOVED % name_s
	else:
		why = Progress.bind(slot, id)
		if why == "":
			info.text = PLACED % [name_s, InputHint.key(slot)]
	if why != "":
		info.text = why
		info.add_theme_color_override("font_color", UiStyle.WARN)
		Sfx.play_ui("ui_error", -14.0)
	else:
		info.add_theme_color_override("font_color", UiStyle.CREAM)
		Sfx.play_ui("ui_tick", -10.0)
	_rebuild(false, id)
	return why

func _combat() -> KeeperCombat:
	var p := get_tree().get_first_node_in_group("player")
	return p.combat if p else null

func _rebuild(fresh: bool, keep_focus: String = "") -> void:
	var combat := _combat()
	for c in slot_row.get_children():
		slot_row.remove_child(c)
		c.queue_free()
	for s in Progress.SLOTS:
		var chip := PanelContainer.new()
		var sel: bool = s == slot
		chip.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.AMBER if sel else Color(0.29, 0.42, 0.58, 0.6), Color(0.043, 0.055, 0.1, 0.95), 3 if sel else 1, 8))
		chip.custom_minimum_size = Vector2(176, 0)
		var v := VBoxContainer.new()
		chip.add_child(v)
		var key := UiStyle.label(20, UiStyle.GOLD if sel else UiStyle.PALE)
		key.text = InputHint.key(s)
		v.add_child(key)
		var id: String = Progress.bar.get(s, "")
		var nm := UiStyle.label(20, UiStyle.CREAM if id != "" else Color(0.43, 0.56, 0.7))
		nm.text = combat.skill(id).title() if combat and id != "" else EMPTY
		v.add_child(nm)
		slot_row.add_child(chip)
	for c in list.get_children():
		list.remove_child(c)   # out of the list first, so focus lands on the new buttons (the level-up bug)
		c.queue_free()
	buttons.clear()
	var focus_id := keep_focus
	for id in Progress.SKILL_ORDER:
		var s: Skill = combat.skill(id) if combat else null
		if s == null:
			continue
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 20)
		b.custom_minimum_size = Vector2(740, 62)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var on := Progress.slot_of(id)
		var where := ("   [%s]" % InputHint.key(on)) if on != "" else ""
		if not Progress.knows(id):
			b.text = NOT_YET % [s.title(), Tuning.kl_lance_level] + "\n" + s.blurb()
			b.disabled = true
		else:
			b.text = "%s%s   %s\n%s" % [s.title(), where, s.facts(), s.blurb()]
			b.disabled = locked or id == "lampfire"
		if b.disabled:
			b.focus_mode = Control.FOCUS_NONE
		else:
			b.pressed.connect(pick.bind(id))
			if fresh and focus_id == "" and on == "":
				focus_id = id   # the first skill that's off the bar: one press puts it on slot 3
		list.add_child(b)
		buttons[id] = b
	dash_label.text = DASH_ROW % InputHint.key("dash")
	hint.text = HINT_PAD if InputHint.pad else HINT_KEYS
	var target: Button = buttons.get(focus_id)
	if target == null or target.disabled:
		for id in buttons:
			if not buttons[id].disabled:
				target = buttons[id]
				break
	if target:
		target.grab_focus()

## Handled in _input so no other menu (or the world) sees these presses while the list is open.
func _input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("pause") or (event.is_action_pressed("skills") and event is InputEventKey):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		_step_slot(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		_step_slot(1)
	elif event.is_action_pressed("interact") and not event.is_action_pressed("ui_accept"):
		var f := get_viewport().gui_get_focus_owner()
		get_viewport().set_input_as_handled()
		if f is Button and not (f as Button).disabled:
			(f as Button).pressed.emit()

func _step_slot(d: int) -> void:
	var order := ["skill_2", "skill_3", "skill_4"]
	var i := order.find(slot)
	var focused := ""
	var f := get_viewport().gui_get_focus_owner()
	for id in buttons:
		if buttons[id] == f:
			focused = id
	slot = order[clampi(i + d, 0, order.size() - 1)]
	Sfx.play_ui("ui_tick", -16.0)
	_rebuild(false, focused)

func _unhandled_input(event: InputEvent) -> void:
	if root.visible or Tuning.ui_open:
		return
	if event.is_action_pressed("skills"):
		if open():
			get_viewport().set_input_as_handled()
