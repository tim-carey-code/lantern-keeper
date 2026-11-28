extends CanvasLayer
## The pack's Skills tab (M2, GAME_PLAN §3, §4.2, §14; was the M1a Skills list). Three parts:
##   - the bar's slots across the top (RT is always Lampfire);
##   - the skills down the left (Lampfire, Fireglobe, Lance, the dash; the optional Beam and Hearth ring last);
##   - the focused skill's branch tree on the right: three tiers, one pick each, a skill point a pick.
## Pad: the D-pad moves (up / down in a column; right from a skill into its tree, left back), A acts, B goes back or
## closes. A on a skill: choose its slot (left / right), A puts it there (on the slot it's on: takes it off), B backs
## out. A on a pick takes it. Resting at a lit WayLamp opens respec (Progress.respec_open): A on another pick in a
## taken tier swaps it, A on a taken pick gives it back, and the row under the tree resets every pick. Keyboard and
## mouse: arrows / WASD move, E or a click acts, K / Esc closes. Greyed, with the reason, while something hunts you.
## Owner note (2026-11-28, "the skills coming up for the Beam after it was already replaced is not great"): nothing
## here pushes a skill that isn't on the bar. It opens on a skill on the bar; the Beam and Hearth ring are marked
## optional. The world is paused while it is open. Texts are DRAFT (STORY §17).

const TITLE := "Skills"
const HUNTED := "Something hunts you. Change skills when it's quiet."
const PLACED := "%s is on %s."
const REMOVED := "%s is off the bar."
const NOT_YET := "%s (level %d)"
const EMPTY := "empty"
const OPTIONAL := "optional"
const POINTS := "Skill points: %d"
const RESPEC_OPEN := "Resting by the WayLamp: your picks can be changed for free."
const RESPEC_SHUT := "Picks are kept. Rest at a lit WayLamp to change them."
const RESET_ROW := "Give back every pick (free while you rest here)"
const TAKEN := "%s: taken."
const CHOOSE_SLOT := "Choose a slot for %s."
const DASH_SLOT := "The dash is always on %s."
const LAMPFIRE_SLOT := "Lampfire stays on slot 1."
const HINT_PAD := "D-pad: move    A: choose    B: back / close"
const HINT_KEYS := "Arrows / WASD: move    E or click: choose    K / Esc: close"
const HINT_SLOTS_PAD := "Left / Right: slot    A: put it there    B: back"
const HINT_SLOTS_KEYS := "Left / Right: slot    E: put it there    Esc: back"
const ORDER := ["lampfire", "fireglobe", "lance", "dash", "beam", "hearth_ring"]
const OPTIONAL_SKILLS := ["beam", "hearth_ring"]
const PICK_SLOTS := ["skill_2", "skill_3", "skill_4"]

var root: Control
var slot_row: HBoxContainer
var list: VBoxContainer
var tree_box: VBoxContainer
var tree_title: Label
var points_label: Label
var respec_label: Label
var info: Label
var hint: Label
var detail: Label                # the focused pick's title, text and why it can't be taken (under the tree)
var slot := "skill_3"            # the slot a skill goes on (place mode; tests set it with choose_slot)
var buttons := {}                # skill id -> Button
var pick_buttons := {}           # pick id -> Button
var reset_button: Button
var locked := false              # hunted when it opened: nothing can be changed
## The cursor: area "list" (a skill), "tree" (a pick; row 3 = the reset row), "slots" (choosing a slot).
var area := "list"
var list_i := 0
var tier_i := 0
var col_i := 0
var placing := ""                # the skill being placed (area "slots")

func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("skills_list")
	root = Control.new()
	root.size = Vector2(1280, 720)
	root.visible = false
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.012, 0.02, 0.96)
	dim.size = root.size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var frame := Panel.new()
	frame.position = Vector2(32, 56)
	frame.size = Vector2(1216, 652)
	frame.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.WOOD, UiStyle.NAVY, 2, 0))
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(frame)
	var title := UiStyle.label(30, UiStyle.GOLD)
	title.text = TITLE
	title.position = Vector2(56, 62)
	root.add_child(title)
	points_label = UiStyle.label(20, UiStyle.CREAM)
	points_label.position = Vector2(200, 70)
	root.add_child(points_label)
	respec_label = UiStyle.label(20, UiStyle.PALE)
	respec_label.position = Vector2(460, 70)
	root.add_child(respec_label)
	slot_row = HBoxContainer.new()
	slot_row.position = Vector2(56, 104)
	slot_row.add_theme_constant_override("separation", 10)
	root.add_child(slot_row)
	list = VBoxContainer.new()
	list.position = Vector2(56, 176)
	list.add_theme_constant_override("separation", 6)
	root.add_child(list)
	tree_title = UiStyle.label(20, UiStyle.GOLD)
	tree_title.position = Vector2(500, 176)
	tree_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tree_title.custom_minimum_size = Vector2(720, 0)
	root.add_child(tree_title)
	tree_box = VBoxContainer.new()
	tree_box.position = Vector2(500, 262)   # under the skill's name and its two-line blurb
	tree_box.add_theme_constant_override("separation", 8)
	root.add_child(tree_box)
	# Review fix (M2): the pick buttons show only their titles; the focused pick's text is here, under the tree, so the
	# tree, its shut-tier reasons and the reset row fit inside the frame at every level.
	detail = UiStyle.label(20, UiStyle.CREAM)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.custom_minimum_size = Vector2(720, 0)
	detail.position = Vector2(500, 552)
	root.add_child(detail)
	info = UiStyle.label(20, UiStyle.CREAM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(720, 0)
	info.position = Vector2(500, 636)   # review fix: in the tree column, under the pick's text (it overlapped the list)
	root.add_child(info)
	hint = UiStyle.label(20, Color(0.43, 0.56, 0.7))
	hint.position = Vector2(56, 668)
	root.add_child(hint)

func is_open() -> bool:
	return root.visible

## Opens the pack on this tab. False (and nothing opens) while another menu is open.
func open() -> bool:
	if root.visible or Tuning.ui_open:
		return false
	if PackScreen.inst:
		return PackScreen.inst.open("skills")
	return open_page()

## The pack shows this tab: where the cursor starts (a skill on the bar; with points, the first open pick of a skill
## on the bar), the world pauses.
func open_page() -> bool:
	if root.visible:
		return true
	var main := get_tree().get_first_node_in_group("main")
	locked = main != null and Hunt.is_hunted(get_tree(), main.player.global_position)
	slot = "skill_3"
	placing = ""
	area = "list"
	list_i = 0
	tier_i = 0
	col_i = 0
	var start := suggested_skill()
	list_i = maxi(0, ORDER.find(start))
	if not locked and Progress.skill_points() > 0:
		var t := _first_open_tier(start)
		if t >= 0:
			area = "tree"
			tier_i = t
	root.visible = true
	Tuning.ui_open = true
	get_tree().paused = true
	info.text = HUNTED if locked else ""
	info.add_theme_color_override("font_color", UiStyle.WARN if locked else UiStyle.CREAM)
	_rebuild()
	Sfx.play_ui("ui_open", -14.0)
	return true

func close() -> void:
	close_page(false)

## keep: the pack moves to another tab (the world stays paused).
func close_page(keep: bool) -> void:
	if not root.visible:
		return
	root.visible = false
	get_viewport().gui_release_focus()
	if keep:
		return
	Tuning.ui_open = false
	get_tree().paused = false
	Progress.block_input()
	Sfx.play_ui("ui_close", -14.0)

## The skill the tab points at first: with points to spend, the first skill on the bar (or the dash) that has an open
## tier with no pick; else the first skill on the bar. Never a skill off the bar (owner note, 2026-11-28).
func suggested_skill() -> String:
	var on_bar := []
	for id in ORDER:
		if id == "dash" or Progress.slot_of(id) != "":
			on_bar.append(id)
	if Progress.skill_points() > 0:
		for id in on_bar:
			if _first_open_tier(id) >= 0:
				return id
	return on_bar[0] if not on_bar.is_empty() else "lampfire"

## The first tier of a skill that is open and has no pick yet, or -1.
func _first_open_tier(id: String) -> int:
	for t in 3:
		if Progress.tier_reason(id, t) == "" and Progress.pick_in(id, t) == "":
			return t
	return -1

func focused_skill() -> String:
	return ORDER[clampi(list_i, 0, ORDER.size() - 1)]

## The pick under the cursor, or "".
func focused_pick() -> String:
	if area != "tree" or tier_i > 2:
		return ""
	var ps := SkillTree.tier_picks(focused_skill(), tier_i)
	return ps[col_i] if col_i < ps.size() else ""

## Picks the slot being filled (tests, and left / right in place mode).
func choose_slot(s: String) -> void:
	if s in PICK_SLOTS:
		slot = s
		_rebuild()

## Puts skill `id` on the chosen slot (or takes it off if it is there already). Returns "" or why not.
func pick(id: String) -> String:
	if locked:
		_say(HUNTED, true)
		return HUNTED
	var s: Skill = _combat().skill(id) if _combat() else null
	var name_s := s.title() if s else id
	var why := ""
	if Progress.bar.get(slot, "") == id and slot != "skill_1":
		why = Progress.bind(slot, "")
		if why == "":
			_say(REMOVED % name_s)
	else:
		why = Progress.bind(slot, id)
		if why == "":
			_say(PLACED % [name_s, InputHint.key(slot)])
	if why != "":
		_say(why, true)
	_rebuild()
	return why

## Takes the pick (or at rest: swaps it in, or gives a taken one back). Returns "" or why not.
func choose_pick(id: String) -> String:
	if locked:
		_say(HUNTED, true)
		return HUNTED
	var why := ""
	var inf := SkillTree.info(id)
	if Progress.has_pick(id):
		if Progress.respec_open():
			why = Progress.unlearn(id)
			if why == "":
				_say("%s: given back." % inf.get("title", id))
		else:
			why = TAKEN % inf.get("title", id)
			_say(why)
			_rebuild()
			return why
	else:
		why = Progress.take_pick(id)
		if why == "":
			_say("%s: %s" % [inf.title, inf.body])
	if why != "":
		_say(why, true)
	_rebuild()
	return why

## Gives back every pick (only at rest).
func reset_all() -> String:
	var why := Progress.reset_picks()
	_say("Every pick is back as points." if why == "" else why, why != "")
	_rebuild()
	return why

func _say(text: String, warn: bool = false) -> void:
	info.text = text
	info.add_theme_color_override("font_color", UiStyle.WARN if warn else UiStyle.CREAM)
	if warn:
		Sfx.play_ui("ui_error", -14.0)
	else:
		Sfx.play_ui("ui_tick", -10.0)

func _combat() -> KeeperCombat:
	var p := get_tree().get_first_node_in_group("player")
	return p.combat if p else null

func _skill_title(id: String) -> String:
	var c := _combat()
	if c and c.skill(id):
		return c.skill(id).title()
	return SkillTree.skill_title(id)

# --- Drawing the tab ----------------------------------------------------------------------------------

func _chip_style(sel: bool, active: bool) -> StyleBoxFlat:
	return UiStyle.panel(UiStyle.AMBER if sel else Color(0.29, 0.42, 0.58, 0.6), Color(0.043, 0.055, 0.1, 0.95) if active else Color(0.03, 0.035, 0.06, 0.8), 3 if sel else 1, 8)

func _style_button(b: Button, sel: bool, taken: bool = false) -> void:
	var border := UiStyle.AMBER if sel else (UiStyle.GOLD if taken else Color(0.29, 0.42, 0.58, 0.6))
	var bg := Color(0.16, 0.1, 0.04, 0.95) if taken else Color(0.043, 0.055, 0.1, 0.95)
	var sb := UiStyle.panel(border, bg, 3 if sel else (2 if taken else 1), 8)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	b.add_theme_color_override("font_color", UiStyle.GOLD if taken else UiStyle.CREAM)
	b.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.58))
	b.focus_mode = Control.FOCUS_NONE

func _rebuild(_fresh: bool = false, _keep_focus: String = "") -> void:
	var combat := _combat()
	points_label.text = POINTS % Progress.skill_points()
	points_label.add_theme_color_override("font_color", UiStyle.GOLD if Progress.skill_points() > 0 else UiStyle.PALE)
	var rs := Progress.respec_open()
	respec_label.text = RESPEC_OPEN if rs else RESPEC_SHUT
	respec_label.add_theme_color_override("font_color", UiStyle.AMBER if rs else Color(0.43, 0.56, 0.7))
	# The bar's slots.
	for c in slot_row.get_children():
		slot_row.remove_child(c)
		c.queue_free()
	for s in Progress.SLOTS:
		var chip := PanelContainer.new()
		var sel: bool = area == "slots" and s == slot
		chip.add_theme_stylebox_override("panel", _chip_style(sel, area == "slots"))
		chip.custom_minimum_size = Vector2(200, 0)
		var v := VBoxContainer.new()
		chip.add_child(v)
		var key := UiStyle.label(20, UiStyle.GOLD if sel else UiStyle.PALE)
		key.text = InputHint.key(s)
		v.add_child(key)
		var id: String = Progress.bar.get(s, "")
		var nm := UiStyle.label(20, UiStyle.CREAM if id != "" else Color(0.43, 0.56, 0.7))
		nm.text = _skill_title(id) if id != "" else EMPTY
		v.add_child(nm)
		slot_row.add_child(chip)
	var dash_chip := PanelContainer.new()
	dash_chip.add_theme_stylebox_override("panel", _chip_style(false, false))
	dash_chip.custom_minimum_size = Vector2(160, 0)
	var dv := VBoxContainer.new()
	dash_chip.add_child(dv)
	var dk := UiStyle.label(20, UiStyle.PALE)
	dk.text = InputHint.key("dash")
	dv.add_child(dk)
	var dn := UiStyle.label(20, UiStyle.CREAM)
	dn.text = "Dash"
	dv.add_child(dn)
	slot_row.add_child(dash_chip)
	# The skills.
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	buttons.clear()
	for i in ORDER.size():
		var id: String = ORDER[i]
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 20)
		b.custom_minimum_size = Vector2(420, 66)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var on := "LT" if id == "dash" and InputHint.pad else ("dash" if id == "dash" else Progress.slot_of(id))
		var where := ""
		if id == "dash":
			where = "   [%s]" % InputHint.key("dash")
		elif on != "":
			where = "   [%s]" % InputHint.key(on)
		var opt := ("   (%s)" % OPTIONAL) if OPTIONAL_SKILLS.has(id) else ""
		var n := 0
		for t in 3:
			if Progress.pick_in(id, t) != "":
				n += 1
		var s: Skill = combat.skill(id) if combat else null
		if id != "dash" and not Progress.knows(id):
			b.text = NOT_YET % [_skill_title(id), Tuning.kl_lance_level] + opt
			b.disabled = true
		else:
			var facts := s.facts() if s else "%s s cooldown, %s charge" % [Skill.num(Tuning.kl_dash_cd), Skill.num(Tuning.kl_dash_cost)]
			b.text = "%s%s%s   %d/3\n%s" % [_skill_title(id), where, opt, n, facts]
		_style_button(b, area == "list" and i == list_i)
		b.pressed.connect(_click_skill.bind(i))
		list.add_child(b)
		buttons[id] = b
	# The focused skill's tree.
	var sid := focused_skill()
	var sk: Skill = combat.skill(sid) if combat else null
	tree_title.text = "%s%s\n%s" % [_skill_title(sid), ("   (%s: it has a tree only while it is kept)" % OPTIONAL) if OPTIONAL_SKILLS.has(sid) else "",
		sk.blurb() if sk else "A quick step. Nothing can chill you mid-dash."]
	for c in tree_box.get_children():
		tree_box.remove_child(c)
		c.queue_free()
	pick_buttons.clear()
	for t in 3:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var why := Progress.tier_reason(sid, t)
		var lab := UiStyle.label(20, UiStyle.PALE if why == "" else Color(0.43, 0.56, 0.7))
		lab.text = "Tier %d" % (t + 1)
		lab.custom_minimum_size = Vector2(70, 0)
		row.add_child(lab)
		var ps := SkillTree.tier_picks(sid, t)
		var taken := Progress.pick_in(sid, t)
		for ci in ps.size():
			var pid: String = ps[ci]
			var inf := SkillTree.info(pid)
			var pb := Button.new()
			pb.add_theme_font_size_override("font_size", 20)
			pb.custom_minimum_size = Vector2(212, 46)
			pb.alignment = HORIZONTAL_ALIGNMENT_LEFT
			pb.text = inf.title
			pb.tooltip_text = inf.body
			pb.disabled = why != "" or (taken != "" and taken != pid and not Progress.respec_open())
			_style_button(pb, area == "tree" and t == tier_i and ci == col_i, taken == pid)
			pb.pressed.connect(_click_pick.bind(t, ci))
			row.add_child(pb)
			pick_buttons[pid] = pb
		tree_box.add_child(row)
		if why != "":
			var wl := UiStyle.label(20, Color(0.43, 0.56, 0.7))
			wl.text = "        " + why
			tree_box.add_child(wl)
	reset_button = null
	if Progress.respec_open():
		reset_button = Button.new()
		reset_button.add_theme_font_size_override("font_size", 20)
		reset_button.custom_minimum_size = Vector2(420, 40)
		reset_button.text = RESET_ROW
		_style_button(reset_button, area == "tree" and tier_i == 3)
		reset_button.pressed.connect(func() -> void: reset_all())
		tree_box.add_child(reset_button)
	if area == "slots":
		hint.text = HINT_SLOTS_PAD if InputHint.pad else HINT_SLOTS_KEYS
	else:
		hint.text = HINT_PAD if InputHint.pad else HINT_KEYS
	detail.text = ""
	if area == "tree" and focused_pick() != "":
		var fi := SkillTree.info(focused_pick())
		var w2 := Progress.pick_reason(focused_pick())
		detail.text = "%s: %s" % [fi.title, fi.body]
		if Progress.has_pick(focused_pick()):
			detail.text += "\n(taken: A gives it back)" if Progress.respec_open() else "\n(taken)"
		elif w2 != "":
			detail.text += "\n" + w2
	elif area == "tree" and tier_i == 3:
		detail.text = RESET_ROW + "."
	elif area == "list":
		detail.text = "Right: its picks." if InputHint.pad else "Right / D: its picks."

# --- Moving the cursor --------------------------------------------------------------------------------

func _click_skill(i: int) -> void:
	list_i = i
	area = "list"
	activate()

func _click_pick(t: int, c: int) -> void:
	area = "tree"
	tier_i = t
	col_i = c
	activate()

## A / E on whatever the cursor is on.
func activate() -> void:
	match area:
		"list":
			var id := focused_skill()
			if id == "dash":
				_say(DASH_SLOT % InputHint.key("dash"))
				return
			if id == "lampfire":
				_say(LAMPFIRE_SLOT)
				return
			if not Progress.knows(id):
				_say(NOT_YET % [_skill_title(id), Tuning.kl_lance_level], true)
				return
			if locked:
				_say(HUNTED, true)
				return
			placing = id
			area = "slots"
			var on := Progress.slot_of(id)
			slot = on if on in PICK_SLOTS else "skill_3"
			info.text = CHOOSE_SLOT % _skill_title(id)
			info.add_theme_color_override("font_color", UiStyle.CREAM)
			Sfx.play_ui("ui_tick", -12.0)
			_rebuild()
		"slots":
			var id2 := placing
			placing = ""
			area = "list"
			pick(id2)
		"tree":
			if tier_i == 3:
				reset_all()
				tier_i = 0
				return
			var pid := focused_pick()
			if pid != "":
				choose_pick(pid)

## B: back out of choosing a slot, else close.
func back() -> void:
	if area == "slots":
		area = "list"
		placing = ""
		info.text = ""
		Sfx.play_ui("ui_tick", -16.0)
		_rebuild()
		return
	if PackScreen.inst and PackScreen.inst.tab == "skills":
		PackScreen.inst.close()
	else:
		close()

func move(d: Vector2i) -> void:
	info.text = ""
	match area:
		"list":
			if d.y != 0:
				list_i = clampi(list_i + d.y, 0, ORDER.size() - 1)
			elif d.x > 0:
				area = "tree"
				tier_i = clampi(tier_i, 0, 2)
				var t := _first_open_tier(focused_skill())
				tier_i = t if t >= 0 else 0
				col_i = 0
		"tree":
			var rows := 4 if Progress.respec_open() else 3
			if d.y != 0:
				tier_i = clampi(tier_i + d.y, 0, rows - 1)
				col_i = clampi(col_i, 0, maxi(0, SkillTree.tier_picks(focused_skill(), mini(tier_i, 2)).size() - 1))
			elif d.x < 0 and (col_i == 0 or tier_i == 3):
				area = "list"
			elif d.x != 0 and tier_i < 3:
				col_i = clampi(col_i + d.x, 0, SkillTree.tier_picks(focused_skill(), tier_i).size() - 1)
		"slots":
			if d.x != 0:
				var i := PICK_SLOTS.find(slot)
				slot = PICK_SLOTS[clampi(i + d.x, 0, PICK_SLOTS.size() - 1)]
	Sfx.play_ui("ui_tick", -18.0)
	_rebuild()

## Handled in _input so no other menu (or the world) sees these presses while the tab is open.
func _input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		back()
	elif event.is_action_pressed("skills") and event is InputEventKey:
		get_viewport().set_input_as_handled()
		if PackScreen.inst and PackScreen.inst.tab == "skills":
			PackScreen.inst.close()
		else:
			close()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		get_viewport().set_input_as_handled()
		move(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()
		move(Vector2i(1, 0))
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		move(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		move(Vector2i(0, 1))
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		activate()

func _unhandled_input(event: InputEvent) -> void:
	if root.visible or Tuning.ui_open:
		return
	if event.is_action_pressed("skills"):
		if open():
			get_viewport().set_input_as_handled()
