/* NEWCHAR.C - FINAL.EXE: a new character (gender, code name, difficulty, training),
 * the plot briefing and the episode story, the training and practice menus and the
 * leader-face quiz.  Reconstructed from the original binary; compiles with MSC 5.1
 * CL /AS /Gs /Oas. */
#include "final.h"

/* portrait of each leader (by leader code): sex, then features for face_code_for,
 * [7] the icon */
int face_defs[26][8] = {
    { 0, 1, 2, 2, 2, 2, 3, 1 },
    { 0, 0, 3, 3, 3, 3, 1, 2 },
    { 0, 1, 5, 3, 4, 6, 0, 3 },
    { 0, 0, 8, 4, 6, 1, 3, 1 },
    { 0, 1, 5, 5, 5, 5, 0, 0 },
    { 0, 1, 6, 6, 6, 6, 3, 2 },
    { 0, 1, 4, 8, 5, 2, 3, 1 },
    { 0, 1, 7, 7, 8, 7, 1, 3 },
    { 0, 1, 1, 2, 3, 7, 2, 1 },
    { 0, 1, 3, 1, 8, 5, 3, 3 },
    { 0, 1, 2, 2, 2, 3, 3, 0 },
    { 0, 0, 3, 3, 3, 1, 2, 1 },
    { 0, 1, 4, 8, 5, 3, 3, 2 },
    { 0, 0, 8, 4, 6, 5, 3, 3 },
    { 0, 1, 7, 7, 8, 8, 0, 0 },
    { 0, 1, 6, 6, 6, 8, 3, 3 },
    { 1, 0, 2, 2, 2, 2, 3, 2 },
    { 1, 0, 4, 4, 4, 4, 1, 3 },
    { 1, 0, 7, 1, 8, 5, 0, 3 },
    { 1, 0, 8, 5, 3, 7, 3, 3 },
    { 1, 1, 1, 8, 4, 2, 1, 2 },
    { 1, 1, 4, 7, 2, 1, 0, 2 },
    { 1, 1, 5, 2, 6, 3, 0, 0 },
    { 1, 1, 5, 5, 5, 5, 3, 0 },
    { 1, 0, 5, 3, 1, 6, 3, 1 },
    { 1, 0, 2, 6, 7, 8, 0, 0 }
};

/* plot.txt's plots: name, leaders that may run it, the crime and the two
 * briefing roles of each episode */
struct PlotDef plot_defs[16] = {
    { "Welcome Max", 0xf00,
      { 1, -1, -1, -1, -1, -1, -1, -1 },
      {
        { "the US Embassy", "a top secret code book" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "'KeyHole' Sattelite", 0x900,
      { 0, 6, 4, -1, -1, -1, -1, 1 },
      {
        { "sattelite expert Xavier Rayban", "" },
        { "the uplink ground station", "" },
        { "CIA storage", "X-Band radio transmitter" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Freedom Games", 0xc00,
      { 7, 2, 6, -1, -1, -1, -1, 1 },
      {
        { "the Freedom Games security plan", "" },
        { "an Israeli security expert", "" },
        { "the Israeli athletic dormitory", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "SuperDrug", 0x600,
      { 0, 4, 3, -1, -1, -1, -1, 1 },
      {
        { "the noted chemist Dr Pasture", "" },
        { "a large industrial warehouse", "chemicals" },
        { "new super drug", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Liberian Election", 0x900,
      { 11, 6, 8, -1, -1, -1, -1, 1 },
      {
        { "Geraldo Corazon", "" },
        { "the Election Commission HQ", "" },
        { "the Social Democrat campaign rally", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Summit Conference", 0xc00,
      { 10, 9, 2, -1, -1, -1, -1, 1 },
      {
        { "Carlos the Hyena", "" },
        { "summit ID Documents", "" },
        { "a leading Head of State", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Rampant Inflation", 0xa00,
      { 10, 4, 12, -1, -1, -1, -1, 1 },
      {
        { "Willie the Pen", "" },
        { "the Treasury Building", "Currency Plates" },
        { "medium denomination currency", "currency paper" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Stolen Nuke", 0xc00,
      { 7, 9, 4, -1, -1, -1, -1, 1 },
      {
        { "AirBase Passwords", "" },
        { "AirBase ID Cards", "" },
        { "an AirBase", "a Nuclear Bomb" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Super Cannon", 0xb00,
      { 4, 4, 12, -1, -1, -1, -1, 1 },
      {
        { "a chemical plant", "explosive propellants" },
        { "a metal foundry", "high-strength tubes" },
        { "the super cannon", "precision lathe" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Build Nuclear Weapon", 0xd00,
      { 4, 0, 12, -1, -1, -1, -1, 1 },
      {
        { "a breeder reactor", "plutonium 235" },
        { "physicist Dr A. Einstone", "" },
        { "a nuclear bomb", "imploding detonator" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Terror Campaign", 0xc00,
      { 6, 8, 2, -1, -1, -1, -1, -1 },
      {
        { "train station", "" },
        { "the Veteran's Day parade", "" },
        { "a Supreme Court Justice", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Virus X", 0xc00,
      { 0, 4, 12, -1, -1, -1, -1, -1 },
      {
        { "bacteriologist Edgar Coli", "" },
        { "the medical college", "virulent virus samples" },
        { "deadly virus X", "one million Petri dishes" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Drug Shortage", 0xa00,
      { 6, 2, 3, -1, -1, -1, -1, -1 },
      {
        { "InterPol Headquarters", "" },
        { "chief drug investigator", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Train Wreck", 0xc00,
      { 7, 5, 6, -1, -1, -1, -1, -1 },
      {
        { "VIP travel itinerary", "" },
        { "the locomotive plant", "train schematics" },
        { "the train station", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Prison Break", 0x700,
      { 9, 11, 10, -1, -1, -1, -1, -1 },
      {
        { "prison visitor pass", "" },
        { "the prison warden", "" },
        { "Manny Noriega", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } },
    { "Stealth Fighter", 0x300,
      { 11, 7, 4, -1, -1, -1, -1, -1 },
      {
        { "fighter pilot", "" },
        { "airbase operation plans", "" },
        { "the secret hangar", "stealth fighter" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" },
        { "", "" }
      } }
};

create_new_character()
{
    career_points = 0;
    cur_month = 0;
    history[0] = 0xFF;
    masterminds_arrested = 0L;
    career_rank = 99;
    load_picture_swapped("gender.pic", 1);
    drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
    strcpy(text_buf, "Select one...\n Maximillian Remington\n Maxine Remington\n");
    if (show_menu(text_buf, 96, 33) == 1)
        options |= 2;
    codename_dialog();
    strcpy(text_buf, "Which difficulty level?\n Local Disturbance\n National Threat\n Regional Conflict\n Global Crisis\n");
    difficulty = clamp(show_menu(text_buf, 96, 129), 0, 3);
    training_screen(0L);
}

plot_briefing()
{
    int last, i, k;

    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
    default_sel = 0;
    i = 0;
    do
        random(0xfff);
    while (++i < 16);
    if (difficulty || cur_month) {
        last = plot_num;
        do
            plot_num = random(15) + 1;
        while (last == plot_num);
    } else
        plot_num = 0;
    do {
        k = 0;
        do {
            if (!(k & 7))
                load_world_file(world_num = random(3));
            mm_known = plot_episodes = 0;
            mm_org = random(12) + 4;
            mm_city = random(16);
            last_episode = -1;
        } while (++k < 999 && (1L << orgs[mm_org].flags & masterminds_arrested)
                 || orgs[mm_org].flags == -1);
        mm_id = face_code_for(orgs[mm_org].flags & 0xff);
    } while (leader_code = orgs[mm_org].flags & 0xff,
             !(plot_defs[plot_num].orgs & orgs[mm_org].flags));
    strcpy(plot_key, "*PL0090");
    plot_key[3] = plot_num / 10 + '0';
    plot_key[4] = plot_num % 10 + '0';
    set_scene_var(0, 4);
    drv_set_color_map(story_colors, story_colors);
    set_scene_background("briefing.pan", 0, 0);
    do {
        text_buf[0] = 0;
        if (k = lookup_text_simple("plot.txt", plot_key)) {
            wrap_text_buffer(40);
            show_menu(text_buf, 8, 149);
            clear_text_area();
        }
        plot_key[6]++;
    } while (k);
    briefed = 1;
}

case_intro_story()
{
    int tries, cur_plot, episode, usable, m;

    cur_plot = plot_num;
again:
    tries = 0;
    do {
        episode = random(6);
        usable = (plot_episodes & (1 << episode)) || plot_defs[cur_plot].crime[episode] == -1 ? 0 : 1;
        if (plot_defs[cur_plot].crime[episode + 1] == -1
            && ((m = 0xff >> (8 - episode)) & plot_episodes) != m)
            usable = 0;
        if (episode == last_episode && ++tries < 99)
            usable = 0;
    } while (!usable && ++tries < 999);
    if (tries < 999) {
        last_episode = episode;
        episode_crime = plot_defs[cur_plot].crime[episode];
        if (episode < 7) {
            strcpy(player_name, plot_defs[cur_plot].roles[episode][0]);
            strcpy(player_org_name, plot_defs[cur_plot].roles[episode][1]);
        } else {
            strcpy(player_name, "Max Remington's apartment");
            strcpy(player_org_name, "a mattress full of cash");
        }
        strcpy(plot_key, ((1 << episode) & 3 | plot_episodes) == 3 ? "*PL000A" : "*PL000a");
        plot_key[3] = plot_num / 10 + '0';
        plot_key[4] = plot_num % 10 + '0';
        plot_key[5] = episode + '0';
        if (!briefed || episode == 7) {
            set_scene_var(0, 4);
            drv_set_color_map(story_colors, story_colors);
            set_scene_background("briefing.pan", 0, 0);
            do {
                text_buf[0] = 0;
                if (usable = lookup_text_simple("plot.txt", plot_key)) {
                    wrap_text_buffer(40);
                    show_menu(text_buf, 8, 149);
                    clear_text_area();
                }
                plot_key[6]++;
            } while (usable);
        }
    } else {
        plot_briefing();
        goto again;
    }
    num_msgs = clock_base = game_time = num_sites = mission_ended = f_96d6 = seen_orgs = 0;
}

codename_dialog()
{
    drv_set_color_map(dialog_colors, dialog_colors);
    fill_rect_xy(99, 85, 221, 114, 8);
    fill_rect_xy(100, 87, 220, 113, 5);
    fill_rect_xy(101, 88, 219, 112, 8);
    fill_rect_xy(105, 101, 215, 110, 5);
    draw_line(101, 86, 219, 86, 7);
    draw_line(103, 99, 217, 99, 5);
    draw_line(102, 112, 218, 112, 5);
    draw_line(104, 101, 104, 110, 7);
    draw_line(216, 101, 216, 110, 7);
    draw_text_centered("Max's code name is:", 161, 90, 2);
    text_buf[0] = 0;
    enter_codename(106, 100, 15);
    strcpy(codename, text_buf);
    g_gfx->fillcolor = 5;
    drv_set_color_map(std_colormap, std_colormap2);
}

practice_menu()
{
    strcpy(text_buf, "Which difficulty level?\n Local Disturbance\n National Threat\n Regional Conflict\n Global Crisis\n");
    difficulty = show_menu(text_buf, 80, 128);
    training_screen(1L);
}

char *skill_names[] = {
    "Combat", "Driving", "Cryptography", "Electronics", "Stamina"
};

training_screen(practice)
int practice;
{
    int total, x, y, i, choice, lvl[4];

    x = 40;
    y = 100;
    total = 0;
    load_picture_swapped("training.pic", 1);
    drv_copy_rect(back_page, 0, 0, 320, 200, g_gfx, 0, 0);
    drv_set_color_map(std_colormap, std_colormap2);
    i = 0;
    do
        lvl[i] = 0;
    while (++i < 4);
    default_sel = 0;
    do {
        g_gfx->fillcolor = 5;
        if (!practice)
            training_rating(lvl);
        strcpy(text_buf, " ");
        for (i = 0; i < 4; i++) {
            strcat(text_buf, skill_names[i]);
            strcat(text_buf, practice ? " practice\n " : " training\n ");
        }
        default_sel = choice = show_menu(text_buf, 92, 25);
        if (practice) {
            default_sel = 0;
            return;
        }
        if (choice != -1 && lvl[choice] != 3) {
            total++;
            lvl[choice]++;
        }
    } while (choice != -1 && total != 4);
    for (i = 0; i < 4 - total; i++)
        if (lvl[i] < 3)
            lvl[i]++;
    training_rating(lvl);
    if (lvl[i] == 2)
        lvl[i] = 1;
    i = 0;
    do
        skill_levels += lvl[i] << (i << 1);
    while (++i < 4);
    wait_retrace(60);
    if (!difficulty)
        skill_levels = 0x55;
    skill_levels |= 0x500;
}

int rating_colors[] = { 4, 9, 8, 2 };
char face_palette[] = { 0, 1, 2, 3, 4, 0, 6, 7, 8, 9, 10, 11, 12, 15, 14, 15, 0 };

training_rating(lvl)
int *lvl;
{
    int i;

    if (is_cga)
        rating_colors[3] = 0;
    for (i = 0; i < 4; i++) {
        switch (lvl[i]) {
        case 0:
            strcpy(text_buf, "Average");
            break;
        case 1:
            strcpy(text_buf, "Good");
            break;
        case 2:
            strcpy(text_buf, "Excellent");
            break;
        case 3:
            strcpy(text_buf, "Awesome");
            break;
        }
        gfx_fill_rect(g_gfx, i * 80 + 8, 188, 64, 8, rating_colors[i]);
        draw_text_centered(text_buf, i * 80 + 40, 188, is_cga ? 15 : 14);
    }
}

enter_codename(x, y, len)
int x, y, len;
{
    char tmp[64];
    int first, i, k;

    gfx_fill_rect(g_gfx, x, y + 1, len * 7, 9, 5);
    g_gfx->fillcolor = 5;
    cursor = 0;
    first = 1;
    for (i = strlen(text_buf); i < len; i++)
        text_buf[i] = ' ';
    text_buf[len] = 0;
    draw_codename_field(x, y, len);
    for (;;) {
        while (drv_kbhit()) {
            drv_recolor_rect(g_gfx, cursor_x, y + 1, cursor_w, 10, 5, 2);
            wait_retrace(10);
            drv_recolor_rect(g_gfx, cursor_x, y + 1, cursor_w, 10, 2, 5);
            if (drv_kbhit())
                wait_retrace(10);
        }
        k = get_key();
        if (k == 13) {
            i = len - 1;
            break;
        }
        if (k == 0x4b00 && cursor)
            cursor--;
        if (k == 0x4d00 && len - 1 > cursor)
            cursor++;
        if (k == 0x5200) {
            strcpy(tmp, text_buf + cursor);
            strcpy(text_buf + cursor + 1, tmp);
            text_buf[cursor] = ' ';
            text_buf[len] = 0;
        }
        if (k == 0x5300) {
            strcpy(text_buf + cursor, text_buf + cursor + 1);
            text_buf[cursor] = ' ';
            text_buf[len - 1] = ' ';
            text_buf[len] = 0;
        }
        if (k == 8 && cursor) {
            strcpy(text_buf + cursor - 1, text_buf + cursor);
            text_buf[len - 1] = ' ';
            text_buf[len] = 0;
            cursor--;
        }
        if (k < 0x80 && k >= ' ') {
            if (first)
                for (i = 0; i < len; i++)
                    text_buf[i] = ' ';
            text_buf[cursor] = k;
            if (len - 1 > cursor)
                cursor++;
        }
        first = 0;
        draw_codename_field(x, y, len);
    }
    for (; i > 0 && text_buf[i] == ' '; i--)
        text_buf[i] = 0;
}

draw_codename_field(x, y, len)
int x, y, len;
{
    int i, ch;

    x += 2;
    y += 2;
    for (i = 0; i < len; i++) {
        gfx_fill_rect(g_gfx, x, y, 8, 8, 5);
        if (strlen(text_buf) > i) {
            ch = text_buf[i + 1];
            text_buf[i + 1] = 0;
            draw_text(text_buf + i, x, y, 10);
            text_buf[i + 1] = ch;
            if (i == cursor) {
                cursor_x = x;
                cursor_w = drv_char_width(1, text_buf[i]);
            }
            x += drv_char_width(1, text_buf[i]);
        }
    }
}

face_code_for(p)
int p;
{
    int i, code;

    code = face_defs[p][1] * 2 + face_defs[p][6] * 4 - face_defs[p][0] + 1;
    i = 0;
    do
        code += face_defs[p][i + 2] - 1 << i * 3 + 4;
    while (++i < 4);
    return code;
}

draw_face_for(p, x, y)
int p, x, y;
{
    int code;

    code = face_code_for(p);
    drv_set_color_map(face_colormap, face_colormap);
    gfx_fill_rect(g_gfx, x - 2, y - 2, 54, 56, 7);
    gfx_fill_rect(g_gfx, x - 1, y - 1, 52, 54, 13);
    gfx_fill_rect(g_gfx, x + 2, y + 2, 46, 45, 5);
    if ((code >> 2 & 3) == 3 && video_mode != 'C')
        gfx_fill_rect(g_gfx, x + 3, y + 3, 44, 43, 7);
    else
        gfx_fill_rect(g_gfx, x + 3, y + 3, 44, 43, 3);
    draw_face_parts(code, x + 12, y + 3);
    draw_sprite_a(face_defs[p][7] + (code & 1 ? 0x68 : 0x70), x + 3, y + 28);
}

debug_show_faces()
{
    int i;

    drv_set_palette(face_palette);
    i = 0;
    do {
        gfx_fill_rect(g_gfx, 0, 0, 320, 200, 0);
        draw_face_for(i, 80, 24, 0L);
        draw_text_transparent(mastermind_names[i], 80, 100, 15);
        getch();
    } while (++i < 26);
}

identify_leader_faces()
{
    int used[26], faces[15], done, key, joy_x, joy_y, where, cx, cy, right, leader2, face;

    drv_set_palette(face_palette);
    where = 0;
    do
        used[where] = 0;
    while (++where < 26);
    leader2 = random(26);
    right = random(15);
    used[leader2] = 1;
    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
    strcpy(text_buf, "Max, I'm sure you recognize the head of\nthe ");
    strcat(text_buf, mastermind_names[leader2]);
    strcat(text_buf, " among these faces.\n");
    dossier_state = 1;
    show_menu(text_buf, 16, 1);
    for (where = 0; where < 15; where++) {
        if (where == right)
            face = leader2;
        else {
            do
                face = random(26);
            while (used[face]);
            used[face] = 1;
        }
        draw_face_for(face, where % 5 * 64 + 4, where / 5 * 60 + 24, 0L);
        faces[where] = face;
    }
    cx = 2;
    cy = 1;
    where = 7;
    done = 0;
    do {
        if (is_cga)
            draw_rect_outline(where % 5 * 64 + 1, where / 5 * 60 + 21, 55, 57, 0);
        else
            drv_recolor_rect(g_gfx, where % 5 * 64 + 3, where / 5 * 60 + 23, 54, 56, 0, 13);
        if (drv_kbhit())
            wait_retrace(15);
        key = read_joystick(&joy_x, &joy_y);
        if ((options & 0x10) && joystick_button(0))
            key = 13;
        if (key == -1 && !drv_kbhit())
            key = get_key();
        if (key != -1) {
            switch (key) {
            case 2:
            case 0x4900:
                cx++;
            case 1:
            case 0x4800:
                cy--;
                break;
            case 3:
            case 0x4d00:
                cx++;
                break;
            case 4:
            case 0x5100:
                cx++;
            case 5:
            case 0x5000:
                cy++;
                break;
            case 6:
            case 0x4f00:
                cx--;
                cy++;
                break;
            case 7:
            case 0x4b00:
                cx--;
                break;
            case 8:
            case 0x4700:
                cx--;
                cy--;
                break;
            case 13:
            case 27:
            case ' ':
                done = 1;
                break;
            }
            cx = clamp(cx, 0, 4);
            cy = clamp(cy, 0, 2);
            where = cy * 5 + cx;
        }
        if (is_cga)
            draw_rect_outline(where % 5 * 64 + 1, where / 5 * 60 + 21, 55, 57, 15);
        else
            drv_recolor_rect(g_gfx, where % 5 * 64 + 3, where / 5 * 60 + 23, 54, 56, 13, 0);
        wait_retrace(15);
    } while (!done);
    gfx_fill_rect(g_gfx, 0, 0, 320, 200, 5);
    drv_set_palette(game_palette);
    /* This is the copy protection check. The 1990 floppy FINAL.EXE is exactly this
     * code; the GOG and eXoDOS releases have the JNE of this compare patched to two
     * NOPs (applied after compiling, see `patches` in baseline.py), which removes
     * the protection. */
    return where == right;
}

clear_text_area()
{
    gfx_fill_rect(g_gfx, 4, 149, 312, 48, 5);
}
