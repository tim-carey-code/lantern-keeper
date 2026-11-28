extends Node
## Autoload "Inventory": what the keeper carries. M1b: scrap is the one material (fuel and glass are cut).

signal changed

var carry_limit := 30
var counts := {"scrap": 0}

func reset() -> void:
	counts = {"scrap": 0}
	changed.emit()

func get_count(kind: String) -> int:
	return counts.get(kind, 0)

func space(kind: String) -> int:
	return carry_limit - get_count(kind)

## Adds up to n, limited by carry space. Returns how many were added.
func add(kind: String, n: int) -> int:
	var added := clampi(n, 0, space(kind))
	counts[kind] = get_count(kind) + added
	changed.emit()
	return added

func spend(kind: String, n: int) -> bool:
	if get_count(kind) < n:
		return false
	counts[kind] = get_count(kind) - n
	changed.emit()
	return true
