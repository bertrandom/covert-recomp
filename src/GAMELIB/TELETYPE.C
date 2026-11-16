/* TELETYPE.C - shared game library: the teletype paper background and the
 * "Incoming Msg" teleprinter animation.
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "mps.h"
#include "gamelib.h"

draw_teletype_paper()
{
    int y;
    int j;

    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 15);
    draw_line(8, 0, 8, 199, 7);
    draw_line(0x137, 0, 0x137, 199, 7);
    for (y = 4; y < 199; y += 12) {
        gfx_fill_rect(g_gfx, 2, y, 4, 4, 8);
        gfx_fill_rect(g_gfx, 0x13A, y, 4, 4, 8);
    }
    for (y = 0x20; y < 199; y += 0x40) {
        draw_line(0x17, y + 1, 0x17, y + 0x1D, 11);
        draw_line(0x128, y + 1, 0x128, y + 0x1D, 11);
        for (j = 0; j < 0x20; j += 2)
            draw_line(0x18, y + j, 0x127, y + j, 11);
    }
}

incoming_message(msg)
char *msg;
{
    int x;
    int y;
    int n;

    drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
    drv_set_color_map(tele_colors, tele_colors);
    gfx_fill_rect(g_gfx, 0, 0, 320, 100, 5);
    draw_shape_list(teletype_shapes);
    gfx_fill_rect(g_gfx, 0x32, 0x96, 0xDC, 0x0D, 15);
    draw_text_centered(msg, 0xA0, 0x98, 12);
    draw_text_centered("Incoming Msg", 0x40, 0xBA, 10);
    draw_line(0x31, 0x96, 0x31, 0xA2, 8);
    draw_line(0x10E, 0x96, 0x10E, 0xA2, 8);
    drv_copy_rect(g_gfx, 0, 100, 320, 100, work_page, 0, 100);
    g_gfx->page = 2;
    gfx_fill_rect(g_gfx, 0x32, 0x44, 0xDC, 0x5F, 15);
    g_gfx->fillcolor = 15;
    y = draw_wrapped_text(0x19, 0x3A, 0x4C, 5);
    g_gfx->page = 0;
    flush_input();
    for (n = 0; n < (y - 0x4C) / 8; n++) {
        drv_copy_rect(g_gfx, 0x31, 0x96 - n * 8, 0xDE, n * 8 + 0x0D, g_gfx, 0x31, 0x8E - n * 8);
        gfx_fill_rect(g_gfx, 0x32, 0x9B, 0xDC, 8, 15);
        play_sound(0x1F);
        for (x = 0x34; x < 0xF0; x++) {
            drv_copy_rect(work_page, x - 2, n * 8 + 0x4A, 2, 10, g_gfx, x - 2, 0x99);
            draw_line(x - 1, 0xA3, x - 1, 0xA6, 7);
            draw_sprite_a(0x6F, x, 0x9A);
            if (x & 7)
                wait_retrace(1);
            else
                wait_retrace(3);
            if (!drv_kbhit())
                break;
        }
        play_sound(0x20);
        wait_retrace(15);
        drv_copy_rect(work_page, x - 2, n * 8 + 0x4A, 0x20, 10, g_gfx, x - 2, 0x99);
        gfx_fill_rect(g_gfx, x - 1, 0xA3, 0x20, 4, 7);
        if (!drv_kbhit())
            break;
    }
    drv_copy_rect(g_gfx, 0x31, 0x96 - n * 8, 0xDE, n * 8 + 0x0D, g_gfx, 0x31, 0x8E - n * 8);
    gfx_fill_rect(g_gfx, 0x32, 0x9B, 0xDC, 8, 15);
    drv_copy_rect(g_gfx, 0x31, 0x8E - n * 8, 0xDE, n * 8 + 0x15, g_gfx, 0x31, 0x88 - n * 8);
    gfx_fill_rect(g_gfx, 0x32, 0x9B, 0xDC, 8, 15);
    draw_sprite_a(0x6F, 0x34, 0x9A);
    wait_key_or_button();
    drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
    drv_set_color_map(std_colormap, std_colormap2);
}

draw_shape_list(list)
struct shape *list;
{
    int times;
    int idx;
    int ox;
    int oy;

    idx = ox = oy = 0;
    do {
        switch (list[idx].type) {
        case 0:
            draw_line(list[idx].x1 + ox, list[idx].y1 + oy, list[idx].x2 + ox, list[idx].y2 + oy, list[idx].color);
            break;
        case 1:
            fill_rect_xy(list[idx].x1 + ox, list[idx].y1 + oy, list[idx].x2 + ox, list[idx].y2 + oy, list[idx].color);
            break;
        case 2:
            if (list[idx].color == 0) {
                ox = oy = 0;
                times = list[idx].x2;
                list[idx].color = 1;
            }
            if (--times) {
                ox += list[idx].x1;
                oy += list[idx].y1;
                idx -= list[idx].y2 + 1;
            } else {
                list[idx].color = 0;
                ox = oy = 0;
            }
            break;
        case 3:
            draw_line(list[idx].x1 + ox, list[idx].y1 + oy, list[idx].x1 + ox, list[idx].y2 + oy, list[idx].color);
            draw_line(list[idx].x1 + ox, list[idx].y1 + oy, list[idx].x2 + ox, list[idx].y1 + oy, list[idx].color);
            draw_line(list[idx].x2 + ox, list[idx].y2 + oy, list[idx].x2 + ox, list[idx].y1 + oy, list[idx].color);
            draw_line(list[idx].x2 + ox, list[idx].y2 + oy, list[idx].x1 + ox, list[idx].y2 + oy, list[idx].color);
            break;
        case -1:
            idx = -1;
            break;
        }
    } while (++idx);
}

/* The teletype's drawing (draw_shape_list): type, x1, y1, x2, y2, color. Last
 * in the file, after the literals of incoming_message. */
struct shape teletype_shapes[] = {     /* 2B62 */
    { 1, 0, 54, 319, 55, 8 },
    { 1, 0, 56, 319, 199, 7 },
    { 0, 0, 169, 319, 169, 8 },
    { 0, 0, 56, 0, 56, 7 },
    { 0, 0, 57, 0, 167, 15 },
    { 0, 0, 168, 0, 168, 7 },
    { 0, 1, 56, 1, 168, 8 },
    { 0, 1, 169, 1, 169, 5 },
    { 2, 8, 0, 40, 5, 0 },
    { 1, 31, 98, 290, 165, 7 },
    { 0, 31, 97, 290, 97, 5 },
    { 1, 30, 166, 291, 168, 5 },
    { 0, 31, 113, 31, 166, 8 },
    { 0, 291, 97, 291, 167, 8 },
    { 0, 290, 113, 290, 166, 8 },
    { 0, 30, 97, 30, 167, 8 },
    { 1, 33, 160, 288, 165, 8 },
    { 1, 50, 163, 269, 166, 7 },
    { 0, 270, 166, 270, 166, 8 },
    { 0, 50, 167, 270, 167, 8 },
    { 0, 270, 166, 270, 166, 8 },
    { 0, 50, 167, 270, 167, 8 },
    { 0, 30, 169, 291, 169, 7 },
    { 0, 0, 177, 319, 177, 15 },
    { 1, 4, 184, 124, 195, 5 },
    { 1, 123, 185, 124, 194, 8 },
    { 1, 6, 185, 122, 194, 2 },
    { 0, 4, 196, 124, 196, 15 },
    { 1, 146, 183, 178, 196, 5 },
    { 1, 148, 184, 176, 194, 7 },
    { 0, 147, 184, 147, 194, 15 },
    { 0, 148, 185, 148, 193, 15 },
    { 0, 149, 185, 174, 185, 15 },
    { 0, 176, 185, 176, 193, 8 },
    { 0, 177, 184, 177, 194, 8 },
    { 2, 41, 0, 3, 7, 0 },
    { 0, 270, 184, 319, 184, 5 },
    { 1, 270, 185, 319, 199, 8 },
    { 1, 272, 197, 319, 199, 7 },
    { 1, 274, 189, 295, 193, 5 },
    { 1, 274, 188, 294, 192, 3 },
    { 0, 273, 188, 273, 192, 11 },
    { 0, 274, 188, 293, 188, 11 },
    { 1, 303, 189, 307, 193, 5 },
    { 1, 303, 188, 306, 192, 4 },
    { 0, 302, 188, 302, 192, 12 },
    { 0, 303, 188, 305, 188, 12 },
    { 2, 9, 0, 2, 4, 0 },
    { -1, 0, 0, 0, 0, 0 },
};
