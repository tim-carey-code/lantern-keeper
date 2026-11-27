class_name ClimbStones
extends Node2D
## The loop (owner 2026-11-27): the old climb from the top of the Hollow to the Ridge is the later shortcut.
## Fallen stones close it. Coming down from the Ridge, the keeper pushes them down the slope (within REACH
## tiles, from the north side), and the climb is open for good. Saved in Progress.cleared (ID).
## The stones are rock tiles in the fog grid (drawn as bare stone) with their own collision body, so
## opening them turns them back into ground without rebuilding the map's collision.

const ID := "climb_stones"
const ROWS := [84, 85]   # tile rows across the climb, below the Ridge's edge (y 76)
const REACH := 3.0       # tiles

var main: Node
var tiles: Array[Vector2i] = []
var body: StaticBody2D
var is_open := false

func setup(m: Node, t: Array[Vector2i]) -> void:
	main = m
	tiles = t
	body = StaticBody2D.new()
	add_child(body)
	for tile in tiles:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(FogGrid.TILE, FogGrid.TILE)
		shape.shape = rect
		shape.position = main.fog.tile_center(tile)
		body.add_child(shape)

func top_y() -> float:
	return float(ROWS[0]) * FogGrid.TILE

func center() -> Vector2:
	if tiles.is_empty():
		return Vector2.ZERO
	var c := Vector2.ZERO
	for t in tiles:
		c += main.fog.tile_center(t)
	return c / tiles.size()

func _process(_delta: float) -> void:
	if is_open or main == null:
		return
	if Progress.cleared.has(ID):
		open(false)   # opened before a reload
		return
	var p: Node2D = main.player
	if p.global_position.y < top_y() and p.global_position.distance_to(_nearest(p.global_position)) <= REACH * FogGrid.TILE:
		open(true)

func _nearest(p: Vector2) -> Vector2:
	var best := Vector2.ZERO
	var bd := INF
	for t in tiles:
		var c: Vector2 = main.fog.tile_center(t)
		if c.distance_to(p) < bd:
			bd = c.distance_to(p)
			best = c
	return best

## The stones go down the slope: ground again, the climb walkable both ways.
func open(with_sound: bool = true) -> void:
	if is_open:
		return
	is_open = true
	Progress.cleared[ID] = true
	var fog: FogGrid = main.fog
	for t in tiles:
		fog.set_tile(t, FogGrid.T_GROUND, FogGrid.R_HOLLOW)
	fog.mark_all_dirty()
	if body:
		body.queue_free()
		body = null
	for c in main.get_node("Terrain").get_children():
		if c is MapChunk:
			c.queue_redraw()
	if with_sound:
		Sfx.play("unlock", -6.0)
		main.player.shake(0.5)
