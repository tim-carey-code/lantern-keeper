class_name Art
extends RefCounted
## Where the game's pixel art lives, and small helpers to draw it at 2x.
## Tilesheets: Kenney Tiny Town / Tiny Dungeon (CC0), recoloured to our palette.
## Placeholders: assets/art/placeholders (replace with same name and size).

const SCALE := 2.0
const CELL := 16

const TOWN := preload("res://assets/art/kenney/tiny_town.png")
const DUNGEON := preload("res://assets/art/kenney/tiny_dungeon.png")

# Tiny Town cells (column, row)
const GRASS := Vector2i(0, 0)
const GRASS_TUFT := Vector2i(1, 0)
const GRASS_FLOWERS := Vector2i(2, 0)
const PINES := [Vector2i(4, 0), Vector2i(4, 2), Vector2i(3, 0)]   # trees for the valley's wooded rim
const LOG := Vector2i(10, 8)
const SIGN := Vector2i(11, 6)
const HUT_ROOF := [Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5)]
const HUT_WALL := [Vector2i(0, 7), Vector2i(1, 7), Vector2i(0, 7)]
const PUMP_ROOF := [Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5)]
const PUMP_WALL := [Vector2i(4, 7), Vector2i(5, 7), Vector2i(4, 7)]

# Tiny Dungeon cells
const PLANKS := Vector2i(0, 3)
const STONE_WALL := Vector2i(4, 2)
const GRAVESTONE := Vector2i(5, 5)
const KEEPER := Vector2i(3, 9)          # old single-frame keeper (unused)
const KEEPER_SHEET := preload("res://assets/art/puny/keeper.png")   # Puny Characters (CC0): 24x8 frames of 32x32
const KEEPER_FRAME := 32

static var _ph := {}

static func placeholder(file: String) -> Texture2D:
	if not _ph.has(file):
		_ph[file] = load("res://assets/art/placeholders/" + file)
	return _ph[file]

static func src(cell: Vector2i, w: int = 1, h: int = 1) -> Rect2:
	return Rect2(cell.x * CELL, cell.y * CELL, CELL * w, CELL * h)

## Draw one 16x16 cell of a sheet into a 32x32 rect at top-left `pos`.
static func cell(ci: CanvasItem, sheet: Texture2D, c: Vector2i, pos: Vector2, mod: Color = Color.WHITE) -> void:
	ci.draw_texture_rect_region(sheet, Rect2(pos, Vector2(CELL, CELL) * SCALE), src(c), mod)

## Draw a whole texture at 2x with its bottom-centre at `foot`.
static func sprite(ci: CanvasItem, tex: Texture2D, foot: Vector2, mod: Color = Color.WHITE, flip: bool = false) -> void:
	var size := tex.get_size() * SCALE
	var rect := Rect2(foot - Vector2(size.x / 2.0, size.y), size)
	if flip:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	ci.draw_texture_rect(tex, rect, false, mod)

## Draw a sheet cell at 2x with its bottom-centre at `foot`.
static func cell_at_foot(ci: CanvasItem, sheet: Texture2D, c: Vector2i, foot: Vector2, mod: Color = Color.WHITE, flip: bool = false) -> void:
	var size := Vector2(CELL, CELL) * SCALE
	var rect := Rect2(foot - Vector2(size.x / 2.0, size.y), size)
	if flip:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	ci.draw_texture_rect_region(sheet, rect, src(c), mod)
