class_name EnemyPack
extends Node2D
## A fixed Hollow group that sleeps until the keeper approaches, then stays cleared.
## M1b: after a faint, a half-fought pack is whole and asleep again and keeps its dead (sleep_again, the faint
## rule). Asleep, it shows through the fog as its lure (GAME_PLAN §7): small pale eyes in pairs, one pair a member;
## a pack with a shelled elite shows one larger pair of eyes with a pale ring instead (the crook's guard is only that).

var id := ""
var count := 4
var spitwicks := 0
var elites := 0                 # shelled Wicklings in the pack
var level := 1                  # foe level of every member (HOLLOW_PACKS in main.gd; wick scales with the level gap)
var affixes: Array[String] = [] # M2: its elite's affixes (from kl_affix_min_level; main.gd HOLLOW_AFFIXES)
var wake_radius := -1.0         # px; below 0: Tuning.kl_pack_wake_radius (the first route packs wake closer)
var guard := false              # the small guard on the Post Lamp find (wakes at Tuning.kl_post_guard_wake_radius)
var awake := false
var dead_slots := {}            # member slots beaten before a faint: they stay dead (the faint rule)
var _pulse := 0.0

func _ready() -> void:
	add_to_group("enemy_pack")
	z_index = 4
	_pulse = float(hash(id) % 100) * 0.1   # packs don't blink in step

## Member slot i: a Spitwick, a shelled elite or a Wickling.
func slot_kind(i: int) -> String:
	if i < spitwicks:
		return "spitwick"
	return "elite" if i >= count - elites else "wickling"

## Members still to fight (not beaten before a faint).
func living_slots() -> int:
	return count - dead_slots.size()

func has_elite() -> bool:
	for i in count:
		if slot_kind(i) == "elite" and not dead_slots.has(i):
			return true
	return false

func _process(delta: float) -> void:
	if Progress.cleared.has("pack_" + id):
		visible = false
		return
	visible = true
	_pulse += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not awake and player and player.global_position.distance_to(global_position) <= wake_px():
		awake = true
		for i in count:
			if dead_slots.has(i):
				continue
			var foe: Foe
			match slot_kind(i):
				"spitwick":
					foe = Spitwick.new()
				_:
					var w := Wickling.new()
					w.elite = slot_kind(i) == "elite"
					if w.elite and level >= Tuning.kl_affix_min_level:
						w.affixes = affixes.duplicate()
					foe = w
			foe.pack_id = id
			foe.pack_slot = i
			foe.level = level
			foe.position = global_position + Vector2.from_angle(i * TAU / count) * (22.0 + i * 6.0)
			get_parent().add_child(foe)
	if awake:
		var alive := false
		for foe in get_tree().get_nodes_in_group("foe"):
			if foe.pack_id == id and not foe.is_queued_for_deletion():
				alive = true
				break
		if not alive:
			Progress.cleared["pack_" + id] = true
			awake = false
			visible = false
	queue_redraw()

## The faint rule: an awake, half-fought pack goes back to sleep. Its living members go (healed: they come back
## fresh when it wakes again); the ones already beaten stay dead. A cleared pack stays cleared.
func sleep_again() -> void:
	if not awake or Progress.cleared.has("pack_" + id):
		return
	var alive := {}
	for f in get_tree().get_nodes_in_group("foe"):
		if f.pack_id == id and not f.is_queued_for_deletion() and not f._dead:
			alive[f.pack_slot] = true
			FaintRule.vanish(f)
	for i in count:
		if not alive.has(i):
			dead_slots[i] = true
	awake = false
	if living_slots() <= 0:
		Progress.cleared["pack_" + id] = true

## How close the keeper must come to wake this pack (px).
func wake_px() -> float:
	if guard:
		return Tuning.kl_post_guard_wake_radius
	return wake_radius if wake_radius >= 0.0 else Tuning.kl_pack_wake_radius

## The lure's look: "elite" (one larger pair of eyes with a pale ring) or "pack" (small eyes in pairs).
func lure_kind() -> String:
	return "elite" if has_elite() else "pack"

func _draw() -> void:
	if awake:
		return
	var eye := Color(0.74, 0.88, 1.0)
	if lure_kind() == "elite":
		# One larger pair of eyes with a pale ring: something shelled sleeps here.
		var p := 0.5 + 0.5 * sin(_pulse * 1.3)
		draw_circle(Vector2.ZERO, 16.0, Color(0.43, 0.69, 0.91, 0.12 + 0.06 * p))
		draw_arc(Vector2.ZERO, 14.0 + p * 2.0, 0.0, TAU, 32, Color(0.64, 0.74, 0.83, 0.55 + 0.3 * p), 2.0)
		for s in [-1.0, 1.0]:
			draw_circle(Vector2(5.0 * s, -1.0), 3.0, Color(eye, 0.9))
			draw_circle(Vector2(5.0 * s, -1.0), 1.2, Color(1, 1, 1, 0.9))
		return
	# Small pale eyes in pairs, one pair a member (at most 4), each blinking now and then.
	var n := mini(living_slots(), 4)
	draw_circle(Vector2.ZERO, 22.0, Color(0.43, 0.69, 0.91, 0.05))
	for i in n:
		var off := Vector2(cos(i * 2.4) * 16.0, sin(i * 2.4) * 10.0) if i > 0 else Vector2.ZERO
		var blink := fmod(_pulse * 0.37 + i * 0.29, 1.0) < 0.06
		var a := 0.3 if blink else 0.75 + 0.2 * sin(_pulse * 2.0 + i)
		for s in [-1.0, 1.0]:
			draw_rect(Rect2(off + Vector2(4.0 * s - 1.5, -1.5), Vector2(3, 1 if blink else 3)), Color(eye, a))
