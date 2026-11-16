/* GFX.C - MicroProse library: drawing wrappers, video modes, random numbers. */
#include "mps.h"

RastPort screen_rp = { 0, 0, 0, 319, 199, 1, 15, 4, 0 };
RastPort *g_gfx = &screen_rp;

draw_line(x1, y1, x2, y2, color)
int x1, y1, x2, y2, color;
{
    gfx_line(g_gfx, x1, y1, x2, y2, color);
}

draw_text(s, x, y, color)
char *s;
int x, y, color;
{
    g_gfx->textcolor = color;
    drv_draw_text(g_gfx, x, y, s);
}

draw_text_transparent(s, x, y, color)
char *s;
int x, y, color;
{
    g_gfx->textbg = 0;
    draw_text(s, x, y, color);
    g_gfx->textbg = 1;
}

wait_retrace(n)
int n;
{
    int i;

    if (n)
    while (n--) {
        while (!(inp(0x3DA) & 8))
            ;
        while (inp(0x3DA) & 8)
            ;
    }
}

save_screen()
{
    drv_copy_rect(0, 0, 0, 2, 0, 0, 319, 199);
}

restore_screen()
{
    drv_copy_rect(2, 0, 0, 0, 0, 0, 319, 199);
}

fill_rect_xy(x1, y1, x2, y2, color)
int x1, y1, x2, y2, color;
{
    gfx_fill_rect(g_gfx, x1, y1, x2 - x1 + 1, y2 - y1 + 1, color);
}

set_graphics_mode()
{
    bios_regs.h.ah = 0;
    bios_regs.h.al = 0x0D;
    int86(0x10, &bios_regs, &bios_regs);
}

set_text_mode()
{
    bios_regs.h.ah = 0;
    bios_regs.h.al = 3;
    int86(0x10, &bios_regs, &bios_regs);
}

randomize()
{
    rnd_seed = (unsigned)time(0) & 0x7FFF;
    srand(rnd_seed);
}

random(n)
int n;
{
    return (int)((long)rand() * n >> 15);
}

clamp(v, lo, hi)
int v, lo, hi;
{
    if (v < lo) v = lo;
    if (v > hi) v = hi;
    return v;
}
