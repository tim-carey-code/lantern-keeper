class_name PackScreen
extends CanvasLayer
## The keeper's pack (M2, GAME_PLAN §3, §14): one screen with tabs, Skills, Journal and Map (Gear comes with M3).
## View (pad) or I opens it on Skills; K, J and M (and D-pad down / D-pad up from the world) open it on that tab.
## Inside: LB / RB (Q / Tab) change tabs; on a keyboard K, J and M jump to their tab, and the open tab's own key
## closes it; B / Esc / Start / View closes. The D-pad never changes tabs (it moves inside a tab).
## Each tab is still its own node (SkillsList, Journal, MapScreen: tests and captures open them by name); this node
## draws the tab strip over whichever is open and moves between them without unpausing the world.
## Titles and hints are DRAFT (STORY §17).

const TABS := ["skills", "journal", "map"]
const TITLES := {"skills": "Skills", "journal": "Journal", "map": "Map"}
const NODES := {"skills": "SkillsList", "journal": "Journal", "map": "MapScreen"}
const KEY_ACTIONS := {"skills": "skills", "journal": "journal", "map": "map"}

static var inst: PackScreen

var tab := ""                    # the open tab, or ""
var switches := 0                # tab changes (tests)
var _strip: HBoxContainer
var _hint: Label
var _bar: Control
var _switching := false

func _enter_tree() -> void:
	inst = self

func _exit_tree() -> void:
	if inst == self:
		inst = null

func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pack_screen")
	_bar = Control.new()
	_bar.size = Vector2(1280, 52)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.visible = false
	add_child(_bar)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.045, 0.98)
	bg.size = Vector2(1280, 50)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.add_child(bg)
	var title := UiStyle.label(30, UiStyle.GOLD)
	title.text = "The keeper's pack"
	title.position = Vector2(40, 6)
	_bar.add_child(title)
	_strip = HBoxContainer.new()
	_strip.position = Vector2(420, 8)
	_strip.add_theme_constant_override("separation", 10)
	_bar.add_child(_strip)
	_hint = UiStyle.label(20, Color(0.43, 0.56, 0.7))
	_hint.position = Vector2(900, 14)
	_bar.add_child(_hint)

func page(t: String) -> Node:
	var main := get_tree().get_first_node_in_group("main")
	if main == null or not NODES.has(t):
		return null
	return main.get_node_or_null(NODES[t])

func is_open() -> bool:
	if tab == "":
		return false
	var p := page(tab)
	return p != null and p.is_open()

## Opens the pack on a tab (or moves to it if the pack is open). False if another menu is open.
func open(t: String = "skills") -> bool:
	if not NODES.has(t):
		return false
	if is_open():
		return switch_to(t)
	if Tuning.ui_open:
		return false
	var p := page(t)
	if p == null or not p.open_page():
		return false
	tab = t
	_refresh()
	return true

## Moves to another tab without unpausing the world.
func switch_to(t: String) -> bool:
	if not is_open() or not NODES.has(t):
		return false
	if t == tab:
		return true
	var from := page(tab)
	var to := page(t)
	if to == null:
		return false
	_switching = true
	from.close_page(true)
	Tuning.ui_open = false
	to.open_page()
	_switching = false
	tab = t
	switches += 1
	Sfx.play_ui("ui_tick", -14.0)
	_refresh()
	return true

func step(d: int) -> void:
	var i := TABS.find(tab)
	switch_to(TABS[(i + d + TABS.size()) % TABS.size()])

func close() -> void:
	if is_open():
		page(tab).close_page(false)
	tab = ""
	_refresh()

func switching() -> bool:
	return _switching

func _process(_delta: float) -> void:
	if tab != "" and not is_open():
		tab = ""   # the tab closed itself (B, Esc)
	if _bar.visible != (tab != ""):
		_refresh()

func _refresh() -> void:
	_bar.visible = tab != ""
	if not _bar.visible:
		return
	for c in _strip.get_children():
		_strip.remove_child(c)
		c.queue_free()
	for t in TABS:
		var chip := PanelContainer.new()
		var on: bool = t == tab
		chip.add_theme_stylebox_override("panel", UiStyle.panel(UiStyle.AMBER if on else Color(0.29, 0.42, 0.58, 0.5), Color(0.043, 0.055, 0.1, 0.95), 2 if on else 1, 8))
		var l := UiStyle.label(20, UiStyle.GOLD if on else UiStyle.PALE)
		var mark := ""
		if t == "skills" and Progress.skill_points() > 0:
			mark = "  +%d" % Progress.skill_points()
		l.text = TITLES[t] + mark
		chip.add_child(l)
		_strip.add_child(chip)
	_hint.text = "LB / RB: tab" if InputHint.pad else "Q / Tab: tab"

## Handled first (layer 11, _input) so the D-pad and the tab keys never reach the tabs underneath.
func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed("pack_prev"):
		get_viewport().set_input_as_handled()
		step(-1)
	elif event.is_action_pressed("pack_next"):
		get_viewport().set_input_as_handled()
		step(1)
	elif event.is_action_pressed("pack"):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey:
		# K, J, M jump to their tab (the open tab's own key is left to it: it closes).
		for t in TABS:
			if t != tab and event.is_action_pressed(KEY_ACTIONS[t]):
				get_viewport().set_input_as_handled()
				switch_to(t)
				return

func _unhandled_input(event: InputEvent) -> void:
	if is_open() or Tuning.ui_open:
		return
	if event.is_action_pressed("pack"):
		if open("skills"):
			get_viewport().set_input_as_handled()
