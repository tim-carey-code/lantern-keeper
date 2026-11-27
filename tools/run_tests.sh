#!/usr/bin/env bash
# Runs every test scene in tools/tests/, headless and silent (dummy audio).
# A test fails on a non-zero exit code OR on any SCRIPT ERROR in its output: when you play
# from the editor, a script error freezes the game in the debugger even if every check passes.
#   tools/run_tests.sh               # all tests
#   tools/run_tests.sh save story    # just these (test_save, test_story)
set -uo pipefail
cd "$(dirname "$0")/.."
if [ $# -gt 0 ]; then
	scenes=()
	for n in "$@"; do scenes+=("tools/tests/test_$n.tscn"); done
else
	scenes=(tools/tests/test_*.tscn)
fi
failed=0
total=0
for t in "${scenes[@]}"; do
	out=$(timeout 180 godot --headless --audio-driver Dummy --fixed-fps 60 --path . "res://$t" 2>&1)
	rc=$?
	errors=$(grep -c "SCRIPT ERROR" <<<"$out")
	passes=$(grep -c "^PASS" <<<"$out")
	total=$((total + passes))
	if [ "$rc" -ne 0 ] || [ "$errors" -ne 0 ]; then
		failed=$((failed + 1))
		echo "FAIL $t (exit $rc, $passes checks passed, $errors script errors)"
		grep -E "^FAIL|SCRIPT ERROR|^ +at: " <<<"$out" | head -20
	else
		echo "ok   $t ($passes checks)"
	fi
done
echo "$total checks passed; $failed of ${#scenes[@]} test scenes failed"
[ "$failed" -eq 0 ]
