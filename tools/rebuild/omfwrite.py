#!/usr/bin/env python3
"""Minimal OMF (Intel/Microsoft relocatable object) writer for 16-bit code.

Supports what the CODE.EXE baseline needs: one code segment plus an (empty)
_DATA in DGROUP, LEDATA records with chosen boundaries, FIXUPP records whose
subrecords are written in a chosen order, EXTDEF, PUBDEF and a default-library
comment. Fixup kinds:
  ("seg", ext_name)   16-bit segment base of an external symbol's segment
  ("group", "DGROUP") 16-bit DGROUP paragraph
  ("self", None)      16-bit segment base of this object's own code segment (SEG _TEXT)
  ("call", ext_name)  16-bit self-relative offset to a near external (CALL rel16)
"""
import struct


def rec(typ, body):
    data = bytes([typ]) + struct.pack("<H", len(body) + 1) + body
    chk = (-sum(data)) & 0xFF
    return data + bytes([chk])


def name(s):
    b = s.encode("latin1")
    return bytes([len(b)]) + b


def index(i):
    return bytes([i]) if i < 0x80 else bytes([0x80 | (i >> 8), i & 0xFF])


class ObjWriter:
    def __init__(self, modname, segname, segclass, align="word", combine="public"):
        self.modname = modname
        self.segname = segname
        self.segclass = segclass
        self.align = {"byte": 1, "word": 2, "para": 3}[align]
        self.combine = {"public": 2, "common": 6}[combine]
        self.data = bytearray()
        self.fixups = []      # (offset, kind, target)
        self.exts = []        # external names in order
        self.pubs = []        # (name, offset)
        self.ddata = b""      # contents of this object's _DATA (no fixups)
        self.dpubs = []       # (name, offset in _DATA)
        self.records = None   # list of (start, end, [fixup offsets in emit order]) or None

    def ext(self, n):
        if n not in self.exts:
            self.exts.append(n)
        return self.exts.index(n) + 1

    def build(self, records):
        """records: list of (start, end, fixups_in_order); fixups are (off, kind, target)."""
        for _, _, fx in records:          # register externals before EXTDEF is written
            for _, kind, target in fx:
                if kind in ("seg", "call"):
                    self.ext(target)
        out = bytearray()
        out += rec(0x80, name(self.modname))
        lnames = ["", self.segname, self.segclass, "DGROUP", "_DATA", "DATA"]
        out += rec(0x96, b"".join(name(n) for n in lnames))
        acbp = (self.align << 5) | (self.combine << 2)
        # SEGDEF 1: code segment; SEGDEF 2: _DATA (usually empty; it makes DGROUP exist).
        out += rec(0x98, bytes([acbp]) + struct.pack("<H", len(self.data)) + index(2) + index(3) + index(1))
        out += rec(0x98, bytes([0x48]) + struct.pack("<H", len(self.ddata)) + index(5) + index(6) + index(1))
        out += rec(0x9A, index(4) + b"\xFF" + index(2))
        if self.exts:
            out += rec(0x8C, b"".join(name(n) + index(0) for n in self.exts))
        for n, off in self.pubs:
            out += rec(0x90, index(0) + index(1) + name(n) + struct.pack("<H", off) + index(0))
        for n, off in self.dpubs:
            out += rec(0x90, index(1) + index(2) + name(n) + struct.pack("<H", off) + index(0))
        for p in range(0, len(self.ddata), 1024):
            out += rec(0xA0, index(2) + struct.pack("<H", p) + self.ddata[p:p + 1024])
        for start, end, fx in records:
            out += rec(0xA0, index(1) + struct.pack("<H", start) + bytes(self.data[start:end]))
            if fx:
                body = bytearray()
                for off, kind, target in fx:
                    rel = off - start
                    assert 0 <= rel < 1024
                    if kind == "seg":
                        locat = 0x8000 | 0x4000 | (2 << 10) | rel      # segment-relative, base
                        body += struct.pack(">H", locat)
                        body += bytes([0x56]) + index(self.ext(target))  # F5 (target), P=1, T2 EXTDEF
                    elif kind == "self":
                        locat = 0x8000 | 0x4000 | (2 << 10) | rel
                        body += struct.pack(">H", locat)
                        body += bytes([0x04]) + index(1) + index(1)       # F0 SEGDEF #1, P=1, T0 SEGDEF #1
                    elif kind == "group":
                        locat = 0x8000 | 0x4000 | (2 << 10) | rel
                        body += struct.pack(">H", locat)
                        body += bytes([0x55]) + index(1)                  # F5, P=1, T1 GRPDEF #1
                    elif kind == "call":
                        locat = 0x8000 | (1 << 10) | rel                  # self-relative, offset
                        body += struct.pack(">H", locat)
                        body += bytes([0x46]) + index(self.ext(target))  # F4 (location), P=1, T2
                    else:
                        raise ValueError(kind)
                out += rec(0x9C, bytes(body))
        out += rec(0x8A, b"\x00")
        return bytes(out)
