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
signal bar_changed
signal skill_learned(id: String)

const LANTERN_ORDER := ["post", "reservoir", "hooded", "mirror"]
## The action bar (M1a, GAME_PLAN §3): input action -> skill id ("" = empty). Slot 1 is always Lampfire.
const SLOTS := ["skill_1", "skill_2", "skill_3", "skill_4"]
## Skills in the Skills list, in order. Lance comes at Tuning.kl_lance_level; the rest from level 1.
const SKILL_ORDER := ["lampfire", "fireglobe", "lance", "beam", "hearth_ring"]
const SELF_CAST := ["hearth_ring"]

var upgrades := {}   # upgrade landmark id -> "carry" (keeper's satchel) or "lamp" (lamp glass), once taken
var unlocks := {"post": false}
var selected := "post"
var regions_seen := {}
var notes_read := {}
var settled := {}          # region id -> true once its WayLamp is lit ("held")
var wick := 0
var wick_frac := 0.0        # fractions of wick from reduced kills, carried until they make a whole one
var level := 1
var cleared := {}           # fixed prototype enemies and packs that stay beaten
var combat_upgrades: Array[String] = []
var pending_level_ups := 0
var bar := default_bar()    # the action bar: slot action -> skill id (saved, version 5)
var lance_given := false    # Lance has taken slot 3 once (at level 2); after that the bar is the player's
var last_displaced := ""    # what Lance pushed off slot 3 (the level-2 toast names it)
var _input_block_until := 0

func reset() -> void:
	upgrades = {}
	apply_upgrades()
	unlocks = {"post": false}
	selected = "post"
	regions_seen = {}
	notes_read = {}
	settled = {}
	wick = 0
	wick_frac = 0.0
	level = 1
	cleared = {}
	combat_upgrades = []
	pending_level_ups = 0
	bar = default_bar()
	lance_given = false
	last_displaced = ""

# --- The action bar (M1a) ------------------------------------------------------

## Level 1: RT Lampfire, RB Fireglobe, LB the Beam, Y empty (GAME_PLAN §4.1).
static func default_bar() -> Dictionary:
	return {"skill_1": "lampfire", "skill_2": "fireglobe", "skill_3": "beam", "skill_4": ""}

## Skills the keeper has now.
func knows(id: String) -> bool:
	if id == "lance":
		return lance_given or level >= Tuning.kl_lance_level
	return SKILL_ORDER.has(id)

## "" if `id` may go on `slot`, otherwise why not (shown in the Skills list). "" for id clears the slot.
func bind_reason(slot: String, id: String) -> String:
	if not SLOTS.has(slot):
		return "no such slot"
	if slot == "skill_1":
		return "" if id == "lampfire" else "Slot 1 is always Lampfire."
	if id == "":
		return ""
	if id == "lampfire":
		return "Lampfire stays on slot 1."
	if not knows(id):
		return "Not learned yet."
	if slot == "skill_4" and not SELF_CAST.has(id):
		return "This slot takes skills that need no aim."
	if slot != "skill_4" and SELF_CAST.has(id):
		return "This one needs no aim: it goes on slot 4."
	return ""

## Puts a skill on a slot (moving it off any other slot). Returns "" on success, else the reason.
func bind(slot: String, id: String) -> String:
	var why := bind_reason(slot, id)
	if why != "":
		return why
	for s in SLOTS:
		if s != slot and bar.get(s, "") == id and id != "":
			bar[s] = ""
	bar[slot] = id
	bar_changed.emit()
	return ""

## The slot a skill is on, or "".
func slot_of(id: String) -> String:
	for s in SLOTS:
		if bar.get(s, "") == id:
			return s
	return ""

## At level 2, Lance takes slot 3 (once); whatever was there goes back to the Skills list.
func _grant_level_skills() -> void:
	if not lance_given and level >= Tuning.kl_lance_level:
		lance_given = true
		for s in SLOTS:
			if bar.get(s, "") == "lance":
				bar[s] = ""
		last_displaced = bar.get("skill_3", "")
		bar["skill_3"] = "lance"
		bar_changed.emit()
		skill_learned.emit("lance")

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
		_grant_level_skills()
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

## The most lamp charge the keeper can hold: 1.0, +lamp_upgrade_charge per lamp glass (M1b, GAME_PLAN §5).
func charge_max() -> float:
	return 1.0 + Tuning.lamp_upgrade_charge * upgrade_level("lamp")

## The keeper's fire grows with their level: +kl_dmg_per_level a level over 1 (M1b, GAME_PLAN §4.6).
func dmg_mult() -> float:
	return 1.0 + Tuning.kl_dmg_per_level * float(level - 1)

func reveal_region(id: int, region_name: String) -> void:
	if regions_seen.has(id):
		return
	regions_seen[id] = true
	region_revealed.emit(region_name)

func block_input(ms: int = 200) -> void:
	_input_block_until = Time.get_ticks_msec() + ms

func input_blocked() -> bool:
	return Time.get_ticks_msec() < _input_block_until
