extends CanvasLayer
## Lantern list with costs. Tab / gamepad Y toggles. Only the Post Lamp exists in M2;
## the others are shown locked so the player knows more are out there.

var panel: PanelContainer
var body: Label

func _ready() -> void:
	layer = 6
	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -330
	panel.offset_top = 16
	panel.offset_right = -16
	add_child(panel)
	body = Label.new()
	panel.add_child(body)
	panel.visible = false

func _process(_delta: float) -> void:
	if not panel.visible:
		return
	var scrap := Inventory.get_count("scrap")
	body.text = "\n".join([
		"Lanterns   (Tab / Y to close)",
		"",
		"> Post Lamp     %d scrap   %s" % [Tuning.post_lamp_cost_scrap, "ready" if scrap >= Tuning.post_lamp_cost_scrap else "need more scrap"],
		"   Burns fuel. Light shrinks as it runs low.",
		"   Pick up returns half the scrap and its fuel.",
		"",
		"  ???   found somewhere in the valley",
		"  ???   found somewhere in the valley",
		"  ???   found somewhere in the valley",
	])

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		panel.visible = not panel.visible
		get_viewport().set_input_as_handled()
