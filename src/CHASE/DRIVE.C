/* DRIVE.C - Covert Action car chase (CHASE.EXE): car setup, team car selection,
 * the main chase loop, line of sight, street view, dashboard and city map
 * generation.
 * Reconstructed from the original binary; compiles with MSC 5.1 CL /AS /Gs /Oas. */
#include "mps.h"
#include "chase.h"

/* Assembly library / MS C runtime */
extern int far gate_thunk_b();
extern char *itoa();
char *format_clock();

init_cars()
{
    int x, i, j;

    heat_limit = 1000 / (difficulty + 3);
    heat_limit = heat_limit * 10 / (alert_level + 100) * 10;
    outcome = 0;
    cars[0].x = bld_x[chase_start];
    cars[0].y = bld_y[chase_start];
    cars[0].dir = (bld_y[chase_dest] < cars[0].y) ? 0 : 2;
    cars[0].tx = cars[0].x;
    cars[0].ty = cars[0].y;
    cars[0].req = -1;
    cars[0].heat = 0;
    cars[0].bits = 0;
    cars[0].speed = 2;
    for (i = 1; i < 3; i++) {
        cars[i].x = cars[0].x - (dir_dx[cars[0].dir] << 5) / 4 * i;
        cars[i].y = cars[0].y - (dir_dy[cars[0].dir] << 5) / 4 * i;
        cars[i].dir = cars[0].dir;
        cars[i].follow = 1;
        cars[i].tx = -1;
        cars[i].req = -1;
        cars[i].heat = 0;
        cars[i].speed = 0;
    }
    target_x = bld_x[chase_dest];
    target_y = bld_y[chase_dest];
    if (chase_mode == 2) cur_car = 0;
}

/* Initialized data is emitted after the next function's string literals, which is
 * where these sit in DGROUP. */
int grade_colors[4][2] = { { 7, 8 }, { 10, 2 }, { 15, 7 }, { 12, 4 } };

car_select_screen()
{
    int picked, used[4], slot;
    int c;
    int keycode, total, done, sprite, line, i, j, paint;
    int specs[4];

    play_sound(0x27);
    load_picture_swapped("cars.pic", 1);
    drv_copy_rect(back_page, 0x9A, 0, 0xA6, 200, g_gfx, 0x9A, 0);
    for (i = 0; i < 4; i++) used[i] = 0;
    for (i = 0; i < 4; i++) {
        do {
            c = random(64);
            total = c & 3;
            if (c & 4) total += 2;
            if (c & 8) total++;
            total -= (c & 0x30) >> 4;
            for (j = 0; j < i; j++)
                if (specs[j] == c) total = -1;
        } while (total != 3 - difficulty || (c & 3) == 3);
        specs[i] = c;
        sprite = 2;
        if (!(c & 0x30)) sprite = 3;
        if ((c & 8) && (c & 3)) sprite = 1;
        if ((c & 3) == 2) sprite = 0;
        drv_copy_rect(back_page, 0, sprite * 50, 0x9A, 50, g_gfx, 0, i * 50);
        paint = (c & 0x30) >> 4;
        if (!used[paint] && !is_cga) {
            drv_recolor_rect(g_gfx, 0, i * 50, 0x9A, 50, 11, grade_colors[paint][0]);
            drv_recolor_rect(g_gfx, 0, i * 50, 0x9A, 50, 3, grade_colors[paint][1]);
        }
        used[paint] = 1;
        line = i * 50 + 11;
        if (c & 4) draw_text_transparent("(Tracking)", 256, line, 15);
        line += 9;
        strcpy(message, "");
        strcat(message, itoa((c & 3) * 20 + 40, num_buf, 10));
        strcat(message, " mph");
        draw_text_transparent(message, 256, line, 15);
        line += 9;
        strcpy(message, (c & 8) ? "Excellent" : "Fair");
        draw_text_transparent(message, 256, line, 15);
        line += 9;
        switch ((c & 0x30) >> 4) {
        case 0: strcpy(message, "Low"); break;
        case 1: strcpy(message, "Moderate"); break;
        case 2: strcpy(message, "High"); break;
        case 3: strcpy(message, "Extreme"); break;
        }
        draw_text_transparent(message, 256, line, 15);
        line += 9;
    }
    flush_input();
    drv_set_color_map(select_palette, select_palette);
    picked = -1;
    for (i = 1; i <= 2; i++) {
        slot = !picked;
        if (is_cga) draw_rect_outline(0, slot * 50 + 9, 319, 37, 15);
        else drv_recolor_rect(g_gfx, 0, slot * 50, 320, 50, 1, 9);
        done = 0;
        do {
            while (drv_kbhit()) {
                if (is_cga) draw_rect_outline(0, slot * 50 + 9, 319, 37, 0);
                else drv_recolor_rect(g_gfx, 0, slot * 50, 320, 50, 9, 1);
                wait_retrace(10);
                if (is_cga) draw_rect_outline(0, slot * 50 + 9, 319, 37, 15);
                else drv_recolor_rect(g_gfx, 0, slot * 50, 320, 50, 1, 9);
                wait_retrace(10);
            }
            if (is_cga) draw_rect_outline(0, slot * 50 + 9, 319, 37, 4);
            else drv_recolor_rect(g_gfx, 0, slot * 50, 320, 50, 9, 1);
            switch (keycode = get_key()) {
            case 0x5000:
                if (slot < 3) slot++;
                break;
            case 0x4800:
                if (slot > 0) slot--;
                break;
            case 13:
            case ' ':
                done = 1;
                break;
            }
            if (slot == picked) {
                if ((keycode == 0x5000 && slot < 3) || slot == 0) slot++;
                else slot--;
            }
            if (is_cga) draw_rect_outline(0, slot * 50 + 9, 319, 37, 15);
            else drv_recolor_rect(g_gfx, 0, slot * 50, 320, 50, 1, 9);
        } while (!done);
        cars[i].bits = specs[slot];
        picked = slot;
        strcpy(message, "Car #");
        strcat(message, itoa(i, num_buf, 10));
        draw_text_transparent(message, 0x9A, slot * 50 + 9, 15);
    }
    play_sound(1);
}

chase_loop()
{
    int inview, attempts, lateral, i;
    unsigned newdir;
    int ch, cx, moved, k, spare, cy, dx, leader, dy, ty;

    if (chase_mode != 2 && chase_clock == 32) {
        cars[1].speed = cars[2].speed = 2;
        play_sound(0x16);
        sound_param = cars[cur_car].speed;
        play_sound(0x1B);
        play_sound(0x1A);
        flush_input();
    }
    if (!drv_kbhit() && chase_clock > 32) {
        switch (ch = get_key()) {
        case 'f':
            game_speed = 2;
            break;
        case 'd':
            game_speed = 1;
            break;
        case 's':
            game_speed = 0;
            break;
        case 0x4400:                    /* F10: follow */
            cars[cur_car].follow = 1;
            break;
        case 0x4800:
            cars[cur_car].req = 0;
            cars[cur_car].follow = 0;
            break;
        case 0x4D00:
            cars[cur_car].req = 1;
            cars[cur_car].follow = 0;
            break;
        case 0x5000:
            cars[cur_car].req = 2;
            cars[cur_car].follow = 0;
            break;
        case 0x4B00:
            cars[cur_car].req = 3;
            cars[cur_car].follow = 0;
            break;
        case '=':
            if (cars[cur_car].speed == 0) play_sound(0x16);
            else if (((cars[cur_car].bits + 2) & 3) > (unsigned)cars[cur_car].speed) play_sound(0x18);
            cars[cur_car].speed = clamp(cars[cur_car].speed + 1, 0, (cars[cur_car].bits & 3) + 2);
            if (chase_mode == 2 && cars[cur_car].speed > 2) cars[cur_car].speed = 2;
            sound_param = cars[cur_car].speed;
            play_sound(cur_car == 1 ? 0x1A : 0x1B);
            break;
        case '-':
            if (cars[cur_car].speed) play_sound(0x19);
            cars[cur_car].speed = clamp(cars[cur_car].speed - 1, 0, 3);
            sound_param = cars[cur_car].speed;
            play_sound(cur_car == 1 ? 0x1A : 0x1B);
            break;
        case ' ':
            if (chase_mode != 2) {
                cur_car++;
                if (cur_car >= 3) cur_car = 1;
                scene = (scene + 4) & 7;
            }
            sound_param = cars[cur_car].speed;
            play_sound(cur_car == 1 ? 0x1A : 0x1B);
            break;
        case 'a':
        case 0x3B00:                    /* F1: arrest */
            if (in_range) {
                outcome = 2;
                chase_over = 1;
                return;
            }
        case 'e':
        case 0x3C00:                    /* F2: escape into a building */
            if (check_building_reached(cars[0].x, cars[0].y)) {
                chase_over = 1;
                outcome = 0;
            }
            break;
        case 0x1000:                    /* Alt-Q */
            if (text_window("Are you sure\nyou want to Quit?\n No\n Yes\n", 0xCA, 4) == 1) {
                set_exit_state(1L);
                exit();
            }
            break;
        case 0x1F00:                    /* Alt-S: sound */
            if (options & 4) play_sound(0);
            options ^= 4;
            break;
        case 0x1900:                    /* Alt-P: pause */
            play_sound(0x25);
            get_key();
            play_sound(0x26);
            break;
        case 0x1B:
            if (chase_mode != 2) {
                chase_over = 1;
                return;
            }
            break;
        }
        if (((cars[cur_car].dir + 2) & 3) == cars[cur_car].req) {
            if (cars[cur_car].bits & 8) {
                play_sound(0x17);
                cars[cur_car].dir = cars[cur_car].req;
            }
            cars[cur_car].req = -1;
        }
    }
    in_range = 0;
    for (i = 0; i < 3; i++) {
        leader = (chase_mode != 2) ? (i == 0) : (i != 0);
        if (!leader) draw_map_dot(cars[i].x, cars[i].y, 5);
        else draw_map_dot(cars[i].tx, cars[i].ty, 5);
        moved = 0;
        if (speed_masks[cars[i].speed] & (1 << (chase_clock % 6))) {
            cars[i].x += dir_dx[cars[i].dir];
            cars[i].y += dir_dy[cars[i].dir];
            moved = 1;
            if (!leader && cars[i].x == cars[i].tx && cars[i].y == cars[i].ty) cars[i].tx = -1;
            if (i == cur_car) scene = ++scene & 7;
        }
        if (!leader) {
            if (i != cur_car || (chase_clock & 2)) draw_map_dot(cars[i].x, cars[i].y, 10);
        } else {
            score = cars[i].heat / heat_limit;
            if (cars[i].follow || show_targets) {
                cars[i].tx = cars[i].x;
                cars[i].ty = cars[i].y;
                cars[i].req = cars[i].dir;
            }
            if (chase_mode != 2 || cars[i].follow)
                draw_map_dot(cars[i].tx, cars[i].ty, cars[i].follow ? 13 : 7);
            cars[i].follow = 0;
            if (escape_timer && --escape_timer == 0) chase_over = 1;
            if (chase_mode != 2 && cars[i].x == target_x && cars[i].y == target_y && !escape_timer) {
                cars[i].speed = 0;
                escape_timer = -(difficulty * 64 - 256);
            }
        }
        inview = car_in_view(i);
        if (i != 0 && inview != 0) {
            if (chase_mode != 2) {
                if (cars[i].speed) {
                    cars[i].heat++;
                    if (inview <= 32) cars[i].heat++;
                    if (cars[i].speed > 2) cars[i].heat++;
                    cars[i].heat += ((cars[i].bits & 0x30) >> 4) - 1;
                }
                cars[0].follow = 1;
                if (cars[i].heat > heat_limit * 2) {
                    cars[0].heat++;
                    if (heat_limit / 2 < cars[0].heat && !escape_timer) cars[0].speed = 3;
                    if (cars[0].heat > heat_limit && !escape_timer) cars[0].speed = 4;
                }
                if (escape_timer && chase_mode != 2) {
                    outcome = 1;
                    if (++lost_count > 16) chase_over = 1;
                }
            }
            if (chase_mode != 2 && !escape_timer && cars[0].speed < cars[i].speed)
                cars[0].speed = cars[i].speed;
            if (((cars[0].dir + 2) & 3) == cars[i].dir) {
                if (abs(cars[i].x - cars[0].x) + abs(cars[i].y - cars[0].y) <= 8) {
                    in_range = 1;
                    if (chase_mode == 2) outcome = chase_over = 1;
                }
            }
            if (chase_mode == 2) {
                cars[i].tx = cars[i].x;
                cars[i].ty = cars[i].y;
                cars[i].follow = 1;
                cars[i].speed = clamp((chase_clock >> 3) - i, 0, inview < 32 ? 2 : 3);
            }
        } else {
            if (i != 0 && cars[i].heat > 0) cars[i].heat--;
            if (i != 0 && chase_mode == 2) {
                cars[i].speed = 3;
                if (difficulty == 0) cars[i].speed = (chase_clock & (16 << i)) ? 2 : 3;
                if (difficulty == 3) cars[i].speed = (chase_clock & (16 << i)) ? 3 : 4;
                inview = abs(cars[0].x - cars[i].x) + abs(cars[0].y - cars[i].y);
                if ((5 - difficulty) * 32 / 2 >= inview) {
                    cars[i].tx = cars[i].x;
                    cars[i].ty = cars[i].y;
                    cars[i].follow = 1;
                }
            }
        }
        if (moved && cars[i].x % 32 == 0 && cars[i].y % 32 == 0) {
            nop_stub();
            cx = cars[i].x / 32;
            cy = cars[i].y / 32;
            if (i == 0) {
                if (chase_mode == 2) {
                    if (cars[i].req != -1 && road_open(cx, cy, cars[i].req)) {
                        if (i == cur_car && cars[i].dir != cars[i].req)
                            turn_animation(cars[i].dir, cars[i].req);
                        cars[i].dir = cars[i].req;
                        cars[i].req = -1;
                    }
                    if (!road_open(cx, cy, cars[i].dir)) {
                        attempts = 0;
                        do {
                            do newdir = random(4);
                            while (!road_open(cx, cy, newdir));
                        } while (((cars[i].dir + 2) & 3) == newdir && ++attempts < 9);
                        if (i == cur_car) turn_animation(cars[i].dir, newdir);
                        cars[i].dir = newdir;
                    }
                } else {
                    if (!escape_timer) cars[0].speed = 2;
                    dx = target_x - cars[i].x;
                    dy = target_y - cars[i].y;
                    if ((random(2) || dy == 0) && dx != 0) {
                        newdir = dx > 0 ? 1 : 3;
                        if (!road_open(cx, cy, newdir)) newdir = dy > 0 ? 2 : 0;
                    } else {
                        newdir = dy > 0 ? 2 : 0;
                        if (!road_open(cx, cy, newdir)) newdir = dx > 0 ? 1 : 3;
                    }
                    if (cars[i].heat > random(heat_limit * 4)) newdir = random(4);
                    attempts = 0;
                    while (!road_open(cx, cy, newdir) ||
                           (((cars[i].dir + 2) & 3) == newdir && ++attempts < 9))
                        newdir = random(4);
                    cars[i].dir = newdir;
                    for (k = 1; k < 3; k++) {
                        if (car_in_view(k)) {
                            cars[1].tx = dir_dx[cars[0].dir] * 2 + cars[0].x;
                            cars[1].ty = dir_dy[cars[0].dir] * 2 + cars[0].y;
                        }
                    }
                }
            } else {
                if (chase_mode == 2) {
                    dx = cars[0].x - cars[i].x;
                    dy = cars[0].y - cars[i].y;
                    switch (cars[0].dir) {
                    case 0: ty = -dy; lateral = dx; break;
                    case 2: ty = dy; lateral = -dx; break;
                    case 1: ty = dx; lateral = dy; break;
                    case 3: ty = -dx; lateral = -dy; break;
                    }
                    if (lateral == 0) {
                        newdir = ((turn_toggle++ & 1) * 2 + cars[0].dir - 1) & 3;
                        if (((cars[i].dir + 2) & 3) == newdir || !road_open(cx, cy, newdir))
                            newdir = cars[0].dir;
                        if (!road_open(dir_dx[newdir] + cx, dir_dy[newdir] + cy, cars[0].dir))
                            newdir = cars[0].dir;
                        if (ty < 0) newdir = (cars[0].dir + 2) & 3;
                        if (ty > 32) newdir = cars[0].dir;
                    } else if (-abs(random(lateral)) < ty) {
                        newdir = cars[0].dir;
                        if (((cars[i].dir + 2) & 3) == newdir || !road_open(cx, cy, newdir))
                            newdir = (lateral > 0 ? cars[0].dir + 1 : cars[0].dir - 1) & 3;
                    } else {
                        newdir = (lateral > 0 ? cars[0].dir + 1 : cars[0].dir - 1) & 3;
                        if (((cars[i].dir + 2) & 3) == newdir || !road_open(cx, cy, newdir))
                            newdir = cars[0].dir;
                    }
                } else {
                    newdir = cars[i].dir;
                    if (cars[i].req != -1) {
                        if (road_open(cx, cy, cars[i].req)) {
                            newdir = cars[i].req;
                            cars[i].req = -1;
                        }
                    } else if (cars[i].follow == 1) {
                        dx = cars[1].tx - cars[i].x;
                        dy = cars[1].ty - cars[i].y;
                        if (cars[i].bits & 4) {
                            if (sign(dx) != sign(cars[0].x - cars[i].x) ||
                                sign(dy) != sign(cars[0].y - cars[i].y)) {
                                dx = sign(cars[0].x - cars[i].x) * 4;
                                dy = sign(cars[0].y - cars[i].y) * 4 - random(2) * 2 + 1;
                            }
                        }
                        if (dx || dy) {
                            newdir = abs(dx) > abs(dy) ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2 : 0);
                            if (((cars[i].dir + 2) & 3) == newdir || !road_open(cx, cy, newdir))
                                newdir = abs(dx) <= abs(dy) ? (dx > 0 ? 1 : 3) : (dy > 0 ? 2 : 0);
                            if (((cars[i].dir + 2) & 3) == newdir) newdir = cars[i].dir;
                        }
                    }
                    if (car_in_view(i)) {
                        cars[1].tx = dir_dx[cars[0].dir] * 2 + cars[0].x;
                        cars[1].ty = dir_dy[cars[0].dir] * 2 + cars[0].y;
                    }
                }
                if (road_open(cx, cy, newdir) && ((cars[i].dir + 2) & 3) != newdir) {
                    if (i == cur_car) turn_animation(cars[i].dir, newdir);
                } else {
                    attempts = 0;
                    do {
                        do newdir = random(4);
                        while (!road_open(cx, cy, newdir));
                    } while (((cars[i].dir + 2) & 3) == newdir && ++attempts < 9);
                }
                cars[i].dir = newdir;
            }
        }
    }
    if (chase_mode != 2 && cars[0].follow == 0L && heat_limit * 2 < cars[0].heat && !escape_timer)
        chase_over = 2;
    draw_street_view(cur_car, 200, 100);
    draw_dashboard();
}

/* Local names below are chosen so MSC assigns the original stack slots. */


car_in_view(n)
int n;
{
    int open;
    int ij;
    int bkx, row;
    int rx, distx, dy, ady;
    int dir;

    rx = cars[0].x - cars[n].x;
    dy = cars[0].y - cars[n].y;
    distx = abs(rx);
    ady = abs(dy);
    if (is_night && (distx > 64 || ady > 64))
        return 0;
    open = 1;
    bkx = (cars[n].x + (cars[n].dir == 3 ? 31 : 0)) / 32;
    row = (cars[n].y + (cars[n].dir == 0 ? 31 : 0)) / 32;
    if (distx == 0 && ady < 192 && cars[n].x % 32 == 0) {
        dir = dy > 0 ? 2 : 0;
        for (ij = 0; ij <= ady / 32; ij++) {
            if (!road_open(bkx, row, dir)) {
                open = 0;
                break;
            }
            row += sign(dy);
        }
        car_ahead = dir == 0 ? dy < 0 : dy > 0;
        if (!open)
            return 0;
        return ady;
    }
    if (ady != 0 || distx >= 192 || cars[n].y % 32 != 0)
        return 0;
    dir = rx > 0 ? 1 : 3;
    for (ij = 0; ij <= distx / 32; ij++) {
        if (!road_open(bkx, row, dir)) {
            open = 0;
            break;
        }
        bkx += sign(rx);
    }
    car_ahead = dir == 3 ? rx < 0 : rx > 0;
    if (!open)
        return 0;
    return distx;
}

road_open(x, y, dir)
int x, y, dir;
{
    if (x == 0 && dir != 1) return 0;
    if (y == 0 && dir != 2) return 0;
    if (x == 23 && dir != 3) return 0;
    if (y == 23 && dir != 0) return 0;
    switch (dir) {
    case 0:
        return city_map[x][y - 1] & 8;
    case 1:
        return city_map[x][y] & 1;
    case 2:
        return city_map[x][y] & 8;
    case 3:
        return city_map[x - 1][y] & 1;
    }
}

draw_map_dot(x, y, color)
int x, y, color;
{
    put_pixel(x * 8 / 32, y * 8 / 32, color);
    put_pixel(x * 8 / 32 + 1, y * 8 / 32, color);
    put_pixel(x * 8 / 32, y * 8 / 32 + 1, color);
    put_pixel(x * 8 / 32 + 1, y * 8 / 32 + 1, color);
}

put_pixel(x, y, color)
int x, y, color;
{
    draw_line(x, y, x, y, color);
}

int edge_xw[4][2] = { { 2, 28 }, { 30, 2 }, { 2, 28 }, { 0, 2 } };
int edge_yh[4][2] = { { 0, 2 }, { 2, 28 }, { 30, 2 }, { 2, 28 } };

draw_street_view(n, px, py)
int n, px, py;
{
    int ty3, x, y, frame, flag1, by, syo, bx1, sx, k, tx;

    x = cars[n].x;
    y = cars[n].y;
    tx = clamp(x - 60, 0, 648);
    ty3 = clamp(y - 50, 0, 668);
    if (view_x == 0) {
        view_x = tx;
        view_y = ty3;
    }
    do {
        view_x += clamp(tx - view_x, -4, 4);
        view_y += clamp(ty3 - view_y, -4, 4);
        bx1 = view_x / 32;
        by = view_y / 32;
        if (bx1 != tile_x || by != tile_y) {
            for (x = 0; x < 5; x++) {
                for (y = 0; y < 5; y++) {
                    sx = (city_map[bx1 + x][by + y] >> 4) * 32;
                    syo = 17;
                    while (sx >= 320) {
                        sx -= 320;
                        syo += 32;
                    }
                    drv_copy_rect(sprite_page, sx, syo, 32, 32, back_page, x * 32, y * 32);
                    k = 0;
                    do {
                        if (!((1 << k) & city_map[bx1 + x][by + y]))
                            gfx_fill_rect(back_page, x * 32 + edge_xw[k][0], y * 32 + edge_yh[k][0],
                                          edge_xw[k][1], edge_yh[k][1], 7);
                    } while (++k < 4);
                }
            }
            tile_x = bx1;
            tile_y = by;
        }
        drv_copy_rect(back_page, view_x - bx1 * 32, view_y - by * 32, 120, 100, back_page, px, py);
        for (k = 0; k < 3; k++) {
            if (k != 0 && cars[k].heat > heat_limit * 2 && (chase_clock & 2))
                continue;
            flag1 = chase_mode == 2 ? (flag1 = k > 0) : k == 0;   /* double store as in the original */
            if (!flag1) {
                sx = cars[k].x - view_x;
                syo = cars[k].y - view_y;
                frame = (cars[k].heat > heat_limit ? 0 :
                        k == cur_car && !(chase_clock & 7) ? 8 : 4) + cars[k].dir;
                if ((chase_clock & 4) && cars[k].req != -1) {
                    if ((cars[k].dir + 1 & 3) == cars[k].req)
                        frame += 12;
                    if ((cars[k].dir - 1 & 3) == cars[k].req)
                        frame += 24;
                }
            } else {
                sx = cars[k].tx - view_x;
                syo = cars[k].ty - view_y;
                frame = (cars[k].follow ? 0 : 4) + cars[k].req;
            }
            if (sx > 4 && sx < 116 && syo > 4 && syo < 96)
                draw_car_icon(sx + px, syo + py, k, frame);
        }
        g_gfx->page = 1;
        draw_line(px, py, px + 119, py, 15);
        draw_line(px + 119, py + 99, px + 119, py, 15);
        draw_line(px + 119, py + 99, px, py + 99, 15);
        draw_line(px, py, px, py + 99, 15);
        g_gfx->page = 0;
        drv_copy_rect(back_page, px, py, 120, 100, g_gfx, px, py);
    } while (tx != view_x || ty3 != view_y);
}

draw_car_icon(x, y, flag, dir)
int x, y, flag, dir;
{
    if (chase_mode == 2)
        flag = !flag;
    if (dir & 1)
        drv_copy_rect(sprite_page, dir * 8 + 1, flag ? 10 : 2, 6, 4, back_page, x - 3, y - 2);
    else
        drv_copy_rect(sprite_page, dir * 8 + 2, flag ? 9 : 1, 4, 6, back_page, x - 2, y - 3);
}

nop_stub()
{
    int a, b, c, d;
}

int last_scene = -1;
int last_dash_y = -1;
char clock_str[] = "0:00:00";

draw_dashboard()
{
    if (scene > 7)
        scene = 0;
    if (scene != last_scene) {
        drv_copy_rect(scene_page, scene / 4 * 125, scene % 4 * 47, 116, 44, g_gfx, 201, 1);
        drv_copy_rect(sprite_page, 202, 145, 116, 24, g_gfx, 202, 45);
    }
    if ((dash_dist = car_in_view(cur_car)) && car_ahead) {
        dash_dist += dash_dist / 2;
        dash_size = clamp(dash_dist / 4 - 2, 0, 15);
        dash_near = 63 - clamp(dash_dist, 0, 63);
        dash_y = ((dash_near * dash_near >> 2) * 20 >> 10) + 19;
        dash_x = 61;
        if (cars[cur_car].dir != cars[0].dir)
            dash_x -= (dash_near * dash_near >> 2) * 20 >> 7;
        if (dash_y != last_dash_y || scene != last_scene) {
            if (scene == last_scene) {
                drv_copy_rect(scene_page, scene / 4 * 125, scene % 4 * 47, 116, 44, g_gfx, 201, 1);
                drv_copy_rect(sprite_page, 202, 145, 116, 24, g_gfx, 202, 45);
            }
            gate_thunk_b(car_sprites,
                         dash_x - (car_shape_rect[dash_size].x1 - car_shape_rect[dash_size].x0) / 2,
                         dash_y, car_shapes[dash_size]);
        }
        last_dash_y = dash_y;
    } else {
        if (last_dash_y != -1 && scene == last_scene) {
            drv_copy_rect(scene_page, scene / 4 * 125, scene % 4 * 47, 116, 44, g_gfx, 201, 1);
            drv_copy_rect(sprite_page, 202, 145, 116, 24, g_gfx, 202, 45);
        }
        last_dash_y = -1;
    }
    last_scene = scene;
    strcpy(message, "");
    strcat(message, itoa(cars[cur_car].speed * 20, num_buf, 10));
    g_gfx->fillcolor = 5;
    draw_text(message, 230, 75, 7);
    dash_size = clamp(cars[cur_car].heat * 5 / heat_limit, 0, 10) * 3;
    if (!(chase_clock & 3)) {
        drv_copy_rect(sprite_page, 288, 186, 30, 2, g_gfx, 288, 85);
        if (dash_size && (!(chase_clock & 7) || dash_size < 30))
            drv_recolor_rect(g_gfx, 288, 84, dash_size, 2, 7, 14);
    }
    draw_text(format_clock(chase_clock), 290, 75, 9);
    if (!(chase_clock & 3)) {
        drv_copy_rect(sprite_page, 275, 185, 10, 10, g_gfx, 275, 84);
        if (!(chase_clock & 4) && cars[cur_car].follow == 1)
            drv_recolor_rect(g_gfx, 276, 85, 6, 7, 1, is_cga ? 15 : 7);
    }
    if (!(chase_clock & 3)) {
        drv_copy_rect(sprite_page, 273, 175, 14, 10, g_gfx, 273, 74);
        if (cars[cur_car].bits & 4) {
            if (chase_clock & 4) {
                dash_dx = cars[0].x - cars[cur_car].x;
                dash_dy = cars[0].y - cars[cur_car].y;
                if (dash_dx >= 0 && dash_dy <= 0)
                    drv_recolor_rect(g_gfx, 280, 74, 4, 4, 5, 11);
                if (dash_dx >= 0 && dash_dy >= 0)
                    drv_recolor_rect(g_gfx, 280, 79, 4, 4, 5, 11);
                if (dash_dx <= 0 && dash_dy <= 0)
                    drv_recolor_rect(g_gfx, 273, 74, 4, 4, 5, 11);
                if (dash_dx <= 0 && dash_dy >= 0)
                    drv_recolor_rect(g_gfx, 273, 79, 4, 4, 5, 11);
            } else
                put_pixel(dir_dx[cars[cur_car].dir] + 278, dir_dy[cars[cur_car].dir] + 78, 9);
        }
    }
}

turn_animation(dir, newdir)
int dir, newdir;
{
    int x;

    drv_set_palette(text_palette);
    if ((dir - 1 & 3) == newdir) {
        play_sound(23);
        x = 8;
        do {
            drv_copy_rect(scene_page, scene / 4 * 125, scene % 4 * 47, 116 - x, 44, g_gfx, x + 201, 1);
            drv_copy_rect(scene_page, scene / 4 * 125 - x + 116, scene % 4 * 47, x, 44, g_gfx, 201, 1);
            wait_retrace(2);
            x += 32 / (game_speed + 2);
        } while (x < 116);
    }
    if ((dir + 1 & 3) == newdir) {
        play_sound(23);
        x = 108;
        do {
            drv_copy_rect(scene_page, scene / 4 * 125, scene % 4 * 47, 116 - x, 44, g_gfx, x + 201, 1);
            drv_copy_rect(scene_page, scene / 4 * 125 - x + 116, scene % 4 * 47, x, 44, g_gfx, 201, 1);
            wait_retrace(2);
            x -= 32 / (game_speed + 2);
        } while (x > 8);
    }
    drv_set_palette(chase_palette);
}

sign(n)
int n;
{
    if (n > 0) return 1;
    if (n < 0) return -1;
    return 0;
}
