extends Node
## Autoload "Settings": player options that belong to the PC, not to a save slot (GAME_PLAN §14, brief §4):
## the screen-shake slider, "reduce flashes" and the optional Lampfire auto-fire on the right stick.
## Stored in user://settings.cfg. Only the pause menu calls save(). Tests, captures and the bench (any scene run
## from res://tools/) never read or write that file: the defaults are used, and save() only writes when a test has
## pointed `path` at its own file. Tests also call use_defaults() themselves.

const PATH := "user://settings.cfg"

var shake := 1.0              # 0..1: screen shake strength
var reduce_flashes := false   # dims hit flashes, impact flashes and screen flashes
var autofire := false         # pad: Lampfire fires while the right stick is pushed past Tuning.kl_autofire_stick
# M1c target lock options (PLAN_LANTERNS §6.8).
const LOCK_MODES := ["toggle", "auto", "off"]
## The lock button choices. A standard Xbox pad has no back paddles, so that choice (PLAN_LANTERNS §6.8) is left out
## (M1c review). With the lock on Y, slot 4 moves to R3; with it on L3, the dev tuning panel keeps only F1.
const LOCK_BUTTONS := ["r3", "y", "l3"]
const LOCK_BUTTON_LABELS := {"r3": "R3", "y": "Y", "l3": "L3"}
const LOCK_BUTTON_JOY := {"r3": JOY_BUTTON_RIGHT_STICK, "y": JOY_BUTTON_Y, "l3": JOY_BUTTON_LEFT_STICK}
const AIM_ASSISTS := [12.0, 20.0, 0.0]
var lock_mode := "toggle"     # toggle (the lock button) | auto (picks the nearest hunting foe when you have none) | off
var lock_chain := true        # the lock moves to the next foe when its target dies
var lock_button := "r3"       # which pad button locks (R3, Y or L3)
var lock_large := false       # the lock marker drawn 1.5x, 3 px
var sticky_click := true      # K&M: a click on a foe follows it while held (off with the lock set to Off too)
var aim_assist := 12.0        # pad aim assist in degrees (12, 20 or 0 = off); sets Tuning.kl_aim_assist_deg
var path := PATH              # tests point this elsewhere

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if tool_run():
		use_defaults()
		return
	load_from(path)

## True when the scene being run is a test, capture or bench (res://tools/...), not the game.
static func tool_run() -> bool:
	for a in OS.get_cmdline_args():
		if a.begins_with("res://tools/"):
			return true
	return false

func use_defaults() -> void:
	shake = 1.0
	reduce_flashes = false
	autofire = false
	lock_mode = "toggle"
	lock_chain = true
	lock_button = "r3"
	lock_large = false
	sticky_click = true
	aim_assist = 12.0
	apply_controls()

func load_from(p: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(p) != OK:
		return
	shake = clampf(float(cfg.get_value("feel", "shake", 1.0)), 0.0, 1.0)
	reduce_flashes = bool(cfg.get_value("feel", "reduce_flashes", false))
	autofire = bool(cfg.get_value("controls", "autofire", false))
	lock_mode = str(cfg.get_value("controls", "lock_mode", "toggle"))
	if not LOCK_MODES.has(lock_mode):
		lock_mode = "toggle"
	lock_chain = bool(cfg.get_value("controls", "lock_chain", true))
	lock_button = str(cfg.get_value("controls", "lock_button", "r3"))
	if not LOCK_BUTTONS.has(lock_button):
		lock_button = "r3"
	lock_large = bool(cfg.get_value("controls", "lock_large", false))
	sticky_click = bool(cfg.get_value("controls", "sticky_click", true))
	aim_assist = float(cfg.get_value("controls", "aim_assist", 12.0))
	if not AIM_ASSISTS.has(aim_assist):
		aim_assist = 12.0
	apply_controls()

func save() -> bool:
	if path == PATH and tool_run():
		return false   # a test or capture must never write the owner's settings
	var cfg := ConfigFile.new()
	cfg.set_value("feel", "shake", shake)
	cfg.set_value("feel", "reduce_flashes", reduce_flashes)
	cfg.set_value("controls", "autofire", autofire)
	cfg.set_value("controls", "lock_mode", lock_mode)
	cfg.set_value("controls", "lock_chain", lock_chain)
	cfg.set_value("controls", "lock_button", lock_button)
	cfg.set_value("controls", "lock_large", lock_large)
	cfg.set_value("controls", "sticky_click", sticky_click)
	cfg.set_value("controls", "aim_assist", aim_assist)
	return cfg.save(path) == OK

func lock_button_label() -> String:
	return LOCK_BUTTON_LABELS.get(lock_button, "R3")

## Puts the control options into play: the aim assist (Tuning.kl_aim_assist_deg) and the lock button. The pad
## button chosen for the lock is taken off whatever else used it (Y: slot 4; L3: the dev tuning panel), and given
## back when the lock moves elsewhere. Middle mouse always locks.
func apply_controls() -> void:
	Tuning.kl_aim_assist_deg = aim_assist
	if not InputMap.has_action("lock_on"):
		return
	for e in InputMap.action_get_events("lock_on"):
		if e is InputEventJoypadButton:
			InputMap.action_erase_event("lock_on", e)
	var btn: int = LOCK_BUTTON_JOY.get(lock_button, JOY_BUTTON_RIGHT_STICK)
	_pad_button("lock_on", btn, true)
	# Slot 4: Y, or R3 while the lock has Y (the two swap).
	_pad_button("skill_4", JOY_BUTTON_Y, btn != JOY_BUTTON_Y)
	_pad_button("skill_4", JOY_BUTTON_RIGHT_STICK, btn == JOY_BUTTON_Y)
	_pad_button("debug_toggle", JOY_BUTTON_LEFT_STICK, btn != JOY_BUTTON_LEFT_STICK)

## Gives an action a pad button, or takes it away.
static func _pad_button(action: String, button: int, on: bool) -> void:
	if not InputMap.has_action(action):
		return
	var has := false
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and e.button_index == button:
			has = true
			if not on:
				InputMap.action_erase_event(action, e)
	if on and not has:
		var ev := InputEventJoypadButton.new()
		ev.button_index = button
		InputMap.action_add_event(action, ev)

## The pad label of slot 4 (Y, or R3 while the lock has Y).
func slot4_label() -> String:
	return "R3" if lock_button == "y" else "Y"

## Next value in a list (the pause menu's option buttons cycle).
static func next_in(list: Array, v: Variant) -> Variant:
	var i := list.find(v)
	return list[(i + 1) % list.size()]

## How strong a flash is drawn: 1 normally, much less with "reduce flashes".
func flash_mult() -> float:
	return 0.3 if reduce_flashes else 1.0
