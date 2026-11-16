/* MOUSE.C - MicroProse library: INT 33h mouse driver calls (unused by Covert Action). */
#include "mps.h"

union MREGS { struct { int ax, bx, cx, dx; } x; };
extern union MREGS mouse_regs;
extern int mouse_buttons, mouse_x, mouse_y, mouse_count;

mouse_reset()
{
    mouse_regs.x.ax = 0;
    int86(0x33, &mouse_regs, &mouse_regs);
}

mouse_show()
{
    mouse_regs.x.ax = 1;
    int86(0x33, &mouse_regs, &mouse_regs);
}

mouse_hide()
{
    mouse_regs.x.ax = 2;
    int86(0x33, &mouse_regs, &mouse_regs);
}

mouse_get_status()
{
    mouse_regs.x.ax = 3;
    int86(0x33, &mouse_regs, &mouse_regs);
    mouse_buttons = mouse_regs.x.bx;
    mouse_x = mouse_regs.x.cx;
    mouse_y = mouse_regs.x.dx;
}

mouse_set_pos(x, y)
int x, y;
{
    mouse_regs.x.ax = 4;
    mouse_regs.x.cx = x;
    mouse_regs.x.dx = y;
    int86(0x33, &mouse_regs, &mouse_regs);
}

mouse_press_info(button)
int button;
{
    mouse_regs.x.ax = 5;
    mouse_regs.x.bx = button;
    int86(0x33, &mouse_regs, &mouse_regs);
    mouse_buttons = mouse_regs.x.ax;
    mouse_count = mouse_regs.x.bx;
    mouse_x = mouse_regs.x.cx;
    mouse_y = mouse_regs.x.dx;
}

mouse_release_info(button)
int button;
{
    mouse_regs.x.ax = 6;
    mouse_regs.x.bx = button;
    int86(0x33, &mouse_regs, &mouse_regs);
    mouse_buttons = mouse_regs.x.ax;
    mouse_count = mouse_regs.x.bx;
    mouse_x = mouse_regs.x.cx;
    mouse_y = mouse_regs.x.dx;
}

mouse_set_range(xmin, ymin, xmax, ymax)
int xmin, ymin, xmax, ymax;
{
    mouse_regs.x.ax = 7;
    mouse_regs.x.cx = xmin;
    mouse_regs.x.dx = xmax;
    int86(0x33, &mouse_regs, &mouse_regs);
    mouse_regs.x.ax = 8;
    mouse_regs.x.cx = ymin;
    mouse_regs.x.dx = ymax;
    int86(0x33, &mouse_regs, &mouse_regs);
}
