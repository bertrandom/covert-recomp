/* TEXTWIN.C - MicroProse library: text window / menu. */
#include "mps.h"

extern int line_start[];            /* offsets of each line in the text */
extern int nlines;
extern int max_width;
extern char hotkeys[];              /* first letter of each menu item */
extern int first_item;              /* line of the first menu item (-1: none) */
extern int box_x2, box_y2;
extern int nitems;
extern int text_color, item_color, sel_color, box_color;
extern int redraw_all;
extern int anim_active;

extern int show_ok;
extern unsigned disabled;           /* disabled menu items (drawn with '^') */
extern int default_sel, menu_flag, paused, portrait, portrait_x, portrait_y;
extern int cur_disk, quit_flag;
extern unsigned anim_x;
extern char std_colormap[], std_colormap2[];
extern int anim[];
#define ENV (*(unsigned char far * far *)0x4F0L)

/* MSC emits these after text_window's string literals (globals are flushed at the
 * end of the next function), which is where they sit in DGROUP. */
char pan_sig[] = "PANI";            /* unused */
int anim_handle = -1;
int cur_drive = -1;
int screen_width = 320;             /* width of the area restored from the back page */
int lib_flag = 1;                   /* unused */
char palette1[] = { 0, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0 };
char palette2[] = { 0, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 6, 13, 14, 15, 0 };

text_window(str, x, y)
char *str;
int x, y;
{
    int sel, last, unused1, done, kk, backup, unused2, z, sav, j, joykey, stat, ht;

    last = -1;
    sel = default_sel;
    if (menu_flag || paused) sel = -1;
    first_item = -1;
    redraw_all = 1;
    ht = 8;
    backup = done = stat = 0;
    if (anim_active && !paused && ((options & 8) || portrait != -1)) {
        drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
        if (cur_drive == -1) _dos_getdrive(&cur_drive);
        if (cur_drive <= 2 && anim_x <= 200)
            draw_text("One moment please...", anim_x + 2, 1, 7);
        anim_start(anim);
        backup = 1;
        anim_handle = -1;
        drv_set_palette(palette1);
        require_disk(cur_disk, 1);
        if (portrait != -1) {
            if (((portrait >> 2) & 3) == 3) drv_set_palette(palette2);
            g_gfx->page = 2;
            draw_face_parts(portrait, portrait_x, portrait_y);
            g_gfx->page = 0;
        }
        j = 0;
        do anim_step(); while (++j < 2);
    }
    portrait = -1;
    drv_set_color_map(std_colormap, std_colormap2);
    draw_text_window(str, x, y, sel);
    if (first_item != -1 && !paused && !menu_flag) {
        drv_recolor_rect(g_gfx, x + 3, (first_item + default_sel) * 8 + y + 4, max_width + 3, ht + 1, box_color, 14);
        last = default_sel;
    }
    if (anim_active) restore_background(x, y);
    flush_input();
    if (paused) {
        paused = 0;
        return -1;
    }
    do {
        redraw_all = 0;
        z = options;
        joykey = -1;
        while (drv_kbhit() && joykey == -1) {
            if (anim_active && anim_step()) anim_active = 0;
            joykey = joystick_to_key();
        }
        if (!drv_kbhit() || joykey != -1) {
            switch (kk = (joykey == -1) ? get_key() : joykey) {
            case 0x5000:                                /* down */
                if (sel < nitems - 1) sel++;
                break;
            case 0x4800:                                /* up */
                if (sel > 0) sel--;
                break;
            case 0x1E00:                                /* Alt-A: animations */
                options ^= 8;
                goto toggled;
            case 0x1F00:                                /* Alt-S: sound */
                options ^= 4;
                goto toggled;
            case 0x2400:                                /* Alt-J: joystick */
                options ^= 0x10;
                if (options & 0x10) drv_joy_calibrate();
            toggled:
                if ((int)options > z) play_sound(20); else play_sound(19);
                break;
            case 0x1000:                                /* Alt-Q: quit */
                sav = anim_active;
                anim_active = menu_flag = 0;
                gfx_show_page(0);
                if (text_window("Are you sure\nyou want to Quit?\n No\n Yes\n", x, y & 0xFE) == 1) {
                    quit_flag = -1;
                    if (sav) anim_stop();
                    ENV[0] = quit_flag;
                    set_exit_state();
                    exit();
                }
                anim_active = sav;
            case 0x1B:                                  /* Esc */
                sel = -1;
            case 0x0D:
            case 0x20:
            case 0x3B00:
                done = 1;
                break;
            }
        }
        if (sel < 0 || sel >= nitems || show_ok || menu_flag) sel = -1;
        if (sel != last) {
            if (last != -1)
                drv_recolor_rect(g_gfx, x + 3, (last + first_item) * 8 + y + 4, max_width + 3, ht + 1, 14, box_color);
            if (sel != -1)
                drv_recolor_rect(g_gfx, x + 3, (sel + first_item) * 8 + y + 4, max_width + 3, ht + 1, box_color, 14);
            last = sel;
            if (joykey != -1) wait_retrace(15);
        }
        if (anim_active) restore_background(x, y);
    } while (!done);
    if (sel != -1) {
        drv_recolor_rect(g_gfx, x + 3, (sel + first_item) * 8 + y + 4, max_width + 3, ht + 1, 14, 15);
        if (anim_active) restore_background(x, y);
        wait_retrace(20);
    }
    if (anim_active) {
        anim_stop();
        anim_active = 0;
    }
    if (backup) {
        g_gfx->page = 0;
        gfx_show_page(0);
    }
    default_sel = 0;
    disabled = 0;
    menu_flag = show_ok = 0;
    return sel;
}

draw_text_window(str, x, y, sel)
char *str;
int x, y, sel;
{
    char tmp[80];
    int w, i, n;

    line_start[0] = 0;
    if (redraw_all == 1) {
        for (i = 0; i < 32; i++) hotkeys[i] = 0;
        max_width = w = nlines = n = 0;
        for (i = 0; i < strlen(str); i++) {
            if (str[i] == '\n') {
                if (w > max_width) max_width = w;
                w = 0;
                nlines++;
                line_start[nlines] = i + 1;
            } else {
                if (w == 0 && str[i] == ' ') {
                    hotkeys[n] = str[i + 1];
                    if (first_item == -1) first_item = nlines;
                    n++;
                }
                w += drv_char_width(g_gfx->font, str[i]);
            }
        }
        nlines = clamp(nlines, 0, (192 - y) / 8);
        box_x2 = x + max_width + 8;
        box_y2 = y + nlines * 8 + 6;
        if (str[strlen(str) - 1] != '\n') n--;
        nitems = n;
        text_color = 15;
        item_color = 7;
        sel_color = 7;
        box_color = 5;
        if (y & 1) {
            if (anim_active) {
                screen_width = clamp(anim_x, box_x2 + 5, 999);
                g_gfx->fillcolor = 5;
                if (y < 144) {
                    gfx_fill_rect(g_gfx, 0, 0, screen_width, 200, 5);
                    draw_status_bar();
                } else
                    gfx_fill_rect(g_gfx, 4, y, 312, 198 - y, 5);
            } else {
                gfx_fill_rect(g_gfx, x + 1, y + 1, box_x2 - x, box_y2 - y, g_gfx->fillcolor);
                if (g_gfx->fillcolor == 15) {
                    text_color = 0;
                    sel_color = 8;
                    item_color = 7;
                    box_color = 15;
                }
            }
        } else {
            g_gfx->fillcolor = 5;
            draw_bevel_box(x, y, box_x2 - x, box_y2 - y, 5);
            box_color = 5;
        }
        if (show_ok) {
            draw_text("OK", box_x2 - 17, box_y2 - 8, 11);
            draw_rect_outline(box_x2 - 20, box_y2 - 10, 20, 10, 11);
        }
    }
    n = (*str == ' ') ? 0 : -1;
    g_gfx->textcolor = text_color;
    for (i = 0; i < nlines; i++) {
        if (redraw_all || abs(sel - n) < 2) {
            str[line_start[i + 1] - 1] = 0;
            if (n >= 0 && (disabled & (1 << n))) {
                str[line_start[i]] = '^';
                draw_text_transparent(str + line_start[i], x + 5, i * 8 + y + 5,
                                      n < 0 ? text_color : (n == sel ? sel_color : item_color));
                str[line_start[i]] = ' ';
            } else
                draw_text_transparent(str + line_start[i], x + 5, i * 8 + y + 5,
                                      n < 0 ? text_color : (n == sel ? sel_color : item_color));
            str[line_start[i + 1] - 1] = '\n';
        }
        if (str[line_start[i + 1]] == ' ') n++;
    }
    return sel;
}
