extends Node
## Autoload "Progress": unlocks, selected lantern, revealed regions, notes read, upgrades found.
## Also a tiny input guard so closing a menu doesn't trigger a game action.

signal region_revealed(region_name: String)
signal lantern_unlocked(kind: String)
signal note_opened(title: String, text: String)
signal landmark_spotted(title: String)
signal region_settled(region_id: int, region_name: String)
signal wick_changed(current: int, needed: int, level: int)
signal level_up(level: int)

const LANTERN_ORDER := ["post", "reservoir", "hooded", "mirror"]

var upgrades := {}   # upgrade landmark id -> "carry" (keeper's satchel) or "lamp" (lamp glass), once taken
var unlocks := {"post": false}
var selected := "post"
var regions_seen := {}
var notes_read := {}
var settled := {}          # region id -> true once its WayLamp is lit ("held")
var waylamp_fuel := {}     # WayLamp id -> carried fuel fed into it so far
var wick := 0
var wick_frac := 0.0        # fractions of wick from reduced kills, carried until they make a whole one
var level := 1
var cleared := {}           # fixed prototype enemies and packs that stay beaten
var combat_upgrades: Array[String] = []
var pending_level_ups := 0
var _input_block_until := 0

func reset() -> void:
	upgrades = {}
	apply_upgrades()
	unlocks = {"post": false}
	selected = "post"
	regions_seen = {}
	notes_read = {}
	settled = {}
	waylamp_fuel = {}
	wick = 0
	wick_frac = 0.0
	level = 1
	cleared = {}
	combat_upgrades = []
	pending_level_ups = 0

## Wick to go from level `lv` to the next: a rising curve, kl_wick_base * lv ^ kl_wick_exp (DESIGN §9).
func wick_for_level(lv: int) -> int:
	return maxi(1, roundi(Tuning.kl_wick_base * pow(float(lv), Tuning.kl_wick_exp)))

func wick_needed() -> int:
	return wick_for_level(level)

func at_level_cap() -> bool:
	return level >= Tuning.kl_level_cap

## The level-gap factor (DESIGN §9): 1 within kl_xp_band levels above the foe, then x kl_xp_falloff per level,
## 0 at kl_xp_zero_gap or more; a small bonus for foes above the keeper.
func wick_gap_mult(foe_level: int, keeper_level: int = -1) -> float:
	var gap := (level if keeper_level < 0 else keeper_level) - foe_level
	if gap < 0:
		return 1.0 + minf(Tuning.kl_xp_bonus_max, Tuning.kl_xp_bonus * -gap)
	if gap <= Tuning.kl_xp_band:
		return 1.0
	if gap >= Tuning.kl_xp_zero_gap:
		return 0.0
	return pow(Tuning.kl_xp_falloff, gap - Tuning.kl_xp_band)

## Wick a kill pays: its base wick, grown by its level, times the level-gap factor.
func kill_wick(base: int, foe_level: int, keeper_level: int = -1) -> float:
	var grown := float(base) * (1.0 + Tuning.kl_xp_level_growth * float(maxi(1, foe_level) - 1))
	return grown * wick_gap_mult(foe_level, keeper_level)

## Adds a kill's (maybe fractional) wick; fractions carry over until they make a whole one.
func add_wick_f(amount: float) -> void:
	if amount <= 0.0 or at_level_cap():
		return
	wick_frac += amount
	var whole := floori(wick_frac + 0.0001)
	wick_frac = maxf(0.0, wick_frac - whole)
	if whole > 0:
		add_wick(whole)

func add_wick(amount: int) -> void:
	if amount <= 0 or at_level_cap():
		return
	wick += amount
	while not at_level_cap() and wick >= wick_needed():
		wick -= wick_needed()
		level += 1
		pending_level_ups += 1
		level_up.emit(level)
	if at_level_cap():
		wick = 0
	wick_changed.emit(wick, wick_needed(), level)

func choose_combat_upgrade(id: String) -> void:
	if id != "" and not combat_upgrades.has(id):
		combat_upgrades.append(id)
	pending_level_ups = maxi(0, pending_level_ups - 1)

func has_combat_upgrade(id: String) -> bool:
	return combat_upgrades.has(id)

func is_unlocked(kind: String) -> bool:
	return unlocks.get(kind, false)

func unlock(kind: String) -> void:
	if is_unlocked(kind):
		return
	unlocks[kind] = true
	lantern_unlocked.emit(kind)

func is_settled(region_id: int) -> bool:
	return settled.has(region_id)

## A WayLamp caught: the region is held from now on.
func settle(region_id: int, region_name: String) -> void:
	if settled.has(region_id):
		return
	settled[region_id] = true
	add_wick(Tuning.kl_wick_kindle)
	region_settled.emit(region_id, region_name)

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
