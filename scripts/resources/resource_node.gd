class_name ResourceNode
extends Node2D
## A gatherable spot: a dead tree (fuel/resin) or a ruin pile (scrap).
## Only visible and gatherable on lit ground. Regrows slowly while lit.
## The hut woodpile (always_regrow) regrows even in the dark, so the game can never soft-lock.

const REVEAL_BELOW := 0.35

var kind := "fuel"
var amount := 4
var max_amount := 6
var regrow_sec := 60.0
var always_regrow := false
var label := ""            # display name override, e.g. "Peat"
var _regrow_acc := 0.0

func _ready() -> void:
	add_to_group("resource")
	z_index = 15

func _fog() -> FogGrid:
	return get_tree().get_first_node_in_group("fog_grid") as FogGrid

func is_revealed() -> bool:
	var fog := _fog()
	return fog != null and fog.density_at(global_position) < REVEAL_BELOW

func can_gather() -> bool:
	return amount > 0 and is_revealed()

func take() -> bool:
	if amount <= 0:
		return false
	amount -= 1
	queue_redraw()
	return true

func display_name() -> String:
	if always_regrow:
		return "Woodpile"
	if label != "":
		return label
	if kind == "glass":
		return "Glass shards"
	return "Dead tree (resin)" if kind == "fuel" else "Ruin (scrap)"

func _process(delta: float) -> void:
	visible = is_revealed()
	if amount >= max_amount:
		_regrow_acc = 0.0
		return
	if always_regrow or is_revealed():
		_regrow_acc += delta
		if _regrow_acc >= regrow_sec:
			_regrow_acc = 0.0
			amount += 1
			queue_redraw()

func _draw() -> void:
	var mod := Color(1, 1, 1, 1.0 if amount > 0 else 0.45)
	if always_regrow:
		Art.cell_at_foot(self, Art.TOWN, Art.LOG, Vector2(0, 14), mod)
	elif kind == "fuel" and label == "Peat":
		Art.sprite(self, Art.placeholder("peat.png"), Vector2(0, 14), mod)
	elif kind == "fuel":
		Art.sprite(self, Art.placeholder("dead_tree.png"), Vector2(0, 16), mod)
	elif kind == "glass":
		Art.sprite(self, Art.placeholder("glass.png"), Vector2(0, 14), mod)
	else:
		Art.sprite(self, Art.placeholder("scrap_pile.png"), Vector2(0, 14), mod)
	# How much is left: little amber pips.
	var pip := Color(1.0, 0.82, 0.48)
	for i in amount:
		draw_rect(Rect2(-amount * 2.5 + i * 5.0, 18, 3, 3), pip)
