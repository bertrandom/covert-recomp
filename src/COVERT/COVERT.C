/* COVERT.C - Covert Action launcher (COVERT.EXE).
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas.
 *
 * Runs INTRO.EXE (hardware menu), loads the graphics driver, MISC.EXE and the
 * sound driver as overlays, then runs the game programs in turn: each one leaves
 * the number of the next in ENV[0] (-1: quit). */
typedef struct RastPort {          /* as in MPSLIB's MPS.H */
    int page, x0, y0, x1, y1, textbg, textcolor, fillcolor, font;
} RastPort;

/* Shared game state, published at 0000:04F0 for the child programs. */
#define ENV (*(char far * far *)0x4F0L)
#define BIOS_KBD_FLAGS (*(unsigned char far *)0x00400017L)

/* Assembly segment (far) */
extern int  far load_overlay();
extern void far link_driver_stubs();
extern void far drv_slot36();
extern int  far drv_alloc_page();
extern void far drv_set_page();
extern void far drv_sound100();
extern void far drv_sound102();

/* MS C runtime */
extern int spawnl(), spawnlp(), int86();

extern char env_block[];   /* the shared state block */
extern union { struct { unsigned char al, ah; } h; int pad[7]; } video_regs;

RastPort screen_rp = { 0, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *g_gfx = &screen_rp;

/* program run for each ENV[0] value */
char *programs[] = {
    "game.exe", "tac.exe", "code.exe", "chase.exe", "bug.exe", "chase.exe",
    "chase.exe", "tac.exe", "tac.exe", "final.exe", "tac.exe", "final.exe",
    "bug.exe", "tac.exe", "chase.exe", "code.exe", "bug.exe", "final.exe"
};

char graphic_name[] = "?graphic.exe";   /* ? = driver letter chosen in INTRO */
char sound_name[] = "?sound.ca";
int  page_handle = 0;

main()
{
    int nmax, i, fd;                /* fd: unused (names fix the frame layout) */
    char next;

    ENV = env_block;
    spawnl(0, "intro.exe", "", 0L);
    graphic_name[0] = ENV[2];
    sound_name[0] = ENV[3];
    *(int far *)(ENV + 0x60) = load_overlay(graphic_name, "fonts.cv");
    *(int far *)(ENV + 0x62) = load_overlay("misc.exe", 0);
    *(int far *)(ENV + 0x64) = load_overlay(sound_name, 0);
    link_driver_stubs(*(int far *)(ENV + 0x60));
    link_driver_stubs(*(int far *)(ENV + 0x62));
    link_driver_stubs(*(int far *)(ENV + 0x64));
    drv_slot36(0);
    nmax = 3;
    for (i = 0; i < nmax; i++) {
        page_handle = drv_alloc_page(i);
        drv_set_page(i, page_handle);
    }
    drv_sound100();
    ENV[0] = 11;                    /* start with FINAL.EXE (title, main menu) */
    ENV[1] = 0;
    do {
        BIOS_KBD_FLAGS &= ~0x20;    /* Num Lock off */
        if ((next = ENV[0]) == 'c')
            spawnlp(0, "mcv.exe", "cv", "/2", programs[next], 0L);
        else
            spawnl(0, programs[ENV[0]], "", 0L);
    } while (ENV[0] != -1);
    drv_sound102();
    video_regs.h.ah = 0;
    video_regs.h.al = 3;
    int86(0x10, &video_regs, &video_regs);
}
