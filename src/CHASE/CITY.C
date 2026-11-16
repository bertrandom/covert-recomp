/* CITY.C - CHASE.EXE: dashboard clock and city street map generation (a separate
 * object in the original: the relocation order needs a record break at format_clock). */
#include "mps.h"
#include "chase.h"

/* Assembly library / MS C runtime */
extern int far gate_thunk_b();
extern char *itoa();

char *format_clock(t)
int t;
{
    int min, ss, hr, clock;

    clock = (t / 60 + (int)game_time) % 1440;
    hr = clock / 60;
    min = clock % 60;
    ss = t % 60;
    clock_str[0] = hr % 10 + '0';
    clock_str[2] = min / 10 + '0';
    clock_str[3] = min % 10 + '0';
    clock_str[5] = ss / 10 + '0';
    clock_str[6] = ss % 10 + '0';
    return clock_str;
}

empty_hook()
{
}

generate_city_map()
{
    int lx, dist, nk, byn, i, ok, j, unused9, m, sidej, color;

    if (real_mission)
        srand((unsigned)city_id * 123 + (map_seed & 0x3fff));
    color = is_night || is_cga ? 8 : 7;
    fill_rect_xy(0, 0, 199, 199, 1);
    fill_rect_xy(1, 1, 198, 198, color);
    fill_rect_xy(200, 0, 319, 99, 1);
    drv_copy_rect(sprite_page, 200, 101, 120, 100, g_gfx, 200, 0);
    draw_line(200, 0, 319, 0, 15);
    for (i = 0; i < 24; i++)
        for (j = 0; j < 24; j++)
            city_map[i][j] = random(16) * 16 + 15;
    i = 8;
    do {
        draw_line(i, 1, i, 198, 5);
        draw_line(i + 1, 1, i + 1, 198, 5);
        i += 8;
    } while (i < 200);
    j = 8;
    do {
        draw_line(1, j, 198, j, 5);
        draw_line(1, j + 1, 198, j + 1, 5);
        j += 8;
    } while (j < 200);
    nk = 0;
    do {
        i = random(21) + 2;
        j = random(21) + 2;
        sidej = nk & 3;
        if (nk & 2) {   /* a wall needs two untouched blocks */
            if ((city_map[i][j] & 15) != 15) continue;
            if ((city_map[i + dir_dx[sidej]][j + dir_dy[sidej]] & 15) != 15) continue;
        }
        {
            city_map[i][j] &= 255 - (1 << sidej);
            city_map[i][j] = ((i + j & 1) << 4) + (city_map[i][j] & 15) + 128;
            city_map[i + dir_dx[sidej]][j + dir_dy[sidej]] &= 255 - (1 << (nk + 2 & 3));
            draw_line(wall_x[sidej][0] + i * 8, wall_y[sidej][0] + j * 8,
                      wall_x[sidej][1] + i * 8, wall_y[sidej][1] + j * 8, color);
            draw_line(wall_x[sidej][0] + (sidej & 1) + i * 8, wall_y[sidej][0] + j * 8 - (sidej & 1) + 1,
                      wall_x[sidej][1] + (sidej & 1) + i * 8, wall_y[sidej][1] + j * 8 - (sidej & 1) + 1, color);
        }
    } while (++nk < 192);
    for (nk = 0; nk < 16; nk++) {
        do {
            do {
                if (difficulty < 2) {
                    lx = random(12) * 32 + 192;
                    byn = random(12) * 32 + 208;
                } else {
                    lx = random(18) * 32 + 96;
                    byn = random(18) * 32 + 112;
                }
            } while (!road_open(lx / 32, byn / 32, 2));
            ok = 1;
            for (m = 1; m < nk; m++) {
                dist = abs(lx - bld_x[m]) + abs(byn - bld_y[m]);
                if (dist < difficulty * 32 + 64) {
                    ok = 0;
                    break;
                }
            }
        } while (!ok);
        bld_x[nk] = lx;
        bld_y[nk] = byn;
        if (nk != 0 && (!real_mission || cities[city_id].org_mask & (1 << nk))) {
            draw_map_dot((nk & 1 ? 8 : -8) + lx, byn, 15);
            if (!real_mission) {
                strcpy(message, "Loc");
                strcat(message, itoa(nk, loc_buf, 10));
            } else
                strcpy(message, orgs[nk].abbrev);
            g_gfx->textbg = 0;
            draw_text(message, lx * 8 / 32 + 4, byn * 8 / 32 - 3, is_cga ? 15 : is_night ? 7 : 9);
            g_gfx->textbg = 1;
        }
    }
    chase_start = random(15) + 1;
    do
        chase_dest = random(15) + 1;
    while (chase_start == chase_dest);
    if (real_mission) {
        chase_start = (char)ENV[9];
        if (options & 0x20) {
            do
                chase_start = random(16);
            while (chase_start == target_building);
        }
        chase_dest = target_building;
    }
}

check_building_reached(x, y)
int x, y;
{
    int dist, found, n;

    found = 0;
    for (n = 1; n < 16; n++) {
        if (cities[city_id].org_mask & (1 << n))
            dist = abs(x - bld_x[n]) + abs(y - bld_y[n]);
        if (dist <= 6) {
            if (real_mission)
                target_building = (char)(ENV[0xe] = n);
            found = 1;
            break;
        }
    }
    return found;
}
