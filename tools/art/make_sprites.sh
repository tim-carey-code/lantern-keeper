#!/usr/bin/env bash
# Rebuilds every committed sprite strip from its private key-pose sheet (tools/art/README.md).
# The sheets are not in the repo (ART_DIRECTION §7): put them in tools/art/samples/ first.
#   tools/art/make_sprites.sh           # writes assets/art/...; strips the owner touched up are kept
#   tools/art/make_sprites.sh --force   # overwrite those too
# Previews go to ~/.cache/openclaw/project-scratch/sprite-previews/. Run `godot --headless --import` afterwards.
set -euo pipefail
cd "$(dirname "$0")/../.."
S=tools/art/samples
M=tools/art/manifests
export TMPDIR="${TMPDIR:-$HOME/.cache/openclaw/project-scratch}"
mkdir -p "$TMPDIR"
# sheet                              manifest (owner-approved 2026-11-27, docs/DECISIONS.md)
JOBS=(
	"$S/wicklings_keyposes_grid.jpg    $M/wickling.cfg"
	"$S/spitwick_nest_keyposes_grid.jpg $M/spitwick.cfg"
	"$S/spitwick_nest_keyposes_grid.jpg $M/nest.cfg"
	"$S/keeper_keyposes_grid_v2.jpg    $M/keeper_poses.cfg"
	"$S/ashbrood_keyposes_grid.jpg     $M/ashbrood.cfg"
	"$S/amos_keyposes_grid.jpg         $M/amos.cfg"
)
# Not here on purpose: wickling_timid_sample.cfg (the one-row pilot). The committed timid strips come from
# wickling.cfg; the pilot would write the same file names.
fail=0
for job in "${JOBS[@]}"; do
	read -r sheet manifest <<<"$job"
	if [ ! -f "$sheet" ]; then
		echo "missing sheet: $sheet (skipped)"; fail=1; continue
	fi
	godot --headless --audio-driver Dummy --path . -s tools/art/sprite_from_sheet.gd -- "$sheet" "$manifest" "$@" || fail=1
done
exit $fail
