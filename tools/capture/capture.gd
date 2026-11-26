extends Node
## Visual check without a screen: loads the game, sets up a view, runs a few
## seconds, and lets Godot's movie writer record frames. Run on a virtual display:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --audio-driver Dummy \
##     --write-movie ~/.cache/openclaw/project-scratch/shots/frame.png --fixed-fps 30 \
##     res://tools/capture/capture.tscn -- start
## Views (after "--"): start, marsh, cold, edge, map. The last frame is the one to look at.

var main: Node
var frame := 0
var view := "start"

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		view = args[0]
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _lantern(p: Vector2, kind: String = "post", fuel: float = -1.0) -> Lantern:
	var l := Lantern.new()
	l.kind = kind
	l.fuel = fuel
	l.position = main.fog.tile_center(main.fog.tile_of(p))
	main.get_node("Lanterns").add_child(l)
	return l

func _process(_delta: float) -> void:
	frame += 1
	if frame == 2:
		var wind: Wind = main.get_node("Wind")
		wind.force(Wind.State.CALM, Vector2i.RIGHT, 9999.0)
		var s: Vector2 = main.start
		match view:
			"marsh":
				var pump: Vector2 = main.fog.tile_center(Vector2i(100, 32))
				main.player.position = pump + Vector2(-40, 40)
				_lantern(main.fog.tile_center(Vector2i(92, 32)))
				_lantern(main.fog.tile_center(Vector2i(97, 32)), "reservoir")
				_lantern(main.fog.tile_center(Vector2i(88, 36)))
			"cold":
				_lantern(s + Vector2(-160, 64), "post", 0.0)
				_lantern(s + Vector2(200, 120), "post", 10.0)
				main.player.position = s + Vector2(-40, 60)
			"edge":
				main.player.position = main.fog.tile_center(Vector2i(8, 32))
				_lantern(main.fog.tile_center(Vector2i(9, 30)))
			"map":
				_lantern(s + Vector2(-160, 64))
				for i in 60:
					main.fog.step(0.1)
			_:
				_lantern(s + Vector2(-140, 90))
				_lantern(s + Vector2(60, 150))
				main.player.position = s + Vector2(-20, 30)
		for i in 30:
			main.fog.step(0.1)   # let the light push the fog back before the shot
	if frame == 6 and view == "map":
		main.get_node("MapScreen").toggle()
	if frame >= 45:
		get_tree().quit()
