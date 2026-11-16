# Covert Action recompiled

Source for all 18 executables of Sid Meier's Covert Action (MicroProse, 1990), and
the scripts that build them with the original Microsoft toolchain. Each one comes
out byte-identical to the shipped file:

- the eight programs, in C (plus their small assembly modules): COVERT.EXE (the
  launcher), INTRO.EXE (hardware menu), GAME.EXE, FINAL.EXE, TAC.EXE (break-ins),
  CHASE.EXE (car chases), BUG.EXE (wiretaps) and CODE.EXE (code breaking)
- the ten drivers, in assembly: CGRAPHIC, EGRAPHIC, MGRAPHIC and TGRAPHIC.EXE
  (graphics), MISC.EXE (keyboard, joystick) and ASOUND, ISOUND, NSOUND, RSOUND and
  TSOUND.CA (sound)

No game files are needed to build. The game's data files (pictures, animations,
text) are not part of this repository; to play, copy the built executables over an
installed copy of the game.

## What you need

- DOSBox-X (the build runs the DOS compiler in it headlessly; on macOS the app in
  `/Applications`, elsewhere `dosbox-x` on the PATH or `$DOSBOX`)
- Python 3
- the Microsoft C 5.1 and MASM 5.10 disk sets (not included), for example WinWorld's
  `Microsoft C 5.1 Optimizing Compiler (5.25).7z` and
  `Microsoft Macro Assembler 5.1 (5.25).7z`. Put the archives in `resources/` and run

  ```bash
  tools/setup_toolchain.py
  ```

  (or name the archives, disk images or directories as arguments; `.7z` needs the
  `7z` tool). It finds the files below by SHA-1 and installs them in
  `toolchain/msc51/`:

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
+SLIBFP.LIB +EM.LIB +LIBH.LIB;` with LIB 3.11, in DOSBox-X), checking that the result
is the expected file. The other eight are copied from the disks as they are.

## Building

```bash
tools/build_all.sh
```

builds everything into `build/out/` (about a minute). To check the result against
an original game directory, point `ORIG_DIR` at it (or put it in `resources/Covert`):

```bash
ORIG_DIR=/path/to/game tools/build_all.sh
```

Then each line says `byte-identical`, and the exit status is 0 only if all 18 are.
Single programs: `tools/rebuild/build.sh GAME`; single drivers:
`tools/drivers/build.sh MGRAPHIC`.

**FINAL.EXE and the copy protection.** `identify_leader_faces` (pick the leader's
face from the manual) is the copy protection. The GOG and eXoDOS releases have it
disabled by a two-byte patch (a JNE replaced by two NOPs), which the build applies
by default. `NO_PATCHES=1` builds the 1990 floppy release's FINAL.EXE instead:

```bash
NO_PATCHES=1 ORIG_DIR=/path/to/floppy/game tools/rebuild/build.sh FINAL
```

### Getting an original game directory to compare with

`tools/extract_game.py SOURCE OUTDIR` unpacks the game from any of these releases:
the GOG Windows installer (needs `innoextract`), the GOG macOS `.pkg`, the GOG Linux
`.sh`, the eXoDOS `.zip`, and the 3.5" or 5.25" floppy sets (a `.7z` of disk images,
needs `7z`; disks are installed in order like INSTALL.BAT). All of them give the same
files except FINAL.EXE (patched in the GOG/eXoDOS releases, not on the floppies).

### Docker

`docker/Dockerfile` (Debian: DOSBox-X, Python 3, `innoextract`, `7zip`) builds
everything without installing anything locally. The image contains only this
repository's sources and tools, no game files and no Microsoft files, so it can be
built once and shared:

```bash
docker build -f docker/Dockerfile -t covert-recomp .
```

To use it, make a folder with the two Microsoft disk archives in it (and, to compare,
an original game directory named `original`), and mount it at `/work`:

```bash
docker run --rm -v "/path/to/folder:/work" covert-recomp
```

In Docker Desktop: Images > `covert-recomp` > Run > Optional settings > Volumes, host
path = the folder, container path = `/work`. The container sets up the toolchain
from the archives (kept in `msc51/` in the folder, so later runs skip that step),
builds all 18 executables into `out/` in the folder, and compares them with
`original/` if it's there. The log shows one line per executable. Without the
archives it stops with a message saying what to provide. A ready toolchain can also
be mounted directly at `/covert/toolchain/msc51`. Other commands run instead of the
build when given as arguments, e.g. `tools/extract_game.py`.

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
| `tools/extract_game.py` | unpacks a game release (for the comparison) |
| `tools/setup_toolchain.py` | installs `toolchain/msc51` from the Microsoft disk archives |
| `decomp/*/functions*.txt`, `tools/names/*.lib.txt` | function names and addresses per program (from the analysis), used to name and place symbols |
| `toolchain/msc51/` | the Microsoft files (installed by `setup_toolchain.py`) |
| `resources/` | where you put the disk archives (ignored by git) |
| `docker/` | the build image and its entry point |

Compiler options are `CL /c /AS /Gs /Oas /Zl` (FILEIO with `/Ox`, a few objects
with `/Zd`); the per-object settings are in `baseline.py`.
