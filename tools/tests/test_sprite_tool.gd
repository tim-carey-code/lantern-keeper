extends Node
## The sprite pipeline (tools/art/sprite_from_sheet.gd, sprite_pipeline.gd): a synthetic key-pose sheet built in
## code goes through the whole pipeline into a scratch user:// folder (never assets/). Checks the frame sizes, that
## every pixel is a palette colour with no semi-transparency, the eye repair, the rim and the outline, frame counts
## (and that Art.frames loads them, per-variant sizes included), the dissolve, the content-based layout, the
## dark grid lines, keep = "largest", and that a hand-drawn or touched-up strip is never overwritten without force.
## Run: godot --headless --audio-driver Dummy --fixed-fps 60 --path . res://tools/tests/test_sprite_tool.tscn

const Pipeline := preload("res://tools/art/sprite_pipeline.gd")
const ROOT := "user://sprite_tool_test/"
const CELL := 120
const BODY := Color8(12, 15, 27)
const EYE_SRC := Color8(205, 218, 232)
const GRID := Color8(110, 10, 110)

var fails := 0
var palette: Array[Color] = []

func check(ok: bool, what: String) -> void:
	print(("PASS " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _ready() -> void:
	_wipe(ROOT)
	DirAccess.make_dir_recursive_absolute(ROOT)
	var pal := Image.load_from_file(ProjectSettings.globalize_path(Pipeline.PALETTE_PATH))
	for x in pal.get_width():
		palette.append(Color(pal.get_pixel(x, 0), 1.0))
	_grid_checks()
	_owner_art_checks()
	_auto_checks()
	_component_checks()
	_warm_checks()
	_recolour_checks()
	_wipe(ROOT)
	Art.clear_frames()
	print("RESULT fails=%d" % fails)
	get_tree().quit(1 if fails > 0 else 0)

# --- The synthetic sheet: 2 rows x 3 cols of 120 px cells, JPEG-like noise, dark purple grid lines -------------

## A smoky blob with two pale eyes; `reach` adds an arm to the right, `dy` moves it down.
func _creature(img: Image, ox: int, oy: int, reach: bool = false, dy: int = 0, eyes: bool = true) -> void:
	var cx := ox + 60
	var cy := oy + 66 + dy
	for y in range(oy, oy + CELL):
		for x in range(ox, ox + CELL):
			var e := pow((x - cx) / 28.0, 2) + pow((y - cy) / 40.0, 2)
			if e <= 1.0:
				img.set_pixel(x, y, BODY)
	if reach:
		img.fill_rect(Rect2i(cx + 20, cy - 4, 34, 8), BODY)
	if eyes:
		img.fill_rect(Rect2i(cx - 14, cy - 16, 6, 6), EYE_SRC)
		img.fill_rect(Rect2i(cx + 8, cy - 16, 6, 6), EYE_SRC)

func _sheet() -> Image:
	var img := Image.create(CELL * 3, CELL * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1))
	_creature(img, 0, 0)                     # a/idle
	_creature(img, CELL, 0, false, 6)        # a/move
	_creature(img, CELL * 2, 0, true)        # a/attack
	_creature(img, 0, CELL)                  # b/idle (24x24)
	_creature(img, CELL, CELL)               # b/notice
	_creature(img, CELL * 2, CELL, false, 0, false)   # c/idle: outlined, no eyes
	# Dark purple grid lines between the cells (key_mode = "hue" clears them).
	for i in range(1, 3):
		img.fill_rect(Rect2i(i * CELL - 1, 0, 2, img.get_height()), GRID)
	img.fill_rect(Rect2i(0, CELL - 1, img.get_width(), 2), GRID)
	# JPEG-like noise on the background.
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c == Color(1, 0, 1):
				img.set_pixel(x, y, Color(1.0 - rng.randf() * 0.03, rng.randf() * 0.03, 1.0 - rng.randf() * 0.03))
	return img

func _manifest(path: String, extra: Dictionary = {}) -> void:
	var m := ConfigFile.new()
	m.set_value("sheet", "subject", "sub")
	m.set_value("sheet", "kind", "creature")
	m.set_value("sheet", "rows", 2)
	m.set_value("sheet", "cols", 3)
	m.set_value("sheet", "frame_size", 16)
	m.set_value("sheet", "anchor", "foot")
	m.set_value("sheet", "key_mode", "hue")
	m.set_value("cells", "r0c0", "a/idle")
	m.set_value("cells", "r0c1", "a/move")
	m.set_value("cells", "r0c2", "a/attack")
	m.set_value("cells", "r1c0", "b/idle")
	m.set_value("cells", "r1c1", "b/notice")
	m.set_value("cells", "r1c2", "c/idle")
	m.set_value("variant.b", "frame_size", 24)
	m.set_value("variant.b", "rim", "elite")
	m.set_value("variant.c", "outline", true)
	m.set_value("variant.c", "rim", "none")
	m.set_value("variant.c", "eyes", 0)
	m.set_value("pose.c.idle", "derive", [])
	m.set_value("pose.c.idle", "sway", false)
	m.set_value("anim.idle", "fps", 6.0)
	for k in extra:
		m.set_value(str(k).get_slice("/", 0), str(k).get_slice("/", 1), extra[k])
	m.save(path)

func _run(out: String, manifest_extra: Dictionary = {}, force: bool = false) -> Dictionary:
	var sheet := ROOT + "sheet.png"
	if not FileAccess.file_exists(sheet):
		_sheet().save_png(sheet)
	var man := ROOT + "sub.cfg"
	_manifest(man, manifest_extra)
	return Pipeline.new().run(sheet, man, {"out_root": out, "preview_dir": ROOT + "previews/", "force": force})

# --- Checks --------------------------------------------------------------------------------------------------------

func _grid_checks() -> void:
	var out := ROOT + "out/"
	var rep := _run(out)
	check(rep["ok"] and rep["errors"].is_empty() and rep["cells"] == 6, "the pipeline runs on a 2 x 3 synthetic sheet (%s)" % str(rep["errors"]))
	var dir := out + "creatures/sub/"
	var want := {"sub_a_idle": [4, 16], "sub_a_move": [4, 16], "sub_a_attack": [2, 16], "sub_a_windup": [1, 16],
		"sub_a_hurt": [2, 16], "sub_a_death": [5, 16], "sub_a_spawn": [5, 16], "sub_a_notice": [2, 16],
		"sub_b_idle": [4, 24], "sub_b_notice": [2, 24], "sub_b_hurt": [2, 24], "sub_c_idle": [4, 16]}
	var sizes_ok := true
	for n in want:
		var img := _load(dir + n + ".png")
		var f: int = want[n][0]
		var s: int = want[n][1]
		if img == null or img.get_width() != f * s or img.get_height() != s:
			sizes_ok = false
			print("  ", n, " ", img.get_size() if img else "missing")
	check(sizes_ok, "every strip has its frame count and frame size (16x16; the 24x24 variant b; derived hurt, death, spawn, notice, windup)")
	check(not FileAccess.file_exists(dir + "sub_b_notice_x.png") and not FileAccess.file_exists(dir + "sub_c_hurt.png"), "derive = [] makes no extra strips")
	var all_ok := true
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".png") and not _palette_only(_load(dir + f)):
			all_ok = false
			print("  off-palette or semi-transparent: ", f)
	check(all_ok, "every pixel of every strip is one of the 14 palette colours, fully opaque or fully clear")
	var cold_ok := true
	for f in ["sub_a_idle.png", "sub_b_idle.png", "sub_a_hurt.png"]:
		var img := _load(dir + f)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and not Pipeline.COLD_HEX.has("#" + c.to_html(false)):
					cold_ok = false
	check(cold_ok, "a creature uses only the cold colours (never amber)")
	var idle := _load(dir + "sub_a_idle.png")
	var f0 := idle.get_region(Rect2i(0, 0, 16, 16))
	check(f0.get_pixel(0, 0).a == 0.0 and f0.get_pixel(15, 0).a == 0.0, "the dark purple grid lines key out with the magenta (key_mode = hue)")
	var eyes := _pixels(f0, Color.html(Pipeline.EYE_HEX))
	var xs: Array = eyes.map(func(p): return p.x)
	check(eyes.size() >= 2 and xs.max() - xs.min() >= 2, "eye repair: both eyes are painted back in #a3bcd4, at least 1 px each and apart (%s)" % str(eyes))
	var rep0 := _run(ROOT + "noeyes/", {"variant.a/eyes": 0})
	var bare := _load(ROOT + "noeyes/creatures/sub/sub_a_idle.png")
	check(rep0["ok"] and bare != null and _pixels(bare.get_region(Rect2i(0, 0, 16, 16)), Color.html(Pipeline.EYE_HEX)).size() < 2,
		"without the repair (eyes = 0) the 6 px eyes are lost at 16 px: the repair is what keeps them")
	check(_top_colour(f0) == Color.html("#36507a"), "the small foe gets the 1 px #36507a rim on top")
	var b0 := _load(dir + "sub_b_idle.png").get_region(Rect2i(0, 0, 24, 24))
	check(_top_colour(b0) == Color.html("#4a6a94"), "the elite variant gets the #4a6a94 rim")
	var c0 := _load(dir + "sub_c_idle.png").get_region(Rect2i(0, 0, 16, 16))
	check(_edge_all(c0, Color.html(Pipeline.OUTLINE_HEX)) and _top_colour(c0) == Color.html(Pipeline.OUTLINE_HEX), "the outline variant has a 1 px #141a2e outline all round and no rim")
	# Bob, hurt, notice, death, spawn, attack.
	var f1 := idle.get_region(Rect2i(16, 0, 16, 16))
	check(_top_row(f1) == _top_row(f0) - 1, "idle frame 2 bobs up 1 px")
	var hurt := _load(dir + "sub_a_hurt.png")
	var h0 := hurt.get_region(Rect2i(0, 0, 16, 16))
	check(_opaque(h0) > 10 and _pixels(h0, Color.html("#a3bcd4")).size() == _opaque(h0) and _same(hurt.get_region(Rect2i(16, 0, 16, 16)), f0),
		"hurt: a pale flash of the whole silhouette, then the key pose")
	var notice := _load(dir + "sub_a_notice.png")
	check(_pixels(notice.get_region(Rect2i(16, 0, 16, 16)), Color.html(Pipeline.EYE_HEX)).size() > eyes.size(), "notice: frame 2 flares the eyes by 1 px")
	var death := _load(dir + "sub_a_death.png")
	var d := []
	for i in 5:
		d.append(_opaque(death.get_region(Rect2i(i * 16, 0, 16, 16))))
	var d4 := death.get_region(Rect2i(48, 0, 16, 16))
	check(d[0] > d[1] and d[1] > d[2] and d[2] > d[3] and d[4] == 0 and _pixels(d4, Color.html(Pipeline.EYE_HEX)).size() == d[3] and d[3] > 0,
		"death dissolves in 5 frames, the eyes last (%s)" % str(d))
	var spawn := _load(dir + "sub_a_spawn.png")
	check(_same(spawn.get_region(Rect2i(64, 0, 16, 16)), f0) and _opaque(spawn.get_region(Rect2i(0, 0, 16, 16))) == d[3], "spawn is the dissolve backwards: eyes first, the key pose last")
	var atk := _load(dir + "sub_a_attack.png")
	check(_mass_x(atk.get_region(Rect2i(0, 0, 16, 16))) > _mass_x(atk.get_region(Rect2i(16, 0, 16, 16))), "attack: frame 1 leans 1 px forward")
	# The frames file and the loader (per-variant frame sizes).
	var cfg := ConfigFile.new()
	cfg.load(dir + "sub.frames.cfg")
	check(cfg.get_value("sheet", "frame_size", Vector2i.ZERO) == Vector2i(16, 16) and cfg.get_value("variant.b", "frame_size", Vector2i.ZERO) == Vector2i(24, 24)
		and cfg.get_value("idle", "fps", 0.0) == 6.0 and cfg.get_value("idle", "loop", false) == true and cfg.get_value("death", "loop", true) == false,
		"sub.frames.cfg: [sheet] 16x16, [variant.b] 24x24, fps and loop per animation")
	var old := Art.sprite_roots
	Art.sprite_roots = PackedStringArray([out + "creatures/"])
	Art.clear_frames()
	var sa := Art.frames("sub", "a")
	var sb := Art.frames("sub", "b")
	check(sa != null and sa.get_frame_count("idle") == 4 and sa.get_frame_count("death") == 5 and sa.get_meta("frame_size_idle") == Vector2i(16, 16)
		and sb != null and sb.get_frame_count("idle") == 4 and sb.get_meta("frame_size_idle") == Vector2i(24, 24) and sb.get_animation_speed("idle") == 6.0,
		"Art.frames loads the strips: 4 idle frames at 16x16 for a, at 24x24 for b")
	Art.sprite_roots = old
	Art.clear_frames()
	check(not rep["preview"].is_empty() and FileAccess.file_exists(rep["preview"]) and rep["previews"].size() == rep["strips"].size(),
		"an 8x preview of every strip is written (into the scratch folder given)")
	var pv := _load(rep["preview"])
	check(pv != null and pv.get_pixel(0, 0).to_html(false) == Pipeline.PREVIEW_BG.trim_prefix("#"), "the preview is on #1d2745")

func _owner_art_checks() -> void:
	var out := ROOT + "owner/"
	var dir := out + "creatures/sub/"
	DirAccess.make_dir_recursive_absolute(dir)
	# A hand-drawn move strip is there before the tool ever runs.
	var hand := Image.create(32, 16, false, Image.FORMAT_RGBA8)
	hand.fill_rect(Rect2i(4, 4, 8, 8), Color.html("#28385e"))
	hand.save_png(dir + "sub_a_move.png")
	var md5 := FileAccess.get_md5(dir + "sub_a_move.png")
	var rep := _run(out)
	check(rep["kept"].has(dir + "sub_a_move.png") and FileAccess.get_md5(dir + "sub_a_move.png") == md5, "a hand-drawn strip is never overwritten (it is reported as kept)")
	# A second run rewrites the tool's own untouched strips, but not one the owner touched up in Pixelorama.
	var idle := _load(dir + "sub_a_idle.png")
	idle.set_pixel(0, 15, Color.html("#0b0e1a"))
	idle.save_png(dir + "sub_a_idle.png")
	var touched := FileAccess.get_md5(dir + "sub_a_idle.png")
	var rep2 := _run(out)
	check(rep2["written"].has(dir + "sub_a_death.png") and rep2["kept"].has(dir + "sub_a_idle.png") and FileAccess.get_md5(dir + "sub_a_idle.png") == touched
		and FileAccess.get_md5(dir + "sub_a_move.png") == md5, "a re-run refreshes its own strips but keeps a touched-up one and the hand-drawn one")
	var rep3 := _run(out, {}, true)
	check(rep3["written"].has(dir + "sub_a_move.png") and FileAccess.get_md5(dir + "sub_a_move.png") != md5, "--force overwrites them")
	var rep4 := Pipeline.new().run(ROOT + "sheet.png", ROOT + "sub.cfg", {"out_root": ROOT + "dry/", "preview_dir": ROOT + "previews/", "preview_only": true})
	check(rep4["ok"] and rep4["written"].is_empty() and not DirAccess.dir_exists_absolute(ROOT + "dry/creatures/sub"), "--preview-only writes nothing but the preview")
	var bad := Pipeline.new().run(ROOT + "missing.png", ROOT + "sub.cfg", {"out_root": ROOT + "bad/"})
	check(not bad["ok"] and not bad["errors"].is_empty(), "a missing sheet is reported, not a crash")

## Content-based layout: rows of different heights, a projectile beside a body, keep = "largest".
func _auto_checks() -> void:
	var img := Image.create(400, 320, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1))
	img.fill_rect(Rect2i(30, 10, 60, 190), BODY)      # r0c0: tall
	img.fill_rect(Rect2i(220, 10, 60, 190), BODY)     # r0c1: tall, with a spit glob to its right
	img.fill_rect(Rect2i(300, 90, 12, 12), BODY)
	img.fill_rect(Rect2i(30, 250, 120, 40), BODY)     # r1c0: low and wide (crosses no midline: rows aren't equal)
	img.fill_rect(Rect2i(220, 250, 120, 40), BODY)
	img.save_png(ROOT + "auto.png")
	var m := ConfigFile.new()
	m.set_value("sheet", "subject", "auto")
	m.set_value("sheet", "kind", "creature")
	m.set_value("sheet", "layout", "auto")
	m.set_value("sheet", "rows", 2)
	m.set_value("sheet", "cols", 2)
	m.set_value("sheet", "frame_size", Vector2i(16, 32))
	m.set_value("sheet", "eyes", 0)
	m.set_value("sheet", "rim", "none")
	m.set_value("cells", "r0c0", "idle")
	m.set_value("cells", "r0c1", "attack")
	m.set_value("cells", "r1c0", "skip")
	m.set_value("cells", "r1c1", "skip")
	m.set_value("pose.base.idle", "derive", [])
	m.set_value("pose.base.attack", "derive", [])
	m.set_value("pose.base.attack", "rule", "hold")
	m.save(ROOT + "auto.cfg")
	var rep := Pipeline.new().run(ROOT + "auto.png", ROOT + "auto.cfg", {"out_root": ROOT + "auto_all/", "preview_dir": ROOT + "previews/"})
	var wide := _load(ROOT + "auto_all/creatures/auto/auto_attack.png")
	check(rep["ok"] and rep["cells"] == 2 and wide != null and wide.get_size() == Vector2i(16, 32), "auto layout finds rows of different heights and merges a stray glob into its column (16x32 frames)")
	m.set_value("cell.r0c1", "keep", "largest")
	m.save(ROOT + "auto.cfg")
	var rep2 := Pipeline.new().run(ROOT + "auto.png", ROOT + "auto.cfg", {"out_root": ROOT + "auto_big/", "preview_dir": ROOT + "previews/"})
	var big := _load(ROOT + "auto_big/creatures/auto/auto_attack.png")
	var idle_strip := _load(ROOT + "auto_big/creatures/auto/auto_idle.png")
	var idle := idle_strip.get_region(Rect2i(0, 0, 16, 32)) if idle_strip else null
	check(rep2["ok"] and big != null and wide != null and _width(big) < _width(wide) and absi(_width(big) - _width(idle)) <= 0,
		"keep = \"largest\" drops the glob: the body alone, the same width as the idle (%d, idle %d; %d with the glob)" % [_width(big) if big else -1, _width(idle) if idle else -1, _width(wide) if wide else -1])
	m.set_value("sheet", "rows", 3)
	m.save(ROOT + "auto.cfg")
	var rep3 := Pipeline.new().run(ROOT + "auto.png", ROOT + "auto.cfg", {"out_root": ROOT + "auto_bad/", "preview_dir": ROOT + "previews/"})
	check(not rep3["ok"] and str(rep3["errors"]).contains("row bands"), "auto layout says so when the rows don't match the manifest")

## layout = "components": poses whose boxes overlap in x (a wing under the next pose), plus a loose fragment.
func _component_checks() -> void:
	var img := Image.create(240, 140, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1))
	img.fill_rect(Rect2i(10, 60, 100, 60), BODY)      # A: low and wide, reaching under B
	img.fill_rect(Rect2i(100, 10, 60, 40), BODY)      # B: high, overlapping A's columns 100-110
	img.fill_rect(Rect2i(172, 26, 8, 8), BODY)        # a fragment of B's effect (an ash-ring piece)
	img.save_png(ROOT + "comp.png")
	var m := ConfigFile.new()
	m.set_value("sheet", "subject", "comp")
	m.set_value("sheet", "kind", "creature")
	m.set_value("sheet", "rows", 1)
	m.set_value("sheet", "cols", 2)
	m.set_value("sheet", "frame_size", 16)
	m.set_value("sheet", "eyes", 0)
	m.set_value("cells", "r0c0", "idle")
	m.set_value("cells", "r0c1", "recover")
	m.set_value("pose.base.idle", "derive", [])
	m.set_value("sheet", "layout", "auto")
	m.save(ROOT + "comp.cfg")
	var bad := Pipeline.new().run(ROOT + "comp.png", ROOT + "comp.cfg", {"out_root": ROOT + "comp_auto/", "preview_dir": ROOT + "previews/"})
	var ab: Rect2i = bad["cell_boxes"].get("r0c0", Rect2i())
	check(not bad["ok"] or (ab.position.y <= 10 and ab.end.y >= 120), "column bands can't split poses that overlap in x (auto layout lumps A and B into one cell %s)" % str(ab))
	m.set_value("sheet", "layout", "components")
	m.save(ROOT + "comp.cfg")
	var rep := Pipeline.new().run(ROOT + "comp.png", ROOT + "comp.cfg", {"out_root": ROOT + "comp_out/", "preview_dir": ROOT + "previews/"})
	var a: Rect2i = rep["cell_boxes"].get("r0c0", Rect2i())
	var b: Rect2i = rep["cell_boxes"].get("r0c1", Rect2i())
	check(rep["ok"] and rep["cells"] == 2 and a.position.x <= 10 and a.end.y >= 120 and a.end.x <= 116 and b.position.y <= 10 and b.end.y <= 56 and b.end.x >= 180,
		"components layout: each pose is its own shape (A %s, B %s), the loose fragment joins the nearest pose (B)" % [str(a), str(b)])
	var fa := _load(ROOT + "comp_out/creatures/comp/comp_idle.png")
	var fb := _load(ROOT + "comp_out/creatures/comp/comp_recover.png")
	var a0 := fa.get_region(Rect2i(0, 0, 16, 16)) if fa else null
	check(a0 != null and fb != null and _top_row(a0) >= 6 and _width(a0) >= 13, "the masked cell holds only its own pose: A stays low and wide (none of B above it)")

## warm = "ember": fire-coloured pixels keep the ambers, bone beige and the rest snap cold; "snap" makes all cold.
func _warm_checks() -> void:
	var img := Image.create(240, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1))
	for c in 2:
		var ox := c * 120
		img.fill_rect(Rect2i(ox + 20, 20, 80, 90), BODY)
		img.fill_rect(Rect2i(ox + 30, 26, 40, 24), Color8(222, 206, 172))   # a bone-beige skull
		img.fill_rect(Rect2i(ox + 40, 80, 30, 20), Color8(245, 150, 45))    # the ember
	img.save_png(ROOT + "warm.png")
	var m := ConfigFile.new()
	m.set_value("sheet", "subject", "warm")
	m.set_value("sheet", "kind", "creature")
	m.set_value("sheet", "rows", 1)
	m.set_value("sheet", "cols", 2)
	m.set_value("sheet", "frame_size", 16)
	m.set_value("sheet", "eyes", 0)
	m.set_value("sheet", "palette", "cold")
	m.set_value("cells", "r0c0", "idle")
	m.set_value("cells", "r0c1", "recover")
	m.set_value("cell.r0c0", "warm", "ember")
	m.set_value("pose.base.idle", "derive", [])
	m.save(ROOT + "warm.cfg")
	var rep := Pipeline.new().run(ROOT + "warm.png", ROOT + "warm.cfg", {"out_root": ROOT + "warm_out/", "preview_dir": ROOT + "previews/"})
	var ember := _load(ROOT + "warm_out/creatures/warm/warm_idle.png")
	var cold := _load(ROOT + "warm_out/creatures/warm/warm_recover.png")
	var warm_px := 0
	var cream := 0
	var pale := 0
	for y in 16:
		for x in 16:
			var c := ember.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var hx := "#" + c.to_html(false)
			if Pipeline.FIRE_HEX.has(hx):
				warm_px += 1
			if hx == "#fff1c1":
				cream += 1
			if hx == "#a3bcd4" or hx == "#6d8fb3":
				pale += 1
	var all_cold := true
	for y in cold.get_height():
		for x in cold.get_width():
			var c := cold.get_pixel(x, y)
			if c.a > 0.5 and not Pipeline.COLD_HEX.has("#" + c.to_html(false)):
				all_cold = false
	check(rep["ok"] and warm_px > 0 and cream == 0 and pale > 0, "warm = ember keeps the ember amber (%d px) and snaps the bone-beige skull to the pale cold blues (%d px), not cream" % [warm_px, pale])
	check(all_cold, "without it (palette cold) the same ember turns cold: a foe never glows amber")

## A person: recolour maps skin tones and green glass to chosen colours; a prop gets its own file and stays out of
## the frames file.
func _recolour_checks() -> void:
	var img := Image.create(240, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0, 1))
	img.fill_rect(Rect2i(40, 10, 40, 100), Color8(40, 30, 40))
	img.fill_rect(Rect2i(44, 14, 32, 24), Color8(214, 168, 132))     # a face
	img.fill_rect(Rect2i(44, 60, 32, 24), Color8(70, 110, 88))       # a green bottle
	img.fill_rect(Rect2i(130, 40, 100, 60), Color8(90, 60, 40))      # the cart (a wide prop)
	img.save_png(ROOT + "rc.png")
	var m := ConfigFile.new()
	m.set_value("sheet", "subject", "rc")
	m.set_value("sheet", "kind", "person")
	m.set_value("sheet", "rows", 1)
	m.set_value("sheet", "cols", 2)
	m.set_value("sheet", "frame_size", 32)
	m.set_value("sheet", "recolour", {"skin": ["#d9772b", "#9c4a22"], "green": ["#ffd27a", "#f5a742", "#d9772b"]})
	m.set_value("cells", "r0c0", "idle")
	m.set_value("cells", "r0c1", "cart/cart")
	m.set_value("variant.cart", "frame_size", Vector2i(48, 32))
	m.set_value("pose.cart.cart", "rule", "hold")
	m.set_value("pose.cart.cart", "prop", true)
	m.set_value("pose.cart.cart", "file", "rc_cart")
	m.save(ROOT + "rc.cfg")
	var rep := Pipeline.new().run(ROOT + "rc.png", ROOT + "rc.cfg", {"out_root": ROOT + "rc_out/", "preview_dir": ROOT + "previews/"})
	var dir := ROOT + "rc_out/people/rc/"
	var f := _load(dir + "rc_idle.png")
	var f0 := f.get_region(Rect2i(0, 0, 32, 32)) if f else null
	# The face sits in the top quarter of the figure, the bottle lower down.
	var face := {}
	var bottle := {}
	if f0:
		var top := _top_row(f0)
		for y in 32:
			for x in 32:
				var c := f0.get_pixel(x, y)
				if c.a < 0.5 or c.to_html(false) == "141a2e":
					continue
				var hx := "#" + c.to_html(false)
				if y >= top + 2 and y <= top + 6:
					face[hx] = true
				elif y >= top + 15 and y <= top + 20:
					bottle[hx] = true
	check(rep["ok"] and face.has("#d9772b") and not face.has("#ffd27a") and not face.has("#fff1c1") and not face.has("#f5a742"),
		"recolour skin: a face snaps to #d9772b / #9c4a22, not the lamp ambers (%s)" % str(face.keys()))
	var green_ok := not bottle.is_empty()
	for hx in bottle:
		if not ["#ffd27a", "#f5a742", "#d9772b"].has(hx) and not Pipeline.COLD_HEX.slice(0, 3).has(hx):
			green_ok = false
	check(green_ok and (bottle.has("#ffd27a") or bottle.has("#f5a742") or bottle.has("#d9772b")), "recolour green: a green bottle snaps to the flask ambers (%s)" % str(bottle.keys()))
	var cart := _load(dir + "rc_cart.png")
	var cfg := ConfigFile.new()
	cfg.load(dir + "rc.frames.cfg")
	check(cart != null and cart.get_size() == Vector2i(48, 32) and not FileAccess.file_exists(dir + "rc_cart_cart.png") and not cfg.has_section("cart") and not cfg.has_section("variant.cart") and cfg.has_section("idle"),
		"a prop: its own file (rc_cart.png, 48x32), left out of the frames file")

# --- Helpers -------------------------------------------------------------------------------------------------------

func _load(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img:
		img.convert(Image.FORMAT_RGBA8)
	return img

func _palette_only(img: Image) -> bool:
	if img == null:
		return false
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 == 0:
				continue
			if c.a8 != 255 or not palette.has(Color(c, 1.0)):
				return false
	return true

func _pixels(img: Image, c: Color) -> Array:
	var out := []
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a > 0.5 and p.to_html(false) == c.to_html(false):
				out.append(Vector2i(x, y))
	return out

func _opaque(img: Image) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				n += 1
	return n

func _top_row(img: Image) -> int:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				return y
	return -1

## The colour of the topmost solid pixel in the middle columns.
func _top_colour(img: Image) -> Color:
	for y in img.get_height():
		for x in range(img.get_width() / 2 - 2, img.get_width() / 2 + 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.5:
				return Color(c, 1.0)
	return Color.BLACK

## Every solid pixel next to a clear one (or the edge) is colour c.
func _edge_all(img: Image, c: Color) -> bool:
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a < 0.5:
				continue
			var edge := false
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= img.get_width() or q.y >= img.get_height() or img.get_pixelv(q).a < 0.5:
					edge = true
			if edge and p.to_html(false) != c.to_html(false):
				return false
	return true

func _same(a: Image, b: Image) -> bool:
	return a.get_data() == b.get_data()

func _mass_x(img: Image) -> float:
	var s := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				s += x
				n += 1
	return s / maxi(n, 1)

func _width(img: Image) -> int:
	var x0 := img.get_width()
	var x1 := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	return x1 - x0 + 1

## Removes a user:// test folder and everything in it (only ever under ROOT).
func _wipe(dir: String) -> void:
	if not dir.begins_with(ROOT) or not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_wipe(dir.path_join(d) + "/")
	DirAccess.remove_absolute(dir)
