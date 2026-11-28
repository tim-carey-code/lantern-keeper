class_name SkillTree
extends RefCounted
## M2 "Builds" (GAME_PLAN §4.2, §4.3, §9): fixed branches instead of the "Trim the wick" cards. Each skill has three
## tiers and you take one pick in each; a pick costs one skill point (one a level-up). Tier 1 opens once you have
## the skill, tier 2 at Tuning.kl_tier2_level, tier 3 when the Ashbrood falls. Every pick changes how the skill
## behaves (brief §3); only the Beam keeps the old number cards the owner approved. Respec is free while you rest
## at a lit WayLamp (Progress.respec_open). The Beam and Hearth ring have trees because they are still kept
## (DECISIONS: keep-or-cut is open). Titles from the plan; the one-line bodies are DRAFT (STORY §17).
## The rules live in Progress (take_pick, tier_reason, ...); the effects in each skill, FireBolts, KeeperCombat and Foe.
## Every number is in Tuning (kl_pick_*), shown in the tuning panel.

## The trees, in the Skills tab's order. Each skill: [tier 1, tier 2, tier 3], each tier a list of picks.
const ORDER := ["lampfire", "fireglobe", "lance", "dash", "beam", "hearth_ring"]

const TREES := {
	"lampfire": [
		[["lingering_burn", "Lingering burn", "A foe your bolt hits burns for 2 s."],
		 ["scatter", "Scatter", "Each burst throws 3 sparks on through the pack."]],
		[["twin", "Twin", "Two bolts in a V, each a little weaker."],
		 ["skip", "Skip", "A bolt that hits jumps on to one more foe nearby."]],
		[["catching", "Catching", "A kill sets the nearest foe within 60 px alight."],
		 ["needle", "Needle", "A bolt passes the first foe and bursts on the second."],
		 ["comet", "Comet", "Every 4th bolt is big: double damage and splash."]],
	],
	"fireglobe": [
		[["skipping_globe", "Skipping globe", "It bounces once, bursting again where it lands."],
		 ["slick", "Slick", "Its burning ground slows foes."]],
		[["second_globe", "Second globe", "A smaller globe follows it down."],
		 ["fire_line", "Fire line", "It lands as a line of fire across your aim."]],
		[["cluster", "Cluster", "It bursts into 4 small globes."],
		 ["beacon", "Beacon", "Where it lands stays lit for 6 s, like a tiny lamp. Foes in it are lit."],
		 ["undertow", "Undertow", "The blast pulls foes in before it bursts."]],
	],
	"lance": [
		[["burning_line", "Burning line", "It leaves 2 s of fire along its path."],
		 ["brand", "Brand", "Your next hit on the last foe it struck does 50% more."]],
		[["returning", "Returning", "At the end of its flight it flies back through foes."],
		 ["forked", "Forked", "It splits in two at the first foe it hits."]],
		[["breaking", "Breaking", "At its end it bursts into 3 Lampfire bolts."],
		 ["held_lance", "Held lance", "Hold the button 0.6 s, then let go: double damage, through everything."],
		 ["shatter", "Shatter", "A shell it breaks bursts, hurting everything around."]],
	],
	"dash": [
		[["second_step", "Second step", "Dash twice before its cooldown."],
		 ["cinder_trail", "Cinder trail", "Your dash leaves burning ground behind it."]],
		[["phase", "Phase", "Foes you dash through are stunned for a moment."],
		 ["flame_step", "Flame step", "A small ring of fire where your dash ends."]],
		[["ember_rest", "Ember rest", "Your dash leaves an ember that lights foes around it for 3 s."],
		 ["blink", "Blink", "Your dash is an instant step, farther."],
		 ["recoil", "Recoil", "Dash away from your aim and you throw 3 Lampfire bolts forward."]],
	],
	"beam": [
		[["steady_hand", "Steady hand", "You walk at 90% speed while beaming."],
		 ["long_throw", "Long throw", "Your beam reaches 310 px."]],
		[["deep_tank", "Deep tank", "Your beam costs 20% less lamp charge."],
		 ["tight_focus", "Tight focus", "Your beam wears shells 30% faster."]],
		[["prism", "Prism", "Three thin beams instead of one."],
		 ["searing", "Searing", "Held on one foe, the beam burns up to 50% hotter."],
		 ["stoking", "Stoking", "Every second it burns a foe takes 1 s off Fireglobe's cooldown."]],
	],
	"hearth_ring": [
		[["heavy_ring", "Heavy ring", "It throws foes farther and stuns them."],
		 ["lasting_ring", "Lasting ring", "The ground it sweeps keeps burning for 3 s."]],
		[["spill", "Spill", "Its cooldown is 2.2 s; each foe it hits gives back 3% lamp charge."],
		 ["warm_ring", "Warm ring", "Each foe it hits gives you back a little warmth."]],
		[["sunburst", "Sunburst", "It also throws 8 Lampfire bolts all around."],
		 ["crackle", "Crackle", "It strips 2 shell from every foe it hits."],
		 ["rising_ring", "Rising ring", "A second ring rolls out to 220 px."]],
	],
}

## The old cards (save version 7 and before; GAME_PLAN §4.3): card id -> pick id. Kindled kills, Hot core and Lee
## become gear lines in M3: until then a save that has them keeps them as carried lines (Progress.lines).
const CARD_TO_PICK := {
	"lingering_burn": "lingering_burn", "catching": "catching", "second_step": "second_step",
	"steady_hand": "steady_hand", "long_throw": "long_throw", "deep_tank": "deep_tank", "tight_focus": "tight_focus",
	"heavy_flare": "heavy_ring", "spill": "spill",
}
const CARD_LINES := ["kindled_kills", "hot_core", "lee"]

static var _index := {}
## How often each pick's own effect has happened (tests: every pick still works next to the others). Each effect
## site calls mark(); it is a dictionary bump, only on a pick's own path.
static var fired := {}

static func mark(id: String) -> void:
	fired[id] = int(fired.get(id, 0)) + 1

static func _build_index() -> void:
	if not _index.is_empty():
		return
	for skill in TREES:
		var tiers: Array = TREES[skill]
		for t in tiers.size():
			for p in tiers[t]:
				_index[p[0]] = {"skill": skill, "tier": t, "title": p[1], "body": p[2]}

## {skill, tier (0-2), title, body} for a pick id, or {} if there is no such pick.
static func info(id: String) -> Dictionary:
	_build_index()
	return _index.get(id, {})

static func exists(id: String) -> bool:
	return not info(id).is_empty()

## The pick ids in one tier of a skill.
static func tier_picks(skill: String, tier: int) -> Array:
	var out := []
	var tiers: Array = TREES.get(skill, [])
	if tier >= 0 and tier < tiers.size():
		for p in tiers[tier]:
			out.append(p[0])
	return out

## Every pick id.
static func all_picks() -> Array:
	_build_index()
	return _index.keys()

## What a skill is called in the tree (the dash isn't a bar skill).
static func skill_title(skill: String) -> String:
	match skill:
		"lampfire":
			return "Lampfire"
		"fireglobe":
			return "Fireglobe"
		"lance":
			return "Lance"
		"dash":
			return "Dash"
		"beam":
			return "The Beam"
		"hearth_ring":
			return "Hearth ring"
	return skill
