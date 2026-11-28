extends SceneTree
## Key poses sheet -> game-ready sprite strips (tools/art/README.md; the work is in sprite_pipeline.gd).
##   godot --headless --path . -s tools/art/sprite_from_sheet.gd -- <sheet image> <manifest.cfg> [options]
## Options:
##   --force               overwrite strips the owner drew or touched up (normally they always win)
##   --out <dir>           art root instead of res://assets/art/ (the strips go in <dir>/creatures/<subject>/ ...)
##   --preview-dir <dir>   where the 8x preview goes (default ~/.cache/openclaw/project-scratch/sprite-previews/)
##   --preview-only        write only the preview: nothing in the art folders
## Exit code 0 = done (kept owner strips are not an error), 1 = bad arguments or a failed write.

const Pipeline := preload("res://tools/art/sprite_pipeline.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var pos: Array[String] = []
	var opts := {}
	var i := 0
	while i < args.size():
		var a := args[i]
		match a:
			"--force":
				opts["force"] = true
			"--preview-only":
				opts["preview_only"] = true
			"--out", "--preview-dir":
				if i + 1 >= args.size():
					_usage("%s needs a folder" % a)
					return
				i += 1
				opts["out_root" if a == "--out" else "preview_dir"] = _path(args[i])
			"-h", "--help":
				_usage("")
				return
			_:
				if a.begins_with("--"):
					_usage("unknown option " + a)
					return
				pos.append(_path(a))
		i += 1
	if pos.size() != 2:
		_usage("give a sheet image and a manifest")
		return
	var rep: Dictionary = Pipeline.new().run(pos[0], pos[1], opts)
	for line in rep["lines"]:
		print(line)
	quit(0 if rep["ok"] else 1)

## Relative paths are taken from the folder the command was run in; res:// and user:// pass through.
func _path(p: String) -> String:
	if p.begins_with("res://") or p.begins_with("user://") or p.is_absolute_path():
		return p
	if p.begins_with("~/"):
		return OS.get_environment("HOME") + p.substr(1)
	var cwd := OS.get_environment("PWD")
	return (cwd if cwd != "" else ProjectSettings.globalize_path("res://")).path_join(p)

func _usage(err: String) -> void:
	if err != "":
		printerr("sprite_from_sheet: " + err)
	print("usage: godot --headless --path . -s tools/art/sprite_from_sheet.gd -- <sheet> <manifest.cfg> [--force] [--out <dir>] [--preview-dir <dir>] [--preview-only]")
	quit(1 if err != "" else 0)
