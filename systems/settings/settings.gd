extends Node
## Autoload "Settings": player options that belong to the PC, not to a save slot (GAME_PLAN §14, brief §4):
## the screen-shake slider, "reduce flashes" and the optional Lampfire auto-fire on the right stick.
## Stored in user://settings.cfg. Only the pause menu calls save(); tests and captures never do, and they
## call use_defaults() so the owner's own settings can't change a run.

const PATH := "user://settings.cfg"

var shake := 1.0              # 0..1: screen shake strength
var reduce_flashes := false   # dims hit flashes, impact flashes and screen flashes
var autofire := false         # pad: Lampfire fires while the right stick is pushed past Tuning.kl_autofire_stick
var path := PATH              # tests point this elsewhere

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_from(path)

func use_defaults() -> void:
	shake = 1.0
	reduce_flashes = false
	autofire = false

func load_from(p: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(p) != OK:
		return
	shake = clampf(float(cfg.get_value("feel", "shake", 1.0)), 0.0, 1.0)
	reduce_flashes = bool(cfg.get_value("feel", "reduce_flashes", false))
	autofire = bool(cfg.get_value("controls", "autofire", false))

func save() -> bool:
	var cfg := ConfigFile.new()
	cfg.set_value("feel", "shake", shake)
	cfg.set_value("feel", "reduce_flashes", reduce_flashes)
	cfg.set_value("controls", "autofire", autofire)
	return cfg.save(path) == OK

## How strong a flash is drawn: 1 normally, much less with "reduce flashes".
func flash_mult() -> float:
	return 0.3 if reduce_flashes else 1.0
