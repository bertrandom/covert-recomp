#!/usr/bin/env python3
"""Install the Microsoft C 5.1 / MASM 5.10 files the build needs into toolchain/msc51.

  setup_toolchain.py [SOURCE ...]

Each SOURCE is a .7z (or .zip) of disk images, such as the WinWorld archives
"Microsoft C 5.1 Optimizing Compiler (5.25).7z" and "Microsoft Macro Assembler
5.1 (5.25).7z", a single disk image (.img), or a directory holding images or
already-extracted files. With no arguments, every .7z/.zip in resources/ is used.
.7z archives need the `7z` tool.

Files are recognized by their SHA-1, not by disk or file name, so any copy of the
right version works. Eight files are copied as they are; SLIBCE.LIB, the
small-model runtime, isn't on the disks: like MSC's SETUP, it is built with LIB
3.11 from SLIBCR.LIB, SLIBFP.LIB, EM.LIB and LIBH.LIB (in DOSBox-X, see
tools/dosrun.sh) and checked against the expected SHA-1.
"""
import glob
import hashlib
import io
import os
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extract_game import fat_files, looks_like_fat, tool  # noqa: E402

DEST = os.path.join(ROOT, "toolchain", "msc51")

# installed file -> (SHA-1, where it comes from)
WANTED = {
    "BIN/CL.EXE": ("d44e33af2aa12ce992af4f41422fe1ed36f3de70", "MSC 5.1 Setup disk"),
    "BIN/C1.EXE": ("28ffc307b1e3902a1aaef6d433357cbf1acd91bb", "MSC 5.1 Setup disk"),
    "BIN/C2.EXE": ("04f38da6ba2c0a3d0e5278a2add86240c7ae52b2", "MSC 5.1 Compiler 2 disk"),
    "BIN/C3.EXE": ("4e48d6acce40aac6835d7a79e5d082404bd31f76", "MSC 5.1 Compiler 1 disk"),
    "BIN/LINK.EXE": ("eba98c968fc3cb6727a55172703c6cfc68b3e875", "MSC 5.1 Utilities 1 disk"),
    "BIN/EXEMOD.EXE": ("45bd3685de80124b920befa47e558c0ddfb40b20", "MSC 5.1 Utilities 1 disk"),
    "INCLUDE/STDIO.H": ("2f1d6948de20cbe30cfac1ba532e3f86d9add924", "MSC 5.1 Include Files disk"),
    "BIN/MASM.EXE": ("6fa0c4f39d45a07a1834597c10545184826140be", "MASM 5.10 disk 1"),
}
# what SLIBCE.LIB is built from (only needed during setup)
PARTS = {
    "LIB.EXE": ("dfea75b4762ba9d009fbf7bfeb9d175c6633d84b", "MSC 5.1 Utilities 1 disk"),
    "SLIBCR.LIB": ("8c945a4d15e982d6684dc70fd200f424539c6bb8", "MSC 5.1 Libraries (Small and Medium Models) disk"),
    "SLIBFP.LIB": ("ef4a3308bc35dc2c2c4ecb86e3539c3cabb8f6a0", "MSC 5.1 Floating-Point Libraries disk"),
    "EM.LIB": ("883e9c43d32803d6f05b9eabc28fa42d2f3ac752", "MSC 5.1 Floating-Point Libraries disk"),
    "LIBH.LIB": ("e892ad5d5cbbe99f25af75bfaa7765e9addf21c1", "MSC 5.1 Floating-Point Libraries disk"),
}
SLIBCE = ("LIB/SLIBCE.LIB", "29169062f2cfe56668a0ae473c8dfc00e8398084")
LIB_CMD = "LIB SLIBCE.LIB +SLIBCR.LIB +SLIBFP.LIB +EM.LIB +LIBH.LIB;"


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def blobs_from(source):
    """Every file found in SOURCE: archive members, files inside disk images, plain files."""
    out = []

    def add(name, data):
        if looks_like_fat(data):
            try:
                out.extend(fat_files(data).values())
                return
            except Exception:
                pass
        out.append(data)

    if os.path.isdir(source):
        for dp, _dn, fn in os.walk(source):
            for f in fn:
                add(f, open(os.path.join(dp, f), "rb").read())
        return out
    data = open(source, "rb").read()
    if data[:6] == b"7z\xbc\xaf\x27\x1c":
        with tempfile.TemporaryDirectory() as t:
            subprocess.run([tool("7zz", "7z", "7za"), "x", "-y", "-o" + t, source],
                           check=True, stdout=subprocess.DEVNULL)
            return blobs_from(t)
    if data[:2] == b"PK":
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            for i in z.infolist():
                if not i.is_dir():
                    add(i.filename, z.read(i))
        return out
    add(source, data)
    return out


def main():
    sources = sys.argv[1:] or sorted(glob.glob(os.path.join(ROOT, "resources", "*.7z"))
                                     + glob.glob(os.path.join(ROOT, "resources", "*.zip")))
    if not sources:
        sys.exit("usage: setup_toolchain.py SOURCE...  (the MSC 5.1 and MASM 5.10 disk "
                 "archives; with no arguments, the .7z/.zip files in resources/)")
    found = {}
    for s in sources:
        n = 0
        for b in blobs_from(s):
            found.setdefault(sha1(b), b)
            n += 1
        print(f"{s}: {n} files")
    need = dict(WANTED, **PARTS)
    missing = [(f, where) for f, (h, where) in need.items() if h not in found]
    if missing:
        for f, where in missing:
            print(f"missing {os.path.basename(f)} (from the {where})", file=sys.stderr)
        sys.exit("toolchain/msc51 not set up: give the MSC 5.1 and MASM 5.10 disk archives")
    for f, (h, _) in WANTED.items():
        path = os.path.join(DEST, f)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as o:
            o.write(found[h])
        print(f"  {f}")
    # SLIBCE.LIB: combine the libraries with LIB, in DOSBox-X
    with tempfile.TemporaryDirectory() as t:
        for f, (h, _) in PARTS.items():
            with open(os.path.join(t, f), "wb") as o:
                o.write(found[h])
        env = dict(os.environ, TOOLCHAIN_DIR=t)
        subprocess.run([os.path.join(ROOT, "tools", "dosrun.sh"), "C:", LIB_CMD], env=env,
                       check=True, stdout=subprocess.DEVNULL)
        lib = os.path.join(t, "SLIBCE.LIB")
        if not os.path.exists(lib):
            sys.exit("LIB did not produce SLIBCE.LIB (is DOSBox-X installed?)")
        data = open(lib, "rb").read()
    if sha1(data) != SLIBCE[1]:
        sys.exit(f"SLIBCE.LIB came out different (SHA-1 {sha1(data)}); not installed")
    path = os.path.join(DEST, SLIBCE[0])
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as o:
        o.write(data)
    print(f"  {SLIBCE[0]} (built with LIB)")
    print(f"toolchain/msc51 ready ({len(WANTED) + 1} files)")


if __name__ == "__main__":
    main()
