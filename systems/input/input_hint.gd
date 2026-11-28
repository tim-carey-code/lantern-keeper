extends Node
## Autoload "InputHint": remembers whether the player is on a controller or keyboard/mouse,
## so prompts and the action bar show the right button ("A" vs "E", "RT" vs "LMB").
## The map itself is tools/setup_input.gd (GAME_PLAN §3).

signal device_changed(pad: bool)

var pad := false

const PAD := {"interact": "A", "place_lantern": "X", "cancel": "B", "flask": "B", "dash": "LT", "build_menu": "D-pad right",
	"lamp_prev": "D-pad left", "map": "D-pad up", "skills": "D-pad down", "journal": "View", "pause": "Start", "debug_toggle": "L3",
	"skill_1": "RT", "skill_2": "RB", "skill_3": "LB", "skill_4": "Y", "lock_on": "R3"}
const KEYS := {"interact": "E", "place_lantern": "C", "cancel": "Esc", "flask": "R", "dash": "Space", "build_menu": "Tab",
	"lamp_prev": "Tab", "map": "M", "skills": "K", "journal": "J", "pause": "Esc", "debug_toggle": "F1",
	"skill_1": "Left click", "skill_2": "Right click", "skill_3": "Q", "skill_4": "F", "lock_on": "Middle mouse"}
## Short labels for the action bar's key caps (Ark Pixel at 20 px; they must fit a 48 px slot).
const PAD_SHORT := {"skill_1": "RT", "skill_2": "RB", "skill_3": "LB", "skill_4": "Y", "dash": "LT", "flask": "B"}
const KEYS_SHORT := {"skill_1": "LMB", "skill_2": "RMB", "skill_3": "Q", "skill_4": "F", "dash": "Spc", "flask": "R"}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	var now := pad
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		now = true
	elif event is InputEventKey or event is InputEventMouseButton:
		now = false
	if now != pad:
		pad = now
		device_changed.emit(pad)

## The button for an action on the current device, e.g. key("interact") -> "A" or "E".
func key(action: String) -> String:
	if action == "lock_on" and pad:
		return Settings.lock_button_label()   # M1c: the lock button is an option (R3, Y or L3)
	if action == "skill_4" and pad:
		return Settings.slot4_label()        # with the lock on Y, slot 4 is on R3
	return (PAD if pad else KEYS).get(action, "?")

## The short key-cap label for an action bar slot, e.g. short("skill_1") -> "RT" or "LMB".
func short(action: String) -> String:
	if action == "skill_4" and pad:
		return Settings.slot4_label()
	return (PAD_SHORT if pad else KEYS_SHORT).get(action, key(action))

## Full controls list for the pause menu.
func controls_text() -> String:
	var rows := [["Move", "Left stick" if pad else "WASD / arrows"],
		["Lampfire (hold, aim with the %s)" % ("right stick" if pad else "mouse"), key("skill_1")],
		["Skill slots 2, 3, 4", "%s, %s, %s" % [key("skill_2"), key("skill_3"), key("skill_4")]],
		["Dash", key("dash") + ("" if pad else " / Shift")], ["Drink lamp oil", key("flask")],
		["Lock onto a foe (again: let go)", key("lock_on")],   # DRAFT (M1c)
		["Use: read, light, take, rest, travel", key("interact")], ["Pick up a lamp (hold)", key("interact")],   # DRAFT (M1b)
		["Plant the selected lamp", key("place_lantern")], ["Next lamp kind (hold: the list)", key("build_menu")],
		["Skills", key("skills")], ["Map", key("map")], ["Journal", key("journal")], ["Pause", key("pause")]]
	var lines: Array[String] = []
	for r in rows:
		lines.append("%-34s %s" % [r[0], r[1]])
	return "\n".join(lines)
