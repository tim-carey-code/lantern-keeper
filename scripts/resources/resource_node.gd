class_name ResourceNode
extends Node2D
## A scrap pile: a ruin, a side cache or the pile beside the hut (M1b, GAME_PLAN §5: scrap is the one material).
## A one-off pickup: one press of A / E takes all of it that you can carry, and an empty pile is gone for good.
## Only visible and takeable on lit ground. (Fuel and glass are cut: no dead trees, peat, glass shards or
## woodpile to gather; the woodpile by the hut is scenery.)

const REVEAL_BELOW := 0.35

var kind := "scrap"
var amount := 4
var label := ""            # display name override, e.g. "Old cache"

func _ready() -> void:
	add_to_group("resource")
	z_index = 15

var _fog_ref: FogGrid

func _fog() -> FogGrid:
	if _fog_ref == null or not is_instance_valid(_fog_ref):
		_fog_ref = get_tree().get_first_node_in_group("fog_grid") as FogGrid
	return _fog_ref

func is_revealed() -> bool:
	var fog := _fog()
	return fog != null and fog.density_at(global_position) < REVEAL_BELOW

func can_take() -> bool:
	return amount > 0 and is_revealed()

## Takes as much as the keeper can carry in one go. Returns how much; an emptied pile goes.
func take_all() -> int:
	if amount <= 0:
		return 0
	var got := Inventory.add(kind, amount)
	amount -= got
	queue_redraw()
	if amount <= 0:
		remove_from_group("resource")
		queue_free()
	return got

func display_name() -> String:
	if label != "":
		return label
	return "Ruin (scrap)"

func _process(_delta: float) -> void:
	visible = is_revealed()

func _draw() -> void:
	Art.sprite(self, Art.placeholder("scrap_pile.png"), Vector2(0, 14))
	# How much is there: little pale pips.
	var pip := Color(0.75, 0.82, 0.92)
	var n := mini(amount, 10)
	for i in n:
		draw_rect(Rect2(-n * 2.5 + i * 5.0, 18, 3, 3), pip)
