/* BRIEFING.C - Covert Action strategic game (GAME.EXE): the mission briefing,
 * show_menu, and the city pictures from cities.cat.
 * Reconstructed for Microsoft C 5.1 (CL /AS /Gs /Oas), K&R style. */
#include "game.h"

mission_briefing()
{
    char cell[14];
    int r;
    char val[4];
    char unused[6];
    int total;

    total = 0;
    game_time = -1;
    do {
        if (num_msgs > 5) {
            do r = random(16);
            while (mole_cities & (1 << r));
            total += describe_new_info(1, r, 99, 0, 0);
        } else
            advance_time(180);
        in_building = 0;
    } while ((4 - difficulty) * 2 > total);
    briefing_done = 1;
    set_scene_var(0, 1);
    drv_set_color_map(briefing_colors, briefing_colors);
    set_scene_background("briefing.pan", 0, 0);
    strcpy(text_buf, "The rest is up to you. ");
    if (!difficulty)
        strcat(text_buf, "I've assigned one of my best research assistants to work with you on this case. ");
    strcat(text_buf, "The President's counting on you Max, don't let us down.");
    wrap_text_buffer(0x28);
    show_menu(text_buf, 8, 0x95);
}

reset_people_marks()
{
    int i;
    int spare;

    for (i = 0; i < num_plots; i++) plots[i].state = 999;
}

/* Show a text window (on a cleared screen if one is pending). */
show_menu(s, x, y)
char *s;
int x, y;
{
    if (clear_pending != -1) {
        clear_screen();
        advance_time(0);
        clear_pending = -1;
    }
    text_window(s, x, y);
}

clear_screen()
{
    int unused1;
    int unused2;

    g_gfx->fillcolor = 5;
    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
}

draw_sprite_a(n, x, y)
int n, x, y;
{
    drv_draw_image(g_gfx, x, y, faces_f[n]);
}

/* Show the picture of city C (from cities.cat) with its name centered above
 * (X, Y). */
load_city_picture(c, x, y)
int c, x, y;
{
    if (c != anim_handle) {
        strcpy(text_buf, cities[c].name);
        strip_spaces(text_buf);
        if (strlen(text_buf) > 8) text_buf[8] = 0;
        strcat(text_buf, ".pic");
        show_city_from_catalog(text_buf);
        drv_copy_rect(back_page, 0, 0, city_pic_w, city_pic_h, work_page, 0, 0);
        anim_handle = c;
        shown_pic_w = city_pic_w;
        shown_pic_h = city_pic_h;
    }
    y -= shown_pic_h / 2;
    strcpy(text_buf, cities[c].name);
    strcat(text_buf, ", ");
    strcat(text_buf, cities[c].country);
    draw_text_centered(text_buf, x, y - 10, 15);
    x -= shown_pic_w / 2;
    if (city_pic_w) {
        draw_rect_outline(x - 1, y - 1, shown_pic_w + 1, shown_pic_h + 1, 15);
        drv_copy_rect(work_page, 0, 0, shown_pic_w, shown_pic_h, g_gfx, x, y);
    }
    g_gfx->fillcolor = 5;
}

/* Load picture NAME from cities.cat into the back page and measure it. */
show_city_from_catalog(name)
char *name;
{
    int i;

    if (!require_disk(3, 0L)) {
        city_pic_w = city_pic_h = 0;
        require_disk(2, 1L);
        return;
    }
    gfx_fill_rect(back_page, 0, 0, 320, 200, 0);
    open_catalog("cities.cat");
    load_picture_swapped(name, 1);
    close_catalog();
    require_disk(2, 1L);
    if (is_cga) {
        i = 0;
        do {
            if (drv_slot12(1, i, 0)) city_pic_w = i;
            i++;
        } while (i < 160);
        for (i = 0; i < 100; i++)
            if (drv_slot12(1, 0, i)) city_pic_h = i;
    } else {
        city_pic_w = 0;
        while (drv_slot12(1, city_pic_w, 0) && city_pic_w < 160) city_pic_w++;
        city_pic_h = 0;
        while (drv_slot12(1, 0, city_pic_h) && city_pic_h < 100) city_pic_h++;
    }
}

strip_spaces(s)
char *s;
{
    int i;

    for (i = 0; i < strlen(s); i++)
        while (s[i] == ' ') strcpy(&s[i], &s[i + 1]);
}
