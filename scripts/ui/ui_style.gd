class_name UiStyle
extends RefCounted
## One look for every panel: deep navy, a warm wood or amber trim, slightly rounded.

const NAVY := Color(0.078, 0.102, 0.18, 0.9)
const WOOD := Color(0.61, 0.29, 0.13)
const AMBER := Color(0.96, 0.65, 0.26)
const GOLD := Color(1.0, 0.82, 0.48)
const CREAM := Color(1.0, 0.945, 0.757)
const PALE := Color(0.64, 0.74, 0.83)
const WARN := Color(0.95, 0.69, 0.64)

static func panel(border: Color = WOOD, bg: Color = NAVY, width: int = 2, margin: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(margin)
	return sb

static func bar(fill: Color) -> Array:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.043, 0.055, 0.1)
	bg.set_corner_radius_all(3)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(3)
	return [bg, fg]

static func icon(name: String) -> Texture2D:
	return load("res://assets/art/ui/%s.png" % name)

## A label with a soft drop shadow, readable over the dark world.
static func label(size: int, color: Color = CREAM) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

## A 16x16 icon shown at 2x, crisp.
static func icon_rect(name: String, size: int = 32) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon(name)
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	return t
