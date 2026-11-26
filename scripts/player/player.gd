extends CharacterBody2D
## M0 placeholder keeper: moves with keyboard or gamepad and carries a hand lamp.

@export var speed := 180.0
@export var lamp_radius_px := 512

var lamp: PointLight2D

func _ready() -> void:
	lamp = PointLight2D.new()
	lamp.texture = _radial_texture(lamp_radius_px)
	lamp.color = Color(1.0, 0.82, 0.5)
	lamp.energy = 1.3
	add_child(lamp)

func _physics_process(_delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()

func _draw() -> void:
	draw_rect(Rect2(-8, -12, 16, 24), Color(0.9, 0.85, 0.7))

static func _radial_texture(size: int) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = size
	t.height = size
	return t
