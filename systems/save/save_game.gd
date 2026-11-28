extends Node
## Autoload "SaveGame": one save slot (JSON) plus autosave.
## Saved: keeper (position, warmth, hand lamp), inventory (scrap), progress (unlocks, selected
## lantern, regions found, notes read), every lantern (kind, position, whether an old lamp is still cold),
## every scrap pile left, and the fog map (density and what has been seen). Not saved: Wicklings, embers,
## a snuffed lamp's timer and wind (they come back on their own).
## File: user://save.json  (on Linux: ~/.local/share/godot/app_userdata/Lantern Keeper/)

const VERSION := 8   # 3: isolated Keeper's Light prototype progression; 4: the map is 224 x 200 (regions 4x);
                     # 5: M1a, the action bar and lamp-oil flasks; 6: M1b, no more tending (no fuel or glass);
                     # 7: M1c, the old lamp on the Ashbrood's rim is one of the saved lanterns (lit or cold)
                     # 8: M2, branch picks instead of cards (picks, lines, the respec spot)
const MIN_VERSION := 4   # older saves are for the small map and start fresh; version 4 is migrated on load (migrate_data)
const AUTOSAVE_SEC := 60.0

const SLOTS := 3
var slot_prefix := "user://save_"   # tests point this elsewhere so they never touch the real slots
var slot := 1                    # which save slot is in use (1-3)
var path := "user://save_1.json"
var skip_load_once := false      # set by "New game" so the next start ignores the save
var _autosave_t := AUTOSAVE_SEC

func slot_path(n: int) -> String:
	return "%s%d.json" % [slot_prefix, n]

## Play in slot n from now on.
func use_slot(n: int) -> void:
	slot = clampi(n, 1, SLOTS)
	path = slot_path(slot)

## What a slot holds, for the slot screen: {} if empty, else name, region, time (s) and saved_at.
func slot_info(n: int) -> Dictionary:
	var p := slot_path(n)
	if not FileAccess.file_exists(p):
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	var st: Dictionary = data.get("story", {})
	var region := 1
	for r in st.get("visited", []):
		region = maxi(region, int(r))
	var names := ["", "The Hollow", "The Reedmarsh", "The Windward Ridge", "The Still Lake"]
	return {"name": str(st.get("name", "")), "region": names[clampi(region, 1, names.size() - 1)],
		"time": float(st.get("time", 0.0)), "saved_at": str(data.get("saved_at", "")),
		"old": int(data.get("version", 0)) < MIN_VERSION}

func delete_slot(n: int) -> void:
	var p := ProjectSettings.globalize_path(slot_path(n))
	if FileAccess.file_exists(slot_path(n)):
		DirAccess.remove_absolute(p)

## The one save from before slots becomes slot 1 (kept, never overwritten).
func _ready() -> void:
	migrate("user://save.json")

## Moves a save from before slots into the first empty slot (never over a used one).
## Returns the slot it went to, or 0.
func migrate(old: String) -> int:
	if not FileAccess.file_exists(old):
		return 0
	for n in range(1, SLOTS + 1):
		if not FileAccess.file_exists(slot_path(n)):
			if DirAccess.rename_absolute(ProjectSettings.globalize_path(old), ProjectSettings.globalize_path(slot_path(n))) == OK:
				return n
			return 0
	return 0

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
			"warmth": player.warmth, "lamp_charge": player.lamp_charge, "faints": player.faints, "flasks": player.flasks},
		"inventory": Inventory.counts.duplicate(),
		"progress": {
			"unlocks": Progress.unlocks.duplicate(),
			"selected": Progress.selected,
			"upgrades": Progress.upgrades.duplicate(),
			"regions_seen": Progress.regions_seen.keys(),
			"notes_read": Progress.notes_read.keys(),
			"settled": Progress.settled.keys(),
			"wick": Progress.wick, "wick_frac": Progress.wick_frac, "level": Progress.level,
			"cleared": Progress.cleared.duplicate(),
			"picks": Progress.pick_list(), "lines": Progress.lines.duplicate(),
			"respec_at": ([Progress.respec_at.x, Progress.respec_at.y] if Progress.respec_at != Vector2.INF else []),
			"bar": Progress.bar.duplicate(), "lance_given": Progress.lance_given,
		},
		"lanterns": [],
		"resources": [],
		"wick_drops": [],
		"story": Story.to_dict(),
		"fog": {"cols": fog.cols, "rows": fog.rows, "density": _pack_density(fog.density),
			"remembered": Marshalls.raw_to_base64(fog.remembered)},
	}
	for l in get_tree().get_nodes_in_group("lantern"):
		data["lanterns"].append({"kind": l.kind, "x": l.position.x, "y": l.position.y, "cold": l.cold, "dir": l.mirror_dir})
	for r in get_tree().get_nodes_in_group("resource"):
		if r.is_queued_for_deletion():
			continue
		data["resources"].append({"kind": r.kind, "label": r.label, "x": r.position.x, "y": r.position.y, "amount": r.amount})
	for drop in get_tree().get_nodes_in_group("wick_drop"):
		data["wick_drops"].append({"x": drop.position.x, "y": drop.position.y, "amount": drop.amount})
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save: %s" % FileAccess.get_open_error())
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	return true

## Brings an older save up to this version (only version 4 and up can be loaded at all: older ones are for the
## small map). 4 -> 5 (M1a): the action bar starts as the default one, with Lance on slot 3 if the keeper is
## already level 2 or more, and all flasks full. 5 -> 6 (M1b, no more tending): fuel and glass leave the
## inventory; what WayLamps were fed is dropped (they are lit by touch now); a lantern keeps its kind, place and
## mirror direction, and is cold only if its tank was empty (load_into() lets only the old lamps stay cold);
## fuel spots, peat, glass shards and the woodpile go; untaken fuel and glass caches become scrap caches; scrap
## piles keep what is left in them (one-off now); charge is kept (capped on load). Level, wick, the bar, flasks,
## upgrades, notes, cleared fights and the story are kept as they are. 6 -> 7 (M1c): no field changes; the rim lamp
## a version 6 save lacks is put back cold on load. Public for tests.
static func migrate_data(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 0))
	if v == 4:
		var p: Dictionary = data.get("progress", {})
		var bar := Progress.default_bar()
		var lvl := int(p.get("level", 1))
		if lvl >= Tuning.kl_lance_level:
			bar["skill_3"] = "lance"
		p["bar"] = bar
		p["lance_given"] = lvl >= Tuning.kl_lance_level
		data["progress"] = p
		var pl: Dictionary = data.get("player", {})
		pl["flasks"] = Tuning.kl_flask_max
		data["player"] = pl
		data["version"] = 5
	if int(data.get("version", 0)) == 5:
		var inv: Dictionary = data.get("inventory", {})
		data["inventory"] = {"scrap": int(inv.get("scrap", 0))}
		var p: Dictionary = data.get("progress", {})
		p.erase("waylamp_fuel")
		data["progress"] = p
		var lamps := []
		for l in data.get("lanterns", []):
			if typeof(l) != TYPE_DICTIONARY:
				continue
			lamps.append({"kind": str(l.get("kind", "post")), "x": float(l.get("x", 0.0)), "y": float(l.get("y", 0.0)),
				"cold": float(l.get("fuel", 1.0)) <= 0.0, "dir": int(l.get("dir", 0))})
		data["lanterns"] = lamps
		var piles := []
		for r in data.get("resources", []):
			if typeof(r) != TYPE_DICTIONARY:
				continue
			var kind := str(r.get("kind", ""))
			var label := str(r.get("label", ""))
			var amount := int(r.get("amount", 0))
			if kind != "scrap" and label == "Old cache":
				kind = "scrap"   # the fuel and glass caches hold scrap now (same amounts)
			if kind != "scrap" or amount <= 0:
				continue   # fuel spots, peat, glass shards, the woodpile, dropped fuel, empty piles
			piles.append({"kind": "scrap", "label": label if label in ["Old cache"] else "", "x": float(r.get("x", 0.0)), "y": float(r.get("y", 0.0)), "amount": amount})
		data["resources"] = piles
		data["version"] = 6
	if int(data.get("version", 0)) == 6:
		# 6 -> 7 (M1c): nothing in the file changes. A version 6 save has no rim lamp in its lantern list (it didn't
		# exist); load_into() puts every missing old lamp back, cold, so the rim lamp is there to light by touch.
		# Lamp slots come from the level (nothing to save); snuff, flare and smother timers are not saved.
		data["version"] = 7
		data["from_v6"] = true   # load_into: a lamp the keeper planted on the new rim lamp's tile is refunded
	if int(data.get("version", 0)) == 7:
		# 7 -> 8 (M2, GAME_PLAN §4.3): the cards become picks. Skill points come from the level (one a level over 1),
		# so a level-7 keeper has 6. Each old card maps to its pick (SkillTree.CARD_TO_PICK: Heavy flare is Heavy ring);
		# load_into() keeps a mapped pick only if its tier is open (Catching needs the Ashbrood kill) and its tier is
		# still free (two old Beam cards can share a tier: the first one listed wins); every card that doesn't fit is
		# an unspent point. Kindled kills, Hot core and Lee are carried as lines until gear exists (M3).
		var p: Dictionary = data.get("progress", {})
		var mapped := []
		var carried := []
		for raw in p.get("combat_upgrades", []):
			var id := str(raw)
			if SkillTree.CARD_TO_PICK.has(id):
				mapped.append(SkillTree.CARD_TO_PICK[id])
			elif SkillTree.CARD_LINES.has(id) and not carried.has(id):
				carried.append(id)
		p.erase("combat_upgrades")
		p["picks"] = mapped
		p["lines"] = carried
		p["respec_at"] = []
		data["progress"] = p
		data["version"] = 8
	return data

## A saved action bar, checked slot by slot with Progress.bind_reason() (call it after level and lance_given are
## loaded). A slot holding something it may not (an unknown or unlearned skill, an aimed skill on slot 4, a skill
## already on an earlier slot, not a string) falls back to the default bar's skill for that slot, or to empty if
## that isn't allowed either. A missing slot takes the default too. Public for tests.
static func valid_bar(saved: Dictionary) -> Dictionary:
	var defaults := Progress.default_bar()
	var bar := {}
	var used := {}
	for slot in Progress.SLOTS:
		var id := ""
		var raw = saved.get(slot, null)
		if typeof(raw) == TYPE_STRING and Progress.bind_reason(slot, raw) == "" and (raw == "" or not used.has(raw)):
			id = raw
		else:
			var d: String = defaults[slot]
			if Progress.bind_reason(slot, d) == "" and (d == "" or not used.has(d)):
				id = d
		bar[slot] = id
		if id != "":
			used[id] = true
	return bar

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
	if typeof(data) != TYPE_DICTIONARY or int(data.get("version", 0)) < MIN_VERSION or int(data.get("version", 0)) > VERSION:
		push_warning("Save file is missing or from another version; starting fresh.")
		return false
	data = migrate_data(data)
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
	fog.mark_all_dirty()   # the fog's sparse update and texture must see the loaded map
	# Inventory (scrap only) and progress.
	Inventory.counts = {"scrap": int(data["inventory"].get("scrap", 0))}
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
	Progress.settled = {}
	for r in p.get("settled", []):
		Progress.settled[int(r)] = true
	Progress.wick = int(p.get("wick", 0))
	Progress.wick_frac = float(p.get("wick_frac", 0.0))
	Progress.level = int(p.get("level", 1))
	Progress.pending_level_ups = 0
	Progress.cleared = {}
	for key in p.get("cleared", {}):
		Progress.cleared[str(key)] = true
	Progress.lance_given = bool(p.get("lance_given", false))   # before the bar and picks: knows("lance") depends on it
	# M2: picks (checked against the tiers and points: level, cleared and settled are loaded above), carried lines,
	# and where the keeper last rested (respec stays open while they stand by that WayLamp).
	Progress.lines = []
	for l in p.get("lines", []):
		if SkillTree.CARD_LINES.has(str(l)) and not Progress.lines.has(str(l)):
			Progress.lines.append(str(l))
	var saved_picks = p.get("picks", [])
	Progress.set_picks(saved_picks if typeof(saved_picks) == TYPE_ARRAY else [])
	var ra = p.get("respec_at", [])
	Progress.respec_at = Vector2(float(ra[0]), float(ra[1])) if typeof(ra) == TYPE_ARRAY and ra.size() == 2 else Vector2.INF
	var saved_bar = p.get("bar", {})
	Progress.bar = valid_bar(saved_bar if typeof(saved_bar) == TYPE_DICTIONARY else {})
	# Lanterns: replace the generated ones.
	var lroot: Node = main.get_node("Lanterns")
	for c in lroot.get_children():
		lroot.remove_child(c)
		c.queue_free()
	var rim: Vector2 = main.rim_lamp_pos if "rim_lamp_pos" in main else Vector2.INF
	var kept: Array = []
	for l in data["lanterns"]:
		# Review fix (M1c): a version 6 save may have a planted lamp where the rim lamp now stands. Its scrap goes
		# back to the keeper and the rim lamp takes the tile (below), so the no-scrap way to light the Ashbrood stays.
		if data.get("from_v6", false) and rim != Vector2.INF and Vector2(l["x"], l["y"]).distance_to(rim) < FogGrid.TILE * 1.5:
			Inventory.counts["scrap"] = Inventory.get_count("scrap") + Lantern.cost(str(l["kind"]))
			continue
		kept.append(l)
	for l in kept:
		var lamp := Lantern.new()
		lamp.kind = l["kind"]
		lamp.mirror_dir = int(l.get("dir", 0))
		lamp.position = Vector2(l["x"], l["y"])
		# The valley's old lamps are known by their place; only they can still be cold (lit by touch).
		lamp.old = lamp.kind == "post" and main.has_method("is_old_lamp_spot") and main.is_old_lamp_spot(lamp.position)
		lamp.cold = lamp.old and bool(l.get("cold", false))
		lroot.add_child(lamp)
	# An old lamp the save doesn't list (the rim lamp, in a save from before M1c) comes back cold.
	if main.has_method("old_lamp_spots"):
		for spot in main.old_lamp_spots():
			var found := false
			for l in kept:
				if Vector2(l["x"], l["y"]).distance_to(spot) < 8.0:
					found = true
					break
			if not found:
				var old_lamp := Lantern.new()
				old_lamp.kind = "post"
				old_lamp.old = true
				old_lamp.cold = true
				old_lamp.position = spot
				lroot.add_child(old_lamp)
	# Scrap piles: replace the generated ones with what was left (one-off: taken piles stay gone).
	var rroot: Node = main.get_node("Resources")
	for c in rroot.get_children():
		rroot.remove_child(c)
		c.queue_free()
	for r in data["resources"]:
		var n := ResourceNode.new()
		n.kind = "scrap"
		n.label = str(r.get("label", ""))
		n.amount = int(r["amount"])
		n.position = Vector2(r["x"], r["y"])
		rroot.add_child(n)
	var arena := get_tree().get_first_node_in_group("wickling_spawner")
	if arena:
		for drop_data in data.get("wick_drops", []):
			var drop := WickDrop.new()
			drop.amount = int(drop_data["amount"])
			drop.position = Vector2(drop_data["x"], drop_data["y"])
			arena.add_child(drop)
	# Landmarks already read count as already spotted (no repeat "something catches the light").
	for m in main.get_tree().get_nodes_in_group("landmark"):
		if Progress.notes_read.has(m.id):
			m._spotted = true
	Story.from_dict(data.get("story", {}))
	# The keeper.
	var pd: Dictionary = data["player"]
	main.player.global_position = Vector2(pd["x"], pd["y"])
	main.player.warmth = float(pd["warmth"])
	main.player.lamp_charge = clampf(float(pd["lamp_charge"]), 0.0, Progress.charge_max())
	main.player.faints = int(pd["faints"])
	main.player.flasks = clampi(int(pd.get("flasks", Tuning.kl_flask_max)), 0, main.player.flask_max())
	main.player.reset_physics_interpolation()
	fog.queue_redraw()
	return true
