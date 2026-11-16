/* TRAVEL.C - Covert Action strategic game (GAME.EXE): the world map and the
 * travel screen, the flight between cities, and the alertness of the
 * organizations.  Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "game.h"

/* Plane heading 0-7 (clockwise from north) and its unit step; headings[sign(dx) + 1][sign(dy) + 1] */
char heading_dx[8] = { 0, 1, 1, 1, 0, -1, -1, -1 };        /* 2750 */
char heading_dy[8] = { -1, -1, 0, 1, 1, 1, 0, -1 };        /* 2758 */
char headings[3][3] = { { 7, 6, 5 }, { 0, 0, 4 }, { 1, 2, 3 } };  /* 2760 */

travel_screen(n)
int n;
{
    int cost;
    int key;
    register int city;
    int i;
    int waiting;
    int done;
    int cursor;

    for (;;) {
        switch (cities[0].name[2]) {
        case 's':
            load_picture_swapped("europe.pic", 1);
            break;
        case 'm':
            load_picture_swapped("africa.pic", 1);
            break;
        case 'g':
            load_picture_swapped("central.pic", 1);
            break;
        }
        drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
        strcpy(text_buf, "You're in ");
        strcat(text_buf, cities[here_city].name);
        strcat(text_buf, "\nDo you travel to ...\n");
        strcat(text_buf, " Stay here\n");
        for (i = 0; i < 16; i++) {
            strcat(text_buf, " ");
            strcat(text_buf, cities[i].name);
            strcat(text_buf, "\n");
        }
        strcat(text_buf, " Check Data\n");
        g_gfx->fillcolor = 0;
        draw_wrapped_text(0x28, 0xc2, 9, 7);
        drv_recolor_rect(g_gfx, 0xc0, 9, 0x80, 0x10, 7, 15);
        drv_copy_rect(g_gfx, 0, 0, 320, 200, back_page, 0, 0);
        cursor = -1;
        done = waiting = 0;
        do {
            draw_city_label(here_city, is_cga ? 15 : 7);
            if (cursor >= 0 && cursor < 16) draw_city_label(cursor, 15);
            drv_recolor_rect(g_gfx, 0xc0, cursor * 8 + 0x21, 0x80, 8, 7, 11);
            if (waiting) wait_retrace(10);
            n = cursor;
            while ((key = joystick_to_key()) == 0xffff && drv_kbhit())
                ;
            if (!(waiting = drv_kbhit())) key = get_key();
            switch (key) {
            case 0x5000:
                cursor++;
                break;
            case 0x4800:
                cursor--;
                break;
            case 0x1b:
                cursor = -1;
            case 0x0d:
            case ' ':
                done = 1;
                break;
            }
            cursor = clamp(cursor, -1, 16);
            if (!done) {
                drv_copy_rect(back_page, 0, 0, 0xc0, 200, g_gfx, 0, 0);
                drv_recolor_rect(g_gfx, 0xc0, n * 8 + 0x21, 0x80, 8, 11, 7);
            }
        } while (!done);
        flush_input();
        g_gfx->fillcolor = 7;
        if (cursor == here_city) cursor = -1;
        if ((n = cursor + 1) != 0 && n < 17) {
            city = n - 1;
            cost = fly_to_city(here_city, city) / 8 * 30 + 60;
            here_city = city;
            add_chronology_entry(4, city);
            advance_time(cost);
            heat /= 3;
            return;
        }
        if (n != 17) return;
        data_files_menu();
    }
}

draw_city_label(c, color)
int c, color;
{
    int width;

    gfx_fill_rect(g_gfx, cities[c].map_x - 1, cities[c].map_y - 1, 3, 3, 3);
    width = text_width(cities[c].name);
    gfx_fill_rect(g_gfx, cities[c].map_x - 1, cities[c].map_y - 1, 3, 3, 11);
    if (cities[c].map_x < (unsigned)(0xbd - width))
        draw_text_transparent(cities[c].name, cities[c].map_x + 3, cities[c].map_y - 3, color);
    else
        draw_text_transparent(cities[c].name, cities[c].map_x - width - 3, cities[c].map_y - 3, color);
}

/* Flight animation between two cities; returns the number of frames. */
fly_to_city(from, to)
int from, to;
{
    int alt;
    int ddir;
    int last_alt;
    int x;
    int y;
    int sx;
    int dx;
    int tx;
    int dy;
    int ty;
    int frames;
    int dir;

    drv_copy_rect(g_gfx, 0, 0, 0xc0, 200, back_page, 0, 0);
    x = cities[from].map_x;
    y = cities[from].map_y;
    tx = cities[to].map_x;
    ty = cities[to].map_y;
    ddir = dir = random(8);
    alt = frames = 0;
    dx = tx - x;
    dy = ty - y;
    dir = headings[sign(dx) + 1][sign(dy) + 1];
    play_sound(0x23);
    last_alt = 0;
    do {
        if ((ddir = headings[sign(dx) + 1][sign(dy) + 1] - dir) != 0) {
            if ((ddir & 7) < 4) dir++;
            else dir--;
            dir &= 7;
        }
        alt = clamp((frames++ & 1) + alt, 0, (abs(dx) + abs(dy)) / 2);
        if (alt > 8) alt = 8;
        if (alt < last_alt) {
            play_sound(0x24);
            last_alt = -1;
        }
        if (last_alt != -1) last_alt = alt;
        x += heading_dx[dir];
        y += heading_dy[dir];
        sx = clamp(x - 5, 0, 999);
        drv_copy_rect(back_page, sx, y - alt - 6, 10, alt + 12, g_gfx, sx, y - alt - 6);
        draw_sprite_a(dir + 0x58, sx + 1, y - 4);
        draw_sprite_a(dir + 0x50, sx + 1, y - alt - 4);
        wait_retrace(10);
        dx = tx - x;
        dy = ty - y;
    } while (dx || dy);
    return frames;
}

sign(n)
int n;
{
    if (n > 0) return 1;
    if (n < 0) return -1;
    return 0;
}

/* Raise the alertness of every person in play after Max acts against ORG in
 * CITY, scaled by distance. */
raise_alertness(org, city, amount)
int org, city, amount;
{
    int p;
    int unused;
    int d1;
    int d2;
    int tally;
    int porg;
    int pcity;
    int ratio;

    if (amount > 0) {
        heat += amount / 2;
        for (p = 0; p < num_persons; p++) {
            if (!persons[p].id || persons[p].fate < 0) continue;
            porg = persons[p].org;
            pcity = persons[p].city;
            d1 = city_distance(orgs[org].home, orgs[porg].home);
            d2 = city_distance(cities[city].code, cities[pcity].code);
            ratio = ((long)((d1 + 4) * (d2 + 2)) << 8) / (amount + 1);
            persons[p].fate += (tally = 2500 / ratio);
        }
    }
}

describe_alert_level(org, who)
int org, who;
{
    int clue;
    int lvl;

    if (!org_alert_level(who, org)) {
        strcat(text_buf, "quiet");
        return 0;
    }
    clue = pick_clue(org, who, 0, 0, 0);
    lvl = city_distance(orgs[1].home, orgs[org].home) * heat / 24;
    if (clue != -1) lvl = (persons[clue].fate + lvl) / 2;
    if (mole_cities & (1 << who)) lvl += 16;
    if (lvl < 0) lvl = 99;
    switch (lvl / 12) {
    case 0:
        strcat(text_buf, "unsuspecting");
        break;
    case 1:
        strcat(text_buf, "cautious");
        break;
    case 2:
        strcat(text_buf, "suspicious");
        break;
    case 3:
        strcat(text_buf, "nervous");
        break;
    default:
        strcat(text_buf, "very nervous");
    }
    return lvl;
}
