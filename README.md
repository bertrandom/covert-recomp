# Covert Action recompiled

Source for all 18 executables of Sid Meier's Covert Action (MicroProse, 1990), and
the scripts that build them with the original Microsoft toolchain. Each one comes
out byte-identical to the shipped file (`SHA1SUMS` lists their SHA-1):

- the eight programs, in C (plus their small assembly modules): COVERT.EXE (the
  launcher), INTRO.EXE (hardware menu), GAME.EXE, FINAL.EXE, TAC.EXE (break-ins),
  CHASE.EXE (car chases), BUG.EXE (wiretaps) and CODE.EXE (code breaking)
- the ten drivers, in assembly: CGRAPHIC, EGRAPHIC, MGRAPHIC and TGRAPHIC.EXE
  (graphics), MISC.EXE (keyboard, joystick) and ASOUND, ISOUND, NSOUND, RSOUND and
  TSOUND.CA (sound)

No game files are needed to build. The game's data files (pictures, animations,
text) are not part of this repository; to play, copy the built executables over an
installed copy of the game. The easiest way to build is with Docker
([below](#building-with-docker-easiest)).

## What you need

Both ways of building need the Microsoft C 5.1 and MASM 5.10 disk sets, which are
not included. Download these two archives from WinWorld (the 5.25" disk versions);
only files with exactly these SHA-1 hashes are accepted (they're also in `SHA1SUMS`):

| Archive | Download from | SHA-1 |
|---|---|---|
| `Microsoft C 5.1 Optimizing Compiler (5.25).7z` | [WinWorld: Microsoft C/C++ 5.x](https://winworldpc.com/product/microsoft-c-c/5x) | `8fe843150ea5ac2598703c7e6c893b465ae38967` |
| `Microsoft Macro Assembler 5.1 (5.25).7z` | [WinWorld: Macro Assembler 5.x](https://winworldpc.com/product/macro-assembler/5x) | `2a4a0141a3c938b3cf0adc0018168ccc96305ae9` |

## Building with Docker (easiest)

The easiest way to build is with Docker: the image has everything else (DOSBox-X,
Python 3, 7-Zip), so nothing needs to be installed or set up by hand. It contains
only this repository's sources and tools, no game files and no Microsoft files.

1. Build the image once:

   ```bash
   docker build -f docker/Dockerfile -t covert-recomp .
   ```

2. Make a folder and put the two Microsoft archives in it.
3. Run the image with that folder mounted at `/work`:

   ```bash
   docker run --rm -v "/path/to/folder:/work" covert-recomp
   ```

   In Docker Desktop: Images > `covert-recomp` > Run > Optional settings > Volumes,
   host path = the folder, container path = `/work`, then Run.

The container checks the archives' SHA-1, sets up the toolchain from them (kept in
`msc51/` in the folder, so later runs skip that step), and builds all 18 executables
into `out/` in the folder. The log has one line per executable saying whether it
matches the original release (see [Checking the result](#checking-the-result)).
Without the archives it stops with a message saying what to provide. `-e
NO_PATCHES=1` builds the floppy FINAL.EXE (see below), and a ready toolchain can also
be mounted directly at `/covert/toolchain/msc51`.

## Building without Docker

You also need:

- DOSBox-X (the build runs the DOS compiler in it headlessly; on macOS the app in
  `/Applications`, elsewhere `dosbox-x` on the PATH or `$DOSBOX`)
- Python 3
- the `7z` tool (7-Zip), to open the archives

Put the two archives in `resources/` and set up the toolchain once:

```bash
tools/setup_toolchain.py
```

It checks each archive's SHA-1 before opening it, then installs these files in
`toolchain/msc51/`, each checked against `SHA1SUMS`:

| File | From | Used for |
|---|---|---|
| `BIN/CL.EXE`, `BIN/C1.EXE`, `BIN/C2.EXE`, `BIN/C3.EXE` | MSC 5.1 | the compiler driver and its three passes |
| `BIN/LINK.EXE` | MSC 5.1 (LINK 5.01) | linking, `/EXEPACK` for the six game programs |
| `BIN/EXEMOD.EXE` | MSC 5.1 | CODE.EXE's minimum-allocation header field |
| `LIB/SLIBCE.LIB` | MSC 5.1 | the small-model C runtime |
| `INCLUDE/STDIO.H` | MSC 5.1 | the one system header the sources include |
| `BIN/MASM.EXE` | MASM 5.10 | the assembly sources |

`SLIBCE.LIB` is not on the disks as such: MSC 5.1's SETUP builds it from the
component libraries, and so does `setup_toolchain.py` (`LIB SLIBCE.LIB +SLIBCR.LIB
+SLIBFP.LIB +EM.LIB +LIBH.LIB;` with LIB 3.11, in DOSBox-X). The other eight are
copied from the disk images as they are.

Then build:

```bash
tools/build_all.sh
```

This builds all 18 into `build/out/` (about a minute). Single programs:
`tools/rebuild/build.sh GAME`; single drivers: `tools/drivers/build.sh MGRAPHIC`.

## Checking the result

Each built executable's SHA-1 is compared with the original release's (`SHA1SUMS`),
and every line says whether it matches:

```
GAME.EXE: built, matches the original release (8168312a996c)
...
18/18 built into build/out/: 18 match the original release, 0 differ
```

A difference is reported but isn't an error: once you change the source, the
executables are expected to differ (`GAME.EXE: built, DIFFERS from the original
release (SHA-1 …, expected …)`), and they're still built. The exit status is non-zero
only if something failed to build.

**FINAL.EXE and the copy protection.** `identify_leader_faces` (pick the leader's
face from the manual) is the copy protection. The GOG and eXoDOS releases have it
disabled by a two-byte patch (a JNE replaced by two NOPs), which the build applies
by default, and `SHA1SUMS` lists that FINAL.EXE. `NO_PATCHES=1` builds the 1990
floppy release's FINAL.EXE instead, checked against its own hash:

```bash
NO_PATCHES=1 tools/rebuild/build.sh FINAL
```

## Layout

| Directory | What it is |
|---|---|
| `src/CODE`, `BUG`, `CHASE`, `TAC`, `GAME`, `FINAL`, `COVERT`, `INTRO` | C source of each program |
| `src/MPSLIB` | the MicroProse C library: text windows and menus, input, disk prompts, `env.sve`, mouse, drawing, file and picture I/O, the `.pan` animation player |
| `src/GAMELIB` | the game library shared by BUG, TAC, FINAL and GAME: clues and locations, dossiers, `text.dta`, faces, people, the teletype |
| `src/ASM` | the programs' assembly modules: driver stub table and overlay loader, graphics primitives and picture decoder, mouse, INT 24h handler, INTRO's helpers |
| `src/ASMDATA` | two hand-written CONST data objects |
| `src/DRIVERS` | the graphics, MISC and sound drivers |
| `tools/build_all.sh` | builds all 18 |
| `tools/rebuild/` | the program build: `build.sh`, `baseline.py` (per-program layout: object order, data placement, symbols; writes the link inputs), `omfwrite.py`, `objpatch.py` (the FINAL.EXE patch), `syms/` (data symbol addresses) |
| `tools/drivers/build.sh` | the driver build |
| `tools/dosrun.sh` | runs DOS commands in DOSBox-X with `C:` = `toolchain/msc51` and `D:` = `build/` |
| `tools/omfsig.py` | OMF object reader used by `baseline.py` |
| `tools/setup_toolchain.py` | installs `toolchain/msc51` from the Microsoft disk archives (SHA-1 checked) |
| `tools/sha1check.py` | compares a built file with `SHA1SUMS` |
| `SHA1SUMS` | SHA-1 of the two archives, the toolchain files and the 18 executables |
| `decomp/*/functions*.txt`, `tools/names/*.lib.txt` | function names and addresses per program (from the analysis), used to name and place symbols |
| `toolchain/msc51/` | the Microsoft files (installed by `setup_toolchain.py`) |
| `resources/` | where you put the disk archives (ignored by git) |
| `docker/` | the build image and its entry point |

Compiler options are `CL /c /AS /Gs /Oas /Zl` (FILEIO with `/Ox`, a few objects
with `/Zd`); the per-object settings are in `baseline.py`.
