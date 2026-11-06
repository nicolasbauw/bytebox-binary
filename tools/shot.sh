#!/bin/sh
# Resume a snapshot without a window, wait, and save a screenshot.
#
#   tools/shot.sh border.sna border.png [microseconds]
#
# The wait is in emulated microseconds (default 2 seconds). The run takes a
# fraction of a second whatever the wait. $BYTEBOX overrides the executable.
set -e
snap=${1:?usage: shot.sh snapshot.sna out.png [microseconds]}
png=${2:?usage: shot.sh snapshot.sna out.png [microseconds]}
wait_us=${3:-2000000}
dir=$(cd "$(dirname "$png")" && pwd)
name=$(basename "${png%.png}")
script=$(mktemp)
trap 'rm -f "$script"' EXIT
cat > "$script" <<CSL
csl_version 1.1
wait $wait_us
screenshot_dir "$dir"
screenshot_name "$name"
screenshot
CSL
"${BYTEBOX:-bytebox}" --headless --snapshot="$snap" --script="$script"
