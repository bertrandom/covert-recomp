#!/usr/bin/env python3
"""Generate a program's build inputs: raw pieces for everything not yet in C.

  baseline.py PROG                 generate build/PROG/{SEG0x,TEXTn,DATA}.ASM
  baseline.py PROG --link-order    LINK object list (e.g. SEG0A+CODE+TEXT1+SEG0B+DATA)
  baseline.py PROG --asm-files     the generated .ASM files
  baseline.py PROG --cl-commands   CL command per C object
  baseline.py PROG --sources       source directories of the C objects
  baseline.py PROG --minalloc      EXEMOD /MIN value (hex), if the original needs one

Outputs in build/PROG/:
  SEG0A.ASM, SEG0B.ASM  the assembly segment, one file per original object: src/ASM/NAME.ASM
  ...                   (asm_src) with PROG_<prog> defined; the .INC files are copied too
  TEXTn.ASM             hand-written raw _TEXT pieces (text_asm), likewise
  TEXTn.OBJ             other raw _TEXT pieces between C objects (OMF written directly so
                        the relocation order matches the original; none left)
  DATn.ASM              program data between two objects that no source covers yet,
                        extracted (none left in the eight programs)
  NAME.ASM              hand-written data objects (data_srcs), copied from src/
  DATA.ASM              _BSS and c_common (sizes and PUBLIC labels only), plus any program
                        _DATA/CONST still extracted (none left)
Relocations become SEG/DGROUP fixups and runtime calls become real `call _name`.

Symbols: the C objects are compiled first (build.sh does that); every external they
reference that no C object defines gets a PUBLIC label at its original address. Code
addresses come from SYMBOLS, then decomp/PROG/functions.txt; data from SYMBOLS.
Names that resolve to the MSC runtime are left to SLIBCE.LIB.
"""
import argparse
import os
import re
import struct
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from omfwrite import ObjWriter  # noqa: E402
import omfsig  # noqa: E402

LOAD_LIN = 0x10000      # Ghidra loads the image at 1000:0000

# Per-program layout. Image offsets unless noted; DGROUP-relative for data.
#   asm          the assembly segment's objects: (start, end, alignment, link position);
#                they are linked before the _TEXT piece that starts at `link position`
#                (None: first; the runtime address: after all of _TEXT). The original
#                relocation order (relocwin.py) shows where each one was linked.
#   asm_src      the src/ASM source of each assembly object (assembled with PROG_<prog>
#                defined for its conditionals)
#   text_asm     {_TEXT start: src/ASM source} for raw _TEXT pieces that are assembly
#   text_start   first user function (_TEXT + 16 bytes reserved by DOSSEG)
#   text_base    image offset of the _TEXT frame
#   runtime      _astart (MSC runtime begins here)
#   dgroup       image offset of DGROUP
#   data         program _DATA [start, end): between crt0's NULL and the runtime's data
#   seg0a_data   end of the data owned by the first assembly object
#   const        program CONST [start, end) still extracted from the image (empty: every
#                CONST word now comes from a C object or a data_srcs object)
#   data_srcs    hand-written MASM data objects: (name, source under src/, DGROUP range of
#                its _DATA or None, name of the object it is linked before or None: last);
#                data_plan places them like C objects
#   bss          program part of _BSS (start, size)
#   common       c_common (start, size): program commons before the runtime's communals
#   common2      program commons after the runtime's communals (start, size), optional
#   minalloc     EXEMOD /MIN value, or None
#   far_symbols  name -> offset of publics inside the far data segment
#   far_data     image range of a far data segment between _TEXT and DGROUP, optional;
#                extracted (FARDATA.ASM) only while no C object defines far_symbols as
#                far communals (ANIMOBJ.C defines anim_mem)
#   bss_init     emit the program _BSS as initialized zeros (it is in the EXE image)
#   epad         contents for EPAD (COMMON with the runtime's one-byte EPAD), optional
#   c_objects    (name, _TEXT start, end, _DATA start, end, extra CL flags, source dir);
#                the _DATA end is only a fallback (the compiled object's size is used)
#   symbols      name -> ("img", image offset) or ("dg", DGROUP offset)
#   runtime_names  image offset -> public name, for runtime routines the matcher missed
#   patches      [(object, _TEXT offset, old hex, new hex)] applied after compiling
#   libs         libraries for LINK (default SLIBCE)
#   asm_frame    paragraph of the assembly segment (default 0: it is first in the image;
#                COVERT and INTRO link it after _TEXT)
#   asm_owns     {assembly object: DGROUP range} of the _DATA its source defines (the first
#                object's [data start, seg0a_data) is implied); data_plan places them
#   exepack      False: linked without /EXEPACK (COVERT, INTRO)
#   lib_from     experimental: link the objects from this one on out of a library
#                (MPS.LIB), as the original probably did with the MicroProse modules
PROGS = {
    "INTRO": dict(
        # like COVERT: _TEXT (main, the assembly helpers 044A-07BE, the runtime), then the
        # assembly segment; its data (0x50A-0x64A) follows main's
        asm=[(0x0CBA, 0x12C0, "WORD", 0x07BE)], asm_frame=0xCB, asm_owns={"SEG0A": (0x050A, 0x064A)},
        asm_src=["DRVLOAD"], text_asm={0x044A: "INTROLIB"},
        text_start=0x0010, text_base=0x0000,
        runtime=0x07BE, dgroup=0x12C0, data=(0x42, 0x064A), seg0a_data=0x0042,
        # _BSS 07DE-082B: the helpers' REGS (also used by main) and the menu tables (the
        # runtime's XO tables follow it, so it is _BSS, not c_common); c_common: 14h bytes
        # (SS = 1B0h puts STACK at DGROUP 0840)
        const=(0x064A, 0x064A), bss=(0x07DE, 0x4E), common=(0x082C, 0x14), minalloc=None,
        exepack=False,
        c_objects=[
            ("INTRO", 0x0010, 0x044A, 0x0042, 0x050A, "", "INTRO"),
        ],
        symbols={
            "_regs": ("dg", 0x07DE), "_snd_sel": ("dg", 0x07F6), "_snd_extra": ("dg", 0x081B),
            "_gfx_sel": ("dg", 0x0824),
        }),
    "COVERT": dict(
        # _TEXT first (main, then the runtime), the assembly segment after it, no EXEPACK
        asm=[(0x11A2, 0x17A0, "WORD", 0x01F4)], asm_frame=0x11A, asm_owns={"SEG0A": (0x0162, 0x02A2)},
        asm_src=["DRVLOAD"],
        text_start=0x0010, text_base=0x0000,
        runtime=0x01F4, dgroup=0x17A0, data=(0x42, 0x02A2), seg0a_data=0x0042,
        # c_common: an unreferenced 14-byte common at 04B2, env_block, video_regs
        const=(0x02A2, 0x02A2), bss=(0x02A2, 0), common=(0x04B2, 0x2EFC), minalloc=None,
        exepack=False,
        c_objects=[
            ("COVERT", 0x0010, 0x01F4, 0x0042, 0x0162, "", "COVERT"),
        ],
        symbols={
            "_env_block": ("dg", 0x04C0), "_video_regs": ("dg", 0x33A0),
        }),
    "CODE": dict(
        asm=[(0x0000, 0x00C9, "PARA", None), (0x00CA, 0x0576, "WORD", 0x2AC0),
             (0x0576, 0x0B4A, "WORD", 0x2AC0)],
        asm_src=["PROBE", "DRVLOAD", "GFX"],
        text_start=0x0B5A, text_base=0x0B40,
        runtime=0x2AC0, dgroup=0x36D0, data=(0x42, 0x1738), seg0a_data=0x1042,
        const=(0x1996, 0x1996), bss=(0x1A70, 0xFE), common=(0x1B70, 0x280), minalloc="FB",
        # the assembly library's data after GFX's (its one object holds the driver stubs
        # and the graphics primitives), then CONST (1994)
        asm_owns={"SEG0B": (0x1264, 0x138C), "SEG0C": (0x138C, 0x1738)},  # loader, graphics
        data_srcs=[("CONSTW", "ASMDATA/CONSTW.ASM", None, None)],
        epad="dw\t0FFFFh",
        c_objects=[
            ("CODE", 0x0B5A, 0x192E, 0x1042, 0x111E, "/Zd", "CODE"),
            ("CLOCK", 0x192E, 0x19CE, 0x111E, 0x1128, "", "CODE"),
            # MicroProse C library (src/MPSLIB), shared by all the programs
            ("TEXTWIN", 0x19CE, 0x224E, 0x1128, 0x119A, "", "MPSLIB"),
            ("UI", 0x224E, 0x26BA, 0x119A, 0x11CE, "/Zd", "MPSLIB"),
            ("DISK", 0x26BA, 0x27EC, 0x11CE, 0x1250, "", "MPSLIB"),
            ("STUBS", 0x27EC, 0x27F0, 0x1250, 0x1250, "", "MPSLIB"),
            ("MOUSE", 0x27F0, 0x2938, 0x1250, 0x1250, "", "MPSLIB"),
            ("GFX", 0x2938, 0x2AC0, 0x1250, 0x1264, "", "MPSLIB"),
        ],
        symbols={
            # assembly segment entry points not (or differently) named in functions.txt
            "_drv_slot36": ("img", 0x0208), "_drv_play_sound": ("img", 0x03CF),
            "_link_driver_stubs": ("img", 0x052D), "_gfx_show_page": ("img", 0x01DC),
            # data
            "_colormap": ("dg", 0x0F82), "_std_colormap": ("dg", 0x0F12), "_std_colormap2": ("dg", 0x0F22),
            "_ticks": ("dg", 0x1A7A), "_revealed": ("dg", 0x1A7C), "_numbuf": ("dg", 0x1AB4),
            "_nletters": ("dg", 0x1ABE), "_count": ("dg", 0x1AC0),
            "_message": ("dg", 0x1B72), "_hyphenate": ("dg", 0x1D40), "_difficulty": ("dg", 0x1D72),
            "_options": ("dg", 0x1D78), "_env44": ("dg", 0x1D7A), "_result": ("dg", 0x1D8E),
            "_elapsed": ("dg", 0x1D90), "_bios_regs": ("dg", 0x1DA0), "_paused": ("dg", 0x1DB2),
            "_done": ("dg", 0x1DBE),
            # library globals (_BSS / c_common)
            "_anim": ("dg", 0x1AF8), "_anim_x": ("dg", 0x1B00), "_line_start": ("dg", 0x1B16),
            "_text_color": ("dg", 0x1B56), "_item_color": ("dg", 0x1B58), "_nlines": ("dg", 0x1B5A),
            "_sel_color": ("dg", 0x1B5C), "_joy_raw": ("dg", 0x1B70), "_rnd_seed": ("dg", 0x1D76),
            "_show_ok": ("dg", 0x1D7C), "_portrait": ("dg", 0x1D7E), "_mouse_regs": ("dg", 0x1D80),
            "_first_item": ("dg", 0x1D92), "_anim_active": ("dg", 0x1D94), "_menu_flag": ("dg", 0x1D96),
            "_nitems": ("dg", 0x1D98), "_redraw_all": ("dg", 0x1D9A), "_box_color": ("dg", 0x1D9C),
            "_max_width": ("dg", 0x1D9E), "_disabled": ("dg", 0x1DAE), "_portrait_x": ("dg", 0x1DB0),
            "_mouse_buttons": ("dg", 0x1DB4), "_mouse_x": ("dg", 0x1DB6), "_mouse_y": ("dg", 0x1DB8),
            "_mouse_count": ("dg", 0x1DBA), "_portrait_y": ("dg", 0x1DBC), "_quit_flag": ("dg", 0x1DBE),
            "_hotkeys": ("dg", 0x1DC0), "_default_sel": ("dg", 0x1DE0), "_box_x2": ("dg", 0x1DE2),
            "_box_y2": ("dg", 0x1DE4),
        }),
    "BUG": dict(
        asm_src=["PROBE", "PALETTE", "DRVLOAD", "GFX"],
        asm=[(0x0000, 0x00C9, "PARA", None), (0x00CA, 0x0156, "WORD", 0x2702),
             (0x0156, 0x0602, "WORD", 0x7E86), (0x0602, 0x0E88, "WORD", 0x8414)],
        text_start=0x0E98, text_base=0x0E80,
        runtime=0x8414, dgroup=0xA630, data=(0x42, 0x33E2), seg0a_data=0x006C,
        const=(0x3914, 0x3914), bss=(0x39EE, 0x1B28), minalloc=None,
        asm_owns={"SEG0C": (0x2F0A, 0x3032), "SEG0D": (0x3036, 0x33E2)},  # loader, graphics
        data_srcs=[("CONSTW", "ASMDATA/CONSTW.ASM", None, None)],
        bss_init=True,      # the original EXE image includes _BSS as zeros
        # c_common includes the runtime's communal stdio buffers (see symbols)
        common=(0x5538, 0x3AA8),
        c_objects=[
            ("BUG", 0x0E98, 0x111C, 0x006C, 0x0092, "", "BUG"),
            ("BOARD", 0x111C, 0x2702, 0x1654, 0x1654, "", "BUG"),
            # Covert Action game library (shared with GAME/TAC/FINAL)
            ("CLUE", 0x2702, 0x49A6, 0x176A, 0x176A, "", "GAMELIB"),
            ("MSGTEXT", 0x49A6, 0x4F44, 0x21EC, 0x240A, "", "GAMELIB"),
            ("FACE", 0x4F44, 0x5516, 0x240A, 0x2420, "", "GAMELIB"),
            ("PERSON", 0x5516, 0x60E2, 0x2420, 0x2420, "", "GAMELIB"),
            ("TELETYPE", 0x60E2, 0x6732, 0x2B54, 0x2B54, "", "GAMELIB"),
            # MicroProse C library
            ("TEXTWIN", 0x6732, 0x6FB2, 0x2DAE, 0x2E20, "", "MPSLIB"),
            ("UI", 0x6FB2, 0x741E, 0x2E20, 0x2E54, "/Zd", "MPSLIB"),
            ("ENV", 0x741E, 0x7BC8, 0x2E54, 0x2E74, "", "MPSLIB"),
            ("DISK", 0x7BC8, 0x7CFA, 0x2E74, 0x2EF6, "", "MPSLIB"),
            ("STUBS", 0x7CFA, 0x7CFE, 0x2EF6, 0x2EF6, "", "MPSLIB"),
            ("GFX", 0x7CFE, 0x7E86, 0x2EF6, 0x2F0A, "", "MPSLIB"),
            ("FILEIO", 0x7E86, 0x8414, 0x3032, 0x3036, "/Ox", "MPSLIB"),
        ],
        symbols={
            # program globals (c_common)
            "_camera_img": ("dg", 0x5C28), "_camera_img2": ("dg", 0x5C2A), "_car_tracer": ("dg", 0x6056),
            "_progress": ("dg", 0x675A), "_alarms": ("dg", 0x747A), "_bug_running": ("dg", 0x7636),
            "_time_limit": ("dg", 0x7DB4), "_orig_difficulty": ("dg", 0x8F96),
            # library globals (_BSS / c_common)
            "_anim": ("dg", 0x3A68), "_anim_x": ("dg", 0x3A70), "_line_start": ("dg", 0x3A86),
            "_text_color": ("dg", 0x3AC6), "_item_color": ("dg", 0x3AC8), "_nlines": ("dg", 0x3ACA),
            "_sel_color": ("dg", 0x3ACC), "_joy_raw": ("dg", 0x5540), "_message": ("dg", 0x5542),
            "_rnd_seed": ("dg", 0x5C20), "_options": ("dg", 0x5C26), "_show_ok": ("dg", 0x6052),
            "_portrait": ("dg", 0x6758), "_first_item": ("dg", 0x7262), "_anim_active": ("dg", 0x7474),
            "_menu_flag": ("dg", 0x7476), "_nitems": ("dg", 0x747C), "_redraw_all": ("dg", 0x763E),
            "_box_color": ("dg", 0x7642), "_max_width": ("dg", 0x7646), "_disabled": ("dg", 0x77B2),
            "_bios_regs": ("dg", 0x779E), "_portrait_x": ("dg", 0x7FBA), "_paused": ("dg", 0x7FBC),
            "_portrait_y": ("dg", 0x8200), "_quit_flag": ("dg", 0x8206), "_hotkeys": ("dg", 0x8208),
            "_default_sel": ("dg", 0x8228), "_box_x2": ("dg", 0x8276), "_box_y2": ("dg", 0x843A),
            # The runtime's communal stdio buffers (0x200 each). LINK scattered them among the
            # program's commons; defining them here keeps it from appending them. _bufin is
            # pinned by stdin's _iob entry; the other two are unreferenced, placed in the two
            # unreferenced 0x200-byte holes (5C32, 8C52 or 8C54).
            "__bufin": ("dg", 0x7274), "__bufout": ("dg", 0x5C32), "__buferr": ("dg", 0x8C52),
            "_gfx_show_page": ("img", 0x0268),
        }),
    "CHASE": dict(
        asm=[(0x0000, 0x00C9, "PARA", None), (0x00CA, 0x0576, "WORD", 0x50FE),
             (0x0576, 0x0DFC, "WORD", 0x568C)],
        asm_src=["PROBE", "DRVLOAD", "GFX"],
        text_start=0x0E0C, text_base=0x0DF0,
        runtime=0x568C, dgroup=0x6630, data=(0x42, 0x1EE2), seg0a_data=0x006C,
        const=(0x22C8, 0x22C8), bss=(0x23A2, 0x1AD4), minalloc=None, bss_init=True,
        asm_owns={"SEG0B": (0x1A0A, 0x1B32), "SEG0C": (0x1B36, 0x1EE2)},  # loader, graphics
        data_srcs=[("CONSTW", "ASMDATA/CONSTW.ASM", None, None)],
        common=(0x3E78, 0x2B68),
        runtime_names={0x65CA: "__dos_freemem", 0x6560: "__dos_close"},  # AH=49h, AH=3Eh
        c_objects=[
            ("CHASE", 0x0E0C, 0x14F8, 0x006C, 0x006C, "/Zd", "CHASE"),
            ("DRIVE", 0x14F8, 0x39C0, 0x1818, 0x1818, "", "CHASE"),
            ("CITY", 0x39C0, 0x400C, 0x18CA, 0x18CA, "", "CHASE"),
            # MicroProse C library
            ("TEXTWIN", 0x400C, 0x488C, 0x18CE, 0x1940, "", "MPSLIB"),
            ("UI", 0x488C, 0x4CF8, 0x1940, 0x1974, "/Zd", "MPSLIB"),
            ("DISK", 0x4CF8, 0x4E2A, 0x1974, 0x19F6, "", "MPSLIB"),
            ("STUBS", 0x4E2A, 0x4E2E, 0x19F6, 0x19F6, "", "MPSLIB"),
            ("MOUSE", 0x4E2E, 0x4F76, 0x19F6, 0x19F6, "", "MPSLIB"),
            ("GFX", 0x4F76, 0x50FE, 0x19F6, 0x1A0A, "", "MPSLIB"),
            ("FILEIO", 0x50FE, 0x568C, 0x1B32, 0x1B36, "/Ox", "MPSLIB"),
        ],
        symbols={
            "_gfx_show_page": ("img", 0x01DC),
            "_draw_status_bar": ("img", 0x1292), "_draw_face_parts": ("img", 0x1293),  # empty hooks
            # library globals (_BSS / c_common)
            "_anim": ("dg", 0x23E0), "_anim_x": ("dg", 0x23E8), "_line_start": ("dg", 0x23FE),
            "_text_color": ("dg", 0x243E), "_item_color": ("dg", 0x2440), "_nlines": ("dg", 0x2442),
            "_sel_color": ("dg", 0x2444), "_joy_raw": ("dg", 0x3E82), "_message": ("dg", 0x3E86),
            "_rnd_seed": ("dg", 0x455C), "_options": ("dg", 0x455E), "_show_ok": ("dg", 0x4782),
            "_portrait": ("dg", 0x50CA), "_mouse_regs": ("dg", 0x50CE), "_first_item": ("dg", 0x5BE2),
            "_anim_active": ("dg", 0x5BF2), "_menu_flag": ("dg", 0x5BF4), "_nitems": ("dg", 0x5BF8),
            "_redraw_all": ("dg", 0x5C04), "_box_color": ("dg", 0x5C08), "_max_width": ("dg", 0x5C0C),
            "_bios_regs": ("dg", 0x5C54), "_disabled": ("dg", 0x5C68), "_portrait_x": ("dg", 0x647A),
            "_paused": ("dg", 0x647C), "_mouse_buttons": ("dg", 0x6480), "_mouse_x": ("dg", 0x6482),
            "_mouse_y": ("dg", 0x6484), "_mouse_count": ("dg", 0x6486), "_portrait_y": ("dg", 0x6488),
            "_quit_flag": ("dg", 0x66CE), "_hotkeys": ("dg", 0x66D0), "_default_sel": ("dg", 0x66F0),
            "_box_x2": ("dg", 0x673C), "_box_y2": ("dg", 0x6800),
        }),
    "TAC": dict(
        # OPEN: the original links _dos_freemem's runtime module before _dos_creat's
        # (ours after _dos_write); the image is otherwise identical.
        asm=[(0x0000, 0x00C9, "PARA", None), (0x00CA, 0x0156, "WORD", None),
             (0x0156, 0x0602, "WORD", 0xE0BA), (0x0602, 0x0E88, "WORD", 0xE648)],
        asm_src=["PROBE", "PALETTE", "DRVLOAD", "GFX"],
        text_start=0x0E98, text_base=0x0E80,
        runtime=0xE648, dgroup=0x10E30, data=(0x42, 0x3C8A), seg0a_data=0x6C,
        const=(0x41BE, 0x41BE), bss=(0x4298, 0x4B14), minalloc=None, bss_init=True,
        asm_owns={"SEG0C": (0x37B2, 0x38DA), "SEG0D": (0x38DE, 0x3C8A)},  # loader, graphics
        data_srcs=[("CONSTW", "ASMDATA/CONSTW.ASM", None, None)],
        common=(0x8DCE, 0x46C2),
        c_objects=[
            ("TAC", 0x0E98, 0x158E, 0x006C, 0x006C, "", "TAC"),
            ("BREAKIN", 0x158E, 0x3B90, 0x1C26, 0x1C26, "/Zd", "TAC"),
            ("ACTION", 0x3B90, 0x5364, 0x1CC0, 0x1CC0, "", "TAC"),
            ("ROOM", 0x5364, 0x64F4, 0x1FF0, 0x1FF0, "", "TAC"),
            ("ROOMVIEW", 0x64F4, 0x6B26, 0x2000, 0x2000, "", "TAC"),
            ("GUARD", 0x6B26, 0x8F86, 0x2034, 0x2034, "", "TAC"),
            ("CLUE", 0x8F86, 0xB22A, 0x226C, 0x226C, "", "GAMELIB"),
            ("MSGTEXT", 0xB22A, 0xB7C8, 0x2CEE, 0x2E2C, "", "GAMELIB"),
            ("FACE", 0xB7C8, 0xBD9A, 0x2F0C, 0x2F0C, "", "GAMELIB"),
            ("PERSON", 0xBD9A, 0xC966, 0x2F22, 0x2F22, "", "GAMELIB"),
            ("TEXTWIN", 0xC966, 0xD1E6, 0x3656, 0x3656, "", "MPSLIB"),
            ("UI", 0xD1E6, 0xD652, 0x36C8, 0x36C8, "/Zd", "MPSLIB"),
            ("ENV", 0xD652, 0xDDFC, 0x36FC, 0x36FC, "", "MPSLIB"),
            ("DISK", 0xDDFC, 0xDF2E, 0x371C, 0x371C, "", "MPSLIB"),
            ("STUBS", 0xDF2E, 0xDF32, 0x379E, 0x379E, "", "MPSLIB"),
            ("GFX", 0xDF32, 0xE0BA, 0x379E, 0x379E, "", "MPSLIB"),
            ("FILEIO", 0xE0BA, 0xE648, 0x38DA, 0x38DE, "/Ox", "MPSLIB"),
        ],
        symbols={
            "_gfx_show_page": ("img", 0x0268),   # runtime communals (_buferr unreferenced: placed in a 0x200 hole)
            "__bufout": ("dg", 0x8DCE), "__bufin": ("dg", 0xB952), "__buferr": ("dg", 0x9B76)}),
    "FINAL": dict(
        # identify_leader_faces is the copy protection (pick the leader's face from the
        # manual). The GOG and eXoDOS FINAL.EXE have its `return where == right` JNE
        # patched to NOP NOP, which disables it; the 1990 floppy release has the plain
        # compiler output (build with NO_PATCHES=1 to get that one). No C produces the
        # patch, so the object is patched after compiling: (object, _TEXT offset, old, new).
        patches=[("NEWCHAR", 0x10B0, "7505", "9090")],
        asm=[(0x0000, 0x00C9, "PARA", None), (0x00CA, 0x0156, "WORD", None),
             (0x0156, 0x0602, "WORD", 0xD1A0), (0x0602, 0x1006, "WORD", 0xD72E)],
        asm_src=["PROBE", "PALETTE", "DRVLOAD", "GFX"],
        text_asm={0x1016: "INT24"},     # its _DATA (6C-76) follows SEG0A's
        text_start=0x1016, text_base=0x1000,
        runtime=0xD72E, dgroup=0x10D80, data=(0x42, 0x5682), seg0a_data=0x76,
        far_symbols={"_anim_mem": 0},   # the animation player's far block
        far_data=(0xFB40, 0x10D80),
        runtime_names={0xFA0A: "__dos_freemem"},
        const=(0x5BBC, 0x5BBC),
        asm_owns={"SEG0C": (0x4B5A, 0x4C82), "SEG0D": (0x4C86, 0x5682)},  # loader, graphics
        data_srcs=[("CONSTW", "ASMDATA/CONSTW.ASM", None, "ANIMOBJ"),
                   ("CONSTW2", "ASMDATA/CONSTW.ASM", None, "ANIMOBJ"),
                   ("ANIMVER", "ASMDATA/ANIMVER.ASM", None, None)],
        bss=(0x5C96, 0x1D1E), minalloc=None, bss_init=True,
        common=(0x79D6, 0x39AA),
        c_objects=[
            ("FINAL", 0x1056, 0x167E, 0x0076, 0x0076, "", "FINAL"),
            ("NEWCHAR", 0x167E, 0x275E, 0x16D2, 0x16D2, "", "FINAL"),
            ("ENDCASE", 0x275E, 0x4F4C, 0x2504, 0x2504, "", "FINAL"),
            ("CASE", 0x4F4C, 0x5CAA, 0x3010, 0x3010, "", "FINAL"),
            ("FAME", 0x5CAA, 0x624C, 0x328E, 0x328E, "", "FINAL"),
            ("CLUE", 0x624C, 0x84F0, 0x3326, 0x3326, "", "GAMELIB"),
            ("MSGTEXT", 0x84F0, 0x8A8E, 0x3DA8, 0x3EE6, "", "GAMELIB"),
            ("FACE", 0x8A8E, 0x9060, 0x3FC6, 0x3FC6, "", "GAMELIB"),
            ("PERSON", 0x9060, 0x9C2C, 0x3FDC, 0x3FDC, "", "GAMELIB"),
            ("CHRONO", 0x9C2C, 0x9F74, 0x4710, 0x4710, "", "GAME"),
            ("TEXTWIN", 0x9F74, 0xA7F4, 0x4778, 0x4778, "", "MPSLIB"),
            ("UI", 0xA7F4, 0xAC60, 0x47EA, 0x47EA, "/Zd", "MPSLIB"),
            ("LOADGAME", 0xAC60, 0xB2F6, 0x481E, 0x481E, "", "FINAL"),
            ("ENV", 0xB2F6, 0xBAA0, 0x4A30, 0x4A30, "", "MPSLIB"),
            ("DISK", 0xBAA0, 0xBBD2, 0x4A50, 0x4A50, "", "MPSLIB"),
            # the animation player: two objects, the second (the .PAN loader) starting at
            # pan_open so a record breaks inside decode_sprite as in the original
            ("ANIMOBJ", 0xBBD2, 0xCA76, 0x4AD2, 0x4B46, "", "MPSLIB"),
            ("ANIMPAN", 0xCA76, 0xCED0, 0x4B46, 0x4B46, "", "MPSLIB"),
            ("MOUSE", 0xCED0, 0xD018, 0x4B46, 0x4B46, "", "MPSLIB"),
            ("GFX", 0xD018, 0xD1A0, 0x4B46, 0x4B46, "", "MPSLIB"),
            ("FILEIO", 0xD1A0, 0xD72E, 0x4C82, 0x4C86, "/Ox", "MPSLIB"),
        ],
        symbols={
            "_drv_blit_sprite_var": ("img", 0x01C0), "_anim_set_pal": ("img", 0x00CA),
            "_blit_sprite": ("img", 0x0D40), "_blit_sprite_restore": ("img", 0x0D5E),
            "_present_dirty_rows": ("img", 0x0DF2), "_clear_dirty_rows": ("img", 0x0E51),
            "_gfx_show_page": ("img", 0x0268),
            "__bufout": ("dg", 0x79D6), "__bufin": ("dg", 0x96E0), "__buferr": ("dg", 0xAE7C)}),
    "GAME": dict(
        asm=[(0x0000, 0x00C9, "PARA", None), (0x00CA, 0x0576, "WORD", 0xE492),
             (0x0576, 0x0F7A, "WORD", 0xEA20)],
        asm_src=["PROBE", "DRVLOAD", "GFX"],
        text_asm={0x0F8A: "INT24"},     # its _DATA (6C-76) follows SEG0A's
        text_start=0x0F8A, text_base=0x0F70,
        runtime=0xEA20, dgroup=0x12060, data=(0x42, 0x4E98), seg0a_data=0x76,
        far_symbols={"_anim_mem": 0},   # the animation player's far block
        far_data=(0x10E20, 0x12060),
        const=(0x53D2, 0x53D2),
        asm_owns={"SEG0B": (0x4370, 0x4498), "SEG0C": (0x449C, 0x4E98)},  # loader, graphics
        data_srcs=[("CONSTW", "ASMDATA/CONSTW.ASM", None, "ANIMOBJ"),
                   ("ANIMVER", "ASMDATA/ANIMVER.ASM", None, None),
                   ("CONSTW2", "ASMDATA/CONSTW.ASM", None, None)],
        bss=(0x54AC, 0x1D24), minalloc=None, bss_init=True,
        common=(0x71F2, 0x386E),
        c_objects=[
            ("GAME", 0x0FCA, 0x135C, 0x0076, 0x0076, "", "GAME"),
            ("PERSON", 0x135C, 0x1F28, 0x16E0, 0x16E0, "", "GAMELIB"),
            ("TELETYPE", 0x1F28, 0x2578, 0x1E14, 0x1E14, "", "GAMELIB"),
            ("CITY", 0x2578, 0x431A, 0x206E, 0x206E, "", "GAME"),
            ("TRAVEL", 0x431A, 0x4AE6, 0x26EE, 0x26EE, "", "GAME"),
            ("BRIEFING", 0x4AE6, 0x4F16, 0x27A6, 0x27A6, "", "GAME"),
            ("CLUE", 0x4F16, 0x71BA, 0x2868, 0x2868, "", "GAMELIB"),
            ("SCREENS", 0x71BA, 0x87A4, 0x32EA, 0x32EA, "", "GAME"),
            ("CHRONO", 0x87A4, 0x8AEC, 0x3886, 0x3886, "", "GAME"),
            ("MSGTXTG", 0x8AEC, 0x90A6, 0x38EE, 0x3A2C, "", "GAME"),   # MSGTEXT.C with GAME_MSGTEXT
            ("FACE", 0x90A6, 0x9678, 0x3B0C, 0x3B0C, "", "GAMELIB"),
            ("TIME", 0x9678, 0xA838, 0x3B22, 0x3B22, "", "GAME"),
            ("SUSPECTS", 0xA838, 0xB3AE, 0x3D0E, 0x3D0E, "", "GAME"),
            ("OFFICE", 0xB3AE, 0xBA44, 0x3F8E, 0x3F8E, "", "GAME"),
            ("ENV", 0xBA44, 0xC1EE, 0x41A0, 0x41A0, "", "MPSLIB"),
            ("DISK", 0xC1EE, 0xC320, 0x41C0, 0x41C0, "", "MPSLIB"),
            ("ANIMOBJ", 0xC320, 0xD1C4, 0x4242, 0x42B6, "", "MPSLIB"),   # see FINAL
            ("ANIMPAN", 0xD1C4, 0xD61E, 0x42B6, 0x42B6, "", "MPSLIB"),
            ("TEXTWIN", 0xD61E, 0xDE9E, 0x42B6, 0x42B6, "", "MPSLIB"),
            ("UI", 0xDE9E, 0xE30A, 0x4328, 0x4328, "/Zd", "MPSLIB"),
            ("GFX", 0xE30A, 0xE492, 0x435C, 0x435C, "", "MPSLIB"),
            ("FILEIO", 0xE492, 0xEA20, 0x4498, 0x449C, "/Ox", "MPSLIB"),
        ],
        symbols={
            "_drv_blit_sprite_var": ("img", 0x0134), "_anim_set_pal": ("img", 0x01C2),
            "_lzw_begin": ("img", 0x0A8E),   # GAME's functions.txt calls it pic_begin_decode_b
            "__bufout": ("dg", 0x71F2), "__bufin": ("dg", 0x8EE2), "__buferr": ("dg", 0x789E)}),
}

P = None            # the selected program's config
PROG = None
OUT = None


def configure(prog):
    global P, PROG, OUT
    PROG, P = prog, PROGS[prog]
    OUT = os.path.join(ROOT, "build", prog)


def active_c_objects():
    return [c for c in P["c_objects"] if os.path.exists(os.path.join(ROOT, "src", c[6], c[0] + ".C"))]


def load():
    d = open(os.path.join(ROOT, "unpacked", PROG + ".EXE"), "rb").read()
    nrel, hdrp = struct.unpack_from("<HH", d, 6)
    roff = struct.unpack_from("<H", d, 0x18)[0]
    img = d[hdrp * 16:]
    rel, order = {}, []
    for i in range(nrel):
        o, s = struct.unpack_from("<HH", d, roff + 4 * i)
        lin = s * 16 + o
        rel[lin] = struct.unpack_from("<H", img, lin)[0]
        order.append(lin)
    return img, rel, order


def functions():
    """name -> image offset (first occurrence) from decomp/PROG/functions.txt."""
    out = {}
    ddir = os.path.join(ROOT, "decomp", PROG)
    for fname in ["functions.txt"] + sorted(f for f in os.listdir(ddir)
                                             if f.startswith("functions.") and f != "functions.txt"):
        for line in open(os.path.join(ddir, fname)):
            if not line.strip():
                continue
            addr, name = line.split("\t")[:2]
            seg, off = (int(x, 16) for x in addr.split(":"))
            out.setdefault(name, seg * 16 + off - LOAD_LIN)
    return out


def runtime_names():
    names = {}
    for line in open(os.path.join(ROOT, "tools", "names", PROG + ".lib.txt")):
        m = re.match(r"func lin:([0-9a-f]+) \S+ MSC 5.1 runtime: (\S+)", line)
        if m:
            names[int(m.group(1), 16) - LOAD_LIN] = m.group(2).split("/")[0]
    for line in open(os.path.join(ROOT, "decomp", PROG, "functions.txt")):
        addr, name = line.split("\t")[:2]
        seg, off = (int(x, 16) for x in addr.split(":"))
        lin = seg * 16 + off - LOAD_LIN
        if (lin >= P["runtime"] and lin not in names and not name.startswith("FUN_")
                and not any(lo <= lin < hi for lo, hi, *_ in P["asm"])):
            names[lin] = "_" + name
    names.update(P.get("runtime_names", {}))     # routines the library matcher missed
    return names


def calls():
    out = {}
    path = os.path.join(ROOT, "decomp", PROG, "insns.txt")
    if not os.path.exists(path):        # only needed for raw _TEXT pieces: disassemble them
        raw = [pc for pc in text_pieces() if pc[0] == "raw" and pc[1] not in asm_sources()]
        if raw:
            import capstone
            img = load()[0]
            md = capstone.Cs(capstone.CS_ARCH_X86, capstone.CS_MODE_16)
            for _, _, lo, hi in raw:
                for i in md.disasm(bytes(img[lo:hi]), lo):
                    if i.bytes[0] in (0xE8, 0xE9):      # near CALL / JMP rel16
                        out[i.address] = (i.size, i.mnemonic.upper(), int(i.op_str, 16))
        return out
    for line in open(path):
        lin, ln, mn, tgt, tname = line.rstrip("\n").split("\t")[:5]
        if mn in ("CALL", "JMP") and tgt != "-":
            out[int(lin, 16) - LOAD_LIN] = (int(ln), mn, int(tgt, 16) - LOAD_LIN)
    return out


def c_symbols():
    """(defined, referenced) public names of the compiled C objects in build/PROG."""
    defined, refs = set(), set()
    for c in active_c_objects():
        path = os.path.join(OUT, c[0] + ".OBJ")
        if not os.path.exists(path):
            continue
        for m in omfsig.parse_modules(path):
            defined |= {n for n, _, _ in m.pubs}
            refs |= {n for n in m.extdefs if n}
    return defined, refs


def file_symbols():
    """tools/rebuild/syms/PROG.txt: `name hexoffset` lines (DGROUP data, C names)."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "syms", PROG + ".txt")
    out = {}
    if os.path.exists(path):
        for line in open(path):
            f = line.split("#")[0].split()
            if len(f) == 2:
                out["_" + f[0]] = ("dg", int(f[1], 16))
    return out


RUNTIME_DATA = {"_errno", "_environ", "__psp", "__osmajor", "__osminor", "__doserrno"}


def resolve_symbols():
    """SYMBOLS plus an entry for every C external not defined in C or by the runtime."""
    syms = file_symbols()
    syms.update(P["symbols"])
    defined, refs = c_symbols()
    funcs = functions()
    rt = set(runtime_names().values())
    missing = []
    for n in sorted(refs - defined):
        if n in syms or n in rt or n.startswith("__") or n in RUNTIME_DATA or n in P.get("far_symbols", {}):
            continue
        a = funcs.get(n[1:] if n.startswith("_") else n)
        if a is None:
            missing.append(n)
        elif a < P["runtime"] or any(lo <= a < hi for lo, hi, *_ in P["asm"]):
            syms[n] = ("img", a)
        # else: a runtime function (SLIBCE resolves it)
    if missing:
        print("unresolved C externals (add them to symbols):", " ".join(missing), file=sys.stderr)
    for n in defined:
        syms.pop(n, None)
    return syms


def far_known():
    return set(P.get("far_symbols", {}))


SYMS = {}
XCALL = {}         # image address -> public name, for near calls between objects


def c_publics():
    """image address -> public name for the compiled C objects' _TEXT publics."""
    out = {}
    for c in active_c_objects():
        path = os.path.join(OUT, c[0] + ".OBJ")
        if not os.path.exists(path):
            continue
        for m in omfsig.parse_modules(path):
            for n, si, off in m.pubs:
                if m.segs[si][0] == "_TEXT":
                    out.setdefault(c[1] + off, n)
    return out


def plan_xcalls(cm):
    """Near calls from raw _TEXT to code in another object become CALL fixups to a
    public, so LINK resolves them like the original link did (and a module can come
    from a library). Targets in raw pieces get a label (SYMS) there."""
    cpub = c_publics()
    pieces = [pc for pc in text_pieces() if pc[0] == "raw"]
    used = {n for n, (k, a) in SYMS.items()} | set(cpub.values())
    byaddr = {}
    for n, a in functions().items():
        byaddr.setdefault(a, n)
    for p, c in sorted(cm.items()):
        t = c[2]
        if c[1] != "CALL" or c[0] != 3 or not (P["text_start"] <= t < P["runtime"]):
            continue
        src = next((pc for pc in pieces if pc[2] <= p < pc[3]), None)
        if src is None or src[2] <= t < src[3] or t in XCALL:
            continue
        if t in cpub:
            XCALL[t] = cpub[t]
            continue
        have = [n for n, (k, a) in SYMS.items() if k == "img" and a == t]
        if have:
            XCALL[t] = have[0]
            continue
        n = "_" + byaddr[t] if t in byaddr else f"_fn_{t:04x}"
        if n in used:
            n = f"_fn_{t:04x}"
        used.add(n)
        SYMS[n] = ("img", t)
        XCALL[t] = n


def labels_in(kind, lo, hi):
    """address -> label; names sharing an address (e.g. CODE's `done` is the library's
    `quit_flag`) are joined so they are emitted as consecutive LABEL lines."""
    out = {}
    for n, (k, a) in sorted(SYMS.items()):
        if k == kind and lo <= a < hi:
            out[a] = out[a] + "\tLABEL\tBYTE\n" + n if a in out else n
    return out


def dbs(f, data, start, labels):
    i = 0
    while i < len(data):
        if start + i in labels:
            f.write(f"{labels[start + i]}\tLABEL\tBYTE\n")
        j = i + 1
        while j < len(data) and j - i < 16 and (start + j) not in labels:
            j += 1
        f.write("\tdb\t" + ",".join(f"0{b:02X}h" for b in data[i:j]) + "\n")
        i = j


EXTRNS = set()     # symbols the .ASM file being written refers to (see AsmFile)


class AsmFile:
    """Buffered .ASM output; EXTRN declarations for symbols collected in EXTRNS while
    writing are put at the top (MASM wants them before use)."""
    def __init__(self, path):
        self.path, self.parts = path, []
        EXTRNS.clear()

    def write(self, t):
        self.parts.append(t)

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        body = "".join(self.parts)
        lines = body.split("\n", 1)
        head = "".join(f"\tEXTRN\t{n}:BYTE\n" for n in sorted(EXTRNS))
        with open(self.path, "w") as f:
            f.write(lines[0] + "\n" + head + (lines[1] if len(lines) > 1 else ""))


def emit_range(f, img, rel, lo, hi, labels=None, seg_label="asm0_base", base=0):
    """Emit image bytes [lo, hi) as db/dw with relocation fixups. Label addresses are
    given relative to `base` (0 for image offsets, DGROUP for data)."""
    labels = {a + base: n for a, n in (labels or {}).items()}
    p = lo
    buf, buf_start = bytearray(), p

    def flush():
        nonlocal buf
        if buf:
            dbs(f, bytes(buf), buf_start, labels)
        buf = bytearray()

    while p < hi:
        if p in labels and buf:
            flush()
        if p in rel:
            flush()
            if p in labels:
                f.write(f"{labels[p]}\tLABEL\tBYTE\n")
            v = rel[p]
            if v == P.get("asm_frame", 0):
                f.write(f"\tdw\tSEG {seg_label}\n")
            elif v == P["text_base"] >> 4:
                EXTRNS.add("_main")
                f.write("\tdw\tSEG _main\n")             # SEG _TEXT
            elif P.get("far_data") and v == P["far_data"][0] >> 4:
                EXTRNS.add("fardata_base")
                f.write("\tdw\tSEG fardata_base\n")
            else:
                assert v == P["dgroup"] >> 4, hex(v)
                f.write("\tdw\tDGROUP\n")
            p += 2
            continue
        if not buf:
            buf_start = p
        buf.append(img[p])
        p += 1
    flush()


def publics_decl(labels):
    names = [n.split("\t")[0] for v in labels.values() for n in v.split("\n")]
    return "".join(f"\tPUBLIC\t{n}\n" for n in sorted(names))


def asm_objects():
    """[(name, lo, hi, align, link position)] for the assembly segment's objects."""
    return [(f"SEG0{chr(65 + i)}", lo, hi, al, at) for i, (lo, hi, al, at) in enumerate(P["asm"])]


ASM_DIR = os.path.join(ROOT, "src", "ASM")


DEV_DIR = os.environ.get("ASM_SRC_DIR")     # asmgen.py first passes (while converting)


def asm_source_path(obj, src):
    return os.path.join(DEV_DIR, PROG, obj + ".ASM") if DEV_DIR else os.path.join(ASM_DIR, src + ".ASM")


def asm_sources():
    """{object name: src/ASM source} for the assembly objects and the raw _TEXT pieces
    that are hand-written assembly (`asm_src`, `text_asm`); objects whose source is
    missing are still extracted from the image."""
    out = dict(zip((a[0] for a in asm_objects()), P.get("asm_src", [])))
    for pc in text_pieces():
        if pc[0] == "raw" and pc[2] in P.get("text_asm", {}):
            out[pc[1]] = P["text_asm"][pc[2]]
    return {o: s for o, s in out.items() if os.path.exists(asm_source_path(o, s))}


def asm_data_symbols():
    """tools/rebuild/syms/PROG.asm.txt: `name hexoffset` lines, the DGROUP data the
    assembly sources use (EXTRN) that other objects define, so those get PUBLIC labels."""
    path = (os.path.join(DEV_DIR, PROG, "syms.txt") if DEV_DIR else
            os.path.join(os.path.dirname(os.path.abspath(__file__)), "syms", PROG + ".asm.txt"))
    out = {}
    if os.path.exists(path):
        for line in open(path):
            f = line.split("#")[0].split()
            if len(f) == 2:
                out[f[0]] = ("dg", int(f[1], 16))
    return out


def write_asm_source(obj, src):
    """build/PROG/OBJ.ASM: src/ASM/SRC.ASM with PROG_<name> defined for its conditionals
    (the .INC files it includes are copied next to it)."""
    with open(os.path.join(OUT, obj + ".ASM"), "w") as f:
        f.write(f"PROG_{PROG}\tEQU\t1\t\t; {PROG}.EXE {obj}: src/ASM/{src}.ASM\n")
        f.write(open(asm_source_path(obj, src)).read())
    for inc in os.listdir(ASM_DIR) if os.path.isdir(ASM_DIR) else []:
        if inc.endswith(".INC"):
            with open(os.path.join(OUT, inc), "w") as f:
                f.write(open(os.path.join(ASM_DIR, inc)).read())


def write_asm_segments():
    """The assembly objects (and hand-written raw _TEXT pieces) from src/ASM."""
    srcs = asm_sources()
    for name, *_ in asm_objects():
        assert name in srcs, f"{name}: no src/ASM source (asm_src)"
        write_asm_source(name, srcs[name])


def write_text_obj(name, lo, hi, img, rel, order, cm, rt, first, data=None):
    """Raw _TEXT [lo, hi) as OMF; fixups grouped/ordered like the original (MSC writes
    each FIXUPP record's subrecords in descending offset order). `data` is an optional
    DGROUP range [dlo, dhi) that this object contributes to _DATA."""
    w = ObjWriter(name, "_TEXT", "CODE", align="word")
    w.data = bytearray(img[lo:hi])
    if data and data[1] > data[0]:
        dg = P["dgroup"]
        assert not [r for r in rel if dg + data[0] <= r < dg + data[1]], "relocation in raw data"
        w.ddata = bytes(img[dg + data[0]:dg + data[1]])
        w.dpubs = [(n.split("\t")[0], a - data[0]) for a, v in sorted(labels_in("dg", *data).items())
                   for n in v.split("\n")]
    w.exts = ["__acrtused"]
    w.pubs = [(n, a - lo) for a, v in sorted(labels_in("img", lo, hi).items())
              for n in (x.split("\t")[0] for x in v.split("\n"))]
    if first and not any(n == "_main" for n, _ in w.pubs) and "_main" not in c_symbols()[0]:
        w.pubs.insert(0, ("_main", 0))
    calls_ = []
    for p, c in sorted(cm.items()):
        if not (lo <= p < hi and c[1] == "CALL" and c[0] == 3):
            continue
        if c[2] >= P["runtime"]:
            target = rt[c[2]]
        elif c[2] in XCALL and not (lo <= c[2] < hi):
            target = XCALL[c[2]]            # near call into another object
        else:
            continue
        w.data[p + 1 - lo:p + 3 - lo] = b"\0\0"
        calls_.append((p + 1, target))
    relocs = [r for r in order if lo <= r < hi]
    for r in relocs:                    # LINK adds a segment frame to the stored word
        if reloc_kind(rel[r])[0] != "group":
            w.data[r - lo:r - lo + 2] = b"\0\0"
    groups = []
    for r in relocs:
        if groups and r < groups[-1][-1]:
            groups[-1].append(r)
        else:
            groups.append([r])
    fields = sorted([r for r in relocs] + [c[0] for c in calls_])

    def safe(cut):
        for fs in fields:
            if fs < cut < fs + 2:
                return fs
        return cut

    cuts = [lo]
    for g in sorted(groups, key=min):
        a, b = safe(min(g)), safe(max(g) + 2)
        assert b - a <= 1024
        while a - cuts[-1] > 1024:
            cuts.append(safe(cuts[-1] + 1024))
        if a > cuts[-1]:
            cuts.append(a)
        cuts.append(b)
    while hi - cuts[-1] > 1024:
        cuts.append(safe(cuts[-1] + 1024))
    if cuts[-1] != hi:
        cuts.append(hi)
    pos = {r: i for i, r in enumerate(relocs)}
    records = []
    for a, b in zip(cuts, cuts[1:]):
        fx = [(c[0] - lo, "call", c[1]) for c in calls_ if a <= c[0] < b]
        fx += [(r - lo,) + reloc_kind(rel[r])
               for r in sorted((r for r in relocs if a <= r < b), key=pos.get)]
        records.append((a - lo, b - lo, fx))
    with open(os.path.join(OUT, name + ".OBJ"), "wb") as f:
        f.write(w.build(records))


def reloc_kind(value):
    """Fixup (kind, target) for a relocated word in _TEXT, from its unrelocated value."""
    if value == P.get("asm_frame", 0):
        return "seg", "asm0_base"       # SEG ASM0 (far call into the assembly segment)
    if value == P["text_base"] >> 4:
        return "self", None             # SEG _TEXT
    if P.get("far_data") and value == P["far_data"][0] >> 4:
        return "seg", "fardata_base"    # SEG FAR_DATA (far pointer into the far data)
    assert value == P["dgroup"] >> 4, hex(value)
    return "group", None                # DGROUP


def text_pieces():
    """_TEXT layout: list of ("c", name) and ("raw", name, lo, hi) in address order. Raw
    ranges are also split where an assembly object is linked in between."""
    cuts = sorted({at for *_, at in P["asm"] if at and P["text_start"] < at < P["runtime"]})
    pieces, p, n = [], P["text_start"], 0

    def raw(lo, hi):
        nonlocal n
        for a, b in zip([lo] + [c for c in cuts if lo < c < hi], [c for c in cuts if lo < c < hi] + [hi]):
            n += 1
            pieces.append(("raw", f"TEXT{n}", a, b))
    for name, lo, hi, *_ in sorted(active_c_objects(), key=lambda c: c[1]):
        if p < lo:
            raw(p, lo)
        pieces.append(("c", name, lo, hi))
        p = hi
    if p < P["runtime"]:
        raw(p, P["runtime"])
    return pieces


def far_data_extracted():
    """The far data segment still comes from the image: some far symbol is not defined
    by a C object (ANIMOBJ.C defines anim_mem, a far communal LINK puts there)."""
    if not P.get("far_data"):
        return False
    far = set()
    for c in active_c_objects():
        path = os.path.join(OUT, c[0] + ".OBJ")
        if os.path.exists(path):
            for m in omfsig.parse_modules(path):
                far |= {n for n, kind, _ in m.comdefs if kind == "far"}
    return not set(P.get("far_symbols", {})) <= far


def write_far_data(img, rel):
    """The far data segment (class FAR_DATA, between _TEXT and DGROUP), raw."""
    lo, hi = P["far_data"]
    assert not [r for r in rel if lo <= r < hi], "relocation in far data"
    with open(os.path.join(OUT, "FARDATA.ASM"), "w") as f:
        f.write(f"; {PROG}.EXE far data segment, image {lo:04X}-{hi - 1:04X}, extracted bytes.\n")
        far = P.get("far_symbols", {})
        f.write("FAR_DATA\tSEGMENT PARA PUBLIC 'FAR_DATA'\n\tPUBLIC\tfardata_base\n"
                + "".join(f"\tPUBLIC\t{n}\n" for n in far) + "fardata_base\tLABEL\tBYTE\n")
        dbs(f, bytes(img[lo:hi]), lo, {lo + off: n for n, off in far.items()})
        f.write("FAR_DATA\tENDS\n\tEND\n")


def c_data_size(name):
    """_DATA length of a compiled C object (build/PROG/NAME.OBJ), or None."""
    path = os.path.join(OUT, name + ".OBJ")
    if not os.path.exists(path):
        return None
    for m in omfsig.parse_modules(path):
        for sg in m.segs:
            if sg and sg[0] == "_DATA":
                return sg[2]
    return 0


def data_srcs():
    """Hand-written MASM data objects: [(name, source, (dlo, dhi) or None, linked before)]."""
    return P.get("data_srcs", [])


def data_plan():
    """Walk the C objects in link (= address) order, with the hand-written data objects
    (data_srcs) at their DGROUP ranges. Returns ({object name: gap object name},
    {gap name: (lo, hi)}, end of the last object's data). Data between two objects'
    _DATA that no source covers yet goes into a data-only object extracted from the image,
    linked just before the second one. A C object's data range is its configured start
    plus the compiled _DATA length (word aligned)."""
    items = []
    for name, lo, hi, dlo, dhi, *_ in sorted(active_c_objects(), key=lambda c: c[1]):
        size = c_data_size(name)
        if size is None:
            size = dhi - dlo
        items.append((dlo, dlo + size + (size & 1), name))
    for name, _, rng, _ in data_srcs():
        if rng:
            items.append((rng[0], rng[1], name))
    for name, rng in P.get("asm_owns", {}).items():   # assembly objects' own _DATA
        items.append((rng[0], rng[1], name))
    before, gaps, cursor, n = {}, {}, P["seg0a_data"], 0
    for dlo, dhi, name in sorted(items, key=lambda t: t[0]):   # stable: C order kept
        if dlo > cursor:
            n += 1
            before[name] = f"DAT{n}"
            gaps[f"DAT{n}"] = (cursor, dlo)
        assert dlo >= cursor, f"{name}: data starts at {dlo:04X}, before {cursor:04X}"
        cursor = dhi
    return before, gaps, cursor


def link_order():
    order = full_order()
    if P.get("lib_from") and not LIB_PROBE_OFF:
        i = order.index(P["lib_from"])
        order = order[:i]
    return "+".join(order)


LIB_PROBE_OFF = False


def lib_objects():
    """Objects that go into MPS.LIB (from `lib_from` on, in link order)."""
    if not P.get("lib_from"):
        return []
    order = full_order()
    return order[order.index(P["lib_from"]):]


def full_order():
    order = []
    asm = asm_objects()
    before, _, _ = data_plan()
    for pc in text_pieces():
        order += [a[0] for a in asm if a[4] is not None and a[4] == pc[2]]
        if pc[1] in before:
            order.append(before[pc[1]])
        order.append(pc[1])
    order = [a[0] for a in asm if a[4] is None] + order
    order += [a[0] for a in asm if a[4] is not None and a[4] >= P["runtime"]]
    for name, _, _, at in data_srcs():     # hand-written data objects (and their gaps)
        objs = ([before[name]] if name in before else []) + [name]
        i = order.index(at) if at else len(order)
        order[i:i] = objs
    return order + (["FARDATA"] if far_data_extracted() else []) + ["DATA"]


def main():
    global SYMS
    ap = argparse.ArgumentParser()
    ap.add_argument("prog")
    ap.add_argument("--link-order", action="store_true")
    ap.add_argument("--cl-commands", action="store_true")
    ap.add_argument("--sources", action="store_true")
    ap.add_argument("--minalloc", action="store_true")
    ap.add_argument("--asm-files", action="store_true")
    ap.add_argument("--libs", action="store_true")
    ap.add_argument("--lib-objects", action="store_true")
    ap.add_argument("--patches", action="store_true")
    ap.add_argument("--exepack", action="store_true")
    a = ap.parse_args()
    configure(a.prog.upper())
    if a.link_order:
        print(link_order())
        return
    if a.sources:
        for d in sorted({c[6] for c in active_c_objects()}):
            print(os.path.join("src", d))
        return
    if a.asm_files:
        print(" ".join([a_[0] for a_ in asm_objects()]
                       + [n for n in asm_sources() if n.startswith("TEXT")]
                       + (["FARDATA"] if far_data_extracted() else [])
                       + list(data_plan()[1])
                       + [d[0] for d in data_srcs()]))
        return
    if a.libs:
        print(("MPS+" if P.get("lib_from") else "") + P.get("libs", "SLIBCE"))
        return
    if a.patches:
        for obj, off, old, new in P.get("patches", []):
            print(f"{obj}.OBJ {off:X} {old} {new}")
        return
    if a.lib_objects:
        print(" ".join(lib_objects()))
        return
    if a.exepack:
        print("/EXEPACK" if P.get("exepack", True) else "")
        return
    if a.minalloc:
        print(P["minalloc"] or "")
        return
    if a.cl_commands:
        for c in active_c_objects():
            opt = "" if "/O" in c[5] else "/Oas "   # a module's own /O flag replaces /Oas
            print(f"CL /c /AS /Gs {opt}/Zl {c[5]} {c[0]}.C".replace("  ", " "))
        return
    _, gaps0, data_lo0 = data_plan()
    if (far_data_extracted() or gaps0 or data_lo0 < P["data"][1] or P["const"][1] > P["const"][0]
            or any(pc[0] == "raw" and pc[1] not in asm_sources() for pc in text_pieces())):
        img, rel, order = load()        # something is still extracted from the image
    else:
        img, rel, order = b"", {}, []   # everything comes from source
    rt = runtime_names()
    cm = calls()
    os.makedirs(OUT, exist_ok=True)
    SYMS = resolve_symbols()
    SYMS.update(asm_data_symbols())
    plan_xcalls(cm)
    cobjs = active_c_objects()
    data_start, data_end = P["data"]
    # _DATA ownership: SEG0A [start, seg0a_data), C objects their ranges, data-only
    # objects the gaps between them, DATA.ASM the rest (see data_plan).
    write_asm_segments()
    if far_data_extracted():
        write_far_data(img, rel)
    for pc in text_pieces():
        if pc[0] == "raw" and pc[1] in asm_sources():
            write_asm_source(pc[1], asm_sources()[pc[1]])
        elif pc[0] == "raw":
            write_text_obj(pc[1], pc[2], pc[3], img, rel, order, cm, rt,
                           first=(pc[2] == P["text_start"]))
    for name, src, _, _ in data_srcs():      # hand-written data objects: copied (CRLF)
        text = open(os.path.join(ROOT, "src", src)).read().replace("\r\n", "\n")
        with open(os.path.join(OUT, name + ".ASM"), "w", newline="\r\n") as f:
            f.write(text)
    before, gaps, data_lo = data_plan()
    extracted = sum(hi - lo for lo, hi in gaps.values()) + (P["const"][1] - P["const"][0])
    assert not set(gaps) & {before.get(a[0]) for a in asm_objects()}, "gap before an assembly object"
    for gname, (lo, hi) in gaps.items():    # data-only objects (MASM: may hold relocations)
        dlab = labels_in("dg", lo, hi)
        with AsmFile(os.path.join(OUT, gname + ".ASM")) as f:
            f.write(f"; {PROG}.EXE data between C objects, DGROUP {lo:04X}-{hi - 1:04X}, extracted bytes.\n")
            f.write("DGROUP\tGROUP\t_DATA\n\tASSUME\tDS:DGROUP\n_DATA\tSEGMENT WORD PUBLIC 'DATA'\n")
            f.write(publics_decl(dlab))
            emit_range(f, img, rel, P["dgroup"] + lo, P["dgroup"] + hi, dlab, base=P["dgroup"])
            f.write("_DATA\tENDS\n\tEND\n")

    extracted += data_end - data_lo
    if extracted or far_data_extracted():
        print(f"program data still extracted from the image: {extracted:#x} bytes"
              + (", far data" if far_data_extracted() else ""), file=sys.stderr)
    bss_start, bss_size = P["bss"]
    com_start, com_size = P["common"]
    dg = P["dgroup"]
    dlab = labels_in("dg", data_lo, data_end)
    blab = labels_in("dg", bss_start, bss_start + bss_size)
    clab = labels_in("dg", com_start, com_start + com_size)
    with AsmFile(os.path.join(OUT, "DATA.ASM")) as f:
        f.write(f"; {PROG}.EXE program data in DGROUP: _BSS and c_common (sizes and labels only).\n")
        f.write(f"; Layout (DGROUP offsets): NULL 0000 | _DATA program {data_start:04X}-{data_end - 1:04X},"
                f" runtime {data_end:04X} |\n")
        f.write(f";   CONST {P['const'][0]:04X} | HDR/MSG/PAD | EPAD (a word) | _BSS {bss_start:04X}"
                f" (program {bss_size:#x} bytes) | XOB/XO/XOE | c_common {com_start:04X}"
                f"-{com_start + com_size - 1:04X} | STACK\n")
        f.write("DGROUP\tGROUP\t_DATA, CONST, _BSS, HDR, MSG, PAD, EPAD, XOB, XO, XOE, c_common"
                + (", COMMON2" if P.get("common2") else "") + "\n")
        f.write("\tASSUME\tDS:DGROUP\n")
        f.write("_DATA\tSEGMENT WORD PUBLIC 'DATA'\n" + publics_decl(dlab))
        emit_range(f, img, rel, dg + data_lo, dg + data_end, dlab, base=dg)
        clo = P["const"][0]
        klab = labels_in("dg", clo, P["const"][1])
        f.write("_DATA\tENDS\nCONST\tSEGMENT WORD PUBLIC 'CONST'\n" + publics_decl(klab))
        emit_range(f, img, rel, dg + clo, dg + P["const"][1], klab, base=dg)
        f.write("CONST\tENDS\n")

        def bss_block(seg, start, size, labs, fill="?"):
            f.write(f"{seg}\tSEGMENT WORD PUBLIC 'BSS'\n" + publics_decl(labs))
            p = start
            for addr, nm in sorted(labs.items()):
                if addr > p:
                    f.write(f"\tdb\t{addr - p} dup ({fill})\n")
                f.write(f"{nm}\tLABEL\tBYTE\n")
                p = addr
            if start + size > p:
                f.write(f"\tdb\t{start + size - p} dup ({fill})\n")
            f.write(f"{seg}\tENDS\n")
        bss_block("_BSS", bss_start, bss_size, blab, "0" if P.get("bss_init") else "?")
        f.write("HDR\tSEGMENT BYTE PUBLIC 'MSG'\nHDR\tENDS\nMSG\tSEGMENT BYTE PUBLIC 'MSG'\nMSG\tENDS\n")
        f.write("PAD\tSEGMENT BYTE COMMON 'MSG'\nPAD\tENDS\n")
        f.write("EPAD\tSEGMENT BYTE COMMON 'MSG'\n" + (f"\t{P['epad']}\n" if P.get("epad") else "")
                + "EPAD\tENDS\n")
        # XOB/XO/XOE declared (empty) first so c_common follows them, as in the original.
        for s_ in ("XOB", "XO", "XOE"):
            f.write(f"{s_}\tSEGMENT WORD PUBLIC 'BSS'\n{s_}\tENDS\n")
        # lowercase (DATA.ASM is assembled with /Ml) so it is LINK's communal segment
        bss_block("c_common", com_start, com_size, clab)
        if P.get("common2"):
            c2, n2 = P["common2"]
            bss_block("COMMON2", c2, n2, labels_in("dg", c2, c2 + n2))
        f.write("\tEND\n")
    print(f"link order: {link_order()}" + (f"  library: {' '.join(lib_objects())}" if P.get("lib_from") else ""))


if __name__ == "__main__":
    main()
