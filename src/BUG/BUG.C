/* BUG.C - Covert Action electronics puzzle (BUG.EXE): entry point and program hooks.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "bug.h"
#include "gamelib.h"

/* Initialized data, held by MSC until the end of main: after main's strings, before
 * BOARD's. The game library's tables and pages, then the color maps. */
int dir_dx[8] = { 0, 1, 1, 1, 0, -1, -1, -1 };     /* 0092 */
int dir_dy[8] = { -1, -1, 0, 1, 1, 1, 0, -1 };     /* 00A2 */
int logic[12][4][2] = {                           /* 00B2 chip truth tables: [chip][right*2 + left][output 0 left, 1 right] */
    { { 0, 0 }, { 1, 0 }, { 1, 0 }, { 1, 0 } },   /*  0: OR, out on the left */
    { { 0, 0 }, { 0, 1 }, { 0, 1 }, { 0, 1 } },   /*  1: OR, out on the right */
    { { 0, 0 }, { 1, 1 }, { 0, 0 }, { 1, 1 } },   /*  2: split the left input */
    { { 0, 0 }, { 0, 0 }, { 1, 1 }, { 1, 1 } },   /*  3: split the right input */
    { { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } },   /*  4: straight through */
    { { 0, 0 }, { 0, 1 }, { 1, 0 }, { 1, 1 } },   /*  5: crossover */
    { { 1, 0 }, { 0, 0 }, { 1, 1 }, { 0, 1 } },   /*  6: straight, left inverted */
    { { 0, 1 }, { 1, 1 }, { 0, 0 }, { 1, 0 } },   /*  7: straight, right inverted */
    { { 1, 1 }, { 0, 1 }, { 1, 0 }, { 0, 0 } },   /*  8: straight, both inverted */
    { { 0, 1 }, { 0, 0 }, { 1, 1 }, { 1, 0 } },   /*  9: crossover, left input inverted */
    { { 1, 0 }, { 1, 1 }, { 0, 0 }, { 0, 1 } },   /* 10: crossover, right input inverted */
    { { 1, 1 }, { 1, 0 }, { 0, 1 }, { 0, 0 } },   /* 11: crossover, both inverted */
};
struct Person persons[64] = { 0 };                 /* 0172 */
struct Site sites[256] = { 0 };                    /* 0572 */
struct Clue clues[80] = { 0 };                     /* 1172 */
int jailbreak_person = -1;                         /* 1532 */
RastPort work_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *work_page = &work_rp;                    /* 1546 */
RastPort back_rp = { 1, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *back_page = &back_rp;                    /* 155A */
char spare_colormaps[2][16] = {                   /* 155C not referenced by BUG */
    { 0, 0, 0x01, 0, 0x02, 0, 0, 0x02, 0, 0x01, 0x03, 0x01, 0x02, 0x01, 0, 0x03 },
    { 0, 0x01, 0x11, 0x11, 0x02, 0, 0x02, 0x03, 0x30, 0x11, 0x13, 0x31, 0x22, 0x23, 0x33, 0x33 },
};
char std_colormap[16] = { 0, 0, 0x01, 0, 0x02, 0, 0, 0x02, 0, 0x01, 0x02, 0x03, 0x02, 0x01, 0x01, 0x03 };
char std_colormap2[16] = { 0, 0, 0x11, 0x11, 0x22, 0, 0, 0x22, 0, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };
char colormap[64] = {                             /* 159C */
    0, 0, 0x11, 0x11, 0x22, 0x22, 0x22, 0x22, 0, 0x22, 0x33, 0x33, 0, 0, 0x11, 0x33,
    0, 0x22, 0, 0, 0, 0, 0, 0, 0, 0x22, 0x22, 0, 0, 0, 0x11, 0x33,
    0, 0x12, 0x11, 0x10, 0x11, 0, 0x12, 0x33, 0x22, 0x13, 0x33, 0x11, 0x33, 0x22, 0x33, 0x33,
    0, 0x12, 0, 0, 0x22, 0, 0, 0x13, 0x02, 0x11, 0, 0, 0, 0, 0x33, 0x33,
};
char tele_colors[32] = { 0, 0x11, 0x11, 0x11, 0x22, 0, 0x22, 0x12, 0, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33,
    0, 0x11, 0x11, 0x11, 0x22, 0, 0x22, 0x12, 0, 0x11, 0x11, 0x33, 0x33, 0x22, 0x33, 0x33 };
char face_colormap[16] = { 0, 0x11, 0x11, 0x01, 0x22, 0, 0x22, 0x22, 0, 0x11, 0x11, 0x33, 0x33, 0x33, 0x33, 0x33 };
char terminal_colormap[16] = { 0, 0, 0x11, 0x11, 0x22, 0, 0, 0x11, 0x22, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33 };   /* not referenced by BUG */
char tac_colormap[32] = { 0, 0, 0x11, 0x11, 0x22, 0, 0, 0x22, 0, 0x22, 0x33, 0x33, 0x22, 0x11, 0x22, 0x33,   /* not referenced by BUG */
    0, 0, 0x11, 0x11, 0x22, 0, 0, 0x33, 0x22, 0x22, 0x11, 0x33, 0x22, 0x33, 0x22, 0x33 };
int cur_disk = 2;                                  /* 163C */
RastPort chip_rp = { 2, 0, 0, 319, 199, 0, 15, 4, 0 };
RastPort *chip_page = &chip_rp;                    /* 1650 */
int difficulty = 1;                                /* 1652 */

main()
{
    bug_running = 1;
    load_env("env.sve");
    orig_difficulty = difficulty;
    difficulty = clamp(difficulty - ((*(int far *)(ENV + 0x4E) >> 6) & 3) + 1, 0, 3);
    /* time limit: 10 minutes minus one per 5 alert points, 2 to 10 */
    time_limit = clamp(10 - *(int far *)(ENV + 0x48) / 5, 2, 10) * 60;
    if (ENV[0] == 12) {                 /* car tracer: half the time */
        car_tracer = 1;
        time_limit /= 2;
    }
    ENV[0] = 0xFF;
    link_driver_stubs(*(int far *)(ENV + 0x60));
    link_driver_stubs(*(int far *)(ENV + 0x62));
    link_driver_stubs(*(int far *)(ENV + 0x64));
    g_gfx->font = 1;
    g_gfx->fillcolor = 15;
    drv_set_color_map(colormap, colormap);
    drv_begin_image_grab();
    load_picture_swapped("camera.pic", 2);
    camera_img = drv_get_image(2, 0, 0, 146, 102);
    camera_img2 = drv_get_image(2, 200, 0, 72, 61);
    drv_end_image_grab();
    load_bug_sprites();
    drv_set_color_map(colormap, colormap);
    load_picture_swapped("board.pic", 0);
    randomize();
    build_board();
    flush_input();
    do
        bug_frame();
    while (!quit_flag);
    ENV[8] = progress * 5;
    ENV[9] = alarms;
    ENV[0] = (options & 0x20) ? 0x11 : 0;
    save_env("env.sve");
    play_sound(0);
    set_exit_state();
    play_tune(4);
    require_disk((options & 0x20) ? 1 : 2, 1L);
}

set_exit_state()
{
}

play_sound(n)
int n;
{
    if (options & 4) drv_play_sound(n);
}

bios_set_page(page)
int page;
{
    bios_regs.h.ah = 5; bios_regs.h.al = page;
    int86(0x10, &bios_regs, &bios_regs);
}

/* INT 10h AX=1010h: set one DAC register (palette entries 8-15 are DAC 16-23). */
bios_set_border(color, red, green, blue)
int color, red, green, blue;
{
    union {
        struct { unsigned ax, bx, cx, dx; } x;
        struct { unsigned char al, ah, bl, bh, cl, ch, dl, dh; } h;
        int pad[7];
    } regs;

    if (color > 7) color += 8;
    regs.h.ah = 0x10;
    regs.h.al = 0x10;
    regs.x.bx = color;
    regs.h.dh = red;
    regs.h.ch = green;
    regs.h.cl = blue;
    int86(0x10, &regs, &regs);
}

stub0()                             /* unreferenced, as in CODE */
{
}

show_menu_top(s)                    /* text window at the top left */
char *s;
{
    text_window(s, 0, 0);
}

draw_status_bar()
{
}
