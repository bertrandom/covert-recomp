#!/bin/bash
# Assemble and link a driver from src/DRIVERS/NAME.ASM with MASM 5.10 / LINK 5.01,
# and compare its SHA-1 with the original release's (SHA1SUMS; a difference is
# reported, not an error).
#   tools/drivers/build.sh NAME [SRC.ASM]
# The output is build/NAME/NAME.EXE (NAME.CA for the sound drivers). Exit status 0
# when it was built.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NAME="$(echo "$1" | tr a-z A-Z)"
SRC="${2:-$ROOT/src/DRIVERS/$NAME.ASM}"
[ -n "$NAME" ] && [ -f "$SRC" ] || { echo "usage: $0 NAME [SRC.ASM]" >&2; exit 2; }
"$ROOT/tools/dosrun.sh" --check || exit 2

EXT=EXE
case "$NAME" in ?SOUND) EXT=CA;; esac     # the sound drivers ship as .CA

B="$ROOT/build/$NAME"
mkdir -p "$B"
rm -f "$B/$NAME.OBJ" "$B/$NAME.EXE" "$B/$NAME.CA" "$B/$NAME.LST"
# DOS wants CRLF line ends
sed 's/\r*$/\r/' "$SRC" > "$B/$NAME.ASM"
# Extra LINK options come from a "; LINK options: ..." line in the source.
LFLAGS="$(sed -n 's/^; LINK options: *\([^\r]*\).*/\1/p' "$SRC" | head -1)"
LOG="$("$ROOT/tools/dosrun.sh" "CD $NAME" "MASM /Mx $NAME,,$NAME;" "LINK $LFLAGS $NAME;")"
if [ ! -f "$B/$NAME.EXE" ]; then
  echo "$LOG"
  echo "$NAME: build failed"
  exit 1
fi
echo "$LOG" | grep -E "error|warning" | grep -v -E "^ +0 (Warning|Severe)" || true
OUT="$B/$NAME.EXE"
# A "; EXE checksum: XXXXh" line sets the header checksum after linking (for an
# original that was patched after it was linked, so its checksum is stale).
CKS="$(sed -n 's/^; EXE checksum: *\([0-9A-Fa-f]*\)h.*/\1/p' "$SRC" | head -1)"
if [ -n "$CKS" ]; then
  python3 -c "import sys; p=sys.argv[1]; b=bytearray(open(p,'rb').read()); v=int(sys.argv[2],16); b[18:20]=bytes([v&255,v>>8]); open(p,'wb').write(b)" "$OUT" "$CKS"
fi
if [ "$EXT" = CA ]; then mv "$OUT" "$B/$NAME.CA"; OUT="$B/$NAME.CA"; fi
python3 -I "$ROOT/tools/sha1check.py" "$OUT" "$NAME.$EXT" || true
