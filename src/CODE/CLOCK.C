/* CLOCK.C - workstation clock (CODE.EXE). A separate object in the original link:
 * it was compiled without line numbers (/Zd), unlike CODE.C. */
#include "code.h"

char clock_str[] = "00:00:00";

draw_clock()
{
    int s, mins, hold;

    elapsed += ticks / 60;
    ticks %= 60;
    g_gfx->font = 2;
    mins = elapsed / 60;
    clock_str[0] = mins / 10 + '0';
    clock_str[1] = mins % 10 + '0';
    s = elapsed % 60;
    clock_str[3] = s / 10 + '0';
    clock_str[4] = s % 10 + '0';
    clock_str[6] = ticks / 10 + '0';
    clock_str[7] = ticks % 10 + '0';
    g_gfx->fillcolor = 10;
    draw_text(clock_str, 256, 1, 2);
}
