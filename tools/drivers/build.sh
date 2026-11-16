#!/bin/bash
# Assemble and link a driver from src/DRIVERS/NAME.ASM with MASM 5.10 / LINK 5.01
# and compare it with the original.
#   tools/drivers/build.sh NAME [SRC.ASM]
# The output is build/NAME/NAME.EXE (renamed to NAME.CA for the sound drivers,
# whose original is NAME.CA). Exit status 0 when byte-identical.
set -e
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NAME="$(echo "$1" | tr a-z A-Z)"
SRC="${2:-$ROOT/src/DRIVERS/$NAME.ASM}"
[ -n "$NAME" ] && [ -f "$SRC" ] || { echo "usage: $0 NAME [SRC.ASM]" >&2; exit 2; }
"$ROOT/tools/dosrun.sh" --check || exit 2

ORIG_DIR="${ORIG_DIR:-$ROOT/resources/Covert}"
if [ ! -d "$ORIG_DIR" ] && git -C "$ROOT" rev-parse >/dev/null 2>&1; then
  COMMON="$(git -C "$ROOT" rev-parse --path-format=absolute --git-common-dir)"
  ORIG_DIR="$(dirname "$COMMON")/resources/Covert"
fi
EXT=EXE
case "$NAME" in ?SOUND) EXT=CA;; esac     # the sound drivers ship as .CA
ORIG="$ORIG_DIR/$NAME.$EXT"

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
if [ ! -f "$ORIG" ]; then
  echo "$NAME.$EXT: built, no original to compare with ($(wc -c < "$OUT" | tr -d ' ') bytes)"
elif cmp -s "$OUT" "$ORIG"; then
  echo "$NAME.$EXT: byte-identical ($(wc -c < "$ORIG" | tr -d ' ') bytes)"
else
  N=$(cmp -l "$OUT" "$ORIG" 2>/dev/null | wc -l | tr -d ' ')
  echo "$NAME.$EXT: differs ($N bytes differ; sizes $(wc -c < "$OUT" | tr -d ' ') vs $(wc -c < "$ORIG" | tr -d ' '))"
  cmp "$OUT" "$ORIG" 2>&1 | head -1 || true
  exit 1
fi
