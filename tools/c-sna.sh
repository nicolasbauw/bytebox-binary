#!/bin/sh
# Build a C program with SDCC into a snapshot ByteBox can resume.
#
#   tools/c-sna.sh src/c/bars.c            -> bars.sna
#   tools/c-sna.sh src/c/bars.c out.sna
#
# Needs sdcc (z80 target), sdasz80 and makebin from the SDCC package, and
# RASM ($RASM, or in the PATH) to wrap the binary into a snapshot. The
# start-up code is src/c/crt0.s: code is linked at #4010, data at #8000.
set -e
here=$(cd "$(dirname "$0")/.." && pwd)
src=${1:?usage: c-sna.sh program.c [out.sna]}
src=$(cd "$(dirname "$src")" && pwd)/$(basename "$src")
out=${2:-$(basename "${src%.c}").sna}
case $out in /*) ;; *) out=$PWD/$out ;; esac
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cd "$work"
cp "$here/src/c/crt0.s" "$src" .
sdasz80 -o crt0.rel crt0.s
sdcc -mz80 --no-std-crt0 --code-loc 0x4010 --data-loc 0x8000 \
    crt0.rel "$(basename "$src")" -o prog.ihx
makebin -p -o 16384 prog.ihx prog.bin

cat > wrap.asm <<ASM
        BUILDSNA V2
        BANKSET 0
        ORG  #4000
        RUN  #4000
        INCBIN "prog.bin"
ASM
"${RASM:-rasm}" wrap.asm -oi "$out" -v2
