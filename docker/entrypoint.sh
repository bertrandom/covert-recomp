#!/bin/bash
# Container entry point. With a host folder mounted at /work (in Docker Desktop:
# Run > Optional settings > Volumes, container path /work):
#   1. the Microsoft C 5.1 / MASM 5.10 disk archives (.7z, identified by SHA-1) in
#      that folder are unpacked into /work/msc51 (once; later runs reuse it);
#   2. all 18 executables are built and copied to /work/out, and each one's SHA-1
#      is compared with the original release's (SHA1SUMS).
# A toolchain mounted directly at /covert/toolchain/msc51 is used as it is.
# Any arguments are run as a command instead.
set -e
cd /covert
[ $# -gt 0 ] && exec "$@"
TC=/covert/toolchain/msc51
if [ ! -f "$TC/BIN/CL.EXE" ]; then
  if [ ! -d /work ]; then
    echo "No toolchain. Mount a folder holding the Microsoft C 5.1 and MASM 5.10 disk"
    echo "archives at /work (docker run -v /path/to/folder:/work ...), or the toolchain"
    echo "itself at $TC."
    exit 2
  fi
  if [ ! -f /work/msc51/BIN/CL.EXE ]; then
    python3 tools/setup_toolchain.py /work || {
      echo "Put the Microsoft C 5.1 and MASM 5.10 disk archives (.7z) in the folder mounted at /work."
      exit 2; }
    mkdir -p /work/msc51
    cp -R "$TC/." /work/msc51/
  fi
  rm -rf "$TC"
  mkdir -p "$(dirname "$TC")"
  ln -s /work/msc51 "$TC"
fi
status=0
tools/build_all.sh || status=$?
if [ -d /work ]; then
  mkdir -p /work/out
  cp build/out/* /work/out/
  echo "The executables are in out/ in the mounted folder."
fi
exit $status
