#!/bin/sh
# Resume a snapshot in the ByteBox window.
#
#   tools/run.sh border.sna
#
# $BYTEBOX overrides the executable.
exec "${BYTEBOX:-bytebox}" --snapshot="${1:?usage: run.sh snapshot.sna}"
