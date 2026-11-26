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
