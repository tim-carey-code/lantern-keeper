extends CanvasLayer
## M2 HUD: carried resources, hand lamp, what is nearby, why you can't build, controls.

var label: Label

func _ready() -> void:
	layer = 5
	label = Label.new()
	label.position = Vector2(16, 12)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(label)

func _process(_delta: float) -> void:
	var lamps := get_tree().get_nodes_in_group("lantern")
	var lit := lamps.filter(func(l): return l.is_lit()).size()
	var fog := get_tree().get_first_node_in_group("fog_grid") as FogGrid
	var player = get_tree().get_first_node_in_group("player")
	if player == null or fog == null:
		return
	var lim := Inventory.carry_limit
	var lines: Array[String] = []
	lines.append("Fuel %d/%d    Scrap %d/%d    Hand lamp %d%%" % [
		Inventory.get_count("fuel"), lim, Inventory.get_count("scrap"), lim, roundi(player.lamp_charge * 100.0)])
	lines.append("Lanterns lit %d/%d    Hollow seen %d%%" % [lit, lamps.size(), roundi(fog.revealed_fraction() * 100.0)])
	var t = player.nearest_target()
	if t is PostLamp:
		var state := "%d%% fuel" % roundi(t.fuel_frac() * 100.0) if t.is_lit() else "cold"
		lines.append("Lantern (%s): [E / A] refuel   [Q / B] pick up" % state)
	elif t is ResourceNode:
		var verb := "gathering..." if player.is_gathering() else "hold [E / A] to gather"
		lines.append("%s, %d left: %s" % [t.display_name(), t.amount, verb])
	var reason: String = player.place_block_reason(player.place_pos())
	if reason != "" and reason != "too close to a lantern":
		lines.append("Build here: %s" % reason)
	lines.append("[Space / X] build Post Lamp (%d scrap)   [Tab / Y] lanterns   [F1 / Select] tuning" % Tuning.post_lamp_cost_scrap)
	label.text = "\n".join(lines)
