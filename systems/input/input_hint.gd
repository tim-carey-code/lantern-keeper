extends Node
## Autoload "InputHint": remembers whether the player is on a controller or keyboard/mouse,
## so prompts show the right button ("A" vs "E").

signal device_changed(pad: bool)

var pad := false

const PAD := {"interact": "A", "place_lantern": "X", "cancel": "B", "flare": "RB", "build_menu": "Y",
	"map": "LB", "journal": "View", "pause": "Start", "debug_toggle": "L3"}
const KEYS := {"interact": "E", "place_lantern": "Space", "cancel": "Q", "flare": "F", "build_menu": "Tab",
	"map": "M", "journal": "J", "pause": "Esc", "debug_toggle": "F1"}

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
	return (PAD if pad else KEYS).get(action, "?")

## Full controls list for the pause menu.
func controls_text() -> String:
	var rows := [["Move", "Left stick / D-pad" if pad else "WASD / arrows"], ["Use: read, refuel, turn, gather (hold)", key("interact")],
		["Build selected lantern", key("place_lantern")], ["Pick up lantern", key("cancel")], ["Ward (hold)", key("flare") + (" / RT" if pad else "")],
		["Lantern list", key("build_menu")], ["Map", key("map")], ["Journal", key("journal")], ["Pause", key("pause")]]
	var lines: Array[String] = []
	for r in rows:
		lines.append("%-40s %s" % [r[0], r[1]])
	return "\n".join(lines)
