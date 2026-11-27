class_name WayLamp
extends Node2D
## PROTOTYPE. An old keepers' WayLamp, one per region.
##   1. Reach it with your own light: a burning lantern whose light covers it, or a mirror beam.
##   2. Feed it fuel (Tuning.waylamp_fuel_need carried fuel, over as many trips as you like).
##   3. It kindles for Tuning.waylamp_kindle_sec seconds. Bold Wicklings swarm it; each one on it
##      undoes the kindling. Drive them off with your ward.
##   4. Lit, it holds its region: lanterns there stop burning and are refilled, no Wicklings come.
## What has been fed and which regions are held live in Progress (saved).

const LAMP_Y := -60.0   # the lamp cage, above the tile centre

var id := ""            # "hollow", "marsh", "ridge"
var region_id := 0
var title := ""
var text := ""          # inspection text (DRAFT until the owner approves STORY.md)
var kindling := false
var kindle_t := 0.0
var light: PointLight2D

func _ready() -> void:
	add_to_group("waylamp")
	add_to_group("light_source")
	z_index = 20
	light = PointLight2D.new()
	light.texture = LightTex.radial()
	light.color = Color(1.0, 0.82, 0.5)
	light.position = Vector2(0, LAMP_Y)
	light.enabled = false
	add_child(light)

# --- State ---------------------------------------------------------------------

func is_lit() -> bool:
	return Progress.is_settled(region_id)

func fuel_units() -> int:
	return int(Progress.waylamp_fuel.get(id, 0))

func needs() -> int:
	return Tuning.waylamp_fuel_need

func seconds_left() -> float:
	return maxf(0.0, Tuning.waylamp_kindle_sec - kindle_t)

## Your own light reaches it: a burning lantern's light covers it, or a mirror beam touches it.
## (The hand lamp doesn't count.)
func is_reached() -> bool:
	if is_lit():
		return true
	for l in get_tree().get_nodes_in_group("lantern"):
		if l.kind != "mirror" and l.is_lit() and l.global_position.distance_to(global_position) <= l.get_light_radius() * 0.95:
			return true
	for m in get_tree().get_nodes_in_group("mirror"):
		if m.beam_level_at(global_position) > 0.0:
			return true
	return false

func get_light_radius() -> float:
	if is_lit():
		return Tuning.waylamp_radius
	if kindling:
		return lerpf(48.0, 220.0, clampf(kindle_t / Tuning.waylamp_kindle_sec, 0.0, 1.0))
	return 0.0

# --- Actions ---------------------------------------------------------------------

## The keeper interacts. Returns what happened: held, not_reached, no_fuel, kindling, fed.
func feed() -> String:
	var note_id := "waylamp_" + id
	if not Progress.notes_read.has(note_id):
		Progress.notes_read[note_id] = true
		Story.tip("waylamp_seen")
		Progress.note_opened.emit(title, text + "\n\nReach it with your own light, then feed it %d fuel.\nWhile it kindles, the dark will come for it. Keep them off it.\nLit, it holds this whole region: its lanterns stop burning down, and nothing comes here." % needs())
		return "read"
	if is_lit():
		return "held"
	if not is_reached():
		Sfx.play("ui_error", -14.0)
		return "not_reached"
	if kindling:
		return "kindling"
	var give := mini(needs() - fuel_units(), Inventory.get_count("fuel"))
	if give <= 0:
		Sfx.play("ui_error", -14.0)
		return "no_fuel"
	Inventory.spend("fuel", give)
	Progress.waylamp_fuel[id] = fuel_units() + give
	Sfx.play("refuel", -8.0)
	if fuel_units() >= needs():
		start_kindling()
	return "fed"

func start_kindling() -> void:
	if kindling or is_lit():
		return
	kindling = true
	kindle_t = 0.0
	Sfx.play("relight", -6.0)
	Story.tip("kindle_attack")
	var spawner := get_tree().get_first_node_in_group("wickling_spawner")
	if spawner and Tuning.waylamp_swarm > 0:
		spawner.spawn_swarm(self, Tuning.waylamp_swarm)

## A Wickling on the WayLamp drinks the new flame.
func sap(seconds: float) -> void:
	kindle_t = maxf(0.0, kindle_t - seconds)

func _process(delta: float) -> void:
	if kindling:
		kindle_t += delta
		if kindle_t >= Tuning.waylamp_kindle_sec:
			kindling = false
			Sfx.play("unlock", -4.0)
			Progress.settle(region_id, FogGrid.REGION_NAMES[region_id])
	elif not is_lit() and fuel_units() >= needs() and is_reached():
		start_kindling()   # fed before a reload: carry on
	var r := get_light_radius()
	light.enabled = r > 0.0
	if r > 0.0:
		light.texture_scale = LightTex.scale_for(r)
		var flick := 0.25 if kindling else 0.05
		light.energy = (0.95 if is_lit() else 0.8) + sin(Time.get_ticks_msec() * 0.013) * flick
	queue_redraw()

func _draw() -> void:
	var lit := is_lit() or kindling
	Art.sprite(self, Art.placeholder("waylamp_lit.png" if lit else "waylamp_cold.png"), Vector2(0, 16))
	if kindling:
		# A ring that fills as it kindles.
		var k := clampf(kindle_t / Tuning.waylamp_kindle_sec, 0.0, 1.0)
		draw_arc(Vector2(0, LAMP_Y), 30.0, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color(1.0, 0.82, 0.48, 0.95), 3.0)
		draw_arc(Vector2(0, LAMP_Y), 30.0, 0.0, TAU, 40, Color(1.0, 0.82, 0.48, 0.2), 1.0)
	elif not is_lit() and fuel_units() > 0:
		# How much it has been fed.
		var f := float(fuel_units()) / float(needs())
		draw_rect(Rect2(-20, 22, 40, 5), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-20, 22, 40 * f, 5), Color(1.0, 0.7, 0.3))
