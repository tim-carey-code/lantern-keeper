extends Node
## Placeholder ambience, generated live (no audio files yet; real sounds come in M4).
##   Base:  a low, soft rumble everywhere.
##   Marsh: a breathy reed hiss that fades in while you are in the Reedmarsh.
##   Wind:  a rising rush during gust warnings and gusts.
## Seamless because it is synthesized continuously. Quiet by default.

const RATE := 22050.0

var stream_player: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback
var rng := RandomNumberGenerator.new()
var w_marsh := 0.0
var w_wind := 0.0
var _brown := 0.0
var _t := 0.0

func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.25
	stream_player = AudioStreamPlayer.new()
	stream_player.stream = gen
	stream_player.volume_db = -18.0
	stream_player.bus = "Ambience"
	add_child(stream_player)
	stream_player.play()
	playback = stream_player.get_stream_playback() as AudioStreamGeneratorPlayback

func _process(delta: float) -> void:
	var fog := get_tree().get_first_node_in_group("fog_grid") as FogGrid
	var player = get_tree().get_first_node_in_group("player")
	var wind := get_tree().get_first_node_in_group("wind") as Wind
	var in_marsh: bool = fog != null and player != null and fog.region_at(player.global_position) == FogGrid.R_MARSH
	w_marsh = move_toward(w_marsh, 1.0 if in_marsh else 0.0, delta * 0.3)
	w_wind = move_toward(w_wind, wind.gust_level() if wind else 0.0, delta * 0.5)
	if playback == null:
		return
	var n := playback.get_frames_available()
	var step := 1.0 / RATE
	for i in n:
		var white := rng.randf() * 2.0 - 1.0
		_brown = (_brown + 0.02 * white) / 1.02
		_t += step
		var s := _brown * 1.8
		s += white * 0.035 * w_marsh * (0.55 + 0.45 * sin(_t * TAU * 0.25))
		s += (white - _brown * 3.0) * 0.1 * w_wind * (0.7 + 0.3 * sin(_t * TAU * 0.7))
		playback.push_frame(Vector2(s, s))
