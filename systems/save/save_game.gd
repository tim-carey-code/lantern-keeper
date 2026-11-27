extends Node
## Autoload "SaveGame": one save slot (JSON) plus autosave.
## Saved: keeper (position, warmth, hand lamp), inventory, progress (unlocks, selected
## lantern, regions found, notes read), every lantern (kind, position, fuel), every
## resource node (including piles dropped when fainting), and the fog map (density and
## what has been seen). Not saved: Wicklings, embers and wind (they come back on their own).
## File: user://save.json  (on Linux: ~/.local/share/godot/app_userdata/Lantern Keeper/)

const VERSION := 2   # 2: the map grew north for the Windward Ridge; older saves start fresh
const AUTOSAVE_SEC := 60.0

var path := "user://save.json"
var skip_load_once := false      # set by "New game" so the next start ignores the save
var _autosave_t := AUTOSAVE_SEC

func has_save() -> bool:
	return FileAccess.file_exists(path)

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _process(delta: float) -> void:
	_autosave_t -= delta
	if _autosave_t <= 0.0:
		_autosave_t = AUTOSAVE_SEC
		var main := get_tree().get_first_node_in_group("main")
		if main and not Tuning.ui_open:
			save(main)

# --- Save ----------------------------------------------------------------------

func save(main: Node) -> bool:
	var fog: FogGrid = main.fog
	var player = main.player
	var data := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"player": {"x": player.global_position.x, "y": player.global_position.y,
			"warmth": player.warmth, "lamp_charge": player.lamp_charge, "faints": player.faints},
		"inventory": Inventory.counts.duplicate(),
		"progress": {
			"unlocks": Progress.unlocks.duplicate(),
			"selected": Progress.selected,
			"upgrades": Progress.upgrades.duplicate(),
			"regions_seen": Progress.regions_seen.keys(),
			"notes_read": Progress.notes_read.keys(),
		},
		"lanterns": [],
		"resources": [],
		"story": Story.to_dict(),
		"fog": {"cols": fog.cols, "rows": fog.rows, "density": _pack_density(fog.density),
			"remembered": Marshalls.raw_to_base64(fog.remembered)},
	}
	for l in get_tree().get_nodes_in_group("lantern"):
		data["lanterns"].append({"kind": l.kind, "x": l.position.x, "y": l.position.y, "fuel": l.fuel, "dir": l.mirror_dir})
	for r in get_tree().get_nodes_in_group("resource"):
		data["resources"].append({"kind": r.kind, "label": r.label, "x": r.position.x, "y": r.position.y,
			"amount": r.amount, "max": r.max_amount, "regrow": r.regrow_sec, "always": r.always_regrow})
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save: %s" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

func _pack_density(d: PackedFloat32Array) -> String:
	var b := PackedByteArray()
	b.resize(d.size())
	for i in d.size():
		b[i] = int(clampf(d[i], 0.0, 1.0) * 255.0)
	return Marshalls.raw_to_base64(b)

# --- Load ----------------------------------------------------------------------

## Reads the save into an already-generated world. Returns false if there is no usable save.
func load_into(main: Node) -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) != VERSION:
		push_warning("Save file is missing or from another version; starting fresh.")
		return false
	var fog: FogGrid = main.fog
	var fd: Dictionary = data["fog"]
	if int(fd["cols"]) != fog.cols or int(fd["rows"]) != fog.rows:
		push_warning("Save is for a different map size; starting fresh.")
		return false
	# Fog map.
	# (Packed arrays are values: edit local copies, then assign back once.)
	var dens := Marshalls.base64_to_raw(fd["density"])
	var d := fog.density
	for i in mini(dens.size(), d.size()):
		d[i] = dens[i] / 255.0
	fog.density = d
	var rem := Marshalls.base64_to_raw(fd["remembered"])
	if rem.size() == fog.remembered.size():
		fog.remembered = rem
	# Inventory and progress.
	for k in data["inventory"]:
		Inventory.counts[k] = int(data["inventory"][k])
	var p: Dictionary = data["progress"]
	Progress.unlocks = {}
	for k in p["unlocks"]:
		Progress.unlocks[k] = bool(p["unlocks"][k])
	Progress.selected = p["selected"]
	Progress.upgrades = {}
	var ups: Dictionary = p.get("upgrades", {})
	for k in ups:
		Progress.upgrades[str(k)] = str(ups[k])
	Progress.apply_upgrades()
	Progress.regions_seen = {}
	for r in p["regions_seen"]:
		Progress.regions_seen[int(r)] = true
	Progress.notes_read = {}
	for n in p["notes_read"]:
		Progress.notes_read[n] = true
	# Lanterns: replace the generated ones.
	var lroot: Node = main.get_node("Lanterns")
	for c in lroot.get_children():
		lroot.remove_child(c)
		c.queue_free()
	for l in data["lanterns"]:
		var lamp := Lantern.new()
		lamp.kind = l["kind"]
		lamp.fuel = float(l["fuel"])
		lamp.mirror_dir = int(l.get("dir", 0))
		lamp.position = Vector2(l["x"], l["y"])
		lroot.add_child(lamp)
	# Resources: replace the generated ones (keeps amounts and dropped piles).
	var rroot: Node = main.get_node("Resources")
	for c in rroot.get_children():
		rroot.remove_child(c)
		c.queue_free()
	for r in data["resources"]:
		var n := ResourceNode.new()
		n.kind = r["kind"]
		n.label = r["label"]
		n.amount = int(r["amount"])
		n.max_amount = int(r["max"])
		n.regrow_sec = float(r["regrow"])
		n.always_regrow = bool(r["always"])
		n.position = Vector2(r["x"], r["y"])
		rroot.add_child(n)
	# Landmarks already read count as already spotted (no repeat "something catches the light").
	for m in main.get_tree().get_nodes_in_group("landmark"):
		if Progress.notes_read.has(m.id):
			m._spotted = true
	Story.from_dict(data.get("story", {}))
	# The keeper.
	var pd: Dictionary = data["player"]
	main.player.global_position = Vector2(pd["x"], pd["y"])
	main.player.warmth = float(pd["warmth"])
	main.player.lamp_charge = float(pd["lamp_charge"])
	main.player.faints = int(pd["faints"])
	main.player.reset_physics_interpolation()
	fog.queue_redraw()
	return true
