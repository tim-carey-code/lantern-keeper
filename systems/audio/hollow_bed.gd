extends Node
## The Hollow's ambience bed, layered under its music: a wind whoosh loop and night crickets, on the
## "Ambience" bus. Fades in while the keeper is in the Hollow and out when they leave.
## Placeholder recordings picked by the owner (see assets/CREDITS.md for their licence status).

const LAYERS := [
	["res://assets/audio/ambience/wind_loop.ogg", -4.0],      # file, base volume in dB
	["res://assets/audio/ambience/crickets_loop.ogg", -6.0],
]
const SILENT_DB := -60.0
const FADE_DB_PER_SEC := 15.0

var players: Array[AudioStreamPlayer] = []
var wanted := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for l in LAYERS:
		var s := load(l[0]) as AudioStreamOggVorbis
		s.loop = true
		var p := AudioStreamPlayer.new()
		p.stream = s
		p.bus = "Ambience"
		p.volume_db = SILENT_DB
		add_child(p)
		players.append(p)

func _process(delta: float) -> void:
	var fog := get_tree().get_first_node_in_group("fog_grid") as FogGrid
	var keeper = get_tree().get_first_node_in_group("player")
	wanted = fog != null and keeper != null and fog.region_at(keeper.global_position) == FogGrid.R_HOLLOW
	for i in players.size():
		var p := players[i]
		p.volume_db = move_toward(p.volume_db, LAYERS[i][1] if wanted else SILENT_DB, FADE_DB_PER_SEC * delta)
		if wanted and not p.playing:
			p.play()
		elif not wanted and p.playing and p.volume_db <= SILENT_DB + 1.0:
			p.stop()
