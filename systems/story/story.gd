extends Node
## Autoload "Story": the keeper's name, the goals that guide the player, the journal
## ("story so far"), one-time tips, and the goal pointer setting. Text comes from
## docs/STORY.md (owner-reviewed). Goals complete from what happens in the world,
## checked a few times a second; if one is done early, the next unfinished one shows.

signal goal_completed(id: String, text: String)
signal goal_changed(id: String, text: String)
signal entry_added(title: String)
signal tip_shown(text: String)

const GOALS := [
	{"id": "gather_fuel", "text": "Take fuel from the woodpile", "target": "woodpile"},
	{"id": "relight_first", "text": "Relight the old lantern by the hut", "target": "start_lantern", "entry": 1},
	{"id": "read_ledger", "text": "Read the ledger by the hut", "target": "ledger", "entry": 2},
	{"id": "build_post", "text": "Build a Post Lamp at the edge of the light", "target": "passage"},
	{"id": "stone_way", "text": "Light the way east to the carved stone", "target": "stone_way"},
	{"id": "enter_marsh", "text": "Follow the arrow into the marsh", "target": "marsh_entry"},
	{"id": "frames_east", "text": "Find the old frames on the boardwalk", "target": "frames_east", "entry": 3},
	{"id": "chalk_lake", "text": "Look at the chalk on the pumphouse", "target": "chalk_lake"},
	{"id": "pumphouse", "text": "Wake the old pump", "target": "pumphouse", "entry": 4},
	{"id": "build_reservoir", "text": "Build a Reservoir Lamp", "target": ""},
	{"id": "climb_north", "text": "Climb north from the top of the Hollow", "target": "climb_cairn", "entry": 5},
	{"id": "glazier", "text": "Find the glazier's workshop", "target": "glazier", "entry": 6},
	{"id": "build_hooded", "text": "Build a Hooded Lamp in the wind", "target": ""},
	{"id": "lens", "text": "Look for the great lens", "target": "lens"},
	{"id": "coat", "text": "Follow the ridge east", "target": "coat", "entry": 7},
	{"id": "station", "text": "Reach the signal station", "target": "station", "entry": 8},
	{"id": "build_mirror", "text": "Light a Mirror Post from a lantern", "target": ""},
	{"id": "descend", "text": "Take the old steps down to the lake", "target": "ridge_steps"},
]

const ENTRIES := {
	1: ["Arrival", "I came because of the letter. The old lantern took the flame on the first try. One hook on the rack is empty."],
	2: ["The ledger", "The keepers counted every lamp they lit. At the end, one mark a night. O. went east."],
	3: ["The marsh", "The frames all face east, toward a lake I cannot see."],
	4: ["The pumphouse", "The chalk shows the lake, bright, then dark. Something coiled around its light. The pump still works."],
	5: ["The climb", "O. sent me up. The wind pulls at every flame."],
	6: ["The workshop", "O. could not stay to finish the hood. I did."],
	7: ["The coat", "O.'s coat, caught in the rocks. Something came up out of the water and drank the great lamp. I hope O. found somewhere warm."],
	8: ["The station", "O. turned the last mirror toward the lake. That is where O. went."],
}

const TITLE_CARD := ["The valley had keepers once.", "Then the lamps went out, one by one.", "Now there is a letter, and you."]
const LETTER := "To whoever reads this,\n\nThe lamps in the valley are going out. I cannot keep them alone any more.\n\nThere is a hut at the bottom of the Hollow, with an old lantern by the door. Light that first. Then follow my marks. I left them where the light will find them.\n\nStay in the light. The dark is not empty.\n\nIf you came, thank you.\n\n- O., the last keeper"

const TIPS := {
	"cold_lantern": "A cold lantern keeps its frame. A little fuel will wake it.",
	"low_lantern": "Lanterns burn down. Top them up before they go cold.",
	"fog_edge": "Fog comes back where light fades. Light holds the ground.",
	"gust": "Wind is coming. Rock on the windward side shelters a flame.",
	"wickling_seen": "Something small moves in the dark. It is drawn to your lights.",
	"wickling_close": "Hold F / RB / RT to swell your lamp. Wicklings cannot bear it.",
	"lamp_empty": "Your lamp is down to an ember. Rest in a lantern's light to fill it.",
	"warmth_low": "You are getting cold. Stand in a lantern's light.",
	"faint": "You woke by the nearest light. What you dropped waits where you fell.",
	"glass": "Glass. The keepers on the ridge made lamps from it.",
	"mirror_placed": "A mirror needs light. Stand it inside a burning lantern's glow.",
	"mirror_lit": "Interact to turn the beam. Beams pass from mirror to mirror.",
}

var player_name := ""
var done := {}               # goal id -> true
var current := ""            # id of the goal on the HUD ("" = all done for now)
var entries: Array = []      # entry numbers written, in order
var tips_seen := {}
var pointer_mode := "auto"   # auto (on until the Reedmarsh), on, off
var visited := {}            # region id -> true (where the keeper has actually walked)
var built := {}              # lantern kind -> count built by the player
var skip_opening := false    # tests and captures set this
var play_time := 0.0
var _t := 0.0

func reset() -> void:
	player_name = ""
	done = {}
	current = ""
	entries = []
	tips_seen = {}
	pointer_mode = "auto"
	visited = {}
	built = {}
	play_time = 0.0

func display_name() -> String:
	return player_name if player_name != "" else "Keeper"

func goal_text(id: String) -> String:
	for g in GOALS:
		if g["id"] == id:
			return g["text"]
	return ""

func goal_target(id: String) -> String:
	for g in GOALS:
		if g["id"] == id:
			return g["target"]
	return ""

func pointer_on() -> bool:
	match pointer_mode:
		"on":
			return true
		"off":
			return false
	return not visited.has(FogGrid.R_MARSH)   # auto: on in the Hollow, off once you reach the marsh

func note_built(kind: String) -> void:
	built[kind] = int(built.get(kind, 0)) + 1

func tip(id: String) -> void:
	if tips_seen.has(id) or not TIPS.has(id):
		return
	tips_seen[id] = true
	tip_shown.emit(TIPS[id])

func add_entry(n: int) -> void:
	if entries.has(n) or not ENTRIES.has(n):
		return
	entries.append(n)
	entry_added.emit(ENTRIES[n][0])

# --- Checking the world --------------------------------------------------------

func _process(delta: float) -> void:
	var main := get_tree().get_first_node_in_group("main")
	if main == null or get_tree().paused:
		return
	play_time += delta
	_t -= delta
	if _t > 0.0:
		return
	_t = 0.25
	update(main)

## Re-checks goals, tips and where the keeper is. Public so tests can call it.
func update(main: Node) -> void:
	var fog: FogGrid = main.fog
	var r := fog.region_at(main.player.global_position)
	if r > 0:
		visited[r] = true
	for g in GOALS:
		var id: String = g["id"]
		if not done.has(id) and _is_done(id, main):
			done[id] = true
			goal_completed.emit(id, g["text"])
			if g.has("entry"):
				add_entry(int(g["entry"]))
	var next := ""
	for g in GOALS:
		if not done.has(g["id"]):
			next = g["id"]
			break
	if next != current:
		current = next
		goal_changed.emit(current, goal_text(current))
	_check_tips(main)

func _lanterns(main: Node) -> Array:
	return main.get_tree().get_nodes_in_group("lantern")

func _is_done(id: String, main: Node) -> bool:
	var read := Progress.notes_read
	match id:
		"gather_fuel":
			return Inventory.get_count("fuel") >= 1 or done.has("relight_first")
		"relight_first":
			for l in _lanterns(main):
				if l.global_position.distance_to(main.start_lantern_pos) < 8.0 and l.is_lit():
					return true
			return false
		"read_ledger":
			return read.has("ledger")
		"stone_way", "frames_east", "pumphouse", "glazier", "lens", "coat", "station":
			return read.has(id)
		"chalk_lake":
			return read.has("chalk_lake") or read.has("pumphouse")
		"build_post":
			return int(built.get("post", 0)) > 0
		"enter_marsh":
			return visited.has(FogGrid.R_MARSH)
		"build_reservoir":
			return int(built.get("reservoir", 0)) > 0
		"climb_north":
			return visited.has(FogGrid.R_RIDGE)
		"build_hooded":
			return int(built.get("hooded", 0)) > 0
		"build_mirror":
			for l in _lanterns(main):
				if l.kind == "mirror" and l.is_lit():
					return true
			return false
		"descend":
			return visited.has(4)   # the Still Lake (not built yet)
	return false

func _check_tips(main: Node) -> void:
	var player = main.player
	for l in _lanterns(main):
		if l.needs_fuel() and not l.is_lit():
			tip("cold_lantern")
		elif l.needs_fuel() and l.fuel_frac() < 0.25:
			tip("low_lantern")
		if l.kind == "mirror":
			tip("mirror_placed")
			if l.is_lit():
				tip("mirror_lit")
	if play_time > 90.0:
		tip("fog_edge")
	var wind := main.get_tree().get_first_node_in_group("wind") as Wind
	if wind and wind.state == Wind.State.WARNING:
		tip("gust")
	for w in main.get_tree().get_nodes_in_group("wickling"):
		var d: float = w.global_position.distance_to(player.global_position)
		if d < 420.0:
			tip("wickling_seen")
		if d < 130.0:
			tip("wickling_close")
	if player.lamp_charge <= Tuning.ward_min_charge:
		tip("lamp_empty")
	if player.warmth < Tuning.warmth_max * 0.35:
		tip("warmth_low")
	if player.faints > 0:
		tip("faint")
	if Inventory.get_count("glass") > 0:
		tip("glass")

# --- Save ------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"name": player_name, "done": done.keys(), "entries": entries, "tips": tips_seen.keys(),
		"pointer": pointer_mode, "visited": visited.keys(), "built": built, "time": play_time}

func from_dict(d: Dictionary) -> void:
	reset()
	player_name = str(d.get("name", ""))
	for k in d.get("done", []):
		done[str(k)] = true
	for n in d.get("entries", []):
		entries.append(int(n))
	for k in d.get("tips", []):
		tips_seen[str(k)] = true
	pointer_mode = str(d.get("pointer", "auto"))
	for k in d.get("visited", []):
		visited[int(k)] = true
	var b: Dictionary = d.get("built", {})
	for k in b:
		built[str(k)] = int(b[k])
	play_time = float(d.get("time", 0.0))
	current = ""
