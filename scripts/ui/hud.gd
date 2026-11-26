extends CanvasLayer
## Minimal M1 HUD: counts, nearby lantern fuel, controls hint.

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
	var near := ""
	if player:
		var n = player.nearest_lantern()
		if n:
			near = "\nNearby lantern: %d%% fuel" % roundi(n.fuel_frac() * 100.0)
	label.text = "Lanterns lit: %d / %d    Fuel poured: %d    Valley seen: %d%%%s\n[Space / X] place   [E / A] refuel   [Q / B] pick up   [F1 / Select] tuning" % [
		lit, lamps.size(), roundi(player.fuel_poured if player else 0.0),
		roundi(fog.revealed_fraction() * 100.0) if fog else 0, near]
