class_name MapChunk
extends Node2D
## One square of the static map, drawn once (performance). The map used to be a single canvas item
## with a draw command for every tile, so the renderer replayed the whole map every frame and again
## for every light. In chunks, off-screen chunks are culled and a light only touches the chunks under it.

const SIZE := 16   # tiles per side

var fog: FogGrid
var t0 := Vector2i.ZERO   # first tile of this chunk

static func _hash(x: int, y: int) -> int:
	return ((x * 73856093) ^ (y * 19349663)) & 0xffff

func _draw() -> void:
	var t := FogGrid.TILE
	var ground_tint := Color(0.78, 0.8, 0.9)   # keep lamplit grass from washing out
	var marsh_tint := Color(0.5, 0.68, 0.74)
	var plank_tint := Color(1.0, 0.8, 0.6)
	for y in range(t0.y, mini(t0.y + SIZE, fog.rows)):
		for x in range(t0.x, mini(t0.x + SIZE, fog.cols)):
			var pos := Vector2((x - t0.x) * t, (y - t0.y) * t)
			var h := _hash(x, y)
			match fog.terrain[y * fog.cols + x]:
				FogGrid.T_ROCK when fog.region[y * fog.cols + x] == FogGrid.R_RIDGE:
					# Ridge outcrops: bare stone that breaks the wind.
					Art.cell(self, Art.TOWN, Art.GRASS, pos, Color(0.5, 0.55, 0.65))
					Art.cell(self, Art.DUNGEON, Art.STONE_WALL, pos, Color(0.75, 0.78, 0.88))
				FogGrid.T_ROCK:
					Art.cell(self, Art.TOWN, Art.GRASS, pos, Color(0.22, 0.24, 0.32))
					if h % 100 < 70:
						Art.cell(self, Art.TOWN, Art.PINES[h % Art.PINES.size()], pos + Vector2((h % 7) - 3, (h % 5) - 2), Color(0.6, 0.64, 0.78))
				FogGrid.T_MARSH:
					Art.cell(self, Art.TOWN, Art.GRASS, pos, marsh_tint)
					if h % 100 < 45:
						draw_texture_rect(Art.placeholder("reeds.png"), Rect2(pos, Vector2(t, t)), false)
				FogGrid.T_BOARDWALK:
					Art.cell(self, Art.TOWN, Art.GRASS, pos, marsh_tint)
					Art.cell(self, Art.DUNGEON, Art.PLANKS, pos, plank_tint)
				_:
					var c := Art.GRASS
					if h % 100 < 3:
						c = Art.GRASS_FLOWERS
					elif h % 100 < 25:
						c = Art.GRASS_TUFT
					Art.cell(self, Art.TOWN, c, pos, ground_tint)
