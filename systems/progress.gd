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
signal picks_changed

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
## M2 (GAME_PLAN §4.2): the branch picks. skill id -> [tier 1, tier 2, tier 3] pick ids ("" = none yet).
var picks := {}
var _picked := {}           # pick id -> true (the fast check every hit makes)
## Old card effects that become gear lines in M3 (Kindled kills, Hot core, Lee), kept from a version 7 save.
var lines: Array[String] = []
## Where the keeper last rested (a lit WayLamp): picks can be changed freely near it (respec), Vector2.INF if not.
var respec_at := Vector2.INF
var respecs := 0            # times picks were reset or swapped at rest (tests)
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
	picks = {}
	_picked = {}
	lines = []
	respec_at = Vector2.INF
	respecs = 0
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
	# M1c (PLAN_LANTERNS §6.6): slot 4 (Y) takes any skill; an aimed one fires at the lock or auto-targets.
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
		_grant_level_skills()
		level_up.emit(level)
	if at_level_cap():
		wick = 0
	wick_changed.emit(wick, wick_needed(), level)

# --- Skill points and picks (M2, GAME_PLAN §4.2, §9) ---------------------------------------------------

## Skill points earned so far: kl_points_per_level for every level over 1.
func points_total() -> int:
	return maxi(0, level - 1) * Tuning.kl_points_per_level

func points_spent() -> int:
	return _picked.size()

## Points not spent yet (the Skills tab's mark).
func skill_points() -> int:
	return maxi(0, points_total() - points_spent())

func has_pick(id: String) -> bool:
	return _picked.has(id)

## An old card's effect carried as a line until gear exists (M3): kindled_kills, hot_core, lee.
func has_line(id: String) -> bool:
	return lines.has(id)

## The pick taken in a tier of a skill, or "".
func pick_in(skill: String, tier: int) -> String:
	var row: Array = picks.get(skill, [])
	return str(row[tier]) if tier >= 0 and tier < row.size() else ""

## True once the Ashbrood (the Hollow's guardian) has fallen: tier 3 opens.
func tier3_open() -> bool:
	return cleared.has("ashbrood_hollow") or settled.has(FogGrid.R_HOLLOW)

## "" if tier `tier` (0-2) of `skill` is open, else why not (shown in the Skills tab).
func tier_reason(skill: String, tier: int) -> String:
	if skill != "dash" and not knows(skill):
		return "Learn %s first (level %d)." % [SkillTree.skill_title(skill), Tuning.kl_lance_level]
	match tier:
		1:
			if level < Tuning.kl_tier2_level:
				return "Opens at level %d." % Tuning.kl_tier2_level
		2:
			if not tier3_open():
				return "Opens when the Ashbrood falls."
	return ""

## Picks can be changed freely here: the keeper rested at a lit WayLamp and is still by it, not hunted.
func respec_open() -> bool:
	if respec_at == Vector2.INF:
		return false
	var k := get_tree().get_first_node_in_group("player") as Node2D if get_tree() else null
	if k == null:
		return false
	if k.global_position.distance_to(respec_at) > Tuning.kl_respec_radius:
		return false
	return not ("hunted" in k and k.hunted)

## "" if `id` can be taken now, else why not.
func pick_reason(id: String) -> String:
	var inf := SkillTree.info(id)
	if inf.is_empty():
		return "No such pick."
	if has_pick(id):
		return "You have it."
	var why := tier_reason(inf.skill, inf.tier)
	if why != "":
		return why
	var taken := pick_in(inf.skill, inf.tier)
	if taken != "":
		return "" if respec_open() else "One pick a tier. Rest at a lit WayLamp to change it."
	if skill_points() <= 0:
		return "No skill points. You get one each level."
	return ""

## Takes a pick (at rest, it replaces the one already in its tier, for free). "" on success, else why not.
func take_pick(id: String) -> String:
	var why := pick_reason(id)
	if why != "":
		return why
	var inf := SkillTree.info(id)
	var row: Array = picks.get(inf.skill, ["", "", ""])
	var old := str(row[inf.tier])
	if old != "":
		_picked.erase(old)
		respecs += 1
	row[inf.tier] = id
	picks[inf.skill] = row
	_picked[id] = true
	picks_changed.emit()
	return ""

## Gives a pick back (only at rest). "" on success, else why not.
func unlearn(id: String) -> String:
	if not has_pick(id):
		return "You don't have it."
	if not respec_open():
		return "Rest at a lit WayLamp to change your picks."
	var inf := SkillTree.info(id)
	var row: Array = picks.get(inf.skill, ["", "", ""])
	row[inf.tier] = ""
	picks[inf.skill] = row
	_picked.erase(id)
	respecs += 1
	picks_changed.emit()
	return ""

## Every pick back as points (only at rest). "" on success, else why not.
func reset_picks() -> String:
	if not respec_open():
		return "Rest at a lit WayLamp to change your picks."
	if _picked.is_empty():
		return "No picks to reset."
	picks = {}
	_picked = {}
	respecs += 1
	picks_changed.emit()
	return ""

## Sets picks without the rules (loading a save, tests). Unknown ids, a second pick in a tier, or more picks than
## points are dropped. Returns the picks kept.
func set_picks(list: Array) -> Array:
	picks = {}
	_picked = {}
	var kept := []
	for raw in list:
		var id := str(raw)
		var inf := SkillTree.info(id)
		if inf.is_empty() or _picked.has(id) or _picked.size() >= points_total():
			continue
		if tier_reason(inf.skill, inf.tier) != "" or pick_in(inf.skill, inf.tier) != "":
			continue
		var row: Array = picks.get(inf.skill, ["", "", ""])
		row[inf.tier] = id
		picks[inf.skill] = row
		_picked[id] = true
		kept.append(id)
	picks_changed.emit()
	return kept

## Every pick taken, in tree order (saves).
func pick_list() -> Array:
	var out := []
	for skill in SkillTree.ORDER:
		for t in 3:
			var id := pick_in(skill, t)
			if id != "":
				out.append(id)
	return out

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

## Lamp slots by level (M1c, PLAN_LANTERNS §5; owner 2026-11-28): 2 at the start, 3 at level 4, 4 at 8, 5 at 12.
## No gear adds slots yet (M3); never more than kl_lamp_slots_max.
func lamp_slots(lv: int = -1) -> int:
	var l := level if lv < 0 else lv
	var n := Tuning.kl_lamp_slots_base
	for at in [Tuning.kl_lamp_slot_level_a, Tuning.kl_lamp_slot_level_b, Tuning.kl_lamp_slot_level_c]:
		if l >= at:
			n += 1
	return clampi(n, 0, Tuning.kl_lamp_slots_max)

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
