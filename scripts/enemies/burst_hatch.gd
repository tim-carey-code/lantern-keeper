class_name BurstHatch
extends Node2D
## A *Bursting* elite's last act (M2 affix, GAME_PLAN §8.1; ART_DIRECTION §4.3 "Planned attacks"): cold spawn
## glows where `count` Wicklings will rise, kl_affix_burst_tell after it dies; then they rise, fading in harmless
## for kl_hatch_fade. They are summoned (they drop nothing; a faint takes them away).

var level := 1
var count := 2
var _tell: Telegraph.Tell
var spawned: Array = []

func _ready() -> void:
	add_to_group("burst_hatch")
	_tell = Telegraph.begin(self, Telegraph.SPAWN, "wickling", maxf(Tuning.kl_affix_burst_tell, Tuning.kl_tell_min), false)
	_tell.radius = 12.0
	for i in count:
		_tell.points.append(global_position + Vector2.from_angle(TAU * float(i) / float(maxi(1, count)) + 0.6) * 26.0)
	Telegraph.arm(_tell, get_tree())

func _exit_tree() -> void:
	if _tell:
		_tell.finish()

func tell() -> Telegraph.Tell:
	return _tell

func _process(delta: float) -> void:
	if _tell == null:
		return
	_tell.tick(delta)
	if not _tell.done():
		return
	for p in _tell.points:
		var w := Wickling.new()
		w.summoned = true
		w.level = level
		w.position = p
		w.fade_in()
		get_parent().add_child(w)
		spawned.append(w)
	_tell.finish()
	_tell = null
	queue_free()
