#!/usr/bin/env bash
# Renders the README screenshots and the relight GIF into docs/screenshots/.
# Uses the staged "readme_*" views in tools/capture/capture.gd (pop-ups hidden).
# Needs godot 4.7 (project imported once), xvfb-run and ffmpeg. Runs silent (dummy audio).
#   tools/capture/readme_shots.sh            # from the project folder
#   SCRATCH=~/somewhere tools/capture/readme_shots.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
OUT=docs/screenshots
WORK="${SCRATCH:-$HOME/.cache/lantern-keeper-shots}"
mkdir -p "$OUT" "$WORK"

shoot() {   # render one view; its frames land in $WORK/<view>/
	local v=$1
	rm -rf "${WORK:?}/$v"
	mkdir -p "$WORK/$v"
	timeout 180 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --audio-driver Dummy \
		--write-movie "$WORK/$v/frame.png" --fixed-fps 30 res://tools/capture/capture.tscn -- "$v" \
		>"$WORK/$v.log" 2>&1
}

last_frame() {
	find "$WORK/$1" -name 'frame*.png' | sort | tail -1
}

for pair in readme_hollow:hollow readme_ward:ward readme_marsh:marsh readme_ridge:ridge \
		readme_map:map readme_lanterns:lanterns opening:opening journal:journal; do
	view=${pair%%:*}
	name=${pair##*:}
	shoot "$view"
	cp "$(last_frame "$view")" "$OUT/$name.png"
	echo "$OUT/$name.png"
done

# The relit lantern pushing the fog back: frames 10-110, centre crop, 15 fps, last frame held.
shoot readme_relight
ffmpeg -loglevel error -y -start_number 10 -framerate 30 -i "$WORK/readme_relight/frame%08d.png" \
	-vf "crop=640:360:320:150,fps=15,tpad=stop_mode=clone:stop_duration=1.6,split[a][b];[a]palettegen=max_colors=96:stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
	-loop 0 "$OUT/relight.gif"
echo "$OUT/relight.gif"
