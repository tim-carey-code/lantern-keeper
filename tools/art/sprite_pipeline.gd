extends RefCounted
## The sprite pipeline: one "key poses" sheet (an R x C grid of equal cells on flat magenta) becomes game-ready
## PNG strips in the layout of docs/ART_DIRECTION.md §6.2-§6.4. How-to: tools/art/README.md.
## Run from the command line with tools/art/sprite_from_sheet.gd; tools/tests/test_sprite_tool.gd drives it directly.
##
## Per cell: key out the magenta (JPEG-tolerant), crop to the content, scale it into the frame (every pose of a
## variant shares one scale and one baseline), snap each pixel to the 14-colour palette, threshold the alpha.
## Repairs (each a manifest option): paint the eyes back, add the 1 px rim (creatures) or outline (people, keeper,
## props). Then the auto frames (idle bob, move bob, hurt flash, notice flare, death dissolve, spawn, wind-up hold,
## attack lean). A strip the owner has drawn or touched up is never overwritten unless `force` is set.

const PALETTE_PATH := "res://source/palette/lantern-keeper-14.png"
const COLD_HEX := ["#0b0e1a", "#141a2e", "#1d2745", "#28385e", "#36507a", "#4a6a94", "#6d8fb3", "#a3bcd4"]
const RIM := {"small": "#36507a", "elite": "#4a6a94"}
const OUTLINE_HEX := "#141a2e"
const EYE_HEX := "#a3bcd4"
const FIRE_HEX := ["#fff1c1", "#ffd27a", "#f5a742", "#d9772b"]
const PREVIEW_BG := "#1d2745"
const PREVIEW_SCALE := 8
## Default playback rates (ART_DIRECTION §2-§3); a manifest's [anim.<name>] section overrides them.
const FPS := {"idle": 6.0, "move": 8.0, "notice": 8.0, "windup": 8.0, "attack": 10.0, "recover": 8.0, "hurt": 12.0,
	"death": 12.0, "spawn": 10.0, "flee": 10.0, "crack": 12.0, "thrust": 18.0, "lob": 14.0, "dash": 20.0,
	"drink": 10.0, "cast": 18.0, "talk": 6.0, "trade": 4.0}
const LOOPING := ["idle", "move", "flee", "talk"]
const FOLDER := {"creature": "creatures/%s/", "keeper": "keeper/", "person": "people/%s/", "prop": "props/%s/"}
const RULES := ["idle", "move", "notice", "attack", "hold", "keys", "hurt", "death", "spawn"]

var manifest := ConfigFile.new()
var palette_all: Array[Color] = []
var report := {}
var _subject := ""
var _preview_name := ""
var _kind := "creature"
var _rng := RandomNumberGenerator.new()

# --- Entry point ---------------------------------------------------------------------------------------------------

## Runs the whole pipeline. opts: out_root (default "res://assets/art/"), preview_dir (default the scratch folder),
## force (overwrite strips the owner changed), preview_only (write nothing but the preview).
## Returns the report: ok, errors, written, kept, strips {file: frames}, frames_cfg, preview, lines.
func run(sheet_path: String, manifest_path: String, opts: Dictionary = {}) -> Dictionary:
	report = {"ok": false, "errors": [], "warnings": [], "written": [], "kept": [], "strips": {}, "frames_cfg": "",
		"preview": "", "previews": [], "lines": [], "cells": 0, "cell_boxes": {}}
	if not FileAccess.file_exists(manifest_path) or manifest.load(manifest_path) != OK:
		return _fail("can't read the manifest " + manifest_path)
	if not FileAccess.file_exists(sheet_path):
		return _fail("can't find the sheet " + sheet_path)
	var sheet := Image.load_from_file(_abs(sheet_path))
	if sheet == null or sheet.is_empty():
		return _fail("can't read the sheet " + sheet_path)
	sheet.convert(Image.FORMAT_RGBA8)
	if not _load_palette():
		return _fail("can't read the palette " + PALETTE_PATH)
	_subject = str(_opt("sheet", "subject", ""))
	_preview_name = manifest_path.get_file().get_basename()
	_kind = str(_opt("sheet", "kind", "creature"))
	if _subject == "" or not FOLDER.has(_kind):
		return _fail("the manifest needs [sheet] subject and kind (creature, keeper, person or prop)")
	var rows := int(_opt("sheet", "rows", 1))
	var cols := int(_opt("sheet", "cols", 1))
	if rows < 1 or cols < 1:
		return _fail("rows and cols must be 1 or more")

	# 1. Find the cells (an equal grid, or content-based bands), then read each one: key, crop, find the eyes.
	var regions := {}
	var cell_imgs := {}
	var layout := str(_opt("sheet", "layout", "grid"))
	if layout == "auto":
		regions = _auto_cells(sheet, rows, cols)
		if regions.is_empty():
			return report
	elif layout == "components":
		cell_imgs = _component_cells(sheet, rows, cols)
		if cell_imgs.is_empty():
			return report
		for k in cell_imgs:
			regions[k] = cell_imgs[k]["rect"]
	else:
		var mg := int(_opt("sheet", "margin", 0))
		for r in rows:
			for c in cols:
				var x0 := roundi(float(c) * sheet.get_width() / cols)
				var x1 := roundi(float(c + 1) * sheet.get_width() / cols)
				var y0 := roundi(float(r) * sheet.get_height() / rows)
				var y1 := roundi(float(r + 1) * sheet.get_height() / rows)
				regions["r%dc%d" % [r, c]] = Rect2i(x0 + mg, y0 + mg, x1 - x0 - 2 * mg, y1 - y0 - 2 * mg)
	var cells: Array = []
	for r in rows:
		for c in cols:
			var cname := "r%dc%d" % [r, c]
			var spec := str(_opt("cells", cname, "skip")).strip_edges()
			if spec == "" or spec == "skip" or not regions.has(cname):
				continue
			var variant := ""
			var pose := spec
			if spec.contains("/"):
				variant = spec.get_slice("/", 0).strip_edges()
				pose = spec.get_slice("/", 1).strip_edges()
			if variant == "base":
				variant = ""
			var src: Image = cell_imgs[cname]["img"] if cell_imgs.has(cname) else sheet.get_region(regions[cname])
			var cell := _key_cell(src, variant, cname)
			cell["variant"] = variant
			cell["pose"] = pose
			cell["name"] = cname
			cell["region"] = regions[cname]
			report["cell_boxes"][cname] = regions[cname]
			if cell["box"].size.x <= 0:
				report["warnings"].append("cell %s (%s) is empty after keying: skipped" % [cname, spec])
				continue
			cells.append(cell)
	report["cells"] = cells.size()
	if cells.is_empty():
		return _fail("no cells with content (check [cells] and the magenta background)")

	# 2. Per variant: one scale and one baseline, then the key frames.
	var by_variant := {}
	for cell in cells:
		if not by_variant.has(cell["variant"]):
			by_variant[cell["variant"]] = []
		by_variant[cell["variant"]].append(cell)
	var out_root := str(opts.get("out_root", "res://assets/art/"))
	if not out_root.ends_with("/"):
		out_root += "/"
	var pattern: String = FOLDER[_kind]
	var folder: String = out_root + (pattern % _subject if pattern.contains("%s") else pattern)
	if manifest.has_section_key("sheet", "folder"):
		folder = out_root + str(manifest.get_value("sheet", "folder")).trim_suffix("/") + "/"
	var file_base := "keeper" if _kind == "keeper" else _subject
	var strips: Array = []         # {file, variant, anim, frames: Array[Image], size, thumb}
	for variant in by_variant:
		strips.append_array(_build_variant(variant, by_variant[variant], file_base))

	# 3. Write (never over owner art), merge the frames file, make the preview.
	var preview_only := bool(opts.get("preview_only", false))
	if not preview_only:
		DirAccess.make_dir_recursive_absolute(_abs(folder))
	var gen_path := folder + file_base + ".generated.cfg"
	var gen := ConfigFile.new()
	if FileAccess.file_exists(gen_path):
		gen.load(gen_path)
	for s in strips:
		var path: String = folder + s["file"]
		var img := _join(s["frames"], s["size"])
		s["image"] = img
		report["strips"][s["file"]] = s["frames"].size()
		if preview_only:
			continue
		if FileAccess.file_exists(path) and not bool(opts.get("force", false)):
			var md5 := FileAccess.get_md5(path)
			if str(gen.get_value("files", s["file"], "")) != md5:
				report["kept"].append(path)
				s["kept"] = true
				var owner := Image.load_from_file(_abs(path))
				if owner != null and not owner.is_empty():
					s["image"] = owner
				continue
		var err := img.save_png(_abs(path))
		if err != OK:
			report["errors"].append("can't write %s (error %d)" % [path, err])
			continue
		gen.set_value("files", s["file"], FileAccess.get_md5(path))
		report["written"].append(path)
	if not preview_only:
		gen.save(gen_path)
		report["frames_cfg"] = _merge_frames_cfg(folder + file_base + ".frames.cfg", strips, by_variant.keys())
	var pdir := str(opts.get("preview_dir", OS.get_environment("HOME") + "/.cache/openclaw/project-scratch/sprite-previews/"))
	report["preview"] = _write_preview(pdir, strips)
	report["ok"] = report["errors"].is_empty()
	_summary(folder, strips)
	return report

# --- Manifest helpers ----------------------------------------------------------------------------------------------

func _opt(section: String, key: String, fallback: Variant) -> Variant:
	if manifest.has_section_key(section, key):
		return manifest.get_value(section, key)
	return fallback

## A variant's option: [variant.<v>] first, then [sheet], then the default for this kind of subject.
func _vopt(variant: String, key: String) -> Variant:
	var sec := "variant." + (variant if variant != "" else "base")
	if manifest.has_section_key(sec, key):
		return manifest.get_value(sec, key)
	if manifest.has_section_key("sheet", key):
		return manifest.get_value("sheet", key)
	var creature := _kind == "creature"
	match key:
		"frame_size": return 16
		"anchor": return "foot"
		"facing": return "right"
		"rim": return "small" if creature else "none"
		"outline": return not creature
		"eyes": return 2 if creature else 0
		"eye_threshold": return 0.62
		"eye_min_area": return 4
		"eye_size_max": return 2
		"palette": return "cold" if creature else "all"
		"flash": return "#a3bcd4" if creature else "#fff1c1"
		"sway": return creature
		"alpha_threshold": return 0.5
		"key_lo": return 0.15
		"key_hi": return 0.85
		"key_mode": return "magenta"
		"keep": return "all"
		"keep_near": return 0
		"fill": return 1.0
		"gain": return 1.0
		"align_x": return "mass"
		"seed": return hash(_subject + "/" + variant) & 0x7fffffff
	return null

## A cell's option: [cell.rXcY] first, then the variant chain.
func _copt(cname: String, variant: String, key: String, fallback: Variant = null) -> Variant:
	if manifest.has_section_key("cell." + cname, key):
		return manifest.get_value("cell." + cname, key)
	var v: Variant = _vopt(variant, key)
	return v if v != null else fallback

## A pose's option: [pose.<v>.<pose>] first, then the variant chain.
func _popt(variant: String, pose: String, key: String, fallback: Variant = null) -> Variant:
	var sec := "pose.%s.%s" % [variant if variant != "" else "base", pose]
	if manifest.has_section_key(sec, key):
		return manifest.get_value(sec, key)
	var v: Variant = _vopt(variant, key)
	return v if v != null else fallback

static func _size_of(v: Variant) -> Vector2i:
	if v is Vector2i:
		return v
	if v is Vector2:
		return Vector2i(v)
	return Vector2i(int(v), int(v))

# --- Keying, cropping, eye finding ---------------------------------------------------------------------------------

## A pixel's alpha. "magenta": its magenta-ness m = min(r, b) - g, from key_lo (opaque) to key_hi (clear).
## "hue" also clears dark magenta and purple (grid lines between cells): it judges m against the pixel's brightness.
static func key_alpha(r: float, g: float, b: float, lo: float, hi: float, hue: bool) -> float:
	var m := minf(r, b) - g
	var al := clampf((hi - m) / maxf(hi - lo, 0.01), 0.0, 1.0)
	if hue and m > 0.015:
		var rel := m / maxf(maxf(r, b), 0.01)
		al = minf(al, clampf((0.65 - rel) / 0.3, 0.0, 1.0))
	return al

## Content-based cells: row bands split by clear rows, then column bands in each row. Extra bands (a spit glob, a
## spark) merge across the narrowest gap until the count matches rows and cols (or [sheet] cols_r<N>).
func _auto_cells(sheet: Image, rows: int, cols: int) -> Dictionary:
	var w := sheet.get_width()
	var h := sheet.get_height()
	var data := sheet.get_data()
	var lo := float(_vopt("", "key_lo"))
	var hi := float(_vopt("", "key_hi"))
	var hue := str(_vopt("", "key_mode")) == "hue"
	var solid := PackedByteArray()
	solid.resize(w * h)
	var row_n := PackedInt32Array()
	row_n.resize(h)
	for y in h:
		for x in w:
			var i := (y * w + x) * 4
			if key_alpha(data[i] / 255.0, data[i + 1] / 255.0, data[i + 2] / 255.0, lo, hi, hue) > 0.5:
				solid[y * w + x] = 1
				row_n[y] += 1
	var pad := int(_opt("sheet", "auto_pad", 4))
	var row_bands := _bands(row_n, rows)
	if row_bands.size() != rows:
		_fail("auto layout: found %d row bands, the manifest says %d" % [row_bands.size(), rows])
		return {}
	var out := {}
	for r in rows:
		var y0: int = row_bands[r].x
		var y1: int = row_bands[r].y
		var col_n := PackedInt32Array()
		col_n.resize(w)
		for y in range(y0, y1):
			for x in w:
				if solid[y * w + x] == 1:
					col_n[x] += 1
		var want := int(_opt("sheet", "cols_r%d" % r, cols))
		var col_bands := _bands(col_n, want)
		if col_bands.size() != want:
			_fail("auto layout: row %d has %d column bands, the manifest says %d" % [r, col_bands.size(), want])
			return {}
		for c in want:
			var x0: int = maxi(0, col_bands[c].x - pad)
			var x1: int = mini(w, col_bands[c].y + pad)
			out["r%dc%d" % [r, c]] = Rect2i(x0, maxi(0, y0 - pad), x1 - x0, mini(h, y1 + pad) - maxi(0, y0 - pad))
	report["lines"].append("  auto layout: " + ", ".join(out.keys().map(func(k): return "%s %s" % [k, str(out[k])])))
	return out

## Connected-component cells, for sheets whose cells overlap in x or y (a wing under the next pose). The solid mask
## is labelled at 1/component_scale size; rows come from clear row bands; in each row the `cols` biggest shapes are
## the cells (left to right) and every smaller shape (an ash ring, a flame) joins the nearest one. Each cell's image
## is its shapes alone, everything else painted magenta. Returns {cname: {"rect": Rect2i, "img": Image}}.
func _component_cells(sheet: Image, rows: int, cols: int) -> Dictionary:
	var k := maxi(1, int(_opt("sheet", "component_scale", 4)))
	var w := sheet.get_width()
	var h := sheet.get_height()
	var lw := (w + k - 1) / k
	var lh := (h + k - 1) / k
	var data := sheet.get_data()
	var lo := float(_vopt("", "key_lo"))
	var hi := float(_vopt("", "key_hi"))
	var hue := str(_vopt("", "key_mode")) == "hue"
	var low := PackedByteArray()
	low.resize(lw * lh)
	for y in h:
		var ly := (y / k) * lw
		for x in w:
			var i := (y * w + x) * 4
			if key_alpha(data[i] / 255.0, data[i + 1] / 255.0, data[i + 2] / 255.0, lo, hi, hue) > 0.5:
				low[ly + x / k] = 1
	# Label (8-connected).
	var label := PackedInt32Array()
	label.resize(lw * lh)
	var area: Array[int] = [0]
	var boxes: Array[Rect2i] = [Rect2i()]
	var cy_sum: Array[float] = [0.0]
	var cx_sum: Array[float] = [0.0]
	var stack := PackedInt32Array()
	for start in lw * lh:
		if low[start] == 0 or label[start] != 0:
			continue
		var id := area.size()
		label[start] = id
		stack.append(start)
		var n := 0
		var bx := Rect2i(start % lw, start / lw, 1, 1)
		var sx := 0.0
		var sy := 0.0
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % lw
			var y := i / lw
			n += 1
			sx += x
			sy += y
			bx = bx.expand(Vector2i(x + 1, y + 1)).expand(Vector2i(x, y))
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = x + dx
					var ny: int = y + dy
					if nx < 0 or ny < 0 or nx >= lw or ny >= lh:
						continue
					var j := ny * lw + nx
					if low[j] == 1 and label[j] == 0:
						label[j] = id
						stack.append(j)
		area.append(n)
		boxes.append(bx)
		cx_sum.append(sx / n)
		cy_sum.append(sy / n)
	var row_n := PackedInt32Array()
	row_n.resize(lh)
	for y in lh:
		for x in lw:
			if low[y * lw + x] == 1:
				row_n[y] += 1
	var row_bands := _bands(row_n, rows)
	if row_bands.size() != rows:
		_fail("components layout: found %d row bands, the manifest says %d" % [row_bands.size(), rows])
		return {}
	var min_area := int(_opt("sheet", "component_min_area", 2))
	var owner := PackedInt32Array()       # component -> cell index (r * 1000 + c), -1 = dropped
	owner.resize(area.size())
	owner.fill(-1)
	var out := {}
	for r in rows:
		var want := int(_opt("sheet", "cols_r%d" % r, cols))
		var comps: Array[int] = []
		for id in range(1, area.size()):
			if area[id] >= min_area and cy_sum[id] >= row_bands[r].x and cy_sum[id] < row_bands[r].y:
				comps.append(id)
		if comps.size() < want:
			_fail("components layout: row %d has %d shapes, the manifest says %d" % [r, comps.size(), want])
			return {}
		var by_area := comps.duplicate()
		by_area.sort_custom(func(a, b): return area[a] > area[b])
		var seeds: Array = by_area.slice(0, want)
		seeds.sort_custom(func(a, b): return cx_sum[a] < cx_sum[b])
		for c in want:
			owner[seeds[c]] = r * 1000 + c
		# Every other shape joins the seed with the nearest pixel (a multi-source walk over the row band).
		var near := _nearest_seed(label, lw, lh, Rect2i(0, row_bands[r].x, lw, row_bands[r].y - row_bands[r].x), seeds)
		for id in comps:
			if owner[id] >= 0:
				continue
			var b: Rect2i = boxes[id]
			var votes := {}
			for y in range(b.position.y, b.end.y):
				for x in range(b.position.x, b.end.x):
					if label[y * lw + x] == id and near.has(y * lw + x):
						var s: int = near[y * lw + x]
						votes[s] = int(votes.get(s, 0)) + 1
			var best := -1
			for s in votes:
				if best < 0 or votes[s] > votes[best]:
					best = s
			if best >= 0:
				owner[id] = r * 1000 + best
	var pad := int(_opt("sheet", "auto_pad", 4))
	for r in rows:
		for c in int(_opt("sheet", "cols_r%d" % r, cols)):
			var tag := r * 1000 + c
			var lb := Rect2i()
			var first := true
			for id in range(1, area.size()):
				if owner[id] == tag:
					lb = boxes[id] if first else lb.merge(boxes[id])
					first = false
			var rect := Rect2i(lb.position * k, lb.size * k).grow(pad).intersection(Rect2i(0, 0, w, h))
			var img := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
			img.fill(Color(1, 0, 1))
			for y in rect.size.y:
				var gy := rect.position.y + y
				for x in rect.size.x:
					var gx := rect.position.x + x
					var id := label[(gy / k) * lw + gx / k]
					if id > 0 and owner[id] == tag:
						var i := (gy * w + gx) * 4
						img.set_pixel(x, y, Color8(data[i], data[i + 1], data[i + 2]))
			out["r%dc%d" % [r, c]] = {"rect": rect, "img": img}
	report["lines"].append("  components layout: " + ", ".join(out.keys().map(func(key): return "%s %s" % [key, str(out[key]["rect"])])))
	return out

## For each low-res pixel in `area`, the index (into seeds) of the nearest seed shape (8-neighbour steps).
static func _nearest_seed(label: PackedInt32Array, lw: int, lh: int, area: Rect2i, seeds: Array) -> Dictionary:
	var near := {}
	var queue := PackedInt32Array()
	var seed_of := {}
	for s in seeds.size():
		seed_of[seeds[s]] = s
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var i := y * lw + x
			if seed_of.has(label[i]):
				near[i] = seed_of[label[i]]
				queue.append(i)
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % lw
		var y := i / lw
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var nx: int = x + dx
				var ny: int = y + dy
				if nx < area.position.x or ny < area.position.y or nx >= area.end.x or ny >= area.end.y:
					continue
				var j := ny * lw + nx
				if not near.has(j):
					near[j] = near[i]
					queue.append(j)
	return near

## Runs of counts >= 2 (start, end) split by clear gaps; then merge across the narrowest gaps down to `want`.
static func _bands(counts: PackedInt32Array, want: int) -> Array:
	var bands: Array = []
	var start := -1
	for i in counts.size():
		if counts[i] >= 2:
			if start < 0:
				start = i
		elif start >= 0:
			bands.append(Vector2i(start, i))
			start = -1
	if start >= 0:
		bands.append(Vector2i(start, counts.size()))
	# Specks a few px across (JPEG noise) are dropped before merging.
	bands = bands.filter(func(b): return b.y - b.x >= 3)
	while bands.size() > want and bands.size() > 1:
		var best := 0
		var best_gap := 1 << 30
		for i in bands.size() - 1:
			var gap: int = bands[i + 1].x - bands[i].y
			# A small band is pulled into its neighbour first: weigh the gap by the smaller band's size.
			var small: int = mini(bands[i].y - bands[i].x, bands[i + 1].y - bands[i + 1].x)
			var score := gap * 4 + small
			if score < best_gap:
				best_gap = score
				best = i
		bands[best] = Vector2i(bands[best].x, bands[best + 1].y)
		bands.remove_at(best + 1)
	return bands

## Keys one cell (key_alpha); the magenta spill is taken back out of the colour (premultiplied). Then the cell's
## keep ("largest": only the biggest connected shape, plus shapes within keep_near px of it) and region
## ([x0, y0, x1, y1] as fractions of the cell) options. Returns w, h, a, pr, pg, pb, box, mass_x, eyes.
func _key_cell(img: Image, variant: String, cname: String = "") -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var lo := float(_copt(cname, variant, "key_lo"))
	var hi := float(_copt(cname, variant, "key_hi"))
	var hue := str(_copt(cname, variant, "key_mode")) == "hue"
	var a := PackedFloat32Array()
	var pr := PackedFloat32Array()
	var pg := PackedFloat32Array()
	var pb := PackedFloat32Array()
	a.resize(w * h)
	pr.resize(w * h)
	pg.resize(w * h)
	pb.resize(w * h)
	var reg: Variant = _copt(cname, variant, "region", null)
	var rx0 := 0
	var ry0 := 0
	var rx1 := w
	var ry1 := h
	if reg is Array and reg.size() == 4:
		rx0 = roundi(float(reg[0]) * w)
		ry0 = roundi(float(reg[1]) * h)
		rx1 = roundi(float(reg[2]) * w)
		ry1 = roundi(float(reg[3]) * h)
	for y in h:
		for x in w:
			var i := y * w + x
			if x < rx0 or x >= rx1 or y < ry0 or y >= ry1:
				continue      # outside the region: clear (the arrays start at 0)
			var r := data[i * 4] / 255.0
			var g := data[i * 4 + 1] / 255.0
			var b := data[i * 4 + 2] / 255.0
			var al := key_alpha(r, g, b, lo, hi, hue)
			a[i] = al
			pr[i] = clampf(r - (1.0 - al), 0.0, al)
			pg[i] = minf(g, al)
			pb[i] = clampf(b - (1.0 - al), 0.0, al)
	if str(_copt(cname, variant, "keep")) == "largest":
		a = _keep_largest(a, w, h, int(_copt(cname, variant, "keep_near")))
		for i in w * h:
			if a[i] <= 0.0:
				pr[i] = 0.0
				pg[i] = 0.0
				pb[i] = 0.0
	var col_count := PackedInt32Array()
	var row_count := PackedInt32Array()
	col_count.resize(w)
	row_count.resize(h)
	var mass := 0.0
	var mass_x := 0.0
	for y in h:
		for x in w:
			var i := y * w + x
			if a[i] > 0.5:
				col_count[x] += 1
				row_count[y] += 1
				mass += 1.0
				mass_x += x
	# The box: rows and columns with at least 2 solid pixels (lone JPEG specks don't count).
	var bx0 := -1
	var bx1 := -1
	var by0 := -1
	var by1 := -1
	for x in w:
		if col_count[x] >= 2:
			if bx0 < 0:
				bx0 = x
			bx1 = x
	for y in h:
		if row_count[y] >= 2:
			if by0 < 0:
				by0 = y
			by1 = y
	var box := Rect2i() if bx0 < 0 or by0 < 0 else Rect2i(bx0, by0, bx1 - bx0 + 1, by1 - by0 + 1)
	var cell := {"w": w, "h": h, "a": a, "pr": pr, "pg": pg, "pb": pb, "box": box,
		"mass_x": mass_x / mass if mass > 0.0 else w / 2.0, "eyes": []}
	if box.size.x > 0 and int(_copt(cname, variant, "eyes")) > 0:
		cell["eyes"] = _find_eyes(cell, variant, cname)
	return cell

## keep = "largest": clears every solid shape (8-connected) but the biggest, and those within `near` px of its box.
func _keep_largest(a: PackedFloat32Array, w: int, h: int, near: int) -> PackedFloat32Array:
	var label := PackedInt32Array()
	label.resize(w * h)
	var sizes: Array[int] = [0]
	var boxes: Array[Rect2i] = [Rect2i()]
	var next := 1
	var stack := PackedInt32Array()
	for start in w * h:
		if a[start] <= 0.5 or label[start] != 0:
			continue
		label[start] = next
		stack.append(start)
		var n := 0
		var bx := Rect2i(start % w, start / w, 1, 1)
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			n += 1
			var x := i % w
			var y := i / w
			bx = bx.expand(Vector2i(x, y)).expand(Vector2i(x + 1, y + 1))
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = x + dx
					var ny: int = y + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var j := ny * w + nx
					if a[j] > 0.5 and label[j] == 0:
						label[j] = next
						stack.append(j)
		sizes.append(n)
		boxes.append(bx)
		next += 1
	if next <= 2:
		return a
	var big := 1
	for k in range(1, next):
		if sizes[k] > sizes[big]:
			big = k
	var keep := {big: true}
	if near > 0:
		var grown := boxes[big].grow(near)
		for k in range(1, next):
			if grown.intersects(boxes[k]):
				keep[k] = true
	# Faint edge pixels (no label) stay when they sit by a kept shape.
	var kept_boxes: Array[Rect2i] = []
	for k in keep:
		kept_boxes.append(boxes[k].grow(2))
	for i in w * h:
		if a[i] <= 0.0:
			continue
		if label[i] != 0:
			if not keep.has(label[i]):
				a[i] = 0.0
			continue
		var p := Vector2i(i % w, i / w)
		var by := false
		for bx in kept_boxes:
			if bx.has_point(p):
				by = true
				break
		if not by:
			a[i] = 0.0
	return a

## The eyes in the big source: bright, cold (not warm) blobs on the body. Biggest first, up to `eyes` of them.
func _find_eyes(cell: Dictionary, variant: String, cname: String = "") -> Array:
	var w: int = cell["w"]
	var box: Rect2i = cell["box"]
	var thr := float(_copt(cname, variant, "eye_threshold"))
	var min_area := int(_copt(cname, variant, "eye_min_area"))
	var bright := {}
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var i := y * w + x
			var al: float = cell["a"][i]
			if al < 0.9:
				continue
			var r: float = cell["pr"][i] / al
			var g: float = cell["pg"][i] / al
			var b: float = cell["pb"][i] / al
			if 0.299 * r + 0.587 * g + 0.114 * b > thr and b >= r - 0.05:
				bright[Vector2i(x, y)] = true
	var blobs: Array = []
	var seen := {}
	for p in bright:
		if seen.has(p):
			continue
		var stack: Array[Vector2i] = [p]
		seen[p] = true
		var n := 0
		var sum := Vector2.ZERO
		var mn: Vector2i = p
		var mx: Vector2i = p
		while not stack.is_empty():
			var q: Vector2i = stack.pop_back()
			n += 1
			sum += Vector2(q)
			mn = mn.min(q)
			mx = mx.max(q)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nq: Vector2i = q + d
				if bright.has(nq) and not seen.has(nq):
					seen[nq] = true
					stack.append(nq)
		if n >= min_area:
			blobs.append({"area": n, "c": sum / n + Vector2(0.5, 0.5), "size": Vector2(mx - mn + Vector2i.ONE)})
	blobs.sort_custom(func(p, q): return p["area"] > q["area"])
	return blobs.slice(0, int(_copt(cname, variant, "eyes")))

# --- Scaling, palette, repairs ---------------------------------------------------------------------------------------

func _load_palette() -> bool:
	palette_all.clear()
	var img := Image.load_from_file(_abs(PALETTE_PATH))
	if img == null or img.is_empty():
		return false
	img.convert(Image.FORMAT_RGBA8)
	for x in img.get_width():
		var c := img.get_pixel(x, 0)
		c.a = 1.0
		if not palette_all.has(c):
			palette_all.append(c)
	return palette_all.size() >= 8

func _palette_for(variant: String, cname: String = "") -> Array[Color]:
	var p: Variant = _copt(cname, variant, "palette")
	var out: Array[Color] = []
	if p is Array or p is PackedStringArray:
		for hx in p:
			out.append(Color.html(str(hx)))
	elif str(p) == "cold":
		for hx in COLD_HEX:
			out.append(Color.html(hx))
	else:
		out = palette_all.duplicate()
	return out

## A fire-coloured pixel: a saturated, not-too-dark orange or amber (bone beige and wood browns are not).
static func is_fire(c: Color) -> bool:
	return c.s > 0.5 and c.v > 0.35 and (c.h < 0.17 or c.h > 0.97)

## Nearest palette colour ("redmean" weighted RGB distance: close to how the eye judges it, and cheap).
static func snap(c: Color, pal: Array[Color]) -> Color:
	var best := pal[0]
	var bd := INF
	for p in pal:
		var rm := (c.r + p.r) * 0.5
		var dr := c.r - p.r
		var dg := c.g - p.g
		var db := c.b - p.b
		var d := (2.0 + rm) * dr * dr + 4.0 * dg * dg + (3.0 - rm) * db * db
		if d < bd:
			bd = d
			best = p
	return best

## Builds every strip for one variant: key frames, repairs, then the animation rules.
func _build_variant(variant: String, cells: Array, file_base: String) -> Array:
	var size := _size_of(_vopt(variant, "frame_size"))
	var outline := bool(_vopt(variant, "outline"))
	var facing := 1 if str(_vopt(variant, "facing")) != "left" else -1
	var has_attack := false
	for cell in cells:
		if _rule_for(variant, cell["pose"], 1) == "attack":
			has_attack = true
	var pad_side := (1 if outline else 0) + (1 if has_attack else 0)
	var pad_top := 1 + (1 if outline else 0)        # room for the idle and move bob
	var pad_bottom := 1 if outline else 0
	# The union box: the widest and tallest pose of the variant sets one scale for all of them. A pose with
	# fit = "own" is scaled to fit by itself instead, and fit = "clip" uses the shared scale but may be cut off;
	# neither widens the union (a stretched flee or a long reach would shrink every other pose).
	var max_w := 1
	var max_h := 1
	for cell in cells:
		if str(_popt(variant, cell["pose"], "fit", "variant")) == "variant":
			max_w = maxi(max_w, cell["box"].size.x)
			max_h = maxi(max_h, cell["box"].size.y)
	var avail := Vector2(size.x - 2 * pad_side, size.y - pad_top - pad_bottom)
	var fill := clampf(float(_vopt(variant, "fill")), 0.1, 1.0)
	var s := minf(avail.x / max_w, avail.y / max_h) * fill
	# Key frames, in cell order; a pose that has several cells becomes a hand-keyed strip of those frames.
	var keys := {}        # pose -> Array of {img, eyes, thumb}
	var order: Array = []
	for cell in cells:
		var cs := s
		if str(_popt(variant, cell["pose"], "fit", "variant")) == "own":
			cs = minf(avail.x / cell["box"].size.x, avail.y / cell["box"].size.y) * fill
		var key := _key_frame(cell, variant, size, cs, pad_side, pad_bottom, _palette_for(variant, cell["name"]))
		if not keys.has(cell["pose"]):
			keys[cell["pose"]] = []
			order.append(cell["pose"])
		keys[cell["pose"]].append(key)
	var prefix := file_base + ("_" + variant if variant != "" else "")
	var out: Array = []
	var made := {}
	for pose in order:
		var list: Array = keys[pose]
		var anim := str(_popt(variant, pose, "anim", pose))
		var rule := _rule_for(variant, pose, list.size())
		var frames := _apply_rule(rule, list, variant, pose, size, facing, outline)
		if frames.is_empty():
			continue
		out.append({"file": "%s_%s.png" % [prefix, anim], "variant": variant, "anim": anim, "frames": frames,
			"size": size, "thumb": list[0]["thumb"], "rule": rule})
		made[anim] = true
	# Derived strips (hurt, death, spawn, notice, windup) from a key pose, when the sheet has no key for them.
	for pose in order:
		for d in _derive_for(variant, pose, order):
			var dname := str(d)
			if made.has(dname):
				continue
			var drule := "hold" if dname.begins_with("windup") else dname
			if not RULES.has(drule):
				report["warnings"].append("%s/%s: unknown derive '%s' skipped" % [variant, pose, dname])
				continue
			var key: Dictionary = keys[pose][0]
			var frames := _apply_rule(drule, [key], variant, pose, size, facing, outline)
			out.append({"file": "%s_%s.png" % [prefix, dname], "variant": variant, "anim": dname, "frames": frames,
				"size": size, "thumb": key["thumb"], "rule": drule + " (from " + pose + ")"})
			made[dname] = true
	return out

func _rule_for(variant: String, pose: String, key_count: int) -> String:
	var sec := "pose.%s.%s" % [variant if variant != "" else "base", pose]
	if manifest.has_section_key(sec, "rule"):
		var r := str(manifest.get_value(sec, "rule"))
		return "hold" if r == "none" or r == "off" else r
	if key_count > 1:
		return "keys"
	if pose == "idle" or pose == "move" or pose == "notice":
		return pose
	if pose == "flee":
		return "move"
	if pose.begins_with("attack"):
		return "attack"
	return "hold"

func _derive_for(variant: String, pose: String, poses: Array) -> Array:
	var sec := "pose.%s.%s" % [variant if variant != "" else "base", pose]
	if manifest.has_section_key(sec, "derive"):
		return Array(manifest.get_value(sec, "derive"))
	if _kind != "creature":
		return []
	if pose == "idle":
		var d := ["hurt", "death", "spawn"]
		if not poses.has("notice"):
			d.append("notice")
		return d
	if pose.begins_with("attack"):
		var wname := pose.replace("attack", "windup")
		return [] if poses.has(wname) else [wname]
	return []

## One key frame: scaled into the frame at the shared scale, palette-snapped, alpha thresholded, rim and eyes.
func _key_frame(cell: Dictionary, variant: String, size: Vector2i, s: float, pad_side: int, pad_bottom: int, pal: Array[Color]) -> Dictionary:
	var box: Rect2i = cell["box"]
	var w: int = cell["w"]
	var tw := maxi(1, roundi(box.size.x * s))
	var th := maxi(1, roundi(box.size.y * s))
	var ox: int
	if str(_vopt(variant, "align_x")) == "box":
		ox = (size.x - tw) / 2
	else:
		ox = roundi(size.x / 2.0 - (float(cell["mass_x"]) - box.position.x) * s)
	ox = clampi(ox, pad_side, maxi(pad_side, size.x - pad_side - tw)) if tw <= size.x - 2 * pad_side else (size.x - tw) / 2
	var oy := size.y - pad_bottom - th
	var thr := float(_vopt(variant, "alpha_threshold"))
	var gain := float(_vopt(variant, "gain"))
	var cname: String = cell.get("name", "")
	# warm: "snap" (every pixel to the palette), "ember" (fire-coloured pixels keep the four ambers, optionally only
	# inside ember_region, fractions of the cell; the rest snaps to the palette) or "drop" (fire-coloured pixels clear).
	var warm := str(_copt(cname, variant, "warm", "snap"))
	var ember_rect := Rect2()
	var er: Variant = _copt(cname, variant, "ember_region", null)
	if er is Array and er.size() == 4:
		ember_rect = Rect2(float(er[0]) * cell["w"], float(er[1]) * cell["h"], (float(er[2]) - float(er[0])) * cell["w"], (float(er[3]) - float(er[1])) * cell["h"])
	var fire: Array[Color] = []
	for hx in FIRE_HEX:
		fire.append(Color.html(hx))
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	for ty in th:
		var sy0 := box.position.y + int(floor(ty / s))
		var sy1 := maxi(sy0 + 1, box.position.y + int(floor((ty + 1) / s)))
		sy1 = mini(sy1, box.end.y)
		for tx in tw:
			var sx0 := box.position.x + int(floor(tx / s))
			var sx1 := maxi(sx0 + 1, box.position.x + int(floor((tx + 1) / s)))
			sx1 = mini(sx1, box.end.x)
			var sa := 0.0
			var sr := 0.0
			var sg := 0.0
			var sb := 0.0
			var n := 0
			for yy in range(sy0, sy1):
				for xx in range(sx0, sx1):
					var i := yy * w + xx
					sa += cell["a"][i]
					sr += cell["pr"][i]
					sg += cell["pg"][i]
					sb += cell["pb"][i]
					n += 1
			if n == 0 or sa / n < thr:
				continue
			var px := ox + tx
			var py := oy + ty
			if px < 0 or py < 0 or px >= size.x or py >= size.y:
				continue
			var col := Color(sr / sa * gain, sg / sa * gain, sb / sa * gain)
			if warm != "snap" and is_fire(col):
				if warm == "drop":
					continue
				if warm == "ember" and (ember_rect.size.x <= 0.0 or ember_rect.has_point(Vector2((sx0 + sx1) * 0.5, (sy0 + sy1) * 0.5))):
					img.set_pixel(px, py, snap(col, fire))
					continue
			img.set_pixel(px, py, snap(col, pal))
	# The rim: top and the light side, on body pixels darker than the rim colour (wings and shells stay).
	var rim := str(_vopt(variant, "rim"))
	var facing := 1 if str(_vopt(variant, "facing")) != "left" else -1
	if rim != "none" and rim != "false" and rim != "":
		var rc := Color.html(RIM.get(rim, rim))
		var src := img.duplicate() as Image
		for y in size.y:
			for x in size.x:
				var c := src.get_pixel(x, y)
				if c.a < 0.5 or c.get_luminance() >= rc.get_luminance():
					continue
				if not _solid(src, x, y - 1) or not _solid(src, x + facing, y):
					img.set_pixel(x, y, rc)
	# The eyes: found in the big source, painted back at the scaled spot, at least 1 px, the pair kept apart.
	var eyes: Array[Vector2i] = []
	if not cell["eyes"].is_empty():
		var max_e := int(_vopt(variant, "eye_size_max"))
		var spots: Array = []
		for e in cell["eyes"]:
			var p := Vector2i(floori(ox + (e["c"].x - box.position.x) * s), floori(oy + (e["c"].y - box.position.y) * s))
			var es := Vector2i(clampi(roundi(e["size"].x * s), 1, max_e), clampi(roundi(e["size"].y * s), 1, max_e))
			spots.append({"p": p - (es - Vector2i.ONE) / 2, "s": es})
		spots.sort_custom(func(p, q): return p["p"].x < q["p"].x)
		for i in range(1, spots.size()):
			var lp: Vector2i = spots[i - 1]["p"]
			var ls: Vector2i = spots[i - 1]["s"]
			var rp: Vector2i = spots[i]["p"]
			var rs: Vector2i = spots[i]["s"]
			# Rows that touch (diagonals too): keep at least one clear column between the two eyes.
			if rp.y <= lp.y + ls.y and lp.y <= rp.y + rs.y:
				var gap := rp.x - (lp.x + ls.x)
				if gap < 1:
					var need := 1 - gap
					var left_move := need / 2 + need % 2
					spots[i - 1]["p"] = lp - Vector2i(left_move, 0)
					spots[i]["p"] = rp + Vector2i(need - left_move, 0)
		var ec := Color.html(EYE_HEX)
		for sp in spots:
			for yy in sp["s"].y:
				for xx in sp["s"].x:
					var q: Vector2i = sp["p"] + Vector2i(xx, yy)
					if q.x >= 0 and q.y >= 0 and q.x < size.x and q.y < size.y:
						img.set_pixelv(q, ec)
						eyes.append(q)
	# A small thumbnail of the source (keyed over the preview background) for the preview's left column.
	var thumb := Image.create(box.size.x, box.size.y, false, Image.FORMAT_RGBA8)
	var bg := Color.html(PREVIEW_BG)
	for y in box.size.y:
		for x in box.size.x:
			var i := (box.position.y + y) * w + box.position.x + x
			var al: float = cell["a"][i]
			thumb.set_pixel(x, y, Color(cell["pr"][i] + (1.0 - al) * bg.r, cell["pg"][i] + (1.0 - al) * bg.g, cell["pb"][i] + (1.0 - al) * bg.b))
	return {"img": img, "eyes": eyes, "thumb": thumb}

static func _solid(img: Image, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return false
	return img.get_pixel(x, y).a > 0.5

## The 1 px outline (#141a2e) around the silhouette: every clear pixel next to a solid one.
static func outlined(img: Image) -> Image:
	var out := img.duplicate() as Image
	var oc := Color.html(OUTLINE_HEX)
	for y in img.get_height():
		for x in img.get_width():
			if _solid(img, x, y):
				continue
			if _solid(img, x - 1, y) or _solid(img, x + 1, y) or _solid(img, x, y - 1) or _solid(img, x, y + 1):
				out.set_pixel(x, y, oc)
	return out

# --- Animation rules -----------------------------------------------------------------------------------------------

func _apply_rule(rule: String, keys: Array, variant: String, pose: String, size: Vector2i, facing: int, outline: bool) -> Array:
	var key: Image = keys[0]["img"]
	var eyes: Array = keys[0]["eyes"]
	var frames: Array = []
	var bob := int(_popt(variant, pose, "bob", 1))
	match rule:
		"keys":
			for k in keys:
				frames.append(k["img"])
		"idle", "move":
			var n := int(_popt(variant, pose, "frames", 4 if pose != "flee" else 2))
			var bobs := [0, -bob, -bob, 0] if n == 4 else ([0, -bob] if n == 2 else [0])
			var sway := rule == "idle" and bool(_popt(variant, pose, "sway", false))
			var sways := [0, 1, 0, -1]
			for i in n:
				var f := key
				if sway:
					f = _sway(f, sways[i % 4])
				frames.append(_shift(f, 0, bobs[i % bobs.size()]))
		"hold":
			frames.append(key)
		"attack":
			var lean := int(_popt(variant, pose, "lean", 1))
			frames.append(_lean(key, lean * facing))
			frames.append(key)
		"notice":
			frames.append(key)
			frames.append(_flare(key, eyes))
		"hurt":
			frames.append(_flash(outlined(key) if outline else key, Color.html(str(_popt(variant, pose, "flash", "#a3bcd4")))))
			frames.append(key)
		"death", "spawn":
			var seq := _dissolve(outlined(key) if outline else key, eyes, int(_popt(variant, pose, "seed", 1)))
			if rule == "death":
				frames = seq.slice(1, 6)
			else:
				frames = seq.slice(0, 5)
				frames.reverse()
			return frames      # already outlined
		_:
			report["warnings"].append("%s/%s: unknown rule '%s', held the key pose" % [variant, pose, rule])
			frames.append(key)
	if outline:
		var o: Array = []
		for f in frames:
			o.append(outlined(f))
		return o
	return frames

static func _shift(img: Image, dx: int, dy: int) -> Image:
	if dx == 0 and dy == 0:
		return img
	var out := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(dx, dy))
	return out

## The wisp sway: the bottom third of the body moves dx sideways.
static func _sway(img: Image, dx: int) -> Image:
	if dx == 0:
		return img
	var top := img.get_height()
	var bottom := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				top = mini(top, y)
				bottom = y
				break
	if bottom < 0:
		return img
	var from := bottom - (bottom - top + 1) / 3 + 1
	var out := img.duplicate() as Image
	out.fill_rect(Rect2i(0, from, img.get_width(), img.get_height() - from), Color(0, 0, 0, 0))
	out.blit_rect(img, Rect2i(0, from, img.get_width(), img.get_height() - from), Vector2i(dx, from))
	return out

## The attack lean: the top half moves 1 px forward.
static func _lean(img: Image, dx: int) -> Image:
	var mid := img.get_height() / 2
	for y in img.get_height():
		var row_has := false
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				row_has = true
				break
		if row_has:
			var bottom := y
			for yy in range(img.get_height() - 1, y - 1, -1):
				var any := false
				for x in img.get_width():
					if img.get_pixel(x, yy).a > 0.5:
						any = true
						break
				if any:
					bottom = yy
					break
			mid = y + (bottom - y + 1) / 2
			break
	var out := img.duplicate() as Image
	out.fill_rect(Rect2i(0, 0, img.get_width(), mid), Color(0, 0, 0, 0))
	out.blit_rect(img, Rect2i(0, 0, img.get_width(), mid), Vector2i(dx, 0))
	return out

## The notice flare: each eye grows 1 px upward (onto the body).
static func _flare(img: Image, eyes: Array) -> Image:
	var out := img.duplicate() as Image
	var ec := Color.html(EYE_HEX)
	for e in eyes:
		var q: Vector2i = e + Vector2i(0, -1)
		if q.y >= 0:
			out.set_pixelv(q, ec)
	return out

## The hurt flash: the whole silhouette in one colour.
static func _flash(img: Image, c: Color) -> Image:
	var out := img.duplicate() as Image
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				out.set_pixel(x, y, c)
	return out

## The dissolve: 6 steps from the key pose to nothing, outer pixels first (seeded jitter), the eyes last.
## Death uses steps 1-5; spawn plays steps 0-4 backwards.
static func _dissolve(img: Image, eyes: Array, seed_v: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var solid: Array = []
	var centre := Vector2.ZERO
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5 and not eyes.has(Vector2i(x, y)):
				solid.append(Vector2i(x, y))
				centre += Vector2(x, y)
	if not solid.is_empty():
		centre /= solid.size()
	var maxd := 0.001
	for p in solid:
		maxd = maxf(maxd, Vector2(p).distance_to(centre))
	var scored: Array = []
	for p in solid:
		scored.append([Vector2(p).distance_to(centre) / maxd + rng.randf() * 0.35, p])
	scored.sort_custom(func(a, b): return a[0] > b[0])
	var seq: Array = [img]
	for frac in [0.25, 0.5, 0.75]:
		var f := img.duplicate() as Image
		for i in int(scored.size() * frac):
			f.set_pixelv(scored[i][1], Color(0, 0, 0, 0))
		seq.append(f)
	var eyes_only := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	for e in eyes:
		eyes_only.set_pixelv(e, img.get_pixelv(e))
	seq.append(eyes_only)
	seq.append(Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8))
	return seq

# --- Output --------------------------------------------------------------------------------------------------------

static func _join(frames: Array, size: Vector2i) -> Image:
	var img := Image.create(size.x * frames.size(), size.y, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		img.blit_rect(frames[i], Rect2i(Vector2i.ZERO, size), Vector2i(i * size.x, 0))
	return img

## Writes or merges <subject>.frames.cfg. Keys already there are kept (the owner's fps and timing win), except a
## variant's frame_size, which must match the strips just written.
func _merge_frames_cfg(path: String, strips: Array, variants: Array) -> String:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(path):
		cfg.load(path)
	var sheet_size := _size_of(_opt("sheet", "frame_size", _vopt("", "frame_size")))
	if not cfg.has_section_key("sheet", "frame_size"):
		cfg.set_value("sheet", "frame_size", sheet_size)
	if not cfg.has_section_key("sheet", "anchor"):
		cfg.set_value("sheet", "anchor", str(_opt("sheet", "anchor", "foot")))
	for v in variants:
		if v == "":
			continue
		var vs := _size_of(_vopt(v, "frame_size"))
		var sec := "variant." + str(v)
		if cfg.has_section_key(sec, "frame_size") and _size_of(cfg.get_value(sec, "frame_size")) != vs:
			report["warnings"].append("%s: [%s] frame_size changed to %s" % [path, sec, str(vs)])
		cfg.set_value(sec, "frame_size", vs)
		if manifest.has_section_key("variant." + str(v), "anchor") and not cfg.has_section_key(sec, "anchor"):
			cfg.set_value(sec, "anchor", str(manifest.get_value("variant." + str(v), "anchor")))
	for s in strips:
		var anim: String = s["anim"]
		var asec := "anim." + anim
		for key in ["fps", "loop", "timed_by"]:
			if cfg.has_section_key(anim, key):
				continue
			if manifest.has_section_key(asec, key):
				cfg.set_value(anim, key, manifest.get_value(asec, key))
			elif key == "fps":
				cfg.set_value(anim, "fps", float(FPS.get(anim, FPS.get(anim.get_slice("_", 0), 8.0))))
			elif key == "loop":
				cfg.set_value(anim, "loop", LOOPING.has(anim))
	cfg.save(_abs(path))
	return path

## The preview: each strip at 8x (nearest), on #1d2745, with the source pose beside it.
func _write_preview(dir: String, strips: Array) -> String:
	if strips.is_empty():
		return ""
	var gap := 8
	var rows: Array = []
	var width := 0
	var height := gap
	for s in strips:
		var size: Vector2i = s["size"]
		var big: Image = (s["image"] as Image).duplicate()
		big.resize(big.get_width() * PREVIEW_SCALE, big.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
		var cell := size.y * PREVIEW_SCALE
		var th: Image = (s["thumb"] as Image).duplicate()
		var k := minf(float(cell) / th.get_width(), float(cell) / th.get_height())
		th.resize(maxi(1, roundi(th.get_width() * k)), maxi(1, roundi(th.get_height() * k)), Image.INTERPOLATE_BILINEAR)
		rows.append([th, big, cell, str(s["file"]).get_basename()])
		width = maxi(width, gap + cell + gap * 2 + big.get_width() + gap)
		height += big.get_height() + gap
	var out := Image.create(width, height, false, Image.FORMAT_RGBA8)
	var bg := Color.html(PREVIEW_BG)
	out.fill(bg)
	var y := gap
	for row in rows:
		var th: Image = row[0]
		var big: Image = row[1]
		var cell: int = row[2]
		out.blit_rect(th, Rect2i(Vector2i.ZERO, th.get_size()), Vector2i(gap + (cell - th.get_width()) / 2, y + (cell - th.get_height()) / 2))
		# A thin marker between the source and the strip, and a faint line between frames.
		out.fill_rect(Rect2i(gap + cell + gap - 1, y, 2, big.get_height()), Color.html("#28385e"))
		var x0 := gap + cell + gap * 2
		out.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(x0, y))
		y += big.get_height() + gap
	DirAccess.make_dir_recursive_absolute(_abs(dir))
	var path := dir.trim_suffix("/") + "/" + _preview_name + "_preview.png"
	if out.save_png(_abs(path)) != OK:
		report["errors"].append("can't write the preview " + path)
		return ""
	# One preview per strip too (easier to judge one at a time on a phone): <dir>/<manifest>/<strip>_8x.png
	var each := dir.trim_suffix("/") + "/" + _preview_name + "/"
	DirAccess.make_dir_recursive_absolute(_abs(each))
	report["previews"] = []
	for row in rows:
		var big: Image = row[1]
		var one := Image.create(big.get_width() + 2 * gap, big.get_height() + 2 * gap, false, Image.FORMAT_RGBA8)
		one.fill(bg)
		one.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i(gap, gap))
		var p := each + str(row[3]) + "_8x.png"
		if one.save_png(_abs(p)) == OK:
			report["previews"].append(p)
	return path

func _summary(folder: String, strips: Array) -> void:
	var lines: Array = report["lines"]
	lines.append("sprite_from_sheet: %s (%s), %d cells -> %s" % [_subject, _kind, report["cells"], folder])
	for s in strips:
		var state := "kept (owner art)" if s.get("kept", false) else "ok"
		lines.append("  %-34s %2d x %dx%d  %-22s %s" % [s["file"], s["frames"].size(), s["size"].x, s["size"].y, s["rule"], state])
	lines.append("  written %d, kept %d; frames file %s" % [report["written"].size(), report["kept"].size(), report["frames_cfg"] if report["frames_cfg"] != "" else "(not written)"])
	lines.append("  preview " + str(report["preview"]) + (" (+ one per strip in %s/)" % str(report["preview"]).get_basename().trim_suffix("_preview") if not report["previews"].is_empty() else ""))
	for w in report["warnings"]:
		lines.append("  warning: " + str(w))
	for e in report["errors"]:
		lines.append("  ERROR: " + str(e))

func _fail(msg: String) -> Dictionary:
	report["errors"].append(msg)
	report["lines"].append("sprite_from_sheet: " + msg)
	return report

static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("res://") or path.begins_with("user://") else path
