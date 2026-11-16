#!/usr/bin/env python3
"""Patch bytes in a compiled object's _TEXT, the way the shipped EXE was patched.

Usage: objpatch.py OBJ OFFSET OLDHEX NEWHEX   (OFFSET: hex offset in the object's _TEXT)
Finds the LEDATA record(s) holding _TEXT[OFFSET:OFFSET+n], checks the bytes there
are OLDHEX, writes NEWHEX and fixes the record checksums. Used by build.sh for
`patches` in baseline.py (FINAL's identify_leader_faces, the copy protection, has a JNE patched to NOPs
in the shipped EXE - no C source produces that)."""
import struct
import sys


def main():
    path, off = sys.argv[1], int(sys.argv[2], 16)
    old, new = bytes.fromhex(sys.argv[3]), bytes.fromhex(sys.argv[4])
    assert len(old) == len(new)
    b = bytearray(open(path, "rb").read())
    i, names, segs, done = 0, [""], [None], 0
    while i < len(b):
        t = b[i]
        ln = struct.unpack_from("<H", b, i + 1)[0]
        body = i + 3
        if t == 0x96:
            q = body
            while q < body + ln - 1:
                n = b[q]
                names.append(b[q + 1:q + 1 + n].decode())
                q += 1 + n
        elif t == 0x98:
            segs.append(names[b[body + 3]])
        elif t == 0xA0 and segs[b[body]] == "_TEXT":
            start = struct.unpack_from("<H", b, body + 1)[0]
            data = body + 3
            n = ln - 1 - 3
            for k in range(len(old)):
                p = off + k
                if start <= p < start + n:
                    if b[data + p - start] != old[k]:
                        sys.exit(f"{path}: byte at +{p:#x} is {b[data + p - start]:02x}, expected {old[k]:02x}")
                    b[data + p - start] = new[k]
                    done += 1
            # fix checksum
            b[i + 3 + ln - 1] = (-sum(b[i:i + 3 + ln - 1])) & 0xFF
        i += 3 + ln
    if done != len(old):
        sys.exit(f"{path}: patched {done} of {len(old)} bytes")
    open(path, "wb").write(b)
    print(f"{path}: patched +{off:#x} {old.hex()} -> {new.hex()}")


if __name__ == "__main__":
    main()
