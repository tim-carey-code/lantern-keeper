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

var _spawned := 0   # how many came out of the fog (every Nth is a shelled elite)

func count() -> int:
	return get_tree().get_nodes_in_group("wickling").size()

func _process(delta: float) -> void:
	if not Tuning.wick_enabled or not Tuning.kl_ambient_spawns:
		return   # ARPG: enemies wait in fixed packs and nests; nothing streams out of the fog
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
		if Progress.is_settled(fog.region[fog.idx(t)]):
			continue   # nothing comes into a held region
		_spawned += 1
		return spawn_at(fog.tile_center(t), Tuning.kl_elite_every > 0 and _spawned % Tuning.kl_elite_every == 0)
	return null

## PROTOTYPE: a kindling WayLamp draws a swarm of bold Wicklings out of the dark around it.
func spawn_swarm(lamp: Node2D, n: int) -> Array:
	var fog := _fog()
	var out := []
	if fog == null:
		return out
	for i in n:
		var p := Vector2.ZERO
		var found := false
		for tries in 40:
			var ang := rng.randf() * TAU
			var dist := rng.randf_range(7.0, 11.0) * FogGrid.TILE
			p = lamp.global_position + Vector2.from_angle(ang) * dist
			var t := fog.tile_of(p)
			if fog.in_bounds(t) and fog.solid[fog.idx(t)] == 0 and not Progress.is_settled(fog.region[fog.idx(t)]):
				found = true
				break
		if not found:
			continue
		var w := spawn_at(fog.tile_center(fog.tile_of(p)))
		w.bold = true
		w.summoned = true
		w.level = Tuning.kl_waylamp_swarm_level
		w.target = lamp
		w.state = Wickling.State.SEEK_LANTERN
		out.append(w)
	return out

func spawn_at(p: Vector2, elite: bool = false) -> Wickling:
	var w := Wickling.new()
	w.elite = elite
	w.position = p
	add_child(w)
	return w
