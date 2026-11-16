/* INTRO.C - Covert Action hardware selection menu (INTRO.EXE).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas.
 *
 * Run by COVERT.EXE first: loads MISC.EXE, shows the title box, then asks for
 * the graphics mode (ENV[2] = driver letter), the sound driver (ENV[3]) and
 * the controls (ENV[4]: 1 = joystick and keyboard). */

/* Shared game state, published at 0000:04F0 by COVERT.EXE. */
#define ENV (*(char far * far *)0x4F0L)

/* Assembly segment (far) */
extern int  far load_overlay();
extern void far link_driver_stubs();
extern unsigned char far drv_misc2();      /* wait for a key */

/* Helpers in _TEXT (assembly) */
extern void do_interrupt(), set_cursor(), print_at(), dos_newline();
extern void int_to_str(), str_cat();

extern union { struct { int ax; } x; int pad[7]; } regs;
extern char snd_sel[];      /* menu number -> sound driver letter */
extern char snd_extra[];
extern char gfx_sel[];      /* menu number -> graphics driver letter */

char *gfx_names[] = {
    ") VGA (256 color)", ") MCGA (256 color)", ") EGA (16 color)",
    ") Tandy 1000 (16 color)", ") CGA (4 color)"
};
char *snd_names[] = {
    ") Shhh! No sounds please", ") IBM sounds", ") Tandy sounds",
    ") AdLib sound board", ") Roland MT-32 MIDI board", ") Custom sound driver"
};
char snd_letters[12] = "NITARX";
char gfx_letters[] = "EMETC";
char *gfx_files[] = {
    "Egraphic.exe", "Mgraphic.exe", "Egraphic.exe", "Tgraphic.exe", "Cgraphic.exe"
};
char *blank_line = "                                                                               \r\n$";
char *box_side = " \272                                                                            \272 ";

main()
{
    /* MSC 5.1 lays out locals by a name hash (mschash.py): the names and the
     * unused ones (total, rg, size, drvname, save) reproduce the original frame. */
    char entry[58];             /* menu line: number + name */
    char title[50];
    char waiting;
    long total;
    char sound;                 /* ask for the sound driver (always) */
    int rg[7];
    unsigned char key;
    unsigned char i;
    int ypos;
    long size;
    char drvname[20];
    int ndrivers;               /* set, never used */
    unsigned n;                 /* menu number */
    int save;

    link_driver_stubs(load_overlay("misc.exe", 0));
    regs.x.ax = 3;
    do_interrupt(0x10, &regs, &regs);
    print_at(0, 0, "\377O");
    print_at(1, 0, " \311\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\273 ");
    print_at(2, 0, box_side);
    print_at(3, 0, " \272                    Covert Action (TM) - Version 447.01                     \272 ");
    print_at(4, 0, box_side);
    print_at(5, 0, " \272                    From those sneaky guys at MPS Labs.                     \272 ");
    print_at(6, 0, box_side);
    print_at(7, 0, " \272    Program & Audio-visual Copyright (C) 1990 by MicroProse Software,Inc.,  \272 ");
    print_at(8, 0, " \272                            All Rights Reserved.                            \272 ");
    print_at(9, 0, box_side);
    print_at(10, 0, " \310\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\315\274 ");
    title[0] = 1;
    sound = 1;
    set_cursor(13, 0);
    for (i = 1; i <= 10; i++)
        dos_newline(blank_line);
    set_cursor(11, 0);
    dos_newline(blank_line);
    dos_newline(blank_line);
    print_at(13, 0, "\377\016                           Select graphics mode:                              ");
    dos_newline(blank_line);
    n = 1;
    for (i = 0; i < 5; i++) {
        int_to_str(n, entry, 10);
        gfx_sel[n] = gfx_letters[i];
        str_cat(entry, gfx_names[i]);
        print_at(n++ + 14, 27, entry);
    }
    waiting = 1;
    do {
        set_cursor(13, 49);
        key = drv_misc2();
        if (key >= '1' && key < n + '0') {
            ENV[2] = gfx_sel[key - '0'];
            if (ENV[2] == 'H')
                ENV[2] = 'C';
            if (ENV[2] == 'V')
                ENV[2] = 'M';
            waiting = 0;
        }
    } while (waiting);
    if (sound == 1) {
        set_cursor(12, 0);
        for (i = 1; i <= 12; i++)
            dos_newline(blank_line);
        print_at(12, 0, "\377\016                              Select sound mode:                              ");
        n = 1;
        ypos = 1;
        ndrivers = 7;
        for (i = 0; i < 6; i++) {
            int_to_str(n, entry, 10);
            snd_sel[n] = snd_letters[i];
            if (i >= 7) {               /* never (6 drivers) */
                snd_names[i][15] = snd_extra[i];
                snd_sel[n] = snd_extra[i];
            }
            str_cat(entry, snd_names[i]);
            print_at(ypos++ + 13, 27, entry);
            n++;
        }
        waiting = 1;
        do {
            set_cursor(13, 50);
            key = drv_misc2();
            if (key >= '1' && key < n + '0') {
                ENV[3] = snd_sel[key - '0'];
                waiting = 0;
            }
        } while (waiting);
    }
    set_cursor(12, 0);
    for (i = 1; i <= 12; i++)
        dos_newline(blank_line);
    print_at(13, 27, "1. Joystick and Keyboard");
    print_at(14, 27, "2. Keyboard only");
    waiting = 1;
    do {
        set_cursor(13, 50);
        key = drv_misc2();
        if (key >= '1' && key <= '2') {
            ENV[4] = key == '1';
            waiting = 0;
        }
    } while (waiting);
    set_cursor(12, 0);
    for (i = 1; i <= 12; i++)
        dos_newline(blank_line);
    print_at(13, 0, "\377\016");
    print_at(16, 29, "One Moment Please...");
}
