extends Node
## Autoload "Mix": three audio buses, so sound effects, music and ambience can be balanced
## separately (the F1 tuning panel has a slider for each). Made in code, so there is no layout file to keep in sync.

const BUSES := ["SFX", "Music", "Ambience"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in BUSES:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, n)
			AudioServer.set_bus_send(i, "Master")
	_process(0.0)

func _process(_delta: float) -> void:
	_apply("SFX", Tuning.vol_sfx_db)
	_apply("Music", Tuning.vol_music_db)
	_apply("Ambience", Tuning.vol_ambience_db)

func _apply(bus: String, db: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i != -1 and not is_equal_approx(AudioServer.get_bus_volume_db(i), db):
		AudioServer.set_bus_volume_db(i, db)
