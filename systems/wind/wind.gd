class_name Wind
extends Node
## Gusts from one direction at a time: calm -> warning (5 s) -> gust (8 s) -> calm.
## During a gust, lanterns with no rock 1-2 tiles upwind burn faster and shrink,
## and fog creeps back faster. `direction` is where the wind blows TO.

signal state_changed(state: State)

enum State { CALM, WARNING, GUST }

const DIRS := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
const FROM := {Vector2i.RIGHT: "west", Vector2i.LEFT: "east", Vector2i.DOWN: "north", Vector2i.UP: "south"}

var state := State.CALM
var direction := Vector2i.RIGHT
var timer := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("wind")
	rng.randomize()
	timer = rng.randf_range(Tuning.wind_calm_min, Tuning.wind_calm_max)

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	_advance()
	state_changed.emit(state)

func _advance() -> void:
	match state:
		State.CALM:
			state = State.WARNING
			direction = DIRS[rng.randi() % DIRS.size()]
			timer = Tuning.wind_warning_sec
		State.WARNING:
			state = State.GUST
			timer = Tuning.wind_gust_sec
		State.GUST:
			state = State.CALM
			timer = rng.randf_range(Tuning.wind_calm_min, Tuning.wind_calm_max)

func is_gusting() -> bool:
	return state == State.GUST

## 0 when calm, rises during the warning, 1 during a gust (used for sound).
func gust_level() -> float:
	match state:
		State.GUST:
			return 1.0
		State.WARNING:
			return clampf(1.0 - timer / Tuning.wind_warning_sec, 0.0, 1.0) * 0.6
	return 0.0

func from_name() -> String:
	return FROM.get(direction, "somewhere")

func status_text() -> String:
	match state:
		State.WARNING:
			return "Wind rising from the %s..." % from_name()
		State.GUST:
			return "Gust from the %s: exposed lanterns burn faster" % from_name()
	return ""

## Tests and debugging.
func force(s: State, dir: Vector2i = Vector2i.RIGHT, secs: float = 999.0) -> void:
	state = s
	direction = dir
	timer = secs
	state_changed.emit(state)
