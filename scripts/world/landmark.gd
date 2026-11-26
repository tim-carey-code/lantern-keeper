class_name Landmark
extends Node2D
## Something the light reveals that tells a piece of the valley's story.
## Interact to read it. Some landmarks unlock a lantern type (the pumphouse).

const REVEAL_BELOW := 0.35

var id := ""
var title := ""
var text := ""
var look := "stone"        # stone, ledger, frames, chalk, pumphouse
var unlock_kind := ""
var glow: PointLight2D
var _spotted := false

func _ready() -> void:
	add_to_group("landmark")
	z_index = 15
	glow = PointLight2D.new()
	glow.texture = LightTex.radial()
	glow.texture_scale = LightTex.scale_for(56.0)
	glow.color = Color(1.0, 0.8, 0.45)
	glow.energy = 0.7
	glow.enabled = false
	add_child(glow)

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func is_revealed() -> bool:
	var fog := _fog()
	return fog != null and fog.density_at(global_position) < REVEAL_BELOW

func is_read() -> bool:
	return Progress.notes_read.has(id)

func display_name() -> String:
	return title

func activate() -> void:
	Progress.notes_read[id] = true
	var body := text
	if unlock_kind != "" and not Progress.is_unlocked(unlock_kind):
		Progress.unlock(unlock_kind)
		body += "\n\nNew lantern: %s. Pick it in the lantern list (Tab / Y)." % Lantern.display(unlock_kind)
	Progress.note_opened.emit(title, body)
	queue_redraw()

func _process(_delta: float) -> void:
	var v := is_revealed()
	if v != visible:
		visible = v
	if v and not _spotted:
		_spotted = true
		Progress.landmark_spotted.emit(title)
	# Unread landmarks glow and pulse so they stand out from the scenery.
	glow.enabled = v and not is_read()
	if glow.enabled:
		glow.energy = 0.35 + 0.2 * sin(Time.get_ticks_msec() * 0.004)
	if v:
		queue_redraw()

func _draw() -> void:
	var t := float(FogGrid.TILE)
	match look:
		"ledger":
			Art.cell_at_foot(self, Art.TOWN, Art.SIGN, Vector2(0, 14))
		"frames":
			for i in 3:
				Art.sprite(self, Art.placeholder("post_lamp_cold.png"), Vector2(-26 + i * 26, 16), Color(0.8, 0.8, 0.85))
		"chalk":
			Art.cell_at_foot(self, Art.DUNGEON, Art.STONE_WALL, Vector2(0, 16))
			draw_circle(Vector2(-7, -6), 4.0, Color(0.96, 0.95, 0.88))
			draw_circle(Vector2(7, -6), 4.0, Color(0.05, 0.06, 0.1))
		"pumphouse":
			var origin := Vector2(-1.5 * t, -1.5 * t)
			for i in 3:
				Art.cell(self, Art.TOWN, Art.PUMP_ROOF[i], origin + Vector2(i * t, 0))
				Art.cell(self, Art.TOWN, Art.PUMP_WALL[i], origin + Vector2(i * t, t))
			draw_arc(Vector2(1.9 * t, 0), 11.0, 0.0, TAU, 20, Color(0.42, 0.56, 0.7), 3.0)
			draw_line(Vector2(1.9 * t - 11, 0), Vector2(1.9 * t + 11, 0), Color(0.42, 0.56, 0.7), 2.0)
		_:
			Art.cell_at_foot(self, Art.DUNGEON, Art.GRAVESTONE, Vector2(0, 14))
	if not is_read():
		var top := Vector2(0, -66 if look == "pumphouse" else -40)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
		draw_circle(top, 4.0, Color(1.0, 0.85, 0.4))
		draw_arc(top, 7.0 + pulse * 4.0, 0.0, TAU, 20, Color(1.0, 0.85, 0.4, 0.8 - pulse * 0.6), 1.5)
