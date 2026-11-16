/* BOARD.C - BUG.EXE circuit board: sprites, board setup, signal tracing, the
 * per-frame input loop, timer and intercept popups.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "bug.h"

extern void far gate_thunk_b();     /* draw an image: (port, x, y, image) */
extern void far drv_call_gate();

extern int  sprites_a[];            /* images drawn by draw_sprite_a */
extern int  sprites[];              /* 0-31 trace pieces, 32-43 chips (bugs.pic) */
extern int  traces[][25];           /* trace cells: bits 0-7 directions, 100h lit */
extern int  dir_dx[8], dir_dy[8];
extern int  ticks;
extern char timer_text[];           /* "00:00:00" */
extern char tune_data[][17];
extern RastPort *chip_page;
extern int  paused;
extern int  portrait;
extern char std_colormap[], std_colormap2[];
extern int  chips[7][5];            /* chip ids; 40h locked, 80h placed */
extern int  spare_chip;             /* chip in hand */
extern int  cur_x, cur_y;           /* cursor on the chip grid */
extern int  sig[15][10];            /* signal levels per chip row; 13 outputs, 14 dead */
extern int  links[6][10];           /* chip output -> next row input */
extern int  logic[][4][2];          /* chip truth tables */
extern int  num_chips;
extern int  board_variant;
extern int  tapped, best_tapped;
extern char msgbuf[], numbuf[];
extern int  popup_x, popup_y, popup_style;
extern int  info_a, info_b;
extern int  far drv_slot12();       /* read a pixel: (page, x, y) */
extern char *itoa();

/* Initialized data: emitted after the next function's literals (draw_sprite_a has
 * none), so it comes before "bugs.pic" in DGROUP. 16 colors + border each. */
char tune_data[5][17] = {
    { 0, 1, 2, 3, 15, 12, 6, 7, 8, 9, 10, 11, 12, 15, 14, 15, 0 },
    { 0, 1, 2, 3, 15, 12, 6, 7, 8, 9, 10, 11, 15, 12, 14, 15, 0 },
    { 0, 1, 2, 3, 12, 15, 6, 7, 8, 9, 10, 11, 15, 12, 14, 15, 0 },
    { 0, 1, 2, 3, 12, 15, 6, 7, 8, 9, 10, 11, 12, 15, 14, 15, 0 },
    { 0, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 0 },
};

draw_sprite_a(n, x, y)
int n, x, y;
{
    gate_thunk_b(g_gfx, x, y, sprites_a[n]);
}

draw_sprite(n, x, y)
int n, x, y;
{
    gate_thunk_b(g_gfx, x, y, sprites[n]);
}

load_bug_sprites()
{
    int row, col;

    drv_begin_image_grab();
    draw_face();
    drv_set_color_map(colormap, colormap);
    load_picture_swapped("bugs.pic", 2);
    for (row = 0; row < 2; row++)
        for (col = 0; col < 16; col++)
            sprites[row * 16 + col] = drv_get_image(2, col << 3, row * 8 + 16, 8, 8);
    row = 0;
    do {
        sprites[row + 32] = drv_get_image(2, row << 4, 0, 16, 16);
        row++;
    } while (row < 12);
    drv_end_image_grab();
}

build_board()
{
    int countx, d, bitss, px, py, i1, sumv, pair, n_, rowv, pairs;

    /* The original stores difficulty back onto itself (MOV AX,[1652h] / MOV [1652h],AX).
     * MSC drops a plain self-assignment, so it must have gone through a second name for
     * the same word; chip_page is the word just before difficulty. */
    ((int *)&chip_page)[1] = difficulty;
    num_chips = clamp(difficulty * 2 + 6, 0, 11);
    for (i1 = 0; i1 < 40; i1++)
        for (rowv = 0; rowv < 25; rowv++) {
            px = (i1 << 3) + 4;
            py = (rowv << 3) + 4;
            bitss = 0;
            for (d = 0; d < 8; d++)
                if (drv_slot12(0, dir_dx[d] * 2 + px, dir_dy[d] * 2 + py) == (board_variant ? 3 : 10))
                    bitss += 1 << d;
            traces[i1][rowv] = bitss;
        }
    do {
        countx = 0;
        for (i1 = 0; i1 < 6; i1++) {
            pair = 0;
            for (rowv = 0; rowv < 5; rowv++) {
                px = i1 * 4 + 7;
                py = rowv * 4 + 1;
                switch (random(3)) {
                case 0:
                case 1:
                    traces[px][py] = 0x44;
                    traces[px + 1][py] = 0x44;
                    traces[px][py + 1] = 0x44;
                    traces[px + 1][py + 1] = 0x44;
                    links[i1][rowv * 2] = rowv * 2;
                    links[i1][rowv * 2 + 1] = rowv * 2 + 1;
                    if (pair) {
                        countx++;
                        traces[px][py] = 0x41;
                        traces[px + 1][py] = 5;
                        traces[px][py - 1] = 0x12;
                        traces[px + 1][py - 1] = 0x90;
                        traces[px][py - 2] = 9;
                        traces[px + 1][py - 2] = 0x21;
                        traces[px][py - 3] = 0x50;
                        traces[px + 1][py - 3] = 0x14;
                        links[i1][rowv * 2] = rowv * 2 - 1;
                        links[i1][rowv * 2 - 1] = rowv * 2;
                    }
                    pair = 1;
                    break;
                case 2:
                    traces[px][py] = 0x48;
                    traces[px + 1][py] = 0x24;
                    traces[px][py + 1] = 0x42;
                    traces[px + 1][py + 1] = 0x84;
                    links[i1][rowv * 2] = rowv * 2 + 1;
                    links[i1][rowv * 2 + 1] = rowv * 2;
                    pair = 0;
                    break;
                }
            }
        }
    } while (countx < difficulty * 4 || countx > difficulty * 4 + 4);
    for (i1 = 0; i1 < 10; i1++) {
        rowv = 0;
        do {
            sig[rowv][i1] = -1;
            rowv++;
        } while (rowv < 14);
        sig[0][i1] = (!(i1 & 3) || (i1 & 3) == 3) ? 1 : 0;
    }
    i1 = 1;
    do {
        px = i1 * 4 + 7;
        py = 17;
        traces[px][py + 1] |= 0x10;
        traces[px + 1][py + 1] |= 0x10;
        i1++;
    } while (i1 < 6);
    do {
        for (i1 = 0; i1 < 7; i1++)
            for (rowv = 0; rowv < 5; rowv++)
                do
                    n_ = chips[i1][rowv] = clamp(random(difficulty + 6) + difficulty, 0, 11);
                while (i1 == 6 && n_ < 4);
        board_status(0L);
        sumv = 0;
        pairs = 0;
        i1 = 0;
        do {
            sumv += sig[13][i1];
            sig[14][i1] = !sig[13][i1];
            if (sig[13][i1 & 0xE] && sig[13][(i1 & 0xE) + 1])
                pairs++;
            i1++;
        } while (i1 < 10);
    } while (sumv != 6 - difficulty / 2 || pairs && pairs / 2 > 4 - difficulty);
    for (i1 = 0; i1 < 7; i1++)
        for (rowv = 0; rowv < 5; rowv++)
            if (random(3) + 1 >= difficulty || i1 == 6)
                chips[i1][rowv] |= 0x80;
    n_ = 0;
    while (n_ < difficulty * 2) {
        px = random(6);
        py = random(5);
        if (chips[px][py] > 3 && !(chips[px][py] & 0x40) && (px != 5 || difficulty == 4)) {
            chips[px][py] |= 0x40;
            if (difficulty != 4)
                chips[px][py] |= 0x80;
            n_++;
        }
    }
    for (i1 = 0; i1 < 7; i1++)
        for (rowv = 0; rowv < 5; rowv++) {
            if (chips[i1][rowv] & 0x40) {
                drv_recolor_rect(g_gfx, (i1 << 5) + 0x27, (rowv << 5) + 5, 0x12, 0x17, 2, 8);
                drv_recolor_rect(g_gfx, (i1 << 5) + 0x27, (rowv << 5) + 5, 0x12, 0x17, 3, 8);
                draw_line((i1 << 5) + 0x28, (rowv << 5) + 5, (i1 << 5) + 0x28, (rowv << 5) + 0x18, 8);
                draw_line((i1 << 5) + 0x37, (rowv << 5) + 5, (i1 << 5) + 0x37, (rowv << 5) + 0x18, 8);
            }
            if (chips[i1][rowv] & 0x80)
                draw_chip(chips[i1][rowv], i1 * 32 + 0x28, rowv * 32 + 8, 0L);
        }
    spare_chip = clamp(random(difficulty + 6) + difficulty, 0, 11);
    for (i1 = 0; i1 < 10; i1++) {
        rowv = 0;
        do {
            sig[rowv][i1] = -1;
            rowv++;
        } while (rowv < 14);
        sig[0][i1] = (!(i1 & 3) || (i1 & 3) == 3) ? 1 : 0;
    }
    board_status(1L);
    cur_x = 3;
    cur_y = 2;
    if (chips[cur_x][cur_y] & 0x80)
        draw_chip(chips[cur_x][cur_y], cur_x * 32 + 0x28, cur_y * 32 + 8, 1L);
    else
        draw_chip(-1, cur_x * 32 + 0x28, cur_y * 32 + 8, 1L);
}

board_status(update)
int update;
{
    int unused, xoff2, row, y, bx, i2, oldn, fx;

    gfx_fill_rect(g_gfx, 0x9A, 0xB1, 12, 16, 8);
    draw_sprite((spare_chip & 0x3F) + 0x20, 0x98, 0xB1);
    if (update && !ticks)
        trace_signal(7, 20, 0, 1);
    for (i2 = 0; i2 < 7; i2++)
        for (fx = 0; fx < 5; fx++) {
            row = i2 * 2;
            bx = fx * 2;
            oldn = sig[row + 1][bx];
            sig[row + 1][bx] = logic[chips[i2][fx] & 0x3F][sig[row][bx + 1] * 2 + sig[row][bx]][0];
            if (update && sig[row + 1][bx] != oldn)
                trace_signal(i2 * 4 + 7, fx * 4 + 1, 2, sig[row + 1][bx]);
            if (i2 < 6)
                sig[row + 2][links[i2][bx]] = sig[row + 1][bx];
            oldn = sig[row + 1][bx + 1];
            sig[row + 1][bx + 1] = logic[chips[i2][fx] & 0x3F][sig[row][bx + 1] * 2 + sig[row][bx]][1];
            if (update && sig[row + 1][bx + 1] != oldn)
                trace_signal(i2 * 4 + 7, fx * 4 + 2, 2, sig[row + 1][bx + 1]);
            if (i2 < 6)
                sig[row + 2][links[i2][bx + 1]] = sig[row + 1][bx + 1];
        }
    if (update) {
        tapped = 0;
        for (i2 = 0; i2 < 10; i2++) {
            xoff2 = ((i2 & 1) ? 0x18 : 0) + 0x108;
            y = i2 << 4;
            oldn = sig[13][i2];
            if (sig[14][i2]) {
                drv_copy_rect(chip_page, oldn ? 0x12 : 2, 0x20, 12, 16, g_gfx, xoff2 + 2, y);
                if (oldn) alarms++;
            } else {
                if (tapped == best_tapped && !oldn)
                    play_sound(0x1D);
                if (!car_tracer) {
                    drv_copy_rect(chip_page, oldn ? 0x22 : 0x32, 0x20, 12, 16, g_gfx, xoff2 + 2, y);
                    if (!oldn && ++tapped > best_tapped) {
                        best_tapped = tapped;
                        if (!(options & 0x20))
                            show_intercepted_info(8);
                    }
                }
                if (car_tracer == 1) {
                    drv_copy_rect(chip_page, oldn ? 0x42 : 0x52, 0x20, 12, 16, g_gfx, xoff2 + 2, y);
                    if (!oldn && ++tapped > best_tapped) {
                        best_tapped = tapped;
                        drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
                        strcpy(msgbuf, "Car tracer ");
                        strcat(msgbuf, itoa(tapped * 20, numbuf, 10));
                        strcat(msgbuf, "% complete\n");
                        drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
                    }
                }
            }
        }
    }
    g_gfx->fillcolor = 1;
    if (alarms) {
        play_tune(0);
        play_sound(0x1E);
        strcpy(msgbuf, "Alarm!!!\n");
        text_window(msgbuf, 100, 0x51);
        progress = 0;
        quit_flag = 1;
    }
    if ((!car_tracer ? 6 - difficulty / 2 : 5) <= tapped || time_limit == 0) {
        if (time_limit) {
            if (!car_tracer) {
                if (!(options & 0x20))
                    show_intercepted_info(orig_difficulty << 4);
                strcpy(msgbuf, "Phone taps completed.\n");
            } else
                strcpy(msgbuf, "Car tracer installed.\n");
            play_sound(0x2E);
        } else {
            strcpy(msgbuf, "Time expired.\n");
            if (!car_tracer) {
                strcat(msgbuf, itoa(tapped, numbuf, 10));
                strcat(msgbuf, " phones tapped.\n");
            }
        }
        strcat(msgbuf, alarms ? itoa(alarms, numbuf, 10) : "No");
        strcat(msgbuf, " Alarms\n");
        g_gfx->fillcolor = 15;
        text_window(msgbuf, 100, 0x51);
        progress = tapped;
        quit_flag = 1;
    }
}

trace_signal(x, y, dir, lit)
int x, y, dir, lit;
{
    int first, i, mask;

    while ((mask = traces[x][y]) != 0 && dir != -1) {
        traces[x][y] = (mask & 0xFF) + (lit ? 0x100 : 0);
        draw_trace_cell(x, y, dir);
        first = -1;
        for (i = 0; i < 8; i++) {
            if (((dir + 4) & 7) == i) continue;
            if (!(mask & (1 << i))) continue;
            if (first == -1)
                first = i;
            else
                trace_signal(x + dir_dx[i], y + dir_dy[i], i, lit);
        }
        dir = first;
        x += dir_dx[dir];
        y += dir_dy[dir];
        if (ticks && time_limit > 1) {
            advance_timer(1);
            wait_retrace(1);
        }
    }
}

draw_trace_cell(x, y, dir)
int x, y, dir;
{
    int i, mask;

    mask = traces[x][y];
    for (i = 0; i < 8; i++) {
        if (!(mask & (1 << i))) continue;
        if (mask & 0x100)
            draw_sprite((((dir + 4) & 7) == i ? 16 : 24) + i, x << 3, y << 3);
        else
            draw_sprite(i, x << 3, y << 3);
    }
}

advance_timer(n)
int n;
{
    int i;

    for (i = 0; i < n; i++) {
        ticks++;
        if (!(ticks & 7)) {
            time_limit--;
            draw_timer();
            if (time_limit == 0) board_status();
        }
        play_tune(ticks & 3);
    }
}

char timer_text[] = "00:00:00";     /* after bug_frame's literals */

bug_frame()
{
    int slow, x, y, savedx, keys, dx2, dy2;

    advance_timer(1);
    keys = -1;
    slow = 0;
    if (options & 0x10) {
        keys = read_joystick(&x, &y);
        if (joystick_button(0)) {
            keys = 13;
            flush_input();
        }
        if (keys != -1) slow = 1;
    }
    if (!drv_kbhit() || keys != -1) {
        if (keys == -1) keys = get_key();
        switch (keys) {
        case 0x1B:
            progress = tapped;
            quit_flag = 1;
            break;
        case 13:
        case ' ':
            x = cur_x;
            y = cur_y;
            if (chips[cur_x][cur_y] & 0x40) break;
            if (!(chips[x][y] & 0x80)) {
                draw_chip(chips[x][y], x * 32 + 0x28, y * 32 + 8, 1L);
                advance_timer(10);
            }
            savedx = spare_chip;
            spare_chip = chips[x][y] & 0x3F;
            chips[x][y] = savedx + 0x80;
            draw_chip(chips[x][y], x * 32 + 0x28, y * 32 + 8, 1L);
            play_sound(0x1C);
            board_status(1L);
            break;
        case 1:
        case 0x4800:
            dx2 = 0;
            dy2 = -1;
            goto move;
        case 2:
        case 0x4900:
            dx2 = 1;
            dy2 = -1;
            goto move;
        case 3:
        case 0x4D00:
            dx2 = 1;
            dy2 = 0;
            goto move;
        case 4:
        case 0x5100:
            dx2 = 1;
            dy2 = 1;
            goto move;
        case 5:
        case 0x5000:
            dx2 = 0;
            dy2 = 1;
            goto move;
        case 6:
        case 0x4F00:
            dx2 = -1;
            dy2 = 1;
            goto move;
        case 7:
        case 0x4B00:
            dx2 = -1;
            dy2 = 0;
            goto move;
        case 8:
        case 0x4700:
            dx2 = -1;
            dy2 = -1;
            goto move;
        case 0x1000:
            drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
            g_gfx->fillcolor = 15;
            if (text_window("Are you sure\nyou want to Quit?\n No\n Yes\n", 0x50, 0x51) == 1) {
                set_exit_state();
                ENV[0] = 0xFF;
                exit();
            }
            drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
            break;
        case 0x1F00:
            if (options & 4) play_sound(0);
            options ^= 4;
            break;
        case 0x1900:
            drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
            gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
            paused = 1;
            text_window("PAUSED\n", 0x80, 0x51);
            get_key();
            drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
            break;
        move:
            if (chips[cur_x][cur_y] & 0x80)
                draw_chip(chips[cur_x][cur_y], cur_x * 32 + 0x28, cur_y * 32 + 8, 0L);
            else
                draw_chip(-1, cur_x * 32 + 0x28, cur_y * 32 + 8, 0L);
            cur_x = clamp(dx2 + cur_x, 0, 5);
            cur_y = clamp(dy2 + cur_y, 0, 4);
            if (chips[cur_x][cur_y] & 0x80)
                draw_chip(chips[cur_x][cur_y], cur_x * 32 + 0x28, cur_y * 32 + 8, 1L);
            else
                draw_chip(-1, cur_x * 32 + 0x28, cur_y * 32 + 8, 1L);
            break;
        }
    }
    if (slow) wait_retrace(20);
    else wait_retrace(5);
}

draw_chip(chip, x, y, sel)
int chip, x, y, sel;
{
    drv_copy_rect(chip_page, sel ? 17 : 1, 55, 14, 19, g_gfx, x + 1, y - 1);
    if (chip != -1)
        draw_sprite((chip & 0x3F) + 0x20, x, y);
}

draw_timer()
{
    int min, sec, hrs, rest;

    rest = time_limit;
    hrs = rest / 3600;
    rest -= 3600 * hrs;
    min = rest / 60;
    rest -= 60 * min;
    sec = rest;
    timer_text[0] = hrs / 10 + '0';
    timer_text[1] = hrs % 10 + '0';
    timer_text[3] = min / 10 + '0';
    timer_text[4] = min % 10 + '0';
    timer_text[6] = sec / 10 + '0';
    timer_text[7] = sec % 10 + '0';
    gfx_fill_rect(g_gfx, 0x100, 0xB8, 0x30, 9, 0);
    g_gfx->fillcolor = 0;
    draw_text(timer_text, 0x104, 0xB9, 7);
}

show_menu(s, x, y)
char *s;
int x, y;
{
    text_window(s, x, y);
}

draw_intercept_popup()
{
    int u1, u2, u3, off_, xs, ys, wv;

    xs = clamp(0x1F, popup_x - 0x92, popup_x);
    ys = clamp(0x31, popup_y - 0x66, popup_y);
    gate_thunk_b(g_gfx, xs, ys, camera_img);
    if (portrait > -1)
        draw_portrait(portrait, xs + 0x3A, ys + 0x18);
    if (portrait == -2)
        gate_thunk_b(g_gfx, xs + 0x3E, ys + 10, camera_img2);
    g_gfx->fillcolor = 11;
    draw_wrapped_text(14, xs + 20, ys + 0x43, 3);
    draw_wrapped_text(14, xs + 19, ys + 0x43, 5);
    if (popup_style != 1)
        draw_rect_outline(xs + 13, ys + 10, 0x78, 0x4E, 15);
    else {
        off_ = 16;
        do {
            wv = random(16) + 2;
            draw_line(xs + off_, ys + 0x40, xs + off_ + wv, ys + 0x40, 15);
            off_ += wv;
            draw_line(xs + off_, ys + 0x40, xs + off_, ys + 0x30, 15);
            draw_line(xs + off_, ys + 0x30, xs + off_ + 4, ys + 0x30, 15);
            off_ += 4;
            draw_line(xs + off_, ys + 0x40, xs + off_, ys + 0x30, 15);
        } while (off_ < 0x72);
        draw_line(xs + off_, ys + 0x40, xs + 0x82, ys + 0x40, 15);
    }
}

show_intercepted_info(n)
int n;
{
    int saved;

    drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
    play_tune(4);
    popup_x = 160;
    popup_y = 100;
    saved = difficulty;
    difficulty = orig_difficulty;
    drv_set_color_map(std_colormap, std_colormap2);
    describe_new_info(info_a, info_b, n, 1L);
    drv_set_color_map(colormap, colormap);
    difficulty = saved;
    play_tune(ticks & 3);
    drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
}

play_tune(n)
int n;
{
    drv_call_gate(tune_data[n]);
}
