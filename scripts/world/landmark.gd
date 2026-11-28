class_name Landmark
extends Node2D
## Something the light reveals that tells a piece of the valley's story.
## Interact to read it. Some landmarks unlock a lantern type (the pumphouse); some are upgrades
## you take (a keeper's satchel: carry more scrap; a lamp glass: the hand lamp reaches 12 px further and holds
## 0.1 more charge, M1b).

const REVEAL_BELOW := 0.35

var id := ""
var title := ""
var text := ""
var look := "stone"        # stone, ledger, frames, chalk, pumphouse
var unlock_kind := ""
var upgrade := ""          # "carry" or "lamp": taken the first time it is read
var scenery := false       # just part of the scene: nothing to read, no glow, not a target
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
		# The button that opens the lantern list on the device in use (M1a: Y is a skill slot; the list is D-pad right).
		body += "\n\nNew lantern: %s. Pick it in the lantern list (%s)." % [Lantern.display(unlock_kind), InputHint.key("build_menu")]
	if upgrade != "" and Progress.take_upgrade(id, upgrade):
		Sfx.play("unlock", -6.0)
		if upgrade == "carry":
			body += "\n\nYou can carry %d scrap now." % Inventory.carry_limit   # DRAFT (M1b), was "%d of each"
		else:
			body += "\n\nYour hand lamp reaches further and holds more charge."   # DRAFT (M1b; STORY §15)
	Progress.note_opened.emit(title, body)
	queue_redraw()

func is_taken() -> bool:
	return upgrade != "" and Progress.upgrades.has(id)

func _process(_delta: float) -> void:
	var v := is_revealed()
	if v != visible:
		visible = v
	if scenery:
		glow.enabled = false
		return
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
		"post":
			Art.sprite(self, Art.placeholder("post_lamp_cold.png"), Vector2(0, 14))
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
		"workshop":
			var o := Vector2(-1.5 * t, -1.5 * t)
			for i in 3:
				Art.cell(self, Art.TOWN, Art.PUMP_ROOF[i], o + Vector2(i * t, 0))
				Art.cell(self, Art.TOWN, Art.HUT_WALL[i], o + Vector2(i * t, t))
			# A kiln glowing faintly beside it.
			draw_rect(Rect2(1.6 * t, -10, 14, 22), Color(0.29, 0.42, 0.58))
			draw_rect(Rect2(1.6 * t + 4, 0, 6, 6), Color(0.85, 0.47, 0.17, 0.8))
		"station":
			# A tall stone post with a mirror on top.
			Art.cell_at_foot(self, Art.DUNGEON, Art.STONE_WALL, Vector2(0, 16))
			Art.cell_at_foot(self, Art.DUNGEON, Art.STONE_WALL, Vector2(0, -16))
			draw_colored_polygon(PackedVector2Array([Vector2(-10, -50), Vector2(-4, -64), Vector2(12, -58), Vector2(6, -44)]), Color(0.64, 0.74, 0.83))
			draw_line(Vector2(-2, -60), Vector2(6, -50), Color(0.08, 0.1, 0.18), 1.0)   # the crack
		"letter":
			# A sheet of paper pinned to the hut door, just above.
			draw_rect(Rect2(-5, -30, 10, 12), Color(0.96, 0.95, 0.88))
			draw_rect(Rect2(-1, -31, 2, 2), Color(0.35, 0.2, 0.14))
			draw_line(Vector2(-3, -26), Vector2(3, -26), Color(0.29, 0.42, 0.58), 1.0)
			draw_line(Vector2(-3, -23), Vector2(2, -23), Color(0.29, 0.42, 0.58), 1.0)
			draw_line(Vector2(-3, -20), Vector2(3, -20), Color(0.29, 0.42, 0.58), 1.0)
		"rack":
			draw_rect(Rect2(-16, -10, 32, 3), Color(0.61, 0.29, 0.13))
			for i in 5:
				var hx := -12 + i * 6
				draw_line(Vector2(hx, -7), Vector2(hx, -3), Color(0.35, 0.16, 0.11), 2.0)
				if i != 4:
					draw_rect(Rect2(hx - 2, -3, 4, 6), Color(0.29, 0.42, 0.58))
		"cairn":
			draw_colored_polygon(PackedVector2Array([Vector2(-11, 10), Vector2(-9, 2), Vector2(9, 2), Vector2(11, 10)]), Color(0.29, 0.42, 0.58))
			draw_colored_polygon(PackedVector2Array([Vector2(-7, 2), Vector2(-5, -6), Vector2(5, -6), Vector2(7, 2)]), Color(0.43, 0.56, 0.7))
			draw_colored_polygon(PackedVector2Array([Vector2(-4, -6), Vector2(-2, -12), Vector2(3, -12), Vector2(4, -6)]), Color(0.64, 0.74, 0.83))
			draw_line(Vector2(0, -10), Vector2(0, -16), Color(0.96, 0.95, 0.88), 1.0)
			draw_line(Vector2(0, -16), Vector2(-2, -14), Color(0.96, 0.95, 0.88), 1.0)
			draw_line(Vector2(0, -16), Vector2(2, -14), Color(0.96, 0.95, 0.88), 1.0)
		"steps":
			for i in 4:
				draw_rect(Rect2(-14 + i * 2, -10 + i * 6, 28 - i * 4, 5), Color(0.43, 0.56, 0.7).darkened(i * 0.15))
		"coat":
			draw_colored_polygon(PackedVector2Array([Vector2(-10, 10), Vector2(-7, -8), Vector2(0, -12), Vector2(7, -8), Vector2(10, 10)]), Color(0.36, 0.2, 0.14))
			draw_rect(Rect2(-2, -6, 4, 14), Color(0.21, 0.31, 0.47))
		"satchel", "lampglass":
			# Taken: what is left looks dull and empty.
			var tint := Color(0.42, 0.42, 0.5, 0.85) if is_taken() else Color.WHITE
			Art.sprite(self, Art.placeholder("satchel.png" if look == "satchel" else "lamp_glass.png"), Vector2(0, 14), tint)
		"lens":
			draw_arc(Vector2(-3, 0), 11.0, PI * 0.6, PI * 1.45, 16, Color(0.64, 0.74, 0.83), 3.0)
			draw_arc(Vector2(3, 2), 11.0, -PI * 0.45, PI * 0.4, 16, Color(0.64, 0.74, 0.83), 3.0)
			draw_rect(Rect2(-12, 10, 24, 4), Color(0.36, 0.2, 0.14))
		_:
			Art.cell_at_foot(self, Art.DUNGEON, Art.GRAVESTONE, Vector2(0, 14))
	if not is_read() and not scenery:
		var top := Vector2(0, -66 if look in ["pumphouse", "workshop"] else (-74 if look == "station" else -40))
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
		draw_circle(top, 4.0, Color(1.0, 0.85, 0.4))
		draw_arc(top, 7.0 + pulse * 4.0, 0.0, TAU, 20, Color(1.0, 0.85, 0.4, 0.8 - pulse * 0.6), 1.5)
