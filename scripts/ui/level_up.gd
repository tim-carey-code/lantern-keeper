extends Node
## M2 (GAME_PLAN §9, §14): a level-up gives a skill point and shows as a chime, a line on the tip strip and a mark
## on the HUD's level and the pack's Skills tab, with no pause (the "Trim the wick" card screen is gone; its cards
## became branch picks, SkillTree.CARD_TO_PICK). The line never names a skill: where a point goes is the player's
## choice, and nothing pushes a skill that is off the bar (owner, 2026-11-28). Texts are DRAFT (STORY §17).

const LEVEL_LINE := "Level %d: a skill point. Spend it in your pack (%s), on the Skills tab."
const TIER2_LINE := "Level %d: tier 2 of your skills is open."
const TIER3_LINE := "The Ashbrood is gone: tier 3 of your skills is open."

var shown := 0                   # level-up lines shown (tests)
var last_line := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Progress.level_up.connect(_on_level_up)
	Progress.region_settled.connect(_on_settled)

func _on_level_up(lv: int) -> void:
	Sfx.play_ui("unlock", -4.0)
	_line(LEVEL_LINE % [lv, InputHint.key("pack")])
	if lv == Tuning.kl_tier2_level:
		_line(TIER2_LINE % lv)

func _on_settled(region_id: int, _name: String) -> void:
	if region_id == FogGrid.R_HOLLOW:
		_line(TIER3_LINE)

func _line(text: String) -> void:
	shown += 1
	last_line = text
	var hud := get_parent()
	if hud and "_tips" in hud:
		hud._tips.push_front(text)
