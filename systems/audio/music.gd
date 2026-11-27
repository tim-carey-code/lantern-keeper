extends Node
## The Hollow's music: "Dark Forest Theme" (CC0, see assets/CREDITS.md). Fades in while the keeper is in
## the Hollow and out when they leave, on the "Music" bus. Other regions get their own tracks later.

const TRACK := "res://assets/audio/music/hollow_dark_forest_theme.mp3"
const BASE_DB := -12.0        # the track is loud (-15.5 LUFS); the Music bus slider sits on top of this
const SILENT_DB := -60.0
const FADE_DB_PER_SEC := 15.0 # about 3 s to fade in or out

var player: AudioStreamPlayer
var wanted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # keeps playing under the pause menu
	var s := load(TRACK) as AudioStreamMP3
	s.loop = true
	player = AudioStreamPlayer.new()
	player.stream = s
	player.bus = "Music"
	player.volume_db = SILENT_DB
	add_child(player)

func _process(delta: float) -> void:
	var fog := get_tree().get_first_node_in_group("fog_grid") as FogGrid
	var keeper = get_tree().get_first_node_in_group("player")
	wanted = fog != null and keeper != null and fog.region_at(keeper.global_position) == FogGrid.R_HOLLOW
	player.volume_db = move_toward(player.volume_db, BASE_DB if wanted else SILENT_DB, FADE_DB_PER_SEC * delta)
	if wanted and not player.playing:
		player.play()
	elif not wanted and player.playing and player.volume_db <= SILENT_DB + 1.0:
		player.stop()
