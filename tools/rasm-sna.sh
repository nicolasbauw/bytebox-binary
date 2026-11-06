#!/bin/sh
# Assemble a RASM source into a snapshot ByteBox can resume.
#
#   tools/rasm-sna.sh src/border.asm            -> border.sna
#   tools/rasm-sna.sh src/border.asm out.sna
#
# RASM is looked up in $RASM, then in the PATH. The snapshot is written as
# version 2 (a plain memory dump): version 3 stores memory in compressed
# chunks, which ByteBox refuses to load. A symbol file is written next to it.
set -e
src=${1:?usage: rasm-sna.sh source.asm [out.sna]}
out=${2:-$(basename "${src%.*}").sna}
"${RASM:-rasm}" "$src" -oi "$out" -v2 -s -os "${out%.sna}.sym"
