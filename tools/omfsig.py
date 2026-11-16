#!/usr/bin/env python3
"""FLIRT-style matching of OMF library functions against MZ executables.

Parses 16-bit OMF .LIB/.OBJ files, builds a byte pattern for every public
symbol in a code segment (fixup bytes are wildcards), and searches for exact
matches in the load image of MZ executables.

Usage:
  omfsig.py --lib A.LIB [--lib B.LIB ...] EXE [EXE ...] [--names-dir DIR]

For each EXE prints matches and optionally writes DIR/<PROG>.lib.txt in the
tools/names format (addresses as lin:<hex linear address>, assuming the image
is loaded at segment 0x1000 as Ghidra does).
"""
import argparse
import os
import re
import struct
import sys
from collections import defaultdict

LOAD_SEG = 0x1000
MIN_FIXED = 6  # minimum non-wildcard bytes for a usable pattern


class Module:
    def __init__(self, lib, name):
        self.lib = lib
        self.name = name
        self.lnames = [None]
        self.segs = [None]  # (name, class, length)
        self.data = {}  # seg index -> bytearray
        self.mask = {}  # seg index -> bytearray (1 = fixed byte)
        self.pubs = []  # (name, seg, offset)
        self.extdefs = [None]
        self.fixtargets = {}  # (seg, off) -> extern name for call targets
        self.comdefs = []  # (name, "far"/"near", size) communal definitions


def read_index(b, p):
    v = b[p]
    if v & 0x80:
        return ((v & 0x7F) << 8) | b[p + 1], p + 2
    return v, p + 1


def read_name(b, p):
    n = b[p]
    return b[p + 1:p + 1 + n].decode("latin1"), p + 1 + n


def parse_fixupp(m, body, last_seg, last_off, threads):
    p = 0
    while p < len(body):
        t = body[p]
        if not (t & 0x80):
            # THREAD subrecord
            d = (t >> 6) & 1
            method = (t >> 2) & 7
            num = t & 3
            p += 1
            if d == 0:  # target thread
                idx, p = read_index(body, p)
                threads[("T", num)] = (method & 3, idx)
            else:  # frame thread
                if method < 3:
                    idx, p = read_index(body, p)
                else:
                    idx = None
                threads[("F", num)] = (method, idx)
            continue
        locat = (t << 8) | body[p + 1]
        p += 2
        loc = (locat >> 10) & 0xF
        drec = locat & 0x3FF
        fixdat = body[p]
        p += 1
        f_thread = (fixdat >> 7) & 1
        frame = (fixdat >> 4) & 7
        t_thread = (fixdat >> 3) & 1
        p_bit = (fixdat >> 2) & 1
        targt = fixdat & 3
        if not f_thread and frame < 3:
            _, p = read_index(body, p)
        if t_thread:
            tmethod, tidx = threads.get(("T", targt), (0, 0))
        else:
            tmethod = targt
            tidx, p = read_index(body, p)
        if not p_bit:
            p += 2  # target displacement
        size = {0: 1, 1: 2, 2: 2, 3: 4, 4: 1, 5: 2, 9: 4, 11: 6, 13: 4}.get(loc, 2)
        if last_seg is None:
            continue
        mk = m.mask[last_seg]
        for i in range(size):
            o = last_off + drec + i
            if o < len(mk):
                mk[o] = 0
        if tmethod == 2 and tidx < len(m.extdefs):  # EXTDEF target
            m.fixtargets[(last_seg, last_off + drec)] = m.extdefs[tidx]


def parse_modules(path):
    with open(path, "rb") as f:
        b = f.read()
    lib = os.path.basename(path)
    mods = []
    p = 0
    page = 16
    if b[0] == 0xF0:
        (rlen,) = struct.unpack_from("<H", b, 1)
        page = rlen + 3
        p = page
    m = None
    last_seg = last_off = None
    threads = {}
    while p + 3 <= len(b):
        typ = b[p]
        (rlen,) = struct.unpack_from("<H", b, p + 1)
        body = b[p + 3:p + 3 + rlen - 1]
        nxt = p + 3 + rlen
        if typ == 0xF1:  # library dictionary / end
            break
        if typ == 0x80:  # THEADR
            name, _ = read_name(body, 0)
            m = Module(lib, name)
            threads = {}
            last_seg = None
        elif m is None:
            p = nxt
            continue
        elif typ == 0x96:  # LNAMES
            q = 0
            while q < len(body):
                n, q = read_name(body, q)
                m.lnames.append(n)
        elif typ == 0x98:  # SEGDEF
            attr = body[0]
            q = 1
            if (attr >> 5) == 0:
                q += 3
            (length,) = struct.unpack_from("<H", body, q)
            if attr & 2:
                length = 0x10000
            q += 2
            ni, q = read_index(body, q)
            ci, q = read_index(body, q)
            m.segs.append((m.lnames[ni], m.lnames[ci], length))
            idx = len(m.segs) - 1
            m.data[idx] = bytearray(length)
            m.mask[idx] = bytearray(length)
        elif typ in (0x8C,):  # EXTDEF
            q = 0
            while q < len(body):
                n, q = read_name(body, q)
                _, q = read_index(body, q)
                m.extdefs.append(n)
        elif typ == 0xB0:  # COMDEF (communal variables; not added to extdefs)
            q = 0
            while q < len(body):
                n, q = read_name(body, q)
                _, q = read_index(body, q)
                kind = body[q]
                q += 1
                sizes = []
                for _ in range(2 if kind == 0x61 else 1):
                    v = body[q]
                    q += 1
                    if v > 0x80:                  # 81h: word, 84h: 3 bytes, 88h: dword follows
                        nb = {0x81: 2, 0x84: 3, 0x88: 4}[v]
                        v = int.from_bytes(body[q:q + nb], "little")
                        q += nb
                    sizes.append(v)
                size = sizes[0] * sizes[1] if kind == 0x61 else sizes[0]
                m.comdefs.append((n, "far" if kind == 0x61 else "near", size))
        elif typ in (0x90, 0xB6):  # PUBDEF / LPUBDEF
            q = 0
            _, q = read_index(body, q)
            si, q = read_index(body, q)
            if si == 0:
                q += 2
            while q < len(body):
                n, q = read_name(body, q)
                (off,) = struct.unpack_from("<H", body, q)
                q += 2
                _, q = read_index(body, q)
                m.pubs.append((n, si, off))
        elif typ == 0xA0:  # LEDATA
            si, q = read_index(body, 0)
            (off,) = struct.unpack_from("<H", body, q)
            q += 2
            chunk = body[q:]
            m.data[si][off:off + len(chunk)] = chunk
            m.mask[si][off:off + len(chunk)] = b"\x01" * len(chunk)
            last_seg, last_off = si, off
        elif typ == 0xA2:  # LIDATA: not expanded; treat as unknown data
            last_seg = None
        elif typ == 0x9C:  # FIXUPP
            parse_fixupp(m, body, last_seg, last_off, threads)
        elif typ == 0x8A:  # MODEND
            mods.append(m)
            m = None
            if b[0] == 0xF0:  # modules in a library start on page boundaries
                nxt = (nxt + page - 1) // page * page
        p = nxt
    return mods


def build_patterns(mods):
    pats = []
    for m in mods:
        byseg = defaultdict(list)
        for name, si, off in m.pubs:
            if si and si < len(m.segs) and "CODE" in (m.segs[si][1] or "").upper():
                byseg[si].append((off, name))
        for si, lst in byseg.items():
            lst.sort()
            seglen = m.segs[si][2]
            # Highest offset with data defined, to bound the last function.
            mk = m.mask[si]
            data_end = seglen
            while data_end > 0 and mk[data_end - 1] == 0 and m.data[si][data_end - 1] == 0:
                data_end -= 1
            for i, (off, name) in enumerate(lst):
                end = lst[i + 1][0] if i + 1 < len(lst) else data_end
                if end <= off:
                    continue
                data = bytes(m.data[si][off:end])
                mask = bytes(m.mask[si][off:end])
                # Bytes never written by LEDATA (mask 0, not fixups) are also wildcards.
                fixed = sum(mask)
                if fixed < MIN_FIXED:
                    continue
                aliases = [n for o, n in lst if o == off]
                pats.append({
                    "name": name, "aliases": aliases, "module": m.name, "lib": m.lib,
                    "data": data, "mask": mask, "fixed": fixed,
                    "calls": {o - off: t for (s, o), t in m.fixtargets.items() if s == si and off <= o < end},
                })
    # Deduplicate identical (name, offset-in-module) aliases: keep one per (module, data).
    seen = {}
    out = []
    for pt in pats:
        key = (pt["module"], pt["data"], pt["mask"])
        if key in seen:
            continue
        seen[key] = pt
        out.append(pt)
    return out


def to_regex(data, mask):
    parts = []
    for d, k in zip(data, mask):
        parts.append(re.escape(bytes([d])) if k else b".")
    return re.compile(b"".join(parts), re.DOTALL)


def load_image(path):
    with open(path, "rb") as f:
        d = f.read()
    last, pages, _, hdr = struct.unpack_from("<4H", d, 2)
    size = pages * 512 - (512 - last if last else 0)
    return d[hdr * 16:size]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lib", action="append", required=True)
    ap.add_argument("--names-dir")
    ap.add_argument("--min-len", type=int, default=12, help="minimum fixed bytes to accept a match")
    ap.add_argument("exe", nargs="+")
    a = ap.parse_args()

    mods = []
    for lib in a.lib:
        mods += parse_modules(lib)
    pats = build_patterns(mods)
    print(f"{len(mods)} modules, {len(pats)} function patterns", file=sys.stderr)
    for pt in pats:
        pt["re"] = to_regex(pt["data"], pt["mask"])

    for exe in a.exe:
        img = load_image(exe)
        hits = defaultdict(list)  # offset -> patterns
        for pt in pats:
            if pt["fixed"] < a.min_len:
                continue
            for mt in pt["re"].finditer(img):
                hits[mt.start()].append(pt)
        # Resolve: at each offset keep the longest pattern; drop patterns that match
        # more than one location (ambiguous) unless they are long.
        count_by_pat = defaultdict(int)
        for off, lst in hits.items():
            for pt in lst:
                count_by_pat[id(pt)] += 1
        result = []
        for off in sorted(hits):
            lst = sorted(hits[off], key=lambda pt: -pt["fixed"])
            best = lst[0]
            if count_by_pat[id(best)] > 1 and best["fixed"] < 32:
                continue
            names = sorted({n for pt in lst if pt["fixed"] == best["fixed"] for n in pt["aliases"]})
            result.append((off, best, names))
        prog = os.path.splitext(os.path.basename(exe))[0].upper()
        print(f"== {prog}: {len(result)} library functions matched")
        mods_hit = sorted({best["module"] for _, best, _ in result})
        for off, best, names in result:
            lin = LOAD_SEG * 16 + off
            print(f"  {lin:05x}  {'/'.join(names):30s} {best['lib']}:{best['module']} ({len(best['data'])} bytes)")
        if a.names_dir:
            os.makedirs(a.names_dir, exist_ok=True)
            with open(os.path.join(a.names_dir, f"{prog}.lib.txt"), "w") as f:
                f.write(f"# Generated by omfsig.py from MSC 5.1 libraries. {len(result)} matches.\n")
                for off, best, names in result:
                    lin = LOAD_SEG * 16 + off
                    nm = names[0][1:] if names[0].startswith("_") else names[0]  # MSC prefixes C names with '_'
                    f.write(f"func lin:{lin:05x} {nm} MSC 5.1 runtime: {'/'.join(names)} "
                            f"({best['lib']}:{best['module']}, exact match {best['fixed']}/{len(best['data'])} bytes)\n")


if __name__ == "__main__":
    main()
