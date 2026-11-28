extends Node
## Autoload "Sfx": short sound effects (Kenney CC0 packs, see assets/CREDITS.md).
## Sfx.play("refuel") plays assets/audio/sfx/refuel.ogg; if numbered variants exist
## (step_grass_0.ogg ... step_grass_4.ogg) one is picked at random.
## Performance (readability step): one AudioStreamPolyphonic player mixes every effect. Starting an Ogg on its
## own AudioStreamPlayer cost about 0.25 ms on the main thread each time (the decoder is set up anew), and
## Lampfire plays a tick on every hit (160 a second in the bench). A cue asked for again in the same frame is
## played once: two copies of one sound in the same 16 ms sound like one.

const DIR := "res://assets/audio/sfx/"
const VOICES := 16

var _player: AudioStreamPlayer          # the polyphonic mixer for play()
var _poly: AudioStreamPlaybackPolyphonic
var _ui_player: AudioStreamPlayer      # keeps playing while the world is paused (a level-up)
var _cache := {}
var _frame_of := {}                    # cue -> the process frame it last played in
var rng := RandomNumberGenerator.new()
var plays := {}                        # cue -> times played (tests: the wind-up sound slots)

func _ready() -> void:
	rng.randomize()
	_player = AudioStreamPlayer.new()
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = VOICES
	_player.stream = poly
	add_child(_player)
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

## Plays a cue from DIR. A path under res:// (ending in .ogg) plays that file instead (the foes' sound slots).
func play(name: String, volume_db: float = -8.0, pitch_jitter: float = 0.06, pitch: float = 1.0) -> void:
	var f := Engine.get_process_frames()
	if _frame_of.get(name, -1) == f:
		return
	var v: Array
	if name.begins_with("res://"):
		v = _cache.get(name, [])
		if not _cache.has(name):
			v = [load(name)] if ResourceLoader.exists(name) else []
			_cache[name] = v
	else:
		v = _variants(name)
	if v.is_empty():
		return
	_frame_of[name] = f
	plays[name] = plays.get(name, 0) + 1
	if not _player.playing or _poly == null:
		_player.play()
		_poly = _player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if _poly:
		_poly.play_stream(v[rng.randi() % v.size()], 0.0, volume_db, pitch * (1.0 + rng.randf_range(-pitch_jitter, pitch_jitter)))

## A sound that plays through a pause (the level-up chime pauses the world as it opens).
func play_ui(name: String, volume_db: float = -8.0) -> void:
	var v := _variants(name)
	if v.is_empty():
		return
	_ui_player.stream = v[rng.randi() % v.size()]
	_ui_player.volume_db = volume_db
	_ui_player.play()

func _exit_tree() -> void:
	if _player:
		_player.stop()
	_poly = null
	_cache.clear()
