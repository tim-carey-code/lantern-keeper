extends CanvasLayer
## PROTOTYPE (Keeper's Light): the guardian's health bar, across the bottom of the screen while it fights.
## Name and phase on top, the shell as a pale bar over the red health bar.

const FONT := preload("res://assets/fonts/ark_pixel_10px_proportional_latin.ttf")
var holder: Control

func _ready() -> void:
	layer = 5
	holder = Control.new()
	holder.size = Vector2(1280, 720)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.draw.connect(_draw_bar)
	add_child(holder)

func boss() -> Foe:
	for f in get_tree().get_nodes_in_group("foe"):
		if f is Ashbrood and not f.is_queued_for_deletion() and f.hp_max > 0.0:
			return f
	return null

func _process(_delta: float) -> void:
	holder.queue_redraw()

func _draw_bar() -> void:
	var b := boss()
	if b == null:
		return
	var w := 640.0
	var x := (1280.0 - w) / 2.0
	var y := 556.0   # above the action bar (M1a)
	# M1a: Lance and Lampfire wear shells now, not only the beam (DRAFT hint text).
	var hint := "crack its shell with Lance or Lampfire" if b.shell > 0.0 else "burn it now, before the shell grows back"
	if b.phase == 2:
		hint = "it dives at your lanterns: hit it while it sits" if b.shell <= 0.0 else "crack its shell with Lance, then hit it while it sits"
	var title := "%s   phase %d / 2: %s" % [b.foe_name, b.phase, hint]
	holder.draw_string(FONT, Vector2(x + 2, y - 10), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0, 0, 0, 0.8))
	holder.draw_string(FONT, Vector2(x, y - 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UiStyle.GOLD)
	holder.draw_rect(Rect2(x - 2, y - 2, w + 4, 24), Color(0.02, 0.025, 0.045, 0.9))
	holder.draw_rect(Rect2(x, y + 8, w * clampf(b.hp / b.hp_max, 0.0, 1.0), 12), Color(0.85, 0.28, 0.22))
	if b.shell_max > 0.0:
		holder.draw_rect(Rect2(x, y, w * clampf(b.shell / b.shell_max, 0.0, 1.0), 6), Color(0.7, 0.82, 0.95))
