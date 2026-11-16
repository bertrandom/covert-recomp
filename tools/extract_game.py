#!/usr/bin/env python3
"""Extract the Covert Action game files from a distribution archive.

  extract_game.py SOURCE OUTDIR [--compare DIR]

SOURCE can be any of the known releases (the format is detected from the
content, not the name):
  - GOG Windows installer (Inno Setup .exe)    needs `innoextract`
  - GOG macOS installer (.pkg: xar + gzip'd cpio)
  - GOG Linux installer (.sh: makeself script with a zip appended)
  - eXoDOS archive (.zip)
  - floppy disk sets: a .7z of disk images (needs `7z`), or a directory of
    images, or a single image (FAT12, 360K/720K/...)
  - a directory that already holds the game

OUTDIR receives the game directory's files (upper-case 8.3 names, flat), i.e.
what ends up in C:\\MPS\\COVERT after installing. For floppy sets the disks are
copied in order like INSTALL.BAT does (`copy A:*.*` per disk), so a file on a
later disk replaces the earlier copy.
--compare DIR prints which files match, differ or are missing against DIR.
"""
import argparse
import re
import gzip
import hashlib
import io
import os
import shutil
import struct
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
import zipfile
import zlib

MARKERS = ("GAME.EXE", "COVERT.EXE")     # how the game directory is recognized
DOS_NAME = re.compile(r"^[A-Z0-9_$~!#%&'(){}@^`-]{1,8}(\.[A-Z0-9_$~!#%&'(){}@^`-]{1,3})?$")


# ---------------------------------------------------------------- FAT12 images

def fat_files(img):
    """{NAME.EXT: bytes} of the files in a FAT12/16 floppy image (root and subdirectories)."""
    bps, spc, res, nfats, nroot = struct.unpack_from("<HBHBH", img, 11)
    spf = struct.unpack_from("<H", img, 22)[0]
    if bps not in (512, 1024) or not spc or not nfats:
        raise ValueError("not a FAT image")
    fat = img[res * bps:(res + spf) * bps]
    root = (res + nfats * spf) * bps
    data = root + ((nroot * 32 + bps - 1) // bps) * bps
    clus = spc * bps

    def nxt(c):
        v = struct.unpack_from("<H", fat, c * 3 // 2)[0]
        return v >> 4 if c & 1 else v & 0xFFF

    def chain(c):
        out = bytearray()
        seen = set()
        while 2 <= c < 0xFF0 and c not in seen:
            seen.add(c)
            out += img[data + (c - 2) * clus:data + (c - 1) * clus]
            c = nxt(c)
        return bytes(out)

    def walk(raw, prefix):
        out = {}
        for k in range(0, len(raw) - 31, 32):
            e = raw[k:k + 32]
            if e[0] == 0:
                break
            if e[0] == 0xE5 or e[11] & 0x08 or e[11] == 0x0F:     # deleted, label, LFN
                continue
            base = e[0:8].decode("latin-1").rstrip()
            ext = e[8:11].decode("latin-1").rstrip()
            if base in (".", ".."):
                continue
            name = base + ("." + ext if ext else "")
            start, size = struct.unpack_from("<HI", e, 26)
            if e[11] & 0x10:
                out.update(walk(chain(start), prefix + name + "/"))
            else:
                out[prefix + name] = chain(start)[:size]
        return out

    return walk(img[root:root + nroot * 32], "")


def disk_order(name):
    """Sort key for disk images: the number in the name (disk1, disk2, ...)."""
    digits = "".join(ch for ch in os.path.basename(name) if ch.isdigit())
    return (int(digits) if digits else 0, name)


def from_floppies(images):
    """Install a set of disk images in order, like INSTALL.BAT."""
    files = {}
    for name, img in sorted(images.items(), key=lambda kv: disk_order(kv[0])):
        for path, data in fat_files(img).items():
            if "/" not in path:                 # INSTALL.BAT copies A:*.* (root only)
                files[path.upper()] = data
    return files


def looks_like_fat(b):
    return len(b) >= 512 and b[510:512] == b"\x55\xaa" and struct.unpack_from("<H", b, 11)[0] in (512, 1024)


# ---------------------------------------------------------------- xar (.pkg)

def xar_files(data):
    """{path: bytes} of a xar archive (macOS .pkg)."""
    magic, hsize, _ver, clen, _ulen = struct.unpack_from(">4sHHQQ", data, 0)
    if magic != b"xar!":
        raise ValueError("not a xar archive")
    toc = ET.fromstring(zlib.decompress(data[hsize:hsize + clen]))
    heap = hsize + clen
    out = {}

    def walk(el, prefix):
        for f in el.findall("file"):
            name = f.findtext("name")
            path = prefix + name
            d = f.find("data")
            if d is not None:
                off, ln = int(d.findtext("offset")), int(d.findtext("length"))
                raw = data[heap + off:heap + off + ln]
                enc = d.find("encoding").get("style") if d.find("encoding") is not None else ""
                if "gzip" in enc:
                    raw = zlib.decompress(raw)
                elif "bzip2" in enc:
                    import bz2
                    raw = bz2.decompress(raw)
                out[path] = raw
            walk(f, path + "/")

    walk(toc.find("toc"), "")
    return out


def cpio_files(data):
    """{path: bytes} of a cpio archive (odc '070707' or newc '070701'/'070702')."""
    out, p = {}, 0
    while p < len(data):
        magic = data[p:p + 6]
        if magic == b"070707":
            h = data[p:p + 76]
            mode = int(h[18:24], 8)
            nlen, fsize = int(h[59:65], 8), int(h[65:76], 8)
            name = data[p + 76:p + 76 + nlen - 1].decode("utf-8", "replace")
            p += 76 + nlen
            body, p = data[p:p + fsize], p + fsize
        elif magic in (b"070701", b"070702"):
            h = data[p:p + 110]
            mode = int(h[14:22], 16)
            fsize, nlen = int(h[54:62], 16), int(h[94:102], 16)
            name = data[p + 110:p + 110 + nlen - 1].decode("utf-8", "replace")
            p = (p + 110 + nlen + 3) & ~3
            body, p = data[p:p + fsize], (p + fsize + 3) & ~3
        else:
            break
        if name == "TRAILER!!!":
            break
        if mode & 0o170000 == 0o100000:          # regular file
            out[name[2:] if name.startswith("./") else name] = body
    return out


def from_pkg(data):
    files = {}
    for path, raw in xar_files(data).items():
        if raw[:2] == b"\x1f\x8b":                # Payload / Scripts: gzip'd cpio
            raw = gzip.decompress(raw)
        if raw[:5] == b"07070":
            for p, b in cpio_files(raw).items():
                files[path + "/" + p] = b
        else:
            files[path] = raw
    return files


# ---------------------------------------------------------------- external tools

def tool(*names):
    for n in names:
        p = shutil.which(n)
        if p:
            return p
    sys.exit(f"needs one of: {', '.join(names)} (not found on PATH)")


def read_tree(root):
    out = {}
    for dp, _dn, fn in os.walk(root):
        for f in fn:
            full = os.path.join(dp, f)
            out[os.path.relpath(full, root).replace(os.sep, "/")] = open(full, "rb").read()
    return out


def from_inno(path):
    exe = tool("innoextract")
    with tempfile.TemporaryDirectory() as t:
        subprocess.run([exe, "-s", "-q", "-e", "-d", t, path], check=True)
        return read_tree(t)


def from_7z(path):
    exe = tool("7zz", "7z", "7za")
    with tempfile.TemporaryDirectory() as t:
        subprocess.run([exe, "x", "-y", "-o" + t, path], check=True, stdout=subprocess.DEVNULL)
        return read_tree(t)


# ---------------------------------------------------------------- detection

def game_dir(files):
    """The flat {NAME: bytes} of the directory holding GAME.EXE and COVERT.EXE."""
    dirs = {}
    for path, data in files.items():
        d, _, name = path.rpartition("/")
        dirs.setdefault(d, {})[name.upper()] = data
    hits = [d for d, fs in dirs.items() if all(m in fs for m in MARKERS)]
    if not hits:
        return None
    best = min(hits, key=len)                  # the shallowest one
    # only DOS 8.3 names: drops launcher files a repack put next to the game
    # (eXoDOS's "Covert Action (1990).bat" etc.)
    return {n: d for n, d in dirs[best].items() if DOS_NAME.match(n)}


def collect(source):
    """{NAME: bytes} of the game from SOURCE (file or directory)."""
    if os.path.isdir(source):
        files = read_tree(source)
        images = {p: b for p, b in files.items() if looks_like_fat(b)}
        return game_dir(files) or (from_floppies(images) if images else None)
    data = open(source, "rb").read()
    if data[:4] == b"xar!":
        return game_dir(from_pkg(data))
    if data[:6] == b"7z\xbc\xaf\x27\x1c":
        files = from_7z(source)
        images = {p: b for p, b in files.items() if looks_like_fat(b)}
        return game_dir(files) or (from_floppies(images) if images else None)
    if data[:2] == b"MZ" and b"Inno Setup" in data[:0x200000]:
        return game_dir(from_inno(source))
    if looks_like_fat(data):
        return from_floppies({source: data})
    try:                                       # .zip, or a script/SFX with a zip appended
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            return game_dir({i.filename: z.read(i) for i in z.infolist() if not i.is_dir()})
    except zipfile.BadZipFile:
        pass
    sys.exit(f"{source}: unknown archive format")


def compare(files, ref_dir):
    ref = {f.upper(): open(os.path.join(ref_dir, f), "rb").read()
           for f in os.listdir(ref_dir) if os.path.isfile(os.path.join(ref_dir, f))}
    same = sorted(n for n in files if n in ref and ref[n] == files[n])
    diff = sorted(n for n in files if n in ref and ref[n] != files[n])
    extra = sorted(n for n in files if n not in ref)
    missing = sorted(n for n in ref if n not in files)
    print(f"  vs {ref_dir}: {len(same)} identical, {len(diff)} differ, "
          f"{len(missing)} missing, {len(extra)} extra")
    for label, names in (("differ", diff), ("missing", missing), ("extra", extra)):
        if names:
            print(f"    {label}: {' '.join(names)}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("source")
    ap.add_argument("outdir")
    ap.add_argument("--compare", metavar="DIR")
    a = ap.parse_args()
    files = collect(a.source)
    if not files:
        sys.exit(f"{a.source}: no Covert Action game directory found")
    os.makedirs(a.outdir, exist_ok=True)
    for name, data in sorted(files.items()):
        with open(os.path.join(a.outdir, name), "wb") as f:
            f.write(data)
    digest = hashlib.sha1(b"".join(n.encode() + hashlib.sha1(d).digest()
                                    for n, d in sorted(files.items()))).hexdigest()[:12]
    print(f"{a.source}: {len(files)} files -> {a.outdir} (set {digest})")
    if a.compare:
        compare(files, a.compare)


if __name__ == "__main__":
    main()
