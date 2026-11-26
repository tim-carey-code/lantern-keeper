extends Node2D
## PROTOTYPE. Spawns Wicklings out of deep fog at a distance from the keeper.
## A grace period at the start lets the player settle in first.

var _timer := 0.0
var _started := false
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("wickling_spawner")
	rng.randomize()
	_timer = Tuning.wick_first_delay

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func count() -> int:
	return get_tree().get_nodes_in_group("wickling").size()

func _process(delta: float) -> void:
	if not Tuning.wick_enabled:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = Tuning.wick_spawn_sec
	if count() < Tuning.wick_max:
		spawn_near_player()

## Picks an open tile in deep fog 10-18 tiles from the keeper. Returns the Wickling or null.
func spawn_near_player() -> Wickling:
	var fog := _fog()
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if fog == null or player == null:
		return null
	for i in 40:
		var ang := rng.randf() * TAU
		var dist := rng.randf_range(10.0, 18.0) * FogGrid.TILE
		var p := player.global_position + Vector2.from_angle(ang) * dist
		var t := fog.tile_of(p)
		if not fog.in_bounds(t) or fog.solid[fog.idx(t)] == 1 or fog.density[fog.idx(t)] < 0.85:
			continue
		return spawn_at(fog.tile_center(t))
	return null

func spawn_at(p: Vector2) -> Wickling:
	var w := Wickling.new()
	w.position = p
	add_child(w)
	return w
