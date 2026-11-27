extends Node
## Autoload "Sfx": short sound effects (Kenney CC0 packs, see assets/CREDITS.md).
## Sfx.play("refuel") plays assets/audio/sfx/refuel.ogg; if numbered variants exist
## (step_grass_0.ogg ... step_grass_4.ogg) one is picked at random.

const DIR := "res://assets/audio/sfx/"
const VOICES := 8

var _players: Array[AudioStreamPlayer] = []
var _ui_player: AudioStreamPlayer      # keeps playing while the world is paused (a level-up)
var _cache := {}
var _next := 0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_ui_player = AudioStreamPlayer.new()
	_ui_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ui_player)

func _variants(name: String) -> Array:
	if _cache.has(name):
		return _cache[name]
	var list := []
	if ResourceLoader.exists(DIR + name + ".ogg"):
		list.append(load(DIR + name + ".ogg"))
	var i := 0
	while ResourceLoader.exists(DIR + "%s_%d.ogg" % [name, i]):
		list.append(load(DIR + "%s_%d.ogg" % [name, i]))
		i += 1
	_cache[name] = list
	return list

func has(name: String) -> bool:
	return not _variants(name).is_empty()

func play(name: String, volume_db: float = -8.0, pitch_jitter: float = 0.06) -> void:
	var v := _variants(name)
	if v.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = v[rng.randi() % v.size()]
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + rng.randf_range(-pitch_jitter, pitch_jitter)
	p.play()

## A sound that plays through a pause (the level-up chime pauses the world as it opens).
func play_ui(name: String, volume_db: float = -8.0) -> void:
	var v := _variants(name)
	if v.is_empty():
		return
	_ui_player.stream = v[rng.randi() % v.size()]
	_ui_player.volume_db = volume_db
	_ui_player.play()
