extends Node
## Autoload "Progress": unlocks, selected lantern, revealed regions, notes read.
## Also a tiny input guard so closing a menu doesn't trigger a game action.

signal region_revealed(region_name: String)
signal lantern_unlocked(kind: String)
signal note_opened(title: String, text: String)
signal landmark_spotted(title: String)

const LANTERN_ORDER := ["post", "reservoir", "hooded", "mirror"]

var unlocks := {"post": true}
var selected := "post"
var regions_seen := {}
var notes_read := {}
var _input_block_until := 0

func reset() -> void:
	unlocks = {"post": true}
	selected = "post"
	regions_seen = {}
	notes_read = {}

func is_unlocked(kind: String) -> bool:
	return unlocks.get(kind, false)

func unlock(kind: String) -> void:
	if is_unlocked(kind):
		return
	unlocks[kind] = true
	lantern_unlocked.emit(kind)

func reveal_region(id: int, region_name: String) -> void:
	if regions_seen.has(id):
		return
	regions_seen[id] = true
	region_revealed.emit(region_name)

func block_input(ms: int = 200) -> void:
	_input_block_until = Time.get_ticks_msec() + ms

func input_blocked() -> bool:
	return Time.get_ticks_msec() < _input_block_until
