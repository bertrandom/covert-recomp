#!/bin/bash
# Build all 18 Covert Action executables and compare each with the original.
#   tools/build_all.sh
# The eight programs come from C (tools/rebuild/build.sh), the ten drivers from
# MASM source (tools/drivers/build.sh). The originals are read from
# resources/Covert. Exit status 0 only when every file is byte-identical.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
tools/dosrun.sh --check || exit 2
PROGS="CODE BUG CHASE TAC FINAL GAME COVERT INTRO"
DRIVERS="MGRAPHIC CGRAPHIC EGRAPHIC TGRAPHIC MISC NSOUND ISOUND TSOUND ASOUND RSOUND"
# Without resources/Covert (or ORIG_DIR) the files are only built, not compared.
export ORIG_DIR="${ORIG_DIR:-$ROOT/resources/Covert}"
ok=0
built=0
fail=()
for p in $PROGS; do
  line="$(tools/rebuild/build.sh "$p" 2>&1 | tail -1)"
  echo "$line"
  case "$line" in *byte-identical*) ok=$((ok + 1));; *built,*) built=$((built + 1));; *) fail+=("$p");; esac
done
for d in $DRIVERS; do
  line="$(tools/drivers/build.sh "$d" 2>&1 | tail -1)"
  echo "$line"
  case "$line" in *byte-identical*) ok=$((ok + 1));; *built,*) built=$((built + 1));; *) fail+=("$d");; esac
done
# collect the outputs in one place
OUT=build/out
mkdir -p "$OUT"
for p in $PROGS; do [ -f "build/$p/${p}P.EXE" ] && cp "build/$p/${p}P.EXE" "$OUT/$p.EXE"; done
for d in $DRIVERS; do for f in "build/$d/$d.EXE" "build/$d/$d.CA"; do [ -f "$f" ] && cp "$f" "$OUT/"; done; done
if [ "$built" -gt 0 ]; then
  echo "$((ok + built))/18 built ($ok compared byte-identical, $built with no original to compare); outputs in $OUT/"
else
  echo "$ok/18 byte-identical; outputs in $OUT/"
fi
if [ ${#fail[@]} -gt 0 ]; then
  echo "FAILED: ${fail[*]}"
  exit 1
fi
