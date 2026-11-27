extends Node
## Autoload "Progress": unlocks, selected lantern, revealed regions, notes read, upgrades found.
## Also a tiny input guard so closing a menu doesn't trigger a game action.

signal region_revealed(region_name: String)
signal lantern_unlocked(kind: String)
signal note_opened(title: String, text: String)
signal landmark_spotted(title: String)

const LANTERN_ORDER := ["post", "reservoir", "hooded", "mirror"]

var upgrades := {}   # upgrade landmark id -> "carry" (keeper's satchel) or "lamp" (lamp glass), once taken
var unlocks := {"post": true}
var selected := "post"
var regions_seen := {}
var notes_read := {}
var _input_block_until := 0

func reset() -> void:
	upgrades = {}
	apply_upgrades()
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

# --- Upgrades ----------------------------------------------------------------

func upgrade_level(kind: String) -> int:
	var n := 0
	for k in upgrades.values():
		if k == kind:
			n += 1
	return n

## Takes an upgrade found in the world. False if it was already taken.
func take_upgrade(id: String, kind: String) -> bool:
	if upgrades.has(id):
		return false
	upgrades[id] = kind
	apply_upgrades()
	return true

## Puts the effect of every upgrade taken into play (after taking one, a new game or a load).
func apply_upgrades() -> void:
	Inventory.carry_limit = Tuning.carry_base + Tuning.carry_upgrade_step * upgrade_level("carry")

## The hand lamp, after any lamp glasses found.
func lamp_max_radius() -> float:
	return Tuning.hand_lamp_max_radius + Tuning.lamp_upgrade_radius * upgrade_level("lamp")

func lamp_drain_per_sec() -> float:
	return Tuning.hand_lamp_drain_per_sec * pow(Tuning.lamp_upgrade_dim_mult, upgrade_level("lamp"))

func ward_drain_per_sec() -> float:
	return Tuning.ward_drain_per_sec * pow(Tuning.lamp_upgrade_ward_mult, upgrade_level("lamp"))

func reveal_region(id: int, region_name: String) -> void:
	if regions_seen.has(id):
		return
	regions_seen[id] = true
	region_revealed.emit(region_name)

func block_input(ms: int = 200) -> void:
	_input_block_until = Time.get_ticks_msec() + ms

func input_blocked() -> bool:
	return Time.get_ticks_msec() < _input_block_until
