#!/bin/bash
# Run DOS commands headlessly in DOSBox-X with the MSC 5.1 toolchain.
#   C: = toolchain/msc51 (BIN, LIB, INCLUDE)    D: = build/  (working directory)
# Usage: tools/dosrun.sh "CL /c /AS HELLO.C" ["LINK ..."]...   (--check: only check the toolchain)
# The commands are written to build/DOSRUN.BAT; each command's output is appended
# to build/DOSRUN.LOG, which is printed afterwards.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TC="$ROOT/toolchain/msc51"
for f in BIN/CL.EXE BIN/C1.EXE BIN/C2.EXE BIN/C3.EXE BIN/MASM.EXE BIN/LINK.EXE BIN/EXEMOD.EXE LIB/SLIBCE.LIB INCLUDE/STDIO.H; do
  if [ ! -f "$TC/$f" ]; then
    echo "missing toolchain/msc51/$f: the Microsoft C 5.1 / MASM 5.10 files go in toolchain/msc51 (see README.md)" >&2
    exit 2
  fi
done
[ "$1" = "--check" ] && exit 0     # only check that the toolchain is there
MAC_DOSBOX=/Applications/dosbox-x.app/Contents/MacOS/dosbox-x
if [ -z "$DOSBOX" ]; then
  if [ -x "$MAC_DOSBOX" ]; then DOSBOX="$MAC_DOSBOX"; else DOSBOX="$(command -v dosbox-x)"; fi
fi
B="$ROOT/build"
mkdir -p "$B"
rm -f "$B/DOSRUN.LOG"
{
  printf '@ECHO OFF\r\n'
  for cmd in "$@"; do
    printf 'ECHO == %s >> D:\\DOSRUN.LOG\r\n' "$cmd"
    printf '%s >> D:\\DOSRUN.LOG\r\n' "$cmd"
  done
} > "$B/DOSRUN.BAT"
"$DOSBOX" -silent -fastlaunch -nogui -defaultconf \
  -set "dosbox machine=svga_s3" -set "cpu cycles=max" -set "dos ver=3.30" \
  -c "MOUNT C \"$ROOT/toolchain/msc51\"" -c "MOUNT D \"$B\"" \
  -c "SET PATH=C:\\BIN" -c "SET INCLUDE=C:\\INCLUDE" -c "SET LIB=C:\\LIB" -c "SET TMP=D:\\" \
  -c "D:" -c "CALL D:\\DOSRUN.BAT" > /dev/null 2>&1 || true
[ -f "$B/DOSRUN.LOG" ] && tr -d '\r' < "$B/DOSRUN.LOG"
