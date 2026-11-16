#!/usr/bin/env python3
"""Check files against SHA1SUMS.

  sha1check.py FILE NAME      compare FILE with the hash listed for NAME
  sha1check.py --toolchain    check toolchain/msc51 (warns, never fails)

For a built executable, a difference is reported but not an error: the build is
expected to match the original release, and differs once the source is changed.
Exit status: 0 = matches, 1 = differs, 2 = no hash listed for NAME.
"""
import hashlib
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


def expected():
    out = {}
    for line in open(os.path.join(ROOT, "SHA1SUMS")):
        line = line.strip()
        if line and not line.startswith("#"):
            h, name = line.split(None, 1)
            out[name] = h
    return out


def sha1(path):
    return hashlib.sha1(open(path, "rb").read()).hexdigest()


def main():
    sums = expected()
    if sys.argv[1:] == ["--toolchain"]:
        bad = [n for n in sums if n.startswith("toolchain/")
               and os.path.exists(os.path.join(ROOT, n)) and sha1(os.path.join(ROOT, n)) != sums[n]]
        for n in bad:
            print(f"warning: {n} is not the expected file (SHA1SUMS); the build may differ",
                  file=sys.stderr)
        return 0
    path, name = sys.argv[1], sys.argv[2]
    if name not in sums:
        print(f"{name}: built (SHA-1 {sha1(path)[:12]}, no expected hash)")
        return 2
    got = sha1(path)
    if got == sums[name]:
        print(f"{name.split()[0]}: built, matches the original release ({got[:12]})")
        return 0
    print(f"{name.split()[0]}: built, DIFFERS from the original release "
          f"(SHA-1 {got[:12]}, expected {sums[name][:12]})")
    return 1


if __name__ == "__main__":
    sys.exit(main())
