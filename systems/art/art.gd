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

# --- Placeholder swap hook (readability step; ART_DIRECTION §6.2-§6.4, DRAFT) ------------------------------------
# Owner art goes in per-subject folders: one PNG strip per animation (frames side by side, equal size, no padding)
# and a small frames file:
#   assets/art/creatures/<subject>/<subject>[_<variant>]_<anim>.png   + <subject>.frames.cfg
#   assets/art/keeper/keeper_<anim>.png                               + keeper.frames.cfg
# frames(subject) builds a SpriteFrames from whatever strips exist (cached). With no strips it returns null, and
# the foe keeps drawing its code shape (FoeSprite). Strips Godot hasn't imported yet are read straight from the
# file, so a PNG dropped in shows the next time the game starts.

## Where frames() looks, in order: each root holds <subject>/ folders. Tests point this at a scratch folder.
static var sprite_roots: PackedStringArray = ["res://assets/art/creatures/", "res://assets/art/", "res://assets/art/people/"]
static var _frames := {}
## Animation names (ART_DIRECTION §6.2), plus the keeper's poses. Others can be listed in the frames file.
const ANIMS := ["idle", "move", "notice", "windup", "attack", "recover", "hurt", "death", "spawn",
	"cast", "lob", "thrust", "dash", "drink"]
const LOOPING := ["idle", "move"]

## The SpriteFrames for a subject (and variant: "brave", "elite" ...), or null when it has no strips.
## Metadata: "anchor" ("foot" or "center"), "frame_size" (the first strip's), "frame_size_<anim>" (each strip's),
## "timed_by_<anim>" (a Tuning name).
## Frame size, per strip: a variant's strip uses [variant.<v>] frame_size, a plain strip [<anim>] frame_size, then
## [sheet] frame_size. A strip is one row, so its height is the frame height: a size that doesn't match the strip's
## height gives way to a square of that height (so a 24x24 elite strip still slices right under a 16x16 sheet).
## [variant.<v>] anchor overrides [sheet] anchor. Sections with a dot (variant.*) are not animations.
static func frames(subject: String, variant: String = "") -> SpriteFrames:
	var key := subject + "/" + variant
	if _frames.has(key):
		return _frames[key]
	var sf: SpriteFrames = null
	for root in sprite_roots:
		var dir := root + subject + "/"
		if not DirAccess.dir_exists_absolute(dir):
			continue
		var cfg := ConfigFile.new()
		var has_cfg := FileAccess.file_exists(dir + subject + ".frames.cfg") and cfg.load(dir + subject + ".frames.cfg") == OK
		var vsec := "variant." + variant
		var anchor := "foot"
		if has_cfg:
			anchor = str(cfg.get_value("sheet", "anchor", "foot"))
			if variant != "" and cfg.has_section_key(vsec, "anchor"):
				anchor = str(cfg.get_value(vsec, "anchor"))
		var names: Array = ANIMS.duplicate()
		if has_cfg:
			for sec in cfg.get_sections():
				if sec != "sheet" and not sec.contains(".") and not names.has(sec):
					names.append(sec)
		for anim in names:
			var tex: Texture2D = null
			var from_variant := false
			if variant != "":
				tex = _strip(dir + "%s_%s_%s.png" % [subject, variant, anim])
				from_variant = tex != null
			if tex == null:
				tex = _strip(dir + "%s_%s.png" % [subject, anim])
			if tex == null:
				continue
			var size := strip_frame_size(cfg if has_cfg else null, variant if from_variant else "", anim, tex.get_height())
			if sf == null:
				sf = SpriteFrames.new()
				if sf.has_animation("default"):
					sf.remove_animation("default")
				sf.set_meta("anchor", anchor)
				sf.set_meta("frame_size", size)
			sf.set_meta("frame_size_" + anim, size)
			sf.add_animation(anim)
			sf.set_animation_speed(anim, float(cfg.get_value(anim, "fps", 8.0)) if has_cfg else 8.0)
			sf.set_animation_loop(anim, bool(cfg.get_value(anim, "loop", LOOPING.has(anim))) if has_cfg else LOOPING.has(anim))
			if has_cfg and cfg.has_section_key(anim, "timed_by"):
				sf.set_meta("timed_by_" + anim, str(cfg.get_value(anim, "timed_by")))
			var count := maxi(1, int(tex.get_width() / maxi(1, size.x)))
			for i in count:
				var at := AtlasTexture.new()
				at.atlas = tex
				at.region = Rect2(i * size.x, 0, size.x, mini(size.y, tex.get_height()))
				sf.add_frame(anim, at)
		if sf != null:
			break
	_frames[key] = sf
	return sf

## One strip's frame size (see frames()): the variant's, the animation's or the sheet's configured size, else a
## square of the strip's height; a configured size whose height isn't the strip's height gives way to the square.
static func strip_frame_size(cfg: ConfigFile, variant: String, anim: String, strip_height: int) -> Vector2i:
	var want: Variant = null
	if cfg != null:
		if variant != "" and cfg.has_section_key("variant." + variant, "frame_size"):
			want = cfg.get_value("variant." + variant, "frame_size")
		elif cfg.has_section_key(anim, "frame_size"):
			want = cfg.get_value(anim, "frame_size")
		elif cfg.has_section_key("sheet", "frame_size"):
			want = cfg.get_value("sheet", "frame_size")
	var size := Vector2i(strip_height, strip_height)
	if want is Vector2i:
		size = want
	elif want is Vector2:
		size = Vector2i(want)
	elif want is int or want is float:
		size = Vector2i(int(want), int(want))
	if size.y != strip_height or size.x <= 0:
		size = Vector2i(strip_height, strip_height)
	return size

## Forget cached frames (tests, or after the owner adds a strip while the game runs).
static func clear_frames() -> void:
	_frames.clear()

## A strip: imported by Godot if it can, else read from the file (a PNG the editor hasn't imported yet).
static func _strip(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path)
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)

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
