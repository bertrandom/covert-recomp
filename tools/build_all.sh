#!/bin/bash
# Build all 18 Covert Action executables into build/out/.
#   tools/build_all.sh
# The eight programs come from C (tools/rebuild/build.sh), the ten drivers from
# MASM source (tools/drivers/build.sh). Each is compared with the SHA-1 of the
# original release (SHA1SUMS): a difference is reported, not an error, so a
# modified source still builds. Exit status 0 when all 18 were built.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
tools/dosrun.sh --check || exit 2
python3 -I tools/sha1check.py --toolchain
PROGS="CODE BUG CHASE TAC FINAL GAME COVERT INTRO"
DRIVERS="MGRAPHIC CGRAPHIC EGRAPHIC TGRAPHIC MISC NSOUND ISOUND TSOUND ASOUND RSOUND"
same=0
differ=()
fail=()
check() {             # $1 = name, $2 = last line of its build
  echo "$2"
  case "$2" in
    *"matches the original"*) same=$((same + 1));;
    *built*) differ+=("$1");;
    *) fail+=("$1");;
  esac
}
for p in $PROGS; do check "$p" "$(tools/rebuild/build.sh "$p" 2>&1 | tail -1)"; done
for d in $DRIVERS; do check "$d" "$(tools/drivers/build.sh "$d" 2>&1 | tail -1)"; done
# collect the outputs in one place
OUT=build/out
mkdir -p "$OUT"
rm -f "$OUT"/*
for p in $PROGS; do [ -f "build/$p/${p}P.EXE" ] && cp "build/$p/${p}P.EXE" "$OUT/$p.EXE"; done
for d in $DRIVERS; do for f in "build/$d/$d.EXE" "build/$d/$d.CA"; do [ -f "$f" ] && cp "$f" "$OUT/"; done; done
echo "$(( same + ${#differ[@]} ))/18 built into $OUT/: $same match the original release," \
     "${#differ[@]} differ"
[ ${#differ[@]} -gt 0 ] && echo "different from the original release: ${differ[*]}"
if [ ${#fail[@]} -gt 0 ]; then
  echo "FAILED to build: ${fail[*]}"
  exit 1
fi
exit 0
