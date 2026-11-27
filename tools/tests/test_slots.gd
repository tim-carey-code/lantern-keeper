extends Node
## Save slots: three slots, a slot screen, the old single save moved into slot 1. Run:
##   godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_slots.tscn

var main: Node
var frame := 0
var fails := 0

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Story.skip_opening = true
	SaveGame.slot_prefix = "user://test_slot_"   # never touch the real slots
	for n in range(1, SaveGame.SLOTS + 1):
		SaveGame.delete_slot(n)
	SaveGame.use_slot(2)
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)

func _process(_delta: float) -> void:
	frame += 1
	match frame:
		3:
			check(SaveGame.path == "user://test_slot_2.json", "each slot has its own save file")
			Story.player_name = "Ada"
			check(SaveGame.save(main), "saving writes the slot in use")
			var s := SaveGame.slot_info(2)
			check(s.get("name", "") == "Ada" and s.get("region", "") == "The Hollow", "a slot remembers who and where (%s)" % str(s))
			check(SaveGame.slot_info(1).is_empty() and SaveGame.slot_info(3).is_empty(), "the other slots stay empty")
			# A save from before the 4x map (version 3, 112 x 100): marked old, and loading it starts fresh.
			var sf := FileAccess.open(SaveGame.slot_path(2), FileAccess.READ)
			var old_data: Dictionary = JSON.parse_string(sf.get_as_text())
			sf.close()
			old_data["version"] = 3
			old_data["fog"]["cols"] = 112
			old_data["fog"]["rows"] = 100
			sf = FileAccess.open(SaveGame.slot_path(3), FileAccess.WRITE)
			sf.store_string(JSON.stringify(old_data))
			sf.close()
			check(SaveGame.slot_info(3).get("old", false) and not SaveGame.slot_info(2).get("old", true), "a save from before the bigger map is marked old")
			SaveGame.use_slot(3)
			check(not SaveGame.load_into(main), "an old save doesn't load into the bigger map (a fresh start, no crash)")
			SaveGame.use_slot(2)
			var menu = load("res://scenes/menu/slots.tscn").instantiate()
			add_child(menu)
			check(menu.slot_text(3).contains("(old save)"), "the slot screen marks it \"(old save)\" (%s)" % menu.slot_text(3))
			SaveGame.delete_slot(3)
			menu.refresh()
			check(menu.slot_text(2).contains("Ada") and menu.slot_text(1).contains("New game"), "the slot screen shows each slot (%s | %s)" % [menu.slot_text(1), menu.slot_text(2)])
			check(menu.delete_buttons[1].visible and not menu.delete_buttons[0].visible, "only filled slots can be deleted")
			menu._delete(2)
			check(not SaveGame.slot_info(2).is_empty(), "delete asks to be pressed twice")
			menu._delete(2)
			check(SaveGame.slot_info(2).is_empty() and menu.slot_text(2).contains("New game"), "pressing it again erases the slot")
			menu.queue_free()
			# The single save from before slots moves into slot 1, never over an existing one.
			var f := FileAccess.open("user://test_old_save.json", FileAccess.WRITE)
			f.store_string("{}")
			f.close()
			check(SaveGame.migrate("user://test_old_save.json") == 1, "an old save moves into slot 1")
			check(FileAccess.file_exists(SaveGame.slot_path(1)) and not FileAccess.file_exists("user://test_old_save.json"), "and is gone from the old place")
			f = FileAccess.open("user://test_old_save.json", FileAccess.WRITE)
			f.store_string("{}")
			f.close()
			check(SaveGame.migrate("user://test_old_save.json") == 2 and FileAccess.file_exists(SaveGame.slot_path(1)), "a later one goes to the next empty slot, never over a used one")
			DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_old_save.json"))
			for n in range(1, SaveGame.SLOTS + 1):
				SaveGame.delete_slot(n)
			Art._ph.clear()
			print("RESULT fails=%d" % fails)
			get_tree().quit(1 if fails else 0)
