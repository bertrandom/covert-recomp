/* SUSPECTS.C - GAME.EXE: the suspects overview, person clues and the research
 * office (a separate object from TIME.C in the original: the relocation order needs a
 * record break at suspects_overview). */
#include "game.h"

int tab_colors[] = { 14, 10, 14, 10 };  /* 3d24 */
int list_sel = 0;                       /* 3d2c */

suspects_overview()
{
    int p, padl, padm, keyj;
    char bufg[10];
    int doneo, xn, sd, yo, i, pade, colorl;

    for (;;) {
        gfx_fill_rect(g_gfx, 0, 0, 320, 20, 8);
        for (i = 0; i < num_suspects; i++)
            *((unsigned char *)&suspects[i].flags + 1) &= ~0x40;
        menu_count = 0;
        yo = 6;
        for (i = 0; i < 80; i++) {
            if (clues[i].suspect != -1 && (sd = clues[i].suspect, !(suspects[sd].flags & 0x4000))) {
                *((unsigned char *)&suspects[sd].flags + 1) |= 0x40;
                menu_items[menu_count++] = clues[i].suspect;
                p = suspects[sd].person;
                text_buf[0] = 0;
                if (persons[p].fate == -1)
                    strcpy(text_buf, "ARRESTED");
                if (persons[p].fate == -3)
                    strcpy(text_buf, "TURNED");
                strcpy(bufg, text_buf);
                text_buf[0] = 0;
                append_number(clues[i].text);
                colorl = tab_colors[menu_count & 3];
                if (is_cga)
                    colorl = 2;
                gfx_fill_rect(g_gfx, 0, yo + 8, 320, 8, colorl);
                if (menu_count & 1) {
                    draw_title_tab(160, yo, colorl);
                    gfx_fill_rect(g_gfx, 172, yo + 1, 134, 9, 7);
                    draw_text_centered(text_buf, 240, yo + 2, 0);
                    draw_text_centered(bufg, 240, yo + 6, 12);
                } else {
                    draw_title_tab(0, yo, colorl);
                    gfx_fill_rect(g_gfx, 12, yo + 1, 134, 9, 7);
                    draw_text_centered(text_buf, 80, yo + 2, 0);
                    draw_text_centered(bufg, 80, yo + 6, 12);
                }
                yo += 6;
            }
        }
        gfx_fill_rect(g_gfx, 0, yo + 10, 320, 190 - yo, 8);
        strcpy(text_buf, "Clues");
        draw_text_transparent(text_buf, 144, yo + 16, 15);
        draw_rect_outline(142, yo + 14, text_width(text_buf) + 4, 10, 7);
        draw_rect_outline(16, yo + 12, 288, 24, 0);
        doneo = 0;
        do {
            xn = (list_sel & 1) ? 12 : 172;
            yo = list_sel * 6 + 7;
            drv_recolor_rect(g_gfx, xn, yo, 136, 9, 7, 15);
            wait_retrace(20);
            do {
                keyj = joystick_to_key();
                if (keyj != -1)
                    break;
            } while (drv_kbhit());
            if (!drv_kbhit())
                keyj = get_key();
            switch (keyj) {
            case 0x5000:
                if (list_sel < menu_count - 1)
                    list_sel++;
                break;
            case 0x4800:
                if (list_sel > 0)
                    list_sel--;
                break;
            case 0x0d:
            case 0x20:
                doneo = 1;
                break;
            case 0x1b:
                doneo = -1;
                break;
            }
            drv_recolor_rect(g_gfx, xn, yo, 136, 9, 15, 7);
        } while (doneo == 0);
        flush_input();
        if (doneo != -1) {
            show_person_clues(menu_items[list_sel]);
            continue;
        }
        break;
    }
}

show_person_clues(sus)
int sus;
{
    int p, r, i, y;

    draw_page_frame("Clue", 14);
    y = 16;
    for (i = 0; i < 80; i++) {
        if (clues[i].suspect == sus) {
            r = random(12) + 4;
            if (y != 16)
                draw_card_panel(r, y - 2);
            g_gfx->fillcolor = 15;
            strcpy(text_buf, "\207Source: ");
            strcat(text_buf, orgs[clues[i].org].name);
            strcat(text_buf, "/");
            strcat(text_buf, cities[clues[i].city].name);
            strcat(text_buf, "\n");
            clue_text_wrapper(i);
            strcat(text_buf, "\n");
            y = draw_wrapped_text(32, r + 8, y, 5);
            y += 4;
        }
    }
    y = 16;
    for (i = 0; i < 80; i++) {
        if (clues[i].suspect == sus && clues[i].kind >> 8 == 1) {
            text_buf[0] = 0;
            describe_person(i);
            draw_portrait(face_shown, 264, 16);
            draw_sprite_a(108, 299, 40);
            p = suspects[clues[i].suspect].person;
            if (persons[p].fate == -1)
                draw_text_transparent("ARRESTED", 258, 52, 12);
            if (persons[p].fate == -2)
                draw_text_transparent("IN HIDING", 258, 52, 12);
            if (persons[p].fate == -3)
                draw_text_transparent(" TURNED", 258, 52, 12);
            y += 64;
            if (y > 144)
                break;
        }
    }
    wait_key_or_button();
}

research_office()
{
    int best, bscore, found, si, ev, ln, i, maxa, msg, sc, mmind, p;

    drv_set_color_map(default_colors, default_colors);
    set_scene_background((options & 2) ? "officem.pan" : "officef.pan", 168, 0);
    set_scene_var(0, (options & 2) ? -1 : 1);
    strcpy(text_buf, "Max, I've been\ngoing over the\ninfo we've got\nso far ...\n");
    show_menu(text_buf, 16, 17);
    mmind = suspects[0].person;
    if (difficulty || persons[mmind].fate < 0 || here_city != 1)
        mmind = -1;
    maxa = 3;
    for (i = 0; i < 16; i++)
        if (maxa < org_clue_count[i]) maxa = org_clue_count[i];
    found = 0;
    strcpy(text_buf, "I'd look into\nthese organizations:\n");
    for (i = 0; i < 16; i++) {
        if (maxa - maxa / 4 <= org_clue_count[i] || (mmind != -1 && persons[mmind].org == i)) {
            strcat(text_buf, " ");
            strcat(text_buf, orgs[i].name);
            strcat(text_buf, "\n");
            found = 1;
        }
    }
    if (!found) text_buf[0] = 0;
    maxa = 3;
    for (i = 0; i < 16; i++)
        if (maxa < city_clue_count[i]) maxa = city_clue_count[i];
    found = 0;
    ln = strlen(text_buf);
    strcat(text_buf, "\x8fThese cities have been\n\x8fpretty active lately:\n ");
    for (i = 0; i < 16; i++) {
        if (maxa - maxa / 4 <= city_clue_count[i] || (mmind != -1 && i == 1)) {
            strcat(text_buf, cities[i].name);
            strcat(text_buf, "\n ");
            found = 1;
        }
    }
    if (!found) {
        text_buf[ln] = 0;
        if (ln == 0)
            strcpy(text_buf, "There's not\nmuch to go\nat this point.\n");
    }
    if (mmind != -1) {
        si = set_location_known(persons[mmind].org, 1, 12);
        if (si == -1 || sites[si].strength == 0) {
            menu_flag = 1;
            show_menu(text_buf, 16, 81);
            clear_play_area();
            strcpy(text_buf, "The ");
            strcat(text_buf, orgs[persons[mmind].org].name);
            strcat(text_buf, " has a");
            append_building_type(1, persons[mmind].org);
            strcat(text_buf, " right here in ");
            strcat(text_buf, cities[here_city].name);
            strcat(text_buf, "! I'd suggest you go there and place a wiretap or break in.");
            wrap_text_buffer(16);
            show_menu(text_buf, 16, 17);
            return;
        }
    }
    best = -1;
    bscore = 0;
    for (ev = 0; ev < num_msgs; ev++) {
        msg = msgs[ev].msg;
        if (msgs[ev].type == 0 && msgs[ev].flags != 0
            && ((plots[msg].flags & 0xf00) == 0x200 || (plots[msg].flags & 0xf00) == 0x300
                || msg < 0)
            && !(msgs[ev].flags & 0x8000)) {
            p = msgs[ev].sender;
            if (!(persons[p].roles & 0x7fff)) {
                strcpy(text_buf, "This message should give us some vital info: ");
                append_person_name(p);
                strcat(text_buf, " ");
                format_message_event(ev);
                strcat(text_buf, ". Check with the Crypto branch.");
                bscore = 6;
                best = -2;
            }
        }
    }
    for (i = 0; i < num_persons; i++) {
        if ((persons[i].known & 8) && (persons[i].flags & 0x7fff)) {
            sc = 0;
            if (persons[i].fate < 0) continue;
            if (persons[i].known & 1) sc++;
            if (persons[i].known & 4) sc++;
            if ((persons[i].known & 8) && persons[i].city == here_city) sc += 2;
            if (persons[i].roles & 0x7fff) sc += 5;
            if (sc > bscore) {
                best = i;
                bscore = sc;
            }
        }
    }
    menu_flag = 1;
    if (best > -1) {
        suspect_dossier(best, 0, 0);
        if (persons[best].roles & 0x7fff)
            strcpy(text_buf, "Max, we've got enough evidence to arrest this agent. ");
        else
            strcpy(text_buf, "Max, I suggest you check out this person. ");
        if (persons[best].city == here_city) {
            strcat(text_buf, (persons[best].id & 1) ? "He" : "She");
            strcat(text_buf, "'s right here in ");
            strcat(text_buf, cities[here_city].name);
            strcat(text_buf, ". ");
            if (persons[best].known & 4) {
                if (set_location_known(persons[best].org, here_city, 0) != -1)
                    show_prose(persons[best].roles ? "*advicea" : "*advice1", 32,
                               orgs[persons[best].org].name);
                else
                    show_prose("*advice2", 32, orgs[persons[best].org].name);
            } else if (persons[best].known & 3)
                show_prose("*advice3", 32);
            else
                show_prose("*advice4", 32);
        } else
            show_prose("*advice5", 32, cities[persons[best].city].name);
        show_menu(text_buf, 24, 104);
    }
    if (best == -2) {
        wrap_text_buffer(16);
        show_menu(text_buf, 16, 81);
    }
    if (best == -1)
        show_menu(text_buf, 16, 81);
}
