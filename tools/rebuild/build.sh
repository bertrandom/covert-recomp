#!/bin/bash
# Build a Covert Action program with the original toolchain.
#   Usage: tools/rebuild/build.sh PROG   (CODE, BUG, ...)
#   1. compile the program's C objects with MSC 5.1 (CL /AS /Gs /Oas, see baseline.py)
#   2. write the link inputs: the assembly modules from src/ASM, DATA.ASM (_BSS and
#      communal sizes), the object order and LINK response files
#   3. MASM 5.10, LINK (/EXEPACK unless the config says not) in the original object
#      order, EXEMOD /MIN if needed
#   4. compare the SHA-1 with the original release's (SHA1SUMS); a difference is
#      reported, not an error (it's expected once the source is changed)
# Output: build/PROG/PROGP.EXE. Exit status 0 when it was built.
set -e
PROG="$(echo "${1:?usage: build.sh PROG}" | tr a-z A-Z)"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
tools/dosrun.sh --check || exit 2
BL="python3 -I tools/rebuild/baseline.py $PROG"
mkdir -p "build/$PROG"
rm -f build/$PROG/*.OBJ "build/$PROG/$PROG.EXE" "build/$PROG/${PROG}P.EXE"
CL=()
while IFS= read -r cmd; do CL+=("$cmd"); done < <($BL --cl-commands)
if [ ${#CL[@]} -gt 0 ]; then
  for d in $($BL --sources); do
    for f in "$d"/*.[CH]; do tr -d "\r" < "$f" | sed "s/$/\r/" > "build/$PROG/$(basename "$f" | tr a-z A-Z)"; done
  done
  tools/dosrun.sh "CD $PROG" "${CL[@]}" | grep -iE "error|warning" || true
fi
# NO_PATCHES=1: leave out the binary patches (the floppy release of FINAL.EXE has none;
# the GOG and eXoDOS ones carry it).
[ -n "$NO_PATCHES" ] || while read -r obj off old new; do      # binary patches the shipped EXE carries
  [ -n "$obj" ] && python3 -I tools/rebuild/objpatch.py "build/$PROG/$obj" "$off" "$old" "$new" > /dev/null
done < <($BL --patches)
$BL > /dev/null
ORDER="$($BL --link-order)"
CMDS=("CD $PROG")
for a in $($BL --asm-files); do CMDS+=("MASM /Mx $a;"); done
# LINK response files: the object list is longer than a DOS command line (127 chars).
rsp() { echo "$ORDER$1" | sed 's/+/+\
/g'; }
LIBOBJS="$($BL --lib-objects)"
if [ -n "$LIBOBJS" ]; then         # modules LINK takes from a library, as in the original
  rm -f "build/$PROG/MPS.LIB"
  echo "MPS.LIB" | sed 's/$/\r/' > "build/$PROG/LIB.RSP"
  echo "y" | sed 's/$/\r/' >> "build/$PROG/LIB.RSP"
  for o in $LIBOBJS; do echo "+$o &"; done | sed '$ s/ &$/;/' | sed 's/$/\r/' >> "build/$PROG/LIB.RSP"
fi
LIBS="$($BL --libs)"
rsp ",$PROG,$PROG,$LIBS;" | sed 's/$/\r/' > "build/$PROG/LINK1.RSP"
rsp ",${PROG}P,NUL,$LIBS;" | sed 's/$/\r/' > "build/$PROG/LINK2.RSP"
CMDS+=("MASM /Ml DATA;")
[ -n "$LIBOBJS" ] && CMDS+=("LIB @LIB.RSP")
CMDS+=(
      "LINK /NOI /MAP @LINK1.RSP"
      "LINK $($BL --exepack) /NOI @LINK2.RSP")
MIN="$($BL --minalloc)"
[ -n "$MIN" ] && CMDS+=("EXEMOD ${PROG}P.EXE /MIN $MIN")
tools/dosrun.sh "${CMDS[@]}" | grep -iE "error|warning [CL]|fatal" | grep -v "U4050" || true
[ -f "build/$PROG/${PROG}P.EXE" ] || { echo "$PROG.EXE: build failed"; exit 1; }
KEY="$PROG.EXE"
[ -n "$NO_PATCHES" ] && [ -n "$($BL --patches)" ] && KEY="$PROG.EXE NO_PATCHES"
python3 -I tools/sha1check.py "build/$PROG/${PROG}P.EXE" "$KEY" || true
