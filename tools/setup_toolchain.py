#!/usr/bin/env python3
"""Install the Microsoft C 5.1 / MASM 5.10 files the build needs into toolchain/msc51.

  setup_toolchain.py [ARCHIVE | DIR ...]

The ARCHIVEs are the two WinWorld disk archives
  Microsoft C 5.1 Optimizing Compiler (5.25).7z
  Microsoft Macro Assembler 5.1 (5.25).7z
Each archive's SHA-1 is checked against SHA1SUMS before it is opened: an archive
named on the command line must match; in a DIR (default: resources/) the .7z files
that match are used and others skipped. The archives
hold floppy images (FAT12): eight files are copied from them, and SLIBCE.LIB, the
small-model runtime that MSC's SETUP assembles from component libraries, is built
the same way with LIB 3.11 in DOSBox-X (tools/dosrun.sh). Every installed file is
checked against SHA1SUMS. Needs the `7z` tool.
"""
import glob
import hashlib
import os
import shutil
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
DEST = os.path.join(ROOT, "toolchain", "msc51")
LIB_CMD = "LIB SLIBCE.LIB +SLIBCR.LIB +SLIBFP.LIB +EM.LIB +LIBH.LIB;"
PARTS = ["LIB.EXE", "SLIBCR.LIB", "SLIBFP.LIB", "EM.LIB", "LIBH.LIB"]   # for SLIBCE.LIB


def sha1(b):
    return hashlib.sha1(b).hexdigest()


def sums():
    out = {}
    for line in open(os.path.join(ROOT, "SHA1SUMS")):
        line = line.strip()
        if line and not line.startswith("#"):
            h, name = line.split(None, 1)
            out[name] = h
    return out


def fat_files(img):
    """The files in a FAT12 floppy image (root and subdirectories)."""
    bps, spc, res, nfats, nroot = struct.unpack_from("<HBHBH", img, 11)
    spf = struct.unpack_from("<H", img, 22)[0]
    fat = img[res * bps:(res + spf) * bps]
    root = (res + nfats * spf) * bps
    data = root + ((nroot * 32 + bps - 1) // bps) * bps
    clus = spc * bps

    def chain(c):
        out, seen = bytearray(), set()
        while 2 <= c < 0xFF0 and c not in seen:
            seen.add(c)
            out += img[data + (c - 2) * clus:data + (c - 1) * clus]
            v = struct.unpack_from("<H", fat, c * 3 // 2)[0]
            c = v >> 4 if c & 1 else v & 0xFFF
        return bytes(out)

    def walk(raw):
        out = []
        for k in range(0, len(raw) - 31, 32):
            e = raw[k:k + 32]
            if e[0] == 0:
                break
            if e[0] == 0xE5 or e[11] & 0x08 or e[11] == 0x0F or e[0:1] == b".":
                continue
            start, size = struct.unpack_from("<HI", e, 26)
            out += walk(chain(start)) if e[11] & 0x10 else [chain(start)[:size]]
        return out

    return walk(img[root:root + nroot * 32])


def is_floppy(b):
    return len(b) >= 512 and b[510:512] == b"\x55\xaa" and struct.unpack_from("<H", b, 11)[0] == 512


def main():
    known = sums()
    archives_ok = {h: n for n, h in known.items() if n.endswith(".7z")}
    sources = []
    for a in sys.argv[1:] or [os.path.join(ROOT, "resources")]:
        if os.path.isdir(a):
            for f in sorted(glob.glob(os.path.join(a, "*.7z"))):
                if sha1(open(f, "rb").read()) in archives_ok:
                    sources.append(f)
                else:
                    print(f"{os.path.basename(f)}: not one of the Microsoft archives, skipped")
        else:
            sources.append(a)
    if not sources:
        sys.exit("no Microsoft C 5.1 / MASM 5.10 archives found; expected:\n  "
                 + "\n  ".join(f"{n} (SHA-1 {x})" for x, n in archives_ok.items()))
    seven = shutil.which("7zz") or shutil.which("7z") or shutil.which("7za")
    if not seven:
        sys.exit("needs the 7z tool (7-Zip) on the PATH")
    found = {}
    for src in sources:
        h = sha1(open(src, "rb").read())
        if h not in archives_ok:
            sys.exit(f"{src}: unknown archive (SHA-1 {h}); expected one of:\n  "
                     + "\n  ".join(f"{n} ({x})" for x, n in archives_ok.items()))
        print(f"{os.path.basename(src)}: SHA-1 ok")
        with tempfile.TemporaryDirectory() as t:
            subprocess.run([seven, "x", "-y", "-o" + t, src], check=True, stdout=subprocess.DEVNULL)
            for dp, _dn, fn in os.walk(t):
                for f in fn:
                    b = open(os.path.join(dp, f), "rb").read()
                    if is_floppy(b):
                        for member in fat_files(b):
                            found.setdefault(sha1(member), member)
    want = {n: h for n, h in known.items() if n.startswith("toolchain/") and not n.endswith("SLIBCE.LIB")}
    parts = {p: known["setup/" + p] for p in PARTS}
    missing = [n for n, h in list(want.items()) + list(parts.items()) if h not in found]
    if missing:
        sys.exit("not found in the archives: " + ", ".join(os.path.basename(n) for n in missing)
                 + "\n(give both the MSC 5.1 and the MASM 5.10 archive)")
    for n, h in want.items():
        path = os.path.join(ROOT, n)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "wb") as o:
            o.write(found[h])
        print(f"  {n}")
    # SLIBCE.LIB: combine the libraries with LIB, as SETUP does
    with tempfile.TemporaryDirectory() as t:
        for p, h in parts.items():
            with open(os.path.join(t, p), "wb") as o:
                o.write(found[h])
        subprocess.run([os.path.join(ROOT, "tools", "dosrun.sh"), "C:", LIB_CMD],
                       env=dict(os.environ, TOOLCHAIN_DIR=t), check=True, stdout=subprocess.DEVNULL)
        lib = os.path.join(t, "SLIBCE.LIB")
        if not os.path.exists(lib):
            sys.exit("LIB did not produce SLIBCE.LIB (is DOSBox-X installed?)")
        data = open(lib, "rb").read()
    name = "toolchain/msc51/LIB/SLIBCE.LIB"
    if sha1(data) != known[name]:
        sys.exit(f"SLIBCE.LIB came out different (SHA-1 {sha1(data)}); not installed")
    path = os.path.join(ROOT, name)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as o:
        o.write(data)
    print(f"  {name} (built with LIB)")
    print(f"toolchain/msc51 ready ({len(want) + 1} files, all SHA-1 ok)")


if __name__ == "__main__":
    main()
