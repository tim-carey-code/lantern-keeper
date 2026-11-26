class_name LightTex
extends RefCounted
## Shared soft radial light texture. 256 px wide, so radius = 128 px at texture_scale 1.

const SIZE := 256
const BASE_RADIUS := 128.0

static var _cached: GradientTexture2D

static func radial() -> GradientTexture2D:
	if _cached:
		return _cached
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = SIZE
	t.height = SIZE
	_cached = t
	return t

## texture_scale that makes the light reach `radius` px.
static func scale_for(radius: float) -> float:
	return radius / BASE_RADIUS

static var _strip: ImageTexture

## A long narrow beam pointing right from the left-middle edge (Mirror Post beams).
## 256x40: at texture_scale 1 the beam is 256 px long and 40 px wide.
static func beam_strip() -> ImageTexture:
	if _strip:
		return _strip
	var w := 256
	var h := 40
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for x in w:
		var t := float(x) / float(w - 1)
		var fade := clampf(t * 12.0, 0.0, 1.0) * pow(1.0 - t, 0.35)
		for y in h:
			var d := absf(y - h / 2.0) / (h / 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, fade * clampf(1.2 - d * 1.2, 0.0, 1.0)))
	_strip = ImageTexture.create_from_image(img)
	return _strip
