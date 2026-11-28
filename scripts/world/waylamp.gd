class_name WayLamp
extends Node2D
## An old keepers' WayLamp, one per region (M1b, GAME_PLAN §6, §12: lit by touch; the guardian is the cost).
##   1. The first touch (A / E) reads its note.
##   2. The next touch lights it with your flame: it starts to kindle.
##      - The Hollow's (guardian_fight): the Ashbrood wakes. It broods over the WayLamp's last ember, a small amber
##        glow in the cold bowl (the lamp's light, not the creature's; DECISIONS 2026-11-27). Kill it and the
##        WayLamp takes the ember back: the ember rises into the lamp as it lights (take_back_ember), and the
##        region is held.
##      - The others (until their guardians are built, M5-M6): a hold fight. It kindles for
##        Tuning.waylamp_kindle_sec; bold Wicklings swarm it, and each one on it undoes the kindling.
##   3. Lit, it holds its region: no Wicklings come, you can rest and travel here.
## Which regions are held lives in Progress (saved). Nothing is fed: M1b cut fuel.

const LAMP_Y := -60.0   # the lamp cage, above the tile centre
## Where the last ember lies: in the bowl at the Ashbrood's feet, on the sprite's own small bowl ember, so there is
## one ember (M1c; owner, M1b playtest: the ember in the cage "was right above the yellow quest arrow"). Ashbrood.EMBER_AT.
const EMBER_BOWL := Vector2(4, 12)
const EMBER_RISE_SEC := 1.4           # the ember rises into the lamp as it lights (take_back_ember)

## DRAFT (M1b; STORY §15): the lines under each WayLamp's note. The approved footer said "Feed it 15 fuel." etc.
const NOTE_TOUCH := "Touch your flame to it to light it."
const NOTE_GUARDIAN := "Something broods in its bowl, over one last ember. It will fight for it."
const NOTE_HOLD := "While it kindles, the dark will come for it. Keep them off it."
const NOTE_HELD := "Lit, it holds this whole region: nothing comes here, and you can rest by it."

var id := ""            # "hollow", "marsh", "ridge"
var guardian_fight := false  # the Hollow: lighting it wakes the Ashbrood instead of a hold fight
var region_id := 0
var title := ""
var text := ""          # inspection text (STORY.md §11)
var kindling := false
var kindle_t := 0.0
var light: PointLight2D
var _guardian: Ashbrood
var ember_rise_t := 0.0   # > 0: the ember is rising into the lamp (after the guardian's kill)
var _ember: Node2D        # the ember's glow, on the fog layer so it shows through the dark

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

func seconds_left() -> float:
	return maxf(0.0, Tuning.waylamp_kindle_sec - kindle_t)

## Its guardian is awake and not yet beaten (the ember is in its bowl).
func guardian_awake() -> bool:
	return kindling and guardian_fight and is_instance_valid(_guardian) and not _guardian.is_queued_for_deletion()

func guardian() -> Ashbrood:
	return _guardian if is_instance_valid(_guardian) else null

func get_light_radius() -> float:
	if is_lit():
		return Tuning.waylamp_radius
	if kindling:
		if guardian_fight:
			return 180.0
		return lerpf(48.0, 220.0, clampf(kindle_t / Tuning.waylamp_kindle_sec, 0.0, 1.0))
	return 0.0

## The note the first touch shows: the inscription, then what to do.
func note_text() -> String:
	var how := NOTE_GUARDIAN if guardian_fight else NOTE_HOLD
	return text + "\n\n" + NOTE_TOUCH + "\n" + how + "\n" + NOTE_HELD

# --- Actions ---------------------------------------------------------------------

## The keeper touches it (A / E). Returns what happened: read, held, kindling, lit.
func touch() -> String:
	var note_id := "waylamp_" + id
	if not Progress.notes_read.has(note_id):
		Progress.notes_read[note_id] = true
		Story.tip("waylamp_seen")
		Progress.note_opened.emit(title, note_text())
		return "read"
	if is_lit():
		return "held"
	if kindling:
		return "kindling"
	start_kindling()
	return "lit"

func start_kindling() -> void:
	if kindling or is_lit():
		return
	kindling = true
	kindle_t = 0.0
	Sfx.play("relight", -6.0)
	var spawner := get_tree().get_first_node_in_group("wickling_spawner")
	if guardian_fight:
		_guardian = Ashbrood.new()
		_guardian.position = global_position
		_guardian.waylamp = self
		if spawner:
			spawner.add_child(_guardian)
		_show_ember()
	else:
		Story.tip("kindle_attack")
		if spawner and Tuning.waylamp_swarm > 0:
			spawner.spawn_swarm(self, Tuning.waylamp_swarm)

## A Wickling on the WayLamp drinks the new flame.
func sap(seconds: float) -> void:
	kindle_t = maxf(0.0, kindle_t - seconds)

## The guardian is dead: the WayLamp takes its ember back, and the ember rises into the lamp as it lights.
func take_back_ember() -> void:
	ember_rise_t = EMBER_RISE_SEC
	_show_ember()
	Sfx.play("relight", -4.0)

func _show_ember() -> void:
	if _ember and is_instance_valid(_ember):
		return
	var layer := get_tree().get_first_node_in_group("wickling_spawner")
	if layer == null:
		return
	_ember = WayLampEmber.new()
	_ember.waylamp = self
	_ember.position = global_position
	layer.add_child(_ember)

## 0 while the ember waits in the bowl, rising to 1 as it reaches the lamp and the lamp lights.
func ember_rise() -> float:
	if ember_rise_t <= 0.0:
		return 1.0 if is_lit() else 0.0
	return 1.0 - ember_rise_t / EMBER_RISE_SEC

## The ember shows while the guardian broods over it, and while it rises into the lamp.
func ember_showing() -> bool:
	return guardian_awake() or ember_rise_t > 0.0

func _process(delta: float) -> void:
	ember_rise_t = maxf(0.0, ember_rise_t - delta)
	if kindling:
		if guardian_fight:
			if is_lit():
				kindling = false
		else:
			kindle_t += delta
			if kindle_t >= Tuning.waylamp_kindle_sec:
				kindling = false
				Sfx.play("unlock", -4.0)
				Progress.settle(region_id, FogGrid.REGION_NAMES[region_id])
	var r := get_light_radius()
	light.enabled = r > 0.0
	if r > 0.0:
		light.texture_scale = LightTex.scale_for(r)
		var flick := 0.25 if kindling else 0.05
		var energy := (0.95 if is_lit() else 0.8) + sin(Time.get_ticks_msec() * 0.013) * flick
		if guardian_awake():
			energy = 0.45 + sin(Time.get_ticks_msec() * 0.009) * 0.08   # only its last ember: a low glow
		elif ember_rise_t > 0.0:
			energy *= lerpf(0.35, 1.0, ember_rise())   # it lights as the ember rises
		light.energy = energy
	queue_redraw()

func _draw() -> void:
	# While the guardian broods over it, the bowl is still cold: only the ember (drawn on the fog layer) glows.
	var lit := (is_lit() and ember_rise_t <= 0.0) or (kindling and not guardian_awake())
	Art.sprite(self, Art.placeholder("waylamp_lit.png" if lit else "waylamp_cold.png"), Vector2(0, 16))
	if kindling and not guardian_fight:
		# A ring that fills as it kindles.
		var k := clampf(kindle_t / Tuning.waylamp_kindle_sec, 0.0, 1.0)
		draw_arc(Vector2(0, LAMP_Y), 30.0, -PI / 2.0, -PI / 2.0 + TAU * k, 40, Color(1.0, 0.82, 0.48, 0.95), 3.0)
		draw_arc(Vector2(0, LAMP_Y), 30.0, 0.0, TAU, 40, Color(1.0, 0.82, 0.48, 0.2), 1.0)
