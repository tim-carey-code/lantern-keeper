class_name EnemyPack
extends Node2D
## A fixed Hollow group that sleeps until the keeper approaches, then stays cleared.

var id := ""
var count := 4
var spitwicks := 0
var elites := 0                 # shelled Wicklings in the pack
var awake := false
var _pulse := 0.0

func _ready() -> void:
	add_to_group("enemy_pack")
	z_index = 4

func _process(delta: float) -> void:
	if Progress.cleared.has("pack_" + id):
		visible = false
		return
	visible = true
	_pulse += delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not awake and player and player.global_position.distance_to(global_position) <= Tuning.kl_pack_wake_radius:
		awake = true
		for i in count:
			var foe: Foe
			if i < spitwicks:
				foe = Spitwick.new()
			else:
				var w := Wickling.new()
				w.elite = i >= count - elites
				foe = w
			foe.pack_id = id
			foe.wick_key = "wick_%s_%d" % [id, i]
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

func _draw() -> void:
	if awake:
		return
	var pulse := 0.5 + 0.5 * sin(_pulse * 2.4)
	draw_circle(Vector2.ZERO, 7.0 + pulse * 3.0, Color(0.43, 0.69, 0.91, 0.45))
	draw_circle(Vector2.ZERO, 3.0, Color(0.74, 0.88, 1.0, 0.9))
