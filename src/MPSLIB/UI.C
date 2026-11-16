/* UI.C - MicroProse library: boxes, scene background, keyboard and joystick input. */
#include "mps.h"

extern int anim_active;
extern struct { char *file; int unk1, unk2, unk3, x, y, frames; } anim;
extern union { int w; char b[2]; } joy_raw;

draw_bevel_box(x, y, w, h, color)
int x, y, w, h, color;
{
    fill_rect_xy(x, y, x + w, y + h, color);
    g_gfx->fillcolor = color;
    color ^= 8;
    if (color == 0) color = 7;
    if (color == 13) color = 7;
    draw_rect_outline(x, y, w, h, color);
}

draw_rect_outline(x, y, w, h, color)
int x, y, w, h, color;
{
    draw_line(x, y, x + w, y, color);
    draw_line(x, y + h, x + w, y + h, color);
    draw_line(x + w, y, x + w, y + h, color);
    draw_line(x, y, x, y + h, color);
}

int bld_flag = 0;
char anim_name[] = "animation.pan";
int joy_dirs[] = { 8, 7, 6, 1, -1, 5, 2, 3, 4 };   /* joystick (x, y) -> direction */

set_scene_background(name, x, y)
char *name;
int x, y;
{
    char c;

    if (!(options & 8) || (strcmp(name, "briefing.pan") && !require_disk(4, 0))) {
        gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
        anim.x = x;
        g_gfx->fillcolor = 5;
        return 0;
    }
    strcpy(anim_name, name);
    c = name[3];
    name[3] = 0;
    if (!strcmp(name, "bld")) bld_flag = 1;
    name[3] = c;
    anim_active = 1;
    anim.file = anim_name;
    anim.unk3 = -1;
    anim.x = x;
    anim.y = y;
    anim.frames = -1;
    return 1;
}

restore_background(unused)
int unused;
{
    drv_copy_rect(g_gfx, 0, 0, screen_width, 200, back_page, 0, 0);
    if (bld_flag) {
        drv_copy_rect(g_gfx, 0, 0, 160, 30, back_page, 0, 0);
        bld_flag = 0;
    }
}

get_key()
{
    int k;

    k = drv_getkey();
    switch (k) {
    case 0x4800:
    case 0x487E:
        k = 0x4800;
        break;
    case 0x4900:
        k = 0x4900;
        break;
    case 0xF400:
    case 0x4D00:
        k = 0x4D00;
        break;
    case 0x5100:
        k = 0x5100;
        break;
    case 0x5000:
    case 0x5060:
        k = 0x5000;
        break;
    case 0x4F00:
        k = 0x4F00;
        break;
    case 0x4B00:
    case 0x4B7C:
        k = 0x4B00;
        break;
    case 0x4700:
    case 0x475C:
        k = 0x4700;
        break;
    case 0x4838:
        k = 0x4838;
        break;
    case 0x4939:
        k = 0x4939;
        break;
    case 0x4D36:
    case 0x4D46:
        k = 0x4D36;
        break;
    case 0x5133:
        k = 0x5133;
        break;
    case 0x5032:
        k = 0x5032;
        break;
    case 0x4F31:
        k = 0x4F31;
        break;
    case 0x4B34:
    case 0x4B43:
        k = 0x4B34;
        break;
    case 0x4737:
        k = 0x4737;
        break;
    default:
        if (k & 0xFF)
            k &= 0xFF;
    }
    return k;
}

clear_play_area()
{
    gfx_fill_rect(g_gfx, 0, 0, screen_width, 200, 5);
    draw_status_bar();
    g_gfx->fillcolor = 5;
}

flush_input()
{
    while (!drv_kbhit())
        get_key();
    while ((options & 0x10) && (joystick_button(0) || joystick_button(1)))
        ;
}

joystick_to_key()
{
    int x, y, k;

    k = -1;
    if (options & 0x10) {
        switch (k = read_joystick(&x, &y)) {
        case 1:
        case 2:
        case 8:
            k = 0x4800;
            break;
        default:
            k = -1;
            break;
        case 4:
        case 5:
        case 6:
            k = 0x5000;
            break;
        }
        if (joystick_button(0))
            k = 13;
        if (joystick_button(1))
            k = 27;
    }
    return k;
}

read_joystick(px, py)
int *px, *py;
{
    if (!(options & 0x10))
        return -1;
    joy_raw.w = drv_read_joystick_raw();
    *px = joy_raw.b[0];
    *py = joy_raw.b[1];
    if (*px > 96)
        *px = 1;
    else if (*px < -96)
        *px = -1;
    else
        *px = 0;
    if (*py > 96)
        *py = 1;
    else if (*py < -96)
        *py = -1;
    else
        *py = 0;
    return joy_dirs[*px * 3 + *py + 4];
}

joystick_button(n)
int n;
{
    return !((inp(0x201) >> (n + 4)) & 1);
}
